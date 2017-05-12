package WebService::Booklog;

use strict;
use warnings;

# ABSTRACT: Access to unofficial API of booklog.jp
our $VERSION = 'v0.0.1'; # VERSION

use LWP::UserAgent;
use JSON::Any;

sub new
{
	my ($self) = @_;
	my $class = ref $self || $self;
	return bless {
		_UA => LWP::UserAgent->new,
	}, $class;
}

my %status = (
	want_read => 1,
	reading => 2,
	read => 3,
	stacked => 4,
);

sub get_minishelf
{
	my ($self, $account, %arg) = @_;
	my $data = {};
	$data->{status} = $status{lc $arg{status}} if exists $arg{status};
	foreach my $key (qw(category rank count)) {
		$data->{$key} = $arg{$key} if exists $arg{$key};
	}
	my $param = join '&', map { $_.'='.$data->{$_} } keys %$data;
	$param = "?$param" if length $param;
	my $ret = JSON::Any->from_json($self->{_UA}->get('http://api.booklog.jp/json/'.$account.$param)->content);
	$ret->{category} = {} if ref $ret->{category} eq 'ARRAY';
	$ret->{books} = [ grep { ref $_ ne 'ARRAY' } @{$ret->{books}} ];
	return $ret;
}

sub get_review
{
	my ($self, $book_id) = @_;

	my $ret = JSON::Any->from_json($self->{_UA}->get('http://booklog.jp/json/review/'.$book_id)->content);
	return $ret->{$book_id} if exists $ret->{$book_id};
	return;
}

sub get_shelf
{
	my ($self, $account, %arg) = @_;
	my $data = {};
	$data->{status} = $status{lc $arg{status}} if exists $arg{status};
	$data->{category_id} = $arg{category} if exists $arg{category};
	foreach my $key (qw(sort rank tag genre page parpage keyword)) {
		$data->{$key} = $arg{$key} if exists $arg{$key};
	}
	my $param = join '&', map { $_.'='.$data->{$_} } keys %$data;
	my $ret = JSON::Any->from_json($self->{_UA}->get('http://booklog.jp/users_api/'.$account.'?'.$param)->content);
}

# Followings are not yet tested
sub _login
{
	my ($self, $account, $password) = @_;
	my $ret = $self->{_UA}->post('https://booklog.jp/login', { account => $account, password => $password });
}

sub _logout
{
	my ($self) = @_;
	my $ret = $self->{_UA}->get('http://booklog.jp/logout');
}

sub _add_fav
{
	my ($self, $book_id) = @_;
	$self->{_UA}->post('http://booklog.jp/api/review/fav', { book_id => $book_id });
}

sub _del_fav
{
	my ($self, $book_id) = @_;
	$self->{_UA}->post('http://booklog.jp/api/review/fav', { book_id => $book_id, _method => 'delete' });
}

sub _add_follow
{
	my ($self, $account) = @_;
	$self->{_UA}->post('http://booklog.jp/api/follow/add', { account => $account });
}

# status
# read_at_[ymd] (w/o 0 pad) / read_at_null
# rank
# category_id
# description
# public (2: revealer)
# tags
# create_on_[ymdhis] (w/ 0 pad)
# memo
sub _edit_review
{
	my ($self, $service, $id, $args) = @_;
	$args ||= {};
	$args->{_method} = 'edit';
	$self->{_UA}->post("http://booklog.jp/edit/$service/$id", $args);
}

# description
# page
sub _edit_quote
{
	my ($self, $service, $id, $args) = @_;
	$args ||= {};
	$args->{_method} = 'quote';
	$self->{_UA}->post("http://booklog.jp/edit/$service/$id#select_tab2", $args);
}

# read_at_[ymd] (w/o 0 pad)
# rank
# comment
sub _edit_reread
{
	my ($self, $service, $id, $book_id, $args) = @_;
	$args ||= {};
	$args->{_method} = 'reread';
	$args->{book_id} = $book_id;
	$self->{_UA}->post("http://booklog.jp/edit/$service/$id#select_tab2", $args);
}

sub _delete_item
{
	my ($self, $service, $id) = @_;
	my $args = { _method => 'delete' };
	$self->{_UA}->post("http://booklog.jp/edit/$service/$id#select_tab2", $args);
}

sub _sort_all
{
	my ($self, @book_id) = @_;
	my $arg = [map { ('booklist[]', $_) } @book_id];
	$self->{_UA}->post("http://booklog.jp/sort", $arg);
}

