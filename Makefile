# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
build  :; forge build && forge remappings > remappings.txt
test   :; forge test
trace   :; forge test -vvv
clean  :; forge clean
snapshot :; forge snapshot --check
lint :; npm run lint
lint-check :; npm run lint-check
