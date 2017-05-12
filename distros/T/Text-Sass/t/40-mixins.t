# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: 40-mixins.t 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/40-mixins.t $
#
use strict;
use warnings;
use Text::Sass;
use Test::More tests => 3;

# $Text::Sass::DEBUG = 1;

{
  my $sass_str = <<EOT;
=table-scaffolding
  th
    text-align: center
    font-weight: bold

#data
  +table-scaffolding
EOT

  my $css_str = <<EOT;
#data th {
  text-align: center;
  font-weight: bold;
}
EOT

  my $sass = Text::Sass->new();
  is($sass->sass2css($sass_str), $css_str, 'static mixin');
}

{
  my $sass_str = <<EOT;
=macro(!dist)
  margin-left = !dist
  float: left

#data
  +macro(10px)
EOT

  my $css_str = <<EOT;
#data {
  margin-left: 10px;
  float: left;
}
EOT

  my $sass = Text::Sass->new();
  is($sass->sass2css($sass_str), $css_str, 'dynamic mixin, one variable');
}

{
  my $sass_str = <<EOT;
=table-scaffolding
  th
    text-align: center
    font-weight: bold
  td, th
    padding: 2px

=left(!dist)
  float: left
  margin-left = !dist

#data
  +left(10px)
  +table-scaffolding
EOT

  my $css_str = <<EOT;
#data {
  float: left;
  margin-left: 10px;
}
#data th {
  text-align: center;
  font-weight: bold;
}
#data td, #data th {
  padding: 2px;
}
EOT

 SKIP: {
  skip q[complex mixins don't work yet], 1;
  my $sass = Text::Sass->new();
  is($sass->sass2css($sass_str), $css_str, 'complex mixin, static + dynamic');
 }
}
