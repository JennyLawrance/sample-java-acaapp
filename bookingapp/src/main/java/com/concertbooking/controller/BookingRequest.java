package com.concertbooking.controller;

import lombok.Data;

@Data
public class BookingRequest {
    private String customerName;
    private String customerEmail;
    private int numberOfSeats;
} 