package XML::NewsML_G2::Product;

use Moose;
use namespace::autoclean;


has 'name', isa => 'Str', is => 'ro', lazy => 1, builder => '_build_name';
has 'isbn', isa => 'Str', is => 'rw';
has 'ean', isa => 'Str', is => 'rw';
has 'name_template', isa => 'Str', is => 'ro', default => 'Product %d';

{
    my $product_count = 0;
    sub _build_name {
        my $self = shift;
        return sprintf $self->name_template, ++$product_count;
    }
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Product - a product that is mentioned in the news item

=head1 SYNOPSIS

    my $book = XML::NewsML_G2::Product->new
        (name => 'Some Book', isbn => '1-2345-6789');

=head1 ATTRIBUTES

=over 4

=item name

=item isbn

international standard book number

=item ean

european/international article number

=back

=head1 AUTHOR

Philipp Gortan  C<< <philipp.gortan@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
