# $Id: DB.pm,v 1.2 2004/03/31 20:28:46 claes Exp $

package WWW::Search::Tv::Sweden::TvDotNu::DB;
use strict;

sub new {
  my $class = shift;
  $class = ref($class) || $class;
  my $entries = shift;
  $entries = defined $entries && ref $entries eq 'ARRAY' ? $entries : [];
  bless {
	 entries => $entries,
	}, $class;
}

sub add {
  my ($self, $entry) = @_;
  push @{$self->{entries}}, $entry;
}

sub last {
  my ($self) = @_;
  return ${$self->{entries}}[-1];
}

sub channels {
  my ($self) = @_;
  my %channels = map { $_->channel => 1 } @{$self->{entries}};
  return keys %channels;
}

sub for_channel {
  my $self = shift;
  my @entries;

  die "Must supply channels" unless @_;

  my $channels = "^(?:" . join("|", @_) . ")\$";
  my $re = qr/$channels/i;

  @entries = grep { lc($_->channel) =~ $re } @{$self->{entries}};

  return WWW::Search::Tv::Sweden::TvDotNu::DB->new(\@entries);
}

sub between {
  my ($self, $start_hour, $start_min, $end_hour, $end_min) = @_;

  my @entries = grep { $_->in($start_hour, $start_min, $end_hour, $end_min) } @{$self->{entries}};
  return WWW::Search::Tv::Sweden::TvDotNu::DB->new(\@entries);
}


sub entries {
  my ($self) = @_;
  return @{$self->{entries}};
}

1;
