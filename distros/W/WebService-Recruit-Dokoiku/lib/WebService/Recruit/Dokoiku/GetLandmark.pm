package WebService::Recruit::Dokoiku::GetLandmark;
use strict;
use base qw( WebService::Recruit::Dokoiku::Base );
use vars qw( $VERSION );
$VERSION = '0.10';

sub url { 'http://api.doko.jp/v1/getLandmark.do'; }
sub force_array { [qw( landmark )]; }
sub elem_class { 'WebService::Recruit::Dokoiku::GetLandmark::Element'; }
sub query_class { 'WebService::Recruit::Dokoiku::GetLandmark::Query'; }

sub query_fields { [qw(
    key format callback pagenum pagesize name code lat_jgd lat_jgd radius iarea
)]; }
sub root_elem { 'results'; }
sub elem_fields { {
    results =>  [qw(
        status totalcount pagenum landmark
    )],
    landmark    =>  [qw(
        code name dokopcurl dokomburl dokomapurl
    )],
}; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::Dokoiku::GetLandmark::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::Dokoiku::GetLandmark::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::Dokoiku::GetLandmark::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::Dokoiku::GetLandmark::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::Dokoiku::GetLandmark::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::Dokoiku::GetLandmark - Dokoiku Web Service Beta "getLandmark" API

=head1 SYNOPSIS

    use WebService::Recruit::Dokoiku;

    my $doko = WebService::Recruit::Dokoiku->new();
    $doko->key( 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' );

    my $param = {
        name    =>  'SHIBUYA109',
    };
    my $res = $doko->getLandmark( %$param );
    die 'error!' if $res->is_error;

    my $list = $res->root->landmark;
    foreach my $landmark ( @$list ) {
        print "code: ", $landmark->code, "\n";
        print "name: ", $landmark->name, "\n";
        print "web:  ", $landmark->dokopcurl, "\n";
        print "map:  ", $landmark->dokomapurl, "\n";
        print "\n";
    }

=head1 DESCRIPTION

This module is a interface for the C<getLandmark> API.
It accepts following query parameters to make an request.

    my $param = {
        pagenum     =>  '1',
        pagesize    =>  '10',
        name        =>  'name of station',
        code        =>  '4254',
        lat_jgd     =>  '35.6686',
        lon_jgd     =>  '139.7593',
        radius      =>  '1000',
        iarea       =>  '05800',
    };
    my $res = $doko->getLandmark( %$param );

C<$doko> above is an instance of L<WebService::Recruit::Dokoiku>.

=head1 METHODS

=head2 root

This returns the root element of the response.

    my $root = $res->root;

You can retrieve each element by the following accessors.

    $root->status;
    $root->totalcount;
    $root->pagenum;
    $root->landmark->[0]->code;
    $root->landmark->[0]->name;
    $root->landmark->[0]->dokopcurl;
    $root->landmark->[0]->dokomburl;
    $root->landmark->[0]->dokomapurl;

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

L<WebService::Recruit::Dokoiku>

=head1 AUTHOR

Yusuke Kawasaki L<http://www.kawa.net/>

This module is unofficial and released by the authour in person.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
1;
