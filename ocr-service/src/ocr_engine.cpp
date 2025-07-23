#include "ocr_engine.h"
#include <iostream>
#include <algorithm>
#include <regex>

OCREngine::OCREngine() 
    : language_("eng"), confidence_threshold_(60.0), preprocessing_enabled_(true), initialized_(false) {
}

OCREngine::~OCREngine() {
    cleanup();
}

bool OCREngine::initialize() {
    try {
        tess_api_ = std::make_unique<tesseract::TessBaseAPI>();
        
        // Initialize Tesseract with English language
        if (tess_api_->Init(nullptr, language_.c_str())) {
            std::cerr << "Failed to initialize Tesseract" << std::endl;
            return false;
        }
        
        // Set OCR parameters
        tess_api_->SetPageSegMode(tesseract::PSM_AUTO);
        tess_api_->SetVariable("tessedit_char_whitelist", "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.,!?@#$%&*()_+-=[]{}|;:'\"<>/\\ ");
        
        initialized_ = true;
        std::cout << "OCR Engine initialized successfully" << std::endl;
        return true;
        
    } catch (const std::exception& e) {
        std::cerr << "Error initializing OCR engine: " << e.what() << std::endl;
        return false;
    }
}

void OCREngine::cleanup() {
    if (tess_api_) {
        tess_api_->End();
        tess_api_.reset();
    }
    initialized_ = false;
}

OCRResult OCREngine::extractText(const std::string& image_path) {
    cv::Mat image = cv::imread(image_path);
    if (image.empty()) {
        std::cerr << "Failed to load image: " << image_path << std::endl;
        return OCRResult{};
    }
    
    return extractTextFromMat(image);
}

OCRResult OCREngine::extractTextFromMat(const cv::Mat& image) {
    if (!initialized_) {
        std::cerr << "OCR Engine not initialized" << std::endl;
        return OCRResult{};
    }
    
    OCRResult result;
    
    try {
        cv::Mat processed_image = image.clone();
        
        if (preprocessing_enabled_) {
            processed_image = preprocessImage(processed_image);
        }
        
        // Convert to Pix for Tesseract
        cv::Mat gray;
        cv::cvtColor(processed_image, gray, cv::COLOR_BGR2GRAY);
        
        // Create Pix from OpenCV Mat
        Pix* pix = pixCreate(gray.cols, gray.rows, 8);
        if (!pix) {
            std::cerr << "Failed to create Pix" << std::endl;
            return result;
        }
        
        // Copy data from Mat to Pix
        l_uint32* data = pixGetData(pix);
        int wpl = pixGetWpl(pix);
        for (int y = 0; y < gray.rows; y++) {
            for (int x = 0; x < gray.cols; x++) {
                SET_DATA_BYTE(data + y * wpl, x, gray.at<uchar>(y, x));
            }
        }
        
        // Set image for OCR
        tess_api_->SetImage(pix);
        
        // Get text
        char* text = tess_api_->GetUTF8Text();
        if (text) {
            result.text = std::string(text);
            delete[] text;
        }
        
        // Get confidence
        result.confidence = tess_api_->MeanTextConf();
        
        // Get word-level information
        tesseract::ResultIterator* ri = tess_api_->GetIterator();
        if (ri) {
            do {
                const char* word = ri->GetUTF8Text(tesseract::RIL_WORD);
                if (word) {
                    result.words.push_back(std::string(word));
                    result.word_confidences.push_back(ri->Confidence(tesseract::RIL_WORD));
                    
                    // Get bounding box
                    int left, top, right, bottom;
                    ri->BoundingBox(tesseract::RIL_WORD, &left, &top, &right, &bottom);
                    result.bounding_boxes.push_back(cv::Rect(left, top, right - left, bottom - top));
                    
                    delete[] word;
                }
            } while (ri->Next(tesseract::RIL_WORD));
            delete ri;
        }
        
        pixDestroy(&pix);
        
    } catch (const std::exception& e) {
        std::cerr << "Error during OCR: " << e.what() << std::endl;
    }
    
    return result;
}

DocumentInfo OCREngine::analyzeDocument(const std::string& image_path) {
    cv::Mat image = cv::imread(image_path);
    if (image.empty()) {
        std::cerr << "Failed to load image: " << image_path << std::endl;
        return DocumentInfo{};
    }
    
    return analyzeDocumentFromMat(image);
}

