#
# This is the hand-written PERL part of the X11::Wcl module.
#

use Carp;

package X11::Wcl;

$VERSION = '0.3';

$toplevel = undef;
$application_context = undef;
$initial_resources = undef;
$delete_callback = undef;

#
# called when user has requested callback for window manager close
#
sub delete
{
	&{$delete_callback}();
}

#
# This is the public function used to register PERL callback
# functions.  It saves some information in PERL structures for later
# use when the callback is invoked, and some information it passes
# down to the C level of Wcl for its use.
#
sub WcRegisterCallback
{
	my($app_context, $callback_name, $function, $arg) = @_;

	# save function and argument for use when callback is invoked
	$callback_function{$callback_name} = $function;
	$callback_arg{$callback_name} = $arg;

	# register callback with Widget Creation Library
	_X11_Wcl_register_callback($app_context, $callback_name);
}

#
# This routine is called from the C level when a callback needs to be
# executed.  It calls the proper PERL function, passing information
# remembered from when the callback was registered, and information
# passed in from the C level.
#
sub do_callback
{
	my($callback_name, $widget, $client_data, $callback_data) = @_;

	# convert $widget to the proper type
	$widget = ptrcast(eval $widget, "Widget");

	# convert $client_data to the proper type
	$client_data = ptrcast(eval $client_data, "char *");
	$client_data = ptrvalue($client_data);

	# do the callback
	&{$callback_function{$callback_name}}(
		$widget,
		$client_data,
		$callback_data,
		$callback_arg{$callback_name}
	);
}

#
# perform preprocessing on a string
#
# #if, #else and #endif are valid and can be arbitrarily nested
# argument to #if is a PERL expression
#
# The extra arguments are for internal use, during recursion.
#
sub preprocess
{
	my($data, $inside_an_if, $discarding, $inside_false_clause) = @_;
	my $in;
	my $out = "";

	if (ref $data eq "") {
		$in = $data;
		$data = \$in;
	}
	while ($$data =~ m@^(.*)\n?@gm) {
		$_ = $1;
		if (/^\s*#\s*if\s+((\S.*)?\S)\s*$/) {
			if (eval $1) {
				$out .= preprocess($data, 1, $discarding || $inside_false_clause, 0);
			} else {
				$out .= preprocess($data, 1, $discarding || $inside_false_clause, 1);
			}
		} elsif (/^\s*#\s*else\s*$/) {
			if (!$inside_an_if) {
				croak "unexpected #else";
			} else {
				$inside_false_clause = !$inside_false_clause;
			}
		} elsif (/^\s*#\s*endif\s*$/) {
			if (!$inside_an_if) {
				croak "unexpected #endif";
			} else {
				return $out;
			}
		} elsif (/^\s*#/) {
			croak "unknown directive: $_";
		} elsif (!$discarding && !$inside_false_clause) {
			$out .= "$_\n";
		} else {
			# discard the line
		}
	}
	if ($inside_an_if) {
		croak "unexpected end of input";
	}
	$out;
}

#
# parse resource specifications, performing preprocessing on them
# first, using preprocess()
#
# Input argument can be a scalar, a ref to a scalar, a ref to a
# subroutine, or a ref to a glob (which is interpreted as a file
# handle to read, such as \*DATA).
#
# The keyword MAIN introduces the top-level resources for an
# application.
#
# The keyword TEMPLATE followed by a template name introduces a
# template definition.
#
sub get_resources
{
	my($arg) = @_;
	my $main;
	my $variable;
	my $data;

	if ("SCALAR" eq ref $arg) {
		# reference to a variable
		$data = $$arg;
	} elsif ("CODE" eq ref $arg) {
		# reference to a subroutine
		$data = &{$arg}();
	} elsif ("GLOB" eq ref $arg) {
		# file handle
		my $x = $/;
		undef $/;
		$data = <$arg>;
		$/ = $x;
		close($arg);
	} else {
		# assume scalar value
		$data = $arg;
	}

	$arg = preprocess($data);

	$data = "";
	while ($arg =~ m@^.*\n?@gm) {
		$_ = $&;
		if (/^MAIN\s*$/) {
			# start of top level resources
			if (defined $variable) {
				eval "\$$variable = \$data";
				$data = "";
			}
			$variable = "main";
		} elsif (/^TEMPLATE\s+(\S+)\s*$/) {
			# start of template resources
			if (defined $variable) {
				eval "\$$variable = \$data";
				$data = "";
			}
			$variable = $1;
		} else {
			$data .= $_;
		}
	}
	if (defined $variable) {
		eval "\$$variable = \$data";
	}

	# return top level resources
	$main;
}

