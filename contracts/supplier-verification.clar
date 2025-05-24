;; Supplier Verification Contract
;; Manages supplier registration and verification status

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

;; Data Variables
(define-data-var next-supplier-id uint u1)

;; Data Maps
(define-map suppliers
  { supplier-id: uint }
  {
    name: (string-ascii 100),
    contact-info: (string-ascii 200),
    verification-status: (string-ascii 20),
    verified-by: principal,
    verification-date: uint,
    certifications: (list 10 (string-ascii 50))
  }
)

(define-map supplier-principals
  { supplier-principal: principal }
  { supplier-id: uint }
)

;; Public Functions

;; Register a new supplier
(define-public (register-supplier (name (string-ascii 100))
                                 (contact-info (string-ascii 200))
                                 (certifications (list 10 (string-ascii 50))))
  (let ((supplier-id (var-get next-supplier-id)))
    (asserts! (is-none (map-get? supplier-principals { supplier-principal: tx-sender })) err-already-exists)
    (map-set suppliers
      { supplier-id: supplier-id }
      {
        name: name,
        contact-info: contact-info,
        verification-status: "pending",
        verified-by: contract-owner,
        verification-date: u0,
        certifications: certifications
      }
    )
    (map-set supplier-principals
      { supplier-principal: tx-sender }
      { supplier-id: supplier-id }
    )
    (var-set next-supplier-id (+ supplier-id u1))
    (ok supplier-id)
  )
)

;; Verify a supplier (owner only)
(define-public (verify-supplier (supplier-id uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? suppliers { supplier-id: supplier-id })
      supplier-data
      (begin
        (map-set suppliers
          { supplier-id: supplier-id }
          (merge supplier-data {
            verification-status: "verified",
            verified-by: tx-sender,
            verification-date: block-height
          })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Revoke supplier verification
(define-public (revoke-verification (supplier-id uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? suppliers { supplier-id: supplier-id })
      supplier-data
      (begin
        (map-set suppliers
          { supplier-id: supplier-id }
          (merge supplier-data {
            verification-status: "revoked",
            verified-by: tx-sender,
            verification-date: block-height
          })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Read-only Functions

;; Get supplier information
(define-read-only (get-supplier (supplier-id uint))
  (map-get? suppliers { supplier-id: supplier-id })
)

;; Get supplier ID by principal
(define-read-only (get-supplier-id (supplier-principal principal))
  (map-get? supplier-principals { supplier-principal: supplier-principal })
)

;; Check if supplier is verified
(define-read-only (is-supplier-verified (supplier-id uint))
  (match (map-get? suppliers { supplier-id: supplier-id })
    supplier-data
    (is-eq (get verification-status supplier-data) "verified")
    false
  )
)
