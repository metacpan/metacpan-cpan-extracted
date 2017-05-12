# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-11-10 16:33:37 +0000 (Sat, 10 Nov 2012) $
# Id:            $Id: 90-regression-aa-74181.t 75 2012-11-10 16:33:37Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/90-regression-aa-74181.t $
#
use strict;
use warnings;
use Text::Sass '0.97';
use Test::More tests => 2;

{
  my $css  = <<EOT;
a {
  font-weight: bold;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}
EOT

  my $scss = <<EOT;
a {
  font-weight: bold;
  text-decoration: none;
  &:hover { text-decoration: underline; }
}
EOT

  my $ts = Text::Sass->new();
  
  is($ts->scss2css($scss), $css, "simple parent reference");
}

{
  my $css  = <<EOT;
a {
  font-weight: bold;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}

body.firefox a {
  font-weight: normal;
}
EOT

  my $scss = <<EOT;
a {
  font-weight: bold;
  text-decoration: none;
  &:hover { text-decoration: underline; }
  body.firefox & { font-weight: normal; }
}
EOT

  my $ts = Text::Sass->new();
  
  is($ts->scss2css($scss), $css, "complex parent reference");
}
