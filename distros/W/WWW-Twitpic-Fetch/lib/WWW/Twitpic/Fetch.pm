package WWW::Twitpic::Fetch;
use Moose;
use LWP::UserAgent;
use Web::Scraper;
use URI;
use Carp;
use List::MoreUtils qw/each_array/;
use Text::Trim;
use Encode;
use utf8;

=head1 NAME

WWW::Twitpic::Fetch - Moose-based information scraper/fetcher for Twitpic

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';


=head1 SYNOPSIS

  use WWW::Twitpic::Fetch;
  
  my $twitpic = WWW::Twitpic::Fetch->new();
  my $list = $twitpic->list($username, $page);
  my $photoinfo = $twitpic->photo_info($list->[0]{id}, 0);
  ...

=head1 ATTRIBUTES

attributes can be specified by parameter of C<new> like

  WWW::Twitpic::Fetch->new(
    ua => $my_ua
  );

=head2 ua

LWP::UserAgent compatible UserAgent object.
default is an instance of LWP::UserAgent.

=head2 username

username for twitter (and also twitpic).
B<UNUSED for this version>

=head2 password

password for twitter (and also twitpic).
B<UNUSED for this version>

=cut

has ua => (
  is => q/rw/,
  isa => q/Ref/,
  default => sub {
    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    $ua;
  },
);

has username => (
  is => q/ro/,
  isa => q/Str/,
  #required => 1,
);

has password => (
  is => q/ro/,
  isa => q/Str/,
  #required => 1,
);

# private attributes

has _list_scraper => (
  is => q/ro/,
  lazy => 1,
  default => sub {
    scraper {
      process 'div.user-photo>a' => 'id[]' => '@href';
      process 'div.user-photo>a>img' => 'thumb[]' => '@src';
      process 'div.user-tweet>p.' => 'message[]' => 'TEXT';
    };
  },
);

has _photo_full_scraper => (
  is => q/ro/,
  lazy => 1,
  default => sub {
    scraper {
      process 'body>img' => 'url' => '@src';
    };
  },
);

has _photo_scaled_scraper => (
  is => q/ro/,
  lazy => 1,
  default => sub {
    my $each_comment = scraper {
      process 'div.photo-comment-info>a' => 'username' => 'TEXT';
      process 'div.photo-comment-info>span.photo-comment-date' => 'date' => 'TEXT';
      process 'div.photo-comment-message' => 'comment' => 'TEXT';
      process 'div.photo-comment-avatar>img' => 'avatar' => '@src';
    };
    scraper {
      process 'img#photo-display' => 'url' => '@src';
      process 'div#view-photo-views>div' => 'views' => 'TEXT';
      process 'div#view-photo-caption' => 'message' => 'TEXT';
      process 'div.photo-comment' => 'comments[]' => $each_comment;
			process 'div#view-photo-tags>span>a.nav-link' => 'tags[]' => 'TEXT';
    };
  },
);

has _public_timeline_scraper => (
  is => q/ro/,
  lazy => 1,
  default => sub {
    my $each = scraper {
      process 'img.avatar' => 'avatar' => '@src';
      process 'a.nav' => 'username' => 'TEXT';
      process 'td>div>a' => 'id[]' => '@href';
      process 'td>div' => 'message[]' => 'TEXT';
      process 'div>a>img' => 'mini' => '@src';
    };
    scraper {
      process 'div.comment>table>tr' => 'photos[]' => $each;
    };
  },
);

has _tagged_scraper => (
	is => q/ro/,
	lazy => 1,
	default => sub {
		my $each = scraper {
			process '.' => 'id' => ['@href', sub { s{^/}{}; $_ } ];
			process 'img' => 'mini' => '@src';
		};
		scraper {
			process 'div#tagged-photos>div>a' => 'tagged[]' => $each;
		};
	},
);

=head1 FUNCTIONS

=head2 list I<username> [, I<page>] 

get list of photo informations for I<username>.

returns arrayref of hashref containing following keys
C<'id'>, C<'message'>, C<'thumb'> when success.
(C<'id'> is a photo id, and C<'thumb'> is for url of thumbnail image of photo)

returns undef if failed to fetch list.

=over 1

=item I<username> (required)

specifies whose photo list.

=item I<page>

specifies page of list. can be omitted. (default = 1) 

=back

=cut