#
# standard main routine
#
# The following arguments can be passed.
#
# ARGV => ["program name", "arg1", "arg2", "etc."]
#
#	Required.  Specifies program name (required) and any command line
#	arguments necessary for Wcl or Xt.
#
# DELETE => \&delete_window
#
#	Optional.  Callback routine to be executed when window manager
#	does a close operation.
#
# EDITRES_SUPPORT => 1
#
#	Optional.  Requests that top-level shell support the editres
#	protocol.
#
# INITIAL_RESOURCES => $whatever
# INITIAL_RESOURCES => \$whatever
# INITIAL_RESOURCES => \&whatever
# INITIAL_RESOURCES => \*whatever
#
#	Optional.  Provides the top-level resources and/or templates for
#	the application.
#
# NO_INITIAL_RESOURCES => 1
#
#	Optional.  Prevents main loop from calling Wcl to create the
#	initial widget tree.
#
# NO_REALIZE => 1
#
#	Optional.  Prevents main loop from calling Xt to realize the
#	widget tree, thus preventing top-level shell creation.
#
# CALLBACKS => [
#	["name", \&procedure, "arbitrary PERL object"],
#	...
# ]
#
#	Optional.  Provides information about callback routines that need
#	to be registered with Wcl, because they appear in callback
#	resources.
#
# OPTIONS => [
#	["-name",	"*resource",	$X11::Wcl::XrmoptionXXX, VALUE],
#	...
# ]
#
#	Optional.  Provides values for an array of XrmOptionDescRec
#	structures which is created by main loop for argument parsing.
#	The default Wcl options are always added to the end of any options
#	passed in.
#
# STARTUP => \&startup
#
#	Optional.  Provides a callback routine that is called just before
#	the widget tree is realized by Xt.
#
# NEED_MISC => 1
#
#	Optional.  Indicates that the Misc library is needed.
#
# NEED_MOTIF => 1
#
#	Optional.  Indicates that the Motif library is needed.
#
sub mainloop
{
	my %args = @_;

	croak "no ARGV array was passed"
		unless exists $args{ARGV};

	# add standard Wcl options
	push(@{$args{OPTIONS}},
		["-ResFile","*wclInitResFile",		$XrmoptionSepArg, undef],
		["-rf",		"*wclInitResFile",		$XrmoptionSepArg, undef],
		["-trrf",	"*wclTraceResFiles",	$XrmoptionNoArg,  "on"],
		["-Trace",	"*wcTrace",				$XrmoptionNoArg,  "on"],
		["-tr",		"*wcTrace",				$XrmoptionNoArg,  "on"],
		["-trtd",	"*wclTraceTemplateDef",	$XrmoptionNoArg,  "on"],
		["-trtx",	"*wcTraceTemplate",		$XrmoptionNoArg,  "on"],
		["-Warnings","*wclVerboseWarnings",	$XrmoptionNoArg,  "on"],
	);

	# make array of XrmOptionDescRec structures
	my $options = new XrmOptionDescRec(0, scalar @{$args{OPTIONS}});
	# setup options structure
	my $num_options = 0;
	for (@{$args{OPTIONS}}) {
		my $x = $options->idx($num_options);
		$x->{option} = ${$_}[0];
		$x->{specifier} = ${$_}[1];
		$x->{argKind} = ${$_}[2];
		$x->{value} = ${$_}[3];
		++$num_options;
	}

	# parse the initial resource specifications
	if (exists $args{INITIAL_RESOURCES}) {
		$initial_resources = get_resources($args{INITIAL_RESOURCES});
		push(@{$args{ARGV}}, "-rf");
		push(@{$args{ARGV}}, "\$X11::Wcl::initial_resources");
	}

	# make an int for argc
	my $argc = ptrcreate("int", 0, 1);
	# make array of char * pointers for argv
	my $argv = ptrcreate("char *", 0, 1 + scalar @{$args{ARGV}});
	# set up argv
	my $i = 0;
	for (@{$args{ARGV}}) {
		ptrset($argv, $_, $i++);
	}
	ptrset($argv, ptrcast(0, "char *"), $i++);
	# set up argc
	ptrset($argc, $i);

    # Initialize Toolkit creating the application shell
    $toplevel = XtInitialize(
		WcAppName(ptrvalue($argc), $argv), WcAppClass(ptrvalue($argc), $argv),
		$options, $num_options,
		$argc, $argv);

	# add editres support
	if (exists $args{EDITRES_SUPPORT}) {
		WcAddEditResSupportToShell($toplevel);
	}

	# get application context
    $application_context =
		XtWidgetToApplicationContext($toplevel);

    # Register application specific callbacks and widget classes
	for (@{$args{CALLBACKS}}) {
		WcRegisterCallback($application_context, @{$_});
	}

    # Register all widget classes and constructors
	if (exists $args{NEED_MOTIF}) {
	    XmpRegisterAll($application_context);
	}
	if (exists $args{NEED_MISC}) {
	    RegisterMisc($application_context);
	}

    # Create widget tree below toplevel shell using Xrm database
	if (!exists $args{NO_INITIAL_RESOURCES}) {
		if (WcWidgetCreation($toplevel)) {
			croak "cannot create widget tree";
		}
	}

	# startup here
	if (exists $args{STARTUP}) {
		&{$args{STARTUP}}($toplevel, $application_context);
	}

    # Realize the widget tree
	if (!exists $args{NO_REALIZE}) {
	    XtRealizeWidget($toplevel);
	}

	if (exists $args{DELETE}) {
		$delete_callback = $args{DELETE};
		my $x = MakeXtCallbackProc("X11::Wcl::delete");
		XmpAddMwmCloseCallback($toplevel, $x, undef);
	}

    # finally, enter the main application loop
    XtMainLoop();
}

