package Test::Weaken;


# maybe:
# contents_funcs => arrayref of funcs
#     multiple contents, or sub{} returning list enough ?
# track_filehandles => 1  GLOB and IO
#
# locations=>1
#  top->{'foo'}->[10]->REF->*{IO}
#  top.H{'foo'}.A[10].REF.*{IO}
# unfreed_locations() arrayref of strings
# first location encountered
# locations_maxdepth


use 5.006;
use strict;
use warnings;

require Exporter;

use base qw(Exporter);
our @EXPORT_OK = qw(leaks poof);
our $VERSION   = '3.022000';

#use Smart::Comments;

### <where> Using Smart Comments ...

=begin Implementation:

The basic strategy: get a list of all the objects which allocate memory,
create probe references to them, weaken those probe references, attempt
to free the memory, and check the references.  If the memory is free,
the probe references will be undefined.

Probe references also serve a second purpose -- to avoid copying any
weak reference in the original object.  When you copy a weak reference,
the result is a strong reference.

There may be good reasons for Perl strengthen-on-copy policy, but that
behavior is a big problem for this module.  A lot of what might seem
like needless indirection in the code below is done to avoid working
with references directly in situations which could involve making a copy
of them, even implicitly.

=end Implementation:

=cut

package Test::Weaken::Internal;

use English qw( -no_match_vars );
use Carp;
use Scalar::Util 1.18 qw();

my @default_tracked_types = qw(REF SCALAR VSTRING HASH ARRAY CODE);

sub follow {
    my ( $self, @base_probe_list ) = @_;

    my $ignore_preds       = $self->{ignore_preds};
    my $contents           = $self->{contents};
    my $trace_maxdepth     = $self->{trace_maxdepth};
    my $trace_following    = $self->{trace_following};
    my $trace_tracking     = $self->{trace_tracking};
    my $user_tracked_types = $self->{tracked_types};

    my @tracked_types = @default_tracked_types;
    if ( defined $user_tracked_types ) {
        push @tracked_types, @{$user_tracked_types};
    }
    my %tracked_type = map { ( $_, 1 ) } @tracked_types;

    defined $trace_maxdepth or $trace_maxdepth = 0;

    # Initialize the results with a reference to the dereferenced
    # base reference.

    # The initialization assumes each $base_probe is a reference,
    # not part of the test object, whose referent is also a reference
    # which IS part of the test object.
    my @follow_probes    = @base_probe_list;
    my @tracking_probes  = @base_probe_list;
    my %already_followed = ();
    my %already_tracked  = ();

    FOLLOW_OBJECT:
    while ( defined( my $follow_probe = pop @follow_probes ) ) {

        # The follow probes are to objects which either will not be
        # tracked or which have already been added to @tracking_probes

        next FOLLOW_OBJECT
            if $already_followed{ Scalar::Util::refaddr $follow_probe }++;

        my $object_type = Scalar::Util::reftype $follow_probe;

        my @child_probes = ();

        if ($trace_following) {
            require Data::Dumper;
            ## no critic (ValuesAndExpressions::ProhibitLongChainsOfMethodCalls)
            print {*STDERR} 'Following: ',
                Data::Dumper->new( [$follow_probe], [qw(tracking)] )->Terse(1)
                ->Maxdepth($trace_maxdepth)->Dump
                or Carp::croak("Cannot print to STDOUT: $ERRNO");
            ## use critic
        } ## end if ($trace_following)

        if ( defined $contents ) {
            my $safe_copy = $follow_probe;
            push @child_probes, map { \$_ } ( $contents->($safe_copy) );
        }

        FIND_CHILDREN: {

            foreach my $ignore (@$ignore_preds) {
                my $safe_copy = $follow_probe;
                last FIND_CHILDREN if $ignore->($safe_copy);
            }

            if ( $object_type eq 'ARRAY' ) {
                if ( my $tied_var = tied @{$follow_probe} ) {
                    push @child_probes, \($tied_var);
                }
                foreach my $i ( 0 .. $#{$follow_probe} ) {
                    if ( exists $follow_probe->[$i] ) {
                        push @child_probes, \( $follow_probe->[$i] );
                    }
                }
                last FIND_CHILDREN;
            } ## end if ( $object_type eq 'ARRAY' )

            if ( $object_type eq 'HASH' ) {
                if ( my $tied_var = tied %{$follow_probe} ) {
                    push @child_probes, \($tied_var);
                }
                push @child_probes, map { \$_ } values %{$follow_probe};
                last FIND_CHILDREN;
            } ## end if ( $object_type eq 'HASH' )

            # GLOB is not tracked by default,
            # but we follow ties
            if ( $object_type eq 'GLOB' ) {
                if ( my $tied_var = tied *${$follow_probe} ) {
                    push @child_probes, \($tied_var);
                }
                last FIND_CHILDREN;
            } ## end if ( $object_type eq 'GLOB' )

            # LVALUE is not tracked by default,
            # but we follow ties
            if (   $object_type eq 'SCALAR'
                or $object_type eq 'VSTRING'
                or $object_type eq 'LVALUE' )
            {
                if ( my $tied_var = tied ${$follow_probe} ) {
                    push @child_probes, \($tied_var);
                }
                last FIND_CHILDREN;
            } ## end if ( $object_type eq 'SCALAR' or $object_type eq ...)

            if ( $object_type eq 'REF' ) {
                if ( my $tied_var = tied ${$follow_probe} ) {
                    push @child_probes, \($tied_var);
                }
                push @child_probes, ${$follow_probe};
                last FIND_CHILDREN;
            } ## end if ( $object_type eq 'REF' )

        } ## end FIND_CHILDREN:

        push @follow_probes, @child_probes;

        CHILD_PROBE: for my $child_probe (@child_probes) {

            my $child_type = Scalar::Util::reftype $child_probe;

            next CHILD_PROBE unless $tracked_type{$child_type};

            my $new_tracking_probe = $child_probe;

            next CHILD_PROBE
                if $already_tracked{ Scalar::Util::refaddr $new_tracking_probe
                    }++;

            foreach my $ignore (@$ignore_preds) {
                my $safe_copy = $new_tracking_probe;
                next CHILD_PROBE if $ignore->($safe_copy);
            }

            if ($trace_tracking) {
                ## no critic (ValuesAndExpressions::ProhibitLongChainsOfMethodCalls)
                print {*STDERR} 'Tracking: ',
                    Data::Dumper->new( [$new_tracking_probe], [qw(tracking)] )
                    ->Terse(1)->Maxdepth($trace_maxdepth)->Dump
                    or Carp::croak("Cannot print to STDOUT: $ERRNO");
                ## use critic

                 # print {*STDERR} 'Tracking: ',
                 #   "$new_tracking_probe\n";

            } ## end if ($trace_tracking)
            push @tracking_probes, $new_tracking_probe;

        } ## end for my $child_probe (@child_probes)

    }    # FOLLOW_OBJECT

    return \@tracking_probes;

}    # sub follow

