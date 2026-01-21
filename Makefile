SHELL := /bin/bash
export DISABLE_BUNDLER_SETUP := 1

# ============================================================================
# Configuration
# ============================================================================
ifeq ($(OS),Windows_NT)
  DEFAULT_KITCHEN_YAML := .kitchen-win.yml
else
  DEFAULT_KITCHEN_YAML := .kitchen.yml
endif

KITCHEN_YAML ?= $(DEFAULT_KITCHEN_YAML)
RBENV_BIN := $(shell command -v rbenv 2>/dev/null)
ifdef RBENV_BIN
  KITCHEN_CMD ?= rbenv exec kitchen
else
  KITCHEN_CMD ?= kitchen
endif

# Platforms for Kitchen
PLATFORMS := win11 ubuntu-2404 rockylinux9

# Vagrant configuration
VAGRANT_BOX ?= windows11-security

export VAGRANT_BOX

# Ansible configuration
ANSIBLE_PLAYBOOK := tests/playbook.yml
ANSIBLE_INVENTORY := tests/inventory.ini

.DEFAULT_GOAL := help

# ============================================================================
# Help
# ============================================================================
.PHONY: help
help:
	@echo "Windows Base Role - Available Targets"
	@echo "======================================"
	@echo ""
	@echo "Validation:"
	@echo "  lint              Run ansible-lint on role"
	@echo "  syntax            Check playbook syntax"
	@echo "  check             Run all validation checks"
	@echo ""
	@echo "Vagrant Testing:"
	@echo "  vagrant-up        Start Vagrant VM and provision"
	@echo "  vagrant-provision Re-provision existing VM"
	@echo "  vagrant-ssh       SSH into Vagrant VM (PowerShell)"
	@echo "  vagrant-destroy   Destroy Vagrant VM"
	@echo "  vagrant-status    Show Vagrant VM status"
	@echo ""
	@echo "Kitchen Testing (KITCHEN_YAML=$(KITCHEN_YAML)):"
	@$(foreach p,$(PLATFORMS),echo "  test-$(p)         Full test cycle for $(p)" &&) true
	@$(foreach p,$(PLATFORMS),echo "  converge-$(p)     Converge only for $(p)" &&) true
	@$(foreach p,$(PLATFORMS),echo "  verify-$(p)       Verify only for $(p)" &&) true
	@$(foreach p,$(PLATFORMS),echo "  destroy-$(p)      Destroy VM for $(p)" &&) true
	@echo "  kitchen-list      List all Kitchen instances"
	@echo "  kitchen-status    Show Kitchen instance status"
	@echo ""
	@echo "Utilities:"
	@echo "  deps              Install dependencies (collections)"
	@echo "  box-list          List Vagrant boxes"
	@echo "  clean             Clean all build artifacts"
	@echo "  clean-all         Clean everything including VMs"
	@echo ""
	@echo "Quick Test Shortcuts:"
	@echo "  test              Run vagrant-up (quick test)"
	@echo "  test-choco        Test Chocolatey only"
	@echo "  test-security     Test security only"
	@echo "  test-agents       Test agents only"
	@echo "  test-credssp      Test CredSSP only"
	@echo ""
	@echo "Variables:"
	@echo "  VAGRANT_BOX       Vagrant box to use (default: $(VAGRANT_BOX))"
	@echo "  KITCHEN_YAML      Kitchen config file (default: $(DEFAULT_KITCHEN_YAML))"
	@echo "  TAGS              Ansible tags to run (e.g., TAGS=choco,security)"

# ============================================================================
# Validation Targets
# ============================================================================
.PHONY: lint
lint: deps
	@echo "Running ansible-lint..."
	ansible-lint .

.PHONY: syntax
syntax: deps
	@echo "Checking playbook syntax..."
	ansible-playbook --syntax-check $(ANSIBLE_PLAYBOOK)

.PHONY: check
check: lint syntax
	@echo "All validation checks passed."

