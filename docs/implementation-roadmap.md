# Provena API — roadmap (contracts)

Kratak pregled verzija OpenAPI ugovora. Detaljan plan: [provena-api/docs/implementation-plan.md](https://github.com/NNikolaG/provena-api/blob/main/docs/implementation-plan.md).

| Verzija | Milestone | Endpoint grupe |
|---------|-----------|----------------|
| 0.4.x | Legacy | auth, jobs (verify-only) |
| 0.5.0 | M0 | + zajednički schemas, tag struktura |
| 0.6.0 | M1 | + suppliers, locations |
| 0.7.0 | M2 | + location verify, verify-jobs |
| 0.8.0 | M3 | + evidence vault |
| 0.9.0 | M4 | + lots, lot-events, shipments (planirano) |
| 1.0.0 | M4 | + packages, dashboard (planirano) |

**Pravilo:** FE i api prate istu `info.version` / `VERSION` fajl.
