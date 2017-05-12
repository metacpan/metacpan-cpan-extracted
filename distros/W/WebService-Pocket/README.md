# NAME

WebService::Pocket - Client for the Pocket api (http://getpocket.com/api/)

# VERSION

version 0.003

# SYNOPSIS

    use WebService::Pocket;

    my $p = WebService::Pocket->new(
        username => 'throughnothing',
        password => 'secret',
    );

    # Get list of read items as Array of WebService::Pocket::Item objects
    my $items = $p->list( state => 'read' );

    # Add an item
    $p->add({ url => 'http://www.article.com', title => 'My Title' });

    # Add multiple items, returns Array of WebService::Pocket::Item objects
    my $new_items = $p->add([
        { url => 'http://www.article.com' },
        { url => 'http://www.article1.com', title => 'Article1' },
        { url => 'http://www.article2.com', title => 'Best Article' },
    ]);

    # Get Titles and URL's for new items
    for ( @$new_items ) {
        say $_->title . " : " . $_->url;
    }

    # Update read status of an item
    $items->[0]->state( 0 );

    # Update title of an item
    $items->[0]->title( 'New Title' );

    # Update tags of an item ( replaces all tags with these )
    $items->[0]->tags( [ 'tag1', 'tag2', 'tag3' ] );

# DESCRIPTION

This distribution provides an easy interface to the
[Pocket API](http://getpocket.com/api/).  It allows you to add, view and modify
your list of items in a very simple way.

# METHODS

## new

The constructor accepts a `username` and `password` and validates
your credentials with the [Pocket API](http://getpocket.com/api/):

    my $p = WebService::Pocket->new(
        username => 'throughnothing',
        password => 'myS3cr3t',
    );

## add

Allows you to add items to your `Pocket` list.  You can add a single item
via a simple HashRef:

    my ( $new_item ) = $p->add( { url => 'http://youtube.com/video' } );

Or multiple items via an ArrayRef:

    my $new_items = $p->add([
        { url => 'http://youtube.com/video', title => 'video 1' },
        { url => 'http://youtube.com/video2', title => 'video 2' },
    ]);

Note that only the `url` field is required for each added item, but you
can set the `title` as well if you like. The `add` function will always
return an ArrayRef of [WebService::Pocket::Item](https://metacpan.org/pod/WebService::Pocket::Item) objects if it succeeded.

## list

Allows you to retrieve the list of items in your `Pocket` account.  Returns
a list of [WebService::Pocket::Item](https://metacpan.org/pod/WebService::Pocket::Item) objects.

    my $items = $p->list;

You can pass in any parameters available to the
[Pocket API Get](http://getpocket.com/api/docs/#get) request.

    # Get only read items, with tags
    $p->list( state = 0, tags => 1 );

    # Get only the first 5 resutls
    $p->list( count => 5, page => 1 );

## stats

Stats will return a [WebService::Pocket::Stats](https://metacpan.org/pod/WebService::Pocket::Stats) object, which contains
a few statistics about your `Pocket` account.

    # Get the stats object
    my $stats = $p->stats;

    # How long i've been a user
    say $stats->user_since;

    # How many items in my list total
    say $stats->count_list;

    # How many unread items in my list
    say $stats->count_unread;

    # How many read items in my list
    say $stats->count_read;

# AUTHOR

William Wolf <throughnothing@gmail.com>

# COPYRIGHT AND LICENSE



William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

# CONTRIBUTORS

- Andreas Marienborg <andreas.marienborg@gmail.com>
- Paul Fenwick <pjf@perltraining.com.au>
- ben hengst <notbenh@cpan.org>
