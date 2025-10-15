(define-constant ERR_EVIDENCE_NOT_FOUND (err u200))
(define-constant ERR_DISPUTE_NOT_ACTIVE (err u201))
(define-constant ERR_UNAUTHORIZED_EVIDENCE (err u202))
(define-constant ERR_EVIDENCE_LIMIT_EXCEEDED (err u203))
(define-constant ERR_INVALID_EVIDENCE_TYPE (err u204))

(define-constant MAX_EVIDENCE_PER_DISPUTE u10)
(define-constant MAX_EVIDENCE_DESCRIPTION_LENGTH u300)

(define-data-var next-evidence-id uint u1)

(define-map dispute-evidence
  { dispute-id: uint, evidence-id: uint }
  {
    submitter: principal,
    evidence-type: (string-ascii 20),
    description: (string-ascii 300),
    hash: (buff 32),
    submitted-at: uint,
    verified: bool
  }
)

(define-map dispute-evidence-count
  { dispute-id: uint }
  { count: uint }
)

(define-map evidence-verification
  { evidence-id: uint }
  {
    verifier: principal,
    verified-at: uint,
    verification-notes: (string-ascii 200)
  }
)

(define-private (get-evidence-count (dispute-id uint))
  (default-to u0 (get count (map-get? dispute-evidence-count { dispute-id: dispute-id })))
)

(define-private (increment-evidence-count (dispute-id uint))
  (let
    (
      (current-count (get-evidence-count dispute-id))
      (new-count (+ current-count u1))
    )
    (map-set dispute-evidence-count { dispute-id: dispute-id } { count: new-count })
    new-count
  )
)

(define-private (is-valid-evidence-type (evidence-type (string-ascii 20)))
  (or 
    (is-eq evidence-type "document")
    (or (is-eq evidence-type "image")
    (or (is-eq evidence-type "video")
    (or (is-eq evidence-type "audio")
    (is-eq evidence-type "other"))))
  )
)

(define-public (submit-evidence 
  (dispute-id uint) 
  (evidence-type (string-ascii 20)) 
  (description (string-ascii 300)) 
  (evidence-hash (buff 32)))
  (let
    (
      (evidence-id (var-get next-evidence-id))
      (current-count (get-evidence-count dispute-id))
      (current-block stacks-block-height)
    )
    (if (and 
          (< current-count MAX_EVIDENCE_PER_DISPUTE)
          (is-valid-evidence-type evidence-type)
          (<= (len description) MAX_EVIDENCE_DESCRIPTION_LENGTH))
      (begin
        (map-set dispute-evidence
          { dispute-id: dispute-id, evidence-id: evidence-id }
          {
            submitter: tx-sender,
            evidence-type: evidence-type,
            description: description,
            hash: evidence-hash,
            submitted-at: current-block,
            verified: false
          }
        )
        (increment-evidence-count dispute-id)
        (var-set next-evidence-id (+ evidence-id u1))
        (ok evidence-id)
      )
      (if (>= current-count MAX_EVIDENCE_PER_DISPUTE)
        ERR_EVIDENCE_LIMIT_EXCEEDED
        ERR_INVALID_EVIDENCE_TYPE
      )
    )
  )
)

(define-read-only (get-evidence (dispute-id uint) (evidence-id uint))
  (map-get? dispute-evidence { dispute-id: dispute-id, evidence-id: evidence-id })
)

(define-read-only (get-dispute-evidence-count (dispute-id uint))
  (get-evidence-count dispute-id)
)

(define-read-only (get-evidence-verification (evidence-id uint))
  (map-get? evidence-verification { evidence-id: evidence-id })
)