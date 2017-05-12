# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Test::TableDriven;
use strict;
use warnings;
use Test::More;
use Data::Dumper; # always wanted to intentionally ship this.

our $VERSION = '0.02';

my %tests;

sub import {
    my $class = shift;
    my ($caller) = caller;
    %tests = @_;

    no strict 'refs'; # strict refs are for losers!
    *{"${caller}::runtests"} = \&runtests;
}

sub runtests() {
    my ($caller) = caller;
    my %code;

    # verify that the tests are callable
    foreach my $sub (keys %tests) {
        no strict 'refs';
        $code{$sub} = *{$caller. '::'. $sub}{CODE} or
          die "cannot find a sub in '$caller' to call for '$sub' tests";
    }
    
    # parse the tests, pushing a closure that runs one test onto @todo
    my @todo;
    foreach my $test (keys %tests) {
        my $cases = $tests{$test};
        my $t     = sub { 
            my @a = @_; 
            push @todo, sub { _run_test($code{$test}, $test, @a) };
        };
        
        my $do = { HASH  => sub {
                       $t->($_, $cases->{$_}) for keys %{$cases};
                   },
                   ARRAY => sub {
                       $t->($_->[0], $_->[1]) for @{$cases};
                   },
                 };
        eval {
            $do->{ref $cases}->();
        };
        die "I don't know how to run the tests under key '$test'" if $@;
    }
    
    # now run the tests
    plan tests => scalar @todo;
    $_->() for @todo;
    
    return; # returns nothing
}

sub _run_test {
    my ($code, $test, $in, $expected) = @_;
    no warnings 'uninitialized';
    
    # run a test
    my $got = $code->($in);  # call the user's code
    if (ref $expected || ref $got)  {
        my $i = Dumper($in);
        my $g = Dumper($got);
        my $e = Dumper($expected);
        do { s/\$VAR\d+\s=\s?//; s/\n//g; s/\s+/ /g; s/;//g } for ($i,$g,$e);

        # compare refs
        is_deeply($got, $expected, "$test: $i => $e (is $g)");
    }
    else {
        # compare strings
        do { $_ = 'undef' unless defined $_ } for ($got, $expected);
        is($got, $expected, "$test: $in => $expected (is $got)"); 
    }
    
    return;
}

1;
__END__

=head1 NAME

Test::TableDriven - write tests, not scripts that run them

=head1 SYNOPSIS

   use A::Module qw/or two!/;
   use Test::TableDriven (
     foo => { input   => 'expected output',
              another => 'test',
            },

     bar => [[some => 'more tests'],
             [that => 'run in order'],
             [refs => [qw/also work/]],
             [[qw/this is also possible/] => { and => 'it works' }],
            ],
   );

   runtests;
     
   sub foo {
      my $in  = shift;
      my $out = ...;
      return $out;
   }    

   sub bar { same as foo }

=head1 DESCRIPTION

Writing table-driven tests is usually a good idea.  Adding a test case
doesn't require adding code, so it's easy to avoid fucking up the
other tests.  However, actually going from a table of tests to a test
that runs is non-trivial.

C<Test::TableDriven> makes writing the test drivers trivial.  You
simply define your test cases and write a function that turns the
input data into output data to compare against.  C<Test::TableDriven>
will compute how many tests need to be run, and then run the tests.

Concentrate on your data and what you're testing, not C<plan tests =>
scalar keys %test_cases> and a big foreach loop.

=head1 WHAT DO I DO

Start by using the modules that you need for your tests:

   use strict;
   use warnings;
   use String::Length; # the module you're testing

Then write some code to test the module:

   sub strlen {
       my $in  = shift;
       my $out = String::Length->strlen($in);
       return $out;
   }

This C<strlen> function will accept a test case (as C<$in>) and turns
it into something to compare against your test cases:

Oh yeah, you need some test cases:

   use Test::TableDriven (
       strlen => { foo => 3,
                   bar => 3,
                   ...,
                 },
   );

And you'll want those test to run somehow:

   runtests;

Now execute the test file.  The output will look like:

   1..2
   ok 1 - strlen: bar => 3
   ok 2 - strlen: foo => 3

Add another test case:

       strlen => { foo  => 3,
                   bar  => 3,
                   quux => 4,
                   ...,
                 },

And your test still works:

   1..3
   ok 1 - strlen: bar => 3
   ok 2 - strlen: quux => 4
   ok 3 - strlen: foo => 3

Yay.

=head1 DETAILS

I'm not in a prose-generation mood right now, so here's a list of
things to keep in mind:

=over 4

=item *

Don't forget to C<runtests>.  Just loading the module doesn't do a
whole lot.

=item *  

If a subtest is not a subroutine name in the current package, runtests
will die.

=item *  

If a subtest definition is a hashref, the tests won't be run in order.
If it's an arrayref of arrayrefs, then the tests are run in order.

=item *  

If a test case "expects" a reference, C<is_deeply> is used to compare
the expected result and what your test returned.  If it's just a
string, C<is> is used.

=item *  

Feel free to use C<Test::More::diag> and friends, if you like.

=item *  

Don't print to STDOUT.

=item * 

Especially don't print TAP to STDOUT :)

=back

=head1 EXPORT

=head2 runtests

Run the tests.  Only call this once.

=head1 BUGS

Report them to RT, or patch them against the git repository at:

   git clone git://git.jrock.us/Test-TableDriven

(or L<http://git.jrock.us/>).

=head1 AUTHOR

Jonathan Rockway C<< <jrockway AT cpan.org> >>.

=head1 COPYRIGHT

This module is copyright (c) 2007 Jonathan Rockway.  You may use,
modify, and redistribute it under the same terms as Perl itself.
