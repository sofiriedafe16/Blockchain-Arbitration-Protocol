(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_DISPUTE_NOT_FOUND (err u101))
(define-constant ERR_INVALID_STATUS (err u102))
(define-constant ERR_INSUFFICIENT_STAKE (err u103))
(define-constant ERR_ALREADY_VOTED (err u104))
(define-constant ERR_NOT_ARBITRATOR (err u105))
(define-constant ERR_VOTING_ENDED (err u106))
(define-constant ERR_INSUFFICIENT_FUNDS (err u107))

(define-constant MIN_ARBITRATOR_STAKE u1000000)
(define-constant DISPUTE_FEE u100000)
(define-constant VOTING_PERIOD u144)
(define-constant MIN_ARBITRATORS u3)

(define-constant PERFORMANCE_REWARD_POOL u5000000)
(define-constant MIN_DISPUTES_FOR_REWARDS u5)
(define-constant PERFORMANCE_DECAY_RATE u95)

(define-data-var total-reward-pool uint u0)
(define-data-var performance-update-height uint u0)

(define-data-var next-dispute-id uint u1)
(define-data-var next-arbitrator-id uint u1)

(define-map arbitrators
  { arbitrator-id: uint }
  {
    address: principal,
    stake: uint,
    reputation: uint,
    active: bool,
    disputes-resolved: uint
  }
)

(define-map arbitrator-addresses
  { address: principal }
  { arbitrator-id: uint }
)

(define-map disputes
  {
    dispute-id: uint
  }
  {
    plaintiff: principal,
    defendant: principal,
    amount: uint,
    description: (string-ascii 500),
    status: (string-ascii 20),
    created-at: uint,
    voting-end: uint,
    selected-arbitrators: (list 10 uint),
    votes-for-plaintiff: uint,
    votes-for-defendant: uint,
    resolved: bool
  }
)

(define-map dispute-votes
  {
    dispute-id: uint,
    arbitrator-id: uint
  }
  {
    vote: (string-ascii 10),
    voted-at: uint
  }
)

(define-map user-balances
  { user: principal }
  { balance: uint }
)

(define-private (get-balance (user principal))
  (default-to u0 (get balance (map-get? user-balances { user: user })))
)

(define-private (set-balance (user principal) (amount uint))
  (map-set user-balances { user: user } { balance: amount })
)

(define-private (transfer-internal (from principal) (to principal) (amount uint))
  (let
    (
      (from-balance (get-balance from))
      (to-balance (get-balance to))
    )
    (if (>= from-balance amount)
      (begin
        (set-balance from (- from-balance amount))
        (set-balance to (+ to-balance amount))
        (ok true)
      )
      ERR_INSUFFICIENT_FUNDS
    )
  )
)

(define-public (deposit (amount uint))
  (let
    (
      (current-balance (get-balance tx-sender))
    )
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (set-balance tx-sender (+ current-balance amount))
    (ok amount)
  )
)

