package WebService::Recruit::HotPepper::SmallArea;
use strict;
use base qw( WebService::Recruit::HotPepper::Base );
use vars qw( $VERSION );
$VERSION = '0.02';

sub url { 'http://api.hotpepper.jp/SmallArea/V110'; }
sub force_array { [qw( SmallArea Error )]; }
sub elem_class  { 'WebService::Recruit::HotPepper::SmallArea::Element'; }
sub query_class { 'WebService::Recruit::HotPepper::SmallArea::Query'; }

sub query_fields { [qw(
    key
    SmallAreaName SmallAreaCD MiddleAreaCD
)]; }
sub root_elem { 'Results'; }
sub elem_fields { {
    Results => [qw(
        NumberOfResults APIVersion
        SmallArea
    )],
    SmallArea => [qw(
        SmallAreaCD SmallAreaName MiddleAreaCD
    )],
}; }

# __PACKAGE__->mk_query_accessors();

@WebService::Recruit::HotPepper::SmallArea::Query::ISA = qw( Class::Accessor::Fast );
WebService::Recruit::HotPepper::SmallArea::Query->mk_accessors( @{query_fields()} );

# __PACKAGE__->mk_elem_accessors();

@WebService::Recruit::HotPepper::SmallArea::Element::ISA = qw( Class::Accessor::Children::Fast );
WebService::Recruit::HotPepper::SmallArea::Element->mk_ro_accessors( root_elem() );
WebService::Recruit::HotPepper::SmallArea::Element->mk_child_ro_accessors( %{elem_fields()} );

=head1 NAME

WebService::Recruit::HotPepper::SmallArea - HotPepper Web Service "SmallArea" API

=head1 SYNOPSIS

    use WebService::Recruit::HotPepper;

    my $api = WebService::Recruit::HotPepper->new();
    $api->key( 'xxxxxxxxxxxxxxxx' );

    my $res = $api->SmallArea();
    die 'error!' if $res->is_error;

    my $list = $res->root->SmallArea;
    foreach my $area ( @$list ) {
        print "name:  ", $area->SmallAreaName, "\n";
        print "code:  ", $area->SmallAreaCD, "\n";
        print "\n";
    }

=head1 DESCRIPTION

This module is an interface for the C<SmallArea> API.
It accepts following query parameters to make an request.

    my $res = $hpp->SmallArea();

C<$hpp> above is an instance of L<WebService::Recruit::HotPepper>.

=head1 METHODS

=head2 root

This returns the root element of the response.

    my $root = $res->root;

You can retrieve each element by the following accessors.

    $root->NumberOfResults;
    $root->APIVersion;
    $root->SmallArea->[0]->SmallAreaName;
    $root->SmallArea->[0]->SmallAreaCD;
    $root->SmallArea->[0]->MiddleAreaCD;

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
