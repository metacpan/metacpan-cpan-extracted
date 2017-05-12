package WWW::Ohloh::API::Analysis;

use strict;
use warnings;

use Carp;
use Object::InsideOut;

our $VERSION = '0.3.2';

my @request_url_of : Field : Arg(request_url) : Get( request_url );
my @xml_of : Field : Arg(xml);

my @id_of : Field : Get(id) : Set(_set_id);
my @project_id_of : Field : Get(project_id) : Set(_set_project_id);
my @updated_at_of : Field : Get(updated_at) : Set(_set_updated_at);
my @logged_at_of : Field : Get(logged_at) : Set(_set_logged_at);
my @min_month_of : Field : Get(min_month) : Set(_set_min_month);
my @max_month_of : Field : Get(max_month) : Set(_set_max_month);
my @twelve_month_contributor_count_of : Field :
  Get(twelve_month_contributor_count) :
  Set(_set_twelve_month_contributor_count);
my @total_code_lines_of : Field : Get(total_code_lines) :
  Set(_set_total_code_lines);
my @main_language_id_of : Field : Get(main_language_id) :
  Set(_set_main_language_id);
my @main_language_name_of : Field : Get(main_language_name) :
  Set(_set_main_language_name);

sub _init : Init {
    my $self = shift;

    my $dom = $xml_of[$$self] or return;

    $self->_set_id( $dom->findvalue('id/text()') );
    $self->_set_project_id( $dom->findvalue('project_id/text()') );
    $self->_set_updated_at( $dom->findvalue('updated_at/text()') );
    $self->_set_logged_at( $dom->findvalue('logged_at/text()') );
    $self->_set_min_month( $dom->findvalue('min_month/text()') );
    $self->_set_max_month( $dom->findvalue('max_month/text()') );
    $self->_set_twelve_month_contributor_count(
        $dom->findvalue('twelve_month_contributor_count/text()') );
    $self->_set_total_code_lines(
        $dom->findvalue('total_code_lines/text()') );
    $self->_set_main_language_id(
        $dom->findvalue('main_language_id/text()') );
    $self->_set_main_language_name(
        $dom->findvalue('main_language_name/text()') );

    return;
}

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->startTag('analysis');
    for my $attr (
        qw/ id project_id
        updated_at logged_at min_month
        max_month twelve_month_contributor_count
        total_code_lines
        main_language_name
        main_language_id
        /
      ) {
        $w->dataElement( $attr, $self->$attr );
    }

    $w->endTag;

    return $xml;
}

*language = *main_language = *main_language_name;

'end of WWW::Ohloh::API::Analysis';
__END__

=head1 NAME

WWW::Ohloh::API::Account - an Ohloh account

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );
    my $account $ohloh->get_account( id => 12933 );

    print $account->name;

=head1 DESCRIPTION

W::O::A::Account contains the information associated with an Ohloh 
account as defined at http://www.ohloh.net/api/reference/account. 
To be properly populated, it must be created via
the C<get_account> method of a L<WWW::Ohloh::API> object.

=head1 METHODS 

=head2 API Data Accessors

=head3 id

Return the account's id.

=head3 name

Return the public name of the account.

=head3 created_at

Return the time at which the account was created.

=head3 updated_at

Return the last time at which the account was modified.

=head3 homepage_url

Return the URL to a member's home page, such as a blog, or I<undef> if not
configured.

=head3 avatar_url

Return the URL to the profile image displayed on Ohloh pages, or I<undef> if
not configured.

=head3 posts_count

Return the number of posts made to the Ohloh forums by this account.

=head3 location

Return a text description of this account holder's claimed location, or
I<undef> if not
available. 

=head3 country_code

Return a string representing the account holder's country, or I<undef> is
unavailable. 

=head3 latitude, longitude

Return floating-point values representing the account's latitude and longitude, 
suitable for use with the Google Maps API, or I<undef> is they are not
available.

=head3 kudoScore, kudo_score, kudo

Return a L<WWW::Ohloh::API::KudoScore> object holding the account's 
kudo information, or I<undef> if the account doesn't have a kudo score
yet. All three methods are equivalent.

=head2 Other Methods

=head3 as_xml

Return the account information (including the kudo score if it applies)
as an XML string.  Note that this is not the exact xml document as returned
by the Ohloh server: due to the current XML parsing module used
by W::O::A (to wit: L<XML::Simple>), the ordering of the nodes can differ.

=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>, L<WWW::Ohloh::API::KudoScore>.

=item *

Ohloh API reference: http://www.ohloh.net/api/getting_started

=item * 

Ohloh Account API reference: http://www.ohloh.net/api/reference/account

=back

=head1 VERSION

This document describes WWW::Ohloh::API version 0.3.2

=head1 BUGS AND LIMITATIONS

WWW::Ohloh::API is very extremely alpha quality. It'll improve,
but till then: I<Caveat emptor>.

The C<as_xml()> method returns a re-encoding of the account data, which
can differ of the original xml document sent by the Ohloh server.

Please report any bugs or feature requests to
C<bug-www-ohloh-api@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Yanick Champoux  C<< <yanick@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Yanick Champoux C<< <yanick@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.





