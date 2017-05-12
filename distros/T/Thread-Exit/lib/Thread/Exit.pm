package Thread::Exit;

# Make sure we have version info for this module
# Make sure we do everything by the book from now on

$VERSION = '0.09';
use strict;

# Make sure we only load stuff when we actually need it

use load;

# Make sure we can do threads

use threads ();

# Thread local flag to indicate we're exiting

my $exiting = 0;

# Clone detection logic
# Thread local flag for automatic inheritance
# Thread local reference to BEGIN routine that executes after thread has ended
# Thread local reference to END routine that executes after thread has ended

our $CLONE = 0;
our $inherit = 1;
our $begin;
our $end;

# Make sure we do this before anything else
#  Allow for dirty tricks
#  Hijack the thread creation routine with a sub that
#   Saves the class
#   Save the context

BEGIN {
    no strict 'refs'; no warnings 'redefine';
    my $new = \&threads::new;
    *threads::new = sub {
        my $class = shift;
        my $sub = shift;
        my $wantarray = wantarray;

#   Save the original reference of sub to execute
#   Creates a new thread with a sub
#    Execute the begin routine (if there is one)
#    Execute the original sub within an eval {} context and save return values
#    Save result of eval (args to return if $exiting, or a warning to re-raise)

        $new->( $class,sub {  # closure!
            &$begin if $begin;
            my $return = [eval { $sub->( @_ ) }];

#    If we're exiting
#     Fetch our arguments for a join()ing thread from $@ (@$return is empty)
#     Clear $@ for the benefit of end routines (if any)
#    Elsif we died in another way inside the thread
#     Show the error
#    Execute the end routine (if there is one)
#    Return whatever we need to return

            if ($exiting) {
                $return = $@;
                $@ = '';
            } elsif ($@) {
                warn $@;
            }
            $end->( $exiting ) if $end;
            return $wantarray ? @{$return} : $return->[0];
        },@_ );
    };

# Make sure "create" does the same

    *threads::create = \&threads::new;

#  Steal the system exit with a sub
#   If we're in a thread started after this was loaded
#    Set the exiting flag
#    Freeze parameters and use that to die with (winds up in $@ later)
#   Elsif we're in mod_perl (and in originating thread)
#    Call the mod_perl exit routine
#   Perform the standard exit

    *CORE::GLOBAL::exit = sub {
        if ($CLONE) {
            $exiting = 1;
            die [@_];
        } elsif (exists( &Apache::exit )) {
            goto &Apache::exit;
        }
        CORE::exit( shift || 0 ); # goto or @_ do not work for some reason
    };
} #BEGIN

# Satisfy -require-

1;

#---------------------------------------------------------------------------

# standard Perl features

#---------------------------------------------------------------------------

sub CLONE {

# Mark this thread as a child
# Disable begin and end sub if not automatically inheriting

    $CLONE++;
    $begin = $end = undef unless $inherit;
} #CLONE

#---------------------------------------------------------------------------

# The following subroutines are loaded only on demand

__END__

#---------------------------------------------------------------------------

# class methods

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new subroutine specification (undef to disable)
#      3 flag: chain before (-1), after (1) or replace (0 = default)
# OUT: 1 current code reference

sub begin { shift; $begin = _setsub( $begin,@_ ) } #begin

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new subroutine specification (undef to disable)
#      3 flag: chain before (-1), after (1) or replace (0 = default)
# OUT: 1 current code reference

sub end { shift; $end = _setsub( $end,@_ ) } #end

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new setting of inherit flag
# OUT: 1 current setting of inherit flag

sub inherit {

# Set new inherit flag if one specified
# Return current setting

    $inherit = $_[1] if @_ > 1;
    $inherit;
} #inherit

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)

sub ismain { $CLONE = 0 } #ismain

#---------------------------------------------------------------------------

# internal subroutines

#---------------------------------------------------------------------------
#  IN: 1 current subroutine specification
#      2 new subroutine specification (undef to disable)
#      3 flag: chain before (-1), after (1) or replace (0 = default)
# OUT: 1 new code reference

