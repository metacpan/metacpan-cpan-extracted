#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  t/01-basic.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/Text-OutdentEdge/t/01-basic.t 251 2006-11-25T09:34:10.153482Z hio  $
# -----------------------------------------------------------------------------
use strict;
use warnings;
use Test::More tests => 15;
use Text::OutdentEdge qw(xoutdent outdent);

&test01_xoutdent;   #2.
&test02_xoutdent2;  #2.
&test03_utils;      #6.
&test04_outdent;    #4.
&test05_outdent2;   #1.

# -----------------------------------------------------------------------------
# xoutdent.
#
sub test01_xoutdent
{
  my $in = <<EOT;
    X sample
    X text.
EOT
  is($in, "    X sample\n    X text.\n", "[xoutdent] input is indented with edge");
  is(xoutdent($in), "sample\ntext.\n", "[xoutdent] xoutdent removes both indent and edge");
}

# -----------------------------------------------------------------------------
# xoutdent (2).
#
sub test02_xoutdent2
{
  my $in = <<EOT;
    X sample
    X text,
    X 
    X   and
    X   more indented.
EOT
  is($in, "    X sample\n    X text,\n    X \n    X   and\n    X   more indented.\n", "[xoutdent2] input is indented with edge");
  is(xoutdent($in), "sample\ntext,\n\n  and\n  more indented.\n", "[xoutdent2] xoutdent keeps more deep indent");
}

# -----------------------------------------------------------------------------
# utils.
#
sub test03_utils
{
  my $in = q{
    1
    2
  };
  is($in, "\n    1\n    2\n  ", "[utils] initial");
  is(outdent($in),            "1\n2\n",   "[utils] trimming is default");
  is(outdent($in,{trim=>1}),  "1\n2\n",   "[utils] trimming explicit");
  is(outdent($in,{trim=>0}),  "\n1\n2\n", "[utils] no trimming");
  is(outdent($in,{chomp=>1}), "1\n2",     "[utils] chomp");
  
  is(outdent("    \n"), "    \n", "[utils] spaces only line is skipped");
}

# -----------------------------------------------------------------------------
# outdent.
#
sub test04_outdent
{
  my $in = <<EOT;
    test.
EOT
  is($in, "    test.\n", "[outdent] input is indented");
  is(outdent($in), "test.\n", "[outdent] outdent it");
  is(outdent($in, qr/  /), "  test.\n", "[outdent] outdent just two spaces");
  is(outdent($in, {indent=>qr/  /}), "  test.\n", "[outdent] specify indent by opts");
}

# -----------------------------------------------------------------------------
# multi indents.
#
sub test05_outdent2
{
  my $in = <<EOT;
    text

      with
  multiple
    indents.
EOT
  is(outdent($in), "  text\n\n    with\nmultiple\n  indents.\n", "[outdent2] remove minimum indent");
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
