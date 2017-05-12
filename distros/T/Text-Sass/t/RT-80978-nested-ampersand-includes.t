# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-11-10 16:33:37 +0000 (Sat, 10 Nov 2012) $
# Id:            $Id: RT-80978-nested-ampersand-includes.t 75 2012-11-10 16:33:37Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/RT-80978-nested-ampersand-includes.t $
#
use strict;
use warnings;
use Text::Sass;
use Test::More tests => 1;

{
  my $sass  = <<'EOT';
a {
 b {
   &.this { color: #fff; }
 }
}
EOT

  my $css = <<EOT;
a b.this {
  color: #fff;
}
EOT

 SKIP: {
    skip q[SCSS nested ampersand includes not working], 1;
    my $ts = Text::Sass->new();

    is($ts->scss2css($sass), $css, "RT#80978 scss to css for nested ampersand includes");
  }
}

