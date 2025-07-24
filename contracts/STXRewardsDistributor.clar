;; Constants
(define-constant contract-owner tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))

;; Data vars
(define-data-var last-distribution-block uint u0)
(define-data-var rewards-per-block uint u0)

;; Public functions
(define-public (initialize)
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
        (try! (contract-call? .STXCompounder set-rewards-distributor
            (as-contract tx-sender)
        ))
        (ok true)
    )
)

(define-public (distribute-rewards (amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (try! (contract-call? .STXCompounder compound-rewards amount))
        (var-set last-distribution-block stacks-block-height)
        (ok true)
    )
)

;; Read only functions
(define-read-only (get-pending-rewards)
    (let ((blocks-since-last (* (- stacks-block-height (var-get last-distribution-block))
            (var-get rewards-per-block)
        )))
        blocks-since-last
    )
)

;; Admin functions
(define-public (set-rewards-per-block (amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (var-set rewards-per-block amount)
        (ok true)
    )
)
