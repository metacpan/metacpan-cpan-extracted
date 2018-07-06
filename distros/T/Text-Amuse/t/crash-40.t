#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 4;
use Text::Amuse;
use Text::Amuse::Functions qw/muse_to_object/;
use Data::Dumper;

my $body = <<EOF;
#title Bug

* Bug title

This text is not displayed

* <verbatim></verbatim>

EOF

my $muse = muse_to_object($body);

ok $muse->as_html
  and diag $muse->as_html;
ok $muse->as_latex
  and diag $muse->as_latex;
ok $muse->toc_as_html
  and diag $muse->toc_as_html;
ok $muse->raw_html_toc
  and diag Dumper($muse->raw_html_toc);

