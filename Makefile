EMACS=/Applications/Emacs.app/Contents/MacOS/Emacs

nas-site:
	rm -rf nas-public
	npm run-script build && hugo -b http://192.168.1.231/\~showgood/ -d nas-public

site:
	npm run-script build

setup:
	npm install lunr

export:
	@$(EMACS) -Q --batch -l setup.el --eval '(me/export-hugo-from-dir (car (last command-line-args)))' ~/org/roam/org

debug:
	find content -iname "*.*" | xargs -I % echo "processing " %; node lib/hli.js -i % -o debug.json

test-backlink:
	@$(EMACS) -Q --batch -l setup.el --eval '(me/hugo-export (car (last command-line-args)))' ~/org/roam/org/python.org
