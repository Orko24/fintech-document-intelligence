#include <iostream>
#include <memory>
#include <signal.h>
#include <crow.h>
#include <nlohmann/json.hpp>

#include "ocr_engine.h"
#include "api_handler.h"

using json = nlohmann::json;

std::unique_ptr<OCREngine> ocr_engine;
std::unique_ptr<APIHandler> api_handler;

void signal_handler(int signal) {
    std::cout << "Received signal " << signal << ", shutting down..." << std::endl;
    exit(0);
}

int main() {
    // Set up signal handling
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    try {
        // Initialize OCR engine
        ocr_engine = std::make_unique<OCREngine>();
        if (!ocr_engine->initialize()) {
            std::cerr << "Failed to initialize OCR engine" << std::endl;
            return 1;
        }

        // Initialize API handler
        api_handler = std::make_unique<APIHandler>(*ocr_engine);

        // Create Crow app
        crow::SimpleApp app;

        // Health check endpoint
        CROW_ROUTE(app, "/health")
        ([]() {
            json response = {
                {"status", "healthy"},
                {"service", "ocr-service"},
                {"version", "1.0.0"}
            };
            return crow::response(response.dump());
        });

        // OCR extraction endpoint
        CROW_ROUTE(app, "/api/v1/ocr/extract")
        .methods("POST"_method)
        ([&](const crow::request& req) {
            return api_handler->handleExtractRequest(req);
        });

        // Text extraction endpoint
        CROW_ROUTE(app, "/api/v1/ocr/text")
        .methods("POST"_method)
        ([&](const crow::request& req) {
            return api_handler->handleTextExtraction(req);
        });

        // Document analysis endpoint
        CROW_ROUTE(app, "/api/v1/ocr/analyze")
        .methods("POST"_method)
        ([&](const crow::request& req) {
            return api_handler->handleDocumentAnalysis(req);
        });

        // Batch processing endpoint
        CROW_ROUTE(app, "/api/v1/ocr/batch")
        .methods("POST"_method)
        ([&](const crow::request& req) {
            return api_handler->handleBatchProcessing(req);
        });

        // Set up CORS
        app.handle_all().methods("OPTIONS"_method)
        ([](const crow::request&) {
            crow::response res;
            res.add_header("Access-Control-Allow-Origin", "*");
            res.add_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
            res.add_header("Access-Control-Allow-Headers", "Content-Type, Authorization");
            return res;
        });

        // Start server
        std::cout << "Starting OCR Service on port 8002..." << std::endl;
        app.port(8002).multithreaded().run();

    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }

    return 0;
} 