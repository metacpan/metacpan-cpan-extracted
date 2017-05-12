# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: 93-parentref-comma.t 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/93-parentref-comma.t $
#
use strict;
use warnings;
use Text::Sass;
use Test::More tests => 1;

{
  our $TODO = "Parent ref with commas not working";
  my $css  = <<EOT;
header {
  background: #FFFFFF;
}

#header .error {
  color: #FF0000;
}

#header a, p {
  text-decoration: none;
}

#header a:hover, #header p:hover {
  text-decoration: underline;
}
EOT

  my $sass = <<EOT;
#header
  background: #FFFFFF
  /* -or-  :background #FFFFFF

  .error
    color: #FF0000

  a, p
    text-decoration: none
    &:hover
      text-decoration: underline
EOT

  SKIP: {
      skip $TODO, 1;

      my $ts = Text::Sass->new();
      is($ts->sass2css($sass), $css, "sass to css conversion ok");
    }
}
