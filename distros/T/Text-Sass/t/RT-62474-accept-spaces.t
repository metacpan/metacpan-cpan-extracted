# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: RT-62474-accept-spaces.t 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/RT-62474-accept-spaces.t $
#
use strict;
use warnings;
use Text::Sass;
use Test::More tests => 3;
use Try::Tiny;

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

  is($ts->sass2css($sass), $css, "sass to css conversion ok");
}

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

  is($ts->sass2css($sass), $css, "sass to css conversion ok");
}

{
  my $sass = <<EOT;
h1
  color: #333
   display: inline
EOT

  my $ts = Text::Sass->new();
  
  try {
    diag $ts->sass2css($sass);
  }
  catch {
    ok(1, "dieing from illegal indent $_");
  }
  
}