package Test::Ranger;

use 5.010000;
use strict;
use warnings;
use Carp;

use version 0.77; our $VERSION = qv('0.0.4');

use Test::More;                 # Standard framework for writing test scripts
use Data::Lock qw( dlock );     # Declare locked scalars, arrays, and hashes
use Scalar::Util;               # General-utility scalar subroutines
use Scalar::Util::Reftype;      # Alternate reftype() interface

use Test::Ranger::List;

## use

# Alternate uses
#~ use Devel::Comments;

#============================================================================#

# Pseudo-globals

#~ # Literal hash keys
#~ dlock( my $coderef     = '-coderef');    # cref to code under test

#----------------------------------------------------------------------------#

#=========# CLASS METHOD
#
#   my $obj     = $class->new($self);
#   my $obj     = $class->new();
#   my $obj     = $class->new({ -a  => 'x' });
#   my $obj     = $class->new([ 1, 2, 3, 4 ]);
#       
# Purpose   : Object constructor
# Parms     : $class    : Any subclass of this class
#           : $self     : Hashref or arrayref
# Returns   : $self
# Invokes   : init(), Test::Ranger::List::new()
# 
# If invoked with $class only, blesses and returns an empty hashref. 
# If invoked with $class and a hashref, blesses and returns it. 
# If invoked with $class and an arrayref, invokes ::List::new(). 
# 
sub new {
    my $class   = shift;
    my $self    = shift || {};      # default: hashref
    
    if ( (reftype $self)->array ) {
        $self       = Test::Ranger::List->new($self);
    } 
    else {
        bless ($self => $class);
        $self->init();
    };
    
    return $self;
}; ## new

#=========# OBJECT METHOD
#
#   $obj->init();
#
# Purpose   : Initialize housekeeping info.
# Parms     : $class    : Any subclass of this class
#           : $self     : Hashref
# Returns   : $self
#
sub init {
    my $self        = shift;
    
    $self->{-plan_counter}      = 0;
    $self->{-expanded}          = 0;
    
    return $self;
}; ## init

#=========# OBJECT METHOD
#
#   $single->expand();
#
# Purpose   : Expand/parse declaration into canonical form.
# Parms     : $class
#           : $self
# Returns   : $self
#
sub expand {
    my $self        = shift;
    
    # Default givens
    if ( !$self->{-given}{-args} ) {
        $self->{-given}{-args}     = [];
    };
    
    # Default expectations
    if ( !$self->{-return}{-want} ) {
        $self->{-return}{-want}     = 1;
    };
    
    
    
    $self->{-expanded}          = 1;
    
    return $self;
}; ## expand

#=========# OBJECT METHOD
#
#   $single->execute();
#
#       Execute a $single object.
#
sub execute {
    my $self        = shift;
    
    $self->expand() if !$self->{-expanded};
    
    my $coderef     = $self->{-coderef};
    my @args        = @{ $self->{-given}{-args} };
    ### $coderef
    
    $self->{-return}{-got}    = &$coderef( @args );
    
    return $self;
    
}; ## execute

#=========# OBJECT METHOD
#
#   $single->check();
#
#       Check results in a $single object.
#
sub check {
    my $self        = shift;
    
    is( $self->{-return}{-got}, $self->{-return}{-want}, $self->{-fullname} );
    $self->{-plan_counter}++;
    
    return $self;
    
}; ## check

#=========# OBJECT METHOD
#
#   $single->test();
#
#       Execute and check a $single object.
#
sub test {
    my $self        = shift;
    
    $self->execute();
    $self->check();
    
    return $self;
    
}; ## test

#=========# OBJECT METHOD
#
#   $single->done();
#
#       Conclude testing.
#
sub done {
    my $self        = shift;
    
    done_testing( $self->{-done_counter} );
    
    return $self;
    
}; ## done


## END MODULE
1;
#============================================================================#
__END__

=head1 NAME

Test::Ranger - Test with data tables, capturing, templates

