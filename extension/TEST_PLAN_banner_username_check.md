# Test Plan — Banner salvataggio: controllo username (Storia M)

## Setup comune

1. Server Rails raggiungibile (`http://localhost:3000`).
2. Estensione caricata in modalità sviluppatore (`chrome://extensions`) con `baseUrl` configurato e utente autenticato.
3. Ricaricare l'estensione dopo ogni modifica al codice.

## Casi di test

| ID  | Precondizione | Azione | Atteso |
|-----|--------------|--------|--------|
| T01 | `alice@example.com` già salvata per `example.com` | Login con `bob@example.com` | Banner appare |
| T02 | `alice@example.com` già salvata per `example.com` | Login con `alice@example.com` | Banner NON appare |
| T03 | Nessuna credenziale per il dominio | Login con qualsiasi username | Banner appare |
| T04 | `alice@example.com` salvata | Login con `Alice@example.com` (maiuscola) | Banner appare (confronto case-sensitive) |
| T05 | T01 completato: banner apparso per `bob@` | Salvare `bob@`, poi rifare login con `bob@` | Banner NON appare |

## Regressioni

- R01: stessa credenziale già salvata — banner soppresso → coperto da T02
- R02: dominio senza credenziali — banner appare → coperto da T03
