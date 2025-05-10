package com.concertbooking.model;

import java.time.LocalDateTime;
import java.util.UUID;

public class Booking {
    private String id;
    private String concertId;
    private String customerName;
    private String customerEmail;
    private int numberOfSeats;
    private LocalDateTime bookingTime;
    private double totalPrice;

    public Booking(String concertId, String customerName, String customerEmail, int numberOfSeats, double pricePerSeat) {
        this.id = UUID.randomUUID().toString();
        this.concertId = concertId;
        this.customerName = customerName;
        this.customerEmail = customerEmail;
        this.numberOfSeats = numberOfSeats;
        this.bookingTime = LocalDateTime.now();
        this.totalPrice = numberOfSeats * pricePerSeat;
    }

    // Getters
    public String getId() {
        return id;
    }

    public String getConcertId() {
        return concertId;
    }

    public String getCustomerName() {
        return customerName;
    }

    public String getCustomerEmail() {
        return customerEmail;
    }

    public int getNumberOfSeats() {
        return numberOfSeats;
    }

    public LocalDateTime getBookingTime() {
        return bookingTime;
    }

    public double getTotalPrice() {
        return totalPrice;
    }
} 