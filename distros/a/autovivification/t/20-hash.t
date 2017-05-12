#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Test::Leaner tests => 9 * 3 * 302;

use autovivification::TestCases;

while (<DATA>) {
 1 while chomp;
 next unless /#/;
 testcase_ok($_, '%');
}

__DATA__

--- fetch ---

$x # $x->{a} # '', undef, { }
$x # $x->{a} # '', undef, undef #
$x # $x->{a} # '', undef, undef # +fetch
$x # $x->{a} # '', undef, { }   # +exists
$x # $x->{a} # '', undef, { }   # +delete
$x # $x->{a} # '', undef, { }   # +store

$x # $x->{a} # '', undef, { }   # -fetch
$x # $x->{a} # '', undef, { }   # +fetch -fetch
$x # $x->{a} # '', undef, undef # -fetch +fetch
$x # $x->{a} # '', undef, undef # +fetch -exists

$x # $x->{a} # qr/^Reference vivification forbidden/, undef, undef # +strict +fetch
$x # $x->{a} # '', undef, { } # +strict +exists
$x # $x->{a} # '', undef, { } # +strict +delete
$x # $x->{a} # '', undef, { } # +strict +store

$x # $x->{a}->{b} # '', undef, { a => { } }
$x # $x->{a}->{b} # '', undef, undef        #
$x # $x->{a}->{b} # '', undef, undef        # +fetch
$x # $x->{a}->{b} # '', undef, { a => { } } # +exists
$x # $x->{a}->{b} # '', undef, { a => { } } # +delete
$x # $x->{a}->{b} # '', undef, { a => { } } # +store

$x # $x->{a}->{b} # qr/^Reference vivification forbidden/, undef, undef # +strict +fetch
$x # $x->{a}->{b} # '', undef, { a => { } } # +strict +exists
$x # $x->{a}->{b} # '', undef, { a => { } } # +strict +delete
$x # $x->{a}->{b} # '', undef, { a => { } } # +strict +store

$x->{a} = 1 # $x->{a} # '', 1,     { a => 1 } # +fetch
$x->{a} = 1 # $x->{b} # '', undef, { a => 1 } # +fetch
$x->{a} = 1 # $x->{a} # '', 1,     { a => 1 } # +exists
$x->{a} = 1 # $x->{b} # '', undef, { a => 1 } # +exists
$x->{a} = 1 # $x->{a} # '', 1,     { a => 1 } # +delete
$x->{a} = 1 # $x->{b} # '', undef, { a => 1 } # +delete
$x->{a} = 1 # $x->{a} # '', 1,     { a => 1 } # +store
$x->{a} = 1 # $x->{b} # '', undef, { a => 1 } # +store

$x->{a} = 1 # $x->{a} # '', 1,     { a => 1 } # +strict +fetch
$x->{a} = 1 # $x->{b} # '', undef, { a => 1 } # +strict +fetch
$x->{a} = 1 # $x->{a} # '', 1,     { a => 1 } # +strict +exists
$x->{a} = 1 # $x->{b} # '', undef, { a => 1 } # +strict +exists
$x->{a} = 1 # $x->{a} # '', 1,     { a => 1 } # +strict +delete
$x->{a} = 1 # $x->{b} # '', undef, { a => 1 } # +strict +delete
$x->{a} = 1 # $x->{a} # '', 1,     { a => 1 } # +strict +store
$x->{a} = 1 # $x->{b} # '', undef, { a => 1 } # +strict +store

