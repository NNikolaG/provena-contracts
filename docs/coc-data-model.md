# Chain-of-custody — data model (M4, v0.9.0)

**Status:** v0.9.0 contracts — lots, lot-events, shipments u OpenAPI.

Detaljan opis: [provena-api/docs/implementation-plan.md](https://github.com/NNikolaG/provena-api/blob/main/docs/implementation-plan.md) (Appendix A).

## Planirani endpointi

| Prefix | Operacije |
|--------|-----------|
| `/v1/lots` | CRUD lotova |
| `/v1/lot-events` | receipt, process, output, shipment događaji |
| `/v1/shipments` | isporuke ka EU kupcu |
| `/v1/packages` | compliance paket (DDS export, ne TRACES) |
| `/v1/dashboard/summary` | agregat stub 1/2/3 po supplier/lot |

## Verzionisanje

- v0.9.0 — additive: lots + lot-events + shipments
- v1.0.0 — packages + dashboard (potencijalno breaking na agregatima)
