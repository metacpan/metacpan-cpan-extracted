package Test::Lite;

$Test::Lite::VERSION = '0.009';
$Test::Lite::DieOnSyntaxError = 0;

=head1 NAME

Test::Lite - A small Perl Test Library

=head1 DESCRIPTION

Test::Lite is just that. A minimal test library based on the brilliant L<Test::Builder>. The main focus of this project 
was to learn more about testing while building this module. A pretty overlooked subject amongst some Perl developers is testing (myself included). 
I've tried to offer some different features in this module, but you're probably still better off with L<Test::More>, L<Test::Most> or one of the many other 
testing libraries out there.

=head1 SYNOPSIS

Using Test::Lite is pretty similar to other test modules (Why break tradition, eh?)

    use Test::Lite;

    my $a = { name => 'World' };
    my $b = { name => 'Worlds' };
    
    diff ($a, $b, "Difference between hash 'a' and hash 'b'");

    my @non_ref qw(not a ref);
    my $true_ref = [1, 2, 3];
    is_ref(@non_ref, 'Name of test');
    is_ref($true_ref => 'HASH', 'Name of test'); # Checks to see if $true_ref returns a HASH

    use_ok [qw( A::Module Another::Module )];

=cut

use strict;
use warnings;

use 5.010;
use Scalar::Util 'looks_like_number';
use Sub::Mage ':Class';
extends 'Test::Builder::Module';

my $CLASS = __PACKAGE__;

sub import {
    my ($class, @args) = @_;
    my $pkg = caller(1);
    for (@args) {
        if ($_ eq ':strict') {
            warnings->import;
            strict->import;
        }
    }
    $CLASS->_export_defs(qw/
        is
        ok
        has_key
        cmp_ok
        diff
        diag
        plan 
        use_ok
        can_ok
        isa_ok
        is_ref
        like
        explain
        extended
        methods
        subtest
        todo_start
        todo_end
        is_passing
        count
        note
        level
        finfo
        done_testing
    /);
}

sub _export_defs {
    my ($self, @defs) = @_;
    my $pkg = caller(1);
    for (@defs) {
        exports $_ => ( into => $pkg );
    }
}

sub dieonsyntax { return $Test::Lite::DieOnSyntaxError; }

sub ok {
    my ($val, $name) = @_;
    my $tb = $CLASS->builder;
    $tb->ok(@_);
}

sub cmp_ok {
    my ($a, $type, $b, $name) = @_;
    my $tb = $CLASS->builder;
    $tb->cmp_ok(@_);
}

sub is {
    my ($a, $b, $args, $name) = @_;
    my $tb = $CLASS->builder;
    if (scalar keys %$args < 1) {
        if (looks_like_number($b)) { $tb->is_num($a, $b, $name); }
        else { $tb->is_eq($a, $b, $name); }
    }
    else {
        my $type;
        my $skip;
        for (keys %$args) {
            $type = $args->{type}
                if $_ eq 'type';
            $skip = $args->{skip}
                if $_ eq 'skip';
        }
        
        if ($type eq 'Int') {
            if (! looks_like_number($b)) {
                my $err = "Type for this test is set to 'Int', but a numeric character was not being tested for";
                if ($skip) {
                    $tb->skip($err);
                }
                else { say "not ok " . $tb->current_test() . " - $err"; }
            }
            else { $tb->is_num($a, $b, $name); }
        }
        elsif ($type eq 'Str') {
            if (looks_like_number($b)) {
                my $err = "Type for this test is set to 'Str', but a numeric character entered as a value";
                if ($skip) {
                    $tb->skip($err);
                }
                else {
                    say "not ok " . $tb->current_test() . " - $err";
                }
            }
            else { $tb->is_eq($a, $b, $name); }
        }
    }
}

sub extended {
    my ($mother, @base) = @_;
    my $tb = $CLASS->builder;
    my $test = $tb->current_test();
    my @extends;
    no strict 'refs';
    my $mom = $mother;
    $mother = "$mother\::";
    for my $child (@base) {
        foreach my $key (keys %{$mother}) {
            if (substr($key, -2, -1) eq ':') {
                push @extends, substr("$mother$key", 0, -2);
            }
        }
    }
    $mother = "";
    for $mother (@extends) {
        DEEP_SEARCH: foreach my $key (keys %{"$mother\::"}) {
            if (substr($key, -2, -1) eq ':') {
                push @extends, "$mother\::" . substr("$key", 0, -2);
            }
            if (scalar keys %{$key} > 0) {
                $mother = "$mother$key";
                next DEEP_SEARCH;
            }
        }
    }
    if (scalar @extends > 0) {
        for my $extend (@base) {
            if (! grep { $_ eq $extend } @extends) {
                $tb->ok(0, "$mom does not extend $extend");
                return 1;
            }
        }
        $tb->ok(1, "$mom extends " . join(q{, }, @base));
        return 0;
    }
    else {
        $tb->skip("No extends found in $mom, so let's move on");
        return 0;
    }
}

