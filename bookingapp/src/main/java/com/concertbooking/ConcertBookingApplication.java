package com.concertbooking;

import com.concertbooking.model.Concert;
import com.concertbooking.service.BookingService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;

import java.time.LocalDateTime;

@SpringBootApplication
@ComponentScan(basePackages = "com.concertbooking")
public class ConcertBookingApplication {
    public static void main(String[] args) {
        SpringApplication.run(ConcertBookingApplication.class, args);
    }
    
    @Bean
    public CommandLineRunner demo(BookingService bookingService) {
        return (args) -> {
            System.out.println("Application started successfully!");
            System.out.println("Number of concerts: " + bookingService.getAllConcerts().size());
        };
    }
} 