;; Device Registration Contract
;; Records details of specialized medical devices

(define-data-var last-device-id uint u0)

(define-map devices
  { device-id: uint }
  {
    name: (string-ascii 64),
    model: (string-ascii 64),
    serial-number: (string-ascii 32),
    manufacturer: (string-ascii 64),
    purchase-date: uint,
    warranty-expiry: uint,
    status: (string-ascii 16)
  }
)

(define-public (register-device
    (name (string-ascii 64))
    (model (string-ascii 64))
    (serial-number (string-ascii 32))
    (manufacturer (string-ascii 64))
    (purchase-date uint)
    (warranty-expiry uint))
  (let
    ((new-id (+ (var-get last-device-id) u1)))
    (var-set last-device-id new-id)
    (map-set devices
      { device-id: new-id }
      {
        name: name,
        model: model,
        serial-number: serial-number,
        manufacturer: manufacturer,
        purchase-date: purchase-date,
        warranty-expiry: warranty-expiry,
        status: "available"
      }
    )
    (ok new-id)
  )
)

(define-public (update-device-status (device-id uint) (new-status (string-ascii 16)))
  (let
    ((device (map-get? devices { device-id: device-id })))
    (asserts! (is-some device) (err u404))
    (map-set devices
      { device-id: device-id }
      (merge (unwrap-panic device) { status: new-status })
    )
    (ok true)
  )
)

(define-read-only (get-device (device-id uint))
  (map-get? devices { device-id: device-id })
)

(define-read-only (get-last-device-id)
  (var-get last-device-id)
)
