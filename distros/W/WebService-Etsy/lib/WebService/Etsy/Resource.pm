package WebService::Etsy::Resource;

use strict;
use warnings;
use base qw( Class::Accessor );
__PACKAGE__->mk_accessors( qw( api detail_level ) );

=head1 NAME

WebService::Etsy::Resource - Returned resources from the Etsy API.

=head1 SYNOPSIS

    my $resp = $api->getFeaturedSellers( detail_level => 'medium' );
    # call methods on the object
    print $resp->count . " featured sellers\n";
    # use the object like an arrayref of resources
    for my $shop ( @$resp ) {
        # $shop is a WebService::Etsy::Resource::Shop object
        print $shop->shop_name, "\n";
    }

=head1 DESCRIPTION

The API returns different resource types - shops, users, listings, methods, tags, materials, sections, feedbacks, ints, and strings.

Each return type has its own corresponding Perl class, with methods appropriate to its contents.

=cut

=head1 METHODS

=over 4

=item C<new( $data )>

Constructor method inherited by Resource classes from the Resource base class. Takes the data for the resource as extracted from the API response.

Generally only called by other methods in this library.

=back

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $data = shift;
    my $self;
    if ( ref $data ) {
        $self = bless $data, $class;
    } else {
        $self = bless {}, $class;
        $self->value( $data );
    }
    $self->_init( @_ );
    return $self;
}

sub _init {
    my $self = shift;
    my %params = @_;
    for ( qw( detail_level api ) ) {
        if ( $params{ $_ } ) {
            $self->$_( $params{ $_ } );
        }
    }
}

=head1 RESULT OBJECTS

=head2 WebService::Etsy::Resource::String

The object behaves just like a string in scalar context. It does provide a C<value()> method if you need it.

=cut

package WebService::Etsy::Resource::String;
use base qw( WebService::Etsy::Resource );
__PACKAGE__->mk_accessors( qw( value ) );

use overload '""' => "stringify", fallback => 1;

sub stringify {
    return $_[ 0 ]->value;
}    

#-------

=head2 WebService::Etsy::Resource::Int

The object behaves just like an integer in scalar context. It does provide a C<value()> method if you need it.

=cut

package WebService::Etsy::Resource::Int;
use base qw( WebService::Etsy::Resource::String );

#-------

=head2 WebService::Etsy::Resource::Material

The object behaves just like a string in scalar context. It does provide a C<value()> method if you need it.

=cut

package WebService::Etsy::Resource::Material;
use base qw( WebService::Etsy::Resource::String );

#-------

=head2 WebService::Etsy::Resource::Tag

The object behaves just like a string in scalar context. It does provide a C<value()> method if you need it.

=head3 Additional methods

=over 4

=item C<spaced>

The string value of the tag with underscores translated to spaces.

=item C<children>

The "child tags" of this tag. Equivalent to calling C<getChildTags> with this tag as the parameter. You can pass in any other parameters C<getChildTags> accepts.

=back

=cut

package WebService::Etsy::Resource::Tag;
use base qw( WebService::Etsy::Resource::String );
__PACKAGE__->mk_accessors( qw( spaced ) );

sub children {
    my $self = shift;
    return $self->api->getChildTags( tag => $self );
}

sub _init {
    my $self = shift;
    $self->SUPER::_init( @_ );
    my $value = $self->value;
    $value =~ s/_/ /g;
    $self->spaced( $value );
}

#-------

=head2 WebService::Etsy::Resource::Category

The object behaves just like a string in scalar context. It does provide a C<value()> method if you need it.

=head3 Additional methods

=over 4

=item C<spaced>

The string value of the category with underscores translated to spaces.

=item C<children>

The "child categories" of this tag. Equivalent to calling C<getChildCategories> with this category as the parameter. You can pass in any other parameters C<getChildCategories> accepts.

=back

=cut

package WebService::Etsy::Resource::Category;
use base qw( WebService::Etsy::Resource::Tag );

sub children {
    my $self = shift;
    return $self->api->getChildCategories( category => $self );
}

#-------

=head2 WebService::Etsy::Resource::User

The object includes methods corresponding to the field values described at L<http://developer.etsy.com/docs#users>.

Some of the methods may return undef if the relevant detail level was not requested.

=head3 Additional methods

=over 4

=item C<shop>

If the user is a seller, returns the shop object for the user. Equivalent to calling C<getShopDetails> with this user's ID as the parameter. You can pass in any other parameters C<getShopDetails> accepts.

=back

=cut

