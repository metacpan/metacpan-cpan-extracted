package Test::Extreme;

use 5.012004;
use strict;
use warnings;

use Carp;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
    assert
    assert_true
    assert_false
    assert_passed
    assert_failed
    assert_some
    assert_none
    assert_is_array
    assert_equals
    assert_contains
    assert_subset
    assert_is_array
    assert_is_hash
    assert_size
    assert_keys
    assert_is_string
    run_tests
    run_tests_as_script
);

our $VERSION = '1.01';


sub assert($) {
    if ($_[0]) { return; }
    if (defined($@)) { confess "Assertion failed.\n$@"; undef $@; } 
    else             { confess "Assertion failed.\n"; }
}

sub assert_true($)  { assert $_[0]    }
sub assert_false($) { assert ! $_[0]  }
sub assert_passed() { assert_false $@ }
sub assert_failed() { assert_true  $@ }
sub assert_some($)  { assert_true  $_[0] }
sub assert_none($)  { assert_false $_[0] }

sub assert_equals_string($$) { assert_true($_[0] eq $_[1]) }

sub assert_is_array($);

sub assert_equals_array($$) {
    my ($list0, $list1) = @_;
    assert_is_array $list0;
    assert_is_array $list1;
    assert_equals_string scalar @$list0, scalar @$list1;
    for (my $i = 0 ; $i < @$list0 ; ++$i) {
        assert_equals( $list0->[$i], $list1->[$i] );
    }
}

sub assert_equals_hash($$) {
    my ($hash0, $hash1) = @_;
    assert_equals_string scalar keys %$hash0, scalar keys %$hash1;
    for my $key (keys %{$hash0}) {
        assert_true exists $hash1->{$key};
        assert_equals($hash0->{$key}, $hash1->{$key});
    }
}

sub assert_equals($$) { 
    assert_equals_string $_[0], $_[1] if ref $_[0] eq '';
    assert_equals_array  $_[0], $_[1] if ref $_[0] eq 'ARRAY';
    assert_equals_hash   $_[0], $_[1] if ref $_[0] eq 'HASH';
}

sub assert_contains($$) {
    my ($element, $list) = @_;
    assert_equals "", ref $element;
    assert_equals "ARRAY", ref $list;
    eval { assert_true grep { $_ eq $element } @$list } ;
    if ($@) {
        my $list_text = "[" . join(" " => @$list) . "]";
        confess "Did not find $element in $list_text.\n$@" ; 
    }
}

sub assert_subset($$) {
    my ($list1, $list2) = @_;
    assert_equals "ARRAY", ref $list1;
    assert_equals "ARRAY", ref $list2;
    for my $element (@$list1) 
    { assert_contains $element, $list2 }
}

sub assert_is_array($) { assert_equals 'ARRAY', ref $_[0] }

sub assert_is_hash($)  { assert_equals 'HASH',  ref $_[0] }

sub assert_size($$) { 
    my ($size, $array) = @_;
    assert_is_array $array;
    assert_equals $size, scalar @$array
}

sub assert_keys($$) { 
    my ($keys, $hash) = @_;
    assert_is_hash  $hash;
    assert_is_array $keys;
    my @actual_keys   = sort keys %{$hash}; 
    my @expected_keys = sort @$keys;
    assert_equals \@expected_keys, \@actual_keys
}

sub assert_is_string($) { 
    my ($string) = @_;
    assert_equals '', ref $string;
    assert ($string =~ /\S/)
}

sub _list_symbols {
    use vars qw /$symbol $sym @sym %sym/;

    my $pkg = shift;
    my $prefix = shift;

    no strict 'refs';
    my  %pkg_keys = %{$pkg};
    use strict;

    my $symbols = [];
    foreach $symbol (keys %pkg_keys) {
        next if $symbol !~ /^[\:\w]+$/s;    # Skip if not-word
        my $symbol_path = $prefix . $pkg . $symbol ;
        # Need this because Perl 5.12 deprecates defined on hash
        if ($prefix eq '%') {
            push @$symbols, $symbol if eval qq[!!($symbol_path)];
        } else {
            push @$symbols, $symbol if eval qq[ defined($symbol_path) ];
        }
    }
    @$symbols = sort @$symbols;
    return $symbols;
}

sub _list_subs($)     { return _list_symbols shift, '&' }

sub _list_packages($) { 
    my $list = _list_symbols shift, '%' ;
    @$list = grep { /::$/ } @$list ;
    return $list;
}

sub _list_tests($) {
    my ($pkg) = @_;
    my $list = _list_subs $pkg;
    @$list = map { $pkg . $_ } grep { /^_*[tT]est/ } @$list ;
    return $list;
}

