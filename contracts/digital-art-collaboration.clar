;; Digital Art Collaboration Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-percentage (err u104))

;; Data Maps
(define-map artists { artist-id: principal } { name: (string-utf8 50), registered: bool })
(define-map artworks { artwork-id: uint } {
  title: (string-utf8 100),
  description: (string-utf8 500),
  creator: principal,
  collaborators: (list 10 principal),
  contributions: (list 10 uint),
  total-contributions: uint,
  is-finalized: bool,
  nft-id: (optional uint)
})
(define-map nfts { nft-id: uint } {
  artwork-id: uint,
  owner: principal,
  price: uint
})

;; Variables
(define-data-var last-artwork-id uint u0)
(define-data-var last-nft-id uint u0)

;; Private Functions
(define-private (is-owner)
  (is-eq tx-sender contract-owner)
)

;; Public Functions
(define-public (register-artist (name (string-utf8 50)))
  (let ((artist-data { name: name, registered: true }))
    (if (is-some (map-get? artists { artist-id: tx-sender }))
      err-already-exists
      (ok (map-set artists { artist-id: tx-sender } artist-data))
    )
  )
)

(define-public (create-artwork (title (string-utf8 100)) (description (string-utf8 500)))
  (let (
    (artist (unwrap! (map-get? artists { artist-id: tx-sender }) err-unauthorized))
    (new-artwork-id (+ (var-get last-artwork-id) u1))
  )
    (map-set artworks { artwork-id: new-artwork-id } {
      title: title,
      description: description,
      creator: tx-sender,
      collaborators: (list tx-sender),
      contributions: (list u100),
      total-contributions: u100,
      is-finalized: false,
      nft-id: none
    })
    (var-set last-artwork-id new-artwork-id)
    (ok new-artwork-id)
  )
)

(define-public (add-contribution (artwork-id uint) (contribution uint))
  (let
    (
      (artwork (unwrap! (map-get? artworks { artwork-id: artwork-id }) err-not-found))
      (artist (unwrap! (map-get? artists { artist-id: tx-sender }) err-unauthorized))
    )
    (asserts! (not (get is-finalized artwork)) err-unauthorized)
    (ok (map-set artworks { artwork-id: artwork-id }
      (merge artwork {
        collaborators: (unwrap! (as-max-len? (append (get collaborators artwork) tx-sender) u10) err-unauthorized),
        contributions: (unwrap! (as-max-len? (append (get contributions artwork) contribution) u10) err-unauthorized),
        total-contributions: (+ (get total-contributions artwork) contribution)
      })
    ))
  )
)

(define-public (finalize-artwork (artwork-id uint))
  (let (
    (artwork (unwrap! (map-get? artworks { artwork-id: artwork-id }) err-not-found))
  )
    (asserts! (is-eq (get creator artwork) tx-sender) err-unauthorized)
    (asserts! (not (get is-finalized artwork)) err-unauthorized)
    (ok (map-set artworks { artwork-id: artwork-id }
      (merge artwork { is-finalized: true })
    ))
  )
)