sub _set_sort
{
	my ($self, $book_id, $sort) = @_;
	$self->{_UA}->post('http://booklog.jp/sort_edit', { book_id => $book_id, 'sort' => $sort });
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

WebService::Booklog - Access to unofficial API of booklog.jp

=head1 VERSION

version v0.0.1

=head1 SYNOPSIS

  my $obj = WebService::Booklog->new;
  my $dat = $obj->get_minishelf('yak1ex', status => 'read', rank => 5);
  print Data::Dumper->Dump([$dat]);
  
  $dat = $obj->get_review(60694202);
  print $dat,"\n"; # Just a string
  
  $dat = $obj->get_shelf('yak1ex', status => 'read', rank => 5);
  print Data::Dumper->Dump([$dat]);

=head1 DESCRIPTION

This module provides a way to access B<UNOFFICIAL> L<booklog|http://booklog.jp> API.
They are not only B<UNOFFICIAL> but also B<UNDOCUMENTED>.
Thus, it is expected to be quite B<UNSTABLE>. Please use with care.

=head1 METHODS

=head2 C<new>

Constructor. There is no argument.

=head2 C<get_minishelf($account, %params)>

C<$account> is a target account name.
Available keys for C<%params> are as follows:

=over 4

=item C<category>

Category ID dependent on user configuration.

=item C<status>

One of C<'want_read'>, C<'reading'>, C<'read'> and C<'stacked'>. I believe the meanings are intuitive.

=item C<rank>

An integer from 1 to 5 inclusive.

=item C<count>

The number of items. Defaults to 5.

=back

Results are represented as an object like the followings:

  {
    tana => {
      account => $account,
      image_url => $image_url,
      id => $id,
      name => $name,
    },
    category => {
      id => $id,
      name => $name,
    },
    books => [
      {
        title => $title,
        asin => $asin,
        author => $author,
        url => $url,
        image => $image,
        width => $width,
        height => $height,
        catalog => $catalog,
        id => $id,
      },
    ]
  }

From the raw API, C<[]>, empty array ref, is used for empty data.
However, it is replaced as C<{}>, empty hash ref, by this method.

This interface is NOT documented but it is used by a public minishelf widget.
Thus, it is expected to be a bit stabler than others.
However, it is unofficial, too.

=head2 C<get_review($book_id)>

Get the review content of the specified C<$book_id>. C<$book_id> can be get by other interfaces.
Just a scalar string is returned.

=head2 C<get_shelf($account, %arg)>

Get shelf data of the specified $<$account>. Parameters are as follows:

=over 4

=item C<category>

Category ID dependent on user configuration.

=item C<status>

One of C<'want_read'>, C<'reading'>, C<'read'> and C<'stacked'>. I believe the meanings are intuitive.

=item C<rank>

An integer from 1 to 5 inclusive.

=item C<sort>

A string matching C<(release|date|read|title|sort)_(desc|asc)>. C<date> means register date.

=item C<tag>

Tag string

=item C<keyword>

Keyword string

=item C<page>

Page number

=item C<parpage>

Items par page.

=item C<genre>

Any of C<'other'>, C<'book'>, C<'ebook'> (e-book), C<'comic'>, C<'fbook'> (foreign book), C<'magazine'>, C<'movie'>, C<'music'> and C<'game'>.

=back

Results are represented as an object like the followings:

  {"user":
      {"user_id":"<id>",
       "account":"<account>",
       "plan_id":"0",
       "nickname":"<nick>",
       "image_url":"<url>",
       "associateid":"",
       "last_login":"yyyy-mm-dd hh:mm:ss",
       "create_on":"yyyy-mm-dd hh:mm:ss"}
      },
   "login":
       {"user_id":"<id>",
        "account":"<account>",
        "shelf_id":"<shelf_id>",
        "plan_id":"0"
       },
   "genre_id":null,
   "category_id":"0",
   "status":"0",
   "rank":"0",
   "tag":null,
   "keyword":null,
   "sort":"sort_desc",
   "books":[
     {"book_id":"<id>",
      "service_id":"1", // amazon.co.jp
      "id":"<asin>",
      "rank":"0",
      "category_id":"0",
      "public":"1",
      "status":"0",
      "create_on":"yyyy-mm-dd hh:mm:ss",
      "read_at":"yyyy\u5e74mm\u6708dd\u65e5", // or null
      "title":"<title>",
      "title2":"<title2>",
      "image":"<url>",
      "height":<height>,
      "width":<width>,
      "item":
          {"service_id":1, // amazon.co.jp
           "id":"<asin>",
           "url":"<url>",
           "title":"<title>",
           "authors":["<author>"],
           "directors":[],
           "artists":[],
           "actors":[],
           "creators":["<illustrator>"],
           "small_image_url":"<url>",
           "small_image_width":"<width>",
           "small_image_height":"<height>",
           "medium_image_url":"<url>",
           "medium_image_width":"<width>",
           "medium_image_height":"<height>",
           "large_image_url":"<url>",
           "large_image_width":"<width>",
           "large_image_height":"<height>",
           "publisher":"<publisher>",
           "release_date":"yyyy-mm-dd",
           "genre_id":1,
           "price":"\uffe5 <price>",
           "savedPrice":"\uffe5 <price>",
           "EAN":"<EAN>",
           "languages":[],
           "pages":"<pages>",
           "ProductGroup":"<Group>",
           "Binding":"\u6587\u5eab",
           "platform":"",
           "AlternateVersions":[],
           "isAdult":"0",
           "create_on":1365502041
           },
       "tags":[],
       "quotes":[]
     },
   ],
   "reviews":false, // { "<id>":{"more":true,"public":"1","description":""}, ... }
   "comments":[],
   "pager":
       {"base_url":"<url>",
        "query":"",
        "total":"305",
        "start":1,
        "end":25,
        "parpage":"25",
        "page":1,
        "maxpage":13,
        "startpage":1,
        "lastpage":10,
        "prevpage":0,
        "nextpage":2}
     }
  }

Probably, structure of C<$result-E<gt>{books}[n]{item}> depends on serivice provider.
I did not and will not investigate them deeply. If you have some information, please let me know.

=over 4

=item 1

Amazon.co.jp

=item 2

Amazon.com

=item 3

パブー

=item 4

iTunes Store

=item 5

unknown

=item 6

unknown

=item 7

青空文庫

=item 8

BookLive!

=item 9

GALAPAGOS

=item 10

達人出版会

=item 11

O'Reilly Japan

=item 12

unknown

=item 13

技術評論社

=item 14

unknown

=item 15

パブリ

=item 16

honto

=item 17

BOOK☆WALKER

=item 18

ニコニコ静画

=back

=head1 SEE ALSO

=over 4

=item *

L<http://backyard.chocolateboard.net/201204/booklog-jquery> An article for minishelf API

=back

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
