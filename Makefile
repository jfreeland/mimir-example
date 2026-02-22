MIMIR_ADDR := https://prometheus-us-central1.grafana.net
ALERTMANAGER_ADDR := https://alertmanager-us-central1.grafana.net
RULES_DIR  := rules

.PHONY: sync lint list print am-sync am-get am-verify

sync: lint
	@mimirtool rules sync \
		--address="$(MIMIR_ADDR)" \
		--user="$(MIMIR_USERNAME)" \
		--key="$(MIMIR_ACCESS_TOKEN)" \
		--rule-dirs="$(RULES_DIR)"

lint:
	mimirtool rules lint $(wildcard $(RULES_DIR)/*.yaml)

list:
	@mimirtool rules list \
		--address="$(MIMIR_ADDR)" \
		--user="$(MIMIR_USERNAME)" \
		--key="$(MIMIR_ACCESS_TOKEN)"

print:
	@mimirtool rules print \
		--address="$(MIMIR_ADDR)" \
		--user="$(MIMIR_USERNAME)" \
		--key="$(MIMIR_ACCESS_TOKEN)"

am-sync: am-verify
	@mimirtool alertmanager load alertmanager.yaml \
		--address="$(ALERTMANAGER_ADDR)" \
		--id="$(MIMIR_ALERTMANAGER_ID)" \
		--key="$(MIMIR_ACCESS_TOKEN)"

am-get:
	@mimirtool alertmanager get \
		--address="$(ALERTMANAGER_ADDR)" \
		--id="$(MIMIR_ALERTMANAGER_ID)" \
		--key="$(MIMIR_ACCESS_TOKEN)"

am-verify:
	@mimirtool alertmanager verify alertmanager.yaml