=head1 VERSION

This document describes Test::Ranger version 0.0.1

TODO: THIS IS A DUMMY, NONFUNCTIONAL RELEASE.

=head1 SYNOPSIS

    # Object-oriented usage
    use Test::Ranger;

    my $group    = Test::Ranger->new([
        {
            -coderef    => \&Acme::Teddy::_egg,
            -basename   => 'teddy-egg',
        },
        
        {
            -name       => '4*7',
            -given      => [ 4, 7 ],
            -return     => {
                -is         => 42,
            },
            -stdout     => {
                -like       => [ qw(hello world) ],
                -matches    => 2,
                -lines      => 1,
            },
        },
        
        {
            -name       => '9*9',
            -given      => [ 9, 9 ],
            -return     => {
                -is         => 81,
            },
        },
        
        {
            -name       => 'string',
            -given      => [ 'monkey' ],
            -warn       => {
                -like       => 'dummy',
            },
        },
        
    ]); ## end new

    $group->test();
    
    __END__

=head1 DESCRIPTION

=over

I<The computer should be doing the hard work.> 
I<That's what it's paid to do, after all.>
-- Larry Wall

=back

This is a comprehensive testing module compatible with Test::More and friends 
within TAP::Harness. Helper scripts and templates are included to make 
test-driven development quick, easy, and reliable. Test data structure is 
open; choose from object-oriented methods or procedural/functional calls. 

Tests themselves are formally untestable. All code conceals bugs. Do you want 
to spend your time debugging tests or writing production code? 
The Test::Ranger philosophy is to reduce the amount of code in a test script 
and let test data (given inputs and wanted outputs) dominate. 

Many hand-rolled test scripts examine expected output to see if it matches 
expectations. Test::Ranger traps fatal exceptions cleanly and makes it easy 
to subtest every execution for both expected and unexpected output. 

=head2 Approach

Our overall approach is to B<declare> all the conditions for a series of 
tests in an Arrayref-of-Hashrefs. We B<execute> the tests, supplying inputs 
to code under test and capturing outputs within the same AoH. 
Then we B<compare> each execution's actual outputs with what we expected. 

Each test is represented by a hashref in which each key is a literal string; 
the values may be thought of as attributes of the test. The literal keys are 
part of our published interface; accessor methods are not required. 
Hashrefs and their keys may be nested DWIMmishly. 

Much of the merit of our approach lies in B<sticky> declaration. Once you 
declare, say, a coderef, you don't need to declare it again 
for every set of givens. Or, you can declare a given list of arguments once 
and pass them to several subroutines. See L</-sticky>, L</-clear>.

Test::Ranger does not lock you in to a single specific approach. You can 
declare your entire test series as an object and simply L</test()> it, 
letting TR handle the details. You can read your data from somewhere 
and just use TR to capture a single execution, then examine the results 
on your own. You can mix TR methods and function calls; you can add 
other Test::More-ish checks. The door is open.

=head2 Templates

To further speed things along, please note that a number of templates 
are shipped with TR. These may be copied, modified, and extended as you 
please, of course. Consider them a sort of cookbook and an appendix to 
this documentation. 

=head1 GLOSSARY

I<You are in a maze of twisty little tests, all different.>

The word B<test> is so heavily overloaded that documentation may be unclear. 
In TR docs, I will use the following terms: 

=head3 manager

E.g., I<prove>, I<make test>; 
program that runs a L</suite> through a L</harness>

=head3 harness

E.g., L<Test::Harness> or L<TAP::Harness>; summarizes L</framework> results

=head3 framework

E.g., L<Test::Simple> or L<Test::More>; sends results to L</harness>

=head3 suite

Folder or set of test L<scripts|/script>.

=head3 script

File containing Perl code meant to be run by a L</harness>; 
filename usually ends in .t

=head3 list

Array or series of (several sequential) test L<declarations|/declaration>

=head3 declaration

The data required to execute a test, 
including given L</inputs> and expected L</outputs>; 
also, the phase in which this data is constructed

