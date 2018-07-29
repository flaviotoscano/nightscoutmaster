
# Nightscout tests/builds/analysis
TESTS=tests/*.js
MONGO_CONNECTION?=mongodb://localhost:27017/test_db
CUSTOMCONNSTR_mongo_settings_collection?=test_settings
CUSTOMCONNSTR_mongo_collection?=test_sgvs
MONGO_SETTINGS=MONGO_CONNECTION=${MONGO_CONNECTION} \
	CUSTOMCONNSTR_mongo_collection=${CUSTOMCONNSTR_mongo_collection}

# XXX.bewest: Mocha is an odd process, and since things are being
# wrapped and transformed, this odd path needs to be used, not the
# normal wrapper.  When ./node_modules/.bin/mocha is used, no coverage
# information is generated.  This happens because typical shell
# wrapper performs process management that mucks with the test
# coverage reporter's ability to instrument the tests correctly.
# Hard coding it to the local with our pinned version is bigger for
# initial installs, but ensures a consistent environment everywhere.
# On Travis, ./node_modules/.bin and other `nvm` and `npm` bundles are
# inserted into the default `$PATH` enviroinment, making pointing to
# the unwrapped mocha executable necessary.
MOCHA=./node_modules/mocha/bin/_mocha
# Pinned from dependency list.
ISTANBUL=./node_modules/.bin/istanbul
ANALYZED=./coverage/lcov.info
export CODACY_REPO_TOKEN=e29ae5cf671f4f918912d9864316207c

all: test

coverage:
	NODE_ENV=test ${MONGO_SETTINGS} \
	${ISTANBUL} cover ${MOCHA} -- --timeout 15000 -R tap ${TESTS}

report:
	test -f ${ANALYZED} && \
	(npm install coveralls && cat ${ANALYZED} | \
	./node_modules/.bin/coveralls) || echo "NO COVERAGE"
	test -f ${ANALYZED} && \
	(npm install codacy-coverage && cat ${ANALYZED} | \
	YOURPACKAGE_COVERAGE=1 ./node_modules/codacy-coverage/bin/codacy-coverage.js) || echo "NO COVERAGE"

test_onebyone:
	python -c 'import os,sys,fcntl; flags = fcntl.fcntl(sys.stdout, fcntl.F_GETFL); fcntl.fcntl(sys.stdout, fcntl.F_SETFL, flags&~os.O_NONBLOCK);'
	$(foreach var,$(wildcard tests/*.js),${MONGO_SETTINGS} ${MOCHA} --timeout 30000 --exit --bail -R tap $(var);)

test:
	${MONGO_SETTINGS} ${MOCHA} --timeout 30000 --exit --bail -R tap ${TESTS}

travis:
	python -c 'import os,sys,fcntl; flags = fcntl.fcntl(sys.stdout, fcntl.F_GETFL); fcntl.fcntl(sys.stdout, fcntl.F_SETFL, flags&~os.O_NONBLOCK);'
	NODE_ENV=test ${MONGO_SETTINGS} \
	${ISTANBUL} cover ${MOCHA} --report lcovonly -- --timeout 5000 -R tap ${TESTS}	
#	$(foreach var,$(wildcard tests/*.js),${MONGO_SETTINGS} ${MOCHA} --timeout 30000 --exit --bail -R tap $(var);)

.PHONY: all coverage report test travis
