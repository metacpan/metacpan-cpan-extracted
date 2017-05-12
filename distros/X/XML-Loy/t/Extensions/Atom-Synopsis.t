#!/usr/bin/perl
use strict;
use warnings;

use lib ('lib', '../lib', '../../lib', '../../../lib');

use Mojo::ByteStream 'b';
use Test::Mojo;
use Mojolicious::Lite;

use Test::More tests => 10;

use_ok('XML::Loy::Atom');

# Create new Atom feed
my $feed = XML::Loy::Atom->new('feed');

# Add new author
$feed->author(
  name => 'Sheldon Cooper',
  uri => 'https://en.wikipedia.org/wiki/Sheldon_Cooper'
);

# Set title
$feed->title('Bazinga!');

# Set current time for publishing
$feed->published(time);

# Add new entry
my $entry = $feed->entry(id => 'first');

for ($entry) {
  $_->title('Welcome');
  $_->summary('My first post');

  # Add content
  my $content = $_->content(
    xhtml => '<p>First para</p>'
  );

  # Use XML::Loy methods
  $content->add(p => 'Second para')
    ->comment('My second paragraph');
};

ok(my $author = $feed->author->[0], 'Get author');

is($author->at('name')->text, 'Sheldon Cooper', 'Name');
is($author->at('uri')->text, 'https://en.wikipedia.org/wiki/Sheldon_Cooper', 'Uri');

ok($entry = $feed->entry('first'), 'First entry');
is($entry->summary->all_text, 'My first post',
   'Correct summary');

ok($feed->published, 'Published is set');

is($feed->title->text, 'Bazinga!', 'title');

is($entry->find('div > p')->[0]->text, 'First para', 'First para');
is($entry->find('div > p')->[1]->text, 'Second para', 'Second para');
