;; Constants
(define-constant contract-owner tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PROPOSAL (err u101))
(define-constant VOTING-PERIOD u144) ;; ~1 day in blocks

;; Types
(define-map proposals
    uint
    {
        description: (string-utf8 256),
        votes-for: uint,
        votes-against: uint,
        end-block: uint,
        executed: bool,
    }
)

(define-map user-votes
    {
        proposal-id: uint,
        voter: principal,
    }
    bool
)

(define-data-var proposal-count uint u0)

;; Public functions
(define-public (create-proposal (description (string-utf8 256)))
    (let ((proposal-id (+ (var-get proposal-count) u1)))
        (asserts! (<= (len description) u256) ERR-INVALID-PROPOSAL)
        (map-set proposals proposal-id {
            description: description,
            votes-for: u0,
            votes-against: u0,
            end-block: (+ stacks-block-height VOTING-PERIOD),
            executed: false,
        })
        (var-set proposal-count proposal-id)
        (ok proposal-id)
    )
)

(define-public (vote
        (proposal-id uint)
        (vote-for bool)
    )
    (let (
            (proposal (unwrap! (map-get? proposals proposal-id) ERR-INVALID-PROPOSAL))
            (voting-power (contract-call? .STXCompounder get-deposit tx-sender))
        )
        (asserts! (< stacks-block-height (get end-block proposal))
            ERR-INVALID-PROPOSAL
        )
        (asserts!
            (is-none (map-get? user-votes {
                proposal-id: proposal-id,
                voter: tx-sender,
            }))
            ERR-NOT-AUTHORIZED
        )
        (map-set user-votes {
            proposal-id: proposal-id,
            voter: tx-sender,
        }
            true
        )
        (if vote-for
            (map-set proposals proposal-id
                (merge proposal { votes-for: (+ (get votes-for proposal) voting-power) })
            )
            (map-set proposals proposal-id
                (merge proposal { votes-against: (+ (get votes-against proposal) voting-power) })
            )
        )
        (ok true)
    )
)

;; Read only functions
(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id)
)
