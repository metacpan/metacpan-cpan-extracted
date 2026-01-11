package WWW::Picnic::Result;
our $VERSION = '0.100';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Base class for Picnic API result objects

use Moo;


has raw => (
  is => 'ro',
  required => 1,
);


sub BUILDARGS {
  my ( $class, @args ) = @_;
  if ( @args == 1 && ref $args[0] ) {
    my $ref_type = ref $args[0];
    # Accept both HASH and ARRAY as raw data
    if ( $ref_type eq 'ARRAY' ) {
      return { raw => $args[0] };
    }
    if ( $ref_type eq 'HASH' && !exists $args[0]->{raw} ) {
      return { raw => $args[0] };
    }
  }
  return $class->SUPER::BUILDARGS(@args);
}

sub _get {
  my ( $self, $key ) = @_;
  return $self->raw->{$key};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Picnic::Result - Base class for Picnic API result objects

=head1 VERSION

version 0.100

=head1 SYNOPSIS

    # Base class for all result objects, not used directly
    package WWW::Picnic::Result::Something;
    use Moo;
    extends 'WWW::Picnic::Result';

=head1 DESCRIPTION

This is the base class for all WWW::Picnic result objects. It provides
common functionality for deserializing API responses into Perl objects.

=head2 raw

The raw hashref data from the API response. Useful for accessing fields
that don't have dedicated accessors yet.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-picnic/issues>.

=head2 IRC

You can reach Getty on C<irc.perl.org> for questions and support.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
