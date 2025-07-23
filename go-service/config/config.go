package config

import (
	"github.com/spf13/viper"
)

type Config struct {
	Server   ServerConfig   `mapstructure:"server"`
	Database DatabaseConfig `mapstructure:"database"`
	Redis    RedisConfig    `mapstructure:"redis"`
	Jaeger   JaegerConfig   `mapstructure:"jaeger"`
	Services ServicesConfig `mapstructure:"services"`
}

type ServerConfig struct {
	Port string `mapstructure:"port"`
	Host string `mapstructure:"host"`
}

type DatabaseConfig struct {
	Host     string `mapstructure:"host"`
	Port     string `mapstructure:"port"`
	User     string `mapstructure:"user"`
	Password string `mapstructure:"password"`
	DBName   string `mapstructure:"dbname"`
	SSLMode  string `mapstructure:"sslmode"`
}

type RedisConfig struct {
	Host     string `mapstructure:"host"`
	Port     string `mapstructure:"port"`
	Password string `mapstructure:"password"`
	DB       int    `mapstructure:"db"`
}

type JaegerConfig struct {
	Endpoint string `mapstructure:"endpoint"`
}

type ServicesConfig struct {
	APIGateway string `mapstructure:"api_gateway"`
	MLService  string `mapstructure:"ml_service"`
	OCRService string `mapstructure:"ocr_service"`
}

func LoadConfig() *Config {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("./config")

	// Set defaults
	setDefaults()

	// Read environment variables
	viper.AutomaticEnv()

	// Read config file
	if err := viper.ReadInConfig(); err != nil {
		// Use defaults if config file not found
	}

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		panic(err)
	}

	return &config
}

func setDefaults() {
	// Server defaults
	viper.SetDefault("server.port", "8003")
	viper.SetDefault("server.host", "0.0.0.0")

	// Database defaults
	viper.SetDefault("database.host", "postgres")
	viper.SetDefault("database.port", "5432")
	viper.SetDefault("database.user", "go_user")
	viper.SetDefault("database.password", "go_password")
	viper.SetDefault("database.dbname", "fintech_go")
	viper.SetDefault("database.sslmode", "disable")

	// Redis defaults
	viper.SetDefault("redis.host", "redis")
	viper.SetDefault("redis.port", "6379")
	viper.SetDefault("redis.password", "")
	viper.SetDefault("redis.db", 2)

	// Jaeger defaults
	viper.SetDefault("jaeger.endpoint", "http://jaeger:14268/api/traces")

	// Services defaults
	viper.SetDefault("services.api_gateway", "http://api-gateway:8000")
	viper.SetDefault("services.ml_service", "http://ml-service:8001")
	viper.SetDefault("services.ocr_service", "http://ocr-service:8002")
}
