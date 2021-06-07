#!/usr/bin/env perl

use 5.024;
use feature qw/signatures postderef/;
no warnings qw/experimental uninitialized/;
use utf8::all;
use Try::Tiny;
use Data::Printer;

=pod

=head1 buildpod.pl

This is a utility script for the Vote::Count Distribution.
Method Documentation is being written conventionally as inline POD,
Documentation files are being written in MarkDown. This utility
will convert markdown files to pod files, and insert pod into modules
that have a markdown file. The insertion will be between lines that
have #buildpod comments.

As an added convenience buildpod will read the version from dist.ini and
replace the version strings in modules.

Someday I may make a Dist::Zilla plugin out of this.

=head1 SYNOPSIS

./buildpod.pl

./buildpod.pl fixfooter

=cut


# use Carp::Always;
use Carp;
use Path::Tiny;
use Markdown::Pod;;
# use Time::Piece;
# use Time::Moment;
# use Search::Tools::UTF8;
# use Unicode::Normalize;
# use List::Util qw(max);
# use Unicode::Collate::Locale;
# use feature 'unicode_strings';
# use Encode qw (from_to decode_utf8 encode_utf8 decode encode);
# use Cpanel::JSON::XS;    # qw( encode_json decode_json );
use Data::Printer;
# use Data::Dumper;
# use charnames ':full';
# use Unicode::UCD 'charinfo';
# use Test::More;
# use Getopt::Long::Descriptive;

our $VERSION='2021.0427';

my $m2p = Markdown::Pod->new;

sub fix_version ( $text, $version ) {
  $text =~ s/our \$VERSION(| )=.*;/our \$VERSION='$version';/g;
  $text =~ s/=head1 VERSION.*\n/=head1 VERSION $version\n/;
  return $text;
}

# sub add_pod ( $text, $markdown ) {
#   my $pod = $m2p->markdown_to_pod(
#     markdown => $markdown,
#   );
#   my $markerstr = '#buildpod';
#   my $num_markers = () = $text =~ /$markerstr/g;
# say "Counted Markers: $num_markers";
#   return $text unless $num_markers;
#   if ( $num_markers >2 ) {
#     die "There are too many $markerstr markers in the current file\\n"
#   }
#   my @beforepod = ();
#   my @afterpod = ();
#   my $aftermarker = 0;
#   for my $l ( split /\n/, $text ) {
#     if ($aftermarker == $num_markers ) { push @afterpod, $l }
#     elsif ($aftermarker == 1 ) {
#       $aftermarker++ if $l =~ /$markerstr/;
#     } else {
#       if ( $l =~ /$markerstr/ ) {
#       $aftermarker++ if $l =~ /$markerstr/;
#       } else {
#         push @beforepod, $l;
#       }
#     }
#   }
#   return join( "\n",
#     ( @beforepod, $markerstr, "\n=pod\n$pod\n=cut\n", $markerstr, @afterpod )
#   )
# }

my $footer = <<'FOOTER';

#FOOTER

=pod

BUG TRACKER

L<https://github.com/brainbuz/Vote-Count/issues>

AUTHOR

John Karr (BRAINBUZ) brainbuz@cpan.org

CONTRIBUTORS

Copyright 2019-2021 by John Karr (BRAINBUZ) brainbuz@cpan.org.

LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit L<http://fsf.org>.

SUPPORT

This software is provided as is, per the terms of the GNU Public License. Professional support and customisation services are available from the author.

=cut

FOOTER

my $fixfooter = 0;
for (@ARGV) {
  $fixfooter = 1 if $_ eq 'fixfooter';
}

my $dist = path( './dist.ini')->slurp;
$dist =~ /version\s? =\s?(\d+\.\d+)/;
my $version = $1;

# my @mdfiles = path(".")->children( qr/md$/ );

