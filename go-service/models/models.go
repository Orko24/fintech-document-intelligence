package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Workflow represents a business workflow
type Workflow struct {
	ID          uuid.UUID      `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	Name        string         `json:"name" gorm:"not null"`
	Description string         `json:"description"`
	Steps       []WorkflowStep `json:"steps" gorm:"foreignKey:WorkflowID"`
	Status      string         `json:"status" gorm:"default:'draft'"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"deleted_at,omitempty" gorm:"index"`
}

// WorkflowStep represents a step in a workflow
type WorkflowStep struct {
	ID          uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	WorkflowID  uuid.UUID `json:"workflow_id" gorm:"type:uuid;not null"`
	Name        string    `json:"name" gorm:"not null"`
	Description string    `json:"description"`
	Order       int       `json:"order" gorm:"not null"`
	ServiceType string    `json:"service_type" gorm:"not null"` // ml, ocr, api, etc.
	Config      string    `json:"config" gorm:"type:jsonb"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// Task represents an executable task
type Task struct {
	ID          uuid.UUID      `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	Name        string         `json:"name" gorm:"not null"`
	Description string         `json:"description"`
	Type        string         `json:"type" gorm:"not null"` // workflow, ml_prediction, ocr_extraction, etc.
	Status      string         `json:"status" gorm:"default:'pending'"`
	Config      string         `json:"config" gorm:"type:jsonb"`
	Result      string         `json:"result" gorm:"type:jsonb"`
	Error       string         `json:"error"`
	StartedAt   *time.Time     `json:"started_at"`
	CompletedAt *time.Time     `json:"completed_at"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"deleted_at,omitempty" gorm:"index"`
}

// Job represents a long-running job
type Job struct {
	ID          uuid.UUID      `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	Name        string         `json:"name" gorm:"not null"`
	Description string         `json:"description"`
	Type        string         `json:"type" gorm:"not null"`
	Status      string         `json:"status" gorm:"default:'pending'"`
	Config      string         `json:"config" gorm:"type:jsonb"`
	Progress    int            `json:"progress" gorm:"default:0"`
	Result      string         `json:"result" gorm:"type:jsonb"`
	Error       string         `json:"error"`
	StartedAt   *time.Time     `json:"started_at"`
	CompletedAt *time.Time     `json:"completed_at"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"deleted_at,omitempty" gorm:"index"`
}

// TaskExecution represents a task execution
type TaskExecution struct {
	ID        uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	TaskID    uuid.UUID  `json:"task_id" gorm:"type:uuid;not null"`
	Status    string     `json:"status" gorm:"not null"`
	Result    string     `json:"result" gorm:"type:jsonb"`
	Error     string     `json:"error"`
	StartedAt time.Time  `json:"started_at"`
	EndedAt   *time.Time `json:"ended_at"`
	CreatedAt time.Time  `json:"created_at"`
}

// Request/Response models

type CreateWorkflowRequest struct {
	Name        string              `json:"name" binding:"required"`
	Description string              `json:"description"`
	Steps       []CreateStepRequest `json:"steps"`
}

type CreateStepRequest struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description"`
	Order       int    `json:"order" binding:"required"`
	ServiceType string `json:"service_type" binding:"required"`
	Config      string `json:"config"`
}

type CreateTaskRequest struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description"`
	Type        string `json:"type" binding:"required"`
	Config      string `json:"config"`
}

type CreateJobRequest struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description"`
	Type        string `json:"type" binding:"required"`
	Config      string `json:"config"`
}

type ExecuteWorkflowRequest struct {
	Input map[string]interface{} `json:"input"`
}

type ExecuteTaskRequest struct {
	Input map[string]interface{} `json:"input"`
}

// Status constants
const (
	StatusPending   = "pending"
	StatusRunning   = "running"
	StatusCompleted = "completed"
	StatusFailed    = "failed"
	StatusCancelled = "cancelled"
)

// Task types
const (
	TaskTypeWorkflow      = "workflow"
	TaskTypeMLPrediction  = "ml_prediction"
	TaskTypeOCRExtraction = "ocr_extraction"
	TaskTypeAPICall       = "api_call"
	TaskTypeDataTransform = "data_transform"
)
