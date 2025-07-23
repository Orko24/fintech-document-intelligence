#pragma once

#include <string>
#include <vector>
#include <memory>
#include <opencv2/opencv.hpp>
#include <tesseract/baseapi.h>
#include <leptonica/allheaders.h>

struct OCRResult {
    std::string text;
    double confidence;
    std::vector<cv::Rect> bounding_boxes;
    std::vector<std::string> words;
    std::vector<double> word_confidences;
};

struct DocumentInfo {
    std::string document_type;
    std::vector<std::string> detected_fields;
    std::map<std::string, std::string> extracted_data;
    double overall_confidence;
};

class OCREngine {
public:
    OCREngine();
    ~OCREngine();

    bool initialize();
    void cleanup();

    // Core OCR functions
    OCRResult extractText(const std::string& image_path);
    OCRResult extractTextFromMat(const cv::Mat& image);
    
    // Document processing
    DocumentInfo analyzeDocument(const std::string& image_path);
    DocumentInfo analyzeDocumentFromMat(const cv::Mat& image);
    
    // Batch processing
    std::vector<OCRResult> processBatch(const std::vector<std::string>& image_paths);
    
    // Configuration
    void setLanguage(const std::string& language);
    void setConfidenceThreshold(double threshold);
    void enablePreprocessing(bool enable);

private:
    std::unique_ptr<tesseract::TessBaseAPI> tess_api_;
    cv::Mat preprocessImage(const cv::Mat& input);
    cv::Mat enhanceImage(const cv::Mat& input);
    cv::Mat removeNoise(const cv::Mat& input);
    cv::Mat deskewImage(const cv::Mat& input);
    
    std::string language_;
    double confidence_threshold_;
    bool preprocessing_enabled_;
    bool initialized_;
}; 