$x->{a}->{b} = 1 # $x->{a}->{b} # '', 1,     { a => { b => 1 } } # +fetch
$x->{a}->{b} = 1 # $x->{a}->{d} # '', undef, { a => { b => 1 } } # +fetch
$x->{a}->{b} = 1 # $x->{c}->{d} # '', undef, { a => { b => 1 } } # +fetch
$x->{a}->{b} = 1 # $x->{a}->{b} # '', 1,     { a => { b => 1 } } # +exists
$x->{a}->{b} = 1 # $x->{a}->{d} # '', undef, { a => { b => 1 } } # +exists
$x->{a}->{b} = 1 # $x->{c}->{d} # '', undef, { a => { b => 1 }, c => { } } # +exists
$x->{a}->{b} = 1 # $x->{a}->{b} # '', 1,     { a => { b => 1 } } # +delete
$x->{a}->{b} = 1 # $x->{a}->{d} # '', undef, { a => { b => 1 } } # +delete
$x->{a}->{b} = 1 # $x->{c}->{d} # '', undef, { a => { b => 1 }, c => { } } # +delete
$x->{a}->{b} = 1 # $x->{a}->{b} # '', 1,     { a => { b => 1 } } # +store
$x->{a}->{b} = 1 # $x->{a}->{d} # '', undef, { a => { b => 1 } } # +store
$x->{a}->{b} = 1 # $x->{c}->{d} # '', undef, { a => { b => 1 }, c => { } } # +store

$x->{a}->{b} = 1 # $x->{a}->{b} # '', 1,     { a => { b => 1 } }                # +strict +fetch
$x->{a}->{b} = 1 # $x->{a}->{d} # '', undef, { a => { b => 1 } }                # +strict +fetch
$x->{a}->{b} = 1 # $x->{c}->{d} # qr/^Reference vivification forbidden/, undef, { a => { b => 1 } } # +strict +fetch
$x->{a}->{b} = 1 # $x->{a}->{b} # '', 1,     { a => { b => 1 } }                # +strict +exists
$x->{a}->{b} = 1 # $x->{a}->{d} # '', undef, { a => { b => 1 } }                # +strict +exists
$x->{a}->{b} = 1 # $x->{c}->{d} # '', undef, { a => { b => 1 }, c => { } }      # +strict +exists
$x->{a}->{b} = 1 # $x->{a}->{b} # '', 1,     { a => { b => 1 } }                # +strict +delete
$x->{a}->{b} = 1 # $x->{a}->{d} # '', undef, { a => { b => 1 } }                # +strict +delete
$x->{a}->{b} = 1 # $x->{c}->{d} # '', undef, { a => { b => 1 }, c => { } }      # +strict +delete
$x->{a}->{b} = 1 # $x->{a}->{b} # '', 1,     { a => { b => 1 } }                # +strict +store
$x->{a}->{b} = 1 # $x->{a}->{d} # '', undef, { a => { b => 1 } }                # +strict +store
$x->{a}->{b} = 1 # $x->{c}->{d} # '', undef, { a => { b => 1 }, c => { } }      # +strict +store

--- aliasing ---

$x # 1 for $x->{a}; () # '', undef, { a => undef }
$x # 1 for $x->{a}; () # '', undef, { a => undef } #
$x # 1 for $x->{a}; () # '', undef, { a => undef } # +fetch
$x # 1 for $x->{a}; () # '', undef, { a => undef } # +exists
$x # 1 for $x->{a}; () # '', undef, { a => undef } # +delete
$x # 1 for $x->{a}; () # qr/^Can't vivify reference/, undef, undef # +store

$x # $_ = 1 for $x->{a}; () # '', undef, { a => 1 }
$x # $_ = 1 for $x->{a}; () # '', undef, { a => 1 } #
$x # $_ = 1 for $x->{a}; () # '', undef, { a => 1 } # +fetch
$x # $_ = 1 for $x->{a}; () # '', undef, { a => 1 } # +exists
$x # $_ = 1 for $x->{a}; () # '', undef, { a => 1 } # +delete
$x # $_ = 1 for $x->{a}; () # qr/^Can't vivify reference/, undef, undef # +store

