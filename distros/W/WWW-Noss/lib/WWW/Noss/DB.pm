package WWW::Noss::DB;
use 5.016;
use strict;
use warnings;
our $VERSION = '1.04';

use List::Util qw(all any max);

use DBI;
use JSON;

use WWW::Noss::FeedReader qw(read_feed);

my %DAY_MAP = (
	0 => 'Sunday',
	1 => 'Monday',
	2 => 'Tuesday',
	3 => 'Wednesday',
	4 => 'Thursday',
	5 => 'Friday',
	6 => 'Saturday',
);

sub _initialize {

	my ($self) = @_;

	$self->{ DB } = DBI->connect(
		"dbi:SQLite:dbname=$self->{ Path }", '', '',
		{
			RaiseError => 1,
			AutoInactiveDestroy => 1,
			AutoCommit => 0,
		}
	);

	$self->{ DB }->do(
		q{
CREATE TABLE IF NOT EXISTS feeds (
	nossname TEXT NOT NULL UNIQUE,
	nosslink TEXT NOT NULL,
	title TEXT NOT NULL,
	link TEXT,
	description TEXT,
	updated INTEGER,
	author TEXT,
	category TEXT,
	generator TEXT,
	image TEXT,
	rights TEXT,
	skiphours TEXT,
	skipdays TEXT
);
		}
	);

	$self->{ DB }->do(
		q{
CREATE INDEX IF NOT EXISTS
	idx_feeds_nossname
ON
	feeds(nossname);
		}
	);

	$self->{ DB }->do(
		q{
CREATE TABLE IF NOT EXISTS posts (
	nossid INTEGER NOT NULL,
	status TEXT NOT NULL,
	feed TEXT NOT NULL,
	title TEXT,
	link TEXT,
	author TEXT,
	category TEXT,
	summary TEXT,
	published INTEGER,
	updated INTEGER,
	uid TEXT
);
		}
	);

	$self->{ DB }->do(
		q{
CREATE INDEX IF NOT EXISTS
	idx_posts_uid
ON
	posts(uid);
		}
	);

	$self->{ DB }->do(
		q{
CREATE INDEX IF NOT EXISTS
	idx_posts_feedid
ON
	posts(feed, nossid);
		}
	);

	return 1;

}

sub new {

	my ($class, $file) = @_;

	my $self = {
		Path => undef,
		DB   => undef,
	};

	bless $self, $class;

	$self->{ Path } = $file;

	$self->_initialize;
	$self->commit;

	return $self;

}

sub has_feed {

	my ($self, $feed) = @_;

	my $name =
		$feed->isa('WWW::Noss::FeedConfig')
		? $feed->name
		: $feed;

	my $row = $self->{ DB }->selectrow_arrayref(
		q{
SELECT
	rowid
FROM
	feeds
WHERE
	nossname = ?;
		},
		undef,
		$name
	);

	return defined $row;

}

