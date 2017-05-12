package Test::ManyParams;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw/
    all_ok	
    all_are all_arent
    any_ok
    any_is any_isnt
    
    most_ok
    
    set_seed
/;

our $VERSION = '0.10';

use Test::Builder;
use Set::CrossProduct;
use Data::Dumper;
our $seed;

my $Tester = Test::Builder->new();

sub does_all {
    my ($sub, $params) = @_;
    my $failed_param = undef;
    if (ref($params->[0]) eq 'ARRAY') {
        if (grep {ref($params->[$_]) ne 'ARRAY'} (1 .. @$params-1)) {
            die "If the first parameter is an arrayref, all other parameters must be also. " .
                "Called with Parameter-Ref: " . _dump_params($params);
        }
        $failed_param = @$params > 1
            ? _try_all_of_xproduct($sub, Set::CrossProduct->new( $params ))
            : _try_all_of_the_list($sub, @{$params->[0]});
    } else {
        $failed_param = _try_all_of_the_list($sub, @$params);
    }
    my $ok = not defined($failed_param);
    my @diag = $ok 
        ? () 
        : ("Tests with the parameters: " . _dump_params($params),
           "Failed first using these parameters: " . _dump_params($failed_param));
    return ($ok, @diag);
}

sub does_most {
    my ($sub, $params, $nr) = @_;
    my $failed_param = undef;
    $nr =~ /^\d+$/ or die "The number of tests that shall be done must be an integer, not '$nr'";
    if (ref($params->[0]) eq 'ARRAY') {
        if (grep {ref($params->[$_]) ne 'ARRAY'} (1 .. @$params-1)) {
            die "If the first parameter is an arrayref, all other parameters must be also. " .
                "Called with Parameter-Ref: " . _dump_params($params);
        }
        $failed_param = @$params > 1
            ? _try_most_of_xproduct($sub,$nr, Set::CrossProduct->new( $params ))
            : _try_most_of_the_list($sub,$nr, @{$params->[0]});
    } else {
        $failed_param = _try_most_of_the_list($sub,$nr, @$params);
    }
    my $ok = not defined($failed_param);
    my @diag = $ok 
        ? () 
        : ("Tests with most ($nr) of the parameters: " . _dump_params($params),
           "Failed using these parameters: " . _dump_params($failed_param));
    return ($ok, @diag);
}


sub all_ok(&$;$) {
    my ($sub, $params, $test_name) = @_;
    my ($ok, @diag) = does_all(@_);
    $Tester->ok( $ok, $test_name ) or do { $Tester->diag($_) for @diag };
    return $ok;
}

sub most_ok(&$$;$) {
    my ($sub, $params, $nr, $test_name) = @_;
    my ($ok, @diag) = does_most(@_);
    $Tester->ok( $ok, $test_name ) or do { $Tester->diag($_) for @diag };
    return $ok;
}


sub any_ok(&$;$) {
    my ($sub, $params, $test_name) = @_;
    
    # Please recognise the logic
    # To find out if any of the tests is O.K.,
    # I ask whether all tests fail
    # If so there isn't any_ok, otherwise there is at least one ok
    my ($all_arent_ok) = does_all(sub {!$sub->(@_)}, $params, $test_name);
    my $ok = !$all_arent_ok;
    $Tester->ok( $ok, $test_name );
    return $ok;
}

sub any_is(&$$;$) {
    my ($sub, $expected_value, $params, $test_name) = @_;
    my ($all_arent_ok, @diag) = 
        does_all(sub {!($sub->(@_) eq $expected_value)}, $params, $test_name);
    my $ok = !$all_arent_ok;
    $Tester->ok( $ok, $test_name)
    or do {
        $Tester->diag($_) for @diag;
        $Tester->diag("Expected: " . _dump_params($expected_value));
        $Tester->diag("but didn't found it with at least one parameter");
    };
}

sub any_isnt(&$$;$) {
    my ($sub, $expected_value, $params, $test_name) = @_;
    my ($all_arent_ok, @diag) = 
        does_all(sub {!($sub->(@_) ne $expected_value)}, $params, $test_name);
    my $ok = !$all_arent_ok;
    $Tester->ok( $ok, $test_name)
    or do {
        $Tester->diag($_) for @diag;
        $Tester->diag("Expected to find any parameter where result is different to " . _dump_params($expected_value));
        $Tester->diag("but didn't found such parameters");
    };
}

