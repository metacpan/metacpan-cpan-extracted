#!/bin/bash

perl -pe '/^=head1 DESCRIPTION/ and print <STDIN>' lib/Text/Template/Library.pm >README.pod <<EOF
=head1 INSTALLATION

Before you install this module apply the necessary patches to the
L<Text::Template> distribution, see L<C<Text::Template> patches> below.

 perl Makefile.PL
 make
 make test
 make install

EOF

perldoc -tU README.pod >README
rm README.pod