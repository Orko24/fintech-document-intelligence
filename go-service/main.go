package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
	"github.com/spf13/viper"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/jaeger"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"

	"fintech-ai-platform/go-service/config"
	"fintech-ai-platform/go-service/handlers"
	"fintech-ai-platform/go-service/middleware"
	"fintech-ai-platform/go-service/services"
)

var logger = logrus.New()

func initTracer() (*sdktrace.TracerProvider, error) {
	exp, err := jaeger.New(jaeger.WithCollectorEndpoint(jaeger.WithEndpoint(viper.GetString("jaeger.endpoint"))))
	if err != nil {
		return nil, err
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exp),
		sdktrace.WithResource(resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceName("go-service"),
		)),
	)
	otel.SetTracerProvider(tp)
	return tp, nil
}

func main() {
	// Load configuration
	config.LoadConfig()

	// Initialize tracer
	tp, err := initTracer()
	if err != nil {
		logger.Fatal("Failed to initialize tracer:", err)
	}
	defer func() {
		if err := tp.Shutdown(context.Background()); err != nil {
			logger.Printf("Error shutting down tracer provider: %v", err)
		}
	}()

	// Initialize services
	orchestratorService := services.NewOrchestratorService()
	workflowService := services.NewWorkflowService()

	// Setup Gin router
	gin.SetMode(gin.ReleaseMode)
	router := gin.New()

	// Add middleware
	router.Use(gin.Recovery())
	router.Use(middleware.Logger(logger))
	router.Use(middleware.CORS())
	router.Use(middleware.Metrics())

	// Setup routes
	setupRoutes(router, orchestratorService, workflowService)

	// Create server
	srv := &http.Server{
		Addr:    ":" + viper.GetString("server.port"),
		Handler: router,
	}

	// Start server in a goroutine
	go func() {
		logger.Info("Starting Go Service on port", viper.GetString("server.port"))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Info("Shutting down server...")

	// Give outstanding requests a deadline for completion
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("Server forced to shutdown:", err)
	}

	logger.Info("Server exiting")
}

func setupRoutes(router *gin.Engine, orchestratorService *services.OrchestratorService, workflowService *services.WorkflowService) {
	// Health check
	router.GET("/health", handlers.HealthCheck)

	// API v1 routes
	v1 := router.Group("/api/v1")
	{
		// Workflow routes
		workflows := v1.Group("/workflows")
		{
			workflows.POST("/", handlers.CreateWorkflow(workflowService))
			workflows.GET("/", handlers.ListWorkflows(workflowService))
			workflows.GET("/:id", handlers.GetWorkflow(workflowService))
			workflows.PUT("/:id", handlers.UpdateWorkflow(workflowService))
			workflows.DELETE("/:id", handlers.DeleteWorkflow(workflowService))
			workflows.POST("/:id/execute", handlers.ExecuteWorkflow(workflowService))
		}

		// Orchestration routes
		orchestration := v1.Group("/orchestration")
		{
			orchestration.POST("/tasks", handlers.CreateTask(orchestratorService))
			orchestration.GET("/tasks", handlers.ListTasks(orchestratorService))
			orchestration.GET("/tasks/:id", handlers.GetTask(orchestratorService))
			orchestration.PUT("/tasks/:id", handlers.UpdateTask(orchestratorService))
			orchestration.DELETE("/tasks/:id", handlers.DeleteTask(orchestratorService))
			orchestration.POST("/tasks/:id/execute", handlers.ExecuteTask(orchestratorService))
		}

		// Job routes
		jobs := v1.Group("/jobs")
		{
			jobs.POST("/", handlers.CreateJob(orchestratorService))
			jobs.GET("/", handlers.ListJobs(orchestratorService))
			jobs.GET("/:id", handlers.GetJob(orchestratorService))
			jobs.PUT("/:id", handlers.UpdateJob(orchestratorService))
			jobs.DELETE("/:id", handlers.DeleteJob(orchestratorService))
			jobs.POST("/:id/start", handlers.StartJob(orchestratorService))
			jobs.POST("/:id/stop", handlers.StopJob(orchestratorService))
		}
	}
}
