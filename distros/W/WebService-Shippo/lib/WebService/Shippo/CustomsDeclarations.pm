use strict;
use warnings;
use MRO::Compat 'c3';

package WebService::Shippo::CustomsDeclarations;
require WebService::Shippo::CustomsDeclaration;
use base qw(
    WebService::Shippo::Collection
    WebService::Shippo::Create
    WebService::Shippo::Fetch
);

sub item_class () { 'WebService::Shippo::CustomsDeclaration' }

sub collection_class () { __PACKAGE__ }

BEGIN {
    no warnings 'once';
    *Shippo::CustomsDeclarations:: = *WebService::Shippo::CustomsDeclarations::;
}

1;

=pod

=encoding utf8

=head1 NAME

WebService::Shippo::CustomsDeclarations - Customs Declaration collection class

=head1 VERSION

version 0.0.21

=head1 DESCRIPTION

Customs declarations are relevant information, including one or
multiple customs items, you need to provide for customs clearance
for your international shipments.

=head1 API DOCUMENTATION

For more information about Customs Declarations, consult the Shippo API
documentation:

=over 2

=item * L<https://goshippo.com/docs/#customsdeclarations>

=back

=head1 REPOSITORY

=over 2

=item * L<https://github.com/cpanic/WebService-Shippo>

=item * L<https://github.com/cpanic/WebService-Shippo/wiki>

=back

=head1 AUTHOR

Iain Campbell <cpanic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Iain Campbell.

You may distribute this software under the terms of either the GNU General
Public License or the Artistic License, as specified in the Perl README
file.

=cut
