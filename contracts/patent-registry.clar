;; Patent Registry Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-payment (err u104))

;; Data Variables
(define-map patents
    { patent-id: uint }
    {
        owner: principal,
        title: (string-ascii 256),
        description: (string-utf8 1024),
        registration-date: uint,
        royalty-rate: uint,
        active: bool
    }
)

(define-map royalty-payments
    { patent-id: uint, licensee: principal }
    { amount: uint, last-payment: uint }
)

;; Public Functions
(define-public (register-patent (patent-id uint) (title (string-ascii 256)) (description (string-utf8 1024)) (royalty-rate uint))
    (let ((exists (get active (map-get? patents { patent-id: patent-id }))))
        (asserts! (is-none exists) err-already-registered)
        (ok (map-set patents
            { patent-id: patent-id }
            {
                owner: tx-sender,
                title: title,
                description: description,
                registration-date: block-height,
                royalty-rate: royalty-rate,
                active: true
            }
        ))
    )
)

(define-public (pay-royalty (patent-id uint))
    (let (
        (patent (unwrap! (map-get? patents { patent-id: patent-id }) err-not-found))
        (royalty-amount (get royalty-rate patent))
    )
    (asserts! (get active patent) err-not-found)
    (try! (stx-transfer? royalty-amount tx-sender (get owner patent)))
    (ok (map-set royalty-payments
        { patent-id: patent-id, licensee: tx-sender }
        { 
            amount: royalty-amount,
            last-payment: block-height
        }
    ))
    )
)

(define-public (deactivate-patent (patent-id uint))
    (let ((patent (unwrap! (map-get? patents { patent-id: patent-id }) err-not-found)))
        (asserts! (is-eq tx-sender (get owner patent)) err-unauthorized)
        (ok (map-set patents
            { patent-id: patent-id }
            (merge patent { active: false })
        ))
    )
)

;; Read-only Functions
(define-read-only (get-patent (patent-id uint))
    (ok (map-get? patents { patent-id: patent-id }))
)

(define-read-only (get-royalty-payment (patent-id uint) (licensee principal))
    (ok (map-get? royalty-payments { patent-id: patent-id, licensee: licensee }))
)
