#pragma once

#include <crow.h>
#include <nlohmann/json.hpp>
#include "ocr_engine.h"

using json = nlohmann::json;

class APIHandler {
public:
    explicit APIHandler(OCREngine& engine);
    
    // Request handlers
    crow::response handleExtractRequest(const crow::request& req);
    crow::response handleTextExtraction(const crow::request& req);
    crow::response handleDocumentAnalysis(const crow::request& req);
    crow::response handleBatchProcessing(const crow::request& req);
    
private:
    OCREngine& ocr_engine_;
    
    // Helper methods
    json createErrorResponse(const std::string& error, int status_code = 400);
    json createSuccessResponse(const json& data);
    bool validateRequest(const json& request_data);
    std::string saveUploadedFile(const crow::multipart::message& msg);
}; 