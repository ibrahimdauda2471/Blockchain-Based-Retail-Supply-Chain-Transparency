;; Quality Assurance Contract
;; Records testing and inspection results

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u400))
(define-constant err-not-found (err u401))
(define-constant err-unauthorized (err u402))

;; Data Variables
(define-data-var next-test-id uint u1)
(define-data-var next-inspection-id uint u1)

;; Data Maps
(define-map quality-tests
  { test-id: uint }
  {
    product-id: uint,
    test-type: (string-ascii 50),
    tester: principal,
    test-date: uint,
    result: (string-ascii 20),
    score: uint,
    max-score: uint,
    notes: (string-ascii 300),
    certificate-hash: (string-ascii 64)
  }
)

(define-map inspections
  { inspection-id: uint }
  {
    product-id: uint,
    inspector: principal,
    inspection-date: uint,
    location: (string-ascii 100),
    status: (string-ascii 20),
    defects-found: uint,
    severity: (string-ascii 20),
    corrective-actions: (string-ascii 300)
  }
)

(define-map product-quality-status
  { product-id: uint }
  {
    overall-grade: (string-ascii 10),
    safety-approved: bool,
    quality-approved: bool,
    last-tested: uint,
    last-inspected: uint,
    recall-status: bool
  }
)

;; Public Functions

;; Record quality test
(define-public (record-test (product-id uint)
                           (test-type (string-ascii 50))
                           (result (string-ascii 20))
                           (score uint)
                           (max-score uint)
                           (notes (string-ascii 300))
                           (certificate-hash (string-ascii 64)))
  (let ((test-id (var-get next-test-id)))
    (map-set quality-tests
      { test-id: test-id }
      {
        product-id: product-id,
        test-type: test-type,
        tester: tx-sender,
        test-date: block-height,
        result: result,
        score: score,
        max-score: max-score,
        notes: notes,
        certificate-hash: certificate-hash
      }
    )
    (var-set next-test-id (+ test-id u1))
    (ok test-id)
  )
)

;; Record inspection
(define-public (record-inspection (product-id uint)
                                 (location (string-ascii 100))
                                 (status (string-ascii 20))
                                 (defects-found uint)
                                 (severity (string-ascii 20))
                                 (corrective-actions (string-ascii 300)))
  (let ((inspection-id (var-get next-inspection-id)))
    (map-set inspections
      { inspection-id: inspection-id }
      {
        product-id: product-id,
        inspector: tx-sender,
        inspection-date: block-height,
        location: location,
        status: status,
        defects-found: defects-found,
        severity: severity,
        corrective-actions: corrective-actions
      }
    )
    (var-set next-inspection-id (+ inspection-id u1))
    (ok inspection-id)
  )
)

;; Update product quality status
(define-public (update-quality-status (product-id uint)
                                     (overall-grade (string-ascii 10))
                                     (safety-approved bool)
                                     (quality-approved bool))
  (begin
    (map-set product-quality-status
      { product-id: product-id }
      {
        overall-grade: overall-grade,
        safety-approved: safety-approved,
        quality-approved: quality-approved,
        last-tested: block-height,
        last-inspected: block-height,
        recall-status: false
      }
    )
    (ok true)
  )
)

;; Issue product recall
(define-public (issue-recall (product-id uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? product-quality-status { product-id: product-id })
      quality-data
      (begin
        (map-set product-quality-status
          { product-id: product-id }
          (merge quality-data { recall-status: true })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Read-only Functions

;; Get test information
(define-read-only (get-test (test-id uint))
  (map-get? quality-tests { test-id: test-id })
)

;; Get inspection information
(define-read-only (get-inspection (inspection-id uint))
  (map-get? inspections { inspection-id: inspection-id })
)

;; Get product quality status
(define-read-only (get-quality-status (product-id uint))
  (map-get? product-quality-status { product-id: product-id })
)

;; Check if product is approved for sale
(define-read-only (is-approved-for-sale (product-id uint))
  (match (map-get? product-quality-status { product-id: product-id })
    quality-data
    (and
      (get safety-approved quality-data)
      (get quality-approved quality-data)
      (not (get recall-status quality-data))
    )
    false
  )
)
