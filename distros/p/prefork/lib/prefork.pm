package prefork; # git description: 7b0d615

=pod

=head1 NAME

prefork - Optimized module loading for forking or non-forking processes

=head1 SYNOPSIS

In a module that normally delays module loading with require

  # Module Foo::Bar only uses This::That 25% of the time.
  # We want to preload in in forking scenarios (like mod_perl), but
  # we want to delay loading in non-forking scenarios (like CGI)
  use prefork 'This::That';
  
  sub do_something {
      my $arg = shift;
  
      # Load the module at run-time as normal
      if ( $special_case ) {
          require This::That;
          This::That::blah(@_);
      }
  }
  
  # Register a module to be loaded before forking directly
  prefork::prefork('Module::Name');

In a script or module that is going to be forking.

  package Module::Forker;
  
  # Enable forking mode
  use prefork ':enable';
  
  # Or call it directly
  prefork::enable();

In a third-party run-time loader

  package Runtime::Loader;
  
  use prefork ();
  prefork::notify( \&load_everything );
  
  ...
  
  sub load_everything { ... }
  
  1;
  
=head1 INTRODUCTION

The task of optimizing module loading in Perl tends to move in two different
directions, depending on the context.

In a procedural context, such as scripts and CGI-type situations, you can
improve the load times and memory usage by loading a module at run-time,
only once you are sure you will need it.

In the other common load profile for perl applications, the application
will start up and then fork off various worker processes. To take full
advantage of memory copy-on-write features, the application should load
as many modules as possible before forking to prevent them consuming memory
in multiple worker processes.

Unfortunately, the strategies used to optimise for these two load profiles
are diametrically opposed. What improves a situation for one tends to
make life worse for the other.

=head1 DESCRIPTION

The C<prefork> pragma is intended to allow module writers to optimise
module loading for B<both> scenarios with as little additional code as
possible.

prefork.pm is intended to serve as a central and optional marshalling
point for state detection (are we running in compile-time or run-time
mode) and to act as a relatively light-weight module loader.

=head2 Loaders and Forkers

C<prefork> is intended to be used in two different ways.

The first is by a module that wants to indicate that another module should
be loaded before forking. This is known as a "Loader".

The other is a script or module that will be initiating the forking. It
will tell prefork.pm that it is either going to fork, or is about to fork,
or for some other reason all modules previously mentioned by the Loaders
should be loaded immediately.

=head2 Usage as a Pragma

A Loader can register a module to be loaded using the following

  use prefork 'My::Module';

The same thing can be done in such a way as to not require prefork
being installed, but taking advantage of it if it is.

  eval "use prefork 'My::Module';";

A Forker can indicate that it will be forking with the following

  use prefork ':enable';

In any use of C<prefork> as a pragma, you can only pass a single value
as argument. Any additional arguments will be ignored. (This may throw
an error in future versions).

=head2 Compatibility with mod_perl and others

Part of the design of C<prefork>, and its minimalistic nature, is that it
is intended to work easily with existing modules, needing only small
changes.

For example, C<prefork> itself will detect the C<$ENV{MOD_PERL}>
environment variable and automatically start in forking mode.

prefork has support for integrating with third-party modules, such as
L<Class::Autouse>. The C<notify> function allows these run-time loaders
to register callbacks, to be called once prefork enters forking mode.

The synopsis entry above describes adding support for prefork.pm as a
dependency. To allow your third-party module loader without a dependency
and only if it is installed use the following:

  eval { require prefork; }
  prefork::notify( \&function ) unless $@;

=head2 Using prefork.pm

From the Loader side, it is fairly simple. prefork becomes a dependency
for your module, and you use it as a pragma as documented above.

For the Forker, you have two options. Use as a dependency or optional use.

In the dependency case, you add prefork as a dependency and use it as a
pragma with the ':enable' option.

To add only optional support for prefork, without requiring it to be
installed, you should wait until the moment just before you fork and then
call C<prefork::enable> directly ONLY if it is loaded.

  # Load modules if any use the prefork pragma.
  prefork::enable() if $INC{prefork.pm};

This will cause the modules to be loaded ONLY if there are any modules that
need to be loaded. The main advantage of the dependency version is that you
only need to enable the module once, and not before each fork.

If you wish to have your own module leverage off the forking-detection that
prefork provides, you can also do the following.

  use prefork;
  if ( $prefork::FORKING ) {
      # Complete some preparation task
  }

=head2 Modules that are prefork-aware

=over 4

=item mod_perl/mod_perl2

=item Class::Autouse

=back

=head1 FUNCTIONS

=cut

