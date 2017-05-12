package WWW::Hashdb;

use warnings;
use strict;

use Moose;
use Params::Validate;
use WWW::Mechanize;
use Web::Scraper;

=head1 NAME

WWW::Hashdb - search by http://hashdb.com/.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use WWW::Hashdb;
    use XXX;

    my $hashdb = WWW::Hashdb->new( limit => 10 );
    my @items  = $hashdb->search("BURST CITY");
    XXX @items;

=head1 EXPORT

none.

=head1 FUNCTIONS

=head2 limit

=cut

has 'limit' => ( is => 'rw', isa => 'Int', default => 10 );

=head2 search

=cut

sub search {
    my ($self, $word) = validate_pos(@_, 1, 1);

    # http://hashdb.com/search.php?q=SYMPHONY+X&p=1&s=u
    # q = query, words
    # p = page
    # s = ???

    my @items;

    {
        my @pages = do {
            my $first = URI->new("http://hashdb.com/search.php");
            $first->query_form( { q => $word, p => 1 } );
            $first;
        };

        #warn $uri->as_string;
        my $item = scraper {
            process "p.searchList";
            process 'input', ignore => '@value';
        };
        my $lists = scraper {
            # <a href="search.php?q=aho&amp;p=2&amp;s=u" title="次のページへ" accesskey="N">次へ(<span class="underline">N</span>)</a>

            process 'a[accesskey="N"]',
                "next"    => '@href';
            process 'form[name="download"]>p',
                "items[]" => $item;
            #result 'items';
        };

        while (my $uri = shift @pages) {
            my $items_ref = $lists->scrape( $uri );

            push @items, @{$items_ref->{items} || []};

            last if $self->limit > 0 and @items >= $self->limit;
            push @pages, $items_ref->{next};
        }
    }

    for my $item (@items) {
        my @parts = split(/,/, $item->{ignore});
        # 先頭のフィールド「名前」には「,」がデリミタとしてではなく表れる場合がある。
        until (@parts == 8) {
            $parts[0] = join(',', @parts[0 .. 1]);
            splice(@parts, 1, 1);
        }

        # （アニメ）[ラストエグザイル LASTEXILE] (OP) Cloud Age Symphony.mp3,kzELjn4dD0,0,0,6d3d7136e9a7753108aa44e4a20526b7,0,1,0
        $item->{name}  = $parts[0];
        $item->{trip}  = $parts[1];
        $item->{hash}  = $parts[4];
        $item->{fetch} = $item->{hash} ? join(",", "", "", 0, 0, $item->{hash}, 0) : undef;
    }

    return @items;
}

=head1 AUTHOR

Tomohiro Hosaka, C<< <bokutin at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Tomohiro Hosaka, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
