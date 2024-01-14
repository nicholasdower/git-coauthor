.install: Gemfile Gemfile.lock git-coauthor.gemspec
	@make install
	@touch .install

.PHONY: install
install:
	@bundle install

.PHONY: rspec
rspec: .install
	@rspec

.PHONY: coverage
coverage: .install
	@COVERAGE=1 rspec

.PHONY: clean
clean:
	rm -rf *.gem
	rm -rf .yardoc/
	rm -rf doc/
	rm -rf logs/

.PHONY: gem
gem: .install
	rm -rf *.gem
	gem build

.PHONY: docs
docs:
	@echo '# git-coauthor' >  README.md
	@echo                  >> README.md
	@echo '```'            >> README.md
	@./bin/git-coauthor -h >> README.md
	@echo '```'            >> README.md

.PHONY: rubocop
rubocop: .install
	@bundle exec rubocop

.PHONY: rubocop-fix
rubocop-fix: .install
	@bundle exec rubocop -A

.PHONY: precommit
precommit: .install
	@echo RSpec
	@rspec --format progress
	@echo Rubocop
	@make rubocop
	@echo Docs
	@make docs