=head3 execution

The action of running a test L</declaration> and capturing actual L</outputs>;
also, the phase in which this is done

=head3 checking

The action of comparing actual and expected values for some execution; 
also, the phase in which this is done

=head3 subtest

A single comparison of actual and expected results for some output. 

Note that a C<Test::More::subtest()>, used internally by Test::Ranger, 
counts as a single 'test' passed to harness. In these docs, a 'subtest' is 
any one check within a call to C<subtest()>. 

=head3 inputs

Besides arguments passed to SUT, any state that it might read, 
such as C<@ARGV> and C<%ENV>. 

Inputs are I<given>, perhaps I<generated>. 

=head3 outputs

Besides the conventional return value, anything else SUT might write, 
particularly STDOUT and STDERR; also includes exceptions thrown by SUT.

Outputs may be I<actual> (L</-got>) results or I<expected> (L</-want>).

=head3 CUT, SUT, MUT

code under test, subroutine..., module...; the thing being tested

=head1 INTERFACE 

The primary interface to TR is the test data structure you normally supply 
as the argument to L</new()>. There are also a number of methods you can use. 
In Perl, methods can be called as functions; Test::Ranger's methods 
are written with this in mind.

=head2 $test

You can call this anything you like, of course. This is the football you 
pass to various methods. 

The B<Test::Ranger> object represents a single test L</declaration>. 
Besides the data that you provide, it contains test outputs 
and some housekeeping information. See </new()>.

All data is kept in essentially 
the same structure you pass to the constructor. You should use the following 
literal hash keys to access any element or object attribute. 
Generally, values are interpreted according to the rule: 
If the value is a simple scalar, it is considered the intended value of the
corresponding key. If the value is an arrayref, it is dereferenced and the 
resulting array considered a list of intended values. If the value is 
a hashref, then it is considered to introduce more keys from this interface. 

It's not necessary to supply values for all these keys. 
The only essential key is L</-coderef>. If nothing else is declared, 
C<&{$test->{-coderef}}()> will be executed, with no arguments. 
One subtest will pass if the execution's return value is C<TRUE>. 
C<STDOUT> and C<STDERR> are expected to be empty. 
Any exception will be trapped and reported as a subtest failure. 

See defaults. 

=over

=item *

L</-argv>

=item *

L</-basename>

=item *

L</-coderef>

=item *

L</-counter>

=item *

L</-env>

=item *

L</-fatal>

=item *

L</-file>

=item *

L</-given>

=item *

L</-infile>

=item *

L</-input>

=item *

L</-is>

=item *

L</-like>

=item *

L</-lines>

=item *

L</-matches>

=item *

L</-name>

=item *

L</-outfile>

=item *

L</-return>

=item *

L</-stdout>

=item *

L</-want>

=item *

L</-warn>

=back

=head2 Inputs

These are the values passed into a test execution. 

=head3 -given

    {-given => [2, 'foo']}              # default == ()

Values passed as arguments to CUT. 
Your code might well be passed a hashref; so, if you supply this here, 
TR will not look deeper for more keys. 

=head3 -argv

    {-argv => [--fleegle => 'one']}     # default: untouched

Before each execution, C<@ARGV> will be set to this list. 
Existing C<@ARGV> will be replaced.

=head3 -env

    {-env => [PERL5LIB => '../blib']}   # default: untouched

Before each execution, this list will be added to C<%ENV>. 
Existing C<%ENV> key/value pairs will be untouched.

=head3 -infile

    {-infile => 'my/data/file.txt'}

The supplied file will be opened for reading and one record passed per 
execution. This hashref can be declared as the value for some other 
input; if it's found at the top level of a declaration, 
the record will be passed in as a single string L</-given>.

=head3 -input

    {-input => {-foo => 'baz'}}

These values will not be processed directly when the declaration is executed. 
This feature is intended to allow you to supply additional test inputs. 
It's up to you to pick them out during execution and use them as you wish. 

