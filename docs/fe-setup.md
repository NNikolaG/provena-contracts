# Frontend setup — Provena API

FE koristi **generisani TypeScript SDK** iz `openapi.yaml`. Ručno ne pišite HTTP tipove.

---

## Preduslovi

- Node 20+
- Docker (za `make sdk-typescript`)
- Kloniran `provena-contracts` repo pored FE projekta

---

## Generisanje SDK-a

```bash
cd provena-contracts
make sdk-typescript
```

Izlaz: `generated/typescript/` (ne komituje se — generiše lokalno ili u CI).

### Korišćenje u FE projektu

**Opcija A — npm link (lokalni razvoj):**

```bash
cd provena-contracts/generated/typescript
npm install && npm run build
npm link

cd /path/to/provena-fe
npm link @provena/api-client
```

**Opcija B — file dependency u `package.json`:**

```json
{
  "dependencies": {
    "@provena/api-client": "file:../provena-contracts/generated/typescript"
  }
}
```

Posle svake promene ugovora: `make sdk-typescript` + rebuild FE.

---

## Env varijable

| Varijabla | Primer | Opis |
|-----------|--------|------|
| `VITE_API_URL` | `http://localhost:8080` | Base URL provena-api |
| `VITE_API_VERSION` | `0.8.0` | Contracts verzija (informativno) |

---

## Autentikacija

### Platform UI (Angular app)

1. `POST /v1/auth/login` — telo `{ email, password }`
2. Odgovor: `{ access_token, token_type, expires_in }`
3. Refresh token u **HttpOnly cookie** `provena_refresh` — fetch mora imati `credentials: 'include'`
4. Zaštićeni pozivi: header `Authorization: Bearer <access_token>`
5. Osvežavanje: `POST /v1/auth/refresh` (cookie automatski)
6. Profil: `GET /v1/auth/me`
7. Odjava: `POST /v1/auth/logout`

### Integracije / skripte

API ključ tenant-a: `Authorization: Bearer prov_…`

---

## CORS

Lokalni FE (npr. `http://localhost:4200`) mora biti u `CORS_ALLOWED_ORIGINS` na api servisu. Vidi `provena-deploy` compose env.

---

## Primeri poziva (fetch)

### Login

```typescript
const res = await fetch(`${API_URL}/v1/auth/login`, {
  method: 'POST',
  credentials: 'include',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, password }),
});
const { access_token } = await res.json();
```

### Lista dobavljača (M1+)

```typescript
const res = await fetch(`${API_URL}/v1/suppliers?limit=20`, {
  headers: { Authorization: `Bearer ${access_token}` },
});
const { suppliers, next_cursor } = await res.json();
```

### Kreiranje lokacije (M1+)

```typescript
await fetch(`${API_URL}/v1/locations`, {
  method: 'POST',
  headers: {
    Authorization: `Bearer ${access_token}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    supplier_id: '...',
    label: 'Parcela A',
    geometry: { type: 'Polygon', coordinates: [/* WGS84 */] },
  }),
});
```

### Pokretanje verify (M2+)

```typescript
await fetch(`${API_URL}/v1/locations/${locationId}/verify`, {
  method: 'POST',
  headers: {
    Authorization: `Bearer ${access_token}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ baseline_date: '2020-12-31' }),
});
```

---

## Preporučeni redosled ekrana

1. Login  
2. Supplier list → Supplier detail  
3. Location map (bbox filter: `GET /v1/locations?bbox=…`)  
4. Location import (`POST /v1/locations/import`)  
5. Verify badge na lokaciji (M2)  
6. Evidence upload (M3)  

---

## Mock dok api ne stigne

[Kong Prism](https://github.com/stoplightio/prism) ili `@stoplight/prism-cli`:

```bash
npx @stoplight/prism-cli mock openapi.yaml
```

FE može raditi paralelno sa contracts PR-om pre nego što api implementira handler.

---

## Verzije po milestone-u

| FE milestone | Min contracts verzija |
|--------------|----------------------|
| Skeleton + auth | 0.5.0 |
| Dobavljači + mapa | 0.6.0 |
| Verify UI | 0.7.0 |
| Dokumenti | 0.8.0 |

Proveri `VERSION` fajl u `provena-contracts` root-u.
