# provena-contracts — generisanje SDK-ova i provera ugovora.
# Alati su ilustrativni; instaliraju se po potrebi (vidi README).

OPENAPI      := openapi.yaml
OUT          := generated
GEN_IMAGE    := openapitools/openapi-generator-cli:latest

.PHONY: help lint diff sdk-go sdk-python types-python types-go clean

help:
	@echo "lint          - validacija openapi.yaml i JSON shema"
	@echo "diff BASE=ref - breaking-change diff openapi.yaml vs git ref"
	@echo "sdk-go        - generiši Go klijent iz openapi.yaml"
	@echo "sdk-python    - generiši Python klijent iz openapi.yaml"
	@echo "types-python  - generiši Python tipove iz JSON shema (queue poruke)"
	@echo "types-go      - generiši Go tipove iz JSON shema (queue poruke)"

# --- validacija ---
lint:
	npx -y @redocly/cli@latest lint $(OPENAPI)
	npx -y ajv-cli@latest compile -s schemas/job.schema.json
	npx -y ajv-cli@latest compile -s schemas/result.schema.json

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

# --- tipovi iz JSON shema (unutrašnje queue poruke) ---
types-python:
	pip install datamodel-code-generator
	datamodel-codegen --input schemas --input-file-type jsonschema --output $(OUT)/python_types/models.py

types-go:
	go run github.com/atombender/go-jsonschema/cmd/gojsonschema@latest \
		-p contracts schemas/job.schema.json schemas/result.schema.json > $(OUT)/go_types/contracts.go

clean:
	rm -rf $(OUT)