$x->{a} = 1 # 1 for $x->{a}; () # '', undef, { a => 1 }             # +fetch
$x->{a} = 1 # 1 for $x->{b}; () # '', undef, { a => 1, b => undef } # +fetch
$x->{a} = 1 # 1 for $x->{a}; () # '', undef, { a => 1 }             # +exists
$x->{a} = 1 # 1 for $x->{b}; () # '', undef, { a => 1, b => undef } # +exists
$x->{a} = 1 # 1 for $x->{a}; () # '', undef, { a => 1 }             # +delete
$x->{a} = 1 # 1 for $x->{b}; () # '', undef, { a => 1, b => undef } # +delete
$x->{a} = 1 # 1 for $x->{a}; () # '', undef, { a => 1 }             # +store
$x->{a} = 1 # 1 for $x->{b}; () # '', undef, { a => 1, b => undef } # +store

$x # do_nothing($x->{a}); () # '', undef, { }
$x # do_nothing($x->{a}); () # '', undef, { } #
$x # do_nothing($x->{a}); () # '', undef, { } # +fetch
$x # do_nothing($x->{a}); () # '', undef, { } # +exists
$x # do_nothing($x->{a}); () # '', undef, { } # +delete
$x # do_nothing($x->{a}); () # qr/^Can't vivify reference/, undef, undef # +store

$x # set_arg($x->{a}); () # '', undef, { a => 1 }
$x # set_arg($x->{a}); () # '', undef, { a => 1 } #
$x # set_arg($x->{a}); () # '', undef, { a => 1 } # +fetch
$x # set_arg($x->{a}); () # '', undef, { a => 1 } # +exists
$x # set_arg($x->{a}); () # '', undef, { a => 1 } # +delete
$x # set_arg($x->{a}); () # qr/^Can't vivify reference/, undef, undef # +store

--- dereferencing ---

$x # no warnings 'uninitialized'; my @a = %$x; () # ($strict ? qr/^Can't use an undefined value as a HASH reference/ : ''), undef, undef
$x # no warnings 'uninitialized'; my @a = %$x; () # ($strict ? qr/^Can't use an undefined value as a HASH reference/ : ''), undef, undef #
$x # no warnings 'uninitialized'; my @a = %$x; () # ($strict ? qr/^Can't use an undefined value as a HASH reference/ : ''), undef, undef # +fetch
$x # no warnings 'uninitialized'; my @a = %$x; () # ($strict ? qr/^Can't use an undefined value as a HASH reference/ : ''), undef, undef # +exists
$x # no warnings 'uninitialized'; my @a = %$x; () # ($strict ? qr/^Can't use an undefined value as a HASH reference/ : ''), undef, undef # +delete
$x # no warnings 'uninitialized'; my @a = %$x; () # ($strict ? qr/^Can't use an undefined value as a HASH reference/ : ''), undef, undef # +store

$x->{a} = 1 # my @a = %$x; () # '', undef, { a => 1 } # +fetch
$x->{a} = 1 # my @a = %$x; () # '', undef, { a => 1 } # +exists
$x->{a} = 1 # my @a = %$x; () # '', undef, { a => 1 } # +delete
$x->{a} = 1 # my @a = %$x; () # '', undef, { a => 1 } # +store

--- slice ---

$x # my @a = @$x{'a', 'b'}; \@a # '', [ undef, undef ], { }
$x # my @a = @$x{'a', 'b'}; \@a # '', [ undef, undef ], undef #
$x # my @a = @$x{'a', 'b'}; \@a # '', [ undef, undef ], undef # +fetch
$x # my @a = @$x{'a', 'b'}; \@a # '', [ undef, undef ], { }   # +exists
$x # my @a = @$x{'a', 'b'}; \@a # '', [ undef, undef ], { }   # +delete
$x # my @a = @$x{'a', 'b'}; \@a # '', [ undef, undef ], { }   # +store

$x->{b} = 0 # my @a = @$x{'a', 'b'}; \@a # '', [ undef, 0 ], { b => 0 } # +fetch

$x # @$x{'a', 'b'} = (1, 2); () # '', undef, { a => 1, b => 2 }
$x # @$x{'a', 'b'} = (1, 2); () # '', undef, { a => 1, b => 2 } #
$x # @$x{'a', 'b'} = (1, 2); () # '', undef, { a => 1, b => 2 } # +fetch
$x # @$x{'a', 'b'} = (1, 2); () # '', undef, { a => 1, b => 2 } # +exists
$x # @$x{'a', 'b'} = (1, 2); () # '', undef, { a => 1, b => 2 } # +delete
$x # @$x{'a', 'b'} = (1, 2); () # qr/^Can't vivify reference/, undef, undef # +store