sub load_feed {

	my ($self, $feed) = @_;

	my ($feedref, $postref) = read_feed($feed);

	$self->{ DB }->do(
		q{
INSERT INTO feeds(
	nossname,
	nosslink,
	title,
	link,
	description,
	updated,
	author,
	category,
	generator,
	image,
	rights,
	skiphours,
	skipdays
)
VALUES(
	?,
	?,
	?,
	?,
	?,
	(0 + ?),
	?,
	?,
	?,
	?,
	?,
	?,
	?
)
ON CONFLICT (nossname) DO
UPDATE
SET
	nossname = excluded.nossname,
	nosslink = excluded.nosslink,
	title = excluded.title,
	link = excluded.link,
	description = excluded.description,
	updated = excluded.updated,
	author = excluded.author,
	category = excluded.category,
	generator = excluded.generator,
	image = excluded.image,
	rights = excluded.rights,
	skiphours = excluded.skiphours,
	skipdays = excluded.skipdays;
		},
		undef,
		$feedref->{ nossname },
		$feedref->{ nosslink },
		$feedref->{ title },
		$feedref->{ link },
		$feedref->{ description },
		$feedref->{ updated },
		$feedref->{ author },
		(defined $feedref->{ category } ? encode_json($feedref->{ category }) : undef),
		$feedref->{ generator },
		$feedref->{ image },
		$feedref->{ rights },
		(defined $feedref->{ skiphours } ? encode_json($feedref->{ skiphours }) : undef),
		(defined $feedref->{ skipdays  } ? encode_json($feedref->{ skipdays  }) : undef),
	);

	# Can't pass undef directly to an SQL statement, so we have to do this ugly
	# hack...
	my $sel_id = $self->{ DB }->prepare(
		q{
SELECT
	rowid
FROM
	posts
WHERE
	(uid = ? OR (uid IS NULL AND ? IS NULL)) AND
	feed = ? AND
	(title = ? OR (title IS NULL AND ? IS NULL)) AND
	(link = ? OR (link IS NULL AND ? IS NULL)) AND
	(published = ? OR (published IS NULL AND ? IS NULL));
		}
	);

	my $insert_post = $self->{ DB }->prepare(
		q{
INSERT INTO posts (
	nossid,
	status,
	feed,
	title,
	link,
	author,
	category,
	summary,
	published,
	updated,
	uid
)
VALUES (
	(0 + ?),
	?,
	?,
	?,
	?,
	?,
	?,
	?,
	(0 + ?),
	(0 + ?),
	?
)
RETURNING
	rowid as rowid;
		}
	);

	my $update_post = $self->{ DB }->prepare(
		q{
UPDATE posts
SET
	nossid = (0 + ?),
	author = ?,
	category = ?,
	summary = ?,
	updated = (0 + ?)
WHERE
	rowid = (0 + ?);
		},
	);

	my $new = 0;
	my @ok;

	for my $e (@$postref) {

		$sel_id->execute(
			$e->{ uid }, $self->{ uid },
			$e->{ feed },
			$e->{ title }, $self->{ title },
			$e->{ link }, $self->{ link },
			$e->{ published }, $self->{ published },
		);

		my $sel = $sel_id->fetchrow_arrayref;

		if (defined $sel) {

			$update_post->execute(
				$e->{ nossid },
				$e->{ author },
				(defined $e->{ category } ? encode_json($e->{ category }) : undef),
				$e->{ summary },
				$e->{ updated },
				$sel->[0]
			);

			push @ok, $sel->[0];

		} else {

			$insert_post->execute(
				$e->{ nossid },
				($feed->autoread ? 'read' : 'unread'),
				$e->{ feed },
				$e->{ title },
				$e->{ link },
				$e->{ author },
				(defined $e->{ category } ? encode_json($e->{ category }) : undef),
				$e->{ summary },
				$e->{ published },
				$e->{ updated },
				$e->{ uid },
			);

			my $ins = $insert_post->fetchrow_arrayref;
			push @ok, $ins->[0];
			$new++;

		}
	}

	my $ok_set = sprintf "(%s)", join ',', @ok;

	$self->{ DB }->do(
		qq{
DELETE FROM
	posts
WHERE
	feed = ? AND
	rowid NOT IN $ok_set;
		},
		undef,
		$feed->name
	);

	return $new;

}

sub feed {

	my ($self, $feed, %param) = @_;

	my $name =
		$feed->isa('WWW::Noss::FeedConfig')
		? $feed->name
		: $feed;

	my $row = $self->{ DB }->selectrow_hashref(
		q{
SELECT
	nossname,
	nosslink,
	title,
	link,
	description,
	updated,
	author,
	category,
	generator,
	image,
	rights,
	skiphours,
	skipdays
FROM
	feeds
WHERE
	nossname = ?;
		},
		undef,
		$name
	);

	return undef unless defined $row;

	$row->{ category } =
		defined $row->{ category }
		? decode_json($row->{ category })
		: [];
	$row->{ skiphours } =
		defined $row->{ skiphours }
		? decode_json($row->{ skiphours })
		: [];
	$row->{ skipdays } =
		defined $row->{ skipdays }
		? decode_json($row->{ skipdays })
		: [];

	if ($param{ post_info }) {

		my $posts = $self->{ DB }->selectall_arrayref(
			q{
SELECT
	status,
	updated,
	published
FROM
	posts
WHERE
	feed = ?;
			},
			undef,
			$name
		);

		$row->{ updated } //=
			(max grep { defined } map { $_->[1] } @$posts) //
			(max grep { defined } map { $_->[2] } @$posts);

		$row->{ posts }  = scalar @$posts;
		$row->{ unread } = scalar grep { $_->[0] eq 'unread' } @$posts;

	}

	return $row;

}

