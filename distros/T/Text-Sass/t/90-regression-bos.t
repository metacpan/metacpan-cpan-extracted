# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: 90-regression-bos.t 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/90-regression-bos.t $
#
use strict;
use warnings;
use Text::Sass '0.5';
use Test::More tests => 4;

{
  my $css  = <<EOT;
h1 {
  color: #333;
}
EOT

  my $sass = <<EOT;
h1
  color: #333
EOT

  my $ts = Text::Sass->new();

  is($ts->css2sass($css), $sass, "css to sass conversion ok");
  is($ts->sass2css($sass), $css, "sass to css conversion ok");
}

{
  my $css  = <<EOT;
h1, h2 {
  color: #333;
}
EOT

  my $sass = <<EOT;
h1, h2
  color: #333
EOT

  my $ts = Text::Sass->new();

#  $Text::Sass::DEBUG = 1;

  is($ts->css2sass($css), $sass, "css to sass conversion ok");
  is($ts->sass2css($sass), $css, "sass to css conversion ok");
}