$x->{a} = 0              # @$x{'a', 'b'} = (1, 2); () # '', undef, { a => 1, b => 2 } # +store
$x->{c} = 0              # @$x{'a', 'b'} = (1, 2); () # '', undef, { a => 1, b => 2, c => 0 } # +store
$x->{a} = 0, $x->{b} = 0 # @$x{'a', 'b'} = (1, 2); () # '', undef, { a => 1, b => 2 } # +store

--- exists ---

$x # exists $x->{a} # '', '', { }
$x # exists $x->{a} # '', '', undef #
$x # exists $x->{a} # '', '', { }   # +fetch
$x # exists $x->{a} # '', '', undef # +exists
$x # exists $x->{a} # '', '', { }   # +delete
$x # exists $x->{a} # '', '', { }   # +store

$x # exists $x->{a} # '', '', { } # +strict +fetch
$x # exists $x->{a} # qr/^Reference vivification forbidden/, undef, undef # +strict +exists
$x # exists $x->{a} # '', '', { } # +strict +delete
$x # exists $x->{a} # '', '', { } # +strict +store

$x # exists $x->{a}->{b} # '', '', { a => { } }
$x # exists $x->{a}->{b} # '', '', undef        #
$x # exists $x->{a}->{b} # '', '', { a => { } } # +fetch
$x # exists $x->{a}->{b} # '', '', undef        # +exists
$x # exists $x->{a}->{b} # '', '', { a => { } } # +delete
$x # exists $x->{a}->{b} # '', '', { a => { } } # +store

$x # exists $x->{a}->{b} # '', '', { a => { } } # +strict +fetch
$x # exists $x->{a}->{b} # qr/^Reference vivification forbidden/, undef, undef # +strict +exists
$x # exists $x->{a}->{b} # '', '', { a => { } } # +strict +delete
$x # exists $x->{a}->{b} # '', '', { a => { } } # +strict +store

$x->{a} = 1 # exists $x->{a} # '', 1,  { a => 1 } # +fetch
$x->{a} = 1 # exists $x->{b} # '', '', { a => 1 } # +fetch
$x->{a} = 1 # exists $x->{a} # '', 1,  { a => 1 } # +exists
$x->{a} = 1 # exists $x->{b} # '', '', { a => 1 } # +exists
$x->{a} = 1 # exists $x->{a} # '', 1,  { a => 1 } # +delete
$x->{a} = 1 # exists $x->{b} # '', '', { a => 1 } # +delete
$x->{a} = 1 # exists $x->{a} # '', 1,  { a => 1 } # +store
$x->{a} = 1 # exists $x->{b} # '', '', { a => 1 } # +store

$x->{a} = 1 # exists $x->{a} # '', 1,  { a => 1 } # +strict +fetch
$x->{a} = 1 # exists $x->{b} # '', '', { a => 1 } # +strict +fetch
$x->{a} = 1 # exists $x->{a} # '', 1,  { a => 1 } # +strict +exists
$x->{a} = 1 # exists $x->{b} # '', '', { a => 1 } # +strict +exists
$x->{a} = 1 # exists $x->{a} # '', 1,  { a => 1 } # +strict +delete
$x->{a} = 1 # exists $x->{b} # '', '', { a => 1 } # +strict +delete
$x->{a} = 1 # exists $x->{a} # '', 1,  { a => 1 } # +strict +store
$x->{a} = 1 # exists $x->{b} # '', '', { a => 1 } # +strict +store

