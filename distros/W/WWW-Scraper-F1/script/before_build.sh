#!/usr/bin/env sh

echo "****** Begin before_build script. *******"
cpanm --reinstall --notest --quiet t/assets/Dist-Zilla-Plugin-ReadmeAnyFromPod-0.2.tar.gz
cpanm Dist::Zilla
dzil authordeps | cpanm --notest --quiet --mirror http://cpan.mirrors.travis-ci.org
dzil build
cd WWW-Scraper-F1*
cpanm --quiet --installdeps --notest --mirror http://cpan.mirrors.travis-ci.org .
