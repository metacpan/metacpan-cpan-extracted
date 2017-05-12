package WebService::KakakuCom;
use strict;
use warnings;
use base qw/Class::Accessor::Fast Class::Data::Inheritable/;

use URI;
use Carp;
use Readonly;
use LWP::UserAgent;
use Jcode;
use WebService::KakakuCom::Parser;
use Data::Page;

Readonly my $ApiRoot => 'http://api.kakaku.com/Ver1/';
Readonly my $EntriesPerPage => 5;

our $VERSION = 0.05;

__PACKAGE__->mk_accessors(qw/ie/);
__PACKAGE__->mk_classdata($_) for qw/debug/;

sub ua {
    my $self = shift;
    if (@_) {
        $self->{ua} = shift;
    } else {
        $self->{ua} and return $self->{ua};
        $self->{ua} = LWP::UserAgent->new;
        $self->{ua}->agent(join '/', __PACKAGE__, $self->VERSION);
    }
    $self->{ua};
}

sub search {
    my ($self, $keyword, $args) = @_;
    defined $keyword or croak "No keyword was given";
    $args ||= {};

    my $uri = URI->new_abs('ItemSearch.asp', $ApiRoot);
    $uri->query_form(
        Keyword       => Jcode->new($keyword, $self->ie)->sjis,
        CategoryGroup => $args->{CategoryGroup} || 'ALL',
        ResultSet     => $args->{ResultSet} || 'medium',
        SortOrder     => $args->{SortOrder} || '',
        PageNum       => $args->{PageNum} || 1,
    );

    my $res = $self->ua->get($uri);
    croak $res->status_line if $res->is_error;

    my $rs = WebService::KakakuCom::Parser->parse_for_search($res->content);
    $rs->pager(Data::Page->new($rs->NumOfResult, $EntriesPerPage, $args->{PageNum} || 1));

    wantarray ? @$rs : $rs;
}

sub product {
    my ($self, $product_id, $args) = @_;
    defined $product_id or croak "No ProductID was given";
    $args ||= {};

    my $uri = URI->new_abs('ItemInfo.ashx', $ApiRoot);
    $uri->query_form(
        ProductID => $product_id,
        ResultSet => $args->{ResultSet} || 'medium'
    );

    my $res = $self->ua->get($uri);
    croak $res->status_line if $res->is_error;

    WebService::KakakuCom::Parser->parse_for_product($res->content);
}

1;

__END__

=head1 NAME

WebService::KakakuCom - Handle WebAPI of kakaku.com.

=head1 SYNOPSIS

    use WebService::KakakuCom;

    my $api = WebService::KakakuCom->new;

    my @results = $api->search('VAIO');
    print $_->ProductName, "\n" for @results;

    $api->debug(1);
    $api->ie('utf8'); # for icode of Jcode
    my $rs = $api->search(
        'VAIO',
        { CategoryGroup => 'Pc', SortOrder => 'daterank', PageNum => 2 }
    );
    for (@$rs) {
        print $_->ProductID;
        print $_->ProductName;
        print $_->CategoryName;
        print $_->MakerName;
        print $_->ImageUrl;
        print $_->ItemPageUrl;
        print $_->BbsPageUrl;
        print $_->ReviewPageUrl;
        print $_->LowestPrice;
        print $_->NumOfBbs;
        print $_->ReviewRating;
    }

    my $pager = $rs->pager; # Data::Page
    print $pager->total_entries;
    print $pager->entries_on_this_page;
    ...

    my $product = $api->product($ProductID);
    print $product->ProductID, "\n";
    ...

=head1 DESCRIPTION

This module allows you to handle WebAPI of kakaku.com easily.

Kakaku.com (http://kakaku.com/) is a price comparison sites in
Japan. You can search/retrieve arbitrary product informations via its
own WebAPI. Please refer to http://apiblog.kakaku.com/ for
details. (in Japanese)

=head1 FUNCTIONS

=head2 new()

Returns an instance of this module. You must create an instance before
searching.

=head2 ua()

Returns an User-Agent instance for customizing an User-Agent string,
timeout values, something like that.

=head2 search($keyword, \%options)

Returns search results as a result set. The result set contains
WebService::KakakuCom::Product objects and it will be available as an
array in list context or as a WebService::KakakuCom::ResultSet object
in scalar context.

  my $api = WebService::KakakuCom->new;
  my @results = $api->search('Vaio');
  my $rs = $api->search('Vaio');

A ResultSet object can also be used as an array and it has some
special methods like C<pager()>.

  for my $product (@$rs) {
     ...
  }
  my $pager = $rs->pager;  # an instance of Data::Page

All the informations you want can be retrieve from Product objects in
a result set.

  for my $product (@results) {
      print $_->ProductID;
      print $_->ProductName;
      print $_->CategoryName;
      print $_->MakerName;
      print $_->LowestPrice;
      print $_->NumOfBbs;
      print $_->ReviewRating;

      # These values are wrapped in URI.
      print $_->ImageUrl
      print $_->ItemPageUrl;
      print $_->BbsPageUrl;
      print $_->ReviewPageUrl;
  }

You can specify options of search query like PageNum / SortOrder to
the second argument of this method as hash reference. See the official
API documents about detail of those options.

  my $rs = $api->search(
      'Vaio',
      { PageNum => 1, SortOrder => 'popularityrank' }
  );

=head2 product($ProductID)

Returns an object of product by ProductID. An retrieved object is a
WebService::KakakuCom::Product same as used in C<search()>.

=head2 ie($icode)

In the API of kakaku.com, a character set of multi byte characters
must be Shift-JIS. So this module convert querie's charcter
set to Shift-JIS by using L<Jcode> internally.

If there is no information about an input code, it will be guessed
automatically but may be failed. It's better that you set your
character set of queries with this method.

C<$icode> can be any encoding name that L<Encode> understands.

=head2 debug($bool)

Turn on/off the debug switch. Currently it only dump the data
contained in a result set.

=head1 WARNING

This module is in beta version. Object interface it provides may be
changed later.

=head1 AUTHOR

Naoya Ito, C<< <naoya at bloghackers.net> >>

=head1 SEE ALSO

=over 4

=item * http://apiblog.kakaku.com/KakakuItemSearchV1.0.html

=item * http://apiblog.kakaku.com/KakakuItemInfoV1.0.html

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Naoya Ito, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