You may, if you like, collect other inputs here; it's not required. 
C<-inputs> is a synonym. 

=head2 Expectations

These are the values you B<want> to find after a test execution. 

=head3 -return

    {-return => 1}                      # default: any TRUE value

The value normally returned by the execution. 
Your code might well return a hashref; so, if you supply this here, 
TR will not look deeper for more keys. 

TODO: wantarray?

=head3 -stdout

    {-stdout => [qw(foo bar baz)]}      # default eq q{}

C<STDOUT> is always captured. 
If a scalar or arrayref is supplied for this key (as the example), 
it will be treated as though you had declared: 

    {
        -stdout => {
            -like       => [qw(foo bar baz)],
            -matches    => 1,
        }
    }

You may want more control over the comparison. If you supply a hashref, 
you can declare various subkeys for this purpose. 

=head3 -warn

C<STDERR> is always captured. 
This feature is parallel to L</-stdout>. 
Synonym for C<-stderr>. 

=head3 -fatal

Exceptions are always trapped. You might I<want> the execution to fatal out; 
if so, supply a value for this key, which will be subtested as are 
L</-stdout> and L</-warn>. 

=head3 -want

    {-want => {-foo => 'baz'}}

Extra values will not be processed directly when the declaration is executed. 
This feature is intended to allow you to supply additional test expectations. 
It's up to you to pick them out during comparison and use them as you wish. 

You may, if you like, collect other wants here; it's not required. 
C<-wants> is a synonym. 

=head2 Results

Actual results from execution and comparison are stored in the same object 
you declared in the constructor. 
You may wish to perform additional subtests on them. 
You might like to dump stored results to screen or disk. 

=head3 -got

    {
        -got => {
            -return => 'foo',
            -stdout     => {
                -string     => 'Hello, world!',
            },
            -stderr     => {
                -string     => 'Foo caught at line 17.',
                -matches    => 3,
            },
            -fatal      => undef,
        },
    }
    
All captured results are stored as subkeys of C<-got>. 
To see in detail how TR stores these results, you might like to use the 
convenience method L</dump()>.

=head2 Execution control

TODO: Explain these. See also crossjoin() and friends. 

=head3 -expand

=head3 -sticky

=head3 -clear

=head3 -bailout

=head3 -skip

=head3 -done

=head2 Comparison control

TODO: For any script, comparisons may be done for each declaration 
immediately after its execution; or all at once after all executions have 
completed. 

Between any pair of actual and expected outputs, one or more subtests can be 
made. These are declared, generally, with a subkey similar to the 
corresponding framework comparison function. 
If, for any L</-want>, an expected value is given directly, 
it will be compared using its fallback. 

FIXME: fallback table

-want       value           fallback method

-return     scalar          Test::More::is()
            not scalar      Test::More::is_deeply()

-stdout                     
-stderr                     
-fatal                      

=head3 -is

    {-is => 'Hello, world!'}

String B<eq>. A synonym is C<-string>.

=head3 -number

    {-number => 42}

Numeric B<==>. An additional subtest will fail if the actual result raises
a warning of string in numeric comparision. 
This warning will not be captured into C<{-got}{-warn}>.
See L<perllexwarn/Category Hierarchy>.

=head3 -min

    {-min => 3}

Subtest passes if actual value is at least this. 

=head3 -max

    {-max => 5}

Subtest passes if actual value is not more than this. 

=head3 -like

    {-like => [qw(foo bar baz)]}

A regex will be constructed from the provided list, e.g.: 

    $test->{-got} =~ m/foo|bar|baz/

This subtest will pass if there is at least one match. But see L</matches>. 

=head3 -regex

    {-regex => qr/$my_big_fat_regex/}

Like L</-like>, but allows you to use full regex syntax. 

=head3 -matches

    {
        -like       => [qw(foo bar baz)],
        -matches    => 2,
    }

Only useful with L</-like> or L</-regex>. Checks to see that at least a 
required number of matches were found. But see L</-max>. 