sub _execute_tests($$$) {
    my ($all_tests, $failure_messages, $output) = @_;
    for my $test (@$all_tests) {
        no strict 'refs';
        eval { &{$test} };
        use strict;
        if ($@) { 
            print "F" if $output;
            $failure_messages->{$test} = $@;
        } 
        else { print "." if $output }
    }
    print "\n" if $output;
}

sub _print_failure_messages($$) {
    my ($all_tests, $failure_messages) = @_;
    for my $test (sort keys %{$failure_messages}) {
        print "$test: $failure_messages->{$test}"
    }
    print "\n";
    my $test_count = scalar @$all_tests;
    my $fail_count = scalar keys %{$failure_messages};
    my $pass_count = $test_count - $fail_count;
    my $test_or_tests = $test_count == 1 ? "test" : "tests";
    if ($fail_count == 0) { 
        print "OK ($test_count $test_or_tests)\n" 
    }
    else {
        print "Failures!!!\n\n";
        print "Runs: $test_count,  Passes: $pass_count,  Fails: $fail_count\n";
    }
    print "\n";
}

sub run_tests {
    my @pkgs = map { $_ . "::" } ( 'main' , @_);
    my $all_tests = [];
    for my $pkg (@pkgs) { push @$all_tests, @{ _list_tests $pkg }; }

     my $failure_messages = {};
     _execute_tests $all_tests, $failure_messages, 1;
     _print_failure_messages $all_tests, $failure_messages;
}

sub run_tests_as_script {
    my @pkgs = map { $_ . "::" } ( 'main' , @_);
    my $all_tests = [];
    for my $pkg (@pkgs) { push @$all_tests, @{ _list_tests $pkg }; }

     my $failure_messages = {};
     _execute_tests $all_tests, $failure_messages, 0;

    print "1..", scalar @$all_tests, "\n";
    for (my $i = 0 ; $i < @$all_tests ; ++$i) {
        my $test = $all_tests->[$i];
        print "not " 
            if exists $failure_messages->{$test};
        print "ok ", 1 + $i;
        print "\n", join "\n" => 
            map { "# " . $_ ; } 
            split /\n/, $test . ": " . $failure_messages->{$test} 
                if exists $failure_messages->{$test};
        print "\n";
    }
}


#-----------------------------------------------------------------
# TESTS BEGIN
#-----------------------------------------------------------------

sub test_assert_true() {
    eval { assert_true 1 } ; assert_passed ;
    eval { assert_true 0 } ; assert_failed ;
}

sub test_assert_false() {
    eval { assert_false 1 } ; assert_failed ;
    eval { assert_false 0 } ; assert_passed ;
}

sub test_assert_some() {
    eval { assert_some 1 } ; assert_passed ;
    eval { assert_some 0 } ; assert_failed ;
}

sub test_assert_none() {
    eval { assert_none 1 } ; assert_failed ;
    eval { assert_none 0 } ; assert_passed ;
}

sub test_assert_equals() {
    eval { assert_equals 'a', 'a' } ; assert_passed ;
    eval { assert_equals 'a', 'b' } ; assert_failed ;
}

sub test_assert_equals_array() {
    eval { Test::Extreme::assert_equals_array [ 'a', 'b' ], ['a', 'b'] } ; assert_passed ;
    eval { Test::Extreme::assert_equals_array [ 'a', 'b' ], ['b', 'a'] } ; assert_failed ;

    eval { Test::Extreme::assert_equals_array [ 'a' ], ['a', 'a'] } ; assert_failed ;
    eval { Test::Extreme::assert_equals_array [ 'a', 'b' ], ['a'] } ; assert_failed ;

    eval { Test::Extreme::assert_equals_array 'a', [ 'a' ] } ; assert_failed ;
    eval { Test::Extreme::assert_equals_array [ 'a' ], 'a' } ; assert_failed ;
}

sub test_assert_equals_hash() {
    eval { Test::Extreme::assert_equals_hash { k1=>'v1', k2=>'v2' }, { k1=>'v1', k2=>'v2' } } ; assert_passed ;
    eval { Test::Extreme::assert_equals_hash { k1=>'v1', k2=>'v2' }, { k1=>'v1', k2=>'v3' } } ; assert_failed ;

    eval { Test::Extreme::assert_equals_hash { k1=>'v1', k2=>'v2' }, { k1=>'v1' } } ; assert_failed ;

    eval { Test::Extreme::assert_equals_hash { k1=>'v1', k2=>'v2' }, ['a'] } ; assert_failed ;
    eval { Test::Extreme::assert_equals_hash { k1=>'v1', k2=>'v2' },  'a'  } ; assert_failed ;
}

