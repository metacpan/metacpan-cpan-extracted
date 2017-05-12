package WebService::Affiliate::Voucher::TradeDoubler;

use Moose;
use namespace::autoclean;

use DateTime::Format::ISO8601;

with 'WebService::Affiliate::Role::Voucher';

=head1 NAME

WebService::Affiliate::Voucher::TradeDoubler - TradeDoubler specific voucher code model.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01_01';

$VERSION = eval $VERSION;

=head1 SYNOPSIS

Models a TradeDoubler voucher code.

=cut

=head1 DESCRIPTION

=cut



=head1 METHODS

=head2 Attributes

=cut

has id => ( is => 'rw', isa => 'Int' );


has _updated     => ( is => 'rw', isa => 'Str',                                                                  );
has  updated     => ( is => 'rw', isa => 'Maybe[DateTime]',               lazy => 1, builder => '_build_updated' );

has title             => ( is => 'rw', isa => 'Str' );
has short_description => ( is => 'rw', isa => 'Str' );
has type              => ( is => 'rw', isa => 'Str' );




sub _build_updated
{
    my ($self) = @_;

    return undef if ! $self->_updated;

    return DateTime::Format::MySQL->parse_datetime( $self->_updated ) if $self->_updated =~ /^\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d$/;
    return DateTime::Format::ISO8601->parse_datetime( $self->_updated );
}



=head1 METHODS

=head2 Class Methods

=head3 new


=cut

__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Rob Brown, C<< <rob at intelcompute.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-affiliate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Affiliate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Affiliate

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Affiliate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Affiliate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Affiliate>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Affiliate/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Rob Brown.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of WebService::Affiliate
