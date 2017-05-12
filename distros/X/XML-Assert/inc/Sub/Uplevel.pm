#line 1
package Sub::Uplevel;

use strict;
use vars qw($VERSION @ISA @EXPORT);
$VERSION = '0.1901';

# We must override *CORE::GLOBAL::caller if it hasn't already been 
# overridden or else Perl won't see our local override later.

if ( not defined *CORE::GLOBAL::caller{CODE} ) {
    *CORE::GLOBAL::caller = \&_normal_caller;
}

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(uplevel);

#line 83

use vars qw/@Up_Frames $Caller_Proxy/;
# @Up_Frames -- uplevel stack
# $Caller_Proxy -- whatever caller() override was in effect before uplevel

sub uplevel {
    my($num_frames, $func, @args) = @_;
    
    local @Up_Frames = ($num_frames, @Up_Frames );
    
    # backwards compatible version of "no warnings 'redefine'"
    my $old_W = $^W;
    $^W = 0;

    # Update the caller proxy if the uplevel override isn't in effect
    local $Caller_Proxy = *CORE::GLOBAL::caller{CODE}
        if *CORE::GLOBAL::caller{CODE} != \&_uplevel_caller;
    local *CORE::GLOBAL::caller = \&_uplevel_caller;
    
    # restore old warnings state
    $^W = $old_W;

    return $func->(@args);
}

sub _normal_caller (;$) { ## no critic Prototypes
    my $height = $_[0];
    $height++;
    if ( CORE::caller() eq 'DB' ) {
        # passthrough the @DB::args trick
        package DB;
        if( wantarray and !@_ ) {
            return (CORE::caller($height))[0..2];
        }
        else {
            return CORE::caller($height);
        }
    }
    else {
        if( wantarray and !@_ ) {
            return (CORE::caller($height))[0..2];
        }
        else {
            return CORE::caller($height);
        }
    }
}

sub _uplevel_caller (;$) { ## no critic Prototypes
    my $height = $_[0] || 0;

    # shortcut if no uplevels have been called
    # always add +1 to CORE::caller (proxy caller function)
    # to skip this function's caller
    return $Caller_Proxy->( $height + 1 ) if ! @Up_Frames;

#line 188

    my $saw_uplevel = 0;
    my $adjust = 0;

    # walk up the call stack to fight the right package level to return;
    # look one higher than requested for each call to uplevel found
    # and adjust by the amount found in the Up_Frames stack for that call.
    # We *must* use CORE::caller here since we need the real stack not what 
    # some other override says the stack looks like, just in case that other
    # override breaks things in some horrible way

    for ( my $up = 0; $up <= $height + $adjust; $up++ ) {
        my @caller = CORE::caller($up + 1); 
        if( defined $caller[0] && $caller[0] eq __PACKAGE__ ) {
            # add one for each uplevel call seen
            # and look into the uplevel stack for the offset
            $adjust += 1 + $Up_Frames[$saw_uplevel];
            $saw_uplevel++;
        }
    }

    # For returning values, we pass through the call to the proxy caller
    # function, just at a higher stack level
    my @caller;
    if ( CORE::caller() eq 'DB' ) {
        # passthrough the @DB::args trick
        package DB;
        @caller = $Sub::Uplevel::Caller_Proxy->($height + $adjust + 1);
    }
    else {
        @caller = $Caller_Proxy->($height + $adjust + 1);
    }

    if( wantarray ) {
        if( !@_ ) {
            @caller = @caller[0..2];
        }
        return @caller;
    }
    else {
        return $caller[0];
    }
}

#line 298


1;
