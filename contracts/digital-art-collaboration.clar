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

(define-public (mint-nft (artwork-id uint) (price uint))
  (let (
    (artwork (unwrap! (map-get? artworks { artwork-id: artwork-id }) err-not-found))
    (new-nft-id (+ (var-get last-nft-id) u1))
  )
    (asserts! (get is-finalized artwork) err-unauthorized)
    (asserts! (is-none (get nft-id artwork)) err-already-exists)
    (map-set nfts { nft-id: new-nft-id } {
      artwork-id: artwork-id,
      owner: tx-sender,
      price: price
    })
    (map-set artworks { artwork-id: artwork-id }
      (merge artwork { nft-id: (some new-nft-id) })
    )
    (var-set last-nft-id new-nft-id)
    (ok new-nft-id)
  )
)

(define-public (buy-nft (nft-id uint))
  (let (
    (nft (unwrap! (map-get? nfts { nft-id: nft-id }) err-not-found))
    (artwork (unwrap! (map-get? artworks { artwork-id: (get artwork-id nft) }) err-not-found))
  )
    (try! (stx-transfer? (get price nft) tx-sender (get owner nft)))
    (try! (distribute-royalties nft-id))
    (ok (map-set nfts { nft-id: nft-id }
      (merge nft { owner: tx-sender })
    ))
  )
)

(define-private (distribute-royalties (nft-id uint))
  (let (
    (nft (unwrap! (map-get? nfts { nft-id: nft-id }) err-not-found))
    (artwork (unwrap! (map-get? artworks { artwork-id: (get artwork-id nft) }) err-not-found))
    (total-contributions (get total-contributions artwork))
    (price (get price nft))
  )
    (ok (fold distribute-to-artist
          (get collaborators artwork)
          { index: u0, price: price, total: total-contributions, artwork-id: (get artwork-id nft) }))
  )
)

(define-private (distribute-to-artist (artist principal) (context { index: uint, price: uint, total: uint, artwork-id: uint }))
  (let (
    (artwork (unwrap! (map-get? artworks { artwork-id: (get artwork-id context) }) context))
    (contribution (default-to u0 (element-at (get contributions artwork) (get index context))))
    (royalty (/ (* (get price context) contribution) (get total context)))
  )
    (match (as-contract (stx-transfer? royalty tx-sender artist))
      success (merge context { index: (+ (get index context) u1) })
      error context
    )
  )
)

;; Read-only Functions
(define-read-only (get-artist-info (artist-id principal))
  (map-get? artists { artist-id: artist-id })
)

(define-read-only (get-artwork-info (artwork-id uint))
  (map-get? artworks { artwork-id: artwork-id })
)

(define-read-only (get-nft-info (nft-id uint))
  (map-get? nfts { nft-id: nft-id })
)

