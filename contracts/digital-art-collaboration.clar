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

