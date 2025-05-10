package com.concertbooking;

import com.concertbooking.model.Booking;
import com.concertbooking.model.Concert;
import com.concertbooking.service.BookingService;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Scanner;

public class Main {
    private static BookingService bookingService = new BookingService();
    private static Scanner scanner = new Scanner(System.in);

    public static void main(String[] args) {
        // Add some sample concerts
        addSampleConcerts();

        while (true) {
            System.out.println("\n=== Concert Booking System ===");
            System.out.println("1. View all concerts");
            System.out.println("2. Book tickets");
            System.out.println("3. View bookings by concert");
            System.out.println("4. View bookings by customer");
            System.out.println("5. Exit");
            System.out.print("Enter your choice: ");

            int choice = scanner.nextInt();
            scanner.nextLine(); // Consume newline

            switch (choice) {
                case 1:
                    viewAllConcerts();
                    break;
                case 2:
                    bookTickets();
                    break;
                case 3:
                    viewBookingsByConcert();
                    break;
                case 4:
                    viewBookingsByCustomer();
                    break;
                case 5:
                    System.out.println("Thank you for using the Concert Booking System!");
                    return;
                default:
                    System.out.println("Invalid choice. Please try again.");
            }
        }
    }

    private static void addSampleConcerts() {
        bookingService.addConcert(new Concert("C1", "Summer Festival", "The Rock Band",
                LocalDateTime.now().plusDays(30), "Central Stadium", 50.0, 1000));
        bookingService.addConcert(new Concert("C2", "Jazz Night", "The Jazz Quartet",
                LocalDateTime.now().plusDays(15), "City Hall", 75.0, 500));
    }

    private static void viewAllConcerts() {
        List<Concert> concerts = bookingService.getAllConcerts();
        System.out.println("\nAvailable Concerts:");
        for (Concert concert : concerts) {
            System.out.printf("ID: %s, Name: %s, Artist: %s, Date: %s, Venue: %s, Price: $%.2f%n",
                    concert.getId(), concert.getName(), concert.getArtist(),
                    concert.getDateTime(), concert.getVenue(), concert.getPrice());
        }
    }

    private static void bookTickets() {
        System.out.print("Enter concert ID: ");
        String concertId = scanner.nextLine();
        System.out.print("Enter your name: ");
        String name = scanner.nextLine();
        System.out.print("Enter your email: ");
        String email = scanner.nextLine();
        System.out.print("Enter number of seats: ");
        int seats = scanner.nextInt();
        scanner.nextLine(); // Consume newline

        try {
            bookingService.bookTickets(concertId, name, email, seats);
            System.out.println("Booking successful!");
        } catch (IllegalArgumentException | IllegalStateException e) {
            System.out.println("Error: " + e.getMessage());
        }
    }

    private static void viewBookingsByConcert() {
        System.out.print("Enter concert ID: ");
        String concertId = scanner.nextLine();
        List<Booking> bookings = bookingService.getBookingsByConcertId(concertId);
        
        System.out.println("\nBookings for Concert " + concertId + ":");
        for (Booking booking : bookings) {
            System.out.printf("Booking ID: %s, Customer: %s, Seats: %d, Total: $%.2f%n",
                    booking.getId(), booking.getCustomerName(),
                    booking.getNumberOfSeats(), booking.getTotalPrice());
        }
    }

    private static void viewBookingsByCustomer() {
        System.out.print("Enter customer email: ");
        String email = scanner.nextLine();
        List<Booking> bookings = bookingService.getBookingsByCustomerEmail(email);
        
        System.out.println("\nBookings for Customer " + email + ":");
        for (Booking booking : bookings) {
            System.out.printf("Booking ID: %s, Concert ID: %s, Seats: %d, Total: $%.2f%n",
                    booking.getId(), booking.getConcertId(),
                    booking.getNumberOfSeats(), booking.getTotalPrice());
        }
    }
} 