sub feeds {

	my ($self) = @_;

	my $feeds = $self->{ DB }->selectall_arrayref(
		q{
SELECT
	nossname,
	nosslink,
	title,
	link,
	description,
	updated,
	author,
	category,
	generator,
	image,
	rights,
	skiphours,
	skipdays
FROM
	feeds;
		},
		{ Slice => {} },
	);

	for my $f (@$feeds) {
		$f->{ category } =
			defined $f->{ category }
			? decode_json($f->{ category })
			: [];
		$f->{ skiphours } =
			defined $f->{ skiphours }
			? decode_json($f->{ skiphours })
			: [];
		$f->{ skipdays } =
			defined $f->{ skipdays }
			? decode_json($f->{ skipdays })
			: [];
	}

	return @$feeds;

}

sub del_feeds {

	my ($self, @feeds) = @_;

	my $feed_set =
		sprintf '(%s)',
		join ',',
		map { $self->{ DB }->quote($_) }
		@feeds;

	$self->{ DB }->do(
		qq{
DELETE FROM
	feeds
WHERE
	nossname IN $feed_set;
		}
	);

	$self->{ DB }->do(
		qq{
DELETE FROM
	posts
WHERE
	feed IN $feed_set;
		}
	);

	return 1;

}

sub post {

	my ($self, $feed, $post) = @_;

	my $name =
		$feed->isa('WWW::Noss::FeedConfig')
		? $feed->name
		: $feed;

	my $postref = $self->{ DB }->selectrow_hashref(
		q{
SELECT
	nossid,
	status,
	feed,
	title,
	link,
	author,
	category,
	summary,
	published,
	updated,
	uid
FROM
	posts
WHERE
	feed = ? AND
	nossid = (0 + ?);
		},
		undef,
		$feed,
		$post
	);

	return undef unless defined $postref;

	$postref->{ category } =
		defined $postref->{ category }
		? decode_json($postref->{ category })
		: [];

	return $postref;

}

sub first_unread {

	my ($self, $feed) = @_;

	my $name =
		$feed->isa('WWW::Noss::FeedConfig')
		? $feed->name
		: $feed;

	my $postref = $self->{ DB }->selectrow_hashref(
		q{
SELECT
	nossid,
	status,
	feed,
	title,
	link,
	author,
	category,
	summary,
	published,
	updated,
	uid
FROM
	posts
WHERE
	feed = ? AND
	status = 'unread'
ORDER BY
	nossid DESC;
		},
		undef,
		$feed,
	);

	return undef unless defined $postref;

	$postref->{ category } =
		defined $postref->{ category }
		? decode_json($postref->{ category })
		: [];

	return $postref;

}

sub largest_id {

	my ($self, @feeds) = @_;

	my $where = '';

	if (@feeds) {
		$where = sprintf
			"WHERE feed IN (%s)",
			join(',', map { $self->{ DB }->quote($_) } @feeds);
	}

	my $row = $self->{ DB }->selectrow_arrayref(
		qq{
SELECT
	nossid
FROM
	posts
$where
ORDER BY
	nossid DESC
LIMIT 1;
		},
	);

	return defined $row ? $row->[0] : undef;

}

sub look {

	my ($self, %param) = @_;

	my @posts;

	my $title = $param{ title };
	my @feeds =
		ref $param{ feeds } eq 'ARRAY'
		? @{ $param{ feeds } }
		: ();
	my $status = $param{ status };
	my @tags =
		ref $param{ tags } eq 'ARRAY'
		? @{ $param{ tags } }
		: ();
	my @content =
		ref $param{ content } eq 'ARRAY'
		? @{ $param{ content } }
		: ();
	my $order = $param{ order } // 'feed';
	my $reverse = $param{ reverse } // 0;
	my $callback = $param{ callback } // sub {
		push @posts, $_[0];
	};

	if (defined $status and $status !~ /^(un)?read$/) {
		die "status must be 'read' or 'unread'";
	}

	unless (ref $callback eq 'CODE') {
		die "callback must be a code ref";
	}

	my @wheres;

	if (defined $title) {
		push @wheres, 'title REGEXP ' . $self->{ DB }->quote($title);
	}

	if (@feeds) {
		my $feed_set =
			sprintf '(%s)',
			join ',',
			map { $self->{ DB }->quote($_) }
			@feeds;
		push @wheres, "feed IN $feed_set";
	}

	if (defined $status) {
		push @wheres, 'status = ' . $self->{ DB }->quote($status);
	}

	if (@content) {
		push @wheres, map { 'summary REGEXP ' . $self->{ DB }->quote($_) } @content;
	}

	my $where = @wheres ? 'WHERE ' . join ' AND ', @wheres  : '';

	my ($asc, $desc, $first, $last) =
		$reverse
		? ('DESC', 'ASC' , 'LAST',  'FIRST')
		: ('ASC',  'DESC', 'FIRST', 'LAST');

	my $order_clause;

	if ($order eq 'feed') {
		$order_clause = qq{
feed $asc,
nossid $asc
		};
	} elsif ($order eq 'title') {
		$order_clause = qq{
title $asc NULLS $last,
feed $asc,
nossid $asc
		};
	} elsif ($order eq 'date') {
		$order_clause = qq{

CASE
	WHEN updated IS NOT NULL THEN updated
	ELSE published
END $asc NULLS $first,
feed $asc,
nossid $asc
		};
	} else {
		die "Cannot order posts by '$order'";
	}

	my $sth = $self->{ DB }->prepare(
		qq{
SELECT
	nossid,
	status,
	feed,
	title,
	link,
	author,
	category,
	summary,
	published,
	updated,
	uid
FROM
	posts
$where
ORDER BY
	$order_clause;
		}
	);

	$sth->execute;

	my $n = 0;

	while (my $p = $sth->fetchrow_hashref) {
		$p->{ category } =
			defined $p->{ category }
			? decode_json($p->{ category })
			: [];
		next unless all {
			my $t = $_;
			any { $_ =~ $t } @{ $p->{ category } };
		} @tags;
		$callback->($p);
		$n++;
	}

	$DB::single = 1;

	return defined $param{ callback } ? $n : @posts;

}

