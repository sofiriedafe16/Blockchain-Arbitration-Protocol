(define-constant ERR_NOT_ARBITRATOR (err u500))
(define-constant ERR_INVALID_SCHEDULE (err u501))
(define-constant ERR_SCHEDULE_NOT_FOUND (err u502))

(define-constant STATUS_AVAILABLE "available")
(define-constant STATUS_BUSY "busy")
(define-constant STATUS_OFFLINE "offline")

(define-map arbitrator-availability
  { arbitrator-id: uint }
  {
    status: (string-ascii 20),
    available-from: uint,
    available-until: uint,
    last-updated: uint,
    auto-accept: bool
  }
)

(define-map availability-history
  { arbitrator-id: uint, timestamp: uint }
  {
    status: (string-ascii 20),
    duration-blocks: uint
  }
)

(define-map weekly-schedule
  { arbitrator-id: uint, day: uint }
  {
    start-hour: uint,
    end-hour: uint,
    is-active: bool
  }
)

(define-public (set-availability 
  (arbitrator-id uint) 
  (status (string-ascii 20)) 
  (available-from uint) 
  (available-until uint) 
  (auto-accept bool))
  (let ((current-block stacks-block-height))
    (if (and 
          (>= available-until available-from)
          (or (is-eq status STATUS_AVAILABLE)
              (or (is-eq status STATUS_BUSY) (is-eq status STATUS_OFFLINE))))
      (begin
        (map-set arbitrator-availability
          { arbitrator-id: arbitrator-id }
          {
            status: status,
            available-from: available-from,
            available-until: available-until,
            last-updated: current-block,
            auto-accept: auto-accept
          }
        )
        (ok true)
      )
      ERR_INVALID_SCHEDULE
    )
  )
)

(define-public (set-weekly-schedule 
  (arbitrator-id uint) 
  (day uint) 
  (start-hour uint) 
  (end-hour uint))
  (if (and (< day u7) (< start-hour u24) (<= end-hour u24) (>= end-hour start-hour))
    (begin
      (map-set weekly-schedule
        { arbitrator-id: arbitrator-id, day: day }
        { start-hour: start-hour, end-hour: end-hour, is-active: true }
      )
      (ok true)
    )
    ERR_INVALID_SCHEDULE
  )
)

(define-read-only (is-arbitrator-available (arbitrator-id uint))
  (match (map-get? arbitrator-availability { arbitrator-id: arbitrator-id })
    availability-data
    (let ((current-block stacks-block-height))
      (and 
        (is-eq (get status availability-data) STATUS_AVAILABLE)
        (>= current-block (get available-from availability-data))
        (<= current-block (get available-until availability-data))
      )
    )
    false
  )
)

(define-read-only (get-availability (arbitrator-id uint))
  (map-get? arbitrator-availability { arbitrator-id: arbitrator-id })
)

(define-read-only (get-schedule (arbitrator-id uint) (day uint))
  (map-get? weekly-schedule { arbitrator-id: arbitrator-id, day: day })
)
