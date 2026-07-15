.PHONY: install uninstall package clean

PACKAGE_ID := com.alexey-anufriev.codexstatus
BUILD_DIR := build
PLASMOID := $(BUILD_DIR)/$(PACKAGE_ID).plasmoid
HELPER := package/contents/tools/codex-status.sh
DISCOVERY_HELPER := package/contents/tools/discover-codex.sh

install:
	./scripts/manage-package.sh install

uninstall:
	./scripts/manage-package.sh remove

package:
	chmod +x $(HELPER) $(DISCOVERY_HELPER)
	mkdir -p $(BUILD_DIR)
	rm -f $(PLASMOID)
	cd package && zip -qr ../$(PLASMOID) .
	@echo "Created $(PLASMOID)"

clean:
	rm -rf $(BUILD_DIR)
