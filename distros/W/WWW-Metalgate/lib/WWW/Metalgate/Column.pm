package WWW::Metalgate::Column;

use warnings;
use strict;

use Moose;
use MooseX::Types::URI qw(Uri FileUri DataUri);
use Web::Scraper;
use WWW::Metalgate::Year;

=head1 NAME

WWW::Metalgate::Column

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use WWW::Metalgate::Column;
    use XXX;

    my @years = WWW::Metalgate::Column->new->years;
    warn 0+@years; # 16
    YYY @years;
    #--- !!perl/hash:WWW::Metalgate::Year
    #uri: !!perl/scalar:URI::http http://www.metalgate.jp/best1992.htm
    #year: 1992
    #--- !!perl/hash:WWW::Metalgate::Year
    #uri: !!perl/scalar:URI::http http://www.metalgate.jp/best1993.htm
    #year: 1993
    #... snip ...

=head1 FUNCTIONS

=cut

=head2 uri

=cut

has 'uri' => (is => 'rw', isa => Uri, coerce  => 1, default => "http://www.metalgate.jp/column.htm");

with 'WWW::Metalgate::Role::Html';

=head2 years

=cut

sub years {
    my $self = shift;

    my $year = scraper {
        process 'a',
            url => '@href';
    };

    my $years = scraper {
        process 'td>a',
            'years[]' => $year;
    };

    my $data  = $years->scrape( $self->html );
    my @years = map { $_->{url} =~ m/best(\d{4})/ } (@{$data->{years}});
    my @objs  = map { WWW::Metalgate::Year->new( year => $_ ) } sort @years;

    return @objs;
}

=head1 AUTHOR

Tomohiro Hosaka, C<< <bokutin at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Tomohiro Hosaka, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
