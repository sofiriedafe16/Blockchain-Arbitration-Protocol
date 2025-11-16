(define-constant ERR_BADGE_NOT_FOUND (err u400))
(define-constant ERR_INVALID_BADGE_TYPE (err u401))
(define-constant ERR_BADGE_ALREADY_EARNED (err u402))
(define-constant ERR_INSUFFICIENT_DISPUTES (err u403))
(define-constant ERR_UNAUTHORIZED_AWARD (err u404))

(define-constant BADGE_ROOKIE "rookie")
(define-constant BADGE_VETERAN "veteran")
(define-constant BADGE_EXPERT "expert")
(define-constant BADGE_LEGEND "legend")
(define-constant BADGE_ACCURACY "accuracy-king")
(define-constant BADGE_SPEED "speed-demon")

(define-map arbitrator-badge-collection
  { arbitrator-id: uint, badge-type: (string-ascii 20) }
  {
    earned-at: uint,
    qualifying-metric: uint
  }
)

(define-map arbitrator-total-badges
  { arbitrator-id: uint }
  { count: uint }
)

(define-map badge-requirements
  { badge-type: (string-ascii 20) }
  {
    min-disputes: uint,
    min-accuracy: uint,
    description: (string-ascii 100)
  }
)

(define-private (initialize-badge-requirements)
  (begin
    (map-set badge-requirements { badge-type: BADGE_ROOKIE }
      { min-disputes: u1, min-accuracy: u0, description: "Complete your first dispute" })
    (map-set badge-requirements { badge-type: BADGE_VETERAN }
      { min-disputes: u10, min-accuracy: u70, description: "Resolve 10 disputes with 70%+ accuracy" })
    (map-set badge-requirements { badge-type: BADGE_EXPERT }
      { min-disputes: u25, min-accuracy: u85, description: "Resolve 25 disputes with 85%+ accuracy" })
    (map-set badge-requirements { badge-type: BADGE_LEGEND }
      { min-disputes: u50, min-accuracy: u95, description: "Resolve 50 disputes with 95%+ accuracy" })
    (map-set badge-requirements { badge-type: BADGE_ACCURACY }
      { min-disputes: u5, min-accuracy: u100, description: "Maintain 100% accuracy across 5 disputes" })
    (map-set badge-requirements { badge-type: BADGE_SPEED }
      { min-disputes: u3, min-accuracy: u75, description: "Vote within 1 hour on 3 consecutive disputes" })
    true
  )
)

(begin (initialize-badge-requirements))

(define-public (award-badge (arbitrator-id uint) (badge-type (string-ascii 20)))
  (let
    (
      (current-block stacks-block-height)
      (existing-badge (map-get? arbitrator-badge-collection 
        { arbitrator-id: arbitrator-id, badge-type: badge-type }))
    )
    (if (is-none existing-badge)
      (begin
        (map-set arbitrator-badge-collection
          { arbitrator-id: arbitrator-id, badge-type: badge-type }
          { earned-at: current-block, qualifying-metric: u1 }
        )
        (let ((current-count (default-to u0 
          (get count (map-get? arbitrator-total-badges { arbitrator-id: arbitrator-id })))))
          (map-set arbitrator-total-badges 
            { arbitrator-id: arbitrator-id } 
            { count: (+ current-count u1) })
        )
        (ok true)
      )
      ERR_BADGE_ALREADY_EARNED
    )
  )
)

(define-read-only (has-badge (arbitrator-id uint) (badge-type (string-ascii 20)))
  (is-some (map-get? arbitrator-badge-collection 
    { arbitrator-id: arbitrator-id, badge-type: badge-type }))
)

(define-read-only (get-badge-details (arbitrator-id uint) (badge-type (string-ascii 20)))
  (map-get? arbitrator-badge-collection 
    { arbitrator-id: arbitrator-id, badge-type: badge-type })
)

(define-read-only (get-total-badges (arbitrator-id uint))
  (default-to u0 
    (get count (map-get? arbitrator-total-badges { arbitrator-id: arbitrator-id })))
)

(define-read-only (get-badge-requirement (badge-type (string-ascii 20)))
  (map-get? badge-requirements { badge-type: badge-type })
)
