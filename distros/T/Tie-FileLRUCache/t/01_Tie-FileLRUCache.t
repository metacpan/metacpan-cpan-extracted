use strict;

use lib ('./blib','../blib', './lib','../lib');

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-FixEOL.t'

#########################
# change 'tests => 9' to 'tests => last_test_to_print';

use File::Temp qw (tempdir);
use Test::More (tests => 9);

#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $TESTDIR = tempdir(CLEANUP => 1);

#########
# Test 1
BEGIN {
    use_ok('Tie::FileLRUCache');
}

#########
# Test 2
require_ok ('Tie::FileLRUCache');

#########
# Test 3
ok (test_bare_constructor());

#########
# Test 4
ok (test_parameterized_constructor());

#########
# Test 5
ok (test_tie());

#########
# Test 6
ok (test_obj_cache());

#########
# Test 7
ok (test_tied_cache());

#########
# Test 8
ok (test_clear_cache());

#########
# Test 9
ok (test_make_cache_key());

exit;

#####################################################################
#####################################################################

sub test_directory {
    return $TESTDIR;
}

#####################################################################
#####################################################################

sub test_tied_cache {


    {
        my %cache = ();
        unless (tie (%cache, 'Tie::FileLRUCache', test_directory())) {
                diag("Cache tie failed");
                return 0;
        }

    }

    eval {
        my %cache = ();
        tie (%cache, 'Tie::FileLRUCache');
    };
    unless ($@) {
        diag("Cache tie failed to catch bad tie parameters");
        return 0;
    }

    {
        my %cache = ();
        my $cache_obj;
        unless ($cache_obj = tie (%cache, 'Tie::FileLRUCache', test_directory(), 5)) {
                diag("Cache tie failed");
                return 0;
        }

        {
            my $test_key   = 'test';
            my $test_value = 'value';
            $cache{$test_key} = $test_value;
            unless (exists ($cache{$test_key}) and ($cache{$test_key} eq $test_value)) {
                diag("Tied cache existance check for key $test_key failed unexpectedly");
                return 0;
            }
            delete $cache{$test_key};
            if (exists ($cache{$test_key})) {
                diag("Cache value was found after deletion");
                return 0;
            }
        }

        {
            my $test_key   = { 'test' => 'key' };
            my $test_value = 'value';
            $cache{$test_key} = $test_value;
            unless (exists ($cache{$test_key}) and ($cache{$test_key} eq $test_value)) {
                diag("Tied cache existance check for non-scalar key failed unexpectedly");
                return 0;
            }
            delete $cache{$test_key};
            if (exists ($cache{$test_key})) {
                diag("Cache value was found after deletion");
                return 0;
            }
        }
        {
            my %test_items = qw ( a b    c d    e f
                                  g h    i j    k l
                                  m n
                                );

            my @item_keys = sort keys %test_items;
            foreach my $item (@item_keys) {
                $cache{$item} = $test_items{$item};
                sleep 1;
            }
            my $entries_count = $cache_obj->number_of_entries;
            unless (5 == $entries_count) {
                diag("Unexpected number of cache entries (expected 5, found $entries_count)");
                return 0;
            }
            my $match_counter = 0;
            my %expired_items = qw( a b   c d);
            foreach my $item (@item_keys) {
                unless (exists $cache{$item}) {
                    unless (defined $expired_items{$item}) {
                        diag("Cache value for item $item was expired out of sequence");
                        return 0;
                    }
                    next;
                }
                my $item_value = $cache{$item};
                $match_counter++;
                unless ($item_value eq $test_items{$item}) {
                    diag("Cache value for item was incorrect");
                    return 0;
                }
            }
            while (my ($cache_key, $cache_value) = each %cache) {
                diag("Iteration on tied hash returned results (should not)");
                return 0;
            }

            %cache = ();
            foreach my $item (@item_keys) {
                if (exists $cache{$item}) {
                    diag("Cache clear failed to completely clear tied cache");
                    return 0;
                }
            }
        }
    }

    return 1;
}

#####################################################################
#####################################################################

