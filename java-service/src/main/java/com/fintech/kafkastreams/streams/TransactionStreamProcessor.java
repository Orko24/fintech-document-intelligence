package com.fintech.kafkastreams.streams;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.kafkastreams.model.Transaction;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.kstream.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.EnableKafkaStreams;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.Map;

/**
 * Kafka Streams processor for real-time transaction processing
 */
@Component
@EnableKafkaStreams
public class TransactionStreamProcessor {

    private static final Logger logger = LoggerFactory.getLogger(TransactionStreamProcessor.class);

    @Value("${kafka.topics.transactions.input}")
    private String inputTopic;

    @Value("${kafka.topics.transactions.processed}")
    private String processedTopic;

    @Value("${kafka.topics.transactions.suspicious}")
    private String suspiciousTopic;

    @Value("${kafka.topics.transactions.aggregated}")
    private String aggregatedTopic;

    @Value("${kafka.topics.transactions.alerts}")
    private String alertsTopic;

    private final ObjectMapper objectMapper;

    @Autowired
    public TransactionStreamProcessor(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    /**
     * Build the Kafka Streams topology
     */
    @Autowired
    public void buildPipeline(StreamsBuilder streamsBuilder) {
        // Create Serdes for JSON serialization
        Serde<String> stringSerde = Serdes.String();
        Serde<Transaction> transactionSerde = createTransactionSerde();

        // Create the main stream from input topic
        KStream<String, Transaction> transactionStream = streamsBuilder
                .stream(inputTopic, Consumed.with(stringSerde, transactionSerde));

        // Process transactions and detect suspicious activity
        KStream<String, Transaction> processedStream = transactionStream
                .filter((key, transaction) -> transaction != null)
                .mapValues(this::enrichTransaction)
                .mapValues(this::calculateRiskScore)
                .filter((key, transaction) -> transaction.getRiskScore() != null);

        // Split stream based on risk score
        KStream<String, Transaction>[] branches = processedStream.branch(
                (key, transaction) -> transaction.getRiskScore() > 0.7, // High risk
                (key, transaction) -> transaction.getRiskScore() > 0.3, // Medium risk
                (key, transaction) -> true // Low risk
        );

        // Send high-risk transactions to suspicious topic
        branches[0].to(suspiciousTopic, Produced.with(stringSerde, transactionSerde));

        // Send processed transactions to output topic
        processedStream.to(processedTopic, Produced.with(stringSerde, transactionSerde));

        // Create windowed aggregations
        createWindowedAggregations(streamsBuilder, stringSerde, transactionSerde);

        // Create real-time alerts
        createAlerts(streamsBuilder, stringSerde, transactionSerde);

        logger.info("Kafka Streams topology built successfully");
    }

    /**
     * Enrich transaction with additional data
     */
    private Transaction enrichTransaction(Transaction transaction) {
        // Add category based on merchant and description
        if (transaction.getCategory() == null) {
            transaction.setCategory(categorizeTransaction(transaction));
        }

        // Add tags based on transaction characteristics
        if (transaction.getTags() == null) {
            transaction.setTags(generateTags(transaction));
        }

        return transaction;
    }

    /**
     * Calculate risk score for transaction
     */
    private Transaction calculateRiskScore(Transaction transaction) {
        double riskScore = 0.0;

        // Amount-based risk
        if (transaction.getAmount().compareTo(new BigDecimal("10000")) > 0) {
            riskScore += 0.3;
        } else if (transaction.getAmount().compareTo(new BigDecimal("1000")) > 0) {
            riskScore += 0.1;
        }

        // Location-based risk
        if (transaction.getLocation() != null && 
            transaction.getLocation().toLowerCase().contains("international")) {
            riskScore += 0.2;
        }

        // Time-based risk (night transactions)
        int hour = transaction.getTimestamp().getHour();
        if (hour < 6 || hour > 22) {
            riskScore += 0.1;
        }

        // Merchant-based risk
        if (transaction.getMerchant() != null) {
            String merchant = transaction.getMerchant().toLowerCase();
            if (merchant.contains("gambling") || merchant.contains("casino")) {
                riskScore += 0.4;
            } else if (merchant.contains("crypto") || merchant.contains("bitcoin")) {
                riskScore += 0.3;
            }
        }

        // Frequency-based risk (would need state store for this in real implementation)
        // For now, just a placeholder

        transaction.setRiskScore(Math.min(riskScore, 1.0));
        return transaction;
    }

    /**
     * Create windowed aggregations for analytics
     */
    private void createWindowedAggregations(StreamsBuilder streamsBuilder, 
                                          Serde<String> stringSerde, 
                                          Serde<Transaction> transactionSerde) {
        
        // 5-minute window for transaction counts
        KTable<Windowed<String>, Long> transactionCounts = streamsBuilder
                .stream(inputTopic, Consumed.with(stringSerde, transactionSerde))
                .groupBy((key, transaction) -> transaction.getAccountId())
                .windowedBy(TimeWindows.of(Duration.ofMinutes(5)))
                .count();

        // 1-hour window for amount aggregations
        KTable<Windowed<String>, BigDecimal> totalAmounts = streamsBuilder
                .stream(inputTopic, Consumed.with(stringSerde, transactionSerde))
                .groupBy((key, transaction) -> transaction.getAccountId())
                .windowedBy(TimeWindows.of(Duration.ofHours(1)))
                .aggregate(
                        () -> BigDecimal.ZERO,
                        (key, transaction, total) -> total.add(transaction.getAmount()),
                        Materialized.with(stringSerde, Serdes.serdeFrom(new BigDecimalSerializer(), new BigDecimalDeserializer()))
                );

        // Send aggregated data to output topic
        transactionCounts.toStream()
                .map((key, value) -> KeyValue.pair(key.key(), 
                    String.format("{\"account_id\":\"%s\",\"window_start\":\"%s\",\"transaction_count\":%d}", 
                        key.key(), key.window().startTime(), value)))
                .to(aggregatedTopic, Produced.with(stringSerde, stringSerde));
    }

    /**
     * Create real-time alerts
     */
    private void createAlerts(StreamsBuilder streamsBuilder, 
                            Serde<String> stringSerde, 
                            Serde<Transaction> transactionSerde) {
        
        // High-value transaction alerts
        streamsBuilder
                .stream(inputTopic, Consumed.with(stringSerde, transactionSerde))
                .filter((key, transaction) -> 
                    transaction.getAmount().compareTo(new BigDecimal("5000")) > 0)
                .mapValues(transaction -> String.format(
                    "{\"alert_type\":\"high_value_transaction\",\"account_id\":\"%s\",\"amount\":%s,\"timestamp\":\"%s\"}",
                    transaction.getAccountId(), transaction.getAmount(), transaction.getTimestamp()))
                .to(alertsTopic, Produced.with(stringSerde, stringSerde));

        // Rapid transaction alerts (would need state store for frequency tracking)
        // Placeholder for now
    }

    /**
     * Categorize transaction based on merchant and description
     */
    private String categorizeTransaction(Transaction transaction) {
        String merchant = transaction.getMerchant() != null ? transaction.getMerchant().toLowerCase() : "";
        String description = transaction.getDescription() != null ? transaction.getDescription().toLowerCase() : "";

        if (merchant.contains("grocery") || merchant.contains("supermarket") || description.contains("food")) {
            return "FOOD_AND_GROCERIES";
        } else if (merchant.contains("gas") || merchant.contains("fuel") || description.contains("gasoline")) {
            return "TRANSPORTATION";
        } else if (merchant.contains("amazon") || merchant.contains("walmart") || description.contains("shopping")) {
            return "SHOPPING";
        } else if (merchant.contains("restaurant") || merchant.contains("cafe") || description.contains("dining")) {
            return "DINING";
        } else if (merchant.contains("hotel") || merchant.contains("airbnb") || description.contains("travel")) {
            return "TRAVEL";
        } else if (merchant.contains("netflix") || merchant.contains("spotify") || description.contains("entertainment")) {
            return "ENTERTAINMENT";
        } else {
            return "OTHER";
        }
    }

    /**
     * Generate tags for transaction
     */
    private String[] generateTags(Transaction transaction) {
        // Simple tag generation based on transaction characteristics
        // In a real implementation, this could be more sophisticated
        return new String[]{"processed", "risk_assessed"};
    }

    /**
     * Create Serde for Transaction objects
     */
    private Serde<Transaction> createTransactionSerde() {
        // In a real implementation, you'd want to create a proper JSON Serde
        // For now, using String Serde and manual serialization
        return Serdes.String().mapValues(
            value -> {
                try {
                    return objectMapper.readValue(value, Transaction.class);
                } catch (Exception e) {
                    logger.error("Error deserializing transaction", e);
                    return null;
                }
            },
            transaction -> {
                try {
                    return objectMapper.writeValueAsString(transaction);
                } catch (Exception e) {
                    logger.error("Error serializing transaction", e);
                    return null;
                }
            }
        );
    }

    // Custom serializers for BigDecimal (simplified)
    private static class BigDecimalSerializer implements org.apache.kafka.common.serialization.Serializer<BigDecimal> {
        @Override
        public byte[] serialize(String topic, BigDecimal data) {
            return data != null ? data.toString().getBytes() : null;
        }
    }

    private static class BigDecimalDeserializer implements org.apache.kafka.common.serialization.Deserializer<BigDecimal> {
        @Override
        public BigDecimal deserialize(String topic, byte[] data) {
            return data != null ? new BigDecimal(new String(data)) : null;
        }
    }
} 