package WWW::Ohloh::API::Account;

use strict;
use warnings;

use Carp;
use Object::InsideOut qw/
  WWW::Ohloh::API::Role::Fetchable
  WWW::Ohloh::API::Role::LoadXML /;
use XML::LibXML;
use WWW::Ohloh::API::KudoScore;
use Time::Piece;
use Date::Parse;

use Params::Validate qw/ validate validate_with /;

our $VERSION = '0.3.2';

use overload '""' => sub { $_[0]->name };

#<<<
my @id_of               : Field 
                        : Set(_set_id) 
                        : Get(id)
                        ;
my @name_of             : Field 
                        : Set(_set_name) 
                        : Get(name)
                        ;
my @creation_date_of    : Field 
                        : Set(_set_created_at) 
                        : Get(created_at)
                        : Type(Time::Piece)
                        ;
my @update_date_of      : Field 
                        : Set(_set_updated_at) 
                        : Get(updated_at)
                        ;
my @homepage_url_of     : Field 
                        : Set(_set_homepage_url) 
                        : Get(homepage_url)
                        ;
my @avatar_url_of       : Field 
                        : Set(_set_avatar_url) 
                        : Get(avatar_url)
                        ;
my @posts_count_of      : Field 
                        : Set(_set_posts_count) 
                        : Get(posts_count)
                        ;
my @location_of         : Field 
                        : Set(_set_location) 
                        : Get(location)
                        ;
my @latitude_of         : Field 
                        : Set(_set_latitude) 
                        : Get(latitude)
                        ;
my @longitude_of        : Field 
                        : Set(_set_longitude) 
                        : Get(longitude)
                        ;
my @country_code_of     : Field 
                        : Set(_set_country_code) 
                        : Get(country_code)
                        ;
my @kudo_of             : Field 
                        : Set(_set_kudo) 
                        : Get(kudo_score)
                        ;
#>>>
my @kudos_of : Field : Arg(kudos);

my @stack : Field;

sub element_name { return 'account' }

sub generate_query_url : Chained(bottom up) {
    my ( $self, @args ) = @_;

    my %param = validate_with(
        params      => \@args,
        spec        => { id => 1 },
        allow_extra => 1
    );
    my $id = $param{id};
    delete $param{id};

    if ( index( $id, '@' ) > -1 ) {
        $id = md5_hex($id);
    }

    return ( "accounts/$id.xml", %param );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub load_xml {
    my ( $self, $dom ) = @_;

    $self->_set_id( $dom->findvalue('id/text()') );
    $self->_set_name( $dom->findvalue('name/text()') );
    $self->_set_created_at(
        Time::Piece->new( str2time( $dom->findvalue('created_at/text()') ) )
    );
    $self->_set_updated_at( $dom->findvalue('updated_at/text()') );
    $self->_set_homepage_url( $dom->findvalue('homepage_url/text()') );
    $self->_set_avatar_url( $dom->findvalue('avatar_url/text()') );
    $self->_set_posts_count( $dom->findvalue('posts_count/text()') );
    $self->_set_location( $dom->findvalue('location/text()') );
    $self->_set_country_code( $dom->findvalue('country_code/text()') );
    $self->_set_latitude( $dom->findvalue('latitude/text()') );
    $self->_set_longitude( $dom->findvalue('longitude/text()') );

    if ( my ($node) = $dom->findnodes('kudo_score[1]') ) {
        $kudo_of[$$self] = WWW::Ohloh::API::KudoScore->new( xml => $node );
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->startTag('account');

    $w->dataElement( $_ => $self->$_ ) for qw/
      id name created_at updated_at homepage_url
      avatar_url posts_count
      location
      country_code
      latitude
      longitude
      /;

    $xml .= $self->kudo->as_xml if $self->kudo;

    $w->endTag;

    return $xml;
}

sub kudoScore {
    my $self = shift;
    return $kudo_of[$$self];
}

# aliases
*kudo = *kudoScore;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub stack {
    my $self = shift;

    my $retrieve = shift;
    $retrieve = 1 unless defined $retrieve;

    if ( $retrieve and not $stack[$$self] ) {
        $stack[$$self] = $self->ohloh->get_account_stack( $self->id );
        $stack[$$self]->set_account($self);
    }

    return $stack[$$self];
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub sent_kudos {
    my $self = shift;

    $kudos_of[$$self] ||= $self->ohloh->get_kudos( id => $self->id );

    return $kudos_of[$$self]->sent;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub received_kudos {
    my $self = shift;

    $kudos_of[$$self] ||= $self->ohloh->get_kudos( id => $self->id );

    return $kudos_of[$$self]->received;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub kudos {
    my $self = shift;

    return $kudos_of[$$self] ||= $self->ohloh->get_kudos( id => $self->id );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

'end of WWW::Ohloh::API::Account';
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

=head3 stack( $retrieve )

Return the stack associated with the account as a
L<WWW::Ohloh::API::Stack> object.

If the optional I<$retrieve> argument is given and false,
the stack will not be queried from the Ohloh server and,
if the information has not been retrieved previously, the method
will return nothing.

=head2 Other Methods

=head3 as_xml

Return the account information (including the kudo score if it applies)
as an XML string.  Note that this is not the exact xml document as returned
by the Ohloh server.

=head1 OVERLOADING

When the object is called in a string context, it'll be replaced by
the name associated with the account. E.g.,

    print $account;  # equivalent to 'print $account->name'

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

