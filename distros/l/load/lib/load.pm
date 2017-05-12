package load;

$VERSION= '0.23';

#-------------------------------------------------------------------------------
# No, we're NOT using strict here.  There are several reasons, the most
# important being that strict bleeds into the string eval's that load.pm
# is doing, causing compilation errors in all but the most simple modules.
# If you _do_ want stricture as a developer of load.pm, simply de-activate
# the lines of the BEGIN block below here
#-------------------------------------------------------------------------------
BEGIN { # We're fooling the Kwalitee checker into thinking we're strict
use strict;
}

# do this at compile time
my $now;
BEGIN {

    # make sure we have warnings or dummy warnings for older Perl's
    eval { require warnings } or do { $INC{'warnings.pm'} = '' };

    # set flag indicating whether everything should be loaded immediately
    $now= $ENV{'LOAD_NOW'} || 0;   # environment var undocumented for now

    # "ifdef" is loaded, can we use it?
    if (defined $ifdef::VERSION) {
        die "Must have 'ifdef' version 0.07 or higher to handle on demand loading\n"
          if $ifdef::VERSION < 0.07;
        *IFDEF= sub () { 1 };
    }

    # ifdef not loaded
    else {
        *IFDEF= sub () { 0 };
    }

    # we're supposed to trace
    if ($ENV{'LOAD_TRACE'}) {
        *TRACE= sub () { 1 };
        eval <<'EOD'; # only way to ensure it isn't there when we're not tracing
sub _trace {
    my $tid = $threads::VERSION ? ' ['.threads->tid.']' : '';
    warn "load$tid: ",$_[0],$/;
} #_trace
EOD
    }

    # we're not supposed to trace
    else {
        *TRACE= sub () { 0 };
    }

    # make sure we intercept ->can
    no warnings 'redefine';
    my $can= \&UNIVERSAL::can;
    *UNIVERSAL::can= sub {
        &{$can}( @_ ) || (ref( $_[0] ) ? undef : _can( @_ ))
    };
} #BEGIN

# hash with modules that should be used extra, keyed to package
my %use;

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Class Methods
#
#-------------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 package for which to add additional use-s
#      3 additional module to be used

sub register { $use{ $_[1] }= ( $use{ $_[1] } || '' ) . "use $_[2];" } #register

#-------------------------------------------------------------------------------
#
# Standard Perl Features
#
#-------------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2..N various parameters

sub import {
    my $class  = shift;
    my ($module,undef,$lineno) = caller();

    # need to check / handle parameters specified
    if (@_) {
        my $inmain=   ( $module eq 'main' );
        my $autoload= !$inmain;
        my $scan=     1;
        my $thisnow=  $now;

        # check each parameter separately
        foreach (@_) {

            # handle "now"
            if ( $_ eq 'now' ) {
                ( $inmain ? $now= $thisnow : $thisnow )= $scan= 1;
            }

            # handle "ondemand"
            elsif ( $_ eq 'ondemand' ) {
                ( $inmain ? $now= $thisnow : $thisnow )= 0;
                $scan= 1;
            }

            # want to export AUTOLOAD sub (AUTOLOAD = AutoLoader compatible)
            elsif ( m#^(?:autoload|AUTOLOAD)$# ) {
                die "Can not $_ in main namespace" if $inmain;
                $autoload= 1;
            }

            # don't want to scan now
            elsif ( $_ eq 'dontscan' ) {
                ( $inmain ? $now= $thisnow : $thisnow )= $scan= 0;
            }

            # want to inherit AUTOLOAD
            elsif ( $_ eq 'inherit' ) {
                die "Can not inherit in main namespace" if $inmain;
                $autoload= 0;
            }

            # want to enable AutoLoader mode
            elsif ( $_ eq 'AutoLoader' ) {
                die "Can only activate AutoLoader emulation mode from script"
                  if !$inmain;

                # did not emulate AutoLoader before
                if ( !$INC{'AutoLoader.pm'} or
                      $INC{'AutoLoader.pm'} ne $INC{__PACKAGE__.'.pm' } ) {
                    *AutoLoader::import=   \&import;
                    *AutoLoader::AUTOLOAD= \&AUTOLOAD;

                    # mark as loaded now, owned by us
                    $INC{'AutoLoader.pm'}= $INC{__PACKAGE__.'.pm'};
                }
            }

            # huh?
            else {
                die "Don't know how to handle $_";
            }
        }

        # in a module, scan it if necessary
        if ( !$inmain ) {
            _scan( $module, $thisnow ) if $scan;
            no strict 'refs';
            *{$module.'::AUTOLOAD'}= \&AUTOLOAD if $autoload;
        }
    }

    # called from a script / command line, huh?
    elsif ( $module eq 'main' ) {
       die "Does not make sense to just 'use $class;' from your script"
         if $lineno;
    }

    # no parameters, scan the source
    else {
        _scan( $module );

        # export AUTOLOAD if called here
        if ( $class eq __PACKAGE__ ) {
            no strict 'refs';
            *{$module.'::AUTOLOAD'}= \&AUTOLOAD;
        }
    }
} #import

