# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: 90-regression-wikipedia-parentref.t 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/90-regression-wikipedia-parentref.t $
#
use strict;
use warnings;
use Test::More tests => 1;
use Text::Sass;

my $sass = <<EOT;
a
  text-decoration: none
  &:hover
    text-decoration: underline
EOT

my $css = <<EOT;
a {
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}
EOT

my $ts = Text::Sass->new;
is($ts->sass2css($sass), $css, 'wikipedia example parent "&" reference');
