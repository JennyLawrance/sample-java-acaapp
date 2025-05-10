package com.concertbooking.exception;

public class SoldOutException extends RuntimeException {
    
    private final String concertId;
    private final String concertName;
    
    public SoldOutException(String concertId, String concertName) {
        super("Concert is sold out: " + concertName + " (ID: " + concertId + ")");
        this.concertId = concertId;
        this.concertName = concertName;
    }
    
    public String getConcertId() {
        return concertId;
    }
    
    public String getConcertName() {
        return concertName;
    }
} 