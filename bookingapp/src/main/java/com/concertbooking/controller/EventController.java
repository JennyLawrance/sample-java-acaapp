package com.concertbooking.controller;

import com.concertbooking.exception.SoldOutException;
import com.concertbooking.model.Concert;
import com.concertbooking.service.BookingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Controller
@RequestMapping("/events")
public class EventController {

    private final BookingService bookingService;
    private final DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private final DateTimeFormatter timeFormatter = DateTimeFormatter.ofPattern("HH:mm");

    @Autowired
    public EventController(BookingService bookingService) {
        this.bookingService = bookingService;
    }

    @GetMapping
    public String listEvents(Model model) {
        List<Concert> concerts = bookingService.getAllConcerts();
        
        // Group concerts by date for calendar view
        Map<String, List<Concert>> concertsByDate = concerts.stream()
                .collect(Collectors.groupingBy(concert -> 
                    concert.getDateTime().format(dateFormatter)));
        
        model.addAttribute("concertsByDate", concertsByDate);
        model.addAttribute("dateFormatter", dateFormatter);
        model.addAttribute("timeFormatter", timeFormatter);
        model.addAttribute("now", LocalDateTime.now());
        
        return "events";
    }
    
    @GetMapping("/{id}")
    public String getEventDetails(@PathVariable String id, Model model) {
        Optional<Concert> concertOpt = bookingService.getConcertById(id);
        if (!concertOpt.isPresent()) {
            return "redirect:/events";
        }
        
        Concert concert = concertOpt.get();
        
        // Check if the concert is sold out
        boolean isSoldOut = bookingService.isConcertSoldOut(id);
        
        // Add extra event information
        Map<String, String> eventInfo = new HashMap<>();
        eventInfo.put("Duration", "2 hours");
        eventInfo.put("Doors Open", concert.getDateTime().minusHours(1).format(timeFormatter));
        eventInfo.put("Age Restriction", "All ages welcome");
        eventInfo.put("Genre", getGenreForArtist(concert.getArtist()));
        eventInfo.put("Available Seats", String.valueOf(concert.getTotalSeats() - concert.getBookings().size()));
        eventInfo.put("Status", isSoldOut ? "Sold Out" : "Tickets Available");
        
        model.addAttribute("concert", concert);
        model.addAttribute("eventInfo", eventInfo);
        model.addAttribute("dateFormatter", dateFormatter);
        model.addAttribute("timeFormatter", timeFormatter);
        model.addAttribute("isSoldOut", isSoldOut);
        
        return "event-details";
    }
    
    @GetMapping("/book/{id}")
    public String bookEventTickets(@PathVariable String id) {
        if (bookingService.isConcertSoldOut(id)) {
            throw new SoldOutException(id, bookingService.getConcertById(id)
                .map(Concert::getName)
                .orElse("Unknown Concert"));
        }
        
        return "redirect:/concerts/book/" + id;
    }
    
    private boolean isEventSoldOut(Concert concert) {
        return concert.getBookings().size() >= concert.getTotalSeats();
    }
    
    private String getGenreForArtist(String artist) {
        // Simple mapping for demo purposes
        if (artist.toLowerCase().contains("rock")) {
            return "Rock";
        } else if (artist.toLowerCase().contains("jazz")) {
            return "Jazz";
        } else if (artist.toLowerCase().contains("pop")) {
            return "Pop";
        } else {
            return "Various";
        }
    }
} 