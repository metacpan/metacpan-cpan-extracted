#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Getopt::Std;
use Term::ANSIColor;

use WWW::LEO;

our ($opt_c, $opt_i, $opt_h, $opt_n);
our $VERSION = '0.1';

getopts 'c:ih:n';

usage() if defined $opt_c and defined $opt_n;
usage() if defined $opt_h;

my $term = "@ARGV" or usage();

my $leo = WWW::LEO->new or die "LEO->new(): $!\n";
$leo->query($term);
show_results($leo);

exit 0 unless $opt_i;

for (;;) {

  my ($term, $answer);

  my $num_results = $leo->num_results;

  if ($num_results) {

    no warnings;
    do {
      printf "Query for %s, (n)ew search or (q)uit? ", $num_results > 1 ? "(1 - $num_results)" : '(1)';
      chomp($answer = <STDIN>);
    } until ($answer =~ /^(n|q)$/ or ($answer >=1 && $answer <= $num_results));
    use warnings;

  } else {

    no warnings;
    do {
      printf "(n)ew search or (q)uit? ";
      chomp($answer = <STDIN>);
    } until ($answer =~ /^(n|q)$/);
    use warnings;

  }

  exit 0 if $answer eq 'q';

  if ($answer eq 'n') {
    use Term::ReadLine;
    my $rl = new Term::ReadLine;
    my $nterm = $rl->readline('Please enter search term: ');
    if (not defined $nterm) {
      print STDERR "Editing aborted, taking previous string %s ...\n", $leo->query;
    } else {
      $term = $nterm;
    }
  } else {

    use Term::ReadKey;
    ReadMode 'cbreak';

    my $language;
    do {
      print "Use (e)nglish or (g)erman search term? ";
      $language = ReadKey(0);
      print "\n";
    } until ($language =~ /^(e|g)$/);

    $term = ($language eq 'e' ? $leo->en->[$answer] : $leo->de->[$answer]);

    my $edit;
    do {
      printf "Edit current search string ('%s') before submitting (y/n)? ", $term;
      $edit = ReadKey(0);
      print "\n";
    } until ($edit =~ /^(y|n)$/);
    ReadMode 'normal';

    if ($edit eq 'y') {

      use Term::ReadLine;
      my $rl = new Term::ReadLine;
      my $nterm = $rl->readline('> ', $term);
      if (not defined $nterm) {
	printf STDERR "Editing aborted, taking previous string %s ...\n", $leo->query;
      } else {
	$term = $nterm;
      }

    }

  }

  $term =~ s/^\s+//;
  $term =~ s/\s+$//;

  $leo->query($term);
  show_results($leo);

}

sub show_results {

  my $leo = shift;

  unless ($leo->num_results) {
    printf "Sorry, there were no results for '%s'.\n", $leo->query;
    return;
  }

  my $num_digits = int(log($leo->num_results) / log(10)) + 1;

  printf "Your search term '%s' produced %d result%s:\n", $leo->query, $leo->num_results, $leo->num_results > 1 ? 's' : '';
  print ' ' x ($num_digits + 1), 'ENGLISH', ' ' x ($leo->maxlen_en - length('ENGLISH') + length('<=> ') + 1), ' ' x ($num_digits + 1), 'GERMAN', "\n";
  print '=' x ($num_digits * 2 + $leo->maxlen_en + $leo->maxlen_de + 7), "\n";

  my $i;
  foreach my $resultpair (@{$leo->en_de}) {

    my ($en, $de) = @$resultpair;

    my $hilight = color defined $opt_c ? $opt_c : 'green';
    my $reset = color 'reset';
    my $query = $leo->query;
    my $num_subst = defined $opt_n ? 0 : $en =~ s/(\Q$query\E)/$hilight$1$reset/gi;
    my $format = sprintf "%%%dd %%-%ds <=> %%%dd %%-%ds\n", $num_digits, ($leo->maxlen_en+$num_subst * length($hilight.$reset)), $num_digits, $leo->maxlen_de;

    $de =~ s/(\Q$query\E)/$hilight$1$reset/gi unless defined $opt_n;
    printf $format, ++$i, $en, $i, $de;

  }
  print '=' x ($num_digits * 2 + $leo->maxlen_en + $leo->maxlen_de + 7), "\n" if $opt_i;

}

sub usage {

  (local $0 = $0) =~ s,^.*\/,,;
  print <<"EOT";
Usage: $0 [-c <color> | -n] [-i] [-h[h]] <search term>
Options:
  -c:  specify ANSI color for hilighting (see the Term::ANSIColor man page for valid colors)
  -n:  don't color output
  -i:  run interactively
  -h:  show this help message
  -hh: show more help text
EOT

print <<'EOT' if defined $opt_h and $opt_h eq 'h';

Version: $Id$
Description: This program queries the http://dict.leo.org online dictionary for search terms specified by the user.  In interactive mode, the user may query from terms of the previous search results.
Author: Joerg Ziefle <ziefle@cpan.org>
Copyright: 2002 by Joerg Ziefle.  All rights reserved.
License: This program is free software.  You may use and modify it under the same terms as Perl itself.
EOT

  exit 0;

}
