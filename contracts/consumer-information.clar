;; Consumer Information Contract
;; Provides consolidated product transparency information

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u501))

;; Trait definitions
(define-trait supplier-verification-trait
  (
    (get-supplier (uint) (response (optional {name: (string-ascii 100), contact-info: (string-ascii 200), verification-status: (string-ascii 20), verified-by: principal, verification-date: uint, certifications: (list 10 (string-ascii 50))}) uint))
    (is-supplier-verified (uint) (response bool uint))
  )
)

;; Data Maps
(define-map product-transparency
  { product-id: uint }
  {
    basic-info: {
      name: (string-ascii 100),
      description: (string-ascii 500),
      supplier-name: (string-ascii 100)
    },
    journey-summary: {
      origin: (string-ascii 100),
      current-location: (string-ascii 100),
      stages-completed: uint,
      last-updated: uint
    },
    quality-summary: {
      overall-grade: (string-ascii 10),
      safety-status: bool,
      recall-status: bool,
      last-tested: uint
    },
    ethics-summary: {
      labor-compliant: bool,
      environmentally-friendly: bool,
      certifications: (list 5 (string-ascii 50)),
      ethics-score: uint
    }
  }
)

(define-map consumer-queries
  { query-id: uint }
  {
    consumer: principal,
    product-id: uint,
    query-date: uint,
    information-provided: (string-ascii 1000)
  }
)

(define-data-var next-query-id uint u1)

;; Public Functions

;; Update product transparency information
(define-public (update-transparency-info
                (product-id uint)
                (name (string-ascii 100))
                (description (string-ascii 500))
                (supplier-name (string-ascii 100))
                (origin (string-ascii 100))
                (current-location (string-ascii 100))
                (stages-completed uint)
                (overall-grade (string-ascii 10))
                (safety-status bool)
                (recall-status bool)
                (labor-compliant bool)
                (environmentally-friendly bool)
                (certifications (list 5 (string-ascii 50)))
                (ethics-score uint))
  (begin
    (map-set product-transparency
      { product-id: product-id }
      {
        basic-info: {
          name: name,
          description: description,
          supplier-name: supplier-name
        },
        journey-summary: {
          origin: origin,
          current-location: current-location,
          stages-completed: stages-completed,
          last-updated: block-height
        },
        quality-summary: {
          overall-grade: overall-grade,
          safety-status: safety-status,
          recall-status: recall-status,
          last-tested: block-height
        },
        ethics-summary: {
          labor-compliant: labor-compliant,
          environmentally-friendly: environmentally-friendly,
          certifications: certifications,
          ethics-score: ethics-score
        }
      }
    )
    (ok true)
  )
)

;; Log consumer query
(define-public (log-consumer-query (product-id uint) (information-provided (string-ascii 1000)))
  (let ((query-id (var-get next-query-id)))
    (map-set consumer-queries
      { query-id: query-id }
      {
        consumer: tx-sender,
        product-id: product-id,
        query-date: block-height,
        information-provided: information-provided
      }
    )
    (var-set next-query-id (+ query-id u1))
    (ok query-id)
  )
)

;; Read-only Functions

;; Get complete product transparency information
(define-read-only (get-product-transparency (product-id uint))
  (map-get? product-transparency { product-id: product-id })
)

;; Get consumer query
(define-read-only (get-consumer-query (query-id uint))
  (map-get? consumer-queries { query-id: query-id })
)

;; Get product safety status
(define-read-only (is-product-safe (product-id uint))
  (match (map-get? product-transparency { product-id: product-id })
    transparency-data
    (and
      (get safety-status (get quality-summary transparency-data))
      (not (get recall-status (get quality-summary transparency-data)))
    )
    false
  )
)

;; Get product ethics rating
(define-read-only (get-ethics-rating (product-id uint))
  (match (map-get? product-transparency { product-id: product-id })
    transparency-data
    (some (get ethics-score (get ethics-summary transparency-data)))
    none
  )
)

;; Check if product meets sustainability standards
(define-read-only (meets-sustainability-standards (product-id uint))
  (match (map-get? product-transparency { product-id: product-id })
    transparency-data
    (let ((ethics-data (get ethics-summary transparency-data)))
      (and
        (get labor-compliant ethics-data)
        (get environmentally-friendly ethics-data)
        (>= (get ethics-score ethics-data) u70)
      )
    )
    false
  )
)