sub all_are(&$$;$) {
    my ($sub, $expected, $params, $test_name) = @_;
    my $found = undef;
    my ($ok, @diag) = 
        does_all( sub { $found = $sub->(@_); $found eq $expected }, $params);
    $Tester->ok($ok, $test_name)
    or do {
        $Tester->diag($_) for @diag;
        $Tester->diag("Expected: " . _dump_params($expected));
        $Tester->diag("but found: " . _dump_params($found));
    };
}

sub all_arent(&$$;$) {
    my ($sub, $unexpected, $params, $test_name) = @_;
    my $found = undef;
    my ($ok, @diag) = 
        does_all( sub { $found = $sub->(@_); $found ne $unexpected }, $params);
    $Tester->ok($ok, $test_name)
    or do {
        $Tester->diag($_) for @diag;
        $Tester->diag("Expected not to find " . _dump_params($unexpected) . " but found it");
    };
}

sub _try_all_of_the_list {
    my ($sub, @param) = @_;
    foreach my $p (@param) {
        local $_ = $p;
        $sub->($_) or return [$_];
    }
    return undef;
}

sub _try_most_of_the_list {
    my ($sub,$nr,@param) = @_;
    while ($nr-- > 0) {
        local $_ = $param[rand @param];
        $sub->($_) or return [$_];
    }
    return undef;
}


sub _try_all_of_xproduct {
    my ($sub, $iterator) = @_;
    my $tuple = undef;
    while ($tuple = $iterator->get()) {
        $sub->(@$tuple) or last;
    }
    return $tuple;
}

sub _try_most_of_xproduct {
    my ($sub, $nr, $iterator) = @_;
    while ($nr-- > 0) {
        my $tuple = $iterator->random;
        $sub->(@$tuple) or return $tuple;
    }
    return undef;
}

sub _dump_params {
    local $_ = Dumper($_[0]);
    s/\s+//gs;   # remove all indents, but I didn't want to set 
                 # $Data::Dumper::Indent as it could have global effects
    s/^.*? = //; # remove the variable name of the dumped output
    return $_;
}

sub import {
    my @import_arg;
    my $seed_now = time ^ $$;               # default value for the seed
    while (local $_ = shift @_) {
            /seed/    && do { $seed_now = shift(); 
                              $seed_now =~ /^\d+$/ or die "The seed must be an integer";
                            }
        or  "DEFAULT" && push @import_arg, $_;
    }
    srand($seed_now);
    #Readonly::Scalar $seed => $seed_now;
    $seed = $seed_now;
    Test::ManyParams->export_to_level(1, @import_arg);
}

1;

__END__
=head1 NAME

Test::ManyParams - module to test many params as one test

=head1 SYNOPSIS

  use Test::ManyParams;

  all_ok {foo(@_)}  
         [ [$arg1a, $arg2a], [$arg2b, $arg2b, $arg3b, $arg4b] ],
         "Testing that foo returns true for every combination of the arguments";
         
  all_ok {bar(shift())}
         [qw/arg1 arg2 arg3 arg4 arg5 arg6/],
         "Testing every argument with bar";
         
  all_are       CODE  VALUE,   PARAMETERS, [ TEST_NAME ]
  all_arent     CODE  VALUE,   PARAMETERS, [ TEST_NAME ]
  
  any_ok {drunken_person() eq shift()}
         ["Jim Beam", "Jonny Walker", "Jack Daniels"];
  any_is {ask_for_sense_of_life(shift())} 42, ["Jack London", "Douglas Adams"];
  
  most_ok {$img->colorAt($_[0],$_[1]) == BLACK} 
         [ [0 .. 10_000], [0 .. 10_000] ] => 100,
         "100 random pixels of a black image should be black";
  
  [NOT YET IMPLEMENTED]
  
  all_are_deeply  CODE  SCALAR,  PARAMETERS, [ TEST_NAME ]
  all_like        CODE  REGEXP,  PARAMETERS, [ TEST_NAME ]
  all_unlike      CODE  REGEXP,  PARAMETERS, [ TEST_NAME ]
  all_can         CODE  METHODS, PARAMETERS, [ TEST_NAME ]
  all_dies_ok     CODE           PARAMETERS, [TEST_NAME]
  all_lives_ok    CODE           PARAMETERS, [TEST_NAME]
  all_throws_ok   CODE  REGEXP,  PARAMETERS, [TEST_NAME]

