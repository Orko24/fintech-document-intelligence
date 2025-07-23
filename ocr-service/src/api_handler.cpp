#include "api_handler.h"
#include <fstream>
#include <sstream>
#include <filesystem>
#include <chrono>

APIHandler::APIHandler(OCREngine& engine) : ocr_engine_(engine) {
    // Create upload directory if it doesn't exist
    std::filesystem::create_directories("/tmp/ocr_uploads");
}

crow::response APIHandler::handleExtractRequest(const crow::request& req) {
    try {
        auto start_time = std::chrono::high_resolution_clock::now();
        
        // Parse request
        json request_data;
        try {
            request_data = json::parse(req.body);
        } catch (const json::exception& e) {
            return crow::response(400, createErrorResponse("Invalid JSON format").dump());
        }
        
        // Validate request
        if (!validateRequest(request_data)) {
            return crow::response(400, createErrorResponse("Missing required fields").dump());
        }
        
        std::string file_path = request_data["file_path"];
        
        // Perform OCR
        OCRResult result = ocr_engine_.extractText(file_path);
        
        auto end_time = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);
        
        // Prepare response
        json response_data = {
            {"text", result.text},
            {"confidence", result.confidence},
            {"processing_time", duration.count()},
            {"word_count", result.words.size()},
            {"words", result.words},
            {"word_confidences", result.word_confidences}
        };
        
        return crow::response(200, createSuccessResponse(response_data).dump());
        
    } catch (const std::exception& e) {
        return crow::response(500, createErrorResponse("Internal server error: " + std::string(e.what())).dump());
    }
}

crow::response APIHandler::handleTextExtraction(const crow::request& req) {
    try {
        auto start_time = std::chrono::high_resolution_clock::now();
        
        // Handle multipart form data for file upload
        crow::multipart::message msg(req);
        
        std::string file_path;
        for (const auto& part : msg.parts) {
            if (part.headers.find("Content-Disposition") != part.headers.end()) {
                auto content_disposition = part.headers.at("Content-Disposition");
                if (content_disposition.find("filename=") != std::string::npos) {
                    file_path = saveUploadedFile(msg);
                    break;
                }
            }
        }
        
        if (file_path.empty()) {
            return crow::response(400, createErrorResponse("No file uploaded").dump());
        }
        
        // Perform OCR
        OCRResult result = ocr_engine_.extractText(file_path);
        
        // Clean up uploaded file
        std::filesystem::remove(file_path);
        
        auto end_time = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);
        
        // Prepare response
        json response_data = {
            {"text", result.text},
            {"confidence", result.confidence},
            {"processing_time", duration.count()},
            {"word_count", result.words.size()}
        };
        
        return crow::response(200, createSuccessResponse(response_data).dump());
        
    } catch (const std::exception& e) {
        return crow::response(500, createErrorResponse("Internal server error: " + std::string(e.what())).dump());
    }
}

crow::response APIHandler::handleDocumentAnalysis(const crow::request& req) {
    try {
        auto start_time = std::chrono::high_resolution_clock::now();
        
        // Parse request
        json request_data;
        try {
            request_data = json::parse(req.body);
        } catch (const json::exception& e) {
            return crow::response(400, createErrorResponse("Invalid JSON format").dump());
        }
        
        if (!request_data.contains("file_path")) {
            return crow::response(400, createErrorResponse("Missing file_path field").dump());
        }
        
        std::string file_path = request_data["file_path"];
        
        // Perform document analysis
        DocumentInfo info = ocr_engine_.analyzeDocument(file_path);
        
        auto end_time = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);
        
        // Prepare response
        json response_data = {
            {"document_type", info.document_type},
            {"detected_fields", info.detected_fields},
            {"extracted_data", info.extracted_data},
            {"overall_confidence", info.overall_confidence},
            {"processing_time", duration.count()}
        };
        
        return crow::response(200, createSuccessResponse(response_data).dump());
        
    } catch (const std::exception& e) {
        return crow::response(500, createErrorResponse("Internal server error: " + std::string(e.what())).dump());
    }
}

crow::response APIHandler::handleBatchProcessing(const crow::request& req) {
    try {
        auto start_time = std::chrono::high_resolution_clock::now();
        
        // Parse request
        json request_data;
        try {
            request_data = json::parse(req.body);
        } catch (const json::exception& e) {
            return crow::response(400, createErrorResponse("Invalid JSON format").dump());
        }
        
        if (!request_data.contains("file_paths") || !request_data["file_paths"].is_array()) {
            return crow::response(400, createErrorResponse("Missing or invalid file_paths array").dump());
        }
        
        std::vector<std::string> file_paths = request_data["file_paths"];
        
        if (file_paths.empty()) {
            return crow::response(400, createErrorResponse("Empty file_paths array").dump());
        }
        
        // Process batch
        std::vector<OCRResult> results = ocr_engine_.processBatch(file_paths);
        
        auto end_time = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);
        
        // Prepare response
        json batch_results = json::array();
        for (const auto& result : results) {
            batch_results.push_back({
                {"text", result.text},
                {"confidence", result.confidence},
                {"word_count", result.words.size()}
            });
        }
        
        json response_data = {
            {"results", batch_results},
            {"total_files", results.size()},
            {"processing_time", duration.count()},
            {"average_confidence", [&results]() {
                if (results.empty()) return 0.0;
                double sum = 0.0;
                for (const auto& result : results) {
                    sum += result.confidence;
                }
                return sum / results.size();
            }()}
        };
        
        return crow::response(200, createSuccessResponse(response_data).dump());
        
    } catch (const std::exception& e) {
        return crow::response(500, createErrorResponse("Internal server error: " + std::string(e.what())).dump());
    }
}

json APIHandler::createErrorResponse(const std::string& error, int status_code) {
    return {
        {"success", false},
        {"error", error},
        {"status_code", status_code},
        {"timestamp", std::chrono::duration_cast<std::chrono::seconds>(
            std::chrono::system_clock::now().time_since_epoch()).count()}
    };
}

json APIHandler::createSuccessResponse(const json& data) {
    return {
        {"success", true},
        {"data", data},
        {"timestamp", std::chrono::duration_cast<std::chrono::seconds>(
            std::chrono::system_clock::now().time_since_epoch()).count()}
    };
}

bool APIHandler::validateRequest(const json& request_data) {
    return request_data.contains("file_path") && !request_data["file_path"].empty();
}

std::string APIHandler::saveUploadedFile(const crow::multipart::message& msg) {
    for (const auto& part : msg.parts) {
        if (part.headers.find("Content-Disposition") != part.headers.end()) {
            auto content_disposition = part.headers.at("Content-Disposition");
            
            // Extract filename
            size_t filename_pos = content_disposition.find("filename=");
            if (filename_pos != std::string::npos) {
                std::string filename = content_disposition.substr(filename_pos + 10);
                filename = filename.substr(0, filename.find('"', 1));
                
                // Generate unique filename
                auto now = std::chrono::system_clock::now();
                auto timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
                    now.time_since_epoch()).count();
                
                std::string unique_filename = std::to_string(timestamp) + "_" + filename;
                std::string file_path = "/tmp/ocr_uploads/" + unique_filename;
                
                // Save file
                std::ofstream file(file_path, std::ios::binary);
                if (file.is_open()) {
                    file.write(part.body.c_str(), part.body.length());
                    file.close();
                    return file_path;
                }
            }
        }
    }
    
    return "";
} 