use 5.006;
use strict;
#use warnings;  # this might not be safe to turn on!
use Carp              ();
use List::Util   0.18 ();
use Scalar::Util 0.18 ();

our $VERSION = '1.05';

# The main state variable for this package.
# Are we in preforking mode.
our $FORKING = '';

# The queue of modules to load
our %MODULES = ();

# The queue of notification callbacks
our @NOTIFY = (
	sub {
		# Do a hash copy of Config to get everything
		# inside of it preloaded.
		require Config;
		eval {
			# Sometimes there is no Config_heavy.pl
			require 'Config_heavy.pl';
		};
		my $copy = { %Config::Config };
		return 1;
	},
);

# Look for situations that need us to start in forking mode
$FORKING = 1 if $ENV{MOD_PERL};

sub import {
	return 1 unless $_[1];
	($_[1] eq ':enable') ? enable() : prefork($_[1]);
}

=pod

=head2 prefork $module

The 'prefork' function indicates that a module should be loaded before
the process will fork. If already in forking mode the module will be
loaded immediately.

Otherwise it will be added to a queue to be loaded later if it receives
instructions that it is going to be forking.

Returns true on success, or dies on error.

=cut

sub prefork ($) {
	# Just hand straight to require if enabled
	my $module = defined $_[0] ? "$_[0]" : ''
		or Carp::croak('You did not pass a module name to prefork');
	$module =~ /^[^\W\d]\w*(?:(?:\'|::)[^\W\d]\w*)*$/
		or Carp::croak("'$module' is not a module name");
	my $file = join( '/', split /(?:\'|::)/, $module ) . '.pm';

	# Is it already loaded or queued
	return 1 if $INC{$file};
	return 1 if $MODULES{$module};

	# Load now if enabled, or add to the module list
	return require $file if $FORKING;
	$MODULES{$module} = $file;

	1;
}

=pod

=head2 enable

The C<enable> function indicates to the prefork module that the process is
going to fork, possibly immediately.

When called, prefork.pm will immediately load all outstanding modules, and
will set a flag so that any further 'prefork' calls will load the module
at that time.

Returns true, dying as normal is there is a problem loading a module.

=cut

sub enable () {
	# Turn on the PREFORK flag, so any additional
	# 'use prefork ...' calls made during loading
	# will load immediately.
	return 1 if $FORKING;
	$FORKING = 1;

	# Load all of the modules not yet loaded
	foreach my $module ( sort keys %MODULES ) {
		my $file = $MODULES{$module};

		# Has it been loaded since we were told about it
		next if $INC{$file};

		# Load the module.
		require $file;
	}

	# Clear the modules list
	%MODULES = ();

	# Execute the third-party callbacks
	while ( my $callback = shift @NOTIFY ) {
		$callback->();
	}

	1;
}

=pod

=head2 notify &function

The C<notify> function is used to integrate support for modules other than
prefork.pm itself.

A module loader calls the notify function, passing it a reference to a
C<CODE> reference (either anon or a function reference). C<prefork> will
store this CODE reference, and execute it immediately as soon as it knows
it is in forking-mode, but after it loads its own modules.

Callbacks are called in the order they are registered.

Normally, this will happen as soon as the C<enable> function is called.

However, you should be aware that if prefork is B<already> in preforking
mode at the time that the notify function is called, prefork.pm will
execute the function immediately.

This means that any third party module loader should be fully loaded and
initialised B<before> the callback is provided to C<notify>.

Returns true if the function is stored, or dies if not passed a C<CODE>
reference, or the callback is already set in the notify queue.

=cut

sub notify ($) {
	# Get the CODE ref callback param
	my $function = shift;
	my $reftype  = Scalar::Util::reftype($function);
	unless ( $reftype and $reftype eq 'CODE' ) {
		Carp::croak("prefork::notify was not passed a CODE reference");
	}

	# Call it immediately is already in forking mode
	if ( $FORKING ) {
		$function->();
		return 1;
	}

	# Is it already defined?
	if ( List::Util::first { Scalar::Util::refaddr($function) == Scalar::Util::refaddr($_) } @NOTIFY ) {
		Carp::croak("Callback function already registered");
	}

	# Add to the queue
	push @NOTIFY, $function;

	1;
}





#####################################################################
# Built-in Notifications

# Compile CGI functions automatically
prefork::notify( sub {
	CGI->compile() if $INC{'CGI.pm'};
} );

1;

=pod

=head1 TO DO

- Add checks for more pre-forking situations

=head1 SUPPORT

Bugs should be always submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=prefork>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 COPYRIGHT

Thank you to Phase N Australia (L<http://phase-n.com/>) for
permitting the open sourcing and release of this distribution.

Copyright 2004 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