=head3 -lines

    {-lines => 7}

Checks to see that at least a required number of lines were captured. 
As a sanity check, this subtest will also fail if the actual number of lines 
is much greater than expected. TODO: how many more is too much?
To override this and get finer control, see L</number>, L</min>, L</min>. 
You can say: 

    {-lines => {-min => 5, -max => 9} }         

=head2 Class Methods

TODO: Explain these stuffs

=head3 new()

Takes a hashref or arrayref as a required argument. 

If you pass a hashref to the constructor C<Test::Ranger::new()>, 
it will return an object blessed into class B<Test::Ranger>; 
if you pass an arrayref of hashrefs, it will bless each hashref into the 
base class, wrap the arrayref in a top-level hashref, and bless the mess 
into L<Test::Ranger::List>. 

TR objects are conventionally hashref based and its keys are part of our 
public interface. So, you're free to poke around as you like. 

Returns $self.

=head2 Object Methods

TODO: Explain these stuffs

TR object methods may generally be called as fully-qualified functions. 
Internally, the argument supplied to the function will be passed to L</new()>.

=head3 execute()

Takes a hashref or arrayref as a required argument when called as a function. 
Takes no argument when called as a method. 

Perform the execution of the declared data and code, capturing outputs. 
If the class is L<Test::Ranger::List>, then the list will be looped through 
sequentiallly and each Test::Ranger subobject executed. 

Returns $self. 

=head3 check()

Takes a hashref or arrayref as a required argument when called as a function. 
Takes no argument when called as a method. 

Perform a series of subtests comparing expected and actual results. 
Each subtest writes to C<STDOUT/STDERR> for consumption by a harness. 

Returns $self. 

=head3 test()

Takes a hashref or arrayref as an optional argument when called as a function. 
Takes no argument when called as a method. 

Performs both the execution and comparison phase on a Test::Ranger object. 
If invoked on a Test::Ranger::List, then each subobject will be executed 
and then compared before going to the next. You may prefer this to 
the two-step C<execute; compare;> approach, especially if you want to 
L</-bailout> of testing on failure. 

Returns $self.

=head3 append()

Takes a TR object as a required argument. 
Not usable as a function. 

Pushes its argument into $self. 

Returns $self.

=head3 crossjoin()

Takes a TR object as a required argument. 
Not usable as a function. 

Builds a two-dimensional matrix from $self and its argument, then flattens 
this into a new list. Useful for running every possible combination of two 
lists of test declarations. 

Returns $self. 

=head3 shuffle()

Takes any scalar value as an argument, but interprets it as a boolean. 
A Test::Ranger::List object (only) method. 

Pseudo-randomly rearranges a list of TR subobjects, so they I<won't> 
execute in sequence. Useful for uncovering unexpected state retention. 
Best used I<after> L</expand()>.

Returns $self. 

=head3 expand()

Takes no argument. Not usable as a function. 

Expands the declarations in an object to the most-fully-qualified extent. 
This removes all dependency on L</-sticky> declaration and inserts defaults 
for all values not supplied. Useful if you're not sure TR is really DWYM. 

Returns $self. 

=head3 dump()

Takes a keyword as an optional argument; see below. Not usable as a function. 

    print $test->dump('form');

Convenience method dumps an entire object so you can see what's in it. 
Keyword 'form' uses L<Perl6::Form> to try to get a compact dump. Default is 
L<Data::Dumper>. 

Returns a big long string. 

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back

=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.

Test::Ranger requires no configuration files or environment variables.

=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.

=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.

=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.


Please report any bugs or feature requests to
C<bug-test-ranger@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Xiong Changnian  C<< <xiong@cpan.org> >>

=head1 LICENSE

Copyright (C) 2010 Xiong Changnian C<< <xiong@cpan.org> >>

This library and its contents are released under Artistic License 2.0:

L<http://www.opensource.org/licenses/artistic-license-2.0.php>

=cut
