;; Ethical Sourcing Contract
;; Validates and tracks ethical practices

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-not-found (err u301))
(define-constant err-unauthorized (err u302))

;; Data Variables
(define-data-var next-audit-id uint u1)

;; Data Maps
(define-map ethical-audits
  { audit-id: uint }
  {
    supplier-id: uint,
    audit-type: (string-ascii 50),
    auditor: principal,
    audit-date: uint,
    score: uint,
    max-score: uint,
    status: (string-ascii 20),
    findings: (string-ascii 500),
    recommendations: (string-ascii 500)
  }
)

(define-map supplier-ethics-score
  { supplier-id: uint }
  {
    labor-score: uint,
    environmental-score: uint,
    overall-score: uint,
    last-updated: uint,
    certification-level: (string-ascii 20)
  }
)

(define-map product-ethics
  { product-id: uint }
  {
    labor-compliance: bool,
    environmental-compliance: bool,
    fair-trade: bool,
    organic: bool,
    carbon-neutral: bool,
    verified-at: uint
  }
)

;; Public Functions

;; Conduct ethical audit
(define-public (conduct-audit (supplier-id uint)
                             (audit-type (string-ascii 50))
                             (score uint)
                             (max-score uint)
                             (findings (string-ascii 500))
                             (recommendations (string-ascii 500)))
  (let ((audit-id (var-get next-audit-id)))
    (map-set ethical-audits
      { audit-id: audit-id }
      {
        supplier-id: supplier-id,
        audit-type: audit-type,
        auditor: tx-sender,
        audit-date: block-height,
        score: score,
        max-score: max-score,
        status: "completed",
        findings: findings,
        recommendations: recommendations
      }
    )
    (var-set next-audit-id (+ audit-id u1))
    (ok audit-id)
  )
)

;; Update supplier ethics score
(define-public (update-ethics-score (supplier-id uint)
                                   (labor-score uint)
                                   (environmental-score uint))
  (let ((overall-score (/ (+ labor-score environmental-score) u2))
        (certification-level
          (if (>= overall-score u90) "gold"
            (if (>= overall-score u75) "silver"
              (if (>= overall-score u60) "bronze" "none")))))
    (map-set supplier-ethics-score
      { supplier-id: supplier-id }
      {
        labor-score: labor-score,
        environmental-score: environmental-score,
        overall-score: overall-score,
        last-updated: block-height,
        certification-level: certification-level
      }
    )
    (ok true)
  )
)

;; Verify product ethics
(define-public (verify-product-ethics (product-id uint)
                                     (labor-compliance bool)
                                     (environmental-compliance bool)
                                     (fair-trade bool)
                                     (organic bool)
                                     (carbon-neutral bool))
  (begin
    (map-set product-ethics
      { product-id: product-id }
      {
        labor-compliance: labor-compliance,
        environmental-compliance: environmental-compliance,
        fair-trade: fair-trade,
        organic: organic,
        carbon-neutral: carbon-neutral,
        verified-at: block-height
      }
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get audit information
(define-read-only (get-audit (audit-id uint))
  (map-get? ethical-audits { audit-id: audit-id })
)

;; Get supplier ethics score
(define-read-only (get-supplier-ethics (supplier-id uint))
  (map-get? supplier-ethics-score { supplier-id: supplier-id })
)

;; Get product ethics information
(define-read-only (get-product-ethics (product-id uint))
  (map-get? product-ethics { product-id: product-id })
)

;; Check if supplier meets ethics standards
(define-read-only (meets-ethics-standards (supplier-id uint))
  (match (map-get? supplier-ethics-score { supplier-id: supplier-id })
    ethics-data
    (>= (get overall-score ethics-data) u60)
    false
  )
)
