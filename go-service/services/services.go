package services

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
	"gorm.io/gorm"

	"fintech-ai-platform/go-service/config"
	"fintech-ai-platform/go-service/models"
)

// OrchestratorService handles task and job orchestration
type OrchestratorService struct {
	db     *gorm.DB
	logger *logrus.Logger
	config *config.Config
}

// WorkflowService handles workflow management
type WorkflowService struct {
	db     *gorm.DB
	logger *logrus.Logger
	config *config.Config
}

// NewOrchestratorService creates a new orchestrator service
func NewOrchestratorService() *OrchestratorService {
	return &OrchestratorService{
		logger: logrus.New(),
		config: config.LoadConfig(),
	}
}

// NewWorkflowService creates a new workflow service
func NewWorkflowService() *WorkflowService {
	return &WorkflowService{
		logger: logrus.New(),
		config: config.LoadConfig(),
	}
}

// Task methods

func (s *OrchestratorService) CreateTask(req models.CreateTaskRequest) (*models.Task, error) {
	task := &models.Task{
		Name:        req.Name,
		Description: req.Description,
		Type:        req.Type,
		Status:      models.StatusPending,
		Config:      req.Config,
	}

	if err := s.db.Create(task).Error; err != nil {
		return nil, err
	}

	return task, nil
}

func (s *OrchestratorService) ListTasks(page, limit int) ([]models.Task, int64, error) {
	var tasks []models.Task
	var total int64

	offset := (page - 1) * limit

	if err := s.db.Model(&models.Task{}).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if err := s.db.Offset(offset).Limit(limit).Find(&tasks).Error; err != nil {
		return nil, 0, err
	}

	return tasks, total, nil
}

func (s *OrchestratorService) GetTask(id uuid.UUID) (*models.Task, error) {
	var task models.Task
	if err := s.db.First(&task, id).Error; err != nil {
		return nil, err
	}
	return &task, nil
}

func (s *OrchestratorService) UpdateTask(id uuid.UUID, req models.CreateTaskRequest) (*models.Task, error) {
	task := &models.Task{
		Name:        req.Name,
		Description: req.Description,
		Type:        req.Type,
		Config:      req.Config,
	}

	if err := s.db.Model(&models.Task{}).Where("id = ?", id).Updates(task).Error; err != nil {
		return nil, err
	}

	return s.GetTask(id)
}

func (s *OrchestratorService) DeleteTask(id uuid.UUID) error {
	return s.db.Delete(&models.Task{}, id).Error
}

func (s *OrchestratorService) ExecuteTask(id uuid.UUID, input map[string]interface{}) (map[string]interface{}, error) {
	task, err := s.GetTask(id)
	if err != nil {
		return nil, err
	}

	// Update task status
	now := time.Now()
	task.Status = models.StatusRunning
	task.StartedAt = &now
	s.db.Save(task)

	// Execute based on task type
	var result map[string]interface{}
	switch task.Type {
	case models.TaskTypeMLPrediction:
		result, err = s.executeMLPrediction(task, input)
	case models.TaskTypeOCRExtraction:
		result, err = s.executeOCRExtraction(task, input)
	case models.TaskTypeAPICall:
		result, err = s.executeAPICall(task, input)
	case models.TaskTypeWorkflow:
		result, err = s.executeWorkflow(task, input)
	default:
		err = fmt.Errorf("unsupported task type: %s", task.Type)
	}

	// Update task with result
	completedAt := time.Now()
	task.CompletedAt = &completedAt
	if err != nil {
		task.Status = models.StatusFailed
		task.Error = err.Error()
	} else {
		task.Status = models.StatusCompleted
		resultJSON, _ := json.Marshal(result)
		task.Result = string(resultJSON)
	}
	s.db.Save(task)

	return result, err
}

// Job methods

func (s *OrchestratorService) CreateJob(req models.CreateJobRequest) (*models.Job, error) {
	job := &models.Job{
		Name:        req.Name,
		Description: req.Description,
		Type:        req.Type,
		Status:      models.StatusPending,
		Config:      req.Config,
	}

	if err := s.db.Create(job).Error; err != nil {
		return nil, err
	}

	return job, nil
}

func (s *OrchestratorService) ListJobs(page, limit int) ([]models.Job, int64, error) {
	var jobs []models.Job
	var total int64

	offset := (page - 1) * limit

	if err := s.db.Model(&models.Job{}).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if err := s.db.Offset(offset).Limit(limit).Find(&jobs).Error; err != nil {
		return nil, 0, err
	}

	return jobs, total, nil
}

