package com.concertbooking.model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class Concert {
    private String id;
    private String name;
    private String artist;
    private LocalDateTime dateTime;
    private String venue;
    private double price;
    private int totalSeats;
    private List<Booking> bookings;

    public Concert(String id, String name, String artist, LocalDateTime dateTime, String venue, double price, int totalSeats) {
        this.id = id;
        this.name = name;
        this.artist = artist;
        this.dateTime = dateTime;
        this.venue = venue;
        this.price = price;
        this.totalSeats = totalSeats;
        this.bookings = new ArrayList<>();
    }

    public boolean isAvailable(int requestedSeats) {
        int bookedSeats = bookings.stream()
                .mapToInt(Booking::getNumberOfSeats)
                .sum();
        return (totalSeats - bookedSeats) >= requestedSeats;
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getArtist() {
        return artist;
    }

    public LocalDateTime getDateTime() {
        return dateTime;
    }

    public String getVenue() {
        return venue;
    }

    public double getPrice() {
        return price;
    }

    public int getTotalSeats() {
        return totalSeats;
    }

    public List<Booking> getBookings() {
        return bookings;
    }

    public void addBooking(Booking booking) {
        bookings.add(booking);
    }
} 