sub _setsub {

# If we have a new subroutine specification
#  Get new setting
#  If it is not empty and not a code reference yet
#   Make the subref absolute if it isn't yet
#   Convert to a code ref

    my $current = shift;
    if (@_) {
        my $new = $_[0];
        if ($new and !ref($new)) {
            $new = caller(2).'::'.$new unless $new =~ m#::#;
            $new = \&$new;
        }

#  If we have an old and a new subroutine and we're not replacing
#   Obtain copy of current code ref
#   If chaining this before current
#    Create closure anonymous sub with new one first
#   Else (chaining after current)
#    Create closure anonymous sub with old one first

        if ($current and $new and $_[1]) {
            my $old = $current;
            if ($_[1] < 0) {
	        $current = sub { &$new; &$old };
            } else {
	        $current = sub { &$old; &$new };
            }

#  Else (resetting or replacing or no old)
#   Just set the new value
# Return the current code reference

        } else {
            $current = $new;
        }
    }
    $current;
} #_setsub

#---------------------------------------------------------------------------

# standard Perl features

#---------------------------------------------------------------------------
#  IN: 1 class
#      2..N method/value hash

sub import {

# Get the parameter hash
# For all of the methods and values
#  Die now if invalid method
#  Call the method with the value

    my ($class,%param) = @_;
    while (my ($method,$value) = each %param) {
        die "Cannot call method $method during initialization\n"
         unless $method =~ m#^(?:begin|end|inherit)$#;
        $class->$method( $value );
    }
} #import

#---------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Exit - provide thread-local exit(), BEGIN {}, END {} and exited()

=head1 SYNOPSIS

    use Thread::Exit ();   # just make exit() thread local

    use Thread::Exit
     begin => 'begin_sub', # sub to exec at beginning of thread (default: none)
     end => 'end_sub',     # sub to exec at end of thread (default: none)
     inherit => 1,         # make all new threads inherit (default: 1)
    ;

    $thread = threads->new( sub { exit( "We've exited" ) } ); # or "create"
    print $thread->join;            # prints "We've exited"

    Thread::Exit->ismain;           # mark this thread as main thread

    Thread::Exit->begin( \$begin_sub ); # set/adapt BEGIN sub later
    Thread::Exit->begin( undef );       # disable BEGIN sub
    $begin = Thread::Exit->begin;

    Thread::Exit->end( \$end_sub ); # set/adapt END sub later
    Thread::Exit->end( undef );     # disable END sub
    $end = Thread::Exit->end;

    Thread::Exit->inherit( 1 );     # make all new threads inherit settings
    Thread::Exit->inherit( 0 );     # new threads won't inherit settings
    $inherit = Thread::Exit->inherit;

=head1 DESCRIPTION

                  *** A note of CAUTION ***

 This module only functions on Perl versions 5.8.0 and later.
 And then only when threads are enabled with -Dusethreads.  It
 is of no use with any version of Perl before 5.8.0 or without
 threads enabled.

                  *************************

This module adds three features to threads that are sorely missed by some.

The first feature is that you can use exit() within a thread to return() from
that thread only.  Without this module, exit() stops B<all> threads and exits
to the calling process (which usually is the operating system).  With this
module, exit() functions just as return() (including passing back values to
the parent thread).

The second feature is that you can specify a subroutine that will be executed
B<after> the thread is started, but B<before> the subroutine of which the
thread consists, is started.  This is an alternate implementation of the
CLONE subroutine, which differs by being B<really> executed inside the context
of the new thread (as shown by the value of C<threads->tid>). Multiple "begin"
subroutines can be chained together if necessary.

The third feature is that you can specify a subroutine that will be executed
B<after> the thread is done, but B<before> the thread returns to the parent
thread.  This is similar to the END subroutine, but on a per-thread basis.
Multiple "end" subroutines can be chained together if necessary.

=head1 CLASS METHODS

These are the class methods.

=head2 begin

 Thread::Exit->begin( 'begin' );             # execute "begin"

 Thread::Exit->begin( undef );               # don't execute anything

 Thread::Exit->begin( 'module::before',-1 ); # execute "module::before" first

 Thread::Exit->begin( \&after,1 );           # execute "after" last

 $begin = Thread::Exit->begin;               # return current code reference

The "begin" class method sets and returns the subroutine that will be executed
B<after> the current thread is started but B<before> it starts the actual
subroutine of which the thread consists.  It is similar to the CLONE
subroutine, but is really executed in the context of the thread (whereas
CLONE currently fakes this for performance reasons, causing XS routines and
threads->tid to be executed in the wrong context).