$x->{a}->{b} = 1 # exists $x->{a}->{b} # '', 1,  { a => { b => 1 } } # +fetch
$x->{a}->{b} = 1 # exists $x->{a}->{d} # '', '', { a => { b => 1 } } # +fetch
$x->{a}->{b} = 1 # exists $x->{c}->{d} # '', '', { a => { b => 1 }, c => { } } # +fetch
$x->{a}->{b} = 1 # exists $x->{a}->{b} # '', 1,  { a => { b => 1 } } # +exists
$x->{a}->{b} = 1 # exists $x->{a}->{d} # '', '', { a => { b => 1 } } # +exists
$x->{a}->{b} = 1 # exists $x->{c}->{d} # '', '', { a => { b => 1 } } # +exists
$x->{a}->{b} = 1 # exists $x->{a}->{b} # '', 1,  { a => { b => 1 } } # +delete
$x->{a}->{b} = 1 # exists $x->{a}->{d} # '', '', { a => { b => 1 } } # +delete
$x->{a}->{b} = 1 # exists $x->{c}->{d} # '', '', { a => { b => 1 }, c => { } } # +delete
$x->{a}->{b} = 1 # exists $x->{a}->{b} # '', 1,  { a => { b => 1 } } # +store
$x->{a}->{b} = 1 # exists $x->{a}->{d} # '', '', { a => { b => 1 } } # +store
$x->{a}->{b} = 1 # exists $x->{c}->{d} # '', '', { a => { b => 1 }, c => { } } # +store

$x->{a}->{b} = 1 # exists $x->{a}->{b} # '', 1,  { a => { b => 1 } }            # +strict +fetch
$x->{a}->{b} = 1 # exists $x->{a}->{d} # '', '', { a => { b => 1 } }            # +strict +fetch
$x->{a}->{b} = 1 # exists $x->{c}->{d} # '', '', { a => { b => 1 }, c => { } }  # +strict +fetch
$x->{a}->{b} = 1 # exists $x->{a}->{b} # '', 1,  { a => { b => 1 } }            # +strict +exists
$x->{a}->{b} = 1 # exists $x->{a}->{d} # '', '', { a => { b => 1 } }            # +strict +exists
$x->{a}->{b} = 1 # exists $x->{c}->{d} # qr/^Reference vivification forbidden/, undef, { a => { b => 1 } }  # +strict +exists
$x->{a}->{b} = 1 # exists $x->{a}->{b} # '', 1,  { a => { b => 1 } }            # +strict +delete
$x->{a}->{b} = 1 # exists $x->{a}->{d} # '', '', { a => { b => 1 } }            # +strict +delete
$x->{a}->{b} = 1 # exists $x->{c}->{d} # '', '', { a => { b => 1 }, c => { } }  # +strict +delete
$x->{a}->{b} = 1 # exists $x->{a}->{b} # '', 1,  { a => { b => 1 } }            # +strict +store
$x->{a}->{b} = 1 # exists $x->{a}->{d} # '', '', { a => { b => 1 } }            # +strict +store
$x->{a}->{b} = 1 # exists $x->{c}->{d} # '', '', { a => { b => 1 }, c => { } }  # +strict +store

--- delete ---

$x # delete $x->{a} # '', undef, { }
$x # delete $x->{a} # '', undef, undef #
$x # delete $x->{a} # '', undef, { }   # +fetch
$x # delete $x->{a} # '', undef, { }   # +exists
$x # delete $x->{a} # '', undef, undef # +delete
$x # delete $x->{a} # '', undef, { }   # +store

$x # delete $x->{a} # '', undef, { } # +strict +fetch
$x # delete $x->{a} # '', undef, { } # +strict +exists
$x # delete $x->{a} # qr/^Reference vivification forbidden/, undef, undef # +strict +delete
$x # delete $x->{a} # '', undef, { } # +strict +store

$x # delete $x->{a}->{b} # '', undef, { a => { } }
$x # delete $x->{a}->{b} # '', undef, undef        #
$x # delete $x->{a}->{b} # '', undef, { a => { } } # +fetch
$x # delete $x->{a}->{b} # '', undef, { a => { } } # +exists
$x # delete $x->{a}->{b} # '', undef, undef        # +delete
$x # delete $x->{a}->{b} # '', undef, { a => { } } # +store

