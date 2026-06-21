# provena-contracts

**Jedini izvor istine za ugovore Provena sistema.** Svi ostali repoi *koriste* ovaj — niko ne definiše ugovor kod sebe.

Cilj: kad se ugovor promeni, promena je vidljiva i eksplicitna (diff spec-a + regenerisan SDK koji obara build na nekompatibilnoj promeni), umesto da tiho pukne u runtime-u.

---

## Dve granice, dva spec-a

Sistem ima dve različite granice komunikacije, i svaka ima svoj format:

| Granica | Ko ↔ ko | Transport | Spec |
|---------|---------|-----------|------|
| Spoljni API | `provena-api` ↔ kupci / konsultanti | HTTP/REST | [`openapi.yaml`](openapi.yaml) |
| Unutrašnja | `provena-api` ↔ `provena-verify-service` | red poslova (poruke) | [`schemas/job.schema.json`](schemas/job.schema.json), [`schemas/result.schema.json`](schemas/result.schema.json) |

OpenAPI opisuje request/response i ne pokriva asinhrone poruke — zato unutrašnja granica koristi JSON Schema.

---

## Verzionisanje

- **OpenAPI:** `info.version` (semver). Bump na svaku promenu.
- **Queue poruke:** `contract_version` (integer) u svakoj poruci. Nekompatibilna promena => povećaj broj; primalac može da odbije nepoznatu verziju.

CI (`.github/workflows/contract-diff.yml`) na svaki PR validira spec i pokreće **oasdiff breaking** — nekompatibilna promena obara build pre merge-a.

---

## Generisanje SDK-ova i tipova

```bash
make lint                 # validacija openapi.yaml + JSON shema
make diff BASE=origin/main  # breaking-change provera lokalno

make sdk-go               # Go klijent iz openapi.yaml  -> generated/go
make sdk-python           # Python klijent iz openapi.yaml -> generated/python

make types-go             # Go tipovi iz JSON shema (queue) -> generated/go_types
make types-python         # Python tipovi iz JSON shema (queue) -> generated/python_types
```

Generisani kod ide u `generated/` i **ne komituje se** (vidi `.gitignore`); generiše se u CI-u ili pre objave SDK paketa. Potrebni alati: Docker (za openapi-generator/oasdiff), Node (redocly/ajv), opciono Python/Go za type-generatore.

---

## Kako ga repoi koriste

- **`provena-api`** — implementira `openapi.yaml`; koristi Go tipove queue poruka (`types-go`) za slanje `job` / čitanje `result`.
- **`provena-verify-service`** — koristi Python tipove queue poruka (`types-python`) za čitanje `job` / slanje `result`.
- **Kupci / konsultanti** — dobijaju generisan klijentski SDK (Go/Python/TS) iz `openapi.yaml`.

Predlog toka: promena ide prvo ovde (spec) → CI proveri breaking → objavi novu verziju → repoi povuku novu verziju SDK-a/tipova.

---

## Fazna napomena

U Fazi 0–1 (demo, prvi piloti, sve pokreće osnivač) dovoljne su same JSON Schema datoteke da se Go i Python slažu oko poruka. Pun OpenAPI → SDK pipeline se isplati u Fazi C, kad se API otvori spoljnim klijentima.
