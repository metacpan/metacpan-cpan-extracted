# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-11-10 16:33:37 +0000 (Sat, 10 Nov 2012) $
# Id:            $Id: RT-80927-nested-includes.t 75 2012-11-10 16:33:37Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/RT-80927-nested-includes.t $
#
use strict;
use warnings;
use Text::Sass;
use Test::More tests => 1;

{
  my $sass  = <<'EOT';
@mixin test { color: #fff; } 
p { 
   .a { 
     .b { 
        @include test;
     }
   }
   .c { @include test; }
}
EOT

  my $css = <<EOT;
p .a .b {
  color: #fff;
}

p .c {
  color: #fff;
}
EOT

  my $ts = Text::Sass->new();

  is($ts->scss2css($sass), $css, "RT#80927 scss to css for nested includes");
}
