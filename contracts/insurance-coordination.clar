;; Insurance Coordination Contract
;; Manages coverage for equipment use

(define-map insurance-policies
  { policy-id: uint }
  {
    insurer: (string-ascii 64),
    policy-number: (string-ascii 32),
    coverage-start: uint,
    coverage-end: uint,
    coverage-amount: uint,
    deductible: uint
  }
)

(define-map device-policies
  { device-id: uint }
  { policy-id: uint }
)

(define-map claims
  { claim-id: uint }
  {
    device-id: uint,
    policy-id: uint,
    claim-date: uint,
    claim-amount: uint,
    claim-reason: (string-ascii 256),
    status: (string-ascii 16)
  }
)

(define-data-var last-policy-id uint u0)
(define-data-var last-claim-id uint u0)

(define-public (register-policy
    (insurer (string-ascii 64))
    (policy-number (string-ascii 32))
    (coverage-start uint)
    (coverage-end uint)
    (coverage-amount uint)
    (deductible uint))
  (let
    ((new-id (+ (var-get last-policy-id) u1)))
    (var-set last-policy-id new-id)
    (map-set insurance-policies
      { policy-id: new-id }
      {
        insurer: insurer,
        policy-number: policy-number,
        coverage-start: coverage-start,
        coverage-end: coverage-end,
        coverage-amount: coverage-amount,
        deductible: deductible
      }
    )
    (ok new-id)
  )
)

(define-public (assign-policy-to-device (device-id uint) (policy-id uint))
  (let
    (
      (device (contract-call? .device-registration get-device device-id))
      (policy (map-get? insurance-policies { policy-id: policy-id }))
    )
    ;; Check if device and policy exist
    (asserts! (is-some device) (err u404))
    (asserts! (is-some policy) (err u404))

    (map-set device-policies
      { device-id: device-id }
      { policy-id: policy-id }
    )
    (ok true)
  )
)

(define-public (file-claim
    (device-id uint)
    (claim-amount uint)
    (claim-reason (string-ascii 256)))
  (let
    (
      (device-policy (map-get? device-policies { device-id: device-id }))
      (current-time (get-block-info? time (- block-height u1)))
    )
    ;; Check if device has a policy
    (asserts! (is-some device-policy) (err u404))

    (let
      (
        (policy-id (get policy-id (unwrap-panic device-policy)))
        (policy (map-get? insurance-policies { policy-id: policy-id }))
        (new-id (+ (var-get last-claim-id) u1))
      )
      ;; Check if policy exists and is active
      (asserts! (is-some policy) (err u404))
      (asserts!
        (and
          (<= (get coverage-start (unwrap-panic policy)) (default-to u0 current-time))
          (>= (get coverage-end (unwrap-panic policy)) (default-to u0 current-time))
        )
        (err u403)
      )

      (var-set last-claim-id new-id)
      (map-set claims
        { claim-id: new-id }
        {
          device-id: device-id,
          policy-id: policy-id,
          claim-date: (default-to u0 current-time),
          claim-amount: claim-amount,
          claim-reason: claim-reason,
          status: "pending"
        }
      )
      (ok new-id)
    )
  )
)

(define-public (update-claim-status (claim-id uint) (new-status (string-ascii 16)))
  (let
    ((claim (map-get? claims { claim-id: claim-id })))
    (asserts! (is-some claim) (err u404))
    (map-set claims
      { claim-id: claim-id }
      (merge (unwrap-panic claim) { status: new-status })
    )
    (ok true)
  )
)

(define-read-only (get-policy (policy-id uint))
  (map-get? insurance-policies { policy-id: policy-id })
)

(define-read-only (get-device-policy (device-id uint))
  (map-get? device-policies { device-id: device-id })
)

(define-read-only (get-claim (claim-id uint))
  (map-get? claims { claim-id: claim-id })
)
