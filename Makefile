# provena-contracts — generisanje SDK-ova i provera ugovora.
# Alati su ilustrativni; instaliraju se po potrebi (vidi README).

OPENAPI      := openapi.yaml
OUT          := generated
GEN_IMAGE    := openapitools/openapi-generator-cli:latest

.PHONY: help lint version-check diff sdk-go sdk-python sdk-typescript types-python types-go clean

help:
	@echo "lint          - validacija openapi.yaml i JSON shema"
	@echo "version-check - VERSION fajl mora da se poklapa sa openapi info.version"
	@echo "diff BASE=ref - breaking-change diff openapi.yaml vs git ref"
	@echo "sdk-go        - generiši Go klijent iz openapi.yaml"
	@echo "sdk-python    - generiši Python klijent iz openapi.yaml"
	@echo "sdk-typescript - generiši TypeScript klijent iz openapi.yaml"
	@echo "types-go      - generiši Go tipove iz JSON shema (queue poruke)"

# --- validacija ---
lint:
	npx -y @redocly/cli@latest lint --config .redocly.yaml $(OPENAPI)
	npx -y ajv-cli@latest compile -s schemas/job.schema.json
	npx -y ajv-cli@latest compile -s schemas/result.schema.json

# --- verzija: VERSION fajl == openapi info.version (bez spoljnih zavisnosti) ---
version-check:
	@v_file=$$(tr -d '[:space:]' < VERSION); \
	v_spec=$$(grep -E '^[[:space:]]+version:' $(OPENAPI) | head -1 | sed -E 's/.*version:[[:space:]]*([^[:space:]#]+).*/\1/'); \
	if [ "$$v_file" != "$$v_spec" ]; then \
		echo "✗ neslaganje: VERSION ($$v_file) != openapi info.version ($$v_spec)"; \
		echo "  bumpuj oba na istu vrednost."; exit 1; \
	fi; \
	echo "✓ version-check OK ($$v_file)"

# --- breaking-change diff (CI ga koristi) ---
# BASE je git ref sa kojim poredimo (npr. origin/main).
diff:
	@test -n "$(BASE)" || (echo "Zadaj BASE=<git-ref>"; exit 1)
	git show $(BASE):$(OPENAPI) > /tmp/base-openapi.yaml
	docker run --rm -v $$PWD:/work -v /tmp:/tmp tufin/oasdiff:latest \
		breaking /tmp/base-openapi.yaml /work/$(OPENAPI)

# --- klijentski SDK-ovi iz OpenAPI (spoljni API) ---
sdk-go:
	docker run --rm -v $$PWD:/local $(GEN_IMAGE) generate \
		-i /local/$(OPENAPI) -g go -o /local/$(OUT)/go --additional-properties=packageName=provenaapi

sdk-python:
	docker run --rm -v $$PWD:/local $(GEN_IMAGE) generate \
		-i /local/$(OPENAPI) -g python -o /local/$(OUT)/python --additional-properties=packageName=provena_client

sdk-typescript:
	docker run --rm -v $$PWD:/local $(GEN_IMAGE) generate \
		-i /local/$(OPENAPI) -g typescript-fetch -o /local/$(OUT)/typescript \
		--additional-properties=npmName=@provena/api-client,supportsES6=true,typescriptThreePlus=true

# --- tipovi iz JSON shema (unutrašnje queue poruke) ---
types-python:
	pip install datamodel-code-generator
	datamodel-codegen --input schemas --input-file-type jsonschema --output $(OUT)/python_types/models.py

types-go:
	go run github.com/atombender/go-jsonschema/cmd/gojsonschema@latest \
		-p contracts schemas/job.schema.json schemas/result.schema.json > $(OUT)/go_types/contracts.go

clean:
	rm -rf $(OUT)
