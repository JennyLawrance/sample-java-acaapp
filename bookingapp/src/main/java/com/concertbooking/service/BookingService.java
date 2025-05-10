package com.concertbooking.service;

import com.concertbooking.exception.SoldOutException;
import com.concertbooking.model.Booking;
import com.concertbooking.model.Concert;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class BookingService {
    private List<Concert> concerts;
    private List<Booking> bookings;

    public BookingService() {
        this.concerts = new ArrayList<>();
        this.bookings = new ArrayList<>();
    }

    @PostConstruct
    public void init() {
        // Add sample concerts
        addConcert(new Concert("C1", "Summer Festival", "The Rock Band",
                LocalDateTime.now().plusDays(30), "Central Stadium", 50.0, 1000));
        addConcert(new Concert("C2", "Jazz Night", "The Jazz Quartet",
                LocalDateTime.now().plusDays(15), "City Hall", 75.0, 500));
        addConcert(new Concert("C3", "Pop Extravaganza", "Star Pop Group",
                LocalDateTime.now().plusDays(45), "Dome Arena", 85.0, 2000));
        addConcert(new Concert("C4", "Classical Evening", "Symphony Orchestra",
                LocalDateTime.now().plusDays(10), "Opera House", 95.0, 300));
        
        // Add a sold-out concert for testing
        Concert soldOutConcert = new Concert("C5", "Acoustic Unplugged", "Indie Artists Collective",
                LocalDateTime.now().plusDays(5), "Intimate Theater", 40.0, 100);
        
        // Simulate this concert being sold out by adding bookings
        for (int i = 0; i < 100; i++) {
            soldOutConcert.addBooking(new Booking("C5", "Test Customer " + i,
                    "customer" + i + "@example.com", 1, 40.0));
        }
        
        addConcert(soldOutConcert);
    }

    public void addConcert(Concert concert) {
        concerts.add(concert);
    }

    public List<Concert> getAllConcerts() {
        return new ArrayList<>(concerts);
    }

    public Optional<Concert> getConcertById(String id) {
        return concerts.stream()
                .filter(concert -> concert.getId().equals(id))
                .findFirst();
    }

    public boolean isConcertSoldOut(String concertId) {
        Optional<Concert> concertOpt = getConcertById(concertId);
        if (!concertOpt.isPresent()) {
            return false;
        }
        
        Concert concert = concertOpt.get();
        int bookedSeats = concert.getBookings().stream()
                .mapToInt(Booking::getNumberOfSeats)
                .sum();
        
        return bookedSeats >= concert.getTotalSeats();
    }

    public Booking bookTickets(String concertId, String customerName, String customerEmail, int numberOfSeats) {
        Optional<Concert> concertOpt = getConcertById(concertId);
        
        if (!concertOpt.isPresent()) {
            throw new IllegalArgumentException("Concert not found");
        }

        Concert concert = concertOpt.get();
        
        // Check if the concert is sold out
        if (isConcertSoldOut(concertId)) {
            throw new SoldOutException(concertId, concert.getName());
        }
        
        if (!concert.isAvailable(numberOfSeats)) {
            throw new IllegalStateException("Not enough seats available");
        }

        Booking booking = new Booking(concertId, customerName, customerEmail, numberOfSeats, concert.getPrice());
        concert.addBooking(booking);
        bookings.add(booking);
        
        return booking;
    }

    public List<Booking> getBookingsByConcertId(String concertId) {
        return bookings.stream()
                .filter(booking -> booking.getConcertId().equals(concertId))
                .collect(Collectors.toList());
    }

    public List<Booking> getBookingsByCustomerEmail(String customerEmail) {
        return bookings.stream()
                .filter(booking -> booking.getCustomerEmail().equals(customerEmail))
                .collect(Collectors.toList());
    }
} 