package WebService::Etsy::Resource::User;
use base qw( WebService::Etsy::Resource );
__PACKAGE__->mk_accessors( qw( user_name user_id url image_url_25x25 image_url_30x30 image_url_50x50 image_url_75x75 join_epoch city gender lat lon transaction_buy_count transaction_sold_count is_seller was_featured_seller materials last_login_epoch referred_user_count birth_day birth_month bio feedback_count feedback_percent_positive ) );

sub shop {
    my $self = shift;
    my $seller = $self->is_seller;
    if ( ! defined $seller ) {
        $self->api->last_error( qq[Insufficient detail to tell if user "] . $self->user_name . qq[" (] . $self->user_id . qq[) is a seller] );
        return;
    } elsif ( $seller ) {
        my %params = ( user_id => $self->user_id, @_ );
        if ( !exists $params{ detail_level } ) {
            $params{ detail_level } = $self->detail_level;
        }
        return $self->api->getShopDetails( %params );
    } else {
        $self->api->last_error( qq[User "] . $self->user_name . qq[" (] . $self->user_id . qq[) is not a seller] );
        return;
    }
}

#-------

=head2 WebService::Etsy::Resource::Shop

The object includes methods corresponding to the field values described at L<http://developer.etsy.com/docs#shops>. Note that it extends the C<WebService::Etsy::Resource::User> class.

Some of the methods may return undef if the relevant detail level was not requested.

=head3 Additional methods

=over 4

=item C<listings>

Get the listings for the shop. Equivalent to calling C<getListings> with this shop's ID as the parameter. You can pass in any other parameters C<getListings> accepts.

=back

=cut

package WebService::Etsy::Resource::Shop;
use base qw( WebService::Etsy::Resource::User );
__PACKAGE__->mk_accessors( qw( banner_image_url last_updated_epoch creation_epoch listing_count shop_name title sale_message announcement is_vacation vacation_message currency_code sections ) );

sub listings {
    my $self = shift;
    my %params = ( user_id => $self->user_id, @_ );
    if ( !exists $params{ detail_level } ) {
        $params{ detail_level } = $self->detail_level;
    }
    return $self->api->getShopListings( %params );
}

sub _init {
    my $self = shift;
    $self->SUPER::_init( @_ );
    my $sections = $self->sections;
    if ( ! $sections ) {
        return;
    }
    my $api = $self->api;
    for ( @$sections ) {
        $_ = WebService::Etsy::Resource::ShopSection->new( $_, api => $api );
        $_->shop( $self );
    }
    $self->sections( $sections );
}

#-------

=head2 WebService::Etsy::Resource::Listing

The object includes methods corresponding to the field values described at L<http://developer.etsy.com/docs#listings>.

Some of the methods may return undef if the relevant detail level was not requested.

=head3 Additional methods

=over 4

=item C<shop>

Return the shop object for the listing's seller. Equivalent to calling C<getShopDetails> with this listing's shop ID as the parameter. You can pass in any other parameters C<getShopDetails> accepts.

=back

=cut

package WebService::Etsy::Resource::Listing;
use base qw( WebService::Etsy::Resource );
__PACKAGE__->mk_accessors( qw( listing_id state title url image_url_25x25 image_url_50x50 image_url_75x75 image_url_155x125 image_url_200x200 image_url_430xN creation_epoch views tags materials price currency_code ending_epoch user_id user_name quantity description lat lon city section_id section_title hsv_color rgb_color ) );

sub shop {
    my $self = shift;
    my $seller = $self->user_id;
    if ( ! defined $seller ) {
        $self->api->last_error( qq[Insufficient detail to determine shop for listing ] . $self->listing_id );
        return;
    } else {
        my %params = ( user_id => $seller, @_ );
        if ( !exists $params{ detail_level } ) {
            $params{ detail_level } = $self->detail_level;
        }
        return $self->api->getShopDetails( %params );
    }
}

sub _init {
    my $self = shift;
    $self->SUPER::_init( @_ );
    my $api = $self->api;
    my $tags = $self->tags;
    if ( $tags ) {
        for ( @$tags ) {
            $_ = WebService::Etsy::Resource::Tag->new( $_, api => $api );
        }
        $self->tags( $tags );
    }
    my $materials = $self->materials;
    if ( $materials ) {
        for ( @$materials ) {
            $_ = WebService::Etsy::Resource::Material->new( $_, api => $api );
        }
        $self->materials( $materials );
    }
}
#-------

=head2 WebService::Etsy::Resource::GiftGuide

The object includes methods corresponding to the field values described at L<http://developer.etsy.com/docs#gift_guides>.

=head3 Additional methods

=over 4

=item C<listings>

Return the listings in the guide. Equivalent to calling C<getGiftGuides> with this guide's ID as the parameter. You can pass in any other parameters C<getGiftGuides> accepts.

=back

=cut

