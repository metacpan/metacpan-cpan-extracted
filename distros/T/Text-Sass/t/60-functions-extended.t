# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: 60-functions.t 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/60-functions.t $
#
use strict;
use warnings;
use Test::More tests => 1;
use lib qw(t/lib);
use Text::Sass Functions => [qw(special)];

my $scss = <<'EOT';
$string: bla
$color: #ffffff

li
  background: darken($color, 10%)
  content: funky($string)
EOT

my $css = <<'EOT';
li {
  background: #e5e5e5;
  content: funky bla;
}
EOT

{
  my $ts = Text::Sass->new();
  is($ts->sass2css($scss), $css, "custom function");
}

