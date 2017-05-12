#!perl -Tw

use warnings;
use strict;
use Test::More tests => 7;

BEGIN {
    use_ok( 'WWW::Scripter' );
}

my $mech = WWW::Scripter->new();
isa_ok( $mech, 'WWW::Scripter' );

{ package _::Clonable;
    sub init { bless \(my $x = '') }
    sub clone {
        my $clone = bless \(my $x = ${+shift});
        $$clone .= 'clone' . shift;
        $clone;
    }
}

{ package _::PlainObject;
    sub init {
        bless []
    }
}

{ package _::True;
    sub init { ++our $count; 1 }
}

{ package _::False;
    sub init { ++our $count; 0 }
}

++$INC{"_/$_.pm"},$mech->use_plugin("_::$_")
    for qw/ False Clonable PlainObject True /;
my $wclone = $mech->clone;

is ${$mech->plugin('_::Clonable')}, '',
	'plugin with clone method (original)';
is ${$wclone->plugin('_::Clonable')}, 'clone' . $wclone,
	'plugin with clone method (clone)';
is $mech->plugin('_::PlainObject'), $wclone->plugin('_::PlainObject'),
    'plugin object without clone method';
is $_::True::count, 1, 'no cloning for true non-object';
is $_::False::count, 1, 'no cloning for false non-object';
