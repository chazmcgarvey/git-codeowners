
# This is not a Perl distribution, but it can build one using Dist::Zilla.

COVER       = cover
CPANM       = cpanm
DZIL        = dzil
PERL        = perl
PERLCRITIC  = perlcritic
PROVE       = prove

all: dist

bootstrap:
	$(CPANM) $(CPANM_FLAGS) -n Dist::Zilla
	$(DZIL) authordeps --missing |$(CPANM) $(CPANM_FLAGS) -n
	$(DZIL) listdeps --develop --missing |$(CPANM) $(CPANM_FLAGS) -n

check:
	$(PERLCRITIC) bin lib t

clean:
	$(DZIL) $@

cover:
	$(COVER) -test

debug:
	$(PERL) -Ilib -d bin/git-codeowners $(GIT_CODEOWNERS_FLAGS)

dist:
	$(DZIL) build

distclean: clean
	rm -rf .build cover_db fatlib git-codeowners

run:
	$(PERL) -Ilib bin/git-codeowners $(GIT_CODEOWNERS_FLAGS)

test:
	$(PROVE) -l$(if $(findstring 1,$(V)),v) t

.PHONY: all bootstrap check clean cover debug dist distclean run test