DocumentInfo OCREngine::analyzeDocumentFromMat(const cv::Mat& image) {
    DocumentInfo info;
    
    // Extract text first
    OCRResult ocr_result = extractTextFromMat(image);
    
    if (ocr_result.text.empty()) {
        return info;
    }
    
    // Simple document type detection
    std::string text_lower = ocr_result.text;
    std::transform(text_lower.begin(), text_lower.end(), text_lower.begin(), ::tolower);
    
    if (text_lower.find("invoice") != std::string::npos || 
        text_lower.find("bill") != std::string::npos) {
        info.document_type = "invoice";
    } else if (text_lower.find("receipt") != std::string::npos) {
        info.document_type = "receipt";
    } else if (text_lower.find("contract") != std::string::npos || 
               text_lower.find("agreement") != std::string::npos) {
        info.document_type = "contract";
    } else if (text_lower.find("financial") != std::string::npos || 
               text_lower.find("report") != std::string::npos) {
        info.document_type = "financial_report";
    } else {
        info.document_type = "unknown";
    }
    
    // Extract common fields
    std::vector<std::string> fields = {"date", "amount", "total", "name", "address", "phone", "email"};
    for (const auto& field : fields) {
        std::regex pattern(field + "\\s*[:=]\\s*([^\\n]+)", std::regex_constants::icase);
        std::smatch match;
        if (std::regex_search(ocr_result.text, match, pattern)) {
            info.extracted_data[field] = match[1].str();
            info.detected_fields.push_back(field);
        }
    }
    
    info.overall_confidence = ocr_result.confidence;
    
    return info;
}

std::vector<OCRResult> OCREngine::processBatch(const std::vector<std::string>& image_paths) {
    std::vector<OCRResult> results;
    results.reserve(image_paths.size());
    
    for (const auto& path : image_paths) {
        results.push_back(extractText(path));
    }
    
    return results;
}

void OCREngine::setLanguage(const std::string& language) {
    language_ = language;
    if (initialized_) {
        // Reinitialize with new language
        cleanup();
        initialize();
    }
}

void OCREngine::setConfidenceThreshold(double threshold) {
    confidence_threshold_ = threshold;
}

void OCREngine::enablePreprocessing(bool enable) {
    preprocessing_enabled_ = enable;
}

cv::Mat OCREngine::preprocessImage(const cv::Mat& input) {
    cv::Mat processed = input.clone();
    
    // Convert to grayscale if needed
    if (processed.channels() > 1) {
        cv::cvtColor(processed, processed, cv::COLOR_BGR2GRAY);
    }
    
    // Apply preprocessing steps
    processed = enhanceImage(processed);
    processed = removeNoise(processed);
    processed = deskewImage(processed);
    
    return processed;
}

cv::Mat OCREngine::enhanceImage(const cv::Mat& input) {
    cv::Mat enhanced = input.clone();
    
    // Apply histogram equalization
    cv::equalizeHist(enhanced, enhanced);
    
    // Apply adaptive threshold
    cv::adaptiveThreshold(enhanced, enhanced, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY, 11, 2);
    
    return enhanced;
}

cv::Mat OCREngine::removeNoise(const cv::Mat& input) {
    cv::Mat denoised = input.clone();
    
    // Apply Gaussian blur to reduce noise
    cv::GaussianBlur(denoised, denoised, cv::Size(3, 3), 0);
    
    // Apply morphological operations
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(2, 2));
    cv::morphologyEx(denoised, denoised, cv::MORPH_CLOSE, kernel);
    
    return denoised;
}

cv::Mat OCREngine::deskewImage(const cv::Mat& input) {
    cv::Mat deskewed = input.clone();
    
    // Find contours
    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(deskewed, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    
    if (contours.empty()) {
        return deskewed;
    }
    
    // Find the largest contour (assumed to be the main text area)
    auto max_contour = std::max_element(contours.begin(), contours.end(),
        [](const std::vector<cv::Point>& a, const std::vector<cv::Point>& b) {
            return cv::contourArea(a) < cv::contourArea(b);
        });
    
    if (max_contour == contours.end()) {
        return deskewed;
    }
    
    // Fit a rotated rectangle
    cv::RotatedRect rect = cv::minAreaRect(*max_contour);
    double angle = rect.angle;
    
    // Adjust angle
    if (angle < -45) {
        angle = 90 + angle;
    }
    
    // Rotate image if angle is significant
    if (std::abs(angle) > 0.5) {
        cv::Point2f center(deskewed.cols / 2.0f, deskewed.rows / 2.0f);
        cv::Mat rotation_matrix = cv::getRotationMatrix2D(center, angle, 1.0);
        cv::warpAffine(deskewed, deskewed, rotation_matrix, deskewed.size());
    }
    
    return deskewed;
} 