The first input parameter is the name or a reference to the subroutine that
should be executed before this thread really starts.  It can be specified as a
name or as a code reference.  No changes will be made if no parameters are
specified.  If the first parameter is undef()ined or empty, then no subroutine
will be executed when this thread has started.

The second input parameter only has meaning if there has been a "begin"
subroutine specified before.  The following values are recognized:

=over 2

=item replace (0)

If the value B<0> is specified, then the new subroutine specification will
B<replace> any current "begin" subroutine specification done earlier.  This is
the default.

=item after (1)

If the value B<1> is specified, then the subroutine specificed will be
executed B<after> any other "begin" subroutine that was specified earlier.

=item before (-1)

If the value B<-1> is specified, then the subroutine specificed will be
executed B<before> any other "begin" subroutine that was specified earlier.

=back

By default, new threads inherit the settings of the "begin" subroutine.
Check the L<inherit> method to change this.

=head2 end

 Thread::Exit->end( 'end' );               # execute "end"

 Thread::Exit->end( undef );               # don't execute anything

 Thread::Exit->end( 'module::before',-1 ); # execute "module::before" first

 Thread::Exit->end( \&after,1 );           # execute "after" last

 $end = Thread::Exit->end;                 # return current code reference

The "end" class method sets and returns the subroutine that will be executed
B<after> the current thread is finished but B<before> it will return via a
join().

The "end" subroutine is passed a single flag which is true if the thread
is exiting by calling exit().  Please note that the system variable C<$@>
is also set if the thread exited because of a compilation or execution error.

The first input parameter is the name or a reference to the subroutine that
should be executed after this thread is finished.  It can be specified as a
name or as a code reference.  No changes will be made if no parameters are
specified.  If the first parameter is undef()ined or empty, then no subroutine
will be executed when this thread ends.

The second input parameter only has meaning if there has been an "end"
subroutine specified before.  The following values are recognized:

=over 2

=item replace (0)

If the value B<0> is specified, then the new subroutine specification will
B<replace> any current "end" subroutine specification done earlier.  This is
the default.

=item after (1)

If the value B<1> is specified, then the subroutine specificed will be
executed B<after> any other "end" subroutine that was specified earlier.

=item before (-1)

If the value B<-1> is specified, then the subroutine specificed will be
executed B<before> any other "end" subroutine that was specified earlier.

=back

By default, new threads inherit the settings of the "end" subroutine.
Check the L<inherit> method to change this.

=head2 inherit

 Thread::Exit->inherit( 1 );         # default, new threads inherit

 Thread::Exit->inherit( 0 );         # new threads don't inherit

 $inherit = Thread::Exit->inherit;   # return current setting

The "inherit" class method sets and returns whether newly created threads
will inherit the "begin" and "end" subroutine settings (as previously
indicated with a call to the L<begin> or L<end> class methods).

If an input parameter is specified, it indicates the new setting of this flag.
A true value indicates that new threads should inherit the "begin" and "end"
subroutine settings.  A false value indicates that new threads should B<not>
have any "begin" or "end" subroutine (unless of course specified otherwise
inside the thread after the thread has started).

The default settings is B<1>, causing L<begin> and L<end> settings to be
inherited by newly created threads.

=head2 ismain

 Thread::Exit->ismain;

The "ismain" class method is only needed in very special situation.  It marks
the current thread as the "main" thread from which a "real" exit() should
occur.

By default, only the thread in which the C<use Thread::Exit> occurred, will
perform a "real" exit (either to CORE::exit() or to Apache::exit() when in a
mod_perl environment).  This may however, not always be right.  In those cases
you can use this class method.

=head1 REQUIRED MODULES

 load (0.12)

=head1 MOD_PERL

To allow this module to function under Apache with mod_perl, a special check
is included for the existence of the Apache::exit() subroutine.  If the
Apache::exit() subroutine exists, then that exit routine will be preferred
over the CORE::exit() routine when exiting from the thread in which the
first C<use Thread::Exit> occurred.

=head1 TODO

Examples should be added.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 ACKNOWLEDGEMENTS

Nick Ing-Simmons and Rafael Garcia-Suarez for their suggestions and support.
Mike Pomraning for pointing out that C<die()> can also take a reference as
a parameter inside an C<eval()>, so that the dependency on Thread::Serialize
could be removed.

=head1 COPYRIGHT

Copyright (c) 2002-2003 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<threads>.

=cut
