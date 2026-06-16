# aws-notes — local dev commands
#
# The site is a static docsify app: the shell (index.html, css/, nav files) lives
# at the repo ROOT and the notes live under notes/. docsify loads from a CDN, so
# there's no build step — these targets just serve the folder and check structure.

ROOT := .
PORT ?= 3000
URL  := http://localhost:$(PORT)/

.DEFAULT_GOAL := help
.PHONY: help serve open stop verify

help: ## show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}'

serve: ## serve the site locally from the repo root (PORT=3000 by default)
	@echo "serving $(ROOT) at $(URL)  (ctrl-c to stop)"
	@python3 -m http.server $(PORT)

open: ## open the served site in your browser
	@open $(URL) 2>/dev/null || xdg-open $(URL) 2>/dev/null || echo "open $(URL)"

stop: ## stop a server left running on $(PORT)
	@lsof -ti:$(PORT) | xargs kill 2>/dev/null && echo "stopped server on $(PORT)" || echo "nothing running on $(PORT)"

verify: ## check the house rules: stylesheet first line, sidebar coverage, links
	@ok=1; \
	link='<link rel="stylesheet" href="./css/globals.css">'; \
	for f in $$(find notes -name '*.md') home.md search.md; do \
		first=$$(head -1 "$$f"); \
		if [ "$$first" != "$$link" ]; then echo "  ✗ first line: $$f"; ok=0; fi; \
	done; \
	for f in $$(find notes -name '*.md'); do \
		grep -q "/$$f)" _sidebar.md || { echo "  ✗ orphan (not in _sidebar.md): $$f"; ok=0; }; \
	done; \
	grep -oE '\]\((/[^)]+\.md)\)' _sidebar.md | sed -E 's/\]\(\/(.*)\)/\1/' | while read p; do \
		[ -f "$$p" ] || echo "  ✗ sidebar link missing: $$p"; \
	done; \
	[ $$ok -eq 1 ] && echo "✓ all checks passed" || { echo "✗ problems found"; exit 1; }