$x # delete $x->{a}->{b} # '', undef, { a => { } } # +strict +fetch
$x # delete $x->{a}->{b} # '', undef, { a => { } } # +strict +exists
$x # delete $x->{a}->{b} # qr/^Reference vivification forbidden/, undef, undef # +strict +delete
$x # delete $x->{a}->{b} # '', undef, { a => { } } # +strict +store

$x->{a} = 1 # delete $x->{a} # '', 1,     { }        # +fetch
$x->{a} = 1 # delete $x->{b} # '', undef, { a => 1 } # +fetch
$x->{a} = 1 # delete $x->{a} # '', 1,     { }        # +exists
$x->{a} = 1 # delete $x->{b} # '', undef, { a => 1 } # +exists
$x->{a} = 1 # delete $x->{a} # '', 1,     { }        # +delete
$x->{a} = 1 # delete $x->{b} # '', undef, { a => 1 } # +delete
$x->{a} = 1 # delete $x->{a} # '', 1,     { }        # +store
$x->{a} = 1 # delete $x->{b} # '', undef, { a => 1 } # +store

$x->{a} = 1 # delete $x->{a} # '', 1,     { }        # +strict +fetch
$x->{a} = 1 # delete $x->{b} # '', undef, { a => 1 } # +strict +fetch
$x->{a} = 1 # delete $x->{a} # '', 1,     { }        # +strict +exists
$x->{a} = 1 # delete $x->{b} # '', undef, { a => 1 } # +strict +exists
$x->{a} = 1 # delete $x->{a} # '', 1,     { }        # +strict +delete
$x->{a} = 1 # delete $x->{b} # '', undef, { a => 1 } # +strict +delete
$x->{a} = 1 # delete $x->{a} # '', 1,     { }        # +strict +store
$x->{a} = 1 # delete $x->{b} # '', undef, { a => 1 } # +strict +store

$x->{a}->{b} = 1 # delete $x->{a}->{b} # '', 1,     { a => { } }       # +fetch
$x->{a}->{b} = 1 # delete $x->{a}->{d} # '', undef, { a => { b => 1 } }# +fetch
$x->{a}->{b} = 1 # delete $x->{c}->{d} # '', undef, { a => { b => 1 }, c => { } } # +fetch
$x->{a}->{b} = 1 # delete $x->{a}->{b} # '', 1,     { a => { } }       # +exists
$x->{a}->{b} = 1 # delete $x->{a}->{d} # '', undef, { a => { b => 1 } }# +exists
$x->{a}->{b} = 1 # delete $x->{c}->{d} # '', undef, { a => { b => 1 }, c => { } } # +exists
$x->{a}->{b} = 1 # delete $x->{a}->{b} # '', 1,     { a => { } }       # +delete
$x->{a}->{b} = 1 # delete $x->{a}->{d} # '', undef, { a => { b => 1 } }# +delete
$x->{a}->{b} = 1 # delete $x->{c}->{d} # '', undef, { a => { b => 1 } }# +delete
$x->{a}->{b} = 1 # delete $x->{a}->{b} # '', 1,     { a => { } }       # +store
$x->{a}->{b} = 1 # delete $x->{a}->{d} # '', undef, { a => { b => 1 } }# +store
$x->{a}->{b} = 1 # delete $x->{c}->{d} # '', undef, { a => { b => 1 }, c => { } } # +store