(define-public (withdraw (amount uint))
  (let
    (
      (current-balance (get-balance tx-sender))
    )
    (if (>= current-balance amount)
      (begin
        (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
        (set-balance tx-sender (- current-balance amount))
        (ok amount)
      )
      ERR_INSUFFICIENT_FUNDS
    )
  )
)

(define-public (register-arbitrator)
  (let
    (
      (arbitrator-id (var-get next-arbitrator-id))
      (user-balance (get-balance tx-sender))
    )
    (if (>= user-balance MIN_ARBITRATOR_STAKE)
      (begin
        (try! (transfer-internal tx-sender (as-contract tx-sender) MIN_ARBITRATOR_STAKE))
        (map-set arbitrators
          { arbitrator-id: arbitrator-id }
          {
            address: tx-sender,
            stake: MIN_ARBITRATOR_STAKE,
            reputation: u100,
            active: true,
            disputes-resolved: u0
          }
        )
        (map-set arbitrator-addresses
          { address: tx-sender }
          { arbitrator-id: arbitrator-id }
        )
        (var-set next-arbitrator-id (+ arbitrator-id u1))
        (ok arbitrator-id)
      )
      ERR_INSUFFICIENT_STAKE
    )
  )
)

(define-public (create-dispute (defendant principal) (amount uint) (description (string-ascii 500)))
  (let
    (
      (dispute-id (var-get next-dispute-id))
      (current-block stacks-block-height)
      (user-balance (get-balance tx-sender))
    )
    (if (>= user-balance (+ amount DISPUTE_FEE))
      (begin
        (try! (transfer-internal tx-sender (as-contract tx-sender) (+ amount DISPUTE_FEE)))
        (map-set disputes
          { dispute-id: dispute-id }
          {
            plaintiff: tx-sender,
            defendant: defendant,
            amount: amount,
            description: description,
            status: "pending",
            created-at: current-block,
            voting-end: (+ current-block VOTING_PERIOD),
            selected-arbitrators: (list),
            votes-for-plaintiff: u0,
            votes-for-defendant: u0,
            resolved: false
          }
        )
        (var-set next-dispute-id (+ dispute-id u1))
        (ok dispute-id)
      )
      ERR_INSUFFICIENT_FUNDS
    )
  )
)
(define-private (select-arbitrators-for-dispute (dispute-id uint))
  (let
    (
      (arbitrator-1 u1)
      (arbitrator-2 u2)
      (arbitrator-3 u3)
    )
    (list arbitrator-1 arbitrator-2 arbitrator-3)
  )
)

(define-public (start-arbitration (dispute-id uint))
  (let
    (
      (dispute (unwrap! (map-get? disputes { dispute-id: dispute-id }) ERR_DISPUTE_NOT_FOUND))
      (selected-arbitrators (select-arbitrators-for-dispute dispute-id))
    )
    (if (is-eq (get status dispute) "pending")
      (begin
        (map-set disputes
          { dispute-id: dispute-id }
          (merge dispute {
            status: "active",
            selected-arbitrators: selected-arbitrators
          })
        )
        (ok true)
      )
      ERR_INVALID_STATUS
    )
  )
)

(define-public (vote-on-dispute (dispute-id uint) (vote-for-plaintiff bool))
  (let
    (
      (dispute (unwrap! (map-get? disputes { dispute-id: dispute-id }) ERR_DISPUTE_NOT_FOUND))
      (arbitrator-data (unwrap! (map-get? arbitrator-addresses { address: tx-sender }) ERR_NOT_ARBITRATOR))
      (arbitrator-id (get arbitrator-id arbitrator-data))
      (current-block stacks-block-height)
    )
    (if (and 
          (is-eq (get status dispute) "active")
          (< current-block (get voting-end dispute))
          (is-none (map-get? dispute-votes { dispute-id: dispute-id, arbitrator-id: arbitrator-id })))
      (begin
        (map-set dispute-votes
          { dispute-id: dispute-id, arbitrator-id: arbitrator-id }
          {
            vote: (if vote-for-plaintiff "plaintiff" "defendant"),
            voted-at: current-block
          }
        )
        (if vote-for-plaintiff
          (map-set disputes
            { dispute-id: dispute-id }
            (merge dispute { votes-for-plaintiff: (+ (get votes-for-plaintiff dispute) u1) })
          )
          (map-set disputes
            { dispute-id: dispute-id }
            (merge dispute { votes-for-defendant: (+ (get votes-for-defendant dispute) u1) })
          )
        )
        (ok true)
      )
      (if (>= current-block (get voting-end dispute))
        ERR_VOTING_ENDED
        ERR_ALREADY_VOTED
      )
    )
  )
)
(define-public (resolve-dispute (dispute-id uint))
  (let
    (
      (dispute (unwrap! (map-get? disputes { dispute-id: dispute-id }) ERR_DISPUTE_NOT_FOUND))
      (current-block stacks-block-height)
      (plaintiff-votes (get votes-for-plaintiff dispute))
      (defendant-votes (get votes-for-defendant dispute))
      (total-votes (+ plaintiff-votes defendant-votes))
    )
    (if (and 
          (is-eq (get status dispute) "active")
          (>= current-block (get voting-end dispute))
          (not (get resolved dispute))
          (>= total-votes MIN_ARBITRATORS))
      (let
        (
          (plaintiff-wins (> plaintiff-votes defendant-votes))
          (winner (if plaintiff-wins (get plaintiff dispute) (get defendant dispute)))
          (amount (get amount dispute))
        )
        (try! (as-contract (transfer-internal tx-sender winner amount)))
        (map-set disputes
          { dispute-id: dispute-id }
          (merge dispute {
            status: "resolved",
            resolved: true
          })
        )
        (ok plaintiff-wins)
      )
      ERR_INVALID_STATUS
    )
  )
)

(define-read-only (get-dispute (dispute-id uint))
  (map-get? disputes { dispute-id: dispute-id })
)

(define-read-only (get-arbitrator (arbitrator-id uint))
  (map-get? arbitrators { arbitrator-id: arbitrator-id })
)

(define-read-only (get-arbitrator-by-address (address principal))
  (match (map-get? arbitrator-addresses { address: address })
    arbitrator-data (map-get? arbitrators { arbitrator-id: (get arbitrator-id arbitrator-data) })
    none
  )
)

(define-read-only (get-user-balance (user principal))
  (get-balance user)
)

(define-read-only (get-dispute-vote (dispute-id uint) (arbitrator-id uint))
  (map-get? dispute-votes { dispute-id: dispute-id, arbitrator-id: arbitrator-id })
)

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)