=head1 DESCRIPTION

=head2 GENERAL PRINCIPLES

This module helps to tests many parameters at once.
In general, it calls the given subroutine with every
combination of the given parameter values.
The combinations are created with building a cross product.

Especially it avoids writing ugly, boring code like:

  my $ok = 1;
  foreach my $x ($arg1a, $arg2a) {
      foreach my $y ($arg2a, $arg2b, $arg3b, $arg4b) {
          $ok &&= foo($x,$y);
      }
  }
  ok $ok, $testname;
  
Instead you simpler write

  all_ok {foo(@_)}  
         [ [$arg1a, $arg2a], [$arg2b, $arg2b, $arg3b, $arg4b] ]
         $testname;
  
Additionally the output contains also some useful information
about the parameters that should be tested and the first parameters the
test failed. E.g.

  all_ok {$_[0] != 13 and $_[1] != 13} 
         [ [1 .. 100], [1 .. 100] ], 
         "No double bad luck";
         
would print:

  not ok 1 - No double bad luck
  #     Failed test (x.pl at line 5)
  # Tests with the parameters: $VAR1=[[10,11,12,13,14,15],[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]];
  # Failed first using these parameters: $VAR1=[10,13];
  
  
The parameters passed to C<all_ok> can be passed in two ways.
If you need to test a crossproduct of more than one parameterlist,
you have to write it as

  all_ok CODE [ \@arglist1, \@arglist2, ..., \@arglistn ], TEST_NAME;
  
The CODE-routine will be called with every combination of the arglists,
passed as simple arguments. E.g.

  all_ok {foo(@_)} [ ["red", "green", "blue"], ["big", "medium", "little"] ];
  
would call

  foo("red","big");
  foo("red","medium");
  foo("red","little");
  foo("green","big");
  foo("green","medium");
  foo("green","little");
  foo("blue","big");
  foo("blue","medium");
  foo("blue","little");

Note, that the order of calling shouldn't play any role,
as it could be changed in future versions without any notice about.

Please always remember, that a crossproduct of the lists can be very, very big.
So don't write something like 
C<all_ok {&foo} [ [1 .. 32000], [1 .. 32000], [1 .. 32000] ]>,
as it would test 32_768_000_000_000 parameter combinations.

If you only want to test one parameter with different values,
you can write in general

  all_ok CODE \@values, TEST_NAME
 
So C<all_ok {&foo} [1,2,3]> would call C<foo(1); foo(2); foo(3)>.
(In this way and only in this, C<$_> will be set to the passed argument.
 Thus it is C<$_ = $_[0]> in this special case.
 Reason for this behaviour is just convenience.)

Please take care, that the first element of the values list isn't an array ref,
as Test::ManyParams would assume that you want to test combinations of the above.
If it is important to pass values that are array refs,
you have to write it this way:

  my @values = ( [1 .. 10],
                 [100 .. 110],
                 [990 .. 1000] );
  all_ok {&foo} [ [@values] ];
  
  # calls foo(1), ... foo(10), foo(100), ..., foo(110), foo(990), ..., foo(1000)
  
what is very different to

  all_ok {&foo} [ @values ];
  
  # what would call foo(1,100,900), foo(1,100,901), ...


Of course, the test name is always optional, but recommended.

=head2 FUNCTIONS

=over

=item all_ok  CODE  PARAMETERS,  [ TEST_NAME ]

See the general comments.

=item all_are  CODE  VALUE,  PARAMETERS,  [ TEST_NAME ]

The equivalent to C<Test::More>'s C<is> method.
The given subroutine has to return always the given value.
They are compared with 'eq'.

=item all_arent  CODE  VALUE,  PARAMETERS,  [ TEST_NAME ]

The equivalent to C<Test::More>'s C<isnt> method.
The given subroutine has to return always values different from the given one.
They are compared with 'eq'.

=item any_ok  CODE  PARAMETERS,  [ TEST_NAME ]

Returns whether the subroutine returns true for one of the given parameters.

=item any_is  CODE  VALUE,  PARAMETERS, [ TEST_NAME ]