$x->{a}->{b} = 1 # delete $x->{a}->{b} # '', 1,     { a => { } }                # +strict +fetch
$x->{a}->{b} = 1 # delete $x->{a}->{d} # '', undef, { a => { b => 1 } }         # +strict +fetch
$x->{a}->{b} = 1 # delete $x->{c}->{d} # '', undef, { a => { b => 1 }, c => {} }# +strict +fetch
$x->{a}->{b} = 1 # delete $x->{a}->{b} # '', 1,     { a => { } }                # +strict +exists
$x->{a}->{b} = 1 # delete $x->{a}->{d} # '', undef, { a => { b => 1 } }         # +strict +exists
$x->{a}->{b} = 1 # delete $x->{c}->{d} # '', undef, { a => { b => 1 }, c => {} }# +strict +exists
$x->{a}->{b} = 1 # delete $x->{a}->{b} # '', 1,     { a => { } }                # +strict +delete
$x->{a}->{b} = 1 # delete $x->{a}->{d} # '', undef, { a => { b => 1 } }         # +strict +delete
$x->{a}->{b} = 1 # delete $x->{c}->{d} # qr/^Reference vivification forbidden/, undef, { a => { b => 1 } }  # +strict +delete
$x->{a}->{b} = 1 # delete $x->{a}->{b} # '', 1,     { a => { } }                # +strict +store
$x->{a}->{b} = 1 # delete $x->{a}->{d} # '', undef, { a => { b => 1 } }         # +strict +store
$x->{a}->{b} = 1 # delete $x->{c}->{d} # '', undef, { a => { b => 1 }, c => {} }# +strict +store

--- store ---

$x # $x->{a} = 1 # '', 1, { a => 1 }
$x # $x->{a} = 1 # '', 1, { a => 1 } #
$x # $x->{a} = 1 # '', 1, { a => 1 } # +fetch
$x # $x->{a} = 1 # '', 1, { a => 1 } # +exists
$x # $x->{a} = 1 # '', 1, { a => 1 } # +delete
$x # $x->{a} = 1 # qr/^Can't vivify reference/, undef, undef # +store

$x # $x->{a} = 1 # '', 1, { a => 1 } # +strict +fetch
$x # $x->{a} = 1 # '', 1, { a => 1 } # +strict +exists
$x # $x->{a} = 1 # '', 1, { a => 1 } # +strict +delete
$x # $x->{a} = 1 # qr/^Reference vivification forbidden/, undef, undef # +strict +store

$x # $x->{a}->{b} = 1 # '', 1, { a => { b => 1 } }
$x # $x->{a}->{b} = 1 # '', 1, { a => { b => 1 } } #
$x # $x->{a}->{b} = 1 # '', 1, { a => { b => 1 } } # +fetch
$x # $x->{a}->{b} = 1 # '', 1, { a => { b => 1 } } # +exists
$x # $x->{a}->{b} = 1 # '', 1, { a => { b => 1 } } # +delete
$x # $x->{a}->{b} = 1 # qr/^Can't vivify reference/, undef, undef # +store

$x # $x->{a}->{b} = 1 # '', 1, { a => { b => 1 } } # +strict +fetch
$x # $x->{a}->{b} = 1 # '', 1, { a => { b => 1 } } # +strict +exists
$x # $x->{a}->{b} = 1 # '', 1, { a => { b => 1 } } # +strict +delete
$x # $x->{a}->{b} = 1 # qr/^Reference vivification forbidden/, undef, undef # +strict +store

$x->{a} = 1 # $x->{a} = 2 # '', 2, { a => 2 }         # +fetch
$x->{a} = 1 # $x->{b} = 2 # '', 2, { a => 1, b => 2 } # +fetch
$x->{a} = 1 # $x->{a} = 2 # '', 2, { a => 2 }         # +exists
$x->{a} = 1 # $x->{b} = 2 # '', 2, { a => 1, b => 2 } # +exists
$x->{a} = 1 # $x->{a} = 2 # '', 2, { a => 2 }         # +delete
$x->{a} = 1 # $x->{b} = 2 # '', 2, { a => 1, b => 2 } # +delete
$x->{a} = 1 # $x->{a} = 2 # '', 2, { a => 2 }         # +store
$x->{a} = 1 # $x->{b} = 2 # '', 2, { a => 1, b => 2 } # +store

