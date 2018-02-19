#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use WWW::SmartSheet;
use IO::Prompt qw(prompt);

use Data::Dumper;

my $token   = prompt "Enter Smartsheet API access token: ";
my $w = WWW::SmartSheet->new(token => $token);

my $pagesize = prompt "Sheets per page: ";

display_sheets($pagesize);

sub display_sheets {

  my ($pagesize, $current_page) = @_;

  if (!$current_page) {$current_page = 1;}

  my %all_sheets = %{$w->get_sheets($pagesize, $current_page)};
  if (not %all_sheets) {
    say "You don't have any sheets. Goodbye!";
    exit;
  }

  print "Viewing page $current_page of " . $all_sheets{"totalPages"} . " ($pagesize items per page)\n\n";

  # handling other errors is left as an exercise for the reader

  #  print Dumper \%all_sheets;

  my $i = $pagesize * $current_page - $pagesize;

  foreach my $sheet (@{$all_sheets{"data"}}) {

    $i++;
    # print Dumper \$sheet;
    print "\t" . $i . " " . $sheet->{"name"} . " (" . $sheet->{"id"} . ") " . $sheet->{"permalink"} . "\n";

  }

  if ($all_sheets{"totalPages"} != 1) {

    # probably should adjust the prompt if there's no next or previous but this is just an example script
    my $npq = prompt "Next, Previous, Quit (N,P,Q)? ";

    if ($npq =~ m/^[N]/i) {
      display_sheets($pagesize, ++$current_page);
    } elsif ($npq =~ m/^[P]/i) {
      display_sheets($pagesize, --$current_page);
    } else {
      exit;
    }

  }

}

