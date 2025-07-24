(define-map deposits
    { user: principal }
    { amount: uint }
)
(define-fungible-token ststx)
(define-data-var total-deposited uint u0)

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))

;; Admin
(define-data-var contract-paused bool false)
(define-data-var admin principal tx-sender)
(define-data-var rewards-distributor (optional principal) none)

(define-public (stake (amount uint))
    (begin
        (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (let ((current-deposit (default-to u0 (get amount (map-get? deposits { user: tx-sender })))))
            (map-set deposits { user: tx-sender } { amount: (+ amount current-deposit) })
            (var-set total-deposited (+ amount (var-get total-deposited)))
            (try! (ft-mint? ststx amount tx-sender))
            (ok true)
        )
    )
)

(define-public (set-rewards-distributor (distributor principal))
    (begin
        (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
        (var-set rewards-distributor (some distributor))
        (ok true)
    )
)

;; Read only functions
(define-read-only (get-deposit (user principal))
    (default-to u0 (get amount (map-get? deposits { user: user })))
)

(define-read-only (get-total-deposited)
    (var-get total-deposited)
)

(define-read-only (get-token-balance (user principal))
    (ft-get-balance ststx user)
)

;; Public functions
(define-public (unstake (amount uint))
    (let ((user-balance (default-to u0 (get amount (map-get? deposits { user: tx-sender })))))
        (asserts! (>= user-balance amount) ERR-INSUFFICIENT-BALANCE)
        (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
        (try! (ft-burn? ststx amount tx-sender))
        (try! (as-contract (stx-transfer? amount (as-contract tx-sender) tx-sender)))
        (map-set deposits { user: tx-sender } { amount: (- user-balance amount) })
        (var-set total-deposited (- (var-get total-deposited) amount))
        (ok true)
    )
)

(define-public (compound-rewards (reward uint))
    (begin
        (asserts! (> reward u0) ERR-INVALID-AMOUNT)
        (asserts! (is-some (var-get rewards-distributor)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (some tx-sender) (var-get rewards-distributor))
            ERR-NOT-AUTHORIZED
        )
        (try! (ft-mint? ststx reward (as-contract tx-sender)))
        (ok true)
    )
)

;; Admin functions
(define-public (toggle-pause)
    (begin
        (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
        (var-set contract-paused (not (var-get contract-paused)))
        (ok true)
    )
)

(define-public (emergency-withdraw)
    (begin
        (asserts! (var-get contract-paused) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
        (let ((balance (stx-get-balance (as-contract tx-sender))))
            (try! (as-contract (stx-transfer? balance (as-contract tx-sender) (var-get admin))))
            (ok balance)
        )
    )
)
