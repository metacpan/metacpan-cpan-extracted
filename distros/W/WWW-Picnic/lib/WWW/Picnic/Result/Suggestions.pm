package WWW::Picnic::Result::Suggestions;
# ABSTRACT: Collection of Picnic search suggestions
our $VERSION = '0.101';
use Moo;

extends 'WWW::Picnic::Result';


has suggestions => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;
    my $raw = $self->raw;
    return ref $raw eq 'ARRAY' ? $raw : ( $raw->{suggestions} || [] );
  },
);


sub all_suggestions {
  my ( $self ) = @_;
  return @{ $self->suggestions };
}


sub total_count {
  my ( $self ) = @_;
  return scalar @{ $self->suggestions };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Picnic::Result::Suggestions - Collection of Picnic search suggestions

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    my $suggestions = $picnic->get_suggestions('har');
    say "Found ", $suggestions->total_count, " suggestions";

    for my $suggestion ($suggestions->all_suggestions) {
        say $suggestion->{suggestion};
    }

=head1 DESCRIPTION

Container for the search suggestions returned by the C<suggest> endpoint.
The API returns a plain list, reachable via L</all_suggestions>.

=head2 suggestions

Arrayref of suggestion entries from the API response.

=head2 all_suggestions

Returns list of all suggestion entries (as opposed to arrayref).

=head2 total_count

Returns total number of suggestions.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-picnic/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
