package WebService::Yes24;
our $VERSION = '0.100980';
use 5.010;
use Moose;
use Moose::Util::TypeConstraints;
# ENCODING: utf-8
# ABSTRACT: Yes24 Web Service API Module

use namespace::autoclean;
use Encode qw( encode decode );
use LWP::Simple;
use URI::Escape;
use URI;
use Web::Scraper;


use common::sense;
use WebService::Yes24::Item;


has 'category' => (
    isa     => enum([qw/
        all
        korean-book
        foreign-book
    /]),
    is      => 'rw',
    default => 'all',
);


has 'page_size' => (
    isa     => enum([
        20,
        40,
        60,
    ]),
    is      => 'rw',
    default => 20,
);


subtype 'PageNumber'
    => as 'Int'
    => where { $_ >= 1 }
    => message { "Page number must be >= 1." };

has 'page' => (
    isa     => 'PageNumber',
    is      => 'rw',
    default => 1,
);


has 'sort' => (
    isa     => enum([qw/
        accuracy
        sales
        date
        recommendation
        review
        score
        coupon
        low-price
        high-price
        event
        gift
    /]),
    is      => 'rw',
    default => 'accuracy',
);


has 'sold_out' => (
    isa     => 'Bool',
    is      => 'rw',
    default => 1,
);


has 'query_type' => (
    isa     => enum([qw/
        normal
        author
        publisher
        keyword
        isbn
    /]),
    is      => 'rw',
    default => 'normal',
);

#
# Just private attribute
#
has '_query' => (
    isa => 'Str',
    is  => 'rw',
);


sub _get_page {
    my $self = shift;

    $LWP::Simple::ua->agent("Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 6.0)");

    my $content = get( $self->_query_url );

    return $content;
}


sub search {
    my ( $self, $query ) = @_;

    $self->_query( $query );

    my $content = $self->_get_page;
    return 0 unless defined $content;
    return 0 unless $content =~ m{\((\d+)-(\d+) / <strong>(\d+)건</strong>\)};

    my $start = $1;
    my $end   = $2;
    my $total = $3;

    return $total;
}


sub result {
    my ( $self, $page ) = @_;

    $self->page( $page ) if $page > 0;

    my $scraper = scraper {
        process 'table#tblProductList > tr', 'items[]' => scraper {
            process 'td > table > tr > td > a > img', 'cover'   => '@src';
            process 'td > a > b',                     title     => 'TEXT';
            process 'td > a',                         link      => '@href';
            process 'span.info',                      sub_title => 'TEXT';
            process 'span.priceB',                    price     => 'TEXT';
            process 'span.price',                     mileage   => 'TEXT';

            process 'span.txtAp', info      => sub {
                my $elem = shift;

                my @infos = map {
                    s/^\s*|\s*$//;
                    $_;
                } split(/\|/, $elem->as_text);

                return {
                    author    => $infos[0],
                    publisher => $infos[1],
                    date      => $infos[2],
                };
            };
        };
    };

    my $res = $scraper->scrape( URI->new( $self->_query_url ) );

    my @results;
    for my $item ( @{ $res->{items} } ) {
        next unless $item->{title};
        next unless $item->{link};

        map {
            s/^\s+|\s+$//g
        } (
            $item->{title},
            $item->{cover},
            $item->{sub_title},
            $item->{info}{author},
            $item->{info}{publisher},
            $item->{info}{date},
            $item->{price},
            $item->{mileage},
        );

        $item->{price}      =~ s/\D//g;
        $item->{mileage}    =~ s/\D//g;
        $item->{info}{date} =~ s/^.*?(\d{4})\D+(\d{2}).*$/sprintf('%04d-%02d', $1, $2)/ge;

        my $title = join( q{ }, $item->{title}, $item->{sub_title} );

        my $result_item = WebService::Yes24::Item->new(
            title     => $title,
            cover     => $item->{cover}->as_string,
            author    => $item->{info}{author},
            publisher => $item->{info}{publisher},
            date      => $item->{info}{date},
            price     => $item->{price},
            mileage   => $item->{mileage},
            link      => $item->{link}->as_string,
        );

        push @results, $result_item;
    }

    return \@results;
}