# See POD, below
sub Test::Weaken::new {
    my ( $class, $arg1, $arg2 ) = @_;
    my $self = {};
    bless $self, $class;
    $self->{test} = 1;

    my @ignore_preds;
    my @ignore_classes;
    my @ignore_objects;
    $self->{ignore_preds} = \@ignore_preds;

  UNPACK_ARGS: {
        if ( ref $arg1 eq 'CODE' ) {
            $self->{constructor} = $arg1;
            if ( defined $arg2 ) {
                $self->{destructor} = $arg2;
            }
            return $self;
        }

        if ( ref $arg1 ne 'HASH' ) {
            Carp::croak('arg to Test::Weaken::new is not HASH ref');
        }

        if (defined (my $constructor = delete $arg1->{constructor})) {
            $self->{constructor} = $constructor;
        }

        if (defined (my $destructor = delete $arg1->{destructor})) {
            $self->{destructor} = $destructor;
        }
        if (defined (my $destructor_method = delete $arg1->{destructor_method})) {
            $self->{destructor_method} = $destructor_method;
        }

        if (defined (my $coderef = delete $arg1->{ignore})) {
            if (ref $coderef ne 'CODE') {
                Carp::croak('Test::Weaken: ignore must be CODE ref');
            }
            push @ignore_preds, $coderef;
        }
        if (defined (my $ignore_preds = delete $arg1->{ignore_preds})) {
            push @ignore_preds, @$ignore_preds;
        }
        if ( defined (my $ignore_class = delete $arg1->{ignore_class} )) {
            push @ignore_classes, $ignore_class;
        }
        if ( defined (my $ignore_classes = delete $arg1->{ignore_classes} )) {
            push @ignore_classes, @$ignore_classes;
        }
        push @ignore_objects, delete $arg1->{ignore_object};
        if ( defined (my $ignore_objects = delete $arg1->{ignore_objects} )) {
            push @ignore_objects, @$ignore_objects;
        }

        if ( defined $arg1->{trace_maxdepth} ) {
            $self->{trace_maxdepth} = $arg1->{trace_maxdepth};
            delete $arg1->{trace_maxdepth};
        }

        if ( defined $arg1->{trace_following} ) {
            $self->{trace_following} = $arg1->{trace_following};
            delete $arg1->{trace_following};
        }

        if ( defined $arg1->{trace_tracking} ) {
            $self->{trace_tracking} = $arg1->{trace_tracking};
            delete $arg1->{trace_tracking};
        }

        if ( defined $arg1->{contents} ) {
            $self->{contents} = $arg1->{contents};
            delete $arg1->{contents};
        }

        if ( defined $arg1->{test} ) {
            $self->{test} = $arg1->{test};
            delete $arg1->{test};
        }

        if ( defined $arg1->{tracked_types} ) {
            $self->{tracked_types} = $arg1->{tracked_types};
            delete $arg1->{tracked_types};
        }

        my @unknown_named_args = keys %{$arg1};

        if (@unknown_named_args) {
            my $message = q{};
            for my $unknown_named_arg (@unknown_named_args) {
                $message .= "Unknown named arg: '$unknown_named_arg'\n";
            }
            Carp::croak( $message
                         . 'Test::Weaken failed due to unknown named arg(s)' );
        }

    }    # UNPACK_ARGS

    if ( my $ref_type = ref $self->{constructor} ) {
        Carp::croak('Test::Weaken: constructor must be CODE ref')
            unless ref $self->{constructor} eq 'CODE';
    }

    if ( my $ref_type = ref $self->{destructor} ) {
        Carp::croak('Test::Weaken: destructor must be CODE ref')
            unless ref $self->{destructor} eq 'CODE';
    }

    if ( my $ref_type = ref $self->{contents} ) {
        Carp::croak('Test::Weaken: contents must be CODE ref')
            unless ref $self->{contents} eq 'CODE';
    }

    if ( my $ref_type = ref $self->{tracked_types} ) {
        Carp::croak('Test::Weaken: tracked_types must be ARRAY ref')
            unless ref $self->{tracked_types} eq 'ARRAY';
    }

    if (@ignore_classes) {
        push @ignore_preds, sub {
            my ($ref) = @_;
            if (Scalar::Util::blessed($ref)) {
                foreach my $class (@ignore_classes) {
                    if ($ref->isa($class)) {
                        return 1;
                    }
                }
            }
            return 0;
        };
    }

    # undefs in ignore objects are skipped
    @ignore_objects = grep {defined} @ignore_objects;
    if (@ignore_objects) {
        push @ignore_preds, sub {
            my ($ref) = @_;
            $ref = Scalar::Util::refaddr($ref);
            foreach my $object (@ignore_objects) {
                if (Scalar::Util::refaddr($object) == $ref) {
                    return 1;
                }
            }
            return 0;
        };
    }

    return $self;

}    # sub new

sub Test::Weaken::test {

    my $self = shift;

    if ( defined $self->{unfreed_probes} ) {
        Carp::croak('Test::Weaken tester was already evaluated');
    }

    my $constructor = $self->{constructor};
    my $destructor  = $self->{destructor};
    # my $ignore      = $self->{ignore};
    my $contents    = $self->{contents};
    my $test        = $self->{test};

    my @test_object_probe_list = map {\$_} $constructor->();
    foreach my $test_object_probe (@test_object_probe_list) {
        if ( not ref ${$test_object_probe} ) {
            Carp::carp(
              'Test::Weaken test object constructor returned a non-reference'
            );
        }
    }
    my $probes = Test::Weaken::Internal::follow( $self, @test_object_probe_list );

    $self->{probe_count} = @{$probes};
    $self->{weak_probe_count} =
        grep { ref $_ eq 'REF' and Scalar::Util::isweak ${$_} } @{$probes};
    $self->{strong_probe_count} =
        $self->{probe_count} - $self->{weak_probe_count};

    if ( not $test ) {
        $self->{unfreed_probes} = $probes;
        return scalar @{$probes};
    }

    for my $probe ( @{$probes} ) {
        Scalar::Util::weaken($probe);
    }

    # Now free everything.
    if (defined (my $destructor_method = $self->{destructor_method})) {
        foreach my $test_object_probe (@test_object_probe_list) {
            my $obj = $$test_object_probe;
            $obj->$destructor_method;
        }
    }
    if (defined $destructor) {
        $destructor->( map {$$_} @test_object_probe_list ) ;
    }

    @test_object_probe_list = ();

    my $unfreed_probes = [ grep { defined $_ } @{$probes} ];
    $self->{unfreed_probes} = $unfreed_probes;

    return scalar @{$unfreed_probes};

}    # sub test

# Undocumented and deprecated
sub poof_array_return {

    my $tester  = shift;
    my $results = $tester->{unfreed_probes};

    my @unfreed_strong = ();
    my @unfreed_weak   = ();
    for my $probe ( @{$results} ) {
        if ( ref $probe eq 'REF' and Scalar::Util::isweak ${$probe} ) {
            push @unfreed_weak, $probe;
        }
        else {
            push @unfreed_strong, $probe;
        }
    }

    return (
        $tester->weak_probe_count(),
        $tester->strong_probe_count(),
        \@unfreed_weak, \@unfreed_strong
    );

} ## end sub poof_array_return;

sub Test::Weaken::poof {
    my @args   = @_;
    my $tester = Test::Weaken->new(@args);
    my $result = $tester->test();
    return Test::Weaken::Internal::poof_array_return($tester) if wantarray;
    return $result;
}

sub Test::Weaken::leaks {
    my @args   = @_;
    my $tester = Test::Weaken->new(@args);
    my $result = $tester->test();
    return $tester if $result;
    return;
}

sub Test::Weaken::unfreed_proberefs {
    my $tester = shift;
    my $result = $tester->{unfreed_probes};
    if ( not defined $result ) {
        Carp::croak('Results not available for this Test::Weaken object');
    }
    return $result;
}

sub Test::Weaken::unfreed_count {
    my $tester = shift;
    my $result = $tester->{unfreed_probes};
    if ( not defined $result ) {
        Carp::croak('Results not available for this Test::Weaken object');
    }
    return scalar @{$result};
}

