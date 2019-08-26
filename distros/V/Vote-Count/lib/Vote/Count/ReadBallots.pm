package Vote::Count::ReadBallots;

use 5.022;
use feature qw/postderef signatures/;
no warnings qw/experimental/;
use Path::Tiny 0.108;
use Carp;
# use Data::Dumper;
# use Data::Printer;

# ABSTRACT: Read Ballots for Vote::Count. Toolkit for vote counting.

our $VERSION='0.022';

=head1 NAME

Vote::Count::ReadBallots

=head1 VERSION 0.022

=head1 SYNOPSIS

  Vote::Count::ReadBallots 'read_ballots';

  my $data1 = read_ballots('t/data/data1.txt');

=head1 Description

Reads a file containing vote data. Retruns a HashRef of a Vote::Count BallotSet.

=head1 BallotSet Data Structure

 ballots   {
        CHOCOLATE:MINTCHIP:VANILLA {
            count   1,
            votes   [
                [0] "CHOCOLATE",
                [1] "MINTCHIP",
                [2] "VANILLA"
            ]
        },
    },
    choices   {
        CHOCOLATE    1,
        MINTCHIP     1,
        VANILLA      1
    },
    votescast        1,
    comment   "# Optional Comment",
    options   {
      rcv   1
    }

=head1 Data File Format

  # This is a comment, optional.
  :CHOICES:VANILLA:CHOCOLATE:STRAWBERRY:MINTCHIP:CARAMEL:RUMRAISIN
  5:VANILLA:CHOCOLATE:STRAWBERRY
  RUMRAISIN

CHOICES must be defined before any vote lines. or an error will be thrown. CHOICES must only be defined once. These two rules are to protect against errors in manually prepared files.

A data line may begin with a number or a choice. When there is no number the line is counted as being a single ballot. The number represents the number of ballots identical to that one; this notation will both dramatically shrink the data files and improve performance.

=head2 read_ballots

Reads a data file in the standard Vote::Count format and returns a BallotSet.

=head2 write_ballots

  write_ballots( $BallotSet, $newfile);

Write out a ballotset. Useful for creating a compressed version of a raw file.

=head2 Other Formats

It is planned to add support in the future for ranged voting. JSON, XML, and YAML formats may also be provided in the future.

=cut


use Exporter::Easy (
       OK => [ qw( read_ballots write_ballots ) ],
   );

sub _choices ( $choices ) {
  my %C = ();
  $choices =~ m/^\:CHOICES\:(.*)/;
  for my $choice ( split /:/, $1 ) {
    $C{$choice} = 1;
  }
  return \%C;
}

## Add ballotscount !

sub read_ballots( $filename ) {
  my %data = (
    'choices' => undef,
    'ballots' => {},
    'options' => { 'rcv' => 1 },
    'votescast' => 0 ,
    'comment' => '' );
BALLOTREADLINES:
  for my $line_raw ( path($filename)->lines ) {
    if ( $line_raw =~ m/^\#/ ) {
      $data{'comment'} .= $line_raw;
      next BALLOTREADLINES;
    }
    chomp $line_raw;
    if ( $line_raw =~ m/^\:CHOICES\:/ ) {
      if ( $data{'choices'} ) {
        croak("File $filename redefines CHOICES \n$line_raw\n");
      }
      else { $data{'choices'} = _choices($line_raw); }
      next;
    }
    my $line = $line_raw;
    next unless ( $line =~ /\w/ );
    $line =~ s/^(\d+)\://;
    my $numbals = $1 ? $1 : 1;
    $data{'votescast'} += $numbals;
    if ( $data{'ballots'}{$line} ) {
      $data{'ballots'}{$line}{'count'} =
        $data{'ballots'}{$line}{'count'} + $numbals;
    }
    else {
      my @votes = ();
      for my $choice ( split( /:/, $line ) ) {
        unless ( $data{'choices'}{$choice} ) {
          die "Choice: $choice is not in defined choice list: "
            . join( ", ", keys( $data{'choices'}->%* ) ) .
            "\n -- $line\n";
        }
        push @votes, $choice;
      }
      $data{'ballots'}{$line}{'count'} = $numbals;
      $data{'ballots'}{$line}{'votes'} = \@votes;
    }
  }
  return \%data ;
}

sub write_ballots ( $BallotSet, $destination ) {
  my @data = ( '# Data rewritten in compressed form.');
  my $choicelist = join( ':', sort keys($BallotSet->{'choices'}->%*));
  push @data, "CHOICES:$choicelist";
  for my $k ( sort keys $BallotSet->{'ballots'}->%* ) {
    my $cnt = $BallotSet->{'ballots'}{$k}{'count'};
    push @data, "$cnt:$k";
  }
  for (@data) { $_ .= "\n" if $_ !~ /\n$/ }
  path( $destination )->spew( @data );
}


1;

#buildpod
#FOOTER

=pod

BUG TRACKER

L<https://github.com/brainbuz/Vote-Count/issues>

AUTHOR

John Karr (BRAINBUZ) brainbuz@cpan.org

CONTRIBUTORS

Copyright 2019 by John Karr (BRAINBUZ) brainbuz@cpan.org.

LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit L<http://fsf.org>.

=cut