sub test_assert_equals_polymorphic() {
    eval { assert_equals 'a', 'a' } ; assert_passed ;

    eval { assert_equals [ 'a', 'b' ], ['a', 'b'] } ; assert_passed ;
    eval { assert_equals [ 'a', 'b' ], ['b', 'a'] } ; assert_failed ;

    eval { assert_equals { k1 => 'v1', k2 => 'v2' }, { k1 => 'v1', k2 => 'v2' } } ; assert_passed ;
    eval { assert_equals { k1 => 'v1', k2 => 'v2' }, { k1 => 'v1', k2 => 'v3' } } ; assert_failed ;
}

sub test_assert_subset() {
    eval { assert_subset [ 'a' ], ['a', 'b'] } ; assert_passed ;
    eval { assert_subset ['a', 'b'], ['a', 'b', 'c'] } ; assert_passed;
    eval { assert_subset['a', 'b'], ['a', 'b'] } ; assert_passed;

    eval { assert_subset [ 'c' ], ['a', 'b'] } ; assert_failed ;
    eval { assert_subset [ 'a', 'c' ], ['a', 'b', 'd'] } ; assert_failed ;
}

sub test_assert_contains {
    eval { assert_contains 'a', ['a', 'b'] } ; assert_passed ;
    eval { assert_contains 'b', ['a', 'b'] } ; assert_passed ;
    eval { assert_contains 'c', ['a', 'b'] } ; assert_failed ;
    eval { assert_contains  '', ['a', 'b'] } ; assert_failed ;
}

sub test_assert_is_array {
    eval { assert_is_array ['a', 'b'] } ; assert_passed ;
    eval { assert_is_array {'a', 'b'} } ; assert_failed ;
    eval { assert_is_array  'a'       } ; assert_failed ;
}
    
sub test_assert_is_hash {
    eval { assert_is_hash {'a', 'b'} } ; assert_passed ;
    eval { assert_is_hash ['a', 'b'] } ; assert_failed ;
    eval { assert_is_hash  'a'       } ; assert_failed ;
}
    
sub test_assert_size {
    eval { assert_size 2, ['a', 'b'] } ; assert_passed ;
    eval { assert_size 1, ['a']      } ; assert_passed ;
    eval { assert_size 0, []         } ; assert_passed ;

    eval { assert_size 2, {'a', 'b'} } ; assert_failed ;
    eval { assert_size 1, 'a'        } ; assert_failed ;
}
    
sub test_assert_keys {
    eval { assert_keys ['a', 'b'], { a => 1, b => 2 } } ; assert_passed ;
    eval { assert_keys ['b', 'a'], { a => 1, b => 2 } } ; assert_passed ;
    eval { assert_keys ['a'     ], { a => 1, b => 2 } } ; assert_failed ;
    eval { assert_keys ['a', 'b'], { a => 1         } } ; assert_failed ;

    eval { assert_keys ['a'], ['a'] } ; assert_failed ;
    eval { assert_keys  'a' , ['a'] } ; assert_failed ;
    eval { assert_keys ['a'],  'a'  } ; assert_failed ;
}

sub test_assert_is_string {
    eval { assert_is_string  'hello'  } ; assert_passed ;

    eval { assert_is_string ['hello', 'world'] } ; assert_failed ;
    eval { assert_is_string {'hello', 'world'} } ; assert_failed ;
}
    

package foo ; sub foo_1 { } sub foo_2 { } sub foo_3 { }
package bar ; sub bar_1 { } sub bar_2 { } sub bar_3 { }
package Test::Extreme;

sub test_list_subs {
    assert_equals [ 'foo_1', 'foo_2', 'foo_3' ], Test::Extreme::_list_subs 'main::foo::';
    assert_equals [ 'foo_1', 'foo_2', 'foo_3' ], Test::Extreme::_list_subs 'foo::';
    assert_equals [ 'bar_1', 'bar_2', 'bar_3' ], Test::Extreme::_list_subs 'bar::';
}

sub test_list_packages()
{
    my $packages = Test::Extreme::_list_packages 'main::';
    assert_subset ['foo::', 'bar::'], $packages;
    assert_none grep { ! /::$/ } @$packages;
}

package foo_test ; sub test_1 { } sub test_2 { } sub test_3 { }
package Test::Extreme;

sub test_list_tests() {
    my $list = Test::Extreme::_list_tests 'foo_test::';
    my $expected = [qw( foo_test::test_1  foo_test::test_2  foo_test::test_3 )];
    assert_equals $expected, $list;
}

sub this_will_pass { assert_true 1 }
sub this_will_fail { assert_true 0 }

sub test_execute_tests {
    my $all_tests = ['Test::Extreme::this_will_pass', 'Test::Extreme::this_will_fail'];
    my $failure_messages = { };
    Test::Extreme::_execute_tests $all_tests, $failure_messages, 0;
    assert_keys ['Test::Extreme::this_will_fail'], $failure_messages;
}

