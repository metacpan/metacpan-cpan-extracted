#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde
#
# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# RSS2Leafnode is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use HTML::FormatText::WithLinks;

# {
#   package MyLinks;
#   use base 'HTML::FormatText::WithLinks';
# 
#   sub head_start {
#     my ($self) = @_;
#     $self->SUPER::head_start();
#     # descend into <head> even if superclass not itself interested
#     return 1;
#   }
#   sub base_start {
#     my ($self, $node) = @_;
#     if (my $href = $node->attr('href')) {
#       $self->{base} = $href;
#     }
#     # if SUPER::base_start exists (doesn't as of HTML::FormatText 2.04)
#     if (HTML::FormatText->can('base_start')) {
#       return $self->SUPER::base_start();
#     } else {
#       return 0;
#     }
#   }
# }

my $html = <<'HERE';
<base href="http://foo.com/">
<html>
<head>
</head>
<body>
<p> Text <a href="one.html">and a link</a>
</body>
</html>
HERE
my $html_without = <<'HERE';
<html>
<body>
<p> <a href="two.html">another link</a>
</body>
</html>
HERE

{
    my $class = 'HTML::FormatText::WithLinks';
    my $f = $class->new ($html);
    print $f->format_string ($html);
    print $f->format_string ($html_without);
  # print MyLinks->format_string ($html);
  exit 0;
}
