TESTS_DIR=tests/plenary
TESTS_INIT=tests/init.lua
PLENARY_INIT=tests/plenary_init.lua

test:
	nvim --headless --noplugin -u ${PLENARY_INIT} -c "PlenaryBustedDirectory ${TESTS_DIR} {minimal_init = '${TESTS_INIT}'}"