sub use_ok {
    my ($use, $imports) = @_;
    my $tb = $CLASS->builder;
    my $test = $tb->current_test();
    my $pkg = caller();
    if (ref($use) eq 'ARRAY') {
        my @failed;
        $tb->subtest( 'Use multiple modules', sub {
            for (@$use) {
                eval qq{package $pkg;
                    use $_;
                    1;
                };
                $tb->unlike( $@, qr/Can't locate/, "use $_");
            }
        });
    }
    else {
        if (ref($imports) eq 'ARRAY') {
            my $imps = join "\n", @$imports;
            eval qq{package $pkg;
                use $use qw/$imps/;
                1;
            };
        }
        else {
            eval qq{package $pkg;
                use $use;
                1;
            };
        }
        if ($@) { say "not ok $test - Could not 'use $use'"; return 1 }
        else { $tb->ok( $use, "use $use" ); }
    }
}

sub like {
    my ($this, $like, $name) = @_;
    my $tb = $CLASS->builder;
    my $test = $tb->current_test;
    if (ref($like) ne 'Regexp') {
        my $err = "Second paremeter must be a Regex";
        if ($CLASS->dieonsyntax) { say "not ok $test - $err"; } 
        else { $tb->skip($err); }
        return 1;
    }
    
    $tb->like(@_);
}

sub unlike {
    my ($this, $unlike, $name) = @_;
    my $tb = $CLASS->builder;
    my $test = $tb->current_test;
    if (ref($unlike) ne 'Regexp') {
        my $err = "Second paremeter must be a Regex";
        if ($CLASS->dieonsyntax) { say "not ok $test - $err"; }
        else { $tb->skip($err); }
        return 1;
    }

    $tb->like(@_);
}

sub diff {
    my ($a, $b, $name) = @_;
    my $tb = $CLASS->builder;
    my $test = $tb->current_test;
    if (! ref($a) || ! ref($b)) {
        my $err = "diff expects ArrayRef or HashRef only";
        if ($CLASS->dieonsyntax) { say "not ok $test - $err"; }
        else { $tb->skip($err); }
        return 1;
    }

    $tb->is_eq($tb->explain($a), $tb->explain($b), $name);
}

sub can_ok {
    my ($module, @methods) = @_;
    my $tb = $CLASS->builder;

    my $test = $tb->current_test;
    my $name = "Checking methods in $module";
    $tb->subtest( $name, sub {
        for (@methods) {
            $tb->ok($module->can($_), "$module has method $_");
        }
    });
}

sub is_ref {
    my ($var, $type, $name) = @_;
    my $tb = $CLASS->builder;
    my $test = $tb->current_test;
    my $num = scalar @_;
    my $err = "No ref type found";
    if ($num == 1) {
        # var only
        if (! ref($var)) {
            say "not ok $test - $err";
            return 1;
        }
        
        $tb->ok($var);
    }
    elsif ($num == 2) {
        # var with name
        if (! ref($var)) {
            say "not ok $test - $err";
            return 1;
        }
        
        $tb->ok($var, $type);
        
    }
    elsif ($num == 3) {
        if (! ref($var)) {
            say "not ok $test - $err";
            return 1;
        }
        if (ref($var) ne uc($type)) {
            say "not ok $test - Not of the same ref type";
            return 1;
        }

        $tb->ok(ref($var), $name);
    }
}

sub isa_ok {
    my ($object, $class, $name) = @_;
    my $tb = $CLASS->builder;
    return $tb->ok( defined $object && $object->isa($class), $name );
}

sub todo_start {
    my ($message) = @_;
    my $tb = $CLASS->builder;
    return $tb->todo_start($message);
}

sub todo_end {
    my ($message) = @_;
    my $tb = $CLASS->builder;
    return $tb->todo_end($message);
}

sub explain {
    my ($a) = @_;
    my $tb = $CLASS->builder;
    $tb->explain($a);
}

sub diag {
    my ($msg) = @_;
    my $tb = $CLASS->builder;

    $tb->diag($msg);
}

sub methods {
    my $class = shift;
    my $tb = $CLASS->builder;
    no strict 'refs';
    if (scalar keys %{"$class\::"} < 1) {
        $tb->explain("methods(): Attempted method list on $class, but $class doesn't exist");
        return 1;
    }
    my @m;
    for (keys %{"$class\::"}) {
        if (substr($_, -2, -1) eq ':') { push @m, "-> extends $_"; }
        else { push @m, $_; }
    }
    return join "\n", @m;
}

sub subtest {
    my ($name, $subtest) = @_;
    my $tb = $CLASS->builder;
    $tb->subtest($name, $subtest);
}

sub deep_keys {
    my ($self, $hashref, $code, $args) = @_;
    while (my ($k, $v) = each(%$hashref)) {
        my @newargs = defined($args) ? @$args : ();
        push(@newargs, $k);
        if (ref($v) eq 'HASH') {
            $CLASS->deep_keys($v, $code, \@newargs);
        }
        else {
            $code->(@newargs);
        }
    }
}

sub has_key {
    my ($refvar, $key, $name) = @_;
    my $tb = $CLASS->builder;
    if (! ref($refvar)) {
        $tb->skip('First parameter must be reference');
        return 1;
    }
    
    if (ref($refvar) eq 'HASH') {
        my $match = 0;
        $CLASS->deep_keys($refvar, sub {
            $match = 1
                if grep { $_ eq $key } @_;
        });

        if ($match) { $tb->ok(1, $name); }
        else { $tb->ok(0, $name); }
    }
    elsif (ref($refvar) eq 'ARRAY') {
        if ( grep { $_ eq $key } @$refvar ) {
            $tb->ok(1, $name);
        }
        else {
            $tb->ok(0, $name);
        }
    }
}

sub plan {
    my $tb = $CLASS->builder;
    $tb->plan(@_);
}

sub is_passing {
    my $tb = $CLASS->builder;
    $tb->is_passing;
}

sub level {
    my $tb = $CLASS->builder;
    $tb->level(@_);
}

sub finfo {
    my $tb = $CLASS->builder;
    $tb->caller(@_);
}

sub note {
    my $tb = $CLASS->builder;
    $tb->note(@_);
}

sub count {
    my ($v, $c, $name) = @_;
    my $tb = $CLASS->builder;
    if (! ref($v)) {
        $CLASS->syntax_fail( "count(): First parameter must be a reference" );
        return 1;
    }
    else {
        if (! looks_like_number($c)) {
            $CLASS->syntax_fail( "Can't match against a non-numeric value" );
            return 1;
        }
       
        if (ref($v) eq 'ARRAY') {
            my $num = scalar @$v;
            if ($num != $c) { $CLASS->fail($name||"count(): Number of elements do not match"); }
            else { $tb->ok(1, $name||"count(): Number of elements match"); }
        }
        elsif (ref($v) eq 'HASH') {
            my $num = scalar keys %$v;
            if ($num != $c) { $CLASS->fail($name||"count(): Number of keys do not mach"); }
            else { $tb->ok(1, $name||"count(): Number of keys match"); }
        }
    }
}

sub fail {
    my ($self, $message) = @_;
    my $tb = $CLASS->builder;
    $tb->ok(0, $message);
}

sub syntax_fail {
    my ($self, $message) = @_;
    my $tb = $CLASS->builder;
    if ($self->dieonsyntax) { $tb->ok(0, $message); }
    else { $tb->skip($message); }
}

sub done_testing {
    my ($num) = @_;
    my $tb = $CLASS->builder;
    
    $tb->finalize();
    $tb->done_testing($num);
}

=head1 TESTS

=head2 is

    is ( $a, $b, {}, 'Name of test');

Does C<$a> equal C<$b>? This particular test can match integers or strings.
Third parameter takes a hashref. Using this hashref you can make the test a little 
more 'strict' by setting a type to check for.

    my $a = 1;
    my $b = 'one';
    
    is ($a, $b, { type => 'Int' });
    
The above will fail because it expects an integer, but C<$b> is a string.

=head2 ok

    my $test = "World";
    my $pass = 0;

    ok ( $test, $name ); # passes
    ok ( $pass ); # fails

Checks that the first parameter returns C<true>. If not, it will fail.

=head2 cmp_ok

Evaluates the parameters using the operator specified as the second parameter.

    cmp_ok ( 'this', 'eq', 'that', 'Test Name' );
    cmp_ok ( 1, '==', 2, 'Test Name' );

=head2 like

    like( 'Hello, World!', qr/Hello/, 'Test Name');

Searches the first parameter for the regex specified in the second. If it's found it will pass the test.

=head2 unlike

Similar to C<like>, but the opposite.

=head2 diff

Checks the values of two references (HashRef or ArrayRef). If any are different the test will fail and you'll be able to see 
the output of what C<diff> was expecting, and what it actually got

    my $a = { foo => 'bar' };
    my $b = { baz => 'foo' };
    
    diff $a, $b, 'Test name'; # fail

    my $ary = [1, 2, 3];
    my $ary2 = [1, 2, 3];
    
    diff $ary, $ary2, 'Test name'; # pass

=head2 can_ok

Finds out whether the specified module can call on certain methods.

    can_ok 'Foo' => qw/ this that them who what /;

=head2 isa_ok

Tests to see if the specified object returns the right class

    my $ob = Foo->new;
    isa_ok $ob, 'Foo', 'Test Name';

=head2 diag

Pretty much the same as other Test libraries. Returns output that won't interrupt your tests.

    diag 'Boo!';

=head2 methods

Returns a string listing all the methods callable by a module.

    can_ok( Foo => ['test'] ) or diag methods('Foo');

=head2 explain

Returns a dump of an object (like a hash/arrayref).

    my $hash = {
        a => 1,
        b => 'foo',
        c => 'baz'
    };
    diag explain $hash;

Will return

    # {
    #   'a' => 1,
    #   'b' => 'foo',
    #   'c' => 'baz'
    # }

=head2 use_ok

Attempts to use the module given, or multiple modules if an arrayref is provided

    use_ok 'Foo';
    use_ok [qw( Foo Foo::Bar Baz )];

=head2 todo_start

Signifies the beginning of todo tests

    todo_start("Starting todo tests");
    # ...
    
=head2 todo_end

The end of the todo tests. Don't forget to call when you've finished your todo tests.

    todo_end("Finished todo tests");
    todo_end();

=head2 is_ref

Checks to see if the value given is a true reference. You can go one step further and prove a reference type 
to check against.

    my @non_ref qw(not a ref);
    my $true_ref = [1, 2, 3];
    
    is_ref(@non_ref, 'Name of test');
    is_ref($true_ref => 'HASH', 'Name of test'); # Checks to see if $true_ref returns a HASH

=head2 subtest

Create subtests within a test.

    use Test::Lite;

    use_ok 'Some::Module';
    
    subtest 'My test name' => sub {
        ok ref({}), 'HASH' => 'Reference type is hash';
    };

    subtest 'Another subtest' => sub {
        my $ob = Some::Module->new;
        isa_ok( $ob, 'Some::Module' => 'Matching class with object' );
    };

=head2 has_key

Searches an ArrayRef or HashRef (deeply) for a specific element or key.

    my $hash = {
        name => 'World',
        foo  => 'baz',
        berry => {
            fruit => {
                melon => 'Yum!',
            },
        },
    };

    has_key $hash, 'melon' => 'Found melon!';

    my $ary = [qw(this that there where who what)];

    has_key $ary, 'there' => 'Found "there" in arrayref'; 

=head2 plan

Declare how many tests you are going to run. This is not needed if you have included C<done_testing>

    use Test::Lite;

    plan tests => 2;
    plan 'no_plan';
    plan skip_all => 'reason';

=head2 is_passing

Detects whether the current test suite is passing.

    is_passing or diag "Uh-Oh. We're currently failing the test..."

=head2 note

Just prints text to output(), so it should only be displayed in verbose mode.

    note 'Some note to describe stuff';

=head2 count

Counts the number of keys from a hashref, or elements from an arrayref and matches them against the expected value.

    my $h = {
        foo => 'bar',
        baz => 'foo'
    };
    count $h, 2 => 'Expecting 2 keys in hash';

    my $a = [1, 2, 3, 4];
    count $a, $a->[3] => "Expecting $a->[3] elements from array";

=head2 extended

Searches the module deeply for extended modules. ie: When you C<use base 'Module'> or C<extends> in most OOP frameworks. 

    package Foo;
    
    use base qw/
        Foo::Baz
        Foo::Baz::Foobar
        Foo::Baz::Foobar::Frag
    /;
    
    1;

    # t/01-extends.t

    use Test::Lite;
    
    use_ok 'Foo';
    extended 'Foo' => qw/
        Foo::Baz
        Foo::Baz::Foobar::Frag
    /;
    
    done_testing;

=head1 AUTHOR

Brad Haywood <brad@geeksware.net>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
