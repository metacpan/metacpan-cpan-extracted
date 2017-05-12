package WebService::Recruit::Jalan::AreaSearch;
use strict;
use vars qw( $VERSION );
use base qw( WebService::Recruit::Jalan::Base );
$VERSION = '0.10';

sub url { 'http://jws.jalan.net/APICommon/AreaSearch/V1/'; }

sub query_class { 'WebService::Recruit::Jalan::AreaSearch::Query'; }
sub query_fields { [qw(
    key reg pref l_area
)]; }
sub notnull_param { [qw( key )]; }

sub elem_class { 'WebService::Recruit::Jalan::AreaSearch::Element'; }
sub root_elem { 'Results'; }
sub elem_fields { {
    Results => [qw(
        APIVersion Area
    )],
    Area => [qw(
        Region
    )],
    Region => [qw(
        cd name Prefecture
    )],
    Prefecture => [qw(
        cd name LargeArea
    )],
    LargeArea => [qw(
        cd name SmallArea
    )],
    SmallArea => [qw(
        cd name
    )],
}; }
sub force_array { [qw( Region Prefecture LargeArea SmallArea )]; }


sub total_entries { 1 }     # dummy (override)
sub entries_per_page { 1 }
sub current_page { 1 }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::Jalan::AreaSearch::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::Jalan::AreaSearch::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::Jalan::AreaSearch::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::Jalan::AreaSearch::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::Jalan::AreaSearch::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::Jalan::AreaSearch - Jalan Web Service "AreaSearch" API

=head1 SYNOPSIS

    use WebService::Recruit::Jalan;

    my $jalan = WebService::Recruit::Jalan->new();
    $jalan->key( 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' );

    my $param = {
        reg     =>  '15',
    };
    my $res = $jalan->AreaSearch( %$param );
    die "error!" if $res->is_error;

    my $list = $res->root->Area->Region;
    foreach my $reg ( @$list ) {
        print $reg->cd, "\t# ",  $reg->name, "\n";
        foreach my $pref ( @{ $reg->Prefecture } ) {
            print $pref->cd, "\t  * ",  $pref->name, "\n";
            foreach my $large ( @{ $pref->LargeArea } ) {
                print $large->cd, "\t    + ",  $large->name, "\n";
                foreach my $small ( @{ $large->SmallArea } ) {
                    print $small->cd, "\t      - ",  $small->name, "\n";
                }
            }
        }
    }

=head1 DESCRIPTION

This module is a interface for the C<AreaSearch> API.
It accepts following query parameters to make an request.

    my $param = {
        reg         =>  '10'
        pref        =>  '130000'
        l_area      =>  '136200'
    };

C<$jalan> above is an instance of L<WebService::Recruit::Jalan>.

=head1 METHODS

=head2 root

This returns the root element of the response.

    my $root = $res->root;

You can retrieve each element by the following accessors.

    $root->APIVersion;
    $root->Area;
    $root->Area->Region;
    $root->Area->Region->[0]->cd;
    $root->Area->Region->[0]->name;
    $root->Area->Region->[0]->Prefecture;
    $root->Area->Region->[0]->Prefecture->[0]->cd;
    $root->Area->Region->[0]->Prefecture->[0]->name;
    $root->Area->Region->[0]->Prefecture->[0]->LargeArea;
    $root->Area->Region->[0]->Prefecture->[0]->LargeArea->[0]->cd;
    $root->Area->Region->[0]->Prefecture->[0]->LargeArea->[0]->name;
    $root->Area->Region->[0]->Prefecture->[0]->LargeArea->[0]->SmallArea;
    $root->Area->Region->[0]->Prefecture->[0]->LargeArea->[0]->SmallArea->[0]->cd;
    $root->Area->Region->[0]->Prefecture->[0]->LargeArea->[0]->SmallArea->[0]->name;

=head2 xml

This returns the raw response context itself.

    print $res->xml, "\n";

=head2 code

This returns the response status code.

    my $code = $res->code; # usually "200" when succeeded

=head2 is_error

This returns true value when the response has an error.

    die 'error!' if $res->is_error;

=head1 SEE ALSO

L<WebService::Recruit::Jalan>

=head1 AUTHOR

Yusuke Kawasaki L<http://www.kawa.net/>

This module is unofficial and released by the author in person.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
1;
