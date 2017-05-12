#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 40;
use Test::Exception;
use Tree::SEMETrie;

my $trie = Tree::SEMETrie->new();

#Check that a trie will only find what was inserted
ok ! $trie->find('a'),   'Non-existent key not found';
ok ! $trie->remove('a'), 'Non-existent key not removed';

#Check that undefined keys cannot be stored
is $trie->add(undef), undef,    'Storing undefined key returns undef';
is $trie->find(undef), undef,   'Retrieving undefined key returns undef';
is $trie->remove(undef), undef, 'Removing undefined key returns undef';

#Check that a key can be stored and retrieved
ok $trie->add('a'),                'Key without defined value added successfully';
ok $trie->find('a'),               'Key without defined value found';
ok $trie->find('a')->has_value,    'Key without defined value has value';
is $trie->find('a')->value, undef, 'Value of key without defined value is undefined';
is $trie->remove('a'), undef,      'Removing Key without defined value returns undef';
ok ! $trie->find('a'),             'Removed key without defined value not found';

#Check that a key-value pair can be stored and retrieved
ok $trie->add('b', 2),          'Key with defined value added successfully';
ok $trie->find('b'),            'Key with defined value found';
ok $trie->find('b')->has_value, 'Key with defined value has value';
is $trie->find('b')->value, 2,  'Key with defined value fetched successfully';
is $trie->remove('b'), 2,       'Removing key with defined value returns its value';
ok ! $trie->find('b'),          'Removed key with defined value not found';

#Check that numerical values are not an issue
ok $trie->add(0, 6),          'Numerically false key added successfully';
ok $trie->find(0),            'Numerically false key found';
ok $trie->find(0)->has_value, 'Numerically false key has value';
is $trie->find(0)->value, 6,  'Numerically false key fetched successfully';
is $trie->remove(0), 6,       'Removing numerically false key returns its value';
ok ! $trie->find(0),          'Removed numerically false key not found';

ok $trie->add(9, 8),          'Numerically true key added successfully';
ok $trie->find(9),            'Numerically true key found';
ok $trie->find(9)->has_value, 'Numerically true key has value';
is $trie->find(9)->value, 8,  'Numerically true key fetched successfully';
is $trie->remove(9), 8,       'Removing numerically true key returns its value';
ok ! $trie->find(9),          'Removed numerically true key not found';

#Check that unicode is not an issue
ok $trie->add("\x{b3c3}", 10),         'Unicode key added succesffuly';
ok $trie->find("\x{b3c3}"),            'Unicode key found';
ok $trie->find("\x{b3c3}")->has_value, 'Unicode key has value';
is $trie->find("\x{b3c3}")->value, 10, 'Unicode key fetched successfully';
is $trie->remove("\x{b3c3}"), 10,      'Removing unicode key returns its value';
ok ! $trie->find("\x{b3c3}"),          'Removed unicode key not found';

#Check that the empty string is equivalent to the root
ok $trie->add('', 'root-value'),    'Empty string key added successfully';
is $trie->find(''), $trie,          'Empty string key is equivalent to root';
is $trie->remove(''), 'root-value', 'Removing empty string key returns root value';
ok $trie->find(''),                 'Empty strng key can always be found';
ok ! $trie->find('')->has_value,    'Removed empty string key has no value';