1;

__END__

=head1 NAME

X11::Wcl - Perl interface to the Widget Creation Library

=head1 SYNOPSIS

 use X11::Wcl;

=head1 DESCRIPTION

This module provides an interface to the Widget Creation Library.  The
Widget Creation Library is a C library that allows rapid prototyping
of GUI interfaces using Xt-compatible toolkits.  The module is a
straightforward application of the SWIG interface generator, with very
little custom-written code.

Look at the examples/ directory in the source code to see how to write
a program using this module.  A standard main routine is supplied by
the package, the main difference from application to application being
in the resource specifications and the callbacks.

=head1 STRUCTURE MEMBER FUNCTIONS

The module currently supplies object-oriented access to a number of X,
Xt and Motif structures and constants.  Several member functions have
been provided for each structure to facilitate their manipulation in
the SWIG environment.

=head2 CONSTRUCTORS

Special constructors were created for all wrapped structures provided
by this module.  Two different forms of object construction are
supported.

=over 4

=item *

 C<$object = new StructureName;>
 C<$object = new StructureName(0);>
 C<$object = new StructureName(0, COUNT);>

This form of constructor call creates a new object using calloc() that
consists of a COUNT element array of the named structure type.  If any
arguments are omitted, an array size of 1 (a single struct) is
assumed.

The following code creates an array of 20 XrmOptionDescRec structures:

 $options = new XrmOptionDescRec(0, 20);

The following code creates one XrmOptionDescRec structure:

 $options = new XrmOptionDescRec;

=item *

 C<$object = new StructureName(INT);>
 C<$object = new StructureName(INT, COUNT);>

This form of constructor call creates a new object that references
memory that has already been allocated elsewhere.  It is typically
used in callback routines to convert the callback pointers passed to
the callback routine into the appropriate type of PERL struct.  INT is
the memory address of the already allocated memory (existing C struct
allocated by the X toolkit during a callback, for example).  If COUNT
is supplied, it is assumed that INT references an array of structs,
and the struct at the provided index in the array is returned.

The following code creates a CallbackStruct structure from the second
argument passed to the routine:

 sub callback
 {
     my($widget, $arg1, $arg2, $arg3) = @_;
     $x = new CallbackStruct($arg2);
     print STDOUT $x->{field}, "\n";
     # etc.
 }

