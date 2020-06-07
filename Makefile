EMACS=/Applications/Emacs.app/Contents/MacOS/Emacs

nas-site:
	rm -rf nas-public
	npm run-script build && hugo -b http://192.168.1.231/\~showgood/ -d nas-public

site:
	npm run-script build

setup:
	npm install lunr

export:
	# @$(EMACS) -Q --batch -l setup.el --eval '(me/export-hugo-from-dir (car (last command-line-args)))' ~/org/roam/org

	# if org file has this at file level:
	# #+DATE: 2020-05-19
	# after ox-hugo, md file will have this:
	# date = 2020-05-25
	# this will make command ~node lib/hli.js~ not happy
	find content -iname "*.md" | xargs sed -i -r -E "s/^date = (.*)/date = \"\1\"/"

debug:
	find content -iname "*.md" | xargs -I % sh -c 'echo % ;node lib/hli.js -i %'

test-backlink:
	@$(EMACS) -Q --batch -l setup.el --eval '(me/hugo-export (car (last command-line-args)))' ~/org/roam/org/python.org
