=head1 NAME

Cache::Tester - test utility for Cache implementations

=head1 SYNOPSIS

  use Cache::Tester;

  BEGIN { plan tests => 2 + $CACHE_TESTS }

  use_ok('Cache::Memory');

  my $cache = Cache::Memory->new();
  ok($cache, 'Cache created');

  run_cache_tests($cache);

=head1 DESCRIPTION

This module is used to run tests against an instance of a Cache implementation
to ensure that it operates as required by the Cache specification.

=cut
package Cache::Tester;

require 5.006;
use strict;
use warnings;
use Test::More;
use Exporter;
use vars qw(@ISA @EXPORT $VERSION $CACHE_TESTS);
use Carp;

@ISA = qw(Exporter Test::More);
$VERSION = '2.11';
@EXPORT = (qw(run_cache_tests $CACHE_TESTS), @Test::More::EXPORT);

$CACHE_TESTS = 79;

sub run_cache_tests {
    my ($cache) = @_;

    $cache or croak "Cache required";

    test_store_scalar($cache);
    test_entry_size($cache);
    test_store_complex($cache);
    test_cache_size($cache);
    test_cache_count($cache);
    test_expiry($cache);
    test_read_handle($cache);
    test_write_handle($cache);
    test_append_handle($cache);
    test_handle_async_read($cache);
    test_handle_async_remove($cache);
    test_handle_async_replace($cache);
    test_validity($cache);
    test_load_callback($cache);
    test_validate_callback($cache);
}

# Test storing, retrieving and removing simple scalars
sub test_store_scalar {
    my ($cache) = @_;

    my $key = 'testkey';
    my $entry = $cache->entry($key);
    _ok($entry, 'entry returned');
    _is($entry->key(), $key, 'entry key correct');
    _ok(!$entry->exists(), 'entry doesn\'t exist initially');
    _is($entry->get(), undef, '$entry->get() returns undef');

    $entry->set('test data');
    _ok($entry->exists(), 'entry exists');
    _is($entry->get(), 'test data', 'set/get worked');

    $entry->remove();
    _ok(!$entry->exists(), 'entry removed');

    $cache->set($key, 'more test data');
    _ok($cache->exists($key), 'key exists');
    _is($cache->get($key), 'more test data', 'cache set/get worked');

    $cache->remove($key);
    _ok(!$entry->exists(), 'entry removed via cache');
}

# Test size reporting of entries
sub test_entry_size {
    my ($cache) = @_;

    my $entry = $cache->entry('testsize');
    $entry->set('A'x1234);
    _ok($entry->exists(), 'entry created');
    _is($entry->size(), 1234, 'entry size is correct');

    $entry->remove();
}

# Test storing of complex entities
sub test_store_complex {
    my ($cache) = @_;

    my @array = (1, 2, { hi => 'there' });

    my $entry = $cache->entry('testcomplex');
    $entry->freeze(\@array);
    _ok($entry->exists(), 'frozen entry created');
    my $arrayref = $entry->thaw();
    _ok($array[0] == $$arrayref[0] &&
        $array[1] == $$arrayref[1] &&
        $array[2]->{hi} eq $$arrayref[2]->{hi}, 'entry thawed');

    $entry->remove();
}

# Test size tracking of cache
sub test_cache_size {
    my ($cache) = @_;

    $cache->clear();
    _is($cache->size(), 0, 'cache is empty after clear');
    $cache->set('testkey', 'A'x4000);
    _is($cache->size(), 4000, 'cache size is correct after set');
    $cache->set('testkey2', 'B'x200);
    _is($cache->size(), 4200, 'cache size is correct after 2 sets');
    $cache->set('testkey', 'C'x2800);
    _is($cache->size(), 3000, 'cache size is correct after replace');
    $cache->remove('testkey2');
    _is($cache->size(), 2800, 'cache size is correct after remove');

    $cache->clear();
    _is($cache->size(), 0, 'cache is empty after clear');

    # Add 100 entries of various lengths
    my $size = 0;
    my @keys = (1..100);
    foreach (@keys) {
        $cache->set("key$_", "D"x$_);
        $size += $_;
    }
    _is($cache->size(), $size, 'cache size is ok after multiple sets');

    shuffle(\@keys);
    foreach (@keys) {
        $cache->remove("key$_");
    }
    _is($cache->size(), 0, 'cache is empty after multiple removes');
}

# Test count tracking of cache
sub test_cache_count {
    my ($cache) = @_;

    $cache->clear();
    _is($cache->count(), 0, 'cache is empty after clear');
    $cache->set('testkey', 'test');
    _is($cache->count(), 1, 'cache count correct after set');
    $cache->set('testkey2', 'test2');
    _is($cache->count(), 2, 'cache count correct after 2 sets');
    $cache->set('testkey', 'test3');
    _is($cache->count(), 2, 'cache count correct after replace');
    $cache->remove('testkey2');
    _is($cache->count(), 1, 'cache count correct after remove');

    $cache->clear();
    _is($cache->count(), 0, 'cache is empty after clear');

    # Add 100 entries
    my @keys = (1..100);
    foreach (@keys) {
        $cache->set("key$_", "test");
    }
    _is($cache->count(), 100, 'cache count correct after multiple sets');

    shuffle(\@keys);
    foreach(@keys) {
        $cache->remove("key$_");
    }
    _is($cache->size(), 0, 'cache empty after multiple removes');
}

