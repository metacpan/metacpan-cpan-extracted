package Twilio::Jwt::TaskRouter::Policy;

use 5.016;
use warnings;

our $VERSION = '2.002';

sub new {
  my ($class, $url, $method, @options) = @_;

  # A filter left out is an empty one, while undef means no filter at all: the token says so
  # differently, so the two cannot share a default.
  my ($query_filter, $post_filter, $allow) = @options;
  return bless {
    url          => $url,
    method       => $method,
    query_filter => @options > 0 ? $query_filter : {},
    post_filter  => @options > 1 ? $post_filter  : {},
    allow        => $allow // 1,
  }, $class;
}

sub add_query_filter {
  my ($self, $filter) = @_;
  $self->{query_filter} = _with_filter($self->{query_filter}, $filter);
  return;
}

sub add_post_filter {
  my ($self, $filter) = @_;
  $self->{post_filter} = _with_filter($self->{post_filter}, $filter);
  return;
}

# Filters with no names are a list, and they join named ones under the next free number, which
# is what a PHP array does and so what Twilio's clients have always been sent.
sub _with_filter {
  my ($filters, $filter) = @_;

  return [$filter]              if !$filters || (ref $filters eq 'HASH' && !%{$filters});
  return [@{$filters}, $filter] if ref $filters eq 'ARRAY';

  my @numbers = sort { $b <=> $a } grep { /\A[0-9]+\z/ } keys %{$filters};
  return { %{$filters}, (@numbers ? $numbers[0] + 1 : 0) => $filter };
}

sub to_hash {
  my ($self) = @_;

  my %policy = (url => $self->{url}, method => $self->{method}, allow => $self->{allow} ? \1 : \0);
  $policy{query_filter} = $self->{query_filter} if defined $self->{query_filter};
  $policy{post_filter}  = $self->{post_filter}  if defined $self->{post_filter};
  return \%policy;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Jwt::TaskRouter::Policy - One rule inside a TaskRouter capability token

=head1 SYNOPSIS

  my $policy = Twilio::Jwt::TaskRouter::Policy->new($url, 'GET', {}, {}, 1);

=head1 DESCRIPTION

Used by L<Twilio::Jwt::TaskRouter::CapabilityToken>.

=head1 METHODS

=head2 new

  my $policy = Twilio::Jwt::TaskRouter::Policy->new(
    $url, $method, \%query_filter, \%post_filter, $allow
  );

A filter that is left out is empty, and an undefined one is left out of the token.
C<$allow> defaults to true.

=head2 add_query_filter

=head2 add_post_filter

Add a filter.

=head2 to_hash

Returns the policy as it goes into the token.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
