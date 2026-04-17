package WWW::PayPal::Product;

# ABSTRACT: PayPal Catalogs Product entity

use Moo;
use namespace::clean;

our $VERSION = '0.002';


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has data => ( is => 'rw', required => 1 );


sub id          { $_[0]->data->{id} }
sub name        { $_[0]->data->{name} }
sub type        { $_[0]->data->{type} }
sub category    { $_[0]->data->{category} }
sub description { $_[0]->data->{description} }
sub create_time { $_[0]->data->{create_time} }
sub update_time { $_[0]->data->{update_time} }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PayPal::Product - PayPal Catalogs Product entity

=head1 VERSION

version 0.002

=head1 DESCRIPTION

Wrapper around a PayPal catalog product JSON object.

=head2 data

Raw decoded JSON for the product.

=head2 id

Product ID (e.g. C<PROD-XXX...>). Pass this to
L<WWW::PayPal::API::Plans/create>.

=head2 name

=head2 type

C<PHYSICAL>, C<DIGITAL>, or C<SERVICE>.

=head2 category

PayPal merchant category code, e.g. C<SOFTWARE>.

=head2 description

=head2 create_time

=head2 update_time

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-paypal/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
