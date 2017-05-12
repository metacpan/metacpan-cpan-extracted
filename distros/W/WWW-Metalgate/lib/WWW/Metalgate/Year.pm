package WWW::Metalgate::Year;

use warnings;
use strict;

use Moose;
use MooseX::Types::URI qw(Uri FileUri DataUri);
use Encode;
use IO::All;
use Text::Trim;
use Web::Scraper;

=head1 NAME

WWW::Metalgate::Year

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use WWW::Metalgate::Year;
    use XXX;

    my $year   = WWW::Metalgate::Year->new( year => 2003 );
    my @albums = $year->best_albums;
    YYY @albums;
    #---
    #album: EPICA
    #artist: KAMELOT
    #no: 1
    #year: 2003
    #---
    #album: DELIRIUM VEIL
    #artist: TWILIGHTNING
    #no: 2
    #year: 2003
    #---
    #... snip ...

=head1 FUNCTIONS

=head2 uri

=head2 year

=cut

has 'uri'  => (is => 'rw', isa => Uri, coerce  => 1);
has 'year' => (is => 'ro', isa => 'Int', required => 1);
    
with 'WWW::Metalgate::Role::Html';

=head2 BUILD

=cut

sub BUILD {
    my $self = shift;

    # http://www.metalgate.jp/best1992.htm
    $self->uri( sprintf("http://www.metalgate.jp/best%s.htm", $self->year) );
}

=head2 best_albums

=cut

sub best_albums {
    my $self = shift;

    my $album = sub {
        my $node = shift;
        return () unless $node->as_text =~ m/No\.\d+/ and $node->find_by_tag_name('img');

        my ($no, $artist, $album) = ($node->as_text =~ m/No\.(\d+)\s*(.*?)\s*\/\s*(.*?)\s*$/);
        return {
            no          => $no,
            album       => $album,
            artist      => $artist,
            year        => $self->year,
            description => trim( $node->right->right->as_text ),
            #raw        => $node->as_text,
        };
    };
    my $tables = scraper {
        process "table",
            'tables[]' => $album;
    };
    my $data = $tables->scrape( $self->html );

    return @{$data->{tables}};
}

=head2 best_tunes

=cut

sub best_tunes {
    my $self = shift;

    my $tune = sub {
        my $node = shift;
        return () unless $node->as_text =~ m/^No\.\d+/ and !$node->find_by_tag_name('img');

        my ($name, $artist) = split(/\s*\/\s*/, $node->address(".0.1")->as_text);
        my $description = $node->right->as_text || $node->address(".1")->as_text;
        return {
            no          => ($node->address(".0.0")->as_text =~ m/(\d+)/),
            name        => trim($name),
            artist      => trim($artist),
            year        => $self->year,
            description => trim($description),
        };
    };
    my $tables = scraper {
        process "table",
            'tables[]' => $tune;
    };
    my $data = $tables->scrape( $self->html );

    return @{$data->{tables}};
}

=head1 AUTHOR

Tomohiro Hosaka, C<< <bokutin at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Tomohiro Hosaka, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
