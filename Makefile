PROG ?= splitexec
MAN ?= splitexec.1
MANDOCBIN ?= mandoc
INSTALL ?= install
PREFIX ?= /usr/local

all: release

manhtml: ${MAN}
	for m in $?; do \
		${MANDOCBIN} -T html \
		    -O style=http://man.openbsd.org/mandoc.css,man=http://man.openbsd.org/%N.%S \
		    $$m > $$m.html; \
	done

manmarkdown: ${MAN}
	for m in $?; do \
		${MANDOCBIN} -T markdown $$m > $$m.md; \
	done

README.md: ${MAN}.md
	cp $? ${?:H}/$@

release: manhtml manmarkdown README.md

install:
	${INSTALL} -o root -m 755 ${PROG} ${PREFIX}/bin/
	${INSTALL} -o root -m 644 ${MAN} ${PREFIX}/man/man1/
