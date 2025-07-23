package com.fintech.kafkastreams.model;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Transaction model for financial data processing
 */
public class Transaction {
    
    @JsonProperty("id")
    private UUID id;
    
    @JsonProperty("account_id")
    private String accountId;
    
    @JsonProperty("transaction_type")
    private TransactionType transactionType;
    
    @JsonProperty("amount")
    private BigDecimal amount;
    
    @JsonProperty("currency")
    private String currency;
    
    @JsonProperty("description")
    private String description;
    
    @JsonProperty("merchant")
    private String merchant;
    
    @JsonProperty("location")
    private String location;
    
    @JsonProperty("timestamp")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime timestamp;
    
    @JsonProperty("status")
    private TransactionStatus status;
    
    @JsonProperty("risk_score")
    private Double riskScore;
    
    @JsonProperty("category")
    private String category;
    
    @JsonProperty("tags")
    private String[] tags;

    // Constructors
    public Transaction() {
        this.id = UUID.randomUUID();
        this.timestamp = LocalDateTime.now();
        this.status = TransactionStatus.PENDING;
    }

    public Transaction(String accountId, TransactionType transactionType, BigDecimal amount, String currency) {
        this();
        this.accountId = accountId;
        this.transactionType = transactionType;
        this.amount = amount;
        this.currency = currency;
    }

    // Getters and Setters
    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getAccountId() {
        return accountId;
    }

    public void setAccountId(String accountId) {
        this.accountId = accountId;
    }

    public TransactionType getTransactionType() {
        return transactionType;
    }

    public void setTransactionType(TransactionType transactionType) {
        this.transactionType = transactionType;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }

    public String getCurrency() {
        return currency;
    }

    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getMerchant() {
        return merchant;
    }

    public void setMerchant(String merchant) {
        this.merchant = merchant;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }

    public TransactionStatus getStatus() {
        return status;
    }

    public void setStatus(TransactionStatus status) {
        this.status = status;
    }

    public Double getRiskScore() {
        return riskScore;
    }

    public void setRiskScore(Double riskScore) {
        this.riskScore = riskScore;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String[] getTags() {
        return tags;
    }

    public void setTags(String[] tags) {
        this.tags = tags;
    }

    @Override
    public String toString() {
        return "Transaction{" +
                "id=" + id +
                ", accountId='" + accountId + '\'' +
                ", transactionType=" + transactionType +
                ", amount=" + amount +
                ", currency='" + currency + '\'' +
                ", timestamp=" + timestamp +
                ", status=" + status +
                '}';
    }

    /**
     * Transaction types
     */
    public enum TransactionType {
        DEBIT, CREDIT, TRANSFER, WITHDRAWAL, DEPOSIT, PAYMENT, REFUND
    }

    /**
     * Transaction status
     */
    public enum TransactionStatus {
        PENDING, PROCESSING, COMPLETED, FAILED, CANCELLED, SUSPICIOUS
    }
} 