sub test_obj_cache {

    my $cache = Tie::FileLRUCache->new;
    $cache->keep_last(5);
    $cache->cache_dir(test_directory());

    {
        my $test_key   = 'test';
        my $test_value = 'value';
        eval {
            $cache->update( -cache_ky => $test_key, -value => $test_value );
        };
        unless ($@) {
            diag("'update' failed to catch bad calling parameter");
            return 0;
        }

        eval {
            $cache->update( -value => $test_value );
        };
        unless ($@) {
            diag("'update' failed to catch missing -cache_key/-key parameters");
            return 0;
        }

        $cache->cache_dir(undef);
        eval {
            $cache->update( -cache_key => $test_key, -value => $test_value );
        };
        unless ($@) {
            diag("'update' failed to catch missing cache dir");
            return 0;
        }
        $cache->cache_dir(test_directory());

        $cache->update( -cache_key => $test_key, -value => $test_value );

        eval {
            my ($cache_hit, $cache_result) = $cache->check( -cache_ky => $test_key );
        };
        unless ($@) {
            diag("'check' failed to catch bad calling parameter");
            return 0;
        }

        eval {
            $cache->check( -cache_key => $test_key );
        };
        unless ($@) {
            diag("'check' failed to catch bad calling context");
            return 0;
        }

        eval {
            my ($cache_hit, $cache_result) = $cache->check($test_key);
        };
        unless ($@) {
            diag("'check' failed to catch bad calling parameter");
            return 0;
        }

        eval {
            my ($cache_hit, $cache_result) = $cache->check();
        };
        unless ($@) {
            diag("'check' failed to catch missing parameters");
            return 0;
        }

        $cache->cache_dir(undef);
        eval {
            my ($cache_hit, $cache_result) = $cache->check( -cache_key => $test_key );
        };
        unless ($@) {
            diag("'check' failed to catch missing cache dir");
            return 0;
        }
        $cache->cache_dir(test_directory());

        my ($cache_hit, $check_value) = $cache->check( -cache_key => $test_key);
        if (not ($cache_hit) or ($check_value ne $test_value)) {
            diag("Cache check for key failed unexpectedly");
            return 0;
        }
        $cache->delete( -cache_key => $test_key );
        ($cache_hit, $check_value) = $cache->check({ -cache_key => $test_key });
        if ($cache_hit) {
            diag("Cache value was found after deletion");
            return 0;
        }
    }

    {
        my $test_key   = 'test';
        my $test_value = 'value';
        $cache->update( -key => $test_key, -value => $test_value );
        my ($cache_hit, $check_value) = $cache->check( -key => $test_key);
        if (not ($cache_hit) or ($check_value ne $test_value)) {
            diag("Cache check for raw key failed unexpectedly");
            return 0;
        }

        eval {
            $cache->delete( -cache_ky => $test_key );
        };
        unless ($@) {
            diag("'delete' failed to catch bad calling parameter");
            return 0;
        }

        eval {
            $cache->delete($test_key);
        };
        unless ($@) {
            diag("'delete' failed to catch bad calling parameter");
            return 0;
        }

        eval {
            $cache->delete();
        };
        unless ($@) {
            diag("'delete' failed to catch missing parameters");
            return 0;
        }

        $cache->cache_dir(undef);
        eval {
            $cache->delete( -cache_key => $test_key );
        };
        unless ($@) {
            diag("'delete' failed to catch missing cache dir");
            return 0;
        }
        $cache->cache_dir(test_directory());

        $cache->delete( -key => $test_key );
        ($cache_hit, $check_value) = $cache->check({ -key => $test_key });
        if ($cache_hit) {
            diag("Cache value was found after deletion using raw key");
            return 0;
        }
    }

    {
        my %test_items = qw ( a b    c d    e f
                              g h    i j    k l
                              m n
                            );

        my @item_keys = sort keys %test_items;
        foreach my $item (@item_keys) {
            $cache->update({ -cache_key => $item, -value => $test_items{$item} });
            sleep 1;
        }
        my $entries_count = $cache->number_of_entries;
        unless (5 == $entries_count) {
            diag("Unexpected number of cache entries");
            return 0;
        }
        my $match_counter = 0;
        my %expired_items = qw( a b   c d);
        foreach my $item (@item_keys) {
            my ($cache_hit, $item_value) = $cache->check({ -cache_key => $item });
            unless ($cache_hit) {
                unless (defined $expired_items{$item}) {
                    diag("Cache value for item $item was expired out of sequence");
                    return 0;
                }
                next;
            }

            $match_counter++;
            unless ($item_value eq $test_items{$item}) {
                diag("Cache value for item was incorrect");
                return 0;
            }
        }

        $cache->clear;
        foreach my $item (@item_keys) {
            my ($cache_hit, $item_value) = $cache->check({ -cache_key => $item });
            if ($cache_hit) {
                diag("Cache clear failed to completely clear cache");
                return 0;
            }
        }
    }

    return 1;
}

