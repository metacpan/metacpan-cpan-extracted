package WebService::LiveJournal::List;

use strict;
use warnings;
use overload '""' => sub { $_[0]->as_string }, '@{}' => sub { $_[0]->{list} };

# ABSTRACT: List base class for WebService::LiveJournal
our $VERSION = '0.08'; # VERSION


sub new
{
  my $ob = shift;
  my $class = ref($ob) || $ob;
  my $self = bless { list => [] }, $class;
  my %arg = @_;
  $self->{list} = $arg{list} if defined $arg{list};
  $self->init(@_);

  foreach my $member (@{ $self })
  {
    $member->client($arg{client});
  }

  return $self;
}

sub push
{
  my $self = shift;
  push @{ $self }, @_;
}

sub find
{
  my $self = shift;
  my $key = shift;
  foreach my $element (@{ $self })
  {
    return $element if $element->name eq $key;
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LiveJournal::List - List base class for WebService::LiveJournal

=head1 VERSION

version 0.08

=head1 DESCRIPTION

This class is used as the base class for a number of
list classes included with the L<WebService::LiveJournal>
distribution.  You shouldn't need to interact with it
directly.

=head1 SEE ALSO

L<WebService::LiveJournal>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