func (s *OrchestratorService) GetJob(id uuid.UUID) (*models.Job, error) {
	var job models.Job
	if err := s.db.First(&job, id).Error; err != nil {
		return nil, err
	}
	return &job, nil
}

func (s *OrchestratorService) UpdateJob(id uuid.UUID, req models.CreateJobRequest) (*models.Job, error) {
	job := &models.Job{
		Name:        req.Name,
		Description: req.Description,
		Type:        req.Type,
		Config:      req.Config,
	}

	if err := s.db.Model(&models.Job{}).Where("id = ?", id).Updates(job).Error; err != nil {
		return nil, err
	}

	return s.GetJob(id)
}

func (s *OrchestratorService) DeleteJob(id uuid.UUID) error {
	return s.db.Delete(&models.Job{}, id).Error
}

func (s *OrchestratorService) StartJob(id uuid.UUID) error {
	job, err := s.GetJob(id)
	if err != nil {
		return err
	}

	job.Status = models.StatusRunning
	now := time.Now()
	job.StartedAt = &now

	if err := s.db.Save(job).Error; err != nil {
		return err
	}

	// Start job execution in background
	go s.executeJob(job)

	return nil
}

func (s *OrchestratorService) StopJob(id uuid.UUID) error {
	job, err := s.GetJob(id)
	if err != nil {
		return err
	}

	job.Status = models.StatusCancelled
	now := time.Now()
	job.CompletedAt = &now

	return s.db.Save(job).Error
}

// Workflow methods

func (s *WorkflowService) CreateWorkflow(req models.CreateWorkflowRequest) (*models.Workflow, error) {
	workflow := &models.Workflow{
		Name:        req.Name,
		Description: req.Description,
		Status:      "draft",
	}

	if err := s.db.Create(workflow).Error; err != nil {
		return nil, err
	}

	// Create workflow steps
	for _, stepReq := range req.Steps {
		step := &models.WorkflowStep{
			WorkflowID:  workflow.ID,
			Name:        stepReq.Name,
			Description: stepReq.Description,
			Order:       stepReq.Order,
			ServiceType: stepReq.ServiceType,
			Config:      stepReq.Config,
		}
		if err := s.db.Create(step).Error; err != nil {
			return nil, err
		}
	}

	return workflow, nil
}

func (s *WorkflowService) ListWorkflows(page, limit int) ([]models.Workflow, int64, error) {
	var workflows []models.Workflow
	var total int64

	offset := (page - 1) * limit

	if err := s.db.Model(&models.Workflow{}).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if err := s.db.Preload("Steps").Offset(offset).Limit(limit).Find(&workflows).Error; err != nil {
		return nil, 0, err
	}

	return workflows, total, nil
}

func (s *WorkflowService) GetWorkflow(id uuid.UUID) (*models.Workflow, error) {
	var workflow models.Workflow
	if err := s.db.Preload("Steps").First(&workflow, id).Error; err != nil {
		return nil, err
	}
	return &workflow, nil
}

func (s *WorkflowService) UpdateWorkflow(id uuid.UUID, req models.CreateWorkflowRequest) (*models.Workflow, error) {
	workflow := &models.Workflow{
		Name:        req.Name,
		Description: req.Description,
	}

	if err := s.db.Model(&models.Workflow{}).Where("id = ?", id).Updates(workflow).Error; err != nil {
		return nil, err
	}

	// Delete existing steps
	s.db.Where("workflow_id = ?", id).Delete(&models.WorkflowStep{})

	// Create new steps
	for _, stepReq := range req.Steps {
		step := &models.WorkflowStep{
			WorkflowID:  id,
			Name:        stepReq.Name,
			Description: stepReq.Description,
			Order:       stepReq.Order,
			ServiceType: stepReq.ServiceType,
			Config:      stepReq.Config,
		}
		if err := s.db.Create(step).Error; err != nil {
			return nil, err
		}
	}

	return s.GetWorkflow(id)
}

func (s *WorkflowService) DeleteWorkflow(id uuid.UUID) error {
	// Delete steps first
	if err := s.db.Where("workflow_id = ?", id).Delete(&models.WorkflowStep{}).Error; err != nil {
		return err
	}

	// Delete workflow
	return s.db.Delete(&models.Workflow{}, id).Error
}

