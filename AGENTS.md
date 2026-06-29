# AGENTS.md — provena-contracts

Kontekst za AI agente i nove saradnike. Pročitaj pre rada na ovom repou.

## Sistem (šira slika)

Provena je **horizontalni compliance engine** za regionalne izvoznike ka EU.
Product spec: [provena-api/docs/provena-spec-v2.md](https://github.com/NNikolaG/provena-api/blob/main/docs/provena-spec-v2.md).
Roadmap: `docs/implementation-roadmap.md`, FE: `docs/fe-setup.md`.

Sistem je **polyrepo**:

| Repo | Jezik | Uloga |
|------|-------|-------|
| provena-api | Go | implementira `openapi.yaml` |
| provena-fe | TypeScript/Angular | generisani TS SDK (`make sdk-typescript`) |
| provena-verify-service | Python | legacy queue worker (deprecated) |
| **provena-contracts** (ovaj) | spec | izvor istine za ugovore |
| provena-deploy | infra | orkestrator (docker-compose za ceo sistem) |

## Uloga ovog repoa

Ovo je **jedini izvor istine za ugovore**. Niko drugi ne definiše oblike poruka
ni API kod sebe — svi generišu/povlače odavde. Cilj: promena ugovora je
eksplicitna i hvata se u CI-u, ne tiho puca u runtime-u.

Dve granice, dva spec-a:

| Granica | Transport | Fajl |
|---------|-----------|------|
| `api` ↔ kupci/konsultanti | HTTP/REST | `openapi.yaml` |
| `api` ↔ `worker` | red poslova (poruke) | `schemas/job.schema.json`, `schemas/result.schema.json` |

(OpenAPI ne pokriva asinhrone poruke — zato JSON Schema za queue.)

## Pravila izmene (VAŽNO)

- Svaka promena ugovora počinje **ovde**, ne u servisima.
- Bump verzije: `info.version` (OpenAPI, semver) i/ili `contract_version`
  (integer u queue porukama) na nekompatibilnu promenu.
- CI (`.github/workflows/contract-diff.yml`) validira spec i pokreće
  **oasdiff breaking** — breaking promena obara PR.
- Generisani kod (`generated/`) se ne komituje; generiše se iz spec-a
  (`make sdk-go`, `make sdk-python`, `make sdk-typescript`, `make types-go`, `make types-python`).

## Ko šta koristi

- provena-api: implementira `openapi.yaml`
- provena-fe: `make sdk-typescript` → Angular klijent
- provena-verify-service: legacy Python tipovi queue poruka
- spoljni integratori: generisan SDK (Go/Python/TS)

## Faza

**v2 MVP:** OpenAPI v0.8.0 — auth, suppliers, locations, verify (Whisp), evidence.
Legacy jobs/upload deprecated. Detalji: `docs/implementation-roadmap.md`, `docs/fe-setup.md`.
---

## Odakle vući kontekst (povezani repoi)

Svaki repo je samostalan, ali pripada istom sistemu. Kad ti treba šira slika ili ugovor, kontekst je OVDE — ne pretpostavljaj:

1. **Ovaj repo:** `AGENTS.md` / `CLAUDE.md` (ovaj kontekst) + `README.md` + `SPEC.md` (ako postoji) — uloga, faze, pokretanje.
2. **Ugovor = izvor istine:** repo **provena-contracts** → `openapi.yaml` (spoljni API) i `schemas/*.json` (queue poruke). Nikad ne definiši ni ne menjaj ugovor lokalno; pročitaj/povuci odavde.
3. **Ceo sistem / kako se diže:** repo **provena-deploy** → orkestrator (docker-compose).

GitHub:
- provena-api — https://github.com/NNikolaG/provena-api
- provena-verify-service — https://github.com/NNikolaG/provena-verify-service
- provena-contracts — https://github.com/NNikolaG/provena-contracts
- provena-deploy — https://github.com/NNikolaG/provena-deploy

**Pravilo:** promena koja dira ugovor počinje u `provena-contracts` (bump verzije + CI breaking-check), pa se ovde povuče. Lokalni tipovi/modeli MORAJU da prate `provena-contracts` (ne smeju da se raziđu).
