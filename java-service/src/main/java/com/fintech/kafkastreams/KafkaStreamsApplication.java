package com.fintech.kafkastreams;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.EnableKafkaStreams;

/**
 * Main Spring Boot application for Kafka Streams Service
 * Handles real-time data processing and stream analytics
 */
@SpringBootApplication
@EnableKafka
@EnableKafkaStreams
public class KafkaStreamsApplication {

    public static void main(String[] args) {
        SpringApplication.run(KafkaStreamsApplication.class, args);
    }
} 