Returns whether there is at least one parameter (combination) 
for that the given subroutine results the specified value.

=item any_isnt CODE  VALUE,  PARAMETERS, [ TEST_NAME ]

Returns whether there is at least one parameter (combination)
for that the given subroutine results to a value different to 
the specified one.

=item most_ok  CODE  PARAMETERS  =>  NR_OF_TESTS  [, TEST_NAME]

Tests NR_OF_TESTS (randomly choosen) parameter (combinations)
of the given parameters. All the (randomly choosen) parameters
have to let the subroutine results to true.

This method is intended to used,
when a full test would need to long and
you want to avoid systematic mistakes.

There could be some parameter (combinations),
that are tested twice or more often.

=back

=head2 IMPORTING

In the most cases,
you will simply import this module
(C<use Test::ManyParams>).

But when you want to set the seed for the randomization
of the C<most_ok> method,
the way for importing looks like
C<use Test::ManyParams seed => 42>.

At the time, it only will call C<srand(42)>,
but later on, it will hold
foreach test script and file it's own random numbers,
so that several modules all using this Test::ManyParams
module won't collide.

If you don't seet a seed value,
at default the C<time ^ $$> value will be taken as seed
(the default value could be changed in future versions without any notice).
That's not a very good seed,
but I hope it will be good and quick enough for the most cases.

You can access the setted seed with the variable
C<$Test::ManyParams::seed>. That's a non-exported, readonly variable.

Please take care only to import Test::ManyParams
one times in one package,
as the use command is executed while compile time
and so different seedings will be confusing.

=head2 EXPORT

C<all_ok>
C<all_are>
C<all_arent>
C<any_is>
C<any_isnt>
C<most_ok>

=head1 BUGS

The representation of the parameters uses Data::Dumper.
As this module neither set $Data::Dumper::Indent,
nor reads it out,
setting $Data::Dumper::Indent to some strange values
can destroy a useful parameter outprint.
I don't plan to fix this behaviour in the next time,
as I there a more important things to do.
(Who changes global variables harvest what he/she/it has seed.)

The C<most_ok> method is hard to test.
I wrote some tests that helped to remove the obviously bugs,
but there could be some subtle bugs.
Especially I didn't test what happens,
if you try to test more parameters than there could be.

There are perhaps many mistakes in this documentation.

Please tell me everything you can find.

=head1 TODO

There are a lot of methods I'd like to implement still.
The most of them are simple 
Here's a list of them:

=over

=item all_are_deeply  CODE  SCALAR,  PARAMETERS, [ TEST_NAME ]

=item all_like CODE  REGEXP, PARAMETERS, [ TEST_NAME ]

=item all_unlike CODE  REGEXP, PARAMETERS, [ TEST_NAME ]

=item all_can CODE  REGEXP, PARAMETERS, [ TEST_NAME ]

=item all_dies_ok CODE  PARAMETERS, [TEST_NAME]

=item all_lives_ok CODE  PARAMETERS, [TEST_NAME]

=item all_throws_ok CODE  REGEXP, PARAMETERS, [TEST_NAME]

=back

Similar methods are planned with the prefix any_.

The C<most_ok> method should accept also
a percentage rate and a time slot or ... for specification of
how many tests should be run.
Typical examples for that could be C<'1000', '1%', '5s', '100 + bounds'>.

The pro and contra of had been discussed a bit on perl.qa.
One of the results is that random parameter tests are very sensful,
but the reproducibility is very important.
So the module has to seed (or recognise the seed) of the random generator
and to give the possibility to set them
(e.g. with C<use Test::ManyParams seed => 42>).
Recognising a failed test, this seed has to be printed.
It always seems to be sensful to set an own random numbering for each package
using this module.
The last part still has to be done.

That's only a short synopsis of this discussion,
it will be better explained when these features are built in.

Of course, there will be also some methods like C<most_are>,C<most_arent>,... .

=head1 SEE ALSO

This module had been and will be discussed on perl.qa.

L<Test::More>
L<Test::Exception>

=head1 THANKS

Thanks to Nicholas Clark and to Tels (http://www.bloodgate.com) for
giving a lot of constructive ideas.

=head1 AUTHOR

Janek Schleicher, E<lt>bigj@kamelfreund.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Janek Schleicher

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
