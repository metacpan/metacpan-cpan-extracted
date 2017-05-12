## Webalizer::Hist, created by //YorHel

package Webalizer::Hist;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = "0.03";



my @webalizerheader = qw( month year totalhits totalfiles totalsites
    totalkbytes firstday lastday totalpages totalvisits );

sub new {
  my $self = shift;
  my $class = ref($self) || $self;
  my %args; $#_ % 2 ? %args = @_ : warn "Odd argument list at " . __PACKAGE__ . "::new";

  my $my = bless { desc => 1, %args, _curmonth => 0 }, $class;
  return $my->_parse() ? $my : undef;
}

sub month {
  my $self = shift;
  my $month = shift || undef;
  if($month) {
    foreach my $i (0..$#{$self->{_data}}) {
      if($self->{_data}[$i]{month} == $month) {
        $month = $i;
        last;
      }
    }
  } else {
    $month = $self->{_curmonth}++;
  }
  return 0 if $month > $#{$self->{_data}};
  
  my %hash = %{$self->{_data}[$month]};
  my $days = $hash{lastday} - $hash{firstday} + 1;
  return 0 if !$days;
  foreach my $key (keys %hash) {
    $hash{"avg$1"} = sprintf("%.2f", $hash{$key}/$days)
      if $key =~ /^total(.+)$/;
  }
  return \%hash;
}

sub totals {
  my $self = shift;

  my %hash;
  foreach my $key (@webalizerheader) {
    $hash{$1} = 0 if $key =~ /^total(.+)$/;
  }

  foreach my $month (@{$self->{_data}}) {
    foreach my $key (keys %$month) {
      $hash{$1} += $month->{$key} if $key =~ /^total(.+)$/;
    }
  }
  
  return \%hash;
}

sub _parse {
  my $self = shift;

  my @data;
  my @raw;
  if(ref($self->{source}) eq "SCALAR") {
    @raw = split(/\r?\n/, ${$self->{source}});
  } elsif(!ref($self->{source}) && $self->{source}) {
    open(my $FH, "<$self->{source}") || return 0;
    push(@raw, $_) while(<$FH>);
    close($FH);
  } else {
    return 0;
  }
  
  foreach my $line (@raw) {
    chomp($line);
    my $c = 0; my %line; my $item;
    foreach $item (split(/[\t\s]+/, $line)) {
      $line{$webalizerheader[$c++]} = int($item);
    }
    push(@data, \%line);
  }
  @data = sort { sprintf("%04d%02d", $b->{year}, $b->{month}) <=> sprintf("%04d%02d", $a->{year}, $a->{month}) } @data;
  @data = reverse @data if !$self->{desc};
  $self->{_data} = \@data;
  return 1;
}


1;

__END__

=head1 NAME

Webalizer::Hist - Perl module to parse the webalizer.hist-file.

=head1 VERSION

This document describes version 0.03 of Webalizer::Hist, released
2010-12-14.

=head1 SYNOPSIS

  use Webalizer::Hist;
  
  if(my $wh = Webalizer::Hist->new(source => "webalizer.hist")) {
  
    while(my $hashref = $dwh->month()) {
      printf "Got %d hits in month %s\n", $hashref->{totalhits}, $hashref->{month};
    }
  
    if(my $totals = $dwh->totals()) {
      printf "This website used a total of %d kB\n", $totals->{kbytes};
    }
    
  }

=head1 DESCRIPTION

Webalizer - a popular web server log analysis program - uses a so-called
C<webalizer.hist> file to store (temporary) statistics. That file
usually contains one year of monthly statistics about a website/webserver.

Webalizer::Hist can be used read and parse those data.

=head2 METHOS

The following methods can be used:

=head3 new

Creates a new Webalizer::Hist object using the configuration passed
to it in key/value-pairs. C<new> returns zero or undef on error.

=head4 options

The following options can be passed to C<new>:

=over 4

=item source

This option is required, specifies the source of the webalizer.hist-data
to be parsed. Can either be a scalar containing a filename or a scalarref
to the actual data.

=item desc

Optional, specifies the order in which the C<month> method should return
the data. Set to undef or zero to sort on the date in ascending order,
(newest month last) or set to a positive value to sort in descending order,
(newest month first) which is the default.

=back

=head3 month( [month] )

Returns a hashref containing the data for the month specified by the
optional argument C<month> (a number between 1 and 12), or the next
month in de list. (The order is specified by the C<desc>-option to 
C<new>).

The hashref contains the following keys:

  month year firstday lastday totalhits totalfiles
  totalsites totalkbytes totalpages totalvisits
  avghits avgfiles avgsites avgkbytes avgpages avgvisits

Most keys are self-explainable, C<month> and C<year> specifies the
month and the year of the data returned, and C<firstday> and C<lastday>
specify the beginning and ending of the month (in days). The C<total*>
keys give the total of the month, and the C<avg*> keys the daily
average.

=head3 totals

Returns a hashref containing the sum of the statistics for all months
found in the webalizer file. The hashref contains the following keys:

  hits files sites kbytes pages visits

=head1 SEE ALSO

Website of The Webalizer: L<http://www.mrunix.net/webalizer/>.

=head1 BUGS

No known bugs, but that doesn't mean there aren't any. If you find a
bug please report it at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Webalizer::Hist>
 or contact the author.

=head1 AUTHOR

Y. Heling, E<lt>yorhel@cpan.orgE<gt>, (L<http://yorhel.nl/>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Y. Heling

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