sub Test::Weaken::probe_count {
    my $tester = shift;
    my $count  = $tester->{probe_count};
    if ( not defined $count ) {
        Carp::croak('Results not available for this Test::Weaken object');
    }
    return $count;
}

# Undocumented and deprecated
sub Test::Weaken::weak_probe_count {
    my $tester = shift;
    my $count  = $tester->{weak_probe_count};
    if ( not defined $count ) {
        Carp::croak('Results not available for this Test::Weaken object');
    }
    return $count;
}

# Undocumented and deprecated
sub Test::Weaken::strong_probe_count {
    my $tester = shift;
    my $count  = $tester->{strong_probe_count};
    if ( not defined $count ) {
        Carp::croak('Results not available for this Test::Weaken object');
    }
    return $count;
}

sub Test::Weaken::check_ignore {
    my ( $ignore, $max_errors, $compare_depth, $reporting_depth ) = @_;

    my $error_count = 0;

    $max_errors = 1 if not defined $max_errors;
    if ( not Scalar::Util::looks_like_number($max_errors) ) {
        Carp::croak('Test::Weaken::check_ignore max_errors must be a number');
    }
    $max_errors = 0 if $max_errors <= 0;

    $reporting_depth = -1 if not defined $reporting_depth;
    if ( not Scalar::Util::looks_like_number($reporting_depth) ) {
        Carp::croak(
            'Test::Weaken::check_ignore reporting_depth must be a number');
    }
    $reporting_depth = -1 if $reporting_depth < 0;

    $compare_depth = 0 if not defined $compare_depth;
    if ( not Scalar::Util::looks_like_number($compare_depth)
        or $compare_depth < 0 )
    {
        Carp::croak(
            'Test::Weaken::check_ignore compare_depth must be a non-negative number'
        );
    }

    return sub {
        my ($probe_ref) = @_;

        my $array_context = wantarray;

        my $before_weak =
            ( ref $probe_ref eq 'REF'
                and Scalar::Util::isweak( ${$probe_ref} ) );
        my $before_dump =
            Data::Dumper->new( [$probe_ref], [qw(proberef)] )
            ->Maxdepth($compare_depth)->Dump();
        my $before_reporting_dump;
        if ( $reporting_depth >= 0 ) {
            #<<< perltidy doesn't do this well
            $before_reporting_dump =
                Data::Dumper->new(
                    [$probe_ref],
                    [qw(proberef_before_callback)]
                )
                ->Maxdepth($reporting_depth)
                ->Dump();
            #>>>
        }

        my $scalar_return_value;
        my @array_return_value;
        if ($array_context) {
            @array_return_value = $ignore->($probe_ref);
        }
        else {
            $scalar_return_value = $ignore->($probe_ref);
        }

        my $after_weak =
            ( ref $probe_ref eq 'REF'
                and Scalar::Util::isweak( ${$probe_ref} ) );
        my $after_dump =
            Data::Dumper->new( [$probe_ref], [qw(proberef)] )
            ->Maxdepth($compare_depth)->Dump();
        my $after_reporting_dump;
        if ( $reporting_depth >= 0 ) {
            #<<< perltidy doesn't do this well
            $after_reporting_dump =
                Data::Dumper->new(
                    [$probe_ref],
                    [qw(proberef_after_callback)]
                )
                ->Maxdepth($reporting_depth)
                ->Dump();
            #<<<
        }

        my $problems       = q{};
        my $include_before = 0;
        my $include_after  = 0;

        if ( $before_weak != $after_weak ) {
            my $changed = $before_weak ? 'strengthened' : 'weakened';
            $problems .= "Probe referent $changed by ignore call\n";
            $include_before = defined $before_reporting_dump;
        }
        if ( $before_dump ne $after_dump ) {
            $problems .= "Probe referent changed by ignore call\n";
            $include_before = defined $before_reporting_dump;
            $include_after  = defined $after_reporting_dump;
        }

        if ($problems) {

            $error_count++;

            my $message = q{};
            $message .= $before_reporting_dump
                if $include_before;
            $message .= $after_reporting_dump
                if $include_after;
            $message .= $problems;

            if ( $max_errors > 0 and $error_count >= $max_errors ) {
                $message
                    .= "Terminating ignore callbacks after finding $error_count error(s)";
                Carp::croak($message);
            }

            Carp::carp( $message . 'Above errors reported' );

        }

        return $array_context ? @array_return_value : $scalar_return_value;

    };
}

1;

__END__

=for stopwords abend misdesign misimplement unfreed deallocated deallocation referenceable builtin recursing globals Builtin OO destructor VSTRING LVALUE unevaluated subdirectory refaddr refcount indiscernable XSUB XSUBs mortalizing mortalize pre-calculated subr refcounts recurses dereferences filehandle filehandles Kegler perldoc AnnoCPAN CPAN CPAN's perl Ryde jettero Juerd morgon perrin Perlmonks ie GLOBs hashref coderef isa unblessed numize OOPery arrayref autovivified dup typemap arrayrefs Gtk2-Perl

=head1 NAME

Test::Weaken - Test that freed memory objects were, indeed, freed

=head1 SYNOPSIS

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/synopsis.t', 'synopsis')

=end Marpa::Test::Display:

 use Test::Weaken qw(leaks);

 # basic leaks detection
 my $leaks = leaks(sub {
                    my $obj = { one => 1,
                                two => [],
                                three => [3,3,3] };
                    return $obj;
                   });
 if ($leaks) {
     print "There were memory leaks from test 1!\n";
     printf "%d of %d original references were not freed\n",
         $leaks->unfreed_count(), $leaks->probe_count();
 } else {
     print "No leaks in test 1\n";
 }

 # or with various options
 $leaks = Test::Weaken::leaks(
    { constructor => sub {
        my @array = (42, 711);
        push @array, \@array;  # circular reference
        return \@array;
      },
      destructor  => sub {
        print "This could invoke an object destructor\n";
      },
      ignore  => sub {
        my ($ref) = @_;
        if (some_condition($ref)) {
          return 1;  # ignore
        }
        return 0; # don't ignore
      },
      contents  => sub {
        my ($ref) = @_;
        return extract_more_from($ref);
      },
    });
 if ($leaks) {
     print "There were memory leaks from test 2!\n";
     my $unfreed_proberefs = $leaks->unfreed_proberefs();
     print "These are the probe references to the unfreed objects:\n";
     require Data::Dumper;
     foreach my $ref (@$unfreed_proberefs) {
         print "ref $ref\n";
         print Data::Dumper->Dump([$ref], ['unfreed']);
     }
 }

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

=head1 DESCRIPTION

C<Test::Weaken> helps detect unfreed Perl data in arrays, hashes, scalars,
objects, etc, by descending recursively through structures and watching that
everything is freed.  Unfreed data is a useless overhead and may cause an
application to abend due to lack of memory.

Normally if the last reference to something is discarded then it and
anything in it is freed automatically.  But this might not occur due to
circular references, unexpected global variables or closures, or reference
counting mistakes in XSUBs.

C<Test::Weaken> is named for the strategy used to detect leaks.  References
are taken to the test objects and all their contents, then those references
are weakened and expected to be then freed.

There's options to ignore intentional globals, or include extra associated
data held elsewhere, or invoke an explicit destructor.  Unfreed parts are
reported and can be passed to other modules such as L<Devel::FindRef> to try
to discover why they weren't freed.

C<Test::Weaken> examines structures to an unlimited depth and is safe on
circular structures.

