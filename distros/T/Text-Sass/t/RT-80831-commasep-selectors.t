# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-11-10 16:33:37 +0000 (Sat, 10 Nov 2012) $
# Id:            $Id: RT-80831-commasep-selectors.t 75 2012-11-10 16:33:37Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/RT-80831-commasep-selectors.t $
#
use strict;
use warnings;
use Text::Sass;
use Test::More tests => 1;

{
  my $sass  = <<EOT;
#id { 
  a .abc, b .def { 
    color: #fff;
  }
}
EOT

  my $css = <<EOT;
#id a .abc, #id b .def {
  color: #fff;
}
EOT

  my $ts = Text::Sass->new();

  is($ts->scss2css($sass), $css, "RT#80831 scss to css for comma-separated selectors");
}
