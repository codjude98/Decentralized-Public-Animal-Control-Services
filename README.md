# Decentralized Public Animal Control Services

A blockchain-based system for managing public animal control services including stray animal rescue, adoption processing, vaccination tracking, license enforcement, and euthanasia management.

## System Overview

This decentralized system consists of five independent smart contracts that handle different aspects of animal control services:

### 1. Stray Animal Pickup Contract (`stray-pickup.clar`)
- Coordinates animal rescue operations
- Manages shelter transport logistics
- Tracks pickup requests and assignments
- Records animal intake information

### 2. Adoption Processing Contract (`adoption-processing.clar`)
- Manages pet adoption applications
- Processes adoption fees and payments
- Tracks adoption status and approvals
- Maintains adopter records

### 3. Vaccination Tracking Contract (`vaccination-tracking.clar`)
- Records animal immunization history
- Tracks health records and medical treatments
- Manages vaccination schedules
- Monitors health compliance

### 4. License Enforcement Contract (`license-enforcement.clar`)
- Issues citations for unlicensed pets
- Manages pet licensing requirements
- Tracks compliance and violations
- Processes license fees and renewals

### 5. Euthanasia Management Contract (`euthanasia-management.clar`)
- Handles difficult welfare decisions
- Manages euthanasia authorization process
- Records medical justifications
- Tracks facility capacity and resources

## Key Features

- **Decentralized Operations**: Each contract operates independently
- **Transparent Records**: All actions recorded on blockchain
- **Fee Management**: Built-in payment processing for services
- **Access Control**: Role-based permissions for different user types
- **Data Integrity**: Immutable record keeping for compliance

## Contract Interactions

Each contract is designed to be self-contained with no cross-contract dependencies, ensuring:
- Independent deployment and upgrades
- Reduced complexity and attack surface
- Clear separation of concerns
- Simplified testing and maintenance

## Getting Started

1. Install dependencies: `npm install`
2. Run tests: `npm test`
3. Deploy contracts using Clarinet
4. Configure contract principals for your organization

## Testing

The system includes comprehensive tests using Vitest to ensure:
- Contract functionality works as expected
- Error conditions are handled properly
- Access controls function correctly
- Fee calculations are accurate

## Compliance

This system is designed to meet public animal control regulatory requirements while providing transparency and accountability through blockchain technology.