sub mark {

	my ($self, $mark, $feed, @post) = @_;

	my $name =
		$feed->isa('WWW::Noss::FeedConfig')
		? $feed->name
		: $feed;

	unless ($mark =~ /^(un)?read$/) {
		die "Posts can only be marked as either 'read' or 'unread'";
	}

	my @wheres = ("feed = " . $self->{ DB }->quote($feed));

	if (@post) {
		push @wheres, sprintf "nossid IN (%s)", join ',', @post;
	}

	my $where = join ' AND ', @wheres;

	my $num = $self->{ DB }->do(
		qq{
UPDATE
	posts
SET
	status = ?
WHERE
	$where;
		},
		undef,
		$mark
	);

	return $num;

}

sub skip {

	my ($self, $feed) = @_;

	my $name =
		$feed->isa('WWW::Noss::FeedConfig')
		? $feed->name
		: $feed;

	my $row = $self->{ DB }->selectrow_hashref(
		q{
SELECT
	skiphours,
	skipdays
FROM
	feeds
WHERE
	nossname = ?;
		},
		undef,
		$name
	);

	return undef unless defined $row;

	my ($hour, $day) = (gmtime)[2, 6];

	my @skip_hours =
		defined $row->{ skiphours }
		? @{ decode_json($row->{ skiphours }) }
		: ();
	my @skip_days =
		defined $row->{ skipdays }
		? @{ decode_json($row->{ skipdays }) }
		: ();

	if (grep { $hour eq $_ } @skip_hours) {
		return 1;
	}

	if (grep { $DAY_MAP{ $day } eq $_ } @skip_days) {
		return 1;
	}

	return 0;

}

sub vacuum {

	my ($self) = @_;

	# Stops the 'cannot VACUUM from within a transaction' error
	local $self->{ DB }{ AutoCommit } = 1;

	$self->{ DB }->do(q{ VACUUM; });

	return 1;

}

sub commit {

	my ($self) = @_;

	return $self->{ DB }->commit;

}

sub finish {

	my ($self) = @_;

	$self->{ DB }->disconnect;

}

DESTROY {

	my ($self) = @_;

	$self->finish;

}

1;

=head1 NAME

WWW::Noss::DB - noss SQLite database interface

=head1 USAGE

  use WWW::Noss::DB;

  my $db = WWW::Noss::DB->new('path/to/database');

=head1 DESCRIPTION

B<WWW::Noss::DB> is a module that provides an object-oriented interface to
L<noss>'s SQLite feed database. This is a private module, please consult the
L<noss> manual for user documentation.

=head1 METHODS

=over 4

=item $db = WWW::Noss::DB->new($file)

Loads a L<noss> database from C<$file> or initializes it if ones does not
exist, then returns a blessed B<WWW::Noss::DB> object.

=item $bool = $db->has_feed($feed)

Returns true if C<$db> has the feed C<$feed>.

=item $new = $db->load_feed($feed_conf)

Loads the L<WWW::Noss::FeedConfig> object C<$feed_conf> into the database.
Returns the number of new posts loaded if successful, dies on failure.

To commit the loaded feed, you must also call the C<commit()> method.