run_tests_as_script 'Test::Extreme' if $0 =~ /Extreme.pm$/;

#-----------------------------------------------------------------
# TESTS END
#-----------------------------------------------------------------

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Test::Extreme - A Perlish unit testing framework

=head1 SYNOPSIS

  # In ModuleOne.pm combine unit tests with code

  package ModuleOne;
  use Test::Extreme;
  sub foo { return 23 };
  sub test_foo { assert_equals foo, 23 }    

  # at the end of the module 

  run_tests 'ModuleOne' if $0 =~ /ModuleOne\.pm$/;

  # To run the tests in this module on the command line type

  perl ModuleOne.pm

  # If you have tests in several modules (say in ModuleOne.pm,
  # ModuleTwo.pm and ModuleThree.pm, create test.pl containing
  # precisely the following:

  use ModuleOne;
  use ModuleTwo;
  use ModuleThree;

  run_tests 'ModuleOne', 'ModuleTwo', 'ModuleThree', 

  # Then run these tests on the command line with

  perl test.pl

  # If you prefer to get Perl's classic "ok/not ok" output use
  # replace run_tests with run_tests_as_script in all of the
  # above

  # Also take a look at Test/Extreme.pm which includes its own
  # unit tests for how to instrument a module with unit tests

=head1 DESCRIPTION

Test::Extreme is a Perlish port of the xUnit testing framework. It is
in the spirit of JUnit, the unit testing framework for Java, by Kent
Beck and Erich Gamma. Instead of porting the implementation of JUnit
we have ported its spirit to Perl.

The target market for this module is Perlish people everywhere who
value laziness above all else.

Test::Extreme is especially written so that it can be easily and
concisely used from Perl programs without turning them into Java and
without inducing object-oriented nightmares in innocent Perl
programmers. It has a shallow learning curve. The goal is to adopt the
unit testing idea minus the OO cruft, and to make the world a better
place by promoting the virtues of laziness, impatience and hubris.

=head2 EXPORT

You test a given unit (a script, a module, whatever) by using
Test::Extreme, which exports the following routines into your
namespace:

  assert $x            - $x is true
  assert_true $x       - $x is true
  assert_false $x      - $x is not true
  assert_passed        - the last eval did not die ($@ eq "")
  assert_failed        - the last eval caused a die ($@ ne "")
  assert_some $x       - $x is true
  assert_none          - $x is false
  assert_equals $x, $y - recursively tests arrayrefs, hashrefs
                         and strings to ensure they have the same 
                         contents
  assert_contains $string, $list 
                       - $list contains $string assert_subset 
                         $element_list, $list - $element_list is 
                         a subset of $list (both are arrayrefs)
  assert_is_array $x   - $x is an arrayref
  assert_is_hash $x    - $x is a hashref
  assert_is_string $x  - $x is a scalar
  assert_size N, $list - the arrayref contains N elements
  assert_keys ['k1', 'k2'], $hash 
                       - $hash contains k1, k2 as keys

  run_tests_as_script  - run all tests in package main and emit
                         Perl's classic "ok/not ok" style output

  run_tests_as_script NS1, NS2, ...
                       - run all tests in package main, NS1,
                         NS2, and so on and emit Perl's classic 
                         "ok/not ok" style output

  run_tests            - run all tests in package main

  run_tests NS1, NS2, ...
                       - run all tests in package main, NS1,
                         NS2, and so on

For an example on how to use these assert take a look at
Test/Extreme.pm which includes it own unit tests and illustrates
different ways of using these asserts.

The function run_tests finds all functions that start with the word
test (preceded by zero or more underscores) and runs them one at a
time. It looks in the 'main' namespace by default and also looks in
any namespaces passed to it as arguments.

Running the tests generates a status line (a "." for every successful
test run, or an "F" for any failed test run), a summary result line
("OK" or "FAILURES!!!") and zero or more lines containing detailed
error messages for any failed tests. 

To get Perl's classic "ok/not ok" style output (which is useful for
writing test scripts) use run_tests_as_script instead of run_tests.

=head1 SEE ALSO

See also “JUnit Cookbook” by Kent Beck, Erich Gamma F<http://junit.sourceforge.net/doc/cookbook/cookbook.htm> for examples of how to write small unit tests around your code, and for the philosophy of test-driven development.

=head1 AUTHOR

Asim Jalis E<lt>asimjalis@gmail.comE<gt>. Special thanks to F<http://metaprose.com> for giving me the free time to work on this.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2012 by Asim Jalis E<lt>asimjalis@gmail.comE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

See F<http://www.perl.com/perl/misc/Artistic.html>.

=cut
