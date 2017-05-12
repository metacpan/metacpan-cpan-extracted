# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: 30-variables.t 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/30-variables.t $
#
use strict;
use warnings;
use Text::Sass;
use Test::More tests => 2;

{
  my $sass_str = <<"EOT";
!blue = #3bbfce
!margin = 16px

.content_navigation
  border-color = !blue
  color = !blue - #111

.border
  padding = !margin / 2
  margin = !margin / 2
  border-color = !blue
EOT

  my $css_str = <<"EOT";
.content_navigation {
  border-color: #3bbfce;
  color: #2aaebd;
}

.border {
  padding: 8px;
  margin: 8px;
  border-color: #3bbfce;
}
EOT

  my $sass = Text::Sass->new();
  is($sass->sass2css($sass_str), $css_str, 'sass variables');
}

{
  my $sass_str = <<'EOT';
!blue\: = #3bbfce

.content_navigation
  border-color = !blue\:
EOT

  my $css_str = <<"EOT";
.content_navigation {
  border-color: #3bbfce;
}
EOT

  my $sass = Text::Sass->new();
  is($sass->sass2css($sass_str), $css_str, 'sass variable with escaped colon in name');
}

