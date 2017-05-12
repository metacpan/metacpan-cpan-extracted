#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 27;
use Test::Warn;

use lib '../lib', '../../lib';

use_ok('XML::Loy::Atom');
use_ok('XML::Loy::ActivityStreams');

warning_is {
  XML::Loy::ActivityStreams->new;
} 'Only use XML::Loy::ActivityStreams as an extension to Atom', 'Only extension';

ok(my $as = XML::Loy::Atom->new('feed'), 'New Atom Feed');

ok($as->extension('XML::Loy::ActivityStreams'), 'Add extension');

ok(my $as_entry = $as->entry(id => 'first'), 'New entry');

# add actor
$as->actor(name => 'Fry');

is($as->at('feed > author > name')->text,
   'Fry',
   'Add author 1');

# New actor
my $person = $as_entry->new_person(
  name => 'Bender',
  uri => 'http://sojolicio.us/bender'
);
$as_entry->actor($person);

is($as->at('entry > author > name')->text,
   'Bender',
    'Add author 2');
is($as->at('entry > author > uri')->text,
   'http://sojolicio.us/bender',
    'Add author 3');
is($as_entry->actor->at('name')->text, 'Bender', 'Bender Name');
is($as->actor->at('name')->text, 'Fry', 'Fry Name');

# add verb
ok($as_entry->verb('follow'), 'Add verb');
is($as_entry->at('verb')->namespace,
   'http://activitystrea.ms/schema/1.0/', 'Add verb');
is($as_entry->verb, 'http://activitystrea.ms/schema/1.0/follow', 'Get verb');


# add object
ok($as->object(
  'object-type' => 'person',
  displayName => 'Leela'
), 'Set object');
is($as->at('object > displayName')->text, 'Leela', 'Add object 1');
is($as->at('object > object-type')->text,
   'http://activitystrea.ms/schema/1.0/person', 'Add object 2');
is($as->at('object')->namespace,
   'http://activitystrea.ms/schema/1.0/', 'Add object 3');
is($as->at('object > object-type')->namespace,
   'http://activitystrea.ms/schema/1.0/', 'Add object 4');
is($as->object->at('object-type')->all_text,
   'http://activitystrea.ms/schema/1.0/person',
   'Get object');
is($as->object->at('displayName')->all_text,
   'Leela',
   'Get object displayName');

# add target
$as->target(
  'object-type' => 'person',
  displayName => 'Zoidberg'
);
is($as->at('target > displayName')->text, 'Zoidberg', 'Add target 1');
is($as->at('target > object-type')->text,
   'http://activitystrea.ms/schema/1.0/person', 'Add target 2');
is($as->at('target')->namespace,
   'http://activitystrea.ms/schema/1.0/', 'Add target 3');
is($as->at('target > object-type')->namespace,
   'http://activitystrea.ms/schema/1.0/', 'Add target 4');
is($as->target->at('object-type')->all_text,
   'http://activitystrea.ms/schema/1.0/person',
   'Get target');
is($as->target->at('displayName')->all_text,
   'Zoidberg',
   'Get target displayName');


# diag $as->to_pretty_xml;

__END__