# ============================================================================
# Vagrant Targets
# ============================================================================
.PHONY: vagrant-up
vagrant-up:
	@echo "Starting Vagrant VM (box: $(VAGRANT_BOX))..."
ifdef TAGS
	vagrant up --provision-with ansible -- --tags $(TAGS)
else
	vagrant up
endif

.PHONY: vagrant-provision
vagrant-provision:
	@echo "Provisioning Vagrant VM..."
ifdef TAGS
	vagrant provision -- --tags $(TAGS)
else
	vagrant provision
endif

.PHONY: vagrant-ssh
vagrant-ssh:
	@echo "Connecting to Vagrant VM..."
	vagrant powershell

.PHONY: vagrant-destroy
vagrant-destroy:
	@echo "Destroying Vagrant VM..."
	vagrant destroy -f

.PHONY: vagrant-status
vagrant-status:
	vagrant status

.PHONY: vagrant-reload
vagrant-reload:
	vagrant reload --provision

# ============================================================================
# Kitchen Targets
# ============================================================================
define KITCHEN_PLATFORM_TARGETS
.PHONY: test-$(1)
test-$(1): destroy-$(1)
	KITCHEN_YAML=$(KITCHEN_YAML) $(KITCHEN_CMD) test default-$(1)

.PHONY: converge-$(1)
converge-$(1):
ifdef TAGS
	KITCHEN_YAML=$(KITCHEN_YAML) $(KITCHEN_CMD) converge default-$(1) -- --tags $(TAGS)
else
	KITCHEN_YAML=$(KITCHEN_YAML) $(KITCHEN_CMD) converge default-$(1)
endif

.PHONY: verify-$(1)
verify-$(1):
	KITCHEN_YAML=$(KITCHEN_YAML) $(KITCHEN_CMD) verify default-$(1)

.PHONY: destroy-$(1)
destroy-$(1):
	KITCHEN_YAML=$(KITCHEN_YAML) $(KITCHEN_CMD) destroy default-$(1)

.PHONY: login-$(1)
login-$(1):
	KITCHEN_YAML=$(KITCHEN_YAML) $(KITCHEN_CMD) login default-$(1)
endef

$(foreach platform,$(PLATFORMS),$(eval $(call KITCHEN_PLATFORM_TARGETS,$(platform))))

.PHONY: kitchen-list
kitchen-list:
	KITCHEN_YAML=$(KITCHEN_YAML) $(KITCHEN_CMD) list

.PHONY: kitchen-status
kitchen-status:
	KITCHEN_YAML=$(KITCHEN_YAML) $(KITCHEN_CMD) list

.PHONY: kitchen-destroy-all
kitchen-destroy-all:
	KITCHEN_YAML=$(KITCHEN_YAML) $(KITCHEN_CMD) destroy

# ============================================================================
# Utility Targets
# ============================================================================
.PHONY: setup
setup:
	@./scripts/setup.sh all

.PHONY: deps
deps:
	@echo "Installing Ansible collections..."
	ansible-galaxy collection install ansible.windows chocolatey.chocolatey -p ./collections

.PHONY: box-list
box-list:
	vagrant box list

.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	rm -rf .vagrant/machines/*/virtualbox/
	rm -rf .kitchen/

.PHONY: clean-all
clean-all: clean vagrant-destroy kitchen-destroy-all
	@echo "All cleaned."

# ============================================================================
# Quick Test Shortcuts
# ============================================================================
.PHONY: test
test: vagrant-up
	@echo "Quick test completed."

.PHONY: test-choco
test-choco:
	$(MAKE) vagrant-provision TAGS=choco

.PHONY: test-security
test-security:
	$(MAKE) vagrant-provision TAGS=security

.PHONY: test-agents
test-agents:
	$(MAKE) vagrant-provision TAGS=agents

.PHONY: test-credssp
test-credssp:
	$(MAKE) vagrant-provision TAGS=credssp
