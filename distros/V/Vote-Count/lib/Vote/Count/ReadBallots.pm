package Vote::Count::ReadBallots;

use 5.022;
use feature qw/postderef signatures/;
no warnings qw/experimental/;
use Path::Tiny 0.108;
use Carp;
use JSON::MaybeXS;
use YAML::XS;
# use Data::Dumper;
use Data::Printer;

# ABSTRACT: Read Ballots for Vote::Count. Toolkit for vote counting.

our $VERSION='1.00';

=head1 NAME

Vote::Count::ReadBallots

=head1 VERSION 1.00

=head1 SYNOPSIS

  Vote::Count::ReadBallots;

  my $data1 = read_ballots('t/data/data1.txt');

=head1 Description

Reads a file containing vote data. Retruns a HashRef of a Vote::Count BallotSet.

All public methods are exported.

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

=head1 Range Ballots

Range Ballots are supported in both JSON and YAML format. The read method doesn't perform validation like B<read_ballots> does.

=head2 Range Ballot Format in JSON

  {
    "choices": [
      "TWEEDLEDEE",
      "TWEEDLEDUM",
      "HUMPTYDUMPTY"
    ],
    "ballots": [
      {
        "votes": {
          "TWEEDLEDEE": 1,
          "TWEEDLEDUM": 1,
          "HUMPTYDUMPTY": 3
        },
        "count": 3
      }
    ],
    "depth": 3
  }

=head2 read_range_ballots

Requires a parameter of a JSON or YAML file. The second parameter may be either 'json' or 'yaml', defaulting to 'json'.

  my $BestFastFood = read_range_ballots('t/data/fastfood.range.json');
  my $BestFastFood = read_range_ballots('t/data/fastfood.range.yml', 'yaml');

=head2 write_range_ballots

Takes three parameters, a BallotSet, a file location, and a value of 'json' or 'yaml'. The first two parameters are required, the third defaults to 'json'.

  write_range_ballots( $BestFastFood, '/tmp/fast.json', 'json' );

=cut

use Exporter::Easy ( EXPORT =>
    [qw( read_ballots write_ballots read_range_ballots write_range_ballots)],
);

my $coder = Cpanel::JSON::XS->new->ascii->pretty;

sub _choices ( $choices ) {
  my %C = ();
  $choices =~ m/^\:CHOICES\:(.*)/;
  for my $choice ( split /:/, $1 ) {
    $C{$choice} = 1;
  }
  return \%C;
}

sub read_ballots( $filename ) {
  my %data = (
    'choices'   => undef,
    'ballots'   => {},
    'options'   => { 'rcv' => 1 },
    'votescast' => 0,
    'comment'   => ''
  );
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
            . join( ", ", keys( $data{'choices'}->%* ) )
            . "\n -- $line\n";
        }
        push @votes, $choice;
      }
      $data{'ballots'}{$line}{'count'} = $numbals;
      $data{'ballots'}{$line}{'votes'} = \@votes;
    }
  }
  return \%data;
}

sub write_ballots ( $BallotSet, $destination ) {
  my @data = ('# Data rewritten in compressed form.');
  my $choicelist = join( ':', sort keys( $BallotSet->{'choices'}->%* ) );
  push @data, "CHOICES:$choicelist";
  for my $k ( sort keys $BallotSet->{'ballots'}->%* ) {
    my $cnt = $BallotSet->{'ballots'}{$k}{'count'};
    push @data, "$cnt:$k";
  }
  for (@data) { $_ .= "\n" if $_ !~ /\n$/ }
  path($destination)->spew(@data);
}

sub write_range_ballots ( $BallotSet, $destination, $format = 'json' ) {
  $BallotSet->{'choices'} = [ sort keys $BallotSet->{'choices'}->%* ];
  if ( $format eq 'json' ) {
    path($destination)->spew( $coder->encode($BallotSet) );
  }
  elsif ( $format eq 'yaml' ) {
    $BallotSet = Load path->($destination)->slurp;
    path($destination)->spew( Dump $BallotSet);
  }
  else { die "invalid score ballot format $format." }
}

sub read_range_ballots ( $source, $format = 'json' ) {
  my $BallotSet = undef;
  if ( $format eq 'json' ) {
    $BallotSet = $coder->decode( path($source)->slurp );
  }
  elsif ( $format eq 'yaml' ) {
    $BallotSet = Load path($source)->slurp;
  }
  else { die "invalid score ballot format $format." }
  $BallotSet->{'votescast'} = 0;
  $BallotSet->{'options'} = { 'range' => 1, 'rcv' => 0 };
  my @choices = $BallotSet->{'choices'}->@*;
  $BallotSet->{'choices'} = { map { $_ => 1 } @choices };
  for my $ballot ( $BallotSet->{'ballots'}->@* ) {
    $BallotSet->{'votescast'} += $ballot->{'count'};
  }
  return $BallotSet;
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