func (s *WorkflowService) ExecuteWorkflow(id uuid.UUID, input map[string]interface{}) (map[string]interface{}, error) {
	workflow, err := s.GetWorkflow(id)
	if err != nil {
		return nil, err
	}

	result := make(map[string]interface{})
	currentInput := input

	// Execute steps in order
	for _, step := range workflow.Steps {
		stepResult, err := s.executeWorkflowStep(step, currentInput)
		if err != nil {
			return nil, fmt.Errorf("step %s failed: %w", step.Name, err)
		}

		result[step.Name] = stepResult
		currentInput = stepResult
	}

	return result, nil
}

// Helper methods

func (s *OrchestratorService) executeMLPrediction(task *models.Task, input map[string]interface{}) (map[string]interface{}, error) {
	// Call ML service
	url := fmt.Sprintf("%s/api/v1/predictions/predict", s.config.Services.MLService)

	requestBody := map[string]interface{}{
		"model_type": "document_classification",
		"input_data": input,
	}

	resp, err := http.Post(url, "application/json", nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	return result, nil
}

func (s *OrchestratorService) executeOCRExtraction(task *models.Task, input map[string]interface{}) (map[string]interface{}, error) {
	// Call OCR service
	url := fmt.Sprintf("%s/api/v1/ocr/extract", s.config.Services.OCRService)

	resp, err := http.Post(url, "application/json", nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	return result, nil
}

func (s *OrchestratorService) executeAPICall(task *models.Task, input map[string]interface{}) (map[string]interface{}, error) {
	// Execute API call based on task config
	var config map[string]interface{}
	if err := json.Unmarshal([]byte(task.Config), &config); err != nil {
		return nil, err
	}

	url := config["url"].(string)
	method := config["method"].(string)

	req, err := http.NewRequest(method, url, nil)
	if err != nil {
		return nil, err
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	return result, nil
}

func (s *OrchestratorService) executeWorkflow(task *models.Task, input map[string]interface{}) (map[string]interface{}, error) {
	// Execute workflow based on task config
	var config map[string]interface{}
	if err := json.Unmarshal([]byte(task.Config), &config); err != nil {
		return nil, err
	}

	workflowID := config["workflow_id"].(string)
	workflowUUID, err := uuid.Parse(workflowID)
	if err != nil {
		return nil, err
	}

	workflowService := NewWorkflowService()
	return workflowService.ExecuteWorkflow(workflowUUID, input)
}

func (s *OrchestratorService) executeJob(job *models.Job) {
	// Execute job logic here
	// This is a simplified implementation
	for i := 0; i <= 100; i += 10 {
		job.Progress = i
		s.db.Save(job)
		time.Sleep(1 * time.Second)
	}

	job.Status = models.StatusCompleted
	job.Progress = 100
	now := time.Now()
	job.CompletedAt = &now
	s.db.Save(job)
}

func (s *WorkflowService) executeWorkflowStep(step *models.WorkflowStep, input map[string]interface{}) (map[string]interface{}, error) {
	switch step.ServiceType {
	case "ml":
		return s.executeMLStep(step, input)
	case "ocr":
		return s.executeOCRStep(step, input)
	case "api":
		return s.executeAPIStep(step, input)
	default:
		return input, nil
	}
}

func (s *WorkflowService) executeMLStep(step *models.WorkflowStep, input map[string]interface{}) (map[string]interface{}, error) {
	// Call ML service
	url := fmt.Sprintf("%s/api/v1/predictions/predict", s.config.Services.MLService)

	requestBody := map[string]interface{}{
		"model_type": "document_classification",
		"input_data": input,
	}

	resp, err := http.Post(url, "application/json", nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	return result, nil
}

func (s *WorkflowService) executeOCRStep(step *models.WorkflowStep, input map[string]interface{}) (map[string]interface{}, error) {
	// Call OCR service
	url := fmt.Sprintf("%s/api/v1/ocr/extract", s.config.Services.OCRService)

	resp, err := http.Post(url, "application/json", nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	return result, nil
}

func (s *WorkflowService) executeAPIStep(step *models.WorkflowStep, input map[string]interface{}) (map[string]interface{}, error) {
	// Execute API call based on step config
	var config map[string]interface{}
	if err := json.Unmarshal([]byte(step.Config), &config); err != nil {
		return nil, err
	}

	url := config["url"].(string)
	method := config["method"].(string)

	req, err := http.NewRequest(method, url, nil)
	if err != nil {
		return nil, err
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	return result, nil
}