package WebService::Etsy::Resource::GiftGuide;
use base qw( WebService::Etsy::Resource );
__PACKAGE__->mk_accessors( qw( guide_id creation_tsz_epoch description title display_order guide_section_id guide_section_title ) );

sub listings {
    my $self = shift;
    my %params = ( guide_id => $self->guide_id, @_ );
    if ( !exists $params{ detail_level } ) {
        $params{ detail_level } = $self->detail_level;
    }
    return $self->api->getGiftGuideListings( %params );
}

#-------

=head2 WebService::Etsy::Resource::Feedback

The object includes methods corresponding to the field values described at L<http://developer.etsy.com/docs#feedback>.

=head3 Additional methods

=over 4

=item C<buyer()>

Get the user object of the buyer. Equivalent to calling C<getUserDetails> with this user's ID as the parameter. You can pass in any other parameters C<getUserDetails> accepts.

=item C<seller()>

Get the shop object of the seller. Equivalent to calling C<getShopDetails> with this user's ID as the parameter. You can pass in any other parameters C<getShopDetails> accepts.

=item C<author()>

Get the user or shop object of the author (user if the buyer is the author, shop if the seller is the author). Equivalent to calling C<getUserDetails> (or C<getShopDetails>) with this user's ID as the parameter. You can pass in any other parameters C<getUserDetails> (or C<getShopDetails>) accepts.

=item C<subject()>

Get the user or shop object of the subject (user if the buyer is the subject, shop if the seller is the subject). Equivalent to calling C<getUserDetails> (or C<getShopDetails>) with this user's ID as the parameter. You can pass in any other parameters C<getUserDetails> (or C<getShopDetails>) accepts.

=item C<from_buyer()>

Boolean - is the feedback from a buyer?

=item C<from_seller()>

Boolean - is the feedback from a seller?

=back

=cut

package WebService::Etsy::Resource::Feedback;
use base qw( WebService::Etsy::Resource );
__PACKAGE__->mk_accessors( qw( url creation_epoch feedback_id author_user_id subject_user_id seller_user_id buyer_user_id message disposition value image_url_25x25 image_url_fullxfull from_seller from_buyer ) );

sub _init {
    my $self = shift;
    $self->SUPER::_init( @_ );
    if ( $self->author_user_id == $self->buyer_user_id ) {
        $self->from_seller( 0 );
        $self->from_buyer( 1 );
    } else {
        $self->from_seller( 1 );
        $self->from_buyer( 0 );
    }
}

sub _getUser {
    my $self = shift;
    my %params = @_;
    my $method = ( $params{ get_shop } ) ? "getShopDetails" : "getUserDetails";
    delete $params{ get_shop };
    return $self->api->$method( %params );
}

sub buyer {
    my $self = shift;
    return $self->_getUser( user_id => $self->buyer_user_id, @_ );
}

sub seller {
    my $self = shift;
    return $self->_getUser( get_shop => 1, user_id => $self->seller_user_id, @_ );
}

sub author {
    my $self = shift;
    return $self->_getUser( get_shop => $self->from_seller, user_id => $self->author_user_id, @_ );
}

sub subject {
    my $self = shift;
    return $self->_getUser( get_shop => ! $self->from_seller, user_id => $self->subject_user_id, @_ );
}

#-------

=head2 WebService::Etsy::Resource::ShopSection

The object includes methods corresponding to the field values described at L<http://developer.etsy.com/docs#shop_sections>.

=head3 Additional methods

=over 4

=item C<listings()>

Get the listings in a section. Equivalent to calling C<getShopListings> section's ID as the section parameter. You can pass in any other parameters C<getShopListings> accepts.

=back

=cut

package WebService::Etsy::Resource::ShopSection;
use base qw( WebService::Etsy::Resource );
__PACKAGE__->mk_accessors( qw( shop section_id title listing_count ) );

sub listings {
    my $self = shift;
    my %params = ( user_id => $self->shop->user_id, section_id => $self->section_id, @_ );
    return $self->api->getShopListings( %params );
}

#-------

=head2 WebService::Etsy::Resource::Method

The object includes methods corresponding to the field values described at L<http://developer.etsy.com/docs#methods>.

=cut

package WebService::Etsy::Resource::Method;
use base qw( WebService::Etsy::Resource );
__PACKAGE__->mk_accessors( qw( name description uri params type http_method ) );

package WebService::Etsy::Resource;

=head1 SEE ALSO

L<http://developer.etsy.com/docs#resource_types>, L<WebService::Etsy::Response>.

=head1 AUTHOR

Ian Malpass (ian-cpan@indecorous.com)


=head1 COPYRIGHT

Copyright 2009, Ian Malpass

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
