package XML::NewsML_G2::Organisation;

use Moose;
use namespace::autoclean;

with 'XML::NewsML_G2::Role::HasQCode';

has 'isins', isa => 'ArrayRef[Str]', is => 'rw', default => sub { [] },
  traits => ['Array'], handles => {add_isin => 'push'};
has 'websites', isa => 'ArrayRef[Str]', is => 'rw', default => sub { [] },
  traits => ['Array'], handles => {add_website => 'push', has_websites => 'count'};
has 'indices', isa => 'ArrayRef[Str]', is => 'rw', default => sub { [] },
  traits => ['Array'], handles => {add_index => 'push'};
has 'stock_exchanges', isa => 'ArrayRef[Str]', is => 'rw', default => sub { [] },
  traits => ['Array'], handles => {add_stock_exchange => 'push'};

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Oranisation - a company or organisation

=head1 SYNOPSIS

    my $org = XML::NewsML_G2::Organisation->new
        (name => 'Google Inc.', qcode => 'gogl', websites => ["http://google.com"]);

=head1 ATTRIBUTES

=over 4

=item isins

List of international securities identification numbers.

=item websites

List of the websites

=item indices

List of stock indexes covering this organisation

=item stock_exchanges

List of stock exchanges where this organisation is listed

=back

=head2 METHODS

=over 4

=item add_isin

=item add_website

=item add_index

=item add_stock_exchange

=back

=head1 AUTHOR

Philipp Gortan  C<< <philipp.gortan@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
