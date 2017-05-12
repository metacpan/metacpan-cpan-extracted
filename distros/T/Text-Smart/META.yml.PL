# Copyright (C) 2008 Daniel Berrange <dan@berrange.com>

use strict;
use warnings;

die unless (scalar @ARGV == 1);

open SRC, "lib/Text/Smart.pm"
    or die "lib/Text/Smart.pm: $!";

our $VERSION;
while (<SRC>) {
    if (/\$VERSION\s*=\s*'(.*)'/) {
	$VERSION=$1;
    }
}
close SRC;

local $/ = undef;
$_ = <DATA>;
s/\@VERSION\@/$VERSION/g;

open SPEC, ">$ARGV[0]" or die "$!";
print SPEC $_;
close SPEC;
__DATA__
--- #YAML:1.0
name:         Text-Smart
abstract:     Processor for 'smart text' markup
version:      @VERSION@
author:
  - Daniel P. Berrange <dan@berrange.com>
license: gpl
generated_by: ExtUtils::MakeMaker version 6.30
requires:
    Carp:                          0
build_requires:
    Test::More:                    0
    Test::Pod:                     0
    Test::Pod::Coverage:           0

resources:
  license: http://www.gnu.org/licenses/gpl.html
  homepage: http://berrange.com
  repository: http://hg.berrange.com/libraries/text-smart-devel

distribution_type: module

meta-spec:
   version: 1.3
   url: http://module-build.sourceforge.net/META-spec-v1.3.html
