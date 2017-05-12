#
# This file is part of WWW-DaysOfWonder-Memoir44
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package WWW::DaysOfWonder::Memoir44::Url;
# ABSTRACT: encapsulation of days of wonder urls
$WWW::DaysOfWonder::Memoir44::Url::VERSION = '3.000';
use Moose;
use MooseX::Has::Sugar;
use URI;

use overload q{""} => 'as_string';


# -- attributes


has source => ( ro, isa=>'Str', required   );
has _uri   => ( ro, isa=>'URI', lazy_build, handles=>['as_string'] );


# -- initializers & builders

sub _build__uri {
    my $self = shift;
    my $uri  = URI->new;
    $uri->scheme( 'http' );
    $uri->host( 'www.daysofwonder.com' );
    $uri->path( '/memoir44/en/scenario_list/' );

    # canonical url:
    # http://www.daysofwonder.com/memoir44/en/scenario_list/?&start=0&page_limit=2000
    # other valid http options:
    #   status      game = shipped, approved = official, public = non-dow, classified = restricted
    #   selpack_tp  terrain pack
    #   selpack_ef  east front
    #   selpack_pt  pacific theater
    #   selpack_ap  air pack
    #   selpack_mt  mediterranean theater
    #   selpack_bm  battle map
    #   selpack_cb  carnets campagne
    # with values: 0 = undef, 1 = with, 2 = without
    # eg: selpack_tp=1&selpack_ef=2
    my %options = (
        start      => 0,
        page_limit => 5000,
        status     => $self->source,
    );

    $uri->query_form( \%options );
    return $uri;
}


# -- public methods


# handled by _uri attribute


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::DaysOfWonder::Memoir44::Url - encapsulation of days of wonder urls

=head1 VERSION

version 3.000

=head1 SYNOPSIS

    use WWW::DaysOfWonder::Memoir44::Url;
    my $url = WWW::DaysOfWonder::Memoir44::Url->new( { source => 'game' } );
    print $url;

=head1 DESCRIPTION

This module encapsulates urls to fetch scenarios from Days of Wonder.
Depending on various criterias (cf attributes), the url listing the
available scenarios will be different.

=head1 ATTRIBUTES

=head2 $url->source;

The scenarios source. See the C<Source> type in
L<WWW::DaysOfWonder::Memoir44::Types>.

=head1 METHODS

=head2 my $str = $url->as_string;

Stringifies the object in a well-formed url. This is the method called
when the object needs to be stringified by perl due to the context.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
