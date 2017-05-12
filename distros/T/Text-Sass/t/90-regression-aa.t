# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: 90-regression-aa.t 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/90-regression-aa.t $
#
use strict;
use warnings;
use Text::Sass '0.94';
use Test::More tests => 1;

{
  my $css  = <<EOT;
div.button {
  background: url(../img/button.gif) left top;
}
EOT

  my $scss = <<EOT;
div.button {
  background: url(../img/button.gif) left top;
}
EOT

  my $ts = Text::Sass->new();

  is($ts->scss2css($scss), $css, "scss to css conversion ok");
}
