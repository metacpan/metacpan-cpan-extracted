.PHONY: cover cover-serve test

test:
	prove -lr

cover:
	cover -delete
	DEVEL_COVER_OPTIONS='-ignore,\bt/,+ignore,/usr' PERL5OPT='-MDevel::Cover' prove -lr
	cover

cover-serve:
	pkill -f [S]impleHTTPServer || true
	cd cover_db && python -m SimpleHTTPServer 2>&1 >/dev/null
