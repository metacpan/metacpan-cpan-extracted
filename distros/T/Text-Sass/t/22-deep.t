# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: 22-deep.t 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/22-deep.t $
#
use strict;
use warnings;
use Text::Sass;
use Test::More tests => 1;

{
  my $sass_str = <<EOT;
table
  display: none
  
  .hl
    display: block
    
    td
      color: #333
      
    #id
      margin: 2em 0
      
  #header
    position: absolute
EOT

  my $css_str = <<EOT;
table {
  display: none;
}

table .hl {
  display: block;
}

table .hl td {
  color: #333;
}

table .hl #id {
  margin: 2em 0;
}

table #header {
  position: absolute;
}
EOT

  my $sass = Text::Sass->new();
  is($sass->sass2css($sass_str), $css_str, 'sass2css');
}
