package Wordnet::SenseSearch;

use 5.008008;
use strict;
use warnings;
use Search::Dict;

our $VERSION = '0.02';
our $WNDICT = '/usr/local/WordNet-2.1/dict/';

our @DATAFILES = qw(data.noun data.verb data.adj data.adv data.adj);

sub new {
    my $self = {};
    my $class = shift;
    bless $self, $class;
    my %params = @_;
    $self->{_dictdir} = $params{dir} || $WNDICT;
    open $self->{_senseidx_fh}, $self->{_dictdir} . "/index.sense" or die $!;
    return $self;
}

# takes a sense key (i.e. "animal%1:03:00::") and returns some of the 
# synset data
sub lookup {
    my $self = shift;
    my $key = shift;
    return unless $key;
    my $fh = $self->{_senseidx_fh};
    look $fh, $key;
    my $line = <$fh>;
    my ($lemma,$sstype,$lexfile,$lexid,$headword,$headid,$offset,$sensenum,
          $tagcnt) =
          $line =~ m|^(\S+?)%(\d):(\d\d):(\d\d):(\S+?)*:
          (\d\d)*\s+(\d+)\s(\d+)\s(\d+)\s*$|x;
    open DATA, $self->{_dictdir} . "/" . $DATAFILES[$sstype-1] or die $!;
    seek DATA, $offset, 0;
    my $entry = <DATA>;
    close DATA;
    $entry =~ m|^(\d+)\s(\d\d)\s(\w)\s([\dA-Fa-f]+)\s|g;
    my ($pos,$wcnt) = ($3,hex($4)); # can't do inline assignment with /g
    my @words;
    for (1 .. $wcnt) {
        push @words, $entry =~ m|\G(\S+?)\s[\dA-Fa-f]\s|g;
    }
    my ($gloss) = $entry =~ m/\|\s*(.+?)\s*$/;
    return (words => \@words, pos => $pos, lexfile => $lexfile,
            sensenum => $sensenum, gloss => $gloss);
}

1;
__END__
=head1 NAME

Wordnet::SenseSearch - Just get a synset from a sense key

=head1 SYNOPSIS

  use Wordnet::SenseSearch;
  my $search = new Wordnet::SenseSearch (dir => '/usr/local/Wordnet/dict/');
  my %synset = $search->lookup('animal%1:03:00::');
  print join ", ", @{$synset{words}};
  print $synset{pos};
  print $synset{gloss};

=head1 DESCRIPTION

This module does just one thing: returns the typically useful text for a synset, given its synset index key. The format of these keys and the sense index is described at:

  http://wordnet.princeton.edu/man/senseidx.5WN.html

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Danny Brian.

=cut
