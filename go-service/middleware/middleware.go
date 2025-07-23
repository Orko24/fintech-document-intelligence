package middleware

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/sirupsen/logrus"
)

var (
	httpRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint", "status"},
	)

	httpRequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "Duration of HTTP requests",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "endpoint"},
	)
)

// Logger middleware for request logging
func Logger(logger *logrus.Logger) gin.HandlerFunc {
	return gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
		logger.WithFields(logrus.Fields{
			"timestamp": param.TimeStamp.Format(time.RFC3339),
			"status":    param.StatusCode,
			"latency":   param.Latency,
			"client_ip": param.ClientIP,
			"method":    param.Method,
			"path":      param.Path,
			"error":     param.ErrorMessage,
		}).Info("HTTP Request")

		return ""
	})
}

// CORS middleware
func CORS() gin.HandlerFunc {
	return gin.HandlerFunc(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Credentials", "true")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Header("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})
}

// Metrics middleware for Prometheus metrics
func Metrics() gin.HandlerFunc {
	return gin.HandlerFunc(func(c *gin.Context) {
		start := time.Now()

		c.Next()

		duration := time.Since(start).Seconds()

		httpRequestsTotal.WithLabelValues(
			c.Request.Method,
			c.FullPath(),
			string(rune(c.Writer.Status())),
		).Inc()

		httpRequestDuration.WithLabelValues(
			c.Request.Method,
			c.FullPath(),
		).Observe(duration)
	})
}

// Auth middleware for API key authentication
func Auth() gin.HandlerFunc {
	return gin.HandlerFunc(func(c *gin.Context) {
		apiKey := c.GetHeader("X-API-Key")
		if apiKey == "" {
			c.JSON(401, gin.H{"error": "API key required"})
			c.Abort()
			return
		}

		// In production, validate against database or external service
		if apiKey != "go-service-key" {
			c.JSON(401, gin.H{"error": "Invalid API key"})
			c.Abort()
			return
		}

		c.Next()
	})
}

// RateLimit middleware for request rate limiting
func RateLimit(limit int) gin.HandlerFunc {
	// Simple in-memory rate limiter
	// In production, use Redis or similar
	clients := make(map[string]int)

	return gin.HandlerFunc(func(c *gin.Context) {
		clientIP := c.ClientIP()

		if clients[clientIP] >= limit {
			c.JSON(429, gin.H{"error": "Rate limit exceeded"})
			c.Abort()
			return
		}

		clients[clientIP]++

		// Reset counter after 1 minute
		go func() {
			time.Sleep(time.Minute)
			clients[clientIP] = 0
		}()

		c.Next()
	})
}
