# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: 81-sass-ex.t 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/81-sass-ex.t $
#
use strict;
use warnings;
use Text::Sass;
use Test::More tests => 4;

# $Text::Sass::DEBUG = 1;

{
  my $css  = <<EOT;
.content-navigation {
  border-color: #3bbfce;
  color: #2ba1af;
}

.border {
  padding: 8px;
  margin: 8px;
  border-color: #3bbfce;
}
EOT

  my $sass = <<EOT;
/* SASS
\$blue: #3bbfce
\$margin: 16px

.content-navigation
  border-color: \$blue
  color: darken(\$blue, 9%)

.border
  padding: \$margin / 2
  margin: \$margin / 2
  border-color: \$blue
EOT
  my $ts = Text::Sass->new();

  is($ts->sass2css($sass), $css, "variables examples");
}

{
  my $sass = <<EOT;
table.hl
  margin: 2em 0
  td.ln
    text-align: right

li
  font:
    family: serif
    weight: bold
    size: 1.2em
EOT
  my $css = <<EOT;
table.hl {
  margin: 2em 0;
}

table.hl td.ln {
  text-align: right;
}

li {
  font-family: serif;
  font-weight: bold;
  font-size: 1.2em;
}
EOT
  my $ts = Text::Sass->new();

  is($ts->sass2css($sass), $css, "nesting example");
}

{
  my $sass = <<EOT;
.error
  border: 1px #f00
  background: #fdd

.error.intrusion
  font-size: 1.3em
  font-weight: bold

.badError
  \@extend .error
  border-width: 3px
EOT
  my $css = <<EOT;
.error, .badError {
  border: 1px #f00;
  background: #fdd;
}

.error.intrusion, .badError.intrusion {
  font-size: 1.3em;
  font-weight: bold;
}

.badError {
  border-width: 3px;
}
EOT
  my $ts = Text::Sass->new();
  # BOS: This looks like is wrongly implemented in sass-lang.com/try.html as well.
  local $TODO = "no support for extend yet";

  is($ts->sass2css($sass), $css, "inherintance example");
  
}

{
  my $sass = <<EOT;
\@mixin table-base
  th
    text-align: center
    font-weight: bold
  td, th
    padding: 2px

\@mixin left(\$dist)
  float: left
  margin-left: \$dist

#data
  \@include left(10px)
  \@include table-base
EOT
  my $css = <<EOT;
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
  # $Text::Sass::DEBUG = 1;
  my $ts = Text::Sass->new();
  #local $TODO = "no support for extend yet";

  is($ts->sass2css($sass), $css, "mixin example");
  
}

