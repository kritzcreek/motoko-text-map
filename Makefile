.PHONY: check docs test

check:
	find src -type f -name '*.mo' -print0 | xargs -0 $(shell vessel bin)/moc $(shell vessel sources) --check

all: check-strict docs test

# temporarily disable -Werror while base is deprecating Word types
check-strict: check
#	find src -type f -name '*.mo' -print0 | xargs -0 $(shell vessel bin)/moc $(shell vessel sources) -Werror --check
docs:
	$(shell vessel bin)/mo-doc
test:
	make -C test