# Test expiry
sub test_expiry {
    my ($cache) = @_;

    my $entry = $cache->entry('testexp');

    $entry->set('test data');
    $entry->set_expiry('100 minutes');
    _cmp_ok($entry->expiry(), '>', time(), 'expiry set correctly');
    _cmp_ok($entry->expiry(), '<=', time() + 100*60, 'expiry set correctly');
    $entry->remove();

    my $size = $cache->size();

    $entry->set('test data', 'now');
    _ok(!$entry->exists(), 'entry set with instant expiry not added');
    _is($cache->size(), $size, 'size is unchanged');

    # This is to fix/workaround the test failures by high load. See:
    # https://rt.cpan.org/Public/Bug/Display.html?id=27280
    my $delay = $ENV{PERL_CACHE_PM_TESTING} ? 1 : 3;
    $entry->set('test data', "$delay sec");
    _ok($entry->exists(), "entry with $delay sec timeout added");
    sleep($delay+1);
    _ok(!$entry->exists(), 'entry expired');
    _is($cache->size(), $size, 'size is unchanged');

    $entry->set('test data', '1 minute');
    _ok($entry->exists(), 'entry with 1 min timeout added');
    sleep(2);
    _ok($entry->exists(), 'entry with 1 min timeout remains');
    $entry->set_expiry('now');
    _ok(!$entry->exists(), 'entry expired after change to instant timeout');
    _is($cache->size(), $size, 'size is unchanged');
}

# Test reading via a handle
sub test_read_handle {
    my ($cache) = @_;

    my $entry = $cache->entry('readhandle');
    $entry->remove();
    my $handle = $entry->handle('<');
    _ok(!$handle, 'read handle not available for empty entry');

    $entry->set('some test data');

    $handle = $entry->handle('<');
    _ok($handle, 'read handle created');
    $handle or diag("handle not created: $!");

    local $/;
    _is(<$handle>, 'some test data', 'read via <$handle> successful');

    {
        no warnings;
        print $handle 'this wont work';
    }
    $handle->close();
    _is($entry->get(), 'some test data', 'write to read only handle failed');

    $entry->remove();
}

# Test writing via a handle
sub test_write_handle {
    my ($cache) = @_;

    my $entry = $cache->entry('writehandle');
    $entry->remove();

    my $size = $cache->size();

    my $handle = $entry->handle('>');
    _ok($handle, 'write handle created');
    $handle or diag("handle not created: $!");

    print $handle 'A'x100;
    $handle->close();

    _is($entry->get(), 'A'x100, 'write to write only handle ok');
    _is($entry->size(), 100, 'entry size is correct');
    _is($cache->size(), $size + 100, 'cache size is correct');

    $entry->remove();
}

# Test append via a handle
sub test_append_handle {
    my ($cache) = @_;

    my $entry = $cache->entry('appendhandle');
    $entry->remove();
    $entry->set('hello ');

    my $size = $cache->size();

    my $handle = $entry->handle('>>');
    _ok($handle, 'append handle created');
    $handle or diag("handle not created: $!");

    $handle->print('world');
    $handle->close();

    _is($entry->get(), 'hello world', 'write to append handle ok');
    _is($entry->size(), 11, 'entry size is correct');
    _is($entry->size(), $size + 5, 'cache size is correct');

    $entry->remove();
}

# Test that a entry can be read while a handle is open for read
sub test_handle_async_read {
    my ($cache) = @_;

    my $entry = $cache->entry('readhandle');
    $entry->remove();

    my $size = $cache->size();

    my $data = 'test data';
    $entry->set($data);

    my $handle = $entry->handle('<') or diag("handle not created: $!");

    _ok($entry->exists(), 'entry exists after handle opened');
    _is(<$handle>, $data, 'handle returns correct data');
    _is($entry->get(), $data, '$entry->get() returns correct data');
    $handle->close();
    _ok($entry->exists(), 'entry exists after handle closed');
    _is($entry->get(), $data, '$entry->get() returns correct data');
}

