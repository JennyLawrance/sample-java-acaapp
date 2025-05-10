package com.concertbooking.controller;

import com.concertbooking.exception.SoldOutException;
import com.concertbooking.model.Booking;
import com.concertbooking.model.Concert;
import com.concertbooking.service.BookingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@Controller
@RequestMapping("/concerts")
public class ConcertController {

    private final BookingService bookingService;

    @Autowired
    public ConcertController(BookingService bookingService) {
        this.bookingService = bookingService;
    }

    @GetMapping
    public String listConcerts(Model model) {
        List<Concert> concerts = bookingService.getAllConcerts();
        model.addAttribute("concerts", concerts);
        return "concerts";
    }

    @GetMapping("/{id}")
    public String getConcert(@PathVariable String id, Model model) {
        Optional<Concert> concertOpt = bookingService.getConcertById(id);
        if (!concertOpt.isPresent()) {
            return "redirect:/concerts";
        }
        
        Concert concert = concertOpt.get();
        List<Booking> bookings = bookingService.getBookingsByConcertId(id);
        
        model.addAttribute("concert", concert);
        model.addAttribute("bookings", bookings);
        
        return "concert-details";
    }

    @GetMapping("/book/{id}")
    public String showBookingForm(@PathVariable String id, Model model) {
        Optional<Concert> concertOpt = bookingService.getConcertById(id);
        if (!concertOpt.isPresent()) {
            return "redirect:/concerts";
        }
        
        // Check if the concert is sold out
        if (bookingService.isConcertSoldOut(id)) {
            model.addAttribute("error", "This concert is sold out!");
            return "booking-error";
        }
        
        model.addAttribute("concert", concertOpt.get());
        model.addAttribute("booking", new BookingRequest());
        
        return "booking-form";
    }

    @PostMapping("/book/{id}")
    public String bookTickets(@PathVariable String id, @ModelAttribute BookingRequest bookingRequest, Model model) {
        try {
            Booking booking = bookingService.bookTickets(
                id,
                bookingRequest.getCustomerName(),
                bookingRequest.getCustomerEmail(),
                bookingRequest.getNumberOfSeats()
            );
            model.addAttribute("booking", booking);
            return "booking-success";
        } catch (SoldOutException e) {
            model.addAttribute("error", "Sorry, this concert is sold out!");
            model.addAttribute("concertName", e.getConcertName());
            return "booking-error";
        } catch (IllegalArgumentException | IllegalStateException e) {
            model.addAttribute("error", e.getMessage());
            return "booking-error";
        }
    }

    @GetMapping("/bookings/customer")
    public String getCustomerBookings(@RequestParam String email, Model model) {
        List<Booking> bookings = bookingService.getBookingsByCustomerEmail(email);
        model.addAttribute("bookings", bookings);
        model.addAttribute("email", email);
        return "customer-bookings";
    }
} 