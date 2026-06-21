# AGENTS.md — provena-contracts

Kontekst za AI agente i nove saradnike. Pročitaj pre rada na ovom repou.

## Sistem (šira slika)

Provena radi satelitsku verifikaciju da parcela nije krčena posle baseline
datuma (podrazumevano **31.12.2020**) — audit-spreman dokaz za EUDR. Sistem je
**polyrepo**, četiri zasebna git repoa:

| Repo | Jezik | Uloga |
|------|-------|-------|
| provena-api | Go | servisni / menadžment sloj |
| provena-verify-service | Python | analitički worker (koordinate → dokaz) |
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
  (`make sdk-go`, `make sdk-python`, `make types-go`, `make types-python`).

## Ko šta koristi

- provena-api: implementira `openapi.yaml`; Go tipovi queue poruka.
- provena-verify-service: Python tipovi queue poruka.
- spoljni klijenti: generisan SDK iz `openapi.yaml`.

## Faza

Faza 0–1: dovoljne su JSON Schema datoteke da se Go i Python slažu oko poruka.
Pun OpenAPI→SDK pipeline se isplati u Fazi C (API otvoren spolja).

Detalji: `README.md`.
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