(define-map arbitrator-performance
  { arbitrator-id: uint }
  {
    total-votes: uint,
    majority-votes: uint,
    performance-score: uint,
    last-reward-height: uint,
    total-rewards-earned: uint
  }
)

(define-private (update-performance-score (arbitrator-id uint) (was-majority bool))
  (let
    (
      (current-perf (default-to
        { total-votes: u0, majority-votes: u0, performance-score: u100, last-reward-height: u0, total-rewards-earned: u0 }
        (map-get? arbitrator-performance { arbitrator-id: arbitrator-id })
      ))
      (new-total-votes (+ (get total-votes current-perf) u1))
      (new-majority-votes (if was-majority (+ (get majority-votes current-perf) u1) (get majority-votes current-perf)))
      (majority-rate (if (> new-total-votes u0) (/ (* new-majority-votes u100) new-total-votes) u0))
      (new-score (/ (+ (* (get performance-score current-perf) PERFORMANCE_DECAY_RATE) (* majority-rate u5)) u100))
    )
    (map-set arbitrator-performance
      { arbitrator-id: arbitrator-id }
      (merge current-perf {
        total-votes: new-total-votes,
        majority-votes: new-majority-votes,
        performance-score: new-score
      })
    )
    (ok new-score)
  )
)

(define-private (calculate-reward (arbitrator-id uint))
  (let
    (
      (perf-data (unwrap! (map-get? arbitrator-performance { arbitrator-id: arbitrator-id }) (ok u0)))
      (arbitrator-data (unwrap! (map-get? arbitrators { arbitrator-id: arbitrator-id }) (ok u0)))
    )
    (if (and 
          (>= (get total-votes perf-data) MIN_DISPUTES_FOR_REWARDS)
          (>= (get performance-score perf-data) u80))
      (let
        (
          (base-reward (/ PERFORMANCE_REWARD_POOL u100))
          (score-multiplier (get performance-score perf-data))
          (final-reward (/ (* base-reward score-multiplier) u100))
        )
        (ok final-reward)
      )
      (ok u0)
    )
  )
)

(define-public (distribute-performance-rewards (dispute-id uint))
  (let
    (
      (dispute (unwrap! (map-get? disputes { dispute-id: dispute-id }) ERR_DISPUTE_NOT_FOUND))
    )
    (if (and (get resolved dispute) (> (var-get total-reward-pool) u0))
      (ok true)
      (ok false)
    )
  )
)

(define-private (distribute-single-reward (arb-data { arbitrator-id: uint, won-majority: bool }) (acc uint))
  (let
    (
      (arbitrator-id (get arbitrator-id arb-data))
      (won-majority (get won-majority arb-data))
      (reward-amount (unwrap-panic (calculate-reward arbitrator-id)))
    )
    (begin
      (if (and won-majority (> reward-amount u0))
        (begin
          (unwrap-panic (update-performance-score arbitrator-id won-majority))
          (let
            (
              (arbitrator-data (unwrap-panic (map-get? arbitrators { arbitrator-id: arbitrator-id })))
              (arbitrator-address (get address arbitrator-data))
            )
            (unwrap-panic (as-contract (transfer-internal tx-sender arbitrator-address reward-amount)))
            (var-set total-reward-pool (- (var-get total-reward-pool) reward-amount))
          )
          true
        )
        (begin
          (unwrap-panic (update-performance-score arbitrator-id won-majority))
          true
        )
      )
    )
    (+ acc u1)
  )
)

(define-public (fund-reward-pool (amount uint))
  (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set total-reward-pool (+ (var-get total-reward-pool) amount))
    (ok (var-get total-reward-pool))
  )
)

(define-read-only (get-arbitrator-performance (arbitrator-id uint))
  (map-get? arbitrator-performance { arbitrator-id: arbitrator-id })
)

(define-read-only (get-reward-pool-balance)
  (var-get total-reward-pool)
)

(define-read-only (get-estimated-reward (arbitrator-id uint))
  (calculate-reward arbitrator-id)
)
