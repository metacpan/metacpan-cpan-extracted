#!/usr/bin/perl
#
# Copyright 1999, 2002, 2010, 2022 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

use 5.024;
use autodie;
use warnings;

use AnyDBM_File ();
use Fcntl qw(O_CREAT O_RDONLY O_RDWR);
use File::Spec ();
use Test::More tests => 46;

## no critic (Miscellanea::ProhibitTies)

require_ok('Tie::ShadowHash');

# Test setup.  Tie an AnyDBM_File object and create a tied hash with something
# interesting in it.
my $data = File::Spec->catfile('t', 'data');
my $dbmfile = File::Spec->catfile($data, 'first');
my $db = tie(my %hash, 'AnyDBM_File', $dbmfile, O_RDWR | O_CREAT, oct('666'))
  or BAIL_OUT("Cannot create AnyDBM_File tied hash $dbmfile");
open(my $fh, '<', File::Spec->catfile($data, 'first.txt'));
while (defined(my $line = <$fh>)) {
    chomp($line);
    $hash{$line} = 1;
}
close($fh);
undef $db;
untie(%hash);

# Some basic checks against a text file.
my $text = File::Spec->catfile($data, 'second.txt');
my $obj = tie(%hash, 'Tie::ShadowHash', $text);
isa_ok($obj, 'Tie::ShadowHash');
is($hash{admin}, 1, 'Found existing key in text source');
ok(!exists($hash{meta}), 'Non-existing key returned false to exists');
$hash{meta} = 2;
$hash{admin} = 2;
is($hash{meta}, 2, 'Overriding non-existing key');
is($hash{admin}, 2, 'Overriding existing key');
is($hash{jp}, 1, 'Another untouched key is still correct');
delete $hash{jp};
ok(!exists($hash{jp}), '...and it does not exist after we delete it');
$hash{jp} = 2;
is($hash{jp}, 2, '...and we can set it to another value');

# Tie only the dbm file and check some basic functionality.
undef $obj;
untie(%hash);
tie(my %db, 'AnyDBM_File', $dbmfile, O_RDONLY, oct('666'))
  or BAIL_OUT("Cannot tie newly created db file $dbmfile");
$obj = tie(%hash, 'Tie::ShadowHash', \%db);
isa_ok($obj, 'Tie::ShadowHash');
is($hash{meta}, 1, 'Found existing key in dbm source');
is($hash{admin}, undef, 'Non-existing key returns undef');
$hash{admin} = 2;
is($hash{admin}, 2, 'Overriding existing key');
is($db{admin}, undef, '...and underlying source is unchanged');
delete $hash{meta};
is($hash{meta}, undef, 'Deleting existing key');
is($db{meta}, 1, '...and underlying source is unchanged');

# Check clearning the hash.
%hash = ();
is($hash{sg}, undef, 'Existing key is undefined after clearing');

# Add back in both the dbm file and the text file.
is($obj->add(\%db, $text), 1, 'Adding sources');
is($hash{admin}, 1, 'Found data in text file');
is($hash{meta}, 1, 'Found data in dbm file');
is($hash{fooba}, undef, 'Keys missing in both fall through');

# Compare a keys listing with the full data.
open($fh, '<', File::Spec->catfile($data, 'full'));
my @full = sort <$fh>;
close($fh);
chomp(@full);
is_deeply([sort keys(%hash)], \@full, 'Complete key listing matches');

# Make sure deleted keys are skipped in a key listing.
delete $hash{sg};
my @keys = keys(%hash);
is(scalar(@keys), scalar(@full) - 1, 'One fewer key after deletion');
ok(!(grep { $_ eq 'sg' } @keys), '...and the deleted key is missing');

# Add an additional hash with a key that duplicates a key from an earlier hash
# and ensure that we don't see it twice in the keys listing.
my %extra = (admin => 'foo');
is($obj->add(\%extra), 1, 'Adding another hash source succeeds');
@keys = keys(%hash);
is(scalar(@keys), scalar(@full) - 1, 'Duplicate keys do not add to count');
is($hash{admin}, 1, '...and the earlier source still prevails');

# Restoring the deleted key should increment our key count again.
$hash{sg} = 'override';
@keys = keys(%hash);
is(scalar(@keys), scalar(@full), 'Setting a deleted key restores the count');

# Now add an override and ensure that doesn't cause duplicate keys either, but
# adding a new key via an override should increase our key count.
$hash{admin} = 'foo';
@keys = keys(%hash);
is(scalar(@keys), scalar(@full), 'Overriden keys do not add to count');
is($hash{admin}, 'foo', '...and the override is effective');
$hash{override} = 1;
@keys = keys(%hash);
is(scalar(@keys), scalar(@full) + 1, 'Added keys do add to count');

# Clear the hash and then try adding a special text source with a sub to split
# key and value.
%hash = ();
my $pairs = File::Spec->catfile($data, 'pairs.txt');
my $split = sub { my ($line) = @_; split(q{ }, $line, 2) };
is($obj->add([text => $pairs, $split]), 1, 'Adding special text source works');
my %full;
open($fh, '<', $pairs);
while (defined(my $line = <$fh>)) {
    chomp($line);
    my ($key, $value) = split(q{ }, $line, 2);
    $full{$key} = $value;
}
close($fh);
is(scalar(keys(%full)), scalar(keys(%hash)), '...and has correct key count');
is_deeply(\%hash, \%full, '...and hashes compare equal');

# Add a special text source that returns an array of values.
%hash = ();
my $triples = File::Spec->catfile($data, 'triples.txt');
$split = sub { my ($line) = @_; split(q{ }, $line) };
is($obj->add([text => $triples, $split]), 1, 'Adding second source works');
undef %full;
open($fh, '<', $triples);
while (defined(my $line = <$fh>)) {
    chomp($line);
    my ($key, @value) = split(q{ }, $line);
    $full{$key} = [@value];
}
close($fh);
is(scalar(keys(%full)), scalar(keys(%hash)), '...and has correct key count');
for my $key (keys(%full)) {
    is_deeply($hash{$key}, $full{$key}, "...and value of $key is correct");
}

# Test handling of the hash in a scalar context.
%hash = ();
ok(!scalar(%hash), 'Scalar value is false when the hash as been cleared');
%extra = (foo => 1, bar => 1);
is($obj->add(\%extra), 1, 'Adding a hash works');
ok(scalar(%hash), '...and now the scalar value is true');
delete $hash{foo};
delete $hash{bar};
ok(!scalar(%hash), 'The scalar value is false after deleting both members');

# Ensure that storing an undefined value directly in the shadow hash works
# properly with FETCH.
%hash = ();
is($obj->add(\%extra), 1, 'Adding the hash again works');
is($hash{foo}, 1, '...and the value of foo is what we expect');
$hash{foo} = undef;
is($hash{foo}, undef, 'The value is undef after explicitly storing that');

# Clean up after ourselves (delete first* in $data except for first.txt).
opendir(my $dir, $data);
for my $file (grep { m{ ^ first }xms } readdir($dir)) {
    if ($file ne 'first.txt') {
        unlink(File::Spec->catfile($data, $file));
    }
}
closedir($dir);
