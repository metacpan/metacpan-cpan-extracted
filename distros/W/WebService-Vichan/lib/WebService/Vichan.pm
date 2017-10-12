package WebService::Vichan;

use 5.014000;
use strict;
use warnings;
use parent qw/Exporter/;

use HTTP::Tiny;
use Hash::Inflator;
use JSON::MaybeXS;
use Time::HiRes qw/time sleep/;

our $VERSION = '0.001001';

our %cache;
our $last_request = 0;
our $ht = HTTP::Tiny->new(
	agent      => 'WebService-Vichan/'.$VERSION,
	verify_SSL => 1
);

use constant +{
	API_4CHAN => 'https://a.4cdn.org',
	API_8CHAN => 'https://8ch.net',
};

our @EXPORT_OK = qw/API_4CHAN API_8CHAN/;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub new {
	my ($class, $url) = @_;
	bless { url => $url }, $class
}

sub do_request {
	my ($url, $cached_result, $cached_timestamp) = @_;
	my %options;
	if ($cached_timestamp) {
		$options{headers}{'If-Modified-Since'} = $cached_timestamp
	}
	my $time_since_last_request = time - $last_request;
	sleep 1 - $time_since_last_request if $time_since_last_request < 1;
	my $result = $ht->get($url, \%options);
	$last_request = time;
	if ($result->{status} == 304) {
		[$cached_result, $cached_timestamp]
	} elsif (!$result->{success}) {
		my $diestr = sprintf "Error requesting %s: %s\n", $url, $result->{reason};
		die $diestr unless $result->{success};
	} else {
		[$result->{content}, $last_request]
	}
}

sub requestf {
	my ($self, $format, @args) = @_;
	my $what = sprintf $format, @args;
	my $url = $self->{url} . '/' . $what;
	my $result = $cache{$url};
	if (!defined $result) {
		$cache{$url} = do_request $url
	} elsif (time - $result->[1] > 10) {
		$cache{$url} = do_request $url, @$result
	}
	decode_json $cache{$url}->[0]
}

sub boards {
	my ($self) = @_;
	my $result = $self->requestf('boards.json');
	$result = $result->{boards} if ref $result eq 'HASH';
	my @results = map {
		$_->{board} //= $_->{uri};
		Hash::Inflator->new($_)
	  } @$result;
	wantarray ? @results : \@results;
}

sub threads {
	my ($self, $board) = @_;
	$board = $board->{board} if ref $board;
	my $result = $self->requestf('%s/threads.json', $board);
	my @pages = map { Hash::Inflator->new($_) } @$result;
	wantarray ? @pages : \@pages
}

sub threads_flat {
	my @pages = shift->threads(@_);
	my @flat = map { @{$_->{threads}} } @pages;
	wantarray ? @flat : \@flat
}

sub catalog {
	my ($self, $board) = @_;
	$board = $board->{board} if ref $board;
	my $result = $self->requestf('%s/catalog.json', $board);
	my @pages = map { Hash::Inflator->new($_) } @$result;
	wantarray ? @pages : \@pages
}

sub catalog_flat {
	my @pages = shift->catalog(@_);
	my @flat = map { @{$_->{threads}} } @pages;
	wantarray ? @flat : \@flat
}

sub thread {
	my ($self, $board, $threadno, $is_4chan) = @_;
	$board = $board->{board} if ref $board;
	$threadno = $threadno->{no} if ref $threadno;
	$is_4chan //= (index $self->{url}, '4cdn.org') >= 0;
	my $res_or_thread = $is_4chan ? 'thread' : 'res';
	my $result =
	  $self->requestf('%s/%s/%s.json', $board, $res_or_thread, $threadno);
	my @posts = map { Hash::Inflator->new($_) } @{$result->{posts}};
	wantarray ? @posts : \@posts
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::Vichan - API client for 4chan and vichan-based imageboards

=head1 SYNOPSIS

  use WebService::Vichan qw/:all/;
  my $chan = WebService::Vichan->new(API_4CHAN);

  my @boards = $chan->boards;
  say 'Boards on 4chan: ', join ', ', map { $_->board } @boards;

  my @all_pages_of_wsg = $chan->threads('wsg');
  my @wsg = @{$all_pages_of_wsg[0]->threads};
  say 'IDs of threads on the first page of /wsg/: ', join ', ', map { $_->no } @wsg;

  my @all_threads_of_g = $chan->threads_flat('g');
  my @posts_in_23rd_thread = $chan->thread('g', $all_threads_of_g[22]);
  printf "There are %d posts in the 23rd thread of /g/\n", scalar @posts_in_23rd_thread;
  my $the_post = $posts_in_23rd_thread[1];
  say 'HTML of the 2nd post in the 23rd thread of /g/: ', $the_post->com;

=head1 DESCRIPTION

This is an api client for 4chan.org and imageboards that use vichan
(such as 8ch.net). It offers the following methods:

Note: functions that ordinarily return lists will return arrayrefs if
called in scalar context.

=over

=item WebService::Vichan->B<new>(I<$url>)

Creates a new WebService::Vichan object with the given base URL.

Two constants are exported on request by this module: C<API_4CHAN> and
C<API_8CHAN>, which represent the base URLs for 4chan.org and 8ch.net.

=item $chan->B<boards>

Returns a list of available boards. These are blessed
imageboard-dependent hashrefs which should at least have the methods
C<board> (returning the board code as a string) and C<title>.

=item $chan->B<threads>(I<$board>)

Takes a board object (or a board code as a string) and returns a list
of pages of thread OPs. Each page is a blessed hashref with methods
C<page> (the index of the page) and C<threads> (an arrayref of thread
OPs on that page). Each thread OP is a blessed hashref which has at
least the methods C<no> (the thread number) and C<last_modified>.

=item $chan->B<threads_flat>(I<$board>)

Same as B<threads> but page information is dropped. Returns a list of
thread OPs as described above.

=item $chan->B<catalog>(I<$board>)

Same as B<threads>, but much more information is returned about each
thread OP.

=item $chan->B<catalog_flat>(I<$board>)

Same as B<threads_flat>, but much more information is returned about each thread OP.

=item $chan->B<thread>(I<$board>, I<$threadno>, [I<$is_4chan>])

Takes a board object (or a board code as a string), a thread OP object
(or a thread number) and an optional boolean indicating whether to use
4chan logic for the request (by default 4chan logic is used if the URL
contains C<4cdn.org>).

Returns a post object (blessed hashref) with methods as described in
the API documentation (see links in the SEE ALSO section).

=back

To comply with API usage rules every request is cached for 10 seconds,
and requests are rate-limited to one per second. If a method is called
less than 1 second after a request has happened, it will sleep before
issuing a second request to ensure the rate limitation is followed.

=head1 SEE ALSO

L<https://github.com/4chan/4chan-API>,
L<https://github.com/vichan-devel/vichan-API/>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
