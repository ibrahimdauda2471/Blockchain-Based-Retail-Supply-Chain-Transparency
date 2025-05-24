;; Product Journey Contract
;; Tracks products through the supply chain

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-found (err u201))
(define-constant err-unauthorized (err u202))
(define-constant err-invalid-stage (err u203))

;; Data Variables
(define-data-var next-product-id uint u1)
(define-data-var next-journey-id uint u1)

;; Data Maps
(define-map products
  { product-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    supplier-id: uint,
    created-at: uint,
    current-stage: (string-ascii 50),
    current-location: (string-ascii 100)
  }
)

(define-map journey-stages
  { journey-id: uint }
  {
    product-id: uint,
    stage: (string-ascii 50),
    location: (string-ascii 100),
    timestamp: uint,
    handler: principal,
    notes: (string-ascii 200)
  }
)

(define-map product-journeys
  { product-id: uint, stage-number: uint }
  { journey-id: uint }
)

;; Public Functions

;; Create a new product
(define-public (create-product (name (string-ascii 100))
                              (description (string-ascii 500))
                              (supplier-id uint)
                              (initial-location (string-ascii 100)))
  (let ((product-id (var-get next-product-id))
        (journey-id (var-get next-journey-id)))
    ;; Create product record
    (map-set products
      { product-id: product-id }
      {
        name: name,
        description: description,
        supplier-id: supplier-id,
        created-at: block-height,
        current-stage: "created",
        current-location: initial-location
      }
    )
    ;; Create initial journey stage
    (map-set journey-stages
      { journey-id: journey-id }
      {
        product-id: product-id,
        stage: "created",
        location: initial-location,
        timestamp: block-height,
        handler: tx-sender,
        notes: "Product created"
      }
    )
    (map-set product-journeys
      { product-id: product-id, stage-number: u1 }
      { journey-id: journey-id }
    )
    (var-set next-product-id (+ product-id u1))
    (var-set next-journey-id (+ journey-id u1))
    (ok product-id)
  )
)

;; Add journey stage
(define-public (add-journey-stage (product-id uint)
                                 (stage (string-ascii 50))
                                 (location (string-ascii 100))
                                 (notes (string-ascii 200)))
  (let ((journey-id (var-get next-journey-id)))
    (match (map-get? products { product-id: product-id })
      product-data
      (begin
        ;; Update product current stage
        (map-set products
          { product-id: product-id }
          (merge product-data {
            current-stage: stage,
            current-location: location
          })
        )
        ;; Add journey stage
        (map-set journey-stages
          { journey-id: journey-id }
          {
            product-id: product-id,
            stage: stage,
            location: location,
            timestamp: block-height,
            handler: tx-sender,
            notes: notes
          }
        )
        (var-set next-journey-id (+ journey-id u1))
        (ok journey-id)
      )
      err-not-found
    )
  )
)

;; Read-only Functions

;; Get product information
(define-read-only (get-product (product-id uint))
  (map-get? products { product-id: product-id })
)

;; Get journey stage
(define-read-only (get-journey-stage (journey-id uint))
  (map-get? journey-stages { journey-id: journey-id })
)

;; Get product current status
(define-read-only (get-product-status (product-id uint))
  (match (map-get? products { product-id: product-id })
    product-data
    (some {
      current-stage: (get current-stage product-data),
      current-location: (get current-location product-data)
    })
    none
  )
)
