(define-constant ERR_NOTIFICATION_NOT_FOUND (err u300))
(define-constant ERR_INVALID_EVENT_TYPE (err u301))
(define-constant ERR_DUPLICATE_SUBSCRIPTION (err u302))

(define-constant MAX_NOTIFICATION_MESSAGE u200)

(define-data-var next-notification-id uint u1)

(define-map dispute-timeline
  { dispute-id: uint, event-id: uint }
  {
    event-type: (string-ascii 30),
    actor: principal,
    message: (string-ascii 200),
    block-height: uint,
    timestamp: uint
  }
)

(define-map dispute-event-count
  { dispute-id: uint }
  { count: uint }
)

(define-map user-subscriptions
  { user: principal, dispute-id: uint }
  { 
    subscribed: bool,
    last-viewed: uint
  }
)

(define-map dispute-status-cache
  { dispute-id: uint }
  {
    current-status: (string-ascii 30),
    last-updated: uint,
    next-milestone: (string-ascii 20)
  }
)

(define-private (get-event-count (dispute-id uint))
  (default-to u0 (get count (map-get? dispute-event-count { dispute-id: dispute-id })))
)

(define-private (increment-event-count (dispute-id uint))
  (let ((new-count (+ (get-event-count dispute-id) u1)))
    (map-set dispute-event-count { dispute-id: dispute-id } { count: new-count })
    new-count
  )
)

(define-public (log-dispute-event 
  (dispute-id uint) 
  (event-type (string-ascii 30)) 
  (message (string-ascii 200)))
  (let
    (
      (event-id (increment-event-count dispute-id))
      (current-block stacks-block-height)
    )
    (map-set dispute-timeline
      { dispute-id: dispute-id, event-id: event-id }
      {
        event-type: event-type,
        actor: tx-sender,
        message: message,
        block-height: current-block,
        timestamp: current-block
      }
    )
    (map-set dispute-status-cache
      { dispute-id: dispute-id }
      {
        current-status: event-type,
        last-updated: current-block,
        next-milestone: (get-next-milestone event-type)
      }
    )
    (ok event-id)
  )
)

(define-private (get-next-milestone (current-status (string-ascii 30)))
  (if (is-eq current-status "created")
    "arbitration-start"
    (if (is-eq current-status "arbitration-started")
      "voting-period"
      (if (is-eq current-status "voting-active")
        "resolution"
        "completed"
      )
    )
  )
)

(define-public (subscribe-to-dispute (dispute-id uint))
  (begin
    (map-set user-subscriptions
      { user: tx-sender, dispute-id: dispute-id }
      { subscribed: true, last-viewed: stacks-block-height }
    )
    (ok true)
  )
)

(define-read-only (get-dispute-timeline (dispute-id uint))
  (get-event-count dispute-id)
)

(define-read-only (get-timeline-event (dispute-id uint) (event-id uint))
  (map-get? dispute-timeline { dispute-id: dispute-id, event-id: event-id })
)

(define-read-only (get-user-notifications (user principal) (dispute-id uint))
  (map-get? user-subscriptions { user: user, dispute-id: dispute-id })
)

(define-read-only (get-dispute-status-summary (dispute-id uint))
  (map-get? dispute-status-cache { dispute-id: dispute-id })
)

(define-read-only (get-unread-updates (user principal) (dispute-id uint))
  (match (map-get? user-subscriptions { user: user, dispute-id: dispute-id })
    subscription-data
    (let ((last-viewed (get last-viewed subscription-data)))
      (> (get-event-count dispute-id) last-viewed)
    )
    false
  )
)