=head2 DESTRUCTOR

The destructor function for each structure knows how to destroy a
structure when it is no longer needed.  It takes into account the
different kinds of construction that are possible.

=head2 ARRAY INDEXING

 $object->idx(INT);

This member function assumes that $object is actually an array of
existing objects, and returns the object residing at the provided
integer index.

Here is an example of how to initialize an array of 20 structures,
using the idx() member function:

 # create array of 20 structures
 $options = new StructureName(0, 20);
 # now initialize them
 for ($i=0; $i<20; ++$i) {
     $x = $options->idx($i);
     $x->{field} = "value"
 }

=head1 CALLBACK FUNCTIONS

Callbacks invoked by the GUI interface are written in PERL.  All PERL
callback functions are passed four arguments when they are invoked:

=over 4

=item 1.

The first argument is the widget associated with the callback, of type
Widget.

=item 2.

The second argument is a string that contains the data appearing in
the X resource specification that caused the callback to be invoked.

=item 3.

The third argument is an integer that is the address of the callback
structure passed to the callback by the invoking widget.  You normally
will typecast this to the appropriate type so you can get to details
about the event causing the callback.

=item 4.

The fourth argument is the PERL object that was passed (if any) when
the callback routine was registered using
X11::Wcl::WcRegisterCallback().

=back

See the examples supplied with this module for details on what to do
with callback function arguments.

=head2 GLOBAL FUNCTIONS

 WcRegisterCallback($app_context, $callback_name, $function, $arg)

The WcRegisterCallback() function is a wrapper function that works
almost the same way as its namesake in the Widget Creation Library.
It expects the first argument to be the application context, which it
simply passes down to the C routine.  The second argument is a string
that provides the name of the callback routine as it appears in X
resources.  The third argument should be a PERL function reference.
The final argument is optional, can be any PERL scalar or reference,
and is passed to the callback when it is invoked.

 WcAddEditResSupportToShell($shell)

The WcAddEditResSupportToShell() function adds support for the editres
protocol to the shell widget supplied as an argument.  This allows
easy examination of the widget tree using the editres program, among
other things.

 preprocess($string)

This function performs preprocessing on the argument string and
returns the result.  The syntax is similar that of the C preprocessor,
with #if, #else, and #endif being understood.  The argument to #if
is expected to be a PERL expression.

 MakeXt*Proc($perl_function_name)

One MakeXt*Proc() function is created for each Xt*Proc function
pointer typedef found in the Xt header files when the X11::Wcl module
is built.  Each function takes the name of a PERL function as an
argument, and returns a function pointer suitable for use with a Xt
call that requires a function pointer of the associated type.  No
arguments are currently passed to the PERL function when it is
invoked.

Because of the way this is implemented, you can only make a finite
number of Xt*Proc PERL functions.  The default as shipped is 25 max.

 mainloop(TAG => VALUE, ...)

This function implements a standard main loop for X11::Wcl
applications.  See the X11/Wcl.pm file for documentation on this
function.

=head1 RESOURCE SPECIFICATION

The whole point of the Widget Creation Library is to make it possible
to specify widget trees and widget resources using X resource files,
without writing any C or C++ code.  Read the Widget Creation Library
documentation for details on the resources that control its operation,
and the documentation on the Motif widgets for details on what they
expect.

The Widget Creation Library was originally designed to use files to
specify resource values.  To fit better with PERL, a syntax extension
was created to cause PERL variables to be used instead of files.

The usual syntax for a resource file specification is:

 *resourceFile: some_file_name

As a special case, when the file name begins with a dollar sign,
resources are instead read from the named PERL variable.  So, for
example, the following resource specifies that variable "main::x"
contains the resources to be used:

 *resourceFile: $main::x

The variable should hold a string that contains X resource
specifications in the usual X resource syntax.

=head1 AUTHORS

 "David E. Smyth" (Widget Creation Library)
 "David M. Beazley" <dmb@asator.lanl.gov> (SWIG)
 "Joseph H. Buehler" <jhpb@sarto.gaithersburg.md.us> (X11::Wcl module)

=head1 SEE ALSO

 Widget Creation Library documentation.
 Motif toolkit documentation.
 SWIG documentation.
 examples supplied with this module.
 perl(1).

=cut
