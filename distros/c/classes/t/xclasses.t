# $Id: xclasses.t 140 2006-09-26 09:23:29Z rmuhle $

use strict;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => "Test::Exception needed";
} else {
    plan tests => 31;
}

use_ok 'classes';
use_ok 'classes::Test' ,':all';

# SINGLE FORM

lives_ok( sub {
    classes::define(exceptions => 'X::Single1')
}, 'single form exceptions');

for my $n (1) {
    my $x = undef;  
    my $class = "X::Single$n";
    throws_ok( sub {$class->throw}, $class);
    ok $x = $class->new, "new $class";
    is_classes_exc($x);
}

# ARRAY FORM

lives_ok( sub {
    classes::define(exceptions => ['X::Array1', 'X::Array2' ])
}, 'array form exceptions');

for my $n (1 .. 2) {
    my $x = undef;  
    my $class = "X::Array$n";
    throws_ok( sub {$class->throw}, $class);
    ok $x = $class->new, "new $class";
    is_classes_exc($x);
}
__END__

# HASH FORM

lives_ok( sub {
     use classes exceptions => {
        'X::Hash1'=>{extends=>'X::classes', attrs=>['file1']},
        'X::Hash2'=>{extends=>'X::classes', attrs=>['file2']},
    }
}, 'hash form - exceptions');

lives_ok( sub {
    use classes -excs => {
        'X::Hash3'=>{extends=>'X::classes', attrs=>['file3']},
        'X::Hash4'=>{extends=>'X::classes', attrs=>['file4']},
    }
}, 'hash form - excs');

for my $n (1 .. 4) {
    my $x = undef;  
    my $class = "X::Hash$n";
    throws_ok( sub {$class->throw}, $class);
    ok $x = $class->new, "new $class";
    is_classes_exc($x);
}

# CAUGHT/CATCH, RETHROW/SEND
#diag "testing that caught exceptions are actually";
#diag "blessed objects from class that threw them";
#diag "and that they can be thrown again with rethrow";

TYPE:
for my $t ( 'Single', 'Array', 'Hash' ) {
    for my $n (1 .. 7) {
        my $class = "X::$t$n";
        no strict 'refs';
        next TYPE if !%{$class.'::'}; # has symbols

        # throw and exception - regular usage
        # refaddr otherwise 'as_string' will cause false match
        eval { $class->throw };
        my $c1 = $class->catch;
        my $c2 = $class->caught;
        is $c1->classes::id, $c2->classes::id,
            'catch and caught trapping same';
        isa_ok $c1, $class;
        undef $@;

        # rethrow same exception, not copy
        eval { $c1->rethrow };
        my $c3 = $class->catch;
        my $c4 = $class->caught;
        is $c3->classes::id, $c4->classes::id,
            'catch and caught trapping same';
        isa_ok $c3, $class;
        is $c1->classes::id, $c3->classes::id,
            'thrown and rethrown same, not copies';
        undef $@;

        # send is just synonym for rethrow
        eval { $c1->send };
        my $cc3 = $class->catch;
        my $cc4 = $class->caught;
        is $cc3->classes::id, $cc4->classes::id,
            'catch and caught trapping same';
        isa_ok $cc3, $class;
        is $c1->classes::id, $cc3->classes::id,
            'thrown and send same, not copies';
        undef $@;
    }
}

# BAD USAGE

throws_ok( sub { classes::define -exc => 'X::Bad' },
    'X::classes::Usage',
    'throws X::Usage - missing s in excs');
throws_ok( sub { classes::define -excs => {'X::Bad' => [] } },
    'X::classes::Usage',
    'throws X::Usage - long form - ref type');
throws_ok( sub { classes::define -excs => {'X::Bad' => undef } },
    'X::classes::Usage', 'throws X::Usage - ong form - undef');

# BAD NAMES (rest tested in ok.t)

throws_ok( sub { classes::define -excs => '' },
    'X::classes::InvalidName',
    'throws X::classes::InvalidName - single form - empty name');
throws_ok( sub { classes::define -excs => '1x' },
    'X::classes::InvalidName',
    'throws X::classes::InvalidName - single form - bad name');
throws_ok( sub { classes::define -excs => ['good', '' ] },
    'X::classes::InvalidName',
    'throws X::classes::InvalidName - array form - empty name');