my @pmfiles1 = path("./lib/Vote/Count")->children( qr/pm$|pod$/);
my @pmfiles2 = path("./lib/Vote/Count/Method")->children( qr/pm$/);
my @pmfiles3 = path("./lib/Vote/Count/Charge")->children( qr/pm$/);
my @pmfiles4 = path("./lib/Vote/Count/Helper")->children( qr/pm$/);
my $countpm = path( "./lib/Vote/Count.pm");
my @pmfiles = ( @pmfiles1, @pmfiles2, @pmfiles3, @pmfiles4,$countpm);
my %pmkeys = ();
for my $pm (@pmfiles ) {
  next if $pm =~ /TextTableTiny/;
  $pm =~ /(.*)\.(pm$|pod$)/; # extract the part of the string before .pm
  my @bits = split /\//, $1; # split extracted on /, llast bit is basename
  $pmkeys{ $bits[-1] } = $pm ; # put the path object in the hash keyed on the basename.
}
# FORMD:
# for my $md ( @mdfiles ) {
#   my $name = $md->basename;
# say "ORI base name $name";
#   $name =~ s/\.md$//;
#   say "base name $name";
#   if ( $pmkeys{ $name }) {
#     my $pm = delete $pmkeys{ $name }; # remove from keys, so we dont repeat it later.
#     my $mdtext = path($md)->slurp();
#     my $pmtext = path($pm)->slurp();
#     $pmtext = add_pod( $pmtext, $mdtext );
#     $pmtext = fix_version( $pmtext, $version);
#     $pm->spew( $pmtext );
#     say "updated $pm added pod from $md";
#   } else {
#       next FORMD if $md =~ /README/ ;
#       my $mdtext = try { path($md)->slurp(); }
#         catch { warn "failed to slurp $md"};
#       $mdtext =~ s/(\# ABSTRACT.*)\n//;
#       my $abstract = $1;
#       my $pod =  $m2p->markdown_to_pod( markdown => $mdtext );
#       my $versionline = "=head1 VERSION $version";
# warn $versionline;
#       # $pod = "$abstract\n$versionline\n$pod\n$footer";
#       $pod = "$abstract\n\n=pod\n\n$versionline\n$pod\n$footer\n=cut\n";
#       path( "./lib/Vote/$name.pod")->spew($pod);
#   }

sub updateCountIndex {
  my @modules = sort map {
      my $p = $_->canonpath ;
      my $d = path( $p)->slurp();
      $d =~ /head1 NAME\s+(.*)/i;
      my $n = $1;
      unless ( $n ) {
        $n = $_->basename;
      }
      $n;
  } @pmfiles;
  my $countmod = path('lib/Vote/Count.pm')->slurp();
  my $index = join("\n", map {"=item *\n\nL<$_>\n"} @modules);
  # p @modules;
# $countmod =~ /(?s)#BEGININDEX(.*)/;
  my ( $part1, $part2, $part3 ) = split( /#INDEXSECTION|#FOOTER/, $countmod );

  $countmod = qq|$part1\n
#INDEXSECTION\n
=pod\n
=head1 INDEX of Vote::Count Modules and Documentation\n
=over\n
$index\n
=back\n
=cut\n
#FOOTER\n
$part3|;
  $countmod =~ s/\n\n+/\n\n/g;

  path('lib/Vote/Count.pm')->spew($countmod);
}

updateCountIndex();

  for my $pm ( values @pmfiles ) {
# for my $pm ( values %pmkeys ) {
warn "fixing $pm"    ;
    my $pmtext = path($pm)->slurp;
    unless ($pmtext =~ /\#FOOTER/) { $pmtext .= $footer ; }
    elsif ( $fixfooter ) {
      say "updateding footer $pm"      ;
      # $pmtext =~ s/(?s)\#FOOTER.*/$footer/;
      my $splitstr = "#FOOTER\n";
      my ($body, @trim) = split /$splitstr/, $pmtext;
      $pmtext = $body . $footer;
    }
    $pmtext =~ s/\n\n\n+/\n\n/g;
    path($pm)->spew( fix_version( $pmtext, $version) );
    say "updated version in $pm";
  }