#-------------------------------------------------------------------------------

sub AUTOLOAD {

    # go execute intended AUTOLOAD if possible
    $load::AUTOLOAD =~ m#^(.*)::(.*?)$#;
    goto &{$load::AUTOLOAD} if _can( $1, $2 );

    # nothing to do if unknown DESTROY
    return if $2 eq 'DESTROY';

    # huh?
    my ( $package, $filename, $line )= caller;
    die "Undefined subroutine &$load::AUTOLOAD called at $filename line $line\n";
} #AUTOLOAD

#-------------------------------------------------------------------------------
#
# Internal Subroutines
#
#-------------------------------------------------------------------------------
# _scan
#
# Set up / load given module
#
#  IN: 1 module to scan (AAA::BBB)
#      2 optional: flag to load everything now

sub _scan {
    my $module=  shift;
    my $loadnow= defined( $_[0] ) ? shift : $now;

    # make sure we won't clobber sensitive system vars
    local $_= \my $foo; # make sure $_ is localized properly
    local( $!, $@ );

    # open the file to read
    my $file= _filename( $module )
      or die "Could not find file for '$module'";
    open( VERSION, "<$file" ) # use VERSION as glob to save memory
      or die "Could not open file '$file' for '$module': $!";
    binmode VERSION # needed for Windows systems, apparently
      or die "Could not set binmode on '$file': $!";

    # initializations
    my $line=    0;
    my $pod=     0;
    my $package= '';
    &ifdef::reset if IFDEF; # should get optimized away if not needed

    # look through all lines
    while ( readline VERSION ) {
        &ifdef::oneline if IFDEF; # should get optimized away if not needed
        $line++;

        # inside pod
        $pod= !m#^=cut#, next if m#^=\w#;
        next if $pod or m#^\s*\##;

        # we're done
        last if m#^__END__#;

        # not a package
        next if !m#^package\s+([\w:]+)\s*;#;

        # found a package
        die "Found package '$1' after '$package'" if $package;
        $package= $1;
    }

    # huh?
    die "Could not find package name"           if !$package;
    die "Found package $package inside '$file'" if $package ne $module;

    # initializations
    my $endline=  $line+1;
    my $endstart= tell VERSION;

    # loading now
    if ($loadnow) {
        _trace( "now $module, line $endline (offset $endstart, onwards)" )
         if TRACE;

        # load the source
        my $source= <<"SRC";
package $module;
no warnings;
#line $endline "$file (loaded now from offset $endstart)"
SRC
        $source .= do { local $/; readline(VERSION) =~ m#^(.*)$#s; $1 };
        eval ( IFDEF ? ifdef::process($source) : $source );
        die "Error evaluating source: $@" if $@;
    }

    # loading on demand
    else {
        my $start;
        my $sub= '';
        my $subline;
        my $length;

        # process all lines
        while ( readline VERSION ) {
            $length= length if IFDEF;
            &ifdef::oneline if IFDEF;
            $line++;

            # inside pod
            $pod= !m#^=cut#, next if m#^=\w#;
            next if $pod or m#^\s*\##;

            # we're done
            last if m#^__END__#;

            # huh?
            die "Only one package per file: found '$1' after '$package'"
              if m#^package\s+([\w:]+)\s*;#;

            # not at next sub yet
            next unless m#^sub\s+([\w:]+)#;

            # remember where previous sub starts, if any
            my $seek= tell(VERSION) - ( IFDEF ? $length : length );
            _store( $module, $sub, $subline, $start, $seek - $start ) if $sub;

            # set up for next iteration
            $sub= $1;
            die "Cannot handle fully qualified subroutine '$sub'\n"
              if $sub =~ m#::#;
            $subline= $line;
            $start=   $seek;
        }

        # store rest as a sub, if any
        _store(
          $module,
          $sub,
          $subline,
          $start,
          ( defined() ? tell(VERSION) - length() : -s VERSION ) - $start
        ) if $sub;
    }

    # we're done
    $load::AUTOLOAD{$module}= undef;
    close VERSION;

    return;
} #_scan

#-------------------------------------------------------------------------------
# _filename
#
# Return filename of module
#
#  IN: 1 module name (AAA::BBB)
# OUT: 1 filename (/..../AAA/BBB.pm) or undef if not known

sub _filename {

    # return filename from %INC
    ( my $key= $_[0] ) =~ s#::#/#g;
    my $filename= $INC{"$key.pm"};
    return $filename if !ref $filename;

    # return result of call instead
    return $filename->("$key.pm");
} #_filename

#-------------------------------------------------------------------------------
# _store
#
# Store information about subroutine in memory for later usage
#
#  IN: 1 module name
#      2 subroutine name (not fully qualified)
#      3 line number where sub starts
#      4 offset where sub starts
#      5 number of bytes to read

sub _store {
    _trace( "store $_[0]::$_[1], line $_[2] (offset $_[3], $_[4] bytes)" )
      if TRACE;

    # huh?
    eval "package $_[0]; sub $_[1]";
    die "Could not create stub: $@\n" if $@;

    # store the data
    $load::AUTOLOAD{ $_[0], $_[1] }= pack( 'w3', $_[2], $_[3], $_[4] )
} #_store

#-------------------------------------------------------------------------------
# _can
#
# Our version of ->can
#
#  IN: 1 module to load subroutine from
#      2 subroutine to load
# OUT: 1 reference to subroutine (if exists and loaded, else undef)

sub _can {
    my ( $module, $sub )= @_;

    # nothing to do here
    return if $module eq 'main';

    # scan file if we need to
    _scan( $module ) unless exists $load::AUTOLOAD{$module};

    # huh?  unknown sub?
    my ( $subline, $start, $length )=
      unpack( 'w3', $load::AUTOLOAD{ $module, $sub } || '' );
    return if !$start;

    # seek in the file where the source lives
    local( $!, $@ );
    my $file= _filename( $module )
      or die "Could not find file for '$module.pm'";
    open( VERSION, "<$file" ) # use VERSION glob to conserve memory
      or die "Could not open file '$file' for '$module.pm': $!";
    binmode VERSION # needed for Windows systems, apparently
      or die "Could not set binmode on '$file': $!";
    seek( VERSION, $start, 0 )
      or die "Could not seek to $start for $module\::$sub";

    # set up evallable pre-amble
    _trace( "ondemand ${module}::$sub, line $subline (offset $start, $length bytes)" ) if TRACE;
    my $use=    $use{$module} || '';
    my $source= <<"SRC";
package $module;
no warnings;$use
#line $subline "$file (loaded on demand from offset $start for $length bytes)"
SRC

    # get the stuff
    my $read= read( VERSION, $source, $length, length($source) );
    die "Error reading source: only read $read bytes instead of $length"
      if $read != $length;
    close VERSION;

    # initializations
    &ifdef::reset if IFDEF; # make sure "ifdef" starts afresh
    my $original= $source;

    # eval untainted copy
    $source =~ m#^(.*)$#s;
    $source= IFDEF ? ifdef::process($1) : $1;
    eval $source;
    die "load: $@\n$original====================\n$source" if $@;

    # done this one
    delete $load::AUTOLOAD{ $module, $sub };

    return \&{ $module . '::' . $sub };
} #_can

#-------------------------------------------------------------------------------

__END__

=head1 NAME

load - control when subroutines will be loaded

=head1 SYNOPSIS

  use load;            # default, same as 'autoload'

  use load 'autoload'; # export AUTOLOAD handler to this namespace

  use load 'ondemand'; # load subroutines after __END__ when requested, default

  use load 'now';      # load subroutines after __END__ now

  use load ();         # same as qw(dontscan inherit)

  use load 'dontscan'; # don't scan module until it is really needed

  use load 'inherit';  # do NOT export AUTOLOAD handler to this namespace

=head1 VERSION

This documentation describes version 0.23.

=head1 DESCRIPTION

The "load" pragma allows a module developer to give the application developer
more options with regards to optimize for memory or CPU usage.  The "load"
pragma gives more control on the moment when subroutines are loaded and start
taking up memory.  This allows the application developer to optimize for CPU
usage (by loading all of a module at compile time and thus reducing the
amount of CPU used during the execution of an application).  Or allow the
application developer to optimize for memory usage, by loading subroutines
only when they are actually needed, thereby however increasing the amount of
CPU needed during execution.

The "load" pragma combines the best of both worlds from L<AutoLoader> and
L<SelfLoader>.  And adds some more features.

In a situation where you want to use as little memory as possible, the "load"
pragma (in the context of a module) is a drop-in replacement for L<AutoLoader>.
But for situations where you want to have a module load everything it could
ever possibly need (e.g. when starting a mod_perl server in pre-fork mode), the
"load" pragma can be used (in the context of an application) to have all
subroutines of a module loaded without having to make any change to the source
of the module in question.

So the typical use inside a module is to have:

 package Your::Module;
 use load;

in the source.  And to place all subroutines that you want to be loadable on
demand after the (first) __END__.

If an application developer decides that all subroutines should be loaded
at compile time, (s)he can say in the application:

 use load 'now';
 use Your::Module;

This will cause the subroutines of Your::Module to all be loaded at compile
time.

=head1 MODES OF OPERATION

There are basically two places where you can call the "load" pragma:

=head2 inside a module

When you call the "load" pragma inside a module, you're basically enabling that
module for having an external control when certain subroutines will be loaded.
As with AutoLoader, any subroutines that should be loaded on demand, should be
located B<after> an __END__ line.

If no parameters are specified with the C<use load>, then the "autoload"
parameter is assumed.  Whether the module's subroutines are loaded at compile
time or on demand, is determined by the calling application.  If the
application doesn't specify anything specific, the "ondemand" keyword will
also be assumed.

=head2 inside an application

When you call the "load" pragma inside an application, you're basically
specifying when subroutines will be loaded by "load" enhanced modules.  As an
application developer, you can basically use two keywords: "ondemand" and
"now".

If an application does not call the "load" pragma, the "ondemand" keyword will
be assumed.  With "ondemand", subroutines will only be loaded when they are
actually executed.  This saves memory at the expense of extra CPU the first
time the subroutine is called.

The "now" keyword indicates that all subroutines of all modules that are
enhanced with the "load" pragma, will be loaded at compile time (thus using
more memory, but B<not> having an extra CPU overhead the first time the
subroutine is executed).

=head1 KEYWORDS

The following keywords are recognized with the C<use> command:

=head2 ondemand

The "ondemand" keyword indicates that subroutines, of modules that are enhanced
with the "load" pragma, will only be loaded when they are actually called.

If the "ondemand" keyword is used in the context of an application, all
modules that are subsequently C<use>d, will be forced to load subroutines
only when they are actually called (unless the module itself forces a specific
setting).

If the "ondemand" keyword is used in the context of a module, it indicates
that the subroutines of that module, should B<always> be loaded when they are
actually needed.  Since this takes away the choice from the application
developer, the use of the "ondemand" keyword in module context is not
encouraged.  See also the L<now> and L<dontscan> keywords.

=head2 now

The "now" keyword indicates that subroutines, of modules that are enhanced
with the "load" pragma, will be loaded at compile time.

If the "now" keyword is used in the context of an application, all modules
that are subsequently C<use>d, will be forced to load all subroutines at
compile time (unless the module forces a specific setting itself).

If the "now" keyword is used in the context of a module, it indicates that the
subroutines of that module, should B<always> be loaded at compile time.  Since
this takes away the choice from the application developer, the use of the
"now" keyword in module context is not encouraged.  See also the L<ondemand>
keyword.

=head2 dontscan

The "dontscan" keyword only makes sense when used in the context of a module.
Normally, when a module that is enhanced with the "load" pragma is compiled,
the source after the __END__ is scanned for the locations of the subroutines.
This makes the compiling of modules a little slower, but allows for a faster
(initial) lookup of (yet) unloaded subroutines during execution.

If the "dontscan" keyword is specified, this scanning of the source is
skipped at compile time.  However, as soon as an attempt is made to ececute
a subroutine from this module, then first the scanning of the source is
performed, before the subroutine in question is loaded.

So, you should use the "dontscan" keyword if you are reasonably sure that you
will only need subroutines from the module in special cases.  In all other
cases it will make more sense to have the source scanned at compile time.

The "dontscan" keyword will be ignored if an application developer forces
subroutines to be loaded at compile time with the L<now> keyword.

=head2 autoload

The "autoload" keyword only makes sense when used in the context of a module.
It indicates that a generic AUTOLOAD subroutine will be exported to the
module's namespace.  It is selected by default if you use the "load" pragma
without parameters in the source of a module.  See also the L<inherit> keyword
to B<not> export the generic AUTOLOAD subroutine.

=head2 inherit

The "inherit" keyword only makes sense when used in the context of a module.
It indicates that B<no> AUTOLOAD subroutine will be exported to the module's
namespace.  This can e.g. be used when you need to have your own AUTOLOAD
routine.  That AUTOLOAD routine should then contain:

 $load::AUTOLOAD = $sub;
 goto &load::AUTOLOAD;

to access the "load" pragma functionality.  Another case to use the "inherit"
keyword would be in a sub-class of a module which also is "load" enhanced.
In that case, the inheritance will cause the AUTOLOAD subroutine of the base
class to be used, thereby accessing the "load" pragma automagically (and hence
the naming of the keyword of course).  See also the L<autoload> keyword to
have the module use the generic AUTOLOAD subroutine.

=head2 AutoLoader

The "AutoLoader" keyword enables AutoLoader emulation mode.  It basically
takes over the functionality of the AutoLoader module (which is part of
Perl's core, and which is used by many of Perl's core modules).

Use of AutoLoader emulation mode usually only makes sense in a mod_perl
prefork environment (in combination with the "now" keyword), or a threaded
Perl environment.

It basically adds the flexibility of subroutine loading options of the "load"
pragma to the existing codebase of Perl's core and CPAN modules.  It is
typically invoked from the command line:

 perl -Mload=AutoLoader

or in a mod_perl configuration:

 <Perl>
 use load qw(AutoLoader now); # as early as possible
                              # rest of modules to be loaded
 </Perl>

The AutoLoader emulation mode has the further advantage for modules being
developed with AutoLoader, as it is possible to run the module before having
to have installed the module (which is normally a requirement with using
AutoLoader).

Please note that AutoLoader emulation will only work properly for any modules
loaded B<after> the "load" module is loaded.  It is therefore important to
activate the AutoLoader as soon as possible, before B<any> other modules have
been loaded.  Of particular interest in this respect are the L<threads> and
the L<ifdef> modules.

=head1 REQUIRED MODULES

 (none)

=head1 DIFFERENCES WITH SIMILAR MODULES

There are a number of (core) modules that more or less do the same thing as
the "load" pragma.

=head2 AutoSplit / AutoLoader

The "load" pragma is very similar to the AutoSplit / AutoLoader combination.
The main difference is that the splitting takes place when the "load" import
is called in a module and that there are no external files created.  Instead,
just the offsets and lengths are recorded in a hash (when "ondemand" is active)
or all the source after __END__ is eval'led (when "now" is active).

From a module developer point of view, the advantage is that you do not need to
install a module before you can test it.  From an application developer point
of view, you have the flexibility of having everything loaded now or later (on
demand).

From a memory usage point of view, the "load" offset/length hash takes up more
memory than the equivalent AutoLoader setup.  On the other hand, accessing the
source of a subroutine may generally be faster because the file is more likely
to reside in the operating system's buffers already.

As an extra feature, the "load" pragma allows an application to force all
subroutines to be loaded at compile time, which is not possible with AutoLoader.

The "AutoLoader emulation" mode causes AutoLoader to be replaced by "load",
increasing further flexibility in loading options (which can be particularly
important in the L<"mod_perl prefork"> situation) and ease of use during
development of modules using AutoLoader (as you don't need to install the
module before you can test it).

=head2 SelfLoader

The "load" pragma also has some functionality in common with the SelfLoader
module.  But it gives more granularity: with SelfLoader, all subroutines that
are not loaded directly, will be loaded if B<any> not yet loaded subroutine is
requested.  It also adds complexities if your module needs to use the <DATA>
handle.  So the "load" pragma gives more flexibility and fewer development
complexities.  And of course, an application can force all subroutines to be
loaded at compile time when needed with the "load" pragma.

=head1 UNIVERSAL::can

To ensure the functioning of the ->can class method and &UNIVERSAL::can,
the "load" pragma hijacks the standard UNIVERSAL::can routine so that it
can check whether the subroutine/method that you want to check for, actually
exists and have a code reference to it returned.  This has a side effect that
you the subroutine checked for, is loaded.  You can use this side effect to
load subroutines without calling them.

 Your::Module->can( 'loadthisnow' );

will load the subroutine "loadthisnow" of the Your::Module module without
actually calling it.

=head1 CAVEATS

Currently you may not have multiple packages in the same file, nor can you
have fully qualified subroutine names.

The parser that looks for package names and subroutines, is not very smart.
This is intentionally so, as making it smarter will make it a lot slower, but
probably still not smart enough.  Therefore, the C<package> and C<sub>'s
B<must> be at the start of a line.  And the name of the C<sub> B<must> be on
the same line as the C<sub>.

=head1 EXAMPLES

Some code examples.  Please note that these are just a part of an actual
situation.

=head2 base class

 package Your::Module;
 use load;

Exports the generic AUTOLOAD subroutine and adheres to whatever the application
developer specifies as mode of operation.

=head2 sub class

 package Your::Module::Adapted;
 @ISA = qw(Your::Module);
 use load ();

Does B<not> export the generic AUTOLOAD subroutine, but inherits it from its
base class.  Also implicitely specifies the "dontscan" keyword, causing the
source of the module to be scanned only when the first not yet loaded
subroutine is about to be executed.  If you only want to have the "inherit"
keyword functionality, then you must specify that explicitly:

 package Your::Module::Adapted;
 @ISA = qw(Your::Module);
 use load 'inherit';

=head2 custom AUTOLOAD

 package Your::Module;
 use load 'inherit';
 
 sub AUTOLOAD {
   if (some condition) {
     $load::AUTOLOAD = $Your::Module::AUTOLOAD;
     goto &load::AUTOLOAD;
   }
   # do your own stuff
 }

If you want to use your own AUTOLOAD subroutine, but still want to use the
functionality offered by the "load" pragma, you can use the above construct.

=head2 mod_perl prefork

 use load qw(AutoLoader now);
 use Your::Module;

In pre-fork mod_perl applications (the default mod_perl applications before
mod_perl 2.0), it is advantageous to load all possible subroutines when the
Apache process is started.  This is because the operating system will share
memory using a process called "Copy On Write".  So even though it will take
more memory initially, that memory loss is easily evened out by the gains of
having everything shared.  Loading a not yet loaded subroutine in that
situation, will cause otherwise shared memory to become unshared.  Thereby
increasing the overall memory usage, because the amount that becomes unshared
is typically a lot more than the extra memory used by the subroutine (which
is caused by fragmentation of allocated memory).

The B<AutoLoader> emulation mode causes all modules that use C<AutoLoader> to
be handled by C<load>.  In combination with the "now" mode, this means that
many system modules will also be loaded completely at server startup (causing
a grow in initial use of memory, but sharing more memory means that overall
memory usage is significantly reduced.

=head2 threaded applications and mod_perl worker

 use Your::Module;

Threaded Perl applications, of which mod_perl applications using the "worker"
module are a special case, function best when subroutines are only loaded when
they are actually needed.  This is caused by the nature of the threading model
of Perl, in which all data-structures are B<copied> to each thread (essentially
forcing them to become unshared as far as the operating system is concerned).

Benchmarks have shown that the overhead of the extra CPU is easily offset by
the reduction of the amount of data that needs to be copied (and processed)
when a thread is created.

A little additional memory reduction can be achieved with the L<AutoLoader>
emulation mode: this will prevent the AutoLoader module to be loaded (but
have its functionality handled by the "load" pragma).

=head1 SOURCE FILTERS

If your module wants to use "load" to load subroutines on demand B<and> that
module needs a source filter (which is usually activated with a "use"
statement), then those modules need to be used when the source of the
subroutine is compiled.  The class method "register" is intended to be
used from such a module, typicallly like this:

 sub import {
   my $package = caller();
   load->register( $package,__PACKAGE__ )  # register caller's package
    if defined( $load::VERSION )           # if load.pm loaded
     and $load::VERSION > 0.11;            # and recent enough
 }

The first parameter is the name of the package B<in> which subroutines need
extra modules "use"d.  The second parameter is the name of the module that
needs to be "use"d.

=head1 TODO

The coordinates of a subroutine in a module (start,number of bytes) are stored
in a hash in the load namespace.  Ideally, this information should be stored in
the stash of the module to which they apply.  Then the internals that check
for the existence of a subroutine, would see that the subroutine doesn't exist
(yet), but that there is an offset and length (and implicitely, a file from
%INC) from which the source could be read and evalled.

Loading all of the subroutines should maybe be handled inside the Perl parser,
having it skip __END__ when the global "now" flag is set.

Possibly we should use the <DATA> handle from a module if there is one, or dup
it and use that, rather than opening the file again.

Add L<SelfLoader> emulation mode.

=head1 MODULE RATING

If you want to find out how this module is appreciated by other people, please
check out this module's rating at L<http://cpanratings.perl.org/l/load> (if
there are any ratings for this module).  If you like this module, or otherwise
would like to have your opinion known, you can add your rating of this module
at L<http://cpanratings.perl.org/rate/?distribution=load>.

=head1 ACKNOWLEDGEMENTS

Frank Tolstrup for helping ironing out all of the Windows related issues.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002, 2003, 2004, 2005, 2006, 2007, 2010, 2012 Elizabeth
Mattijsen <liz@dijkmat.nl>. All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

L<AutoLoader>, L<SelfLoader>, L<ifdef>, L<threads>.

=cut