=head2 Tracking and Children

C<Test::Weaken> determines the contents of a data structure by the contents
of the top object of the test data structure, and recursively into the
contents of those sub-parts.  The following data types are tracked and their
contents examined,

    ARRAY       each of its values
    HASH        each of its values
    SCALAR      if a reference then the target thing
    CODE        no contents as yet
    tie ANY     the associated tie object from tied()

In an array or hash each scalar value has an independent existence and
C<Test::Weaken> tracks each individually (see L</Array and Hash Keys and
Values> below).

C<CODE> objects, ie. subroutines, are not examined for children.  This is a
limitation, because closures do hold internal references to data objects.
Future versions of C<Test::Weaken> might descend into CODE objects.

The following types are not tracked by default and not examined for
contents,

    GLOB
    IO         underlying a file handle
    FORMAT     always global
    LVALUE

GLOBs are usually either an entry in the Perl symbol table or a filehandle.
An IO is the file object underlying a filehandle.  Perl symbol tables are
usually permanent and shouldn't be tracked, but see L</File Handles> below
for tracking open files.

Builtin types added to Perl in the future and not known to C<Test::Weaken>
will not be tracked by default but could be requested with C<tracked_types>
below.

A variable of builtin type GLOB may be
a scalar which was assigned a GLOB value
(a scalar-GLOB) or it may simply be a GLOB (a pure-GLOB).
The issue that arises for
C<Test::Weaken> is that,
in the case of a scalar-GLOB,
the scalar and the GLOB may be tied separately.
At present,
the underlying tied variable of the scalar side of a
scalar-GLOB is ignored.
Only the underlying tied variable of the GLOB
is a child for
C<Test::Weaken>'s purposes.

=head2 Returns and Exceptions

The methods of C<Test::Weaken> do not return errors.
Errors are always thrown as exceptions.

=head1 EXPORTS

By default, C<Test::Weaken> exports nothing.  Optionally, C<leaks()> may be
requested in usual C<Exporter> style (see L<Exporter>).  (And C<poof()> from
L</OLD FUNCTIONS> too if desired.)

    use Test::Weaken 'leaks';   # import
    my $tester = leaks (...);

=head1 PORCELAIN METHODS

=head2 leaks

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/snippet.t', 'leaks snippet')

=end Marpa::Test::Display:

    my $leaks = Test::Weaken::leaks(
        {   constructor => sub { Buggy_Object->new() },
            destructor  => \&destroy_buggy_object,
        }
    );
    if ($leaks) {
        print "There are leaks\n";
    }

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

Check for leaks in the object created by the constructor function and return
either an evaluated C<Test::Weaken> object instance if there are leaks, or
Perl false if there are no leaks.

Instances of the C<Test::Weaken> class are called B<testers>.
An B<evaluated> tester is one on which the
tests have been run
and for which results are available.

Users who only want to know if there were unfreed data objects can
check the return value of C<leaks()> for Perl true or false.
Arguments to C<leaks()> are passed as a
hashref of named arguments.
C<leaks()> can also be called in a "short form",
where the constructor and destructor
are passed directly as code references.

=over 4

=item C<constructor =E<gt> $coderef>

The C<constructor> argument is required.
Its value must be a coderef returning a reference to the test data structure.

    my $leaks = leaks ({ constructor => sub {
                           return Some::Object->new(123);
                         },
                       });

For "short form" the constructor coderef is the first
argument,

    leaks (sub {
             return Some::Object->new(123);
          });

If the constructor returns a list of objects then all are checked.

    leaks (sub {
             return (Foo->new(), Bar->new());
          });

Usually this is when two objects are somehow inter-related and should weaken
away together, or perhaps sub-parts of an object not reached by the contents
tracing (or see C<contents> below for a more general way to reach such
sub-parts.)

=item C<destructor =E<gt> $coderef>

=item C<destructor_method =E<gt> $methodname>

An optional destructor is called just before C<Test::Weaken> tries to free
everything.  Some test objects or structures might require explicit
destruction when they're to be freed.

C<destructor> is called with the objects returned by the constructor

    &$destructor ($obj, ...)

For example,

    leaks ({ constructor => sub { return make_some_thing() },
             destructor  => sub {
                              my ($thing) = @_;
                              delete $thing->{'circular_ref'};
                            },
          });

For "short form" the destructor is an optional second argument,

    leaks (sub { Foo->new },
           sub {
             my ($foo) = @_;
             $foo->destroy;
           });

C<destructor_method> is called as a method on each object returned by the
constructor,

    $obj->$methodname();

For example if the constructed object (or objects) require an explicit
C<$foo-E<gt>destroy()> then

    leaks ({ constructor => sub { Foo->new },
             destructor_method => 'destroy' });

If both C<destructor> and C<destructor_method> are given then
C<destructor_method> calls are first, then C<destructor>.

An explicit destructor may be needed for things like toplevel windows in GUI
toolkits such as Wx and Gtk (and perhaps also some main loop iterations if
actual destruction is delayed).  Some object-oriented tree structures may
need explicit destruction too if parent and child nodes keep hard references
to each other, though it's usually more convenient if child-E<gt>parent is
only a weak reference.  (See also L<Object::Destroyer>.)

=item C<ignore =E<gt> $coderef>

=item C<ignore_preds =E<gt> [ $coderef, $coderef, ...]>

=item C<ignore_class =E<gt> $classname>

=item C<ignore_classes =E<gt> [ $classname, $classname, ... ]>

=item C<ignore_object =E<gt> $ref>

=item C<ignore_objects =E<gt> [ $ref, $ref, ... ]>

Ignore some things.  When a thing is ignored it's not tracked for leaks and
its contents are not examined.

C<ignore> and C<ignore_preds> take predicate functions.  If any of them
return true then the thing C<$ref> refers to is ignored.

    $bool = &$coderef ($ref);

For example

=begin Marpa::Test::Display:

## start display
## next 2 displays
is_file($_, 't/ignore.t', 'ignore snippet')

=end Marpa::Test::Display:

    sub ignore_all_tied_hashes {
        my ($ref) = @_;
        return (ref $ref eq 'HASH'
                && defined (tied %$ref));
    }
    my $tester = Test::Weaken::leaks(
        { constructor => sub { MyObject->new() },
          ignore      => \&ignore_all_tied_hashes,
        });

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

