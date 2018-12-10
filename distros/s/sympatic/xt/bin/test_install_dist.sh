set -e
cpanm --installdeps .
v=$( perl -Ilib -MSympatic -E'say $Sympatic::VERSION' )
perl Makefile.PL
make dist
tar xf *gz
cd Sympatic-$v
cpanm .
RELEASE_TESTING=true prove -r