# Test that a handle can be removed asynchronously with it being open
sub test_handle_async_remove {
    my ($cache) = @_;

    my $entry = $cache->entry('removehandle');
    $entry->remove();

    my $size = $cache->size();

    $entry->set('test data');

    my $handle = $entry->handle() or diag("handle not created: $!");

    # extend data by 5 bytes before removing the entry
    $handle->print('some more data');
    $handle->seek(0,0);

    $entry->remove();
    _ok(!$entry->exists(), 'entry removed whilst handle active');

    local $/;
    _is(<$handle>, 'some more data', 'read via <$handle> successful');

    # ensure we can still write to the handle
    $handle->seek(0,0);
    $handle->print('hello wide wide world');
    $handle->seek(0,0);
    _is(<$handle>, 'hello wide wide world', 'write via <$handle> successful');

    $handle->close();
    _ok(!$entry->exists(), 'entry still removed after handle closed');
    _is($entry->size(), undef, 'entry size is undefined');
    _is($cache->size(), $size, 'cache size is correct');
}

sub test_handle_async_replace {
    my ($cache) = @_;

    my $entry = $cache->entry('replacehandle');
    $entry->remove();

    my $size = $cache->size();

    $entry->set('test data');

    my $handle = $entry->handle();

    $entry->set('A'x20);
    _is($entry->get(), 'A'x20, 'entry replaced whilst handle active');

    local $/;
    _is(<$handle>, 'test data', 'read via <$handle> successful');
    $handle->seek(0,0);
    $handle->print('hello world');
    $handle->seek(0,0);
    _is(<$handle>, 'hello world', 'write via <$handle> successful');

    $handle->close();
    _ok($entry->exists(), 'entry still exists after handle closed');
    _is($entry->get(), 'A'x20, 'entry still correct after handle closed');
    _is($entry->size(), 20, 'entry size is correct');
    _is($cache->size(), $size+20, 'cache size is correct');
}

sub test_validity {
    my ($cache) = @_;

    my $entry = $cache->entry('validityentry');
    $entry->remove();

    # create an entry with validity
    $entry->set('test data');
    $entry->set_validity({ tester => 'test string' });

    undef $entry;
    $entry = $cache->entry('validityentry');
    my $validity = $entry->validity();
    _ok($validity, 'validity retrieved');
    _is($validity->{tester}, 'test string', 'validity correct');

    $entry->remove();

    # create an entry with only validity
    $entry->set_validity({ tester => 'test string' });

    undef $entry;
    $entry = $cache->entry('validityentry');
    $validity = $entry->validity();
    _ok($validity, 'validity retrieved');
    _is($validity->{tester}, 'test string', 'validity correct');

    $entry->remove();

    # create an entry with scalar validity
    $entry->set('test data');
    $entry->set_validity('test string');

    undef $entry;
    $entry = $cache->entry('validityentry');
    $validity = $entry->validity();
    _ok($validity, 'validity retrieved');
    _is($validity, 'test string', 'validity correct');
}

sub test_load_callback {
    my ($cache) = @_;

    my $key = 'testloadcallback';
    $cache->remove($key);

    my $old_callback = $cache->load_callback();
    $cache->set_load_callback(sub { return "result ".$_[0]->key() });

    _ok($cache->get($key), "result $key");
    $cache->set_load_callback($old_callback);
}

sub test_validate_callback {
    my ($cache) = @_;

    my $key = 'testvalidatecallback';
    my $result;
    my $old_callback = $cache->validate_callback();
    $cache->set_validate_callback(sub { $result = "result ".$_[0]->key() });

    $cache->set($key, 'somedata');
    $cache->get($key);
    _is($result, "result $key", "validate_callback ok");
    $cache->set_validate_callback($old_callback);
}


### Wrappers for test methods to add function name

sub _ok ($$) {
    my($test, $name) = @_;
    ok($test, (caller(1))[3].': '.$name);
}

sub _is ($$$) {
    my($x, $y, $name) = @_;
    is($x, $y, (caller(1))[3].': '.$name);
}

sub _isnt ($$$) {
    my($x, $y, $name) = @_;
    isnt($x, $y, (caller(1))[3].': '.$name);
}

sub _like ($$$) {
    my($x, $y, $name) = @_;
    like($x, $y, (caller(1))[3].': '.$name);
}

sub _unlike ($$$) {
    my($x, $y, $name) = @_;
    unlike($x, $y, (caller(1))[3].': '.$name);
}

sub _cmp_ok ($$$$) {
    my ($x, $c, $y, $name) = @_;
    cmp_ok($x, $c, $y, (caller(1))[3].': '.$name);
}


# Taken from perlfaq4
sub shuffle {
    my $deck = shift;  # $deck is a reference to an array
    my $i = @$deck;
    while ($i--) {
        my $j = int rand ($i+1);
        @$deck[$i,$j] = @$deck[$j,$i];
    }
}


1;
__END__

=head1 SEE ALSO

Cache

=head1 AUTHOR

 Chris Leishman <chris@leishman.org>
 Based on work by DeWitt Clinton <dewitt@unto.net>

=head1 COPYRIGHT

 Copyright (C) 2003-2006 Chris Leishman.  All Rights Reserved.

This module is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
either expressed or implied. This program is free software; you can
redistribute or modify it under the same terms as Perl itself.

$Id: Tester.pm,v 1.8 2006/01/31 15:23:58 caleishm Exp $

=cut