#####################################################################
#####################################################################

sub test_clear_cache {
    {
        eval {
            my $cache = Tie::FileLRUCache->new();
            $cache->clear;
        };
        unless ($@) {
            diag("'clear' failed to catch unset cache directory");
            return 0;
        }
    }

    {
        eval {
            my $cache = Tie::FileLRUCache->new({ -cache_dir => '' });
            $cache->clear;
        };
        unless ($@) {
            diag("'clear' failed to catch unset cache directory");
            return 0;
        }
    }

    return 1;
}

#####################################################################
#####################################################################

sub test_make_cache_key {
    {
        eval {
            my $cache = Tie::FileLRUCache->new();
            my $cache_key = $cache->make_cache_key ({ -key => { 'a' => 'b', 'c' => 'd' } });
        };
        if ($@) {
            diag("Cache key constructor failed $@");
            return 0;
        }
    }

    {
        eval {
            my $cache = Tie::FileLRUCache->new();
            my $cache_key = $cache->make_cache_key ({ -ky => { 'a' => 'b', 'c' => 'd' } });
        };
        unless ($@) {
            diag("Cache key constructor failed to catch bad parameters");
            return 0;
        }
    }

    return 1;
}

#####################################################################
#####################################################################

sub test_bare_constructor {
    {
        my $result = eval {
            my $fixer = Tie::FileLRUCache::new();
            return $fixer;
        };
        if ($@ or not $result) {
            diag("Direct mode constructor failed");
            return 0;
        }
    }

    {
        my $result = eval {
            my $fixer = Tie::FileLRUCache->new();
            return $fixer;
        };
        if ($@ or not $result) {
            diag("Direct mode constructor failed");
            return 0;
        }
    }

    {
        my $result = eval {
            my $fixer_proto = Tie::FileLRUCache->new();
            my $fixer       = $fixer_proto->new();
            return $fixer;
        };
        if ($@ or not $result) {
            diag("Instance mode constructor failed");
            return 0;
        }
    }

    {
        my $result = eval {
            my $fixer = Tie::FileLRUCache::new();
            return $fixer;
        };
        if ($@ or not $result) {
            diag("Static mode constructor failed");
            return 0;
        }
    }

    {
        my $result = eval {
            my $fixer = new Tie::FileLRUCache();
            return $fixer;
        };
        if ($@ or not $result) {
            diag("Indirect mode constructor failed");
            return 0;
        }
    }

    return 1;
}

#####################################################################
#####################################################################

sub test_parameterized_constructor {
    {
        my $result = eval {
            my $fixer = Tie::FileLRUCache->new({ -cache_dir => test_directory(), -keep_last => 10 });
            return $fixer;
        };
        if ($@ or not $result) {
            diag("Direct mode constructor failed");
            return 0;
        }
    }

    {
        my $result = eval {
            my $fixer = Tie::FileLRUCache->new({ -cache_dir => test_directory(), -keep_lst => 10 });
            return $fixer;
        };
        unless ($@) {
            diag("Direct mode constructor failed to catch bad parameters");
            return 0;
        }
    }

    return 1;
}

#####################################################################
#####################################################################

sub test_tie {
    {
        my $result = eval {
            my %cache_hash;
            my $fixer = tie (%cache_hash, 'Tie::FileLRUCache', test_directory(), 10);
            return $fixer;
        };
        if ($@ or not $result) {
            diag("Direct mode constructor failed");
            return 0;
        }
    }

    return 1;
}
