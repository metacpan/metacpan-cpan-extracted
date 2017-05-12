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

use strict;
use warnings;
use XML::LibXML;
use File::Slurp;

use FindBin;
my $progname = $FindBin::Script;


{
  package XML::Liberal::Remedy::LowAsciiChars;
  use strict;
  use base qw( XML::Liberal::Remedy );

  # optimized to fix all errors in one apply() call
  sub apply {
    my $self = shift;
    my($xml_ref) = @_;
    my $match = $$xml_ref =~ s{&#(?:(\d+)|x([0-9A-Fa-f]{1,4}));}{
      ($1 && is_low_ascii($1)) || ($2 && is_low_ascii(hex($2)))
        ? '' : $&;
    }eg;
    return 1 if $match;

    Carp::carp("Can't find low ascii bytes $self->{error}");
    return;
  }

  my %is_low_ascii = map { $_ => 1 } (0..8, 11..12, 14..31, 127);

  sub is_low_ascii {
    my $num = shift;
    $is_low_ascii{$num};
  }
}

{
  # require XML::Liberal::Remedy::LowAsciiChars;
  my $self = bless { error => 'my-error' },
    'XML::Liberal::Remedy::LowAsciiChars';
  #my $str = "\x08";
  my $str = "<foo>&#x8;</foo>";
  print $self->apply(\$str);
#   if ($str =~ m{&#(?:(\d+)|x([0-9A-Fa-f]{1,4}));}) {
#     print "yes\n";
#   } else {
#     print "no\n";
#   }
  exit 0;
}

{
  require XML::Liberal;

  # my $filename = $FindBin::Dir . '../samp/closing_commentary--2.rss';
  # print "$filename\n";
  # my $xml = read_file($filename);

  # <?xml version="1.0" encoding="ISO-8859-1" ?>
  # <rss version="2.0">
  #  <channel>
  #   <item>
  #    <title>SP 500</title>
  #   </item>
  #  </channel>
  # </rss>

  my $xml = <<'HERE';
<foo>ab &#x8; cd</foo>
HERE


  #my $parser = XML::LibXML->new;
  my $parser = XML::Liberal->new('LibXML');
  my $doc = eval { $parser->parse_string($xml) };
  print $doc,"\n";
  # if ($doc) {
  #   print $doc->toString;
  #
  #   $xml = $doc->toString;
  #   $parser = XML::LibXML->new;
  #   $doc = eval { $parser->parse_string($xml) };
  #   print $doc,"\n";
  # }
  exit 0;
}
