# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: 50-space.t 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/50-space.t $
#
use strict;
use warnings;
use Test::More tests => 2;
use Text::Sass;

{
  my $sass = <<EOT;
#header
  background: #FFFFFF
  .error
    color: #FF0000
a
  text-decoration: none
  .hot
    color: red
EOT

  my $css = <<EOT;
#header {
  background: #FFFFFF;
}

#header .error {
  color: #FF0000;
}

a {
  text-decoration: none;
}

a .hot {
  color: red;
}
EOT

  my $ts = Text::Sass->new;
  is($ts->sass2css($sass), $css, 'without extra whitespace');
}

{
  my $sass = <<EOT;
#header
  background: #FFFFFF

  .error
    color: #FF0000

a
  text-decoration: none

  .hot
    color: red
EOT

  my $css = <<EOT;
#header {
  background: #FFFFFF;
}

#header .error {
  color: #FF0000;
}

a {
  text-decoration: none;
}

a .hot {
  color: red;
}
EOT

  my $ts = Text::Sass->new;
  is($ts->sass2css($sass), $css, 'with extra whitespace');
}