=item \%feed = $db->feed($feed, [ %param ])

Returns a hash ref of information about the feed C<$feed>. C<$feed> can either
be the name of a feed or a L<WWW::Noss::FeedConfig> object. C<%param> is an
optional hash of additional parameters.

C<\%feed> will look something like this:

  {
    nossname    => ...,
	nosslink    => ...,
	title       => ...,
	link        => ...,
	description => ...,
	updated     => ...,
	author	    => ...,
	category    => [ ... ],
	generator   => ...,
	image		=> ...,
	rights      => ...,
	skiphours   => [ ... ],
	skipdays    => [ ... ],
	posts       => ...,     # only with post_info set
	unread      => ...,     # only with post_info set
  }

The following is a list of valid fields for C<%param>:

=over 4

=item post_info

Boolean determining whether to also retrieve the total number of posts and
number of unread posts. This causes C<feed()> to be slower. Defaults to false.

=back

=item @feeds = $db->feeds()

Returns an array of feed hash refs of each feed loaded in the database. The
hash refs follow the same format as the one returned by the C<feed()> method,
minus the C<posts> and C<unread> fields.

=item $rt = $db->del_feeds(@feeds)

Deletes the feeds C<@feeds> from the database. Returns C<1> on success.

To commit the deleted feeds, you must also call the C<commit()> method.

=item \%post = $db->post($feed, $post)

Returns the hash ref C<\%post> representing post number C<$post> in feed
C<$feed>. C<$feed> can be a feed name or a L<WWW::Noss::FeedConfig> object.

C<\%post> will look something like this:

  {
	nossid    => ...,
	status    => ...,
	feed      => ...,
	title     => ...,
	link      => ...,
	author    => ...,
	category  => [ ... ],
	summary   => ...,
	published => ...,
	updated   => ...,
	uid       => ...,
  }

Returns C<undef> if no matching post exists.

=item \%post = $db->first_unread($feed)

Returns the first unread post in C<$feed>. C<$feed> can be a feed name or a
L<WWW::Noss::FeedConfig> object. C<\%post> follows the same format as the one
returned by C<post()>. Returns C<undef> if no unread post exists.

=item $id = $db->largest_id([ @feeds ])

Returns the largest ID in the specified feeds. If feeds is not provided, all
feeds are searched.

=item @posts = $db->look([ %param ])

Returns a list of posts matching the parameters specified in C<%param>. If no
parameters are provided, returns a list of every post in the database.

The following are a list of valid fields to C<%param>:

=over 4

=item title

Only return posts whose titles match the given regex.

=item feeds

Only return posts that are in the feeds of the given array ref.

=item status

Only return posts that are of the given status. Can either be C<'read'> or
C<'unread'>.

=item tags

Only return posts containing the tags specified by the given array ref.

=item content

Only return posts whose content match all regexes in the given array ref.

=item order

How C<look()> should order the returned posts. The following are valid values:

=over 4

=item feed

Order by feed alphabetically.

=item title

Order by post title alphabetically.

=item date

Order by post date.

=back

=item reverse

Return the post list in reverse order.

=item callback

Subroutine reference to a callback to call on each post reference. The post
reference is available via the C<@_> array. When this option is set,
C<look> will return the number of posts processed instead of the post list.

=back

=item $num = $db->mark($mark, $feed, @post)

Mark the posts C<@post> in feed C<$feed> as C<$mark>. Returns the number of posts
updated. C<$feed> can be either a feed name or L<WWW::Noss::FeedConfig> object.
C<$mark> can either be C<'read'> or C<'unread'>. C<@post> is a list of post IDs
to update. If C<@post> is empty, all posts in C<$feed> are updated.

To commit the updated posts, you must also call the C<commit()> method.

=item $bool = $db->skip($feed)

Check whether you are supposed to skip updating C<$feed> right now. C<$feed>
can either be a feed name or L<WWW::Noss::FeedConfig> object. C<undef> is
returned if C<$feed> does not exist.

=item $db->vacuum()

Runs the C<VACUUM> L<sqlite3(1)> command on the database, which frees up any
unused space within the database and reduces its total size.

=item $db->commit()

Commits database updates to the local database. Should be ran after running any
method that modifies the database.

=item $db->finish()

Closes the connection to the local database. Is automatically called when a
B<WWW::Noss::DB> object is destroyed.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/noss.git>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<WWW::Noss::FeedConfig>, L<noss>, L<sqlite3(1)>

=cut

# vim: expandtab shiftwidth=4