sub list
{
  my ($self, $username, $page) = @_;
  croak "invalid username: @{[$username?$username:'']}" if !$username || $username !~ m{^[[:alnum:]_]+$};
  $page += 0 if $page;
  $page = 1 if !defined $page || $page < 1;

  my $ua = $self->ua;

  my $uri = URI->new('http://twitpic.com/photos/'.$username);
  if ( $page > 1 ) {
    $uri->query_form(page => $page);
  }
  my $res = $ua->get($uri);
  if ( !$res->is_success ) {
    return undef;
  }

  my $sres = $self->_list_scraper->scrape(decode_utf8($res->content));

  my ($ids, $messages, $thumbs) = map { $sres->{$_} } qw/id message thumb/;

	return [] if !($ids && $messages && $thumbs);

  warn 'mismatch found for photo ids and messages. return value may be wrong'
  if !(scalar @$ids == scalar @$messages && scalar @$ids == scalar @$thumbs);

  $_ =~ s#^/## for @$ids;
  trim for @$messages;

  my $ea = each_array(@$ids, @$messages, @$thumbs);
  my @list;
  while (my ($id, $message, $thumb) = $ea->() ) {
    push @list, +{ id => $id, message => $message, thumb => $thumb };
  }

  \@list;
}

=head2 photo_info I<photo ID or URL of photo page> [, I<full?>]

get informations of photo file.

returns hashref containing following keys ..

C<'url'>, C<'message'>, C<'comments'>, C<'views'> and C<'tags'> for scaled.

just C<'url'> for fullsize.

return undef if failed to fetch.

=over 1

=item I<photo ID or url of photo page> (required)

photo id. you can get photo id by list() or public_timeline().

or you can just pass an url of certain photo page.

=item I<full?>

FALSE for scaled photo. TRUE for full-size photo.
(default = FALSE).

=back

=cut

sub photo_info {
  my ($self, $id, $full) = @_;

  if ( $id && $id =~ m{http://(?:www\.)?twitpic\.com/([[:alnum:]]+)} ) {
    $id = $1;
  }
  elsif ( !$id || $id !~ m{^[[:alnum:]]+$} ) {
    croak "invalid photo id: @{[$id?$id:'']}";
  }

  my $url = URI->new('http://twitpic.com/' . $id . ($full ? '/full' : ''));
  my $res = $self->ua->get($url);

  return undef if !$res->is_success;

  my $sres =
  ($full ? $self->_photo_full_scraper : $self->_photo_scaled_scraper)
  ->scrape(decode_utf8($res->content));
  return undef if !$sres;

  if ( $full ) {
    return $sres;
  }

  $sres->{views} =~ s/[^\d]*(\d+).*/$1/;
  trim $sres->{message};
  trim $_->{comment} for @{$sres->{comments}};
	$sres->{tags} = [] if !exists $sres->{tags};

  $sres;
}

=head2 public_timeline

get information of photos on public_timeline

returns arrayref of hashref containing following.
C<'avatar'>, C<'username'>, C<'mini'> and C<'message'> ('mini' is for mini-thumbnail).

returns undef if failed to fetch

=cut

sub public_timeline
{
  my ($self) = @_;

  my $res = $self->ua->get('http://twitpic.com/public_timeline/');
  return undef if !$res->is_success;

  my $sres = $self->_public_timeline_scraper->scrape(decode_utf8($res->content));
  return undef if !$sres;

  for (@{$sres->{photos}}) {
    $_->{id} = pop @{$_->{id}};
    $_->{message} = pop @{$_->{message}};

    $_->{id} =~ s#^/##;
    trim $_->{message};
  }

  $sres->{photos};
}

=head2 tagged I<tag name>

get list of photos that tagged certain name.

returns arrayref of hashref containing following keys,
C<'id'>, C<'mini'>

=over 1

=item I<tag name>

=back

=cut

sub tagged
{
	my ($self, $tagname) = @_;

	croak "invalid tag name @{[$tagname?$tagname:'']}" if !$tagname;

	my $url = URI->new('http://twitpic.com/tag/' . $tagname);
	my $res = $self->ua->get($url);

	return undef if !$res->is_success;

	my $sres = $self->_tagged_scraper->scrape($res->content);

	my $ret = $sres->{tagged};

	$_->{id} =~ s{^/}{} for @$ret;

	$ret;
}

=head1 SEEALSO

L<http://twitpic.com/> - Twitpic web site

L<WWW::Twitpic> - Diego Kuperman's Twitpic API client

=head1 AUTHOR

turugina, C<< <turugina at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-twitpic-fetch at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Twitpic-Fetch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Twitpic::Fetch


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Twitpic-Fetch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Twitpic-Fetch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Twitpic-Fetch>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Twitpic-Fetch/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 turugina, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of WWW::Twitpic::Fetch
