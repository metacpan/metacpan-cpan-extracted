# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: 10-beauty.t 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/10-beauty.t $
#
use strict;
use warnings;
use Text::Sass;
use Test::More tests => 2;

my $sass_str = <<"EOT";
h1
  height: 118px
  margin-top: 1em

.tagline
  font-size: 26px
  text-align: right
EOT

my $css_str = <<"EOT";
h1 {
  height: 118px;
  margin-top: 1em;
}

.tagline {
  font-size: 26px;
  text-align: right;
}
EOT

{
  my $sass = Text::Sass->new();
  is($sass->css2sass($css_str), $sass_str, 'css2sass');
}

{
  my $sass = Text::Sass->new();
  is($sass->sass2css($sass_str), $css_str, 'sass2css');
}

