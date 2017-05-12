package WebService::Recruit::HotPepper::ShopSearch;
use strict;
use base qw( WebService::Recruit::HotPepper::Base );
use vars qw( $VERSION );
$VERSION = '0.02';

sub url { 'http://api.hotpepper.jp/ShopSearch/V110'; }
sub force_array { [qw( Shop Error )]; }
sub elem_class  { 'WebService::Recruit::HotPepper::ShopSearch::Element'; }
sub query_class { 'WebService::Recruit::HotPepper::ShopSearch::Query'; }

sub query_fields { [qw(
    Keyword ShopTel
    key Start Count
)]; }
sub root_elem { 'Results'; }
sub elem_fields { {
    Results => [qw(
        NumberOfResults DisplayPerPage DisplayFrom APIVersion
        Shop
    )],
    Shop => [qw(
        ShopIdFront ShopNameKana ShopName ShopAddress
        Desc GenreName ShopUrl KtaiShopUrl
    )],
}; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::HotPepper::ShopSearch::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::HotPepper::ShopSearch::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::HotPepper::ShopSearch::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::HotPepper::ShopSearch::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::HotPepper::ShopSearch::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::HotPepper::ShopSearch - HotPepper Web Service "ShopSearch" API

=head1 SYNOPSIS

    use WebService::Recruit::HotPepper;

    my $api = WebService::Recruit::HotPepper->new();
    $api->key( 'xxxxxxxxxxxxxxxx' );

    my $param = {
        Keyword => 'pizza',
    };
    my $res = $api->ShopSearch( %$param );
    die 'error!' if $res->is_error;

    my $list = $res->root->Shop;
    foreach my $shop ( @$list ) {
        print "name:  ", $shop->ShopName, "\n";
        print "addr:  ", $shop->ShopAddress, "\n";
        print "\n";
    }

=head1 DESCRIPTION

This module is an interface for the C<ShopSearch> API.
It accepts following query parameters to make an request.

    my $param = {
        Start       => 1,
        Count       => 10,
        keyword     => 'italian pizza',
        ShopTel     => '0300000000', # without hyphen
        #
        # ...and so on. See
        # http://api.hotpepper.jp/reference.html
        # for a complete list of available params.
    };
    my $res = $hpp->ShopSearch( %$param );

C<$hpp> above is an instance of L<WebService::Recruit::HotPepper>.

=head1 METHODS

=head2 root

This returns the root element of the response.

    my $root = $res->root;

You can retrieve each element by the following accessors.

    $root->NumberOfResults;
    $root->DisplayPerPage;
    $root->DisplayFrom;
    $root->APIVersion;
    $root->Shop->[0]->ShopIdFront;
    $root->Shop->[0]->ShopName;
    $root->Shop->[0]->ShopNameKana;
    $root->Shop->[0]->ShopAddress;
    $root->Shop->[0]->Desc;
    $root->Shop->[0]->GenreName;
    $root->Shop->[0]->ShopUrl;
    $root->Shop->[0]->KtaiShopUrl;

=head2 xml

This returns the raw response context itself.

    print $res->xml, "\n";

=head2 code

This returns the response status code.

    my $code = $res->code; # usually "200" when succeeded

=head2 is_error

This returns true value when the response has an error.

    die 'error!' if $res->is_error;

=head2 page

This returns a L<Data::Page> instance.

    my $page = $res->page();
    print "Total: ", $page->total_entries, "\n";
    print "Page: ", $page->current_page, "\n";
    print "Last: ", $page->last_page, "\n";

=head2 pageset

This returns a L<Data::Pageset> instance.

    my $pageset = $res->pageset( 'fixed' );
    $pageset->pages_per_set($pages_per_set);
    my $set = $pageset->pages_in_set();
    foreach my $num ( @$set ) {
        print "$num ";
    }

=head2 page_param

This returns a hash to specify the page for the next request.

    my %hash = $res->page_param( $page->next_page );

=head2 page_query

This returns a query string to specify the page for the next request.

    my $query = $res->page_query( $page->prev_page );

=head1 SEE ALSO

L<WebService::Recruit::HotPepper>

=head1 AUTHOR

Toshimasa Ishibashi L<http://iandeth.dyndns.org/>

This module is unofficial and released by the author in person.

=head1 THANKS TO

Yusuke Kawasaki L<http://www.kawa.net/>

For creating/preparing all the base modules and stuff.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Toshimasa Ishibashi. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