sub _query_url {
    my $self = shift;

    my $gcode     = 'Gcode=000_004_001';
    my $page_size = 'fetchsize=' . $self->page_size;
    my $page      = 'Page='      . $self->page;
    my $sold_out  = 'statgb='    . ( $self->sold_out ? q{} : '01' );

    my $category = 'qdomain=';
    given ( $self->category ) {
        when ("all")          { $category .= '%C0%FC%C3%BC'; }
        when ("korean-book")  { $category .= '%B1%B9%B3%BB%B5%B5%BC%AD'; }
        when ("foreign-book") { $category .= '%BF%DC%B1%B9%B5%B5%BC%AD'; }
    }

    my $sort = 'qsort=';
    given ( $self->sort ) {
        when ('accuracy')       { $sort .= 1; }
        when ('sales')          { $sort .= 2; }
        when ('date')           { $sort .= 3; }
        when ('recommendation') { $sort .= 4; }
        when ('review')         { $sort .= 5; }
        when ('score')          { $sort .= 6; }
        when ('coupon')         { $sort .= 7; }
        when ('low-price')      { $sort .= 8; }
        when ('high-price')     { $sort .= 9; }
        when ('event')          { $sort .= 10; }
        when ('gift')           { $sort .= 11; }
    }

    my $query_type;
    given ( $self->query_type ) {
        when ('normal')    { $query_type = 'query='    }
        when ('author')    { $query_type = 'qauthor='  }
        when ('publisher') { $query_type = 'qcompany=' }
        when ('keyword')   { $query_type = 'qkeyword=' }
        when ('isbn')      { $query_type = 'qisbn='    }
    }
    $query_type .= uri_escape( encode('cp949', decode('utf-8', $self->_query)) );

    return join(
        '?',
        'http://www.yes24.com/searchCenter/searchResult.aspx',
        join(
            '&',
            $gcode,
            $page_size,
            $page,
            $sold_out,
            $category,
            $sort,
            $query_type,
        ),
    );
}

__PACKAGE__->meta->make_immutable;
no Moose::Util::TypeConstraints;
no Moose;
1;

__END__
=pod

=encoding utf-8

=head1 NAME

WebService::Yes24 - Yes24 Web Service API Module

=head1 VERSION

version 0.100980

=head1 SYNOPSIS

    use 5.010;
    use WebService::Yes24;
    
    my $yes24 = WebService::Yes24->new;
    $yes24->search( "Learning Perl" );
    for my $item ( @{ $yes24->result } ) {
        say $item->{title};
        say $item->{cover};
        say $item->{author};
        say $item->{publisher};
        say $item->{date};
        say $item->{price};
        say $item->{mileage};
        say $item->{link};
    }
    
    my $total = $yes24->search( "Learning Perl" );
    my $last_page = ($total / $yes24->page_size) + 1;
    for my $page ( 1 .. $last_page ) {
        for my $result ( @{ $yes24->result($page) } ) {
            say $item->{title};
            say $item->{cover};
            say $item->{author};
            say $item->{publisher};
            say $item->{date};
            say $item->{price};
            say $item->{mileage};
            say $item->{link};
        }
    }

=head1 DESCRIPTION

Yes24 (L<http://www.yes24.com>) is a e-commerce company in South Korea.
They mainly sell books, CD/DVDs, gifts and etc like Amazon.
This module provides APIs to get information from Yes24.

=head1 CAUTION

In fact, Yes24 doesn't support API.
So, implementation of this module is based on the web scraping,
which is the very fragile approach and very slow.
Please remember, one day this module might not work!
If you find the such situation, let me know. :-)

=head1 ATTRIBUTES

=head2 category

This attribute stores the category.
The available categories are "all", "korean-book" and "foreign-book".
The default value is "all".

=head2 page_size

This attribute stores the page size.
The available page sizes are 20, 40 and 60.
The default value is 20.

=head2 page

This attribute stores the page number.
The minimum page number is 1.
The default value is 1.

=head2 sort

This attribute stores the sort type.
The available sort types are listed below:

    - accuracy
    - sales
    - date
    - recommendation
    - review
    - score
    - coupon
    - low-price
    - high-price
    - event
    - gift

The default values is 'accuracy'.

=head2 sold_out

This attribute stores the boolean value
of the availability of sold out products.
If this value is set, search result contains the sold out products.
The default value is true.

=head2 query_type

This attribute stores the query type.
The available query types are listed below:

    - normal
    - author
    - publisher
    - keyword
    - isbn

The default value is 'normal'.

=head1 METHODS

=head2 new

    my $yes24 = WebService::Yes24->new;

This method will create and return L<WebService::Yes24> object.

If any parameter was not given, the default values are used:

    # Same as the above code
    my $yes24 = WebService::Yes24->new(
        category   => 'all',
        page_size  => 20,
        page       => 1,
        sort       => 'accuracy',
        sold_out   => 1,
        query_type => 'normal',
    );

=head2 search

    my $total = $yes24->search('Learning Perl');

This method will start search from Yes24.
You have to specify the search keyword as the parameter.
It returns total items of the search result.

=head2 result

    my @items = @{ $yes24->result };

This method will return the items of the search result.

You can set the page number.

    my $page_number = 2;
    my @items_2 = @{ $yes24->result($page_number) };

If the page number is omitted, then $self->page is used.
Above code is same as below:

    my $page_number = 2;
    $yes24->page($page_number);
    my @items_2 = @{ $yes24->result };

=head1 AUTHOR

  Keedi Kim - 김도형 <keedi at cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