C<ignore_class> and C<ignore_classes> ignore blessed objects which are of
the given class or classes.  For example,

    my $leaks = Test::Weaken::leaks(
        { constructor => sub { MyObject->new() },
          ignore_class => 'My::Singleton',
        }

    my $leaks = Test::Weaken::leaks(
        { constructor => sub { MyObject->new() },
          ignore_classes => [ 'My::Singleton',
                              'My::PrinterDriver' ],
        }

Objects are checked with

    blessed($ref) && $ref->isa($classname)

which reaches any class-specific C<isa()> in the object in the usual way.
That allows classes to masquerade or have a dynamic "isa".  That's normally
fine and can be highly desirable in things like lazy loaders.

C<ignore_object> and C<ignore_objects> ignore the particular things referred
to by the each given C<$ref>.  For example,

    my $leaks = Test::Weaken::leaks(
        { constructor => sub { MyObject->new() },
          ignore_object => \%global_data,
        }

    my $leaks = Test::Weaken::leaks(
        { constructor => sub { MyObject->new() },
          ignore_objects => [ $obj1, $obj2 ],
        }

For both C<ignore_object> and C<ignore_objects> any C<undef>s among the refs
are ignored.  This is handy if a global might or might not have been
initialized yet.  These options are called "object" because they're most
often used with blessed objects, but unblessed things are fine too.

C<ignore> callbacks should not change the contents of C<$ref>.  Doing so
might cause an exception, an infinite loop, or erroneous results.  See
L</Debugging Ignore Subroutines> for a little help against bad C<ignore>.

When comparing references in a predicate it's good to use
C<Scalar::Util::refaddr()>.  Plain C<$ref==$something> can be tricked if
C<$ref> is an object with overloaded numize or C<==> (see L<overload>).

Another way to ignore is let globals etc go through as leaks and then filter
them from the C<$leaks-E<gt>unfreed_proberefs()> afterwards.  The benefit of
C<ignore> is that it excludes object contents too.

=item contents

An optional C<contents> function can tell C<Test::Weaken> about additional
Perl data objects which should be checked.

=begin Marpa::Test::Display:

## start display
## next 2 displays
is_file($_, 't/contents.t', 'contents sub snippet')

=end Marpa::Test::Display:

    sub my_extra_contents {
      my ($ref) = @_;
      if (blessed($ref) && $ref->isa('MyObject')) {
        return $ref->data, $ref->moredata;
      } else {
        return;
      }
    }
    my $leaks = Test::Weaken::leaks(
        { constructor => sub { return MyObject->new },
          contents    => \&my_extra_contents
        });

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

The given C<$coderef> is called for each Perl data object.  It should return
a list of additional Perl data objects, or an empty list if no extra
contents.

    @extra_contents = &$coderef ($ref);

C<contents> allows OOPery such as "inside-out" where object contents are
held separately.  It can also be used on wrappers for C-code objects where
some of the contents of a widget etc are not in Perl level structures but
only available through object method calls etc.

C<contents> and C<ignore> can be used together.  C<ignore> is called first
and if not ignored then C<contents> is called.

=item tracked_types

Optional C<tracked_types> is an arrayref of additional builtin types to
track.

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/filehandle.t', 'tracked_types snippet')

=end Marpa::Test::Display:

    my $test = Test::Weaken::leaks(
        {   constructor => sub {
                my $obj = MyObject->new;
                return $obj;
            },
            tracked_types => ['GLOB'],
        }
    );

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

The default tracking is per L</Tracking and Children> above.  The additional
types which may be tracked are

    GLOB
    IO
    FORMAT
    LVALUE

These names are per C<reftype()> of L<Scalar::Util>.  See L</File Handles>
below for setting up to track GLOBs as filehandles.

=back

=head2 unfreed_proberefs

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/snippet.t', 'unfreed_proberefs snippet')

=end Marpa::Test::Display:

    my $tester = Test::Weaken::leaks( sub { Buggy_Object->new() } );
    if ($tester) {
        my $unfreed_proberefs = $tester->unfreed_proberefs();
        foreach my $ref (@$unfreed_proberefs) {
            print "unfreed: $ref\n";
        }
    }

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

Return an arrayref of references to unfreed data objects.  Throws an
exception if there is a problem, for example if the tester has not yet been
evaluated.

The return value can be examined to pinpoint the source of a leak or produce
statistics about unfreed data objects.

=head2 unfreed_count

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/snippet.t', 'unfreed_count snippet')

=end Marpa::Test::Display:

    my $tester = Test::Weaken::leaks( sub { Buggy_Object->new() } );
    if ($tester) {
      printf "%d objects were not freed\n",
        $tester->unfreed_count();
    }

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

Return the count of unfreed data objects.
This is the  length of the C<unfreed_proberefs()> arrayref.
Throws an exception if there is a problem,
for example if the tester has not yet been evaluated.

=head2 probe_count

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/snippet.t', 'probe_count snippet')

=end Marpa::Test::Display:

        my $tester = Test::Weaken::leaks(
            {   constructor => sub { Buggy_Object->new() },
                destructor  => \&destroy_buggy_object,
            }
        );
        next TEST if not $tester;
        printf "%d of %d objects were not freed\n",
            $tester->unfreed_count(), $tester->probe_count();

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

Return the total number of probe references in the test,
including references to freed data objects.
This is the count of probe references
after C<Test::Weaken> was finished finding the descendants of
the test structure reference,
but before C<Test::Weaken> called the test structure destructor or reset the
test structure reference to C<undef>.
Throws an exception if there is a problem,
for example if the tester has not yet been evaluated.

=head1 PLUMBING METHODS

Most users can skip this section.
The plumbing methods exist to satisfy object-oriented purists,
and to accommodate the rare user who wants to access the probe counts
even when the test did find any unfreed data objects.

=head2 new

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/snippet.t', 'new snippet')

=end Marpa::Test::Display:

    my $tester        = Test::Weaken->new( sub { My_Object->new() } );
    my $unfreed_count = $tester->test();
    my $proberefs     = $tester->unfreed_proberefs();
    printf "%d of %d objects freed\n",
        $unfreed_count,
        $tester->probe_count();

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

The L</"new"> method takes the same arguments as the L</"leaks"> method, described above.
Unlike the L</"leaks"> method, it always returns an B<unevaluated> tester.
An B<unevaluated> tester is one on which the test has not yet
been run and for which results are not yet available.
If there are any problems, the L</"new">
method throws an exception.

The L</"test"> method is the only method that can be called successfully on
an unevaluated tester.
Calling any other method on an unevaluated tester causes an exception to be thrown.

=head2 test

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/snippet.t', 'test snippet')

=end Marpa::Test::Display:

    my $tester = Test::Weaken->new(
        {   constructor => sub { My_Object->new() },
            destructor  => \&destroy_my_object,
        }
    );
    printf "There are %s\n", ( $tester->test() ? 'leaks' : 'no leaks' );

Converts an unevaluated tester into an evaluated tester.
It does this by performing the test
specified
by the arguments to the L</"new"> constructor
and recording the results.
Throws an exception if there is a problem,
for example if the tester had already been evaluated.

The L</"test"> method returns the count of unfreed data objects.
This will be identical to the length of the array
returned by L</"unfreed_proberefs"> and
the count returned by L</"unfreed_count">.

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

=head1 ADVANCED TECHNIQUES

=head2 File Handles

File handles are references to GLOBs and by default are not tracked.  If a
handle is a package global like C<open FH, "</file/name"> then that's
probably what you want.  But if you use anonymous handles either from the
L<Symbol> module or Perl 5.6 autovivified then it's good to check the handle
is freed.  This can be done by asking for GLOB and IO in C<tracked_types>,
and extracting the IO from any GLOB encountered,

    sub contents_glob_IO {
      my ($ref) = @_;
      if (ref($ref) eq 'GLOB') {
        return *$ref{IO};
      } else {
        return;
      }
    }

    my $leaks = Test::Weaken::leaks
      ({ constructor => sub { return MyFileObject->new },
         contents => \&contents_glob_IO,
         tracked_types => [ 'GLOB', 'IO' ],
       });

It's good to check the IO too since it's possible for a reference elsewhere
to keep it alive, in particular a Perl-level "dup" can make another handle
GLOB pointing to that same IO,

    open my $dupfh, '<', $fh;
    # $dupfh holds and uses *$fh{IO}

See L<Test::Weaken::ExtraBits> for such a C<contents_glob_IO()>, if you want
to use a module rather than copying couple of lines for that function.

=head2 Array and Hash Keys and Values

As noted above each value in a hash or array is a separate scalar and is
tracked separately.  Usually such scalars are only used in their containing
hash or array, but it's possible to hold a reference to a particular element
and C<leaks()> can notice if that causes it to be unfreed.

    my %hash = (foo => 123);
    my $ref = \$hash{'foo'};  # ref to hash value

It's possible to put specific scalars as the values in a hash or array.
They might be globals or whatever.  Usually that would arise from XSUB code,
but L<Array::RefElem> can do the same from Perl code,

    use Array::RefElem 'av_store';
    my $global;
    my @array;
    av_store (@array, 0, $global);

In XSUB code a little care is needed that refcounts are correct after
C<av_store()> or C<hv_store()> takes ownership of one count etc.  In all
cases C<Test::Weaken> can notice when an array or hash element doesn't
destroy with its container.  C<ignore> etc will be needed for those which
are intentionally persistent.

Hash keys are not separate scalars.  They're strings managed entirely by the
hash and there's nothing separate for C<Test::Weaken> to track.

L<Tie::RefHash> and similar which allow arbitrary objects as keys of a hash
do so by using the object C<refaddr()> internally as the string key but
presenting objects in C<keys()>, C<each()>, etc.  As of L<Tie::RefHash> 1.39
and L<Tie::RefHash::Weak> 0.09 those two modules hold the key objects within
their tie object and therefore those key objects are successfully reached by
C<Test::Weaken> for leak checking in the usual way.

=head2 Tracing Leaks

=head3 Avoidance

C<Test::Weaken> makes tracing leaks easier, but avoidance is
still by far the best way,
and C<Test::Weaken> helps with that.
You need to use test-driven development, L<Test::More>,
modular tests in a C<t/> subdirectory,
and revision control.
These are all very good ideas for many other reasons.

Make C<Test::Weaken> part of your test suite.
Test frequently, so that when a leak occurs,
you'll have a good idea of what changes were made since
the last successful test.
Often, examining these changes is enough to
tell where the leak was introduced.

=head3 Adding Tags

The L</"unfreed_proberefs"> method returns an array containing
probes to
the unfreed
data objects.
This can be used
to find the source of leaks.
If circumstances allow it,
you might find it useful to add "tag" elements to arrays and hashes
to aid in identifying the source of a leak.

=head3 Using Referent Addresses

You can quasi-uniquely identify data objects using
the referent addresses of the probe references.
A referent address
can be determined by using C<refaddr()> from
L<Scalar::Util>.
You can also obtain the referent address of a reference by adding 0
to the reference.

Note that in other Perl documentation, the term "reference address" is often
used when a referent address is meant.
Any given reference has both a reference address and a referent address.
The B<reference address> is the reference's own location in memory.
The B<referent address> is the address of the Perl data object to which the reference refers.
It is the referent address that interests us here and,
happily, it is
the referent address that both zero addition
and L<refaddr|Scalar::Util/refaddr> return.

=head3 Other Techniques

Sometimes, when you are interested in why an object is not being freed,
you want to seek out the reference
that keeps the object's refcount above 0.
L<Devel::FindRef> can be useful for this.

=head2 More About Quasi-Unique Addresses

I call referent addresses "quasi-unique", because they are only
unique at a
specific point in time.
Once an object is freed, its address can be reused.
Absent other evidence,
a data object with a given referent address
is not 100% certain to be
the same data object
as the object that had the same address earlier.
This can bite you
if you're not careful.

To be sure an earlier data object and a later object with the same address
are actually the same object,
you need to know that the earlier object will be persistent,
or to compare the two objects.
If you want to be really pedantic,
even an exact match from a comparison doesn't settle the issue.
It is possible that two indiscernable
(that is, completely identical)
objects with the same referent address are different in the following
sense:
the first data object might have been destroyed
and a second, identical,
object created at the same address.
But for most practical programming purposes,
two indiscernable data objects can be regarded as the same object.

=head2 Debugging Ignore Subroutines

=head3 check_ignore

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/ignore.t', 'check_ignore 1 arg snippet')

=end Marpa::Test::Display:

    $tester = Test::Weaken::leaks(
        {   constructor => sub { MyObject->new() },
            ignore => Test::Weaken::check_ignore( \&ignore_my_global ),
        }
    );

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/ignore.t', 'check_ignore 4 arg snippet')

=end Marpa::Test::Display:

    $tester = Test::Weaken::leaks(
        {   constructor => sub { DeepObject->new() },
            ignore      => Test::Weaken::check_ignore(
                \&cause_deep_problem, 99, 0, $reporting_depth
            ),
        }
    );

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

It can be hard to determine if
C<ignore> callback subroutines
are inadvertently
modifying the test structure.
The
L<Test::Weaken::check_ignore|/"check_ignore">
static method is
provided to make this task easier.
L<Test::Weaken::check_ignore|/"check_ignore">
constructs
a debugging wrapper from
four arguments, three of which are optional.
The first argument must be the ignore callback
that you are trying to debug.
This callback is called the test subject, or
B<lab rat>.

The second, optional argument, is the maximum error count.
Below this count, errors are reported as warnings using L<Carp::carp|Carp>.
When the maximum error count is reached, an
exception is thrown using L<Carp::croak|Carp>.
The maximum error count, if defined,
must be an number greater than or equal to 0.
By default the maximum error count is 1,
which means that the first error will be thrown
as an exception.

If the maximum error count is 0, all errors will be reported
as warnings and no exception will ever be thrown.
Infinite loops are a common behavior of
buggy lab rats,
and setting the maximum error
count to 0 will usually not be something you
want to do.

The third, optional, argument is the B<compare depth>.
It is the depth to which the probe referents will be checked,
as described below.
It must be a number greater than or equal to 0.
If the compare depth is 0, the probe referent is checked
to unlimited depth.
By default the compare depth is 0.

This fourth, optional, argument is the B<reporting depth>.
It is the depth to which the probe referents are dumped
in
L<check_ignore's|/"check_ignore">
error messages.
It must be a number greater than or equal to -1.
If the reporting depth is 0, the object is dumped to unlimited depth.
If the reporting depth is -1, there is no dump in the error message.
By default, the reporting depth is -1.

L<Test::Weaken::check_ignore|/"check_ignore">
returns a reference to the wrapper callback.
If no problems are detected,
the wrapper callback behaves exactly like the lab rat callback,
except that the wrapper is slower.

To discover when and if the lab rat callback is
altering its arguments,
L<Test::Weaken::check_ignore|/"check_ignore">
compares the test structure
before the lab rat is called,
to the test structure after the lab rat returns.
L<Test::Weaken::check_ignore|/"check_ignore">
compares the before and after test structures in two ways.
First, it dumps the contents of each test structure using
L<Data::Dumper>.
For comparison purposes,
the dump using L<Data::Dumper> is performed with C<Maxdepth>
set to the compare depth as described above.
Second, if the immediate probe referent has builtin type REF,
L<Test::Weaken::check_ignore|/"check_ignore">
determines whether the immediate probe referent
is a weak reference or a strong one.

If either comparison shows a difference,
the wrapper treats it as a problem, and
produces an error message.
This error message is either a L<Carp::carp|Carp> warning or a
L<Carp::croak|Carp> exception, depending on the number of error
messages already reported and the setting of the
maximum error count.
If the reporting depth is a non-negative number, the error
message includes a dump from L<Data::Dumper> of the
test structure.
C<Data::Dumper>'s C<Maxdepth>
for reporting purposes is the reporting depth as described above.

A user who wants other features, such as deep checking
of the test structure
for strengthened references,
can easily 
copy
C<check_ignore()>
from the C<Test::Weaken> source
and hack it up.
C<check_ignore()>
is a static method
that does not use any C<Test::Weaken>
package resources.
The hacked version can reside anywhere,
and does not need to
be part of the C<Test::Weaken> package.

=head1 XSUB Mortalizing

When a C code XSUB returns a newly created scalar it should "mortalize" so
the scalar is freed once the caller has finished with it.  See
L<perlguts/Reference Counts and Mortality>.  Failing to do so leaks memory.

    SV *ret = newSViv(123);
    sv_2mortal (ret);   /* must mortalize */
    XPUSHs (ret);

C<Test::Weaken> can check this by taking a reference to the returned
scalar,

    my $leaks = leaks (sub {
                         return \( somexsub() );
                       });
    if ($leaks) ...

Don't store to a new local scalar and then return that since doing so will
only check the local scalar, not the one made by C<somexsub()>.

If you want the value for further calculations then first take a reference
to the return and then look through that for the value.

    leaks (sub {
             my $ref = \( somexsub() );
             my $value = $$ref;
             # ... do something with $value
             return $ref;
           });

If an XSUB returns a list of values then take a reference to each as
follows.  This works because C<map> and C<for> make the loop variable (C<$_>
or named) an alias to each value successively (see L<perlfunc/map> and
L<perlsyn/Foreach Loops>).

    leaks (sub {
             return [ map {\$_} somexsub() ];
           });

    # or with a for loop
    leaks (sub {
             my @refs;
             foreach my $value (somexsub()) {
               push @refs, \$value;
             }
             return \@refs;
           });

Don't store a returned list to an array (named or anonymous) since this
copies into new scalars in that array and the returned ones from
C<somexsub()> then aren't checked.

If you want the returned values for extra calculations then take the
references first and look through them for the values, as in the single case
above.  For example,

    leaks (sub {
             my @refs = map {\$_} somexsub();
             my $first_ref = $refs[0]
             my $value = $$first_ref;
             # ... do something with $value
             return \@refs;
           });

An XSUB might deliberately return the same scalar each time, perhaps a
pre-calculated constant or a global variable it maintains.  In that case the
scalar intentionally won't weaken away and this C<leaks()> checking is not
applicable.

Returning the same scalar every time occurs in pure Perl too with an
anonymous constant subr such as created by the C<constant> module (see
L<constant>).  This is unlikely to arise directly, but might be seen through
a scalar ref within an object etc.

    # FOO() returns same scalar every time
    *FOO = sub () { 123 };

    # same from the constant module
    use constant BAR => 456;

It's up to an XSUB etc how long return values are supposed to live.  But
generally if the code has any sort of C<newSV()> or C<sv_newmortal()> etc to
make a new scalar as its return then that ought to weaken away.

The details of an XSUB return are often hidden in a F<typemap> file for
brevity and consistency (see L<perlxs/The Typemap>).  The standard typemap
conversions of F<Extutils/typemap> are easy to use correctly.  But code with
explicit C<PUSHs()> etc is worth checking.  The reference counting rules for
C<av_push()> etc are slightly subtle too if building nested structures in
XS.  Usually missing mortalizing or ref count sinking will leak objects
which C<Test::Weaken> can detect.  Too much mortalizing or ref count sinking
will cause negative refcounts and probable segfaults.

=head1 OLD FUNCTIONS

The following C<poof()> was from C<Test::Weaken> 1.0 and has been superseded
in 2.0 by C<leaks()> which is easier to use.

=over

=item C<my $unfreed_count = Test::Weaken::poof(sub { return $obj });>

=item C<my ($weak_count, $strong_count, $weak_unfreed_aref, $strong_unfreed_aref) = Test::Weaken::poof(sub { return $obj });>

Check that C<$obj> returned by the given constructor subroutine is freed
when weakened.  This is the same as C<leaks()> except for the style of the
return values.

In scalar context the return is a count of unfreed references.  If
everything is freed then this is 0.

    my $unfreed_count = Test::Weaken::poof(sub { return [1,2,3] });
    if ($unfreed_count == 0 {
      print "No leaks\n";
    } else {
      print "There were leaks\n";
    }

In array context the return is four values

    my ($weak_count, $strong_count,
        $weak_unfreed_aref, $strong_unfreed_aref)
      = Test::Weaken::poof (sub { return $obj });

    $weak_count             count of weak refs examined
    $strong_count           count of strong refs examined
    $weak_unfreed_aref      arrayref of unfreed weak refs
    $strong_unfreed_aref    arrayref of unfreed strong refs

The counts are total references examined.  The arrayrefs give the unfreed
ones.  A distinction is made between strong references and weak references
in the test structure.  If there's no leaks then both C<$weak_unfreed_aref>
and C<$strong_unfreed_aref> are empty arrays.

There's usually not much interest in whether an unfreed thing was from a
weak or strong reference.  In the new C<leaks()> the C<unfreed_proberefs()>
gives both together.  The could be separated there by checking C<isweak()>
on each if desired.

=back

=head1 IMPLEMENTATION DETAILS

=head2 Overview

C<Test::Weaken> first recurses through the test structure.
Starting from the test structure reference,
it examines data objects for children recursively,
until it has found the complete contents of the test structure.
The test structure is explored to unlimited depth.
For each tracked Perl data object, a
probe reference is created.
Tracked data objects are recorded.
In the recursion, no object is visited twice,
and infinite loops will not occur,
even in the presence of cycles.

Once recursion through the test structure is complete,
the probe references are weakened.
This prevents the probe references from interfering
with the normal deallocation of memory.
Next, the test structure destructor is called,
if there is one.

Finally, the test structure reference is set to C<undef>.
This should trigger the deallocation of the entire contents of the test structure.
To check that this happened, C<Test::Weaken> dereferences the probe references.
If the referent of a probe reference was deallocated,
the value of that probe reference will be C<undef>.
If a probe reference is still defined at this point,
it refers to an unfreed Perl data object.

=head2 Why the Test Structure is Passed Via a Closure

C<Test::Weaken> gets its test structure reference
indirectly,
as the return value from a
B<test structure constructor>.
Why so roundabout?

Because the indirect way is the easiest.
When you
create the test structure
in C<Test::Weaken>'s calling environment,
it takes a lot of craft to avoid
leaving
unintended references to the test structure in that calling environment.
It is easy to get this wrong.
Those unintended references will
create memory leaks that are artifacts of the test environment.
Leaks that are artifacts of the test environment
are very difficult to sort out from the real thing.

The B<closure-local strategy> is the easiest way
to avoid leaving unintended references to the
contents of Perl data objects.
Using the closure-local strategy means working
entirely within a closure,
using only data objects local to that closure.
Data objects local to a closure will be destroyed when the
closure returns, and any references they held will be released.
The closure-local strategy makes
it relatively easy to be sure that nothing is left behind
that will hold an unintended reference
to any of the contents
of the test structure.

Nothing prevents a user from
subverting the closure-local strategy.
A test structure constructor
can return a reference to a test structure
created from Perl data objects in any scope the user desires.

=head1 AUTHOR

Jeffrey Kegler

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-weaken at
rt.cpan.org>, or through the web interface at

    http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Weaken

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

=begin Marpa::Test::Display:

## skip display

=end Marpa::Test::Display:

    perldoc Test::Weaken

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Weaken>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Weaken>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Weaken>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Weaken>

=back

=head1 SEE ALSO

L<Test::Weaken::ExtraBits>, miscellaneous extras

L<Test::Weaken::Gtk2>, extras for use with Gtk2-Perl

L<Scalar::Util>,
L<Scalar::Util::Instance>

C<Test::Weaken>
at this point is robust
and has 
seen extensive use.
Its tracking of memory is careful enough
that it has even stumbled upon
a bug in perl 
itself L<http://rt.perl.org/rt3/Public/Bug/Display.html?id=67838>.

=head1 ACKNOWLEDGEMENTS

Thanks to jettero, Juerd, morgon and perrin of Perlmonks for their advice.
Thanks to Lincoln Stein (developer of L<Devel::Cycle>) for
test cases and other ideas.
Kevin Ryde made many important suggestions
and provided the test cases which
provided the impetus
for the versions 2.000000 and after.
For version 3.000000, Kevin also provided patches.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jeffrey Kegler, all rights reserved.

Copyright 2012 Kevin Ryde

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.10.

=cut

1;    # End of Test::Weaken



# For safety, L<Test::Weaken|/"NAME"> passes
# the L</contents> callback a copy of the internal
# probe reference.
# This prevents the user
# altering
# the probe reference itself.
# However,
# the data object referred to by the probe reference is not copied.
# Everything that is referred to, directly or indirectly,
# by this
# probe reference
# should be left unchanged by the L</contents>
# callback.
# The result of modifying the probe referents might be
# an exception, an abend, an infinite loop, or erroneous results.

# Use of the L</contents> argument should be avoided
# when possible.
# Instead of using the L</contents> argument, it is
# often possible to have the constructor
# create a reference to a "wrapper structure",
# L<as described above in the section on nieces|/"Nieces">.
# The L</contents> argument is
# for situations where the "wrapper structure"
# technique is not practical.
# If, for example,
# creating the wrapper structure would involve a recursive
# descent through the lab rat object,
# using the L</contents> argument may be easiest.

# When specified, the value of the L</contents> argument must be a
# reference to a callback subroutine.
# If the reference is C<$contents>,
# L<Test::Weaken|/"NAME">'s call to it will be the equivalent
# of C<< $contents->($safe_copy) >>,
# where C<$safe_copy> is a copy of the probe reference to
# a Perl data object.
# The L</contents> callback is made once
# for every Perl data object
# when that Perl data object is
# about to be examined for children.
# This can impose a significant overhead.
# 
# The example of a L</contents> callback above adds data objects whenever it
# encounters a I<reference> to a blessed object.
# Compare this with the example for the L</ignore> callback above.
# Checking for references to blessed objects will not produce the same
# behavior as checking for the blessed objects themselves --
# there may be many references to a single
# object.



# =head2 Persistent Objects
# 
# As a practical matter, a descendant that is not
# part of the contents of a
# test structure is only a problem
# if its lifetime extends beyond that of the test
# structure.
# A descendant that is expected to stay around after
# the test structure is destroyed
# is called a B<persistent object>.
# 
# A persistent object is not a memory leak.
# That's the problem.
# L<Test::Weaken|/"NAME"> is trying to find memory leaks
# and it looks for data objects that remain
# after the test structure is freed.
# But a persistent object is not expected to
# disappear when the test structure goes away.
# 
# We need to
# separate the unfreed data objects which are memory leaks,
# from those which are persistent data objects.
# It's usually easiest to do this after the test by
# examining the return value of L</"unfreed_proberefs">.
# The C<ignore> named argument can also be used
# to pass L<Test::Weaken|/"NAME"> a closure
# that separates out persistent data objects "on the fly".
# These methods are described in detail
# L<below|/"ADVANCED TECHNIQUES">.

# =head2 Nieces
# 
# A B<niece data object> (also a B<niece object> or just a B<niece>)
# is a data object that is part of the contents of a data 
# structure,
# but that is not a descendant of the top object of that
# data structure.
# When the OO technique called
# "inside-out objects" is used,
# most of the attributes of the blessed object will be
# nieces.
# 
# In L<Test::Weaken|/"NAME">,
# usually the easiest way to deal with non-descendant contents
# is to make the
# data structure you are trying to test
# the B<lab rat> in a B<wrapper structure>.
# In this scheme,
# your test structure constructor will return a reference
# to the top object of the wrapper structure,
# instead of to the top object of the lab rat.
# 
# The top object of the wrapper structure will be a B<wrapper array>.
# The wrapper array will contain the top object of the lab rat,
# along with other objects.
# The other objects need to be
# chosen so that the contents of the 
# wrapper array are exactly
# the wrapper array itself, plus the contents
# of the lab rat.
# 
# It is not always easy to find the right objects to put into the wrapper array.
# For example, determining the contents of the lab rat may
# require a recursive scan from the lab rat's
# top object.
# Depending on the logical structure of the lab rat,
# this may be far from trivial.
# 
# As an alternative to using a wrapper,
# it is possible to have L<Test::Weaken|/"NAME"> add
# contents "on the fly," while it is scanning the lab rat.
# This can be done using L<the C<contents> named argument|/contents>,
# which takes a closure as its value.

# =head2 Data Objects, Blessed Objects and Structures
# 
# B<Object> is a heavily overloaded term in the Perl world.
# This document will use the term B<Perl data object>
# or B<data object> to refer to any referenceable Perl datum,
# including
# scalars, arrays, hashes, references themselves, and code objects.
# The full list of types of referenceable Perl data objects
# is given in
# L<the description of the ref builtin in the Perl documentation|perlfunc/"ref">.
# An B<object> that has been blessed using the Perl
# L<bless builtin|perlfunc/"bless">, will be called a B<blessed object>.
# 
# In this document,
# a Perl B<data structure> (often just called a B<structure>)
# is any group of Perl objects that are
# co-mortal.
# B<Co-mortal> means that the maintainer
# expects those objects to be destroyed at the same time.
# For example, if a group of Perl objects is referenced,
# directly or indirectly,
# through a hash,
# and is referenced only through that hash,
# a programmer will usually expect all of those objects
# to be destroyed when the hash is.
# 
# Perl data structures can be any set of
# Perl data objects.
# Since the question is one of I<expected> lifetime,
# whether an object is part of a data structure
# is, in the last analysis, subjective.
# 
# =head2 The Contents of a Data Structure
# 
# A B<data structure> must have one object
# that is designated as its B<top object>.
# In most data structures, it is obvious which
# data object should be designated as the top object.
# The objects
# in the data structure, including the top object,
# are the B<contents> of that data structure.
# 
# L<Test::Weaken|/"NAME"> gets its B<test data structure>,
# or B<test structure>,
# from a closure.
# The closure should return
# a reference to the test structure.
# This reference is called the B<test structure reference>.

# =head2 Builtin Types
# 
# This document will refer to the builtin type of objects.
# Perl's B<builtin types> are the types Perl originally gives objects,
# as opposed to B<blessed types>, the types assigned objects by
# the L<bless function|perlfunc/"bless">.
# The builtin types are listed in
# L<the description of the ref builtin in the Perl documentation|perlfunc/"ref">.
# 
# Perl's L<ref function|perlfunc/"ref"> returns the blessed type of its
# argument, if the argument has been blessed into a package.
# Otherwise the 
# L<ref function|perlfunc/"ref"> returns the builtin type.
# The L<Scalar::Util/reftype function> always returns the builtin type,
# even for blessed objects.

# L<Data::Dumper> does not deal with
# IO and LVALUE objects
# gracefully,
# issuing a cryptic warning whenever it encounters them.
# Since L<Data::Dumper> is a Perl core module
# in extremely wide use, this suggests that these IO and LVALUE
# objects are, to put it mildly,
# not commonly encountered as the contents of data structures.



#   fill-column: 100
#
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
# End:
# vim: expandtab shiftwidth=4:
