# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: 21-nesting.t 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/21-nesting.t $
#
use strict;
use Test::More tests => 2;
use Text::Sass;

{
  my $sass_str = <<EOT;
form
  p label
    display: block
    font-weight: bold
  input.textbox
    background: white
    color: #666
  button
    color: white
    background: red
    padding: 10px 20px
EOT

  #########
  # TODO: the order of these groups is reversed for some reason.
  # form p label | form input.textbox | form button
  #
  my $css_str = <<EOT;
form p label {
  display: block;
  font-weight: bold;
}

form input.textbox {
  background: white;
  color: #666;
}

form button {
  color: white;
  background: red;
  padding: 10px 20px;
}
EOT
  my $sass = Text::Sass->new();
  is($sass->sass2css($sass_str), $css_str, 'sass2css multilevel nesting');
}

{
  my $sass_str = <<EOT;
#content, #sidebar
  p
    margin: 1em 0
EOT

  my $css_str = <<EOT;
#content p, #sidebar p {
  margin: 1em 0;
}
EOT
  my $sass = Text::Sass->new();
  is($sass->sass2css($sass_str), $css_str, 'sass2css multilevel nesting');
}