$x->{a} = 1 # $x->{a} = 2 # '', 2, { a => 2 }         # +strict +fetch
$x->{a} = 1 # $x->{b} = 2 # '', 2, { a => 1, b => 2 } # +strict +fetch
$x->{a} = 1 # $x->{a} = 2 # '', 2, { a => 2 }         # +strict +exists
$x->{a} = 1 # $x->{b} = 2 # '', 2, { a => 1, b => 2 } # +strict +exists
$x->{a} = 1 # $x->{a} = 2 # '', 2, { a => 2 }         # +strict +delete
$x->{a} = 1 # $x->{b} = 2 # '', 2, { a => 1, b => 2 } # +strict +delete
$x->{a} = 1 # $x->{a} = 2 # '', 2, { a => 2 }         # +strict +store
$x->{a} = 1 # $x->{b} = 2 # '', 2, { a => 1, b => 2 } # +strict +store

$x->{a}->{b} = 1 # $x->{a}->{b} = 2 # '', 2, { a => { b => 2 } }                # +fetch
$x->{a}->{b} = 1 # $x->{a}->{d} = 2 # '', 2, { a => { b => 1, d => 2 } }        # +fetch
$x->{a}->{b} = 1 # $x->{c}->{d} = 2 # '', 2, { a => { b => 1 }, c => { d => 2 } } # +fetch
$x->{a}->{b} = 1 # $x->{a}->{b} = 2 # '', 2, { a => { b => 2 } }                # +exists
$x->{a}->{b} = 1 # $x->{a}->{d} = 2 # '', 2, { a => { b => 1, d => 2 } }        # +exists
$x->{a}->{b} = 1 # $x->{c}->{d} = 2 # '', 2, { a => { b => 1 }, c => { d => 2 } } # +exists
$x->{a}->{b} = 1 # $x->{a}->{b} = 2 # '', 2, { a => { b => 2 } }                # +delete
$x->{a}->{b} = 1 # $x->{a}->{d} = 2 # '', 2, { a => { b => 1, d => 2 } }        # +delete
$x->{a}->{b} = 1 # $x->{c}->{d} = 2 # '', 2, { a => { b => 1 }, c => { d => 2 } } # +delete
$x->{a}->{b} = 1 # $x->{a}->{b} = 2 # '', 2, { a => { b => 2 } }                # +store
$x->{a}->{b} = 1 # $x->{a}->{d} = 2 # '', 2, { a => { b => 1, d => 2 } }        # +store
$x->{a}->{b} = 1 # $x->{c}->{d} = 2 # qr/^Can't vivify reference/, undef, { a => { b => 1 } } # +store

$x->{a}->{b} = 1 # $x->{a}->{b} = 2 # '', 2, { a => { b => 2 } }                # +strict +fetch
$x->{a}->{b} = 1 # $x->{a}->{d} = 2 # '', 2, { a => { b => 1, d => 2 } }        # +strict +fetch
$x->{a}->{b} = 1 # $x->{c}->{d} = 2 # '', 2, { a => { b => 1 }, c => { d => 2 } } # +strict +fetch
$x->{a}->{b} = 1 # $x->{a}->{b} = 2 # '', 2, { a => { b => 2 } }                # +strict +exists
$x->{a}->{b} = 1 # $x->{a}->{d} = 2 # '', 2, { a => { b => 1, d => 2 } }        # +strict +exists
$x->{a}->{b} = 1 # $x->{c}->{d} = 2 # '', 2, { a => { b => 1 }, c => { d => 2 } } # +strict +exists
$x->{a}->{b} = 1 # $x->{a}->{b} = 2 # '', 2, { a => { b => 2 } }                # +strict +delete
$x->{a}->{b} = 1 # $x->{a}->{d} = 2 # '', 2, { a => { b => 1, d => 2 } }        # +strict +delete
$x->{a}->{b} = 1 # $x->{c}->{d} = 2 # '', 2, { a => { b => 1 }, c => { d => 2 } } # +strict +delete
$x->{a}->{b} = 1 # $x->{a}->{b} = 2 # '', 2, { a => { b => 2 } }                # +strict +store
$x->{a}->{b} = 1 # $x->{a}->{d} = 2 # '', 2, { a => { b => 1, d => 2 } }        # +strict +store
$x->{a}->{b} = 1 # $x->{c}->{d} = 2 # qr/^Reference vivification forbidden/, undef, { a => { b => 1 } } # +strict +store
