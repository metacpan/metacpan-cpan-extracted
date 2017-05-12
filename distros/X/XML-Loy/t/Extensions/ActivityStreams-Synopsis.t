#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 14;
use Test::Warn;

use lib 'lib', '../lib', '../../lib';

use_ok('XML::Loy::Atom');
use_ok('XML::Loy::ActivityStreams');

my $atom = XML::Loy::Atom->new('feed');
$atom->extension('XML::Loy::ActivityStreams');

my $entry = $atom->entry(id => 'first_post');

for ($entry) {
  $_->actor(name => 'Fry');
  $_->verb('loves');
  $_->object('object-type' => 'person', name => 'Leela')->title('Captain');
  $_->title(xhtml => 'Fry loves Leela');
  $_->summary("Now it's official!");
  $_->published(time);
};

is($entry->actor->at('name')->text, 'Fry', 'Actor name');
is($entry->verb, 'http://activitystrea.ms/schema/1.0/loves', 'Verb');
is($entry->object->at('name')->text, 'Leela', 'Actor name');
is($entry->object->at('object-type')->text, 'http://activitystrea.ms/schema/1.0/person', 'Actor name');
is($entry->title->all_text, 'Fry loves Leela', 'Title');


is($entry->summary->all_text, 'Now it\'s official!', 'Summary');
ok(my $time = $entry->published, 'Published time');
ok(length($entry->published->to_string) > 5, 'Date length');
ok(length($entry->published->epoch) > 5, 'Date length');
like($entry->published->epoch, qr/^\d+$/, 'Date');
is($entry->published->to_string, $time->to_string, 'Date');
is($entry->published->epoch, $time->epoch, 'Date');

__END__
