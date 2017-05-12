package WebService::HackerNews;
$WebService::HackerNews::VERSION = '0.05';
use 5.006;
use Moo;
use JSON qw(decode_json);

use WebService::HackerNews::Item;
use WebService::HackerNews::User;

has ua => (
    is => 'ro',
    default => sub {
        require HTTP::Tiny;
        require IO::Socket::SSL;
        HTTP::Tiny->new;
    },
);

has base_url => (
    is      => 'ro',
    default => sub { 'https://hacker-news.firebaseio.com/v0' },
);

my $get = sub
{
    my ($self, $relpath) = @_;
    my $url      = $self->base_url.'/'.$relpath;
    my $response = $self->ua->get($url);

    # This is a hack. Can I use JSON->allow_nonref to handle
    # the fact that maxitem returns an int rather than [ int ]?
    return $response->{content} =~ m!^\s*[{[]!
           ? decode_json($response->{content})
           : $response->{content}
           ;
};

sub top_story_ids
{
    my $self   = shift;
    my $result = $self->$get('topstories.json');

    return @$result;
}

sub item
{
    my $self   = shift;
    my $id     = shift;
    my $result = $self->$get("item/$id.json");

    return WebService::HackerNews::Item->new($result);
}

sub user
{
    my $self   = shift;
    my $id     = shift;
    my $result = $self->$get("user/$id.json");

    return WebService::HackerNews::User->new($result);
}

sub max_item_id
{
    my $self   = shift;
    my $result = $self->$get('maxitem.json');

    return $result;
}

sub changed_items_and_users
{
    my $self    = shift;
    my $result = $self->$get('updates.json');
    return ($result->{items} || [], $result->{profiles} || []);
}

1;

=head1 NAME

WebService::HackerNews - interface to the official HackerNews API

=head1 SYNOPSIS

 use WebService::HackerNews;
 my $hn     = WebService::HackerNews->new;
 my @top100 = $hn->top_story_ids;
 my $item   = $hn->item( $top100[0] );
 my $user   = $hn->user($item->by);

 printf qq{"%s" by %s (karma: %d)\n},
        $item->title, $item->by, $user->karma;

=head1 DESCRIPTION

This module provides an interface to the official
L<Hacker News API|https://github.com/HackerNews/API>.
This is very much a lash-up at the moment, and liable to change.
Feel free to hack on it and send me pull requests.

It provides a semi object-oriented interface to the API.
You start off by creating an instance of C<WebService::HackerNews>:

 $hn = WebService::HackerNews->new;

You can then call one of the methods to either get information about
I<items> or I<users>.

An item is either a story, a job, a comment, a poll, or a pollopt. 
All items live in a single space, and are identified by a unique
integer identifier, or B<id>. Given an id, you can get all information
for the associated item using the C<item()> method.

A user is like an item, but represents a registered user of HackerNews.
The id for a user isn't an integer, but is a username.
Given a username, you can get all information for the associated user
with the C<user()> method.

Items and User are represented with classes, but where the attributes
of items and users relate to further items and classes, they are represented
as references to arrays of ids, rather than returning references to arrays
of other objects.

=head1 METHODS

As of version 0.02, this implements all of the functions
listed in the official documentation for the API.

=head2 top_story_ids

Returns a list of ids for the current top 100 stories.

 my @ids = $hn->top_story_ids;

You can then call C<item()> to get the details for specific items.

=head2 item($ID)

Takes an item id and returns an instance of L<WebService::HackerNews::Item>,
which has attributes named exactly the same as the properties listed in
the official doc.

 $item = $hn->item($id);
 printf "item %d has type %s\n", $item->id, $item->type;

=head2 user($ID)

Takes a user id and returns an instance of L<WebService::HackerNews::User>,
which has attributes named exactly the same as the
L<user properties|https://github.com/HackerNews/API#users>
listed in the official doc.

 $user = $hn->user($username);
 printf "user %s has %d karma\n", $user->id, $user->karma;

=head2 max_item_id

Returns the max item id.

=head2 changed_items_and_users

Returns two array references, which contain IDs for changed items
and usernames for changed users:

 use WebService::HackerNews 0.02;

 my $hn              = WebService::HackerNews->new;
 my ($items, $users) = $hn->changed_items_and_users;

 process_changed_items(@$items);
 process_changed_users(@$users);

This method returns "recently changed items and users",
without defining 'changed since when?'.
If you want to track changes, you'd just have to poll on a regular basis.

This method is really aimed at people using Firebase streaming API.

This method was added in version 0.02, so you should specify that as the
minimum version of the module, as above.

=head1 SEE ALSO

L<Blog post about the API|http://blog.ycombinator.com/hacker-news-api>.

L<API Documentation|https://github.com/HackerNews/API>.

=head1 REPOSITORY

L<https://github.com/neilb/WebService-HackerNews>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
