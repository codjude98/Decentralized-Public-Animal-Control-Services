;; Adoption Processing Contract
;; Manages pet adoption applications and fees

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-INVALID-APPLICATION-ID (err u201))
(define-constant ERR-APPLICATION-NOT-FOUND (err u202))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u203))
(define-constant ERR-INVALID-STATUS (err u204))
(define-constant ERR-ANIMAL-NOT-AVAILABLE (err u205))

;; Data Variables
(define-data-var next-application-id uint u1)
(define-data-var adoption-fee uint u1000000) ;; 1 STX in microSTX
(define-data-var contract-balance uint u0)

;; Data Maps
(define-map adoption-applications uint {
    applicant: principal,
    animal-id: uint,
    animal-description: (string-ascii 100),
    applicant-name: (string-ascii 50),
    applicant-address: (string-ascii 100),
    phone-number: (string-ascii 20),
    experience-level: (string-ascii 20),
    housing-type: (string-ascii 30),
    other-pets: bool,
    status: (string-ascii 20),
    application-date: uint,
    approval-date: (optional uint),
    fee-paid: bool,
    notes: (string-ascii 200)
})

(define-map available-animals uint {
    species: (string-ascii 20),
    breed: (string-ascii 30),
    age: uint,
    gender: (string-ascii 10),
    description: (string-ascii 100),
    medical-status: (string-ascii 50),
    adoption-fee: uint,
    available: bool,
    reserved-for: (optional uint)
})

(define-map authorized-staff principal bool)

;; Authorization Functions
(define-public (add-staff (staff principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (ok (map-set authorized-staff staff true))
    )
)

(define-public (remove-staff (staff principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (ok (map-delete authorized-staff staff))
    )
)

;; Animal Management Functions
(define-public (add-available-animal (animal-id uint) (species (string-ascii 20)) (breed (string-ascii 30)) (age uint) (gender (string-ascii 10)) (description (string-ascii 100)) (medical-status (string-ascii 50)) (fee uint))
    (begin
        (asserts! (default-to false (map-get? authorized-staff tx-sender)) ERR-NOT-AUTHORIZED)
        (map-set available-animals animal-id {
            species: species,
            breed: breed,
            age: age,
            gender: gender,
            description: description,
            medical-status: medical-status,
            adoption-fee: fee,
            available: true,
            reserved-for: none
        })
        (ok true)
    )
)

(define-public (update-animal-availability (animal-id uint) (available bool))
    (let ((animal (unwrap! (map-get? available-animals animal-id) ERR-ANIMAL-NOT-AVAILABLE)))
        (begin
            (asserts! (default-to false (map-get? authorized-staff tx-sender)) ERR-NOT-AUTHORIZED)
            (map-set available-animals animal-id (merge animal {
                available: available,
                reserved-for: (if available none (get reserved-for animal))
            }))
            (ok true)
        )
    )
)

;; Application Functions
(define-public (submit-application (animal-id uint) (animal-description (string-ascii 100)) (applicant-name (string-ascii 50)) (applicant-address (string-ascii 100)) (phone-number (string-ascii 20)) (experience-level (string-ascii 20)) (housing-type (string-ascii 30)) (other-pets bool))
    (let ((application-id (var-get next-application-id))
          (animal (unwrap! (map-get? available-animals animal-id) ERR-ANIMAL-NOT-AVAILABLE)))
        (begin
            (asserts! (get available animal) ERR-ANIMAL-NOT-AVAILABLE)
            (map-set adoption-applications application-id {
                applicant: tx-sender,
                animal-id: animal-id,
                animal-description: animal-description,
                applicant-name: applicant-name,
                applicant-address: applicant-address,
                phone-number: phone-number,
                experience-level: experience-level,
                housing-type: housing-type,
                other-pets: other-pets,
                status: "pending",
                application-date: block-height,
                approval-date: none,
                fee-paid: false,
                notes: ""
            })
            ;; Reserve animal for this application
            (map-set available-animals animal-id (merge animal {
                reserved-for: (some application-id)
            }))
            (var-set next-application-id (+ application-id u1))
            (ok application-id)
        )
    )
)

(define-public (review-application (application-id uint) (approved bool) (notes (string-ascii 200)))
    (let ((application (unwrap! (map-get? adoption-applications application-id) ERR-APPLICATION-NOT-FOUND)))
        (begin
            (asserts! (default-to false (map-get? authorized-staff tx-sender)) ERR-NOT-AUTHORIZED)
            (asserts! (is-eq (get status application) "pending") ERR-INVALID-STATUS)
            (map-set adoption-applications application-id (merge application {
                status: (if approved "approved" "rejected"),
                approval-date: (some block-height),
                notes: notes
            }))
            ;; If rejected, make animal available again
            (if (not approved)
                (let ((animal (unwrap! (map-get? available-animals (get animal-id application)) ERR-ANIMAL-NOT-AVAILABLE)))
                    (map-set available-animals (get animal-id application) (merge animal {
                        reserved-for: none
                    }))
                )
                true
            )
            (ok approved)
        )
    )
)

(define-public (pay-adoption-fee (application-id uint))
    (let ((application (unwrap! (map-get? adoption-applications application-id) ERR-APPLICATION-NOT-FOUND))
          (animal (unwrap! (map-get? available-animals (get animal-id application)) ERR-ANIMAL-NOT-AVAILABLE)))
        (begin
            (asserts! (is-eq (get applicant application) tx-sender) ERR-NOT-AUTHORIZED)
            (asserts! (is-eq (get status application) "approved") ERR-INVALID-STATUS)
            (asserts! (not (get fee-paid application)) ERR-INVALID-STATUS)
            (try! (stx-transfer? (get adoption-fee animal) tx-sender (as-contract tx-sender)))
            (map-set adoption-applications application-id (merge application {
                fee-paid: true,
                status: "completed"
            }))
            (map-set available-animals (get animal-id application) (merge animal {
                available: false
            }))
            (var-set contract-balance (+ (var-get contract-balance) (get adoption-fee animal)))
            (ok true)
        )
    )
)

;; Administrative Functions
(define-public (set-adoption-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (var-set adoption-fee new-fee)
        (ok true)
    )
)

(define-public (withdraw-funds (amount uint) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (<= amount (var-get contract-balance)) ERR-INSUFFICIENT-PAYMENT)
        (try! (as-contract (stx-transfer? amount tx-sender recipient)))
        (var-set contract-balance (- (var-get contract-balance) amount))
        (ok true)
    )
)

;; Read-only Functions
(define-read-only (get-application (application-id uint))
    (map-get? adoption-applications application-id)
)

(define-read-only (get-available-animal (animal-id uint))
    (map-get? available-animals animal-id)
)

(define-read-only (get-adoption-fee)
    (var-get adoption-fee)
)

(define-read-only (get-contract-balance)
    (var-get contract-balance)
)

(define-read-only (is-authorized-staff (staff principal))
    (default-to false (map-get? authorized-staff staff))
)

(define-read-only (get-next-application-id)
    (var-get next-application-id)
)
