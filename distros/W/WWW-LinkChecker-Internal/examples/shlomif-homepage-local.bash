#!/bin/bash
perl -Mblib scripts/link-checker \
    --state-filename=foo \
    --base='http://localhost/shlomif/homepage-local/' \
    --pre-skip '\.(?:epub|js|rtf|txt)\z' \
    --before-insert-skip '/show\.cgi' \
    --before-insert-skip '/humour/fortunes/[^\.]+\z' \
    --before-insert-skip '/lecture/.*?\.tar\.gz+\z' \
    --before-insert-skip '/lm-solve/' \
    --before-insert-skip 'gringotts-shlomif.*?\.diff\z' \
    --before-insert-skip '/me/blogs/agg/' \
    --before-insert-skip '/art/by-others/(BertycoX|Yachar)/\1(?:\.zip|-dirs/)' \
    --before-insert-skip '/lecture/WebMetaLecture/slides/examples/' \
    --before-insert-skip '/\.htaccess\z' \
    --before-insert-skip '/js/MathJax/' \
    --before-insert-skip '/art/photography/2005-11-27-cats/gen-html\.pl' \


