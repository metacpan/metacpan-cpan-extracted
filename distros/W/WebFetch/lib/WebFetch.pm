# WebFetch - infrastructure for downloading ("fetching") information from
# various sources around the Internet or the local system in order to
# present them for display, or to export local information to other sites
# on the Internet
#
# Copyright (c) 1998-2009 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  http://www.webfetch.org/GPLv3.txt

package WebFetch;

=head1 NAME

WebFetch - Perl module to download and save information from the Web

=head1 SYNOPSIS

  use WebFetch;

=head1 DESCRIPTION

The WebFetch module is a framework for downloading and saving
information from the web, and for saving or re-displaying it.
It provides a generalized interface for saving to a file
while keeping the previous version as a backup.
This is mainly intended for use in a cron-job to acquire
periodically-updated information.

WebFetch allows the user to specify a source and destination, and
the input and output formats.  It is possible to write new Perl modules
to the WebFetch API in order to add more input and output formats.

The currently-provided input formats are Atom, RSS, WebFetch "SiteNews" files
and raw Perl data structures.

The currently-provided output formats are RSS, WebFetch "SiteNews" files,
the Perl Template Toolkit, and export into a TWiki site.

Some modules which were specific to pre-RSS/Atom web syndication formats
have been deprecated.  Those modules can be found in the CPAN archive
in WebFetch 0.10.  Those modules are no longer compatible with changes
in the current WebFetch API.

=head1 INSTALLATION

After unpacking and the module sources from the tar file, run

C<perl Makefile.PL>

C<make>

C<make install>

Or from a CPAN shell you can simply type "C<install WebFetch>"
and it will download, build and install it for you.

If you need help setting up a separate area to install the modules
(i.e. if you don't have write permission where perl keeps its modules)
then see the Perl FAQ.

To begin using the WebFetch modules, you will need to test your
fetch operations manually, put them into a crontab, and then
use server-side include (SSI) or a similar server configuration to 
include the files in a live web page.

=head2 MANUALLY TESTING A FETCH OPERATION

Select a directory which will be the storage area for files created
by WebFetch.  This is an important administrative decision -
keep the volatile automatically-generated files in their own directory
so they'll be separated from manually-maintained files.

Choose the specific WebFetch-derived modules that do the work you want.
See their particular manual/web pages for details on command-line arguments.
Test run them first before committing to a crontab.

=head2 SETTING UP CRONTAB ENTRIES

If needed, see the manual pages for crontab(1), crontab(5) and any
web sites or books on Unix system administration.

Since WebFetch command lines are usually very long, the user may prefer
to make one or more scripts as front-ends so crontab entries aren't so big.

Try not to run crontab entries too often - be aware if the site you're
accessing has any resource constraints, and how often their information
gets updated.  If they request users not to access a feed more often
than a certain interval, respect it.  (It isn't hard to find violators
in server logs.)  If in doubt, try every 30 minutes until more information
becomes available.

=head1 WebFetch FUNCTIONS

The following function definitions assume B<C<$obj>> is a blessed
reference to a module that is derived from (inherits from) WebFetch.

=over 4

=cut

use strict;

use Getopt::Long;
use LWP::UserAgent;
use HTTP::Request;
use Date::Calc;

# define exceptions/errors
use Exception::Class (
	'WebFetch::Exception',
	'WebFetch::TracedException' => {
                isa => 'WebFetch::Exception',
	},

	'WebFetch::Exception::DataWrongType' => {
                isa => 'WebFetch::TracedException',
		alias => 'throw_data_wrongtype',
                description => "provided data must be a WebFetch::Data::Store",
        },

	'WebFetch::Exception::GetoptError' => {
                isa => 'WebFetch::Exception',
		alias => 'throw_getopt_error',
                description => "software error during command line processing",
        },

	'WebFetch::Exception::Usage' => {
                isa => 'WebFetch::Exception',
		alias => 'throw_cli_usage',
		description => "command line processing failed",
	},

	'WebFetch::Exception::Save' => {
                isa => 'WebFetch::Exception',
		alias => 'throw_save_error',
		description => "an error occurred while saving the data",
	},

	'WebFetch::Exception::NoSave' => {
                isa => 'WebFetch::Exception',
		alias => 'throw_no_save',
		description => "unable to save: no data or nowhere to save it",
	},

	'WebFetch::Exception::NoHandler' => {
                isa => 'WebFetch::Exception',
		alias => 'throw_no_handler',
		description => "no handler was found",
	},

	'WebFetch::Exception::MustOverride' => {
                isa => 'WebFetch::TracedException',
		alias => 'throw_abstract',
		description => "A WebFetch function was called which is "
			."supposed to be overridden by a subclass",
	},

	'WebFetch::Exception::NetworkGet' => {
                isa => 'WebFetch::Exception',
                description => "Failed to access RSS feed",
        },

	'WebFetch::Exception::ModLoadFailure' => {
                isa => 'WebFetch::Exception',
		alias => 'throw_mod_load_failure',
                description => "failed to load a WebFetch Perl module",
        },

	'WebFetch::Exception::ModRunFailure' => {
                isa => 'WebFetch::Exception',
		alias => 'throw_mod_run_failure',
                description => "failed to run a WebFetch module",
        },

	'WebFetch::Exception::ModNoRunModule' => {
                isa => 'WebFetch::Exception',
		alias => 'throw_no_run',
                description => "no module was found to run the request",
        },

	'WebFetch::Exception::AutoloadFailure' => {
                isa => 'WebFetch::TracedException',
		alias => 'throw_autoload_fail',
                description => "AUTOLOAD failed to handle function call",
        },

);

# initialize class variables
our $VERSION = '0.13';
our %default_modules = (
	"input" => {
		"rss" => "WebFetch::Input::RSS",
		"sitenews" => "WebFetch::Input::SiteNews",
		"perlstruct" => "WebFetch::Input::PerlStruct",
		"atom" => "WebFetch::Input::Atom",
		"dump" => "WebFetch::Input::Dump",
	},
	"output" => {
		"rss" => "WebFetch::Output:RSS",
		"atom" => "WebFetch::Output:Atom",
		"tt" => "WebFetch::Output:TT",
		"perlstruct" => "WebFetch::Output::PerlStruct",
		"dump" => "WebFetch::Output::Dump",
	}
);
our %modules;
our $AUTOLOAD;
my $debug;

sub debug
{
	$debug and print STDERR "debug: ".join( " ", @_ )."\n";
}

=item WebFetch::module_register( $module, @capabilities );

This function allows a Perl module to register itself with the WebFetch API
as able to perform various capabilities.

For subclasses of WebFetch, it can be called as a class method.
   C<__PACKAGE__-&gt;module_register( @capabilities );>

For the $module parameter, the Perl module should provide its own
name, usually via the __PACKAGE__ string.

The @capabilities array is any number of strings as needed to list the
capabilities which the module performs for the WebFetch API.
The currently-recognized capabilities are "cmdline", "input" and "output".
"config", "filter", "save" and "storage" are reserved for future use.  The
function will save all the capability names that the module provides, without
checking whether any code will use it.

For example, the WebFetch::Output::TT module registers itself like this:
   C<__PACKAGE__-&gt;module_register( "cmdline", "output:tt" );>
meaning that it defines additional command-line options, and it provides an
output format handler for the "tt" format, the Perl Template Toolkit.

=cut

sub module_register
{
	my $module = shift;
	my @capabilities = @_;

	# each string provided is a capability the module provides
	foreach my $capability ( @capabilities ) {
		# A ":" if present delimits a group of capabilities
		# such as "input:rss" for and "input" capability of "rss"
		if ( $capability =~ /([^:]+):([^:]+)/ ) {
			# A ":" was found so process a 2nd-level group entry
			my $group = $1;
			my $subcap = $2;
			if ( !exists $modules{$group}) {
				$modules{$group} = {};
			}
			if ( !exists $modules{$group}{$subcap}) {
				$modules{$group}{$subcap} = [];
			}
			push @{$modules{$group}{$subcap}}, $module;
		} else {
			# just a simple capbility name so store it
			if ( !exists $modules{$capability}) {
				$modules{$capability} = [];
			}
			push @{$modules{$capability}}, $module;
		}
	}
}

# module selection - choose WebFetch module based on selected file format
# for WebFetch internal use only
sub module_select
{
	my $capability = shift;
	my $is_optional = shift;

	debug "module_select($capability,$is_optional)";
	# parse the capability string
	my ( $group, $topic );
	if ( $capability =~ /([^:]*):(.*)/ ) {
		$group = $1;
		$topic = $2
	} else {
		$topic = $capability;
	}
	
	# check for modules to handle the specified source_format
	my ( @handlers, %handlers, $handler );

	# consider whether a group is in use (single or double-level scan)
	if ( $group ) {
		# double-level scan

		# if the group exists, search in it
		if (( exists $modules{$group}{$topic} )
			and ( ref $modules{$group}{$topic} eq "ARRAY" ))
		{
			# search group for topic
			foreach $handler (@{$modules{$group}{$topic}})
			{
				if ( !exists $handlers{$handler}) {
					push @handlers, $handler;
					$handlers{$handler} = 1;
				}
			}

		# otherwise check the defaults
		} elsif ( exists $default_modules{$group}{$topic} ) {
			# check default handlers
			$handler = $default_modules{$group}{$topic};
			if ( !exists $handlers{$handler}) {
				push @handlers, $handler;
				$handlers{$handler} = 1;
			}
		}
	} else {
		# single-level scan

		# if the topic exists, the search is a success
		if (( exists $modules{$topic})
			and ( ref $modules{$topic} eq "ARRAY" ))
		{
			@handlers = @{$modules{$topic}};
		}
	}
	
	# check if any handlers were found for this format
	if ( ! @handlers and ! $is_optional ) {
		throw_no_handler( "handler not found for $capability" );
	}

	debug "module_select: ".join( " ", @handlers );
	return @handlers;
}

# satisfy POD coverage test - but don't put this function in the user manual
=pod
=cut

# if no input or output format was specified, but only 1 is registered, pick it
# $group parameter should be config group to search, i.e. "input" or "output"
# returns the format string which will be provided
sub singular_handler
{
	my $group = shift;

	debug "singular_handler($group)";
	my $count = 0;
	my ( $entry, $last );
	foreach $entry ( keys %{$modules{$group}} ) {
		if ( ref $modules{$group}{$entry} eq "ARRAY" ) {
			my $entry_count = scalar @{$modules{$group}{$entry}};
			$count += $entry_count;
			if ( $count > 1 ) {
				return undef;
			}
			if ( $entry_count == 1 ) {
				$last = $entry;
			}
		}
	}

	# if there's only one registered, that's the one to use
	debug "singular_handler: count=$count last=$last";
	return $count == 1 ? $last : undef;
}


=item fetch_main

This function is exported into the main package.
For all modules which registered with an "input" capability for the requested
file format at the time this is called, it will call the run() function on
behalf of each of the packages.

=cut

# Find and run all the fetch_main functions in packages under WebFetch.
# This eliminates the need for the sub-packages to export their own
# fetch_main(), which users found conflicted with each other when
# loading more than one WebFetch-derived module.

# fetch_main - eval wrapper for fetch_main2 to catch and display errors
sub main::fetch_main
{
	# run fetch_main2 in an eval so we can catch exceptions
	my $result = eval { &WebFetch::fetch_main2; };

	# process any error/exception that we may have gotten
	if ( $@ ) {
		my $ex = $@;

		# determine if there's an error message available to display
		my $pkg = __PACKAGE__;
		if ( ref $ex ) {
			if ( my $ex_cap = Exception::Class->caught(
				"WebFetch::Exception"))
			{
				if ( $ex_cap->isa( "WebFetch::TracedException" )) {
					warn $ex_cap->trace->as_string, "\n";
				}

				die "$pkg: ".$ex_cap->error."\n";
			}
			if ( $ex->can("stringify")) {
				# Error.pm, possibly others
				die "$pkg: ".$ex->stringify."\n";
			} elsif ( $ex->can("as_string")) {
				# generic - should work for many classes
				die "$pkg: ".$ex->as_string."\n";
			} else {
				die "$pkg: unknown exception of type "
					.(ref $ex)."\n";
			}
		} else {
			die "pkg: $@\n";
		}
	}

	# success
	exit 0;
}


sub fetch_main2
{
	# search for modules which have registered "cmdline" capability
	# collect their command line options
	my ( $cli_mod, @mod_options, @mod_usage );
	if (( exists $modules{cmdline} )
		and ( ref $modules{cmdline} eq "ARRAY" ))
	{
		foreach $cli_mod ( @{$modules{cmdline}}) {
			if ( eval "defined \@{".$cli_mod."::Options}" ) {
				eval "push \@mod_options,"
					."\@{".$cli_mod."::Options}";
			}
			if ( eval "defined \@{".$cli_mod."::Usage}" ) {
				eval "push \@mod_options, \@{"
					.$cli_mod."::Usage}";
			}
		}
	}

	# process command line
	my ( $result, %options );
	$result = eval { GetOptions ( \%options,
		"dir:s",
		"group:s",
		"mode:s",
		"source=s",
		"source_format:s",
		"dest=s",
		"dest_format:s",
		"fetch_urls",
		"quiet",
		"debug",
		@mod_options ) };
	if ( $@ ) {
		throw_getopt_error ( "command line processing failed: $@" );
	} elsif ( ! $result ) {
		throw_cli_usage ( "usage: $0 --dir dirpath "
			."[--group group] [--mode mode] "
			."[--source file] [--source_format fmt-string] "
			."[--dest file] [--dest_format fmt-string] "
			."[--fetch_urls] [--quiet] "
			.join( " ", @mod_usage ));
	}

	# set debugging mode
	if (( exists $options{debug}) and $options{debug}) {
		$debug = 1;
	}
	debug "fetch_main";


	# if either source/input or dest/output formats were not provided,
	# check if only one handler is registered - if so that's the default
	if ( !exists $options{source_format}) {
		if ( my $fmt = singular_handler( "input" )) {
			$options{source_format} = $fmt;
		}
	}
	if ( !exists $options{dest_format}) {
		if ( my $fmt = singular_handler( "output" )) {
			$options{dest_format} = $fmt;
		}
	}

	# check for modules to handle the specified source_format
	my ( @handlers, %handlers );
	if (( exists $modules{input}{ $options{source_format}} )
		and ( ref $modules{input}{ $options{source_format}}
			eq "ARRAY" ))
	{
		my $handler;
		foreach $handler (@{$modules{input}{$options{source_format}}})
		{
			if ( !exists $handlers{$handler}) {
				push @handlers, $handler;
				$handlers{$handler} = 1;
			}
		}
	}
	if ( exists $default_modules{ $options{source_format}} ) {
		my $handler = $default_modules{ $options{source_format}};
		if ( !exists $handlers{$handler}) {
			push @handlers, $handler;
			$handlers{$handler} = 1;
		}
	}
	
	# check if any handlers were found for this input format
	if ( ! @handlers ) {
		throw_no_handler( "input handler not found for "
			.$options{source_format});
	}

	# run the available handlers until one succeeds or none are left
	my $pkgname;
	my $run_count = 0;
	foreach $pkgname ( @handlers ) {
		debug "running for $pkgname";
		eval { &WebFetch::run( $pkgname, \%options )};
		if ( $@ ) {
			print STDERR "WebFetch: run eval error: $@\n";
		} else {
			$run_count++;
			last;
		}
	}
	if ( $run_count == 0 ) {
		throw_no_run( "no handlers were able or available to process "
			." source format" );
	}
}

=item $obj = WebFetch::new( param => "value", [...] )

Generally, the new function should be inherited and used from a derived
class.  However, WebFetch provides an AUTOLOAD function which will catch
wayward function calls from a subclass, and redirect it to the appropriate
function in the calling class, if it exists.

The AUTOLOAD feature is needed because, for example, when an object is
instantiated in a WebFetch::Input::* class, it will later be passed to
a WebFetch::Output::* class, whose data method functions can be accessed
this way as if the WebFetch object had become a member of that class.

=cut

# allocate a new object
sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	# initialize the object parameters
	$self->init(@_);

	# go fetch the data
	# this function must be provided by a derived module
	# non-fetching modules (i.e. data) must define $self->{no_fetch}=1
	if (( ! exists $self->{no_fetch}) or ! $self->{no_fetch}) {
		require WebFetch::Data::Store;
		if ( exists $self->{data}) {
			$self->{data}->isa( "WebFetch::Data::Store" )
				or throw_data_wrongtype "object data must be "
					."a WebFetch::Data::Store";
		} else {
			$self->{data} = WebFetch::Data::Store->new();
		}
		$self->fetch();
	}

	# the object has been created
	return $self;
}

=item $obj->init( ... )

This is called from the C<new> function that modules inherit from WebFetch.
If subclasses override it, they should still call it before completion.
It takes "name" => "value" pairs which are all placed verbatim as
attributes in C<$obj>.

=cut

# initialize attributes of new objects
sub init
{
	my $self = shift;
	if ( @_ ) {
		my %params = @_;
		@$self{keys %params} = values %params;
	}
}

=item WebFetch::mod_load ( $class )

This specifies a WebFetch module (Perl class) which needs to be loaded.
In case of an error, it throws an exception.

=cut

sub mod_load
{
	my $pkg = shift;

	# make sure we have the run package loaded
	eval "require $pkg";
	if ( $@ ) {
		throw_mod_load_failure( "failed to load $pkg: $@" );
	}
}

=item WebFetch::run

This function can be called by the C<main::fetch_main> function
provided by WebFetch or by another user function.
This handles command-line processing for some standard options,
calling the module-specific fetch function and WebFetch's $obj->save
function to save the contents to one or more files.

The command-line processing for some standard options are as follows:

=over 4

=item --dir I<directory>

(required) the directory in which to write output files

=item --group I<group>

(optional) the group ID to set the output file(s) to

=item --mode I<mode>

(optional) the file mode (permissions) to set the output file(s) to

=item --save_file I<save-file-path>

(optional) save a copy of the fetched info
in the file named by this parameter.
The contents of the file are determined by the C<--dest_format> parameter.
If C<--dest_format> isn't defined but only one module has registered a
file format for saving, then that will be used by default.

=item --quiet

(optional) suppress printed warnings for HTTP errors
I<(applies only to modules which use the WebFetch::get() function)>
in case they are not desired for cron outputs

=item --debug

(optional) print verbose debugging outputs,
only useful for developers adding new WebFetch-based modules
or finding/reporting a bug in an existing module

=back

Modules derived from WebFetch may add their own command-line options
that WebFetch::run() will use by defining a variable called
B<C<@Options>> in the calling module,
using the name/value pairs defined in Perl's Getopts::Long module.
Derived modules can also add to the command-line usage error message by
defining a variable called B<C<$Usage>> with a string of the additional
parameters, as they should appear in the usage message.

=cut

# command-line handling for WebFetch-derived classes
sub run
{
	my $run_pkg = shift;
	my $options_ref = shift;
	my $obj;

	debug "entered run for $run_pkg";

	# make sure we have the run package loaded
	mod_load $run_pkg;

	# Note: in order to add WebFetch-embedding capability, the fetch
	# routine saves its raw data without any HTML/XML/etc formatting
	# in @{$obj->{data}} and data-to-savable conversion routines in
	# %{$obj->{actions}}, which contains several structures with key
	# names matching software processing features.  The purpose of
	# this is to externalize the captured data so other software can
	# use it too.

	# create the new object
	# this also calls the $obj->fetch() routine for the module which
	# has inherited from WebFetch to do this
	debug "run before new";
	$obj = eval $run_pkg."->new( \%\$options_ref )";
	if ( $@ ) {
		throw_mod_run_failure( "module run failure: ".$@ );
	}

	# if the object had data for the WebFetch-embedding API,
	# then data processing is external to the fetch routine
	# (This externalizes the data for other software to capture it.)
	debug "run before output";
	my $dest_format = $obj->{dest_format};
	if ( !exists $obj->{actions}) {
		$obj->{actions} = {};
	}
	if (( exists $obj->{data})) {
		if ( exists $obj->{dest}) {
			if ( !exists $obj->{actions}{$dest_format}) {
				$obj->{actions}{$dest_format} = [];
			}
			push @{$obj->{actions}{$dest_format}}, [ $obj->{dest} ];
		}

		# perform requested actions on the data
		$obj->do_actions();
	} else {
		throw_no_save( "save failed: no data or nowhere to save it" );
	}

	debug "run before save";
	my $result = $obj->save();

	# check for errors, throw exception to report errors per savable item
	if ( ! $result ) {
		my $savable;
		my @errors;
		foreach $savable ( @{$obj->{savable}}) {
			(ref $savable eq "HASH") or next;
			if ( exists $savable->{error}) {
				push @errors, "file: ".$savable->{file}
					."error: " .$savable->{error};
			}
		}
		if ( @errors ) {
			throw_save_error( "error saving results in "
				.$obj->{dir}
				."\n".join( "\n", @errors )."\n" );
		}
	}

	return $result ? 0 : 1;
}

=item $obj->do_actions

I<C<do_actions> was added in WebFetch 0.10 as part of the
WebFetch Embedding API.>
Upon entry to this function, $obj must contain the following attributes:

=over 4

=item data

is a reference to a hash containing the following three (required)
keys:

=over 4

=item fields

is a reference to an array containing the names of the fetched data fields
in the order they appear in the records of the I<data> array.
This is necessary to define what each field is called
because any kind of data can be fetched from the web.

=item wk_names

is a reference to a hash which maps from
a key string with a "well-known" (to WebFetch) field type
to a field name used in this table.
The well-known names are defined as follows:

=over 4

=item title

a one-liner banner or title text
(plain text, no HTML tags)

=item url

URL or file path (as appropriate) to the news source

=item id

unique identifier string for the entry

=item date

a date stamp,
which must be program-readable
by Perl's Date::Calc module in the Parse_Date() function
in order to support timestamp-related comparisons
and processing that some users have requested.
If the date cannot be parsed by Date::Calc,
either translate it when your module captures it,
or do not define this "well-known" field
because it wouldn't fit the definition.
(plain text, no HTML tags)

=item summary

a paragraph of summary text in HTML

=item comments

number of comments/replies at the news site
(plain text, no HTML tags)

=item author

a name, handle or login name representing the author of the news item
(plain text, no HTML tags)

=item category

a word or short phrase representing the category, topic or department
of the news item
(plain text, no HTML tags)

=item location

a location associated with the news item
(plain text, no HTML tags)

=back

The field names for this table are defined in the I<fields> array.

The hash only maps for the fields available in the table.
If no field representing a given well-known name is present
in the data fields,
that well-known name key must not be defined in this hash.

=item records

an array containing the data records.
Each record is itself a reference to an array of strings which are
the data fields.
This is effectively a two-dimensional array or a table.

Only one table-type set of data is permitted per fetch operation.
If more are needed, they should be arranged as separate fetches
with different parameters.

=back

=item actions

is a reference to a hash.
The hash keys are names for handler functions.
The WebFetch core provides internal handler functions called
I<fmt_handler_html> (for HTML output), 
I<fmt_handler_xml> (for XML output), 
I<fmt_handler_wf> (for WebFetch::General format), 
However, WebFetch modules may provide additional
format handler functions of their own by prepending
"fmt_handler_" to the key string used in the I<actions> array.

The values are array references containing
I<"action specs">,
which are themselves arrays of parameters
that will be passed to the handler functions
for generating output in a specific format.
There may be more than one entry for a given format if multiple outputs
with different parameters are needed.

The presence of values in this field mean that output is to be
generated in the specified format.
The presence of these would have been chosed by the WebFetch module that
created them - possibly by default settings or by a command-line argument
that directed a specific output format to be used.

For each valid action spec,
a separate "savable" (contents to be placed in a file)
will be generated from the contents of the I<data> variable.

The valid (but all optional) keys are

=over 4

=item html

the value must be a reference to an array which specifies all the
HTML generation (html_gen) operations that will take place upon the data.
Each entry in the array is itself an array reference,
containing the following parameters for a call to html_gen():

=over 4

=item filename

a file name or path string
(relative to the WebFetch output directory unless a full path is given)
for output of HTML text.

=item params

a hash reference containing optional name/value parameters for the
HTML format handler.

=over 4

=item filter_func

(optional)
a reference to code that, given a reference to an entry in
@{$self->{data}{records}},
returns true (1) or false (0) for whether it will be included in the
HTML output.
By default, all records are included.

=item sort_func

(optional)
a reference to code that, given references to two entries in
@{$self->{data}{records}},
returns the sort comparison value for the order they should be in.
By default, no sorting is done and all records (subject to filtering)
are accepted in order.

=item format_func

(optional)
a refernce to code that, given a reference to an entry in
@{$self->{data}{records}},
stores a savable representation of the string.

=back

=back

=back

=back

Additional valid keys may be created by modules that inherit from WebFetch
by supplying a method/function named with "fmt_handler_" preceding the
string used for the key.
For example, for an "xyz" format, the handler function would be
I<fmt_handler_xyz>.
The value (the "action spec") of the hash entry
must be an array reference.
Within that array are "action spec entries",
each of which is a reference to an array containing the list of
parameters that will be passed verbatim to the I<fmt_handler_xyz> function.

When the format handler function returns, it is expected to have
created entries in the $obj->{savables} array
(even if they only contain error messages explaining a failure),
which will be used by $obj->save() to save the files and print the
error messages.

For coding examples, use the I<fmt_handler_*> functions in WebFetch.pm itself.

=back

=cut

sub do_actions
{
	my ( $self ) = @_;
	debug "in WebFetch::do_actions";

	# we *really* need the data and actions to be set!
	# otherwise assume we're in WebFetch 0.09 compatibility mode and
	# $self->fetch() better have created its own savables already
	if (( !exists $self->{data}) or ( !exists $self->{actions})) {

		return
	}

	# loop through all the actions
	my $action_spec;
	foreach $action_spec ( keys %{$self->{actions}} ) {
		my $handler_ref;

		# check for modules to handle the specified dest_format
		my ( @handlers, %handlers );
		my $action_handler = "fmt_handler_".$action_spec;
		if ( exists $modules{output}{$action_spec}) {
			my $class;
			foreach $class ( @{$modules{output}{$action_spec}}) {
				if ( $class->can( $action_handler )) {
					$handler_ref = \&{$class."::".$action_handler};
					last;
				}
			}
		}

		if ( defined $handler_ref )
		{
			# loop through action spec entries (parameter lists)
			my $entry;
			foreach $entry ( @{$self->{actions}{$action_spec}}) {
				# parameters must be in an ARRAY ref
				if (ref $entry ne "ARRAY" ) {
					warn "warning: entry in action spec "
						."\"".$action_spec."\""
						."expected to be ARRAY, found "
						.(ref $entry)." instead "
						."- ignored\n";
					next;
				}

				# everything looks OK - call the handler
				&$handler_ref($self, @$entry);

				# if there were errors, the handler should
				# have created a savable entry which
				# contains only the error entry so that
				# it will be reported by $self->save()
			}
		} else {
			warn "warning: action \"$action_spec\" specified but "
				."\&{\$self->$action_handler}() "
				."not defined in "
				.(ref $self)." - ignored\n";
		}
	}
}

=item $obj->fetch

B<This function must be provided by each derived module to perform the
fetch operaton specific to that module.>
It will be called from C<new()> so you should not call it directly.
Your fetch function should extract some data from somewhere
and place of it in HTML or other meaningful form in the "savable" array.

TODO: cleanup references to WebFetch 0.09 and 0.10 APIs.

Upon entry to this function, $obj must contain the following attributes:

=over 4

=item dir

The name of the directory to save in.
(If called from the command-line, this will already have been provided
by the required C<--dir> parameter.)

=item savable

a reference to an array where the "savable" items will be placed by
the $obj->fetch function.
(You only need to provide an array reference -
other WebFetch functions can write to it.)

In WebFetch 0.10 and later,
this parameter should no longer be supplied by the I<fetch> function
(unless you wish to use 0.09 backward compatibility)
because it is filled in by the I<do_actions>
after the I<fetch> function is completed
based on the I<data> and I<actions> variables
that are set in the I<fetch> function.
(See below.)

Each entry of the savable array is a hash reference with the following
attributes:

=over 4

=item file

file name to save in

=item content

scalar w/ entire text or raw content to write to the file

=item group

(optional) group setting to apply to file

=item mode

(optional) file permissions to apply to file

=back

Contents of savable items may be generated directly by derived modules
or with WebFetch's C<html_gen>, C<html_savable> or C<raw_savable>
functions.
These functions will set the group and mode parameters from the
object's own settings, which in turn could have originated from
the WebFetch command-line if this was called that way.

=back

Note that the fetch functions requirements changed in WebFetch 0.10.
The old requirement (0.09 and earlier) is supported for backward compatibility.

I<In WebFetch 0.09 and earlier>,
upon exit from this function, the $obj->savable array must contain
one entry for each file to be saved.
More than one array entry means more than one file to save.
The WebFetch infrastructure will save them, retaining backup copies
and setting file modes as needed.

I<Beginning in WebFetch 0.10>, the "WebFetch embedding" capability was introduced.
In order to do this, the captured data of the I<fetch> function 
had to be externalized where other Perl routines could access it.  
So the fetch function now only populates data structures
(including code references necessary to process the data.)

Upon exit from the function,
the following variables must be set in C<$obj>:

=over 4

=item data

is a reference to a hash which will be used by the I<do_actions> function.
(See above.)

=item actions

is a reference to a hash which will be used by the I<do_actions> function.
(See above.)

=back

=cut

# placeholder for fetch routines by derived classes
sub fetch
{
	throw_abstract "fetch is an abstract function and must be overridden";
}


=item $obj->get

This WebFetch utility function will get a URL and return a reference
to a scalar with the retrieved contents.
Upon entry to this function, C<$obj> must contain the following attributes: 

=over 4

=item source

the URL to get

=item quiet

a flag which, when set to a non-zero (true) value,
suppresses printing of HTTP request errors on STDERR

=back

=cut

# utility function to get the contents of a URL
sub get
{
        my ( $self, $source ) = @_;

	if ( ! defined $source ) {
		$source = $self->{source};
	}
	if ( $self->{debug}) {
		print STDERR "debug: get(".$source.")\n";
	}

        # send request, capture response
        my $ua = LWP::UserAgent->new;
	$ua->agent("WebFetch/$VERSION ".$ua->agent);
        my $request = HTTP::Request->new(GET => $source);
        my $response = $ua->request($request);

        # abort on failure
        if ($response->is_error) {
                WebFetch::Exception::NetworkGet->throw(
			"The request received an error: "
			.$response->as_string );
        }

        # return the content
        my $content = $response->content;
	return \$content;
}

=item $obj->html_savable( $filename, $content )

I<In WebFetch 0.10 and later, this should be used only in
format handler functions.  See do_actions() for details.>

This WebFetch utility function stores pre-generated HTML in a new entry in
the $obj->{savable} array, for later writing to a file.
It's basically a simple wrapper that puts HTML comments
warning that it's machine-generated around the provided HTML text.
This is generally a good idea so that neophyte webmasters
(and you know there are a lot of them in the world :-)
will see the warning before trying to manually modify
your automatically-generated text.

See $obj->fetch for details on the contents of the C<savable> parameter

=cut

# utility function to make a savable record for HTML text
sub html_savable
{
        my ( $self, $filename, $content ) = @_;

	$self->raw_savable( $filename,
		"<!--- begin text generated by "
		."Perl5 WebFetch $VERSION - do not manually edit --->\n"
		."<!--- WebFetch can be found at "
		."http://www.webfetch.org/ --->\n"
		.$content
		."<!--- end text generated by "
		."Perl5 WebFetch $VERSION - do not manually edit --->\n" );
}

=item $obj->raw_savable( $filename, $content )

I<In WebFetch 0.10 and later, this should be used only in
format handler functions.  See do_actions() for details.>

This WebFetch utility function stores any raw content and a filename
in the $obj->{savable} array,
in preparation for writing to that file.
(The actual save operation may also automatically include keeping
backup files and setting the group and mode of the file.)

See $obj->fetch for details on the contents of the C<savable> parameter

=cut

# utility function to make a savable record for raw text
sub raw_savable
{
        my ( $self, $filename, $content ) = @_;

	if ( !exists $self->{savable}) {
		$self->{savable} = [];
	}
        push ( @{$self->{savable}}, {
                'file' => $filename,
                'content' => $content,
		(( exists $self->{group}) ? ('group' => $self->{group}) : ()),
		(( exists $self->{mode}) ? ('mode' => $self->{mode}) : ())
                });
}

=item $obj->direct_fetch_savable( $filename, $source )

I<This should be used only in format handler functions.
See do_actions() for details.>

This adds a task for the save function to fetch a URL and save it
verbatim in a file.  This can be used to download links contained
in a news feed.

=cut

sub direct_fetch_savable
{
	my ( $self, $url ) = @_;

	if ( !exists $self->{savable}) {
		$self->{savable} = [];
	}
	my $filename = $url;
	$filename =~ s=[;?].*==;
	$filename =~ s=^.*/==;
	push ( @{$self->{savable}}, {
		'url' => $url,
		'file' => $filename,
		'index' => 1,
		(( exists $self->{group}) ? ('group' => $self->{group}) : ()),
		(( exists $self->{mode}) ? ('mode' => $self->{mode}) : ())
		});
}

=item $obj->no_savables_ok

This can be used by an output function which handles its own intricate output
operation (such as WebFetch::Output::TWiki).  If the savables array is empty,
it would cause an error.  Using this function drops a note in it which
basically says that's OK.

=cut

sub no_savables_ok
{
	my $self = shift;

	push ( @{$self->{savable}}, {
		'ok_empty' => 1,
		});
}

=item $obj->save

This WebFetch utility function goes through all the entries in the
$obj->{savable} array and saves their contents,
providing several services such as keeping backup copies, 
and setting the group and mode of the file, if requested to do so.

If you call a WebFetch-derived module from the command-line run()
or fetch_main() functions, this will already be done for you.
Otherwise you will need to call it after populating the
C<savable> array with one entry per file to save.

Upon entry to this function, C<$obj> must contain the following attributes: 

=over 4

=item dir

directory to save files in

=item savable

names and contents for files to save

=back

See $obj->fetch for details on the contents of the C<savable> parameter

=cut

# file-save routines for all WebFetch-derived classes
sub save
{
	my $self = shift;

	if ( $self->{debug} ) {
		print STDERR "entering save()\n";
	}

	# check if we have attributes needed to proceed
	if ( !exists $self->{"dir"}) {
		die "WebFetch: directory path missing - "
			."required for save\n";
	}
	if ( !exists $self->{savable}) {
		die "WebFetch: nothing to save\n";
	}
	if ( ref($self->{savable}) ne "ARRAY" ) {
		die "WebFetch: cannot save - savable is not an array\n";
	}

	# if fetch_urls is defined, turn link fields in the data to savables
	if (( exists $self->{fetch_urls}) and $self->{fetch_urls}) {
		my $url_fnum = $self->wk2fnum( "url" );
		my $entry;
		$self->data->reset_pos;
		while ( $entry = $self->data->next_record()) {
			my $url = $entry->url;
			if ( defined $url ) {
				$self->direct_fetch_savable( $entry->url );
			}
		}
	}

	# loop through "savable" (grouped content and filename destination)
	my $savable;
	foreach $savable ( @{$self->{savable}}) {

		if ( exists $savable->{file}) {
			debug "saving ".$savable->{file}."\n";
		}

		# an output module may have handled a more intricate operation
		if ( exists $savable->{ok_empty}) {
			last;
		}

		# verify contents of savable record
		if ( !exists $savable->{file}) {
			$savable->{error} = "missing file name - skipped";
			next;
		}
		if (( !exists $savable->{content})
			and ( !exists $savable->{url}))
		{
			$savable->{error} = "missing content or URL - skipped";
			next;
		}

		# generate file names
		my $new_content = $self->{"dir"}."/N".$savable->{file};
		my $main_content = $self->{"dir"}."/".$savable->{file};
		my $old_content = $self->{"dir"}."/O".$savable->{file};

		# make sure the Nxx "new content" file does not exist yet
		if ( -f $new_content ) {
			if ( !unlink $new_content ) {
				$savable->{error} = "cannot unlink "
					.$new_content.": $!";
				next;
			}
		}

		# if a URL was provided and index flag is set, use index file
		my %id_index;
		my ( $timestamp, $filename );
		my $was_in_index = 0;
		if (( exists $savable->{url}) and ( exists $savable->{index}))
		{
			require DB_File;
			tie %id_index, 'DB_File',
				$self->{dir}."/id_index.db",
				&DB_File::O_CREAT|&DB_File::O_RDWR, 0640;
			if ( exists $id_index{$savable->{url}}) {
				( $timestamp, $filename ) =
					split /#/, $id_index{$savable->{url}};
				$was_in_index = 1;
			} else {
				$timestamp = time;
				$id_index{$savable->{url}} =
					$timestamp."#".$savable->{file};
			}
			untie %id_index ;
		}

		# For now, we consider it done if the file was in the index.
		# Future options would be to check if URL was modified.
		if ( $was_in_index ) {
			next;
		}

		# if a URL was provided and no content, get content from URL
		if (( ! exists $savable->{content})
			and ( exists $savable->{url}))
		{
			$savable->{content} =
				eval { ${$self->get($savable->{url})} }; 
			if ( $@ ) {
				next;
			}
		}

		# write content to the "new content" file
		if ( ! open ( new_content, ">:utf8", "$new_content" )) {
			$savable->{error} = "cannot open $new_content: $!";
			next;
		}
		if ( !print new_content $savable->{content}) {
			$savable->{error} = "failed to write to "
				.$new_content.": $!";
			close new_content;
			next;
		}
		if ( !close new_content ) {
			# this can happen with NFS errors
			$savable->{error} = "failed to close "
				.$new_content.": $!";
			next;
		}

		# remove the "old content" file to get it out of the way
		if ( -f $old_content ) {
			if ( !unlink $old_content ) {
				$savable->{error} = "cannot unlink "
					.$old_content.": $!";
				next;
			}
		}

		# move the main content to the old content - now it's a backup
		if ( -f $main_content ) {
			if ( !rename $main_content, $old_content ) {
				$savable->{error} = "cannot rename "
					.$main_content." to "
					.$old_content.": $!";
				next;
			}
		}

		# chgrp the "new content" before final installation
		if ( exists $savable->{group}) {
			my $gid = $savable->{group};
			if ( $gid !~ /^[0-9]+$/o ) {
				$gid = (getgrnam($gid))[2];
				if ( ! defined $gid ) {
					$savable->{error} = "cannot chgrp "
						.$new_content.": "
						.$savable->{group}
						." does not exist";
					next;
				}
			}
			if ( ! chown $>, $gid, $new_content ) {
				$savable->{error} = "cannot chgrp "
					.$new_content." to "
					.$savable->{group}.": $!";
				next;
			}
		}

		# chmod the "new content" before final installation
		if ( exists $savable->{mode}) {
			if ( ! chmod oct($savable->{mode}), $new_content ) {
				$savable->{error} = "cannot chmod "
					.$new_content." to "
					.$savable->{mode}.": $!";
				next;
			}
		}

		# move the new content to the main content - final install
		if ( -f $new_content ) {
			if ( !rename $new_content, $main_content ) {
				$savable->{error} = "cannot rename "
					.$new_content." to "
					.$main_content.": $!";
				next;
			}
		}
	}

	# loop through savable to report any errors
	my $err_count = 0;
	foreach $savable ( @{$self->{savable}}) {
		if ( exists $savable->{error}) {
			print STDERR "WebFetch: failed to save "
				.$savable->{file}.": "
				.$savable->{error}."\n";
			$err_count++;
		}
	}
	if ( $err_count ) {
		die "WebFetch: $err_count errors - fetch/save failed\n";
	}

	# success if we got here
	return 1;
}

#
# shortcuts to data object functions
#

sub data { my $self = shift; return $self->{data}; }
sub wk2fname { my $self = shift; return $self->{data}->wk2fname( @_ )};
sub fname2fnum { my $self = shift; return $self->{data}->fname2fnum( @_ )};
sub wk2fnum { my $self = shift; return $self->{data}->wk2fnum( @_ )};

=item AUTOLOAD functionality

When a WebFetch input object is passed to an output class, operations
on $self would not usually work.  WebFetch subclasses are considered to be
cooperating with each other.  So WebFetch provides AUTOLOAD functionality
to catch undefined function calls for its subclasses.  If the calling 
class provides a function by the name that was attempted, then it will
be redirected there.

=cut

# autoloader catches calls to unknown functions
# redirect to the class which made the call, if the function exists
sub AUTOLOAD
{
	my $self = shift;
	my $type = ref($self) or throw_autoload_fail "self is not an object";

	my $name = $AUTOLOAD;
	$name =~ s/.*://;   # strip fully-qualified portion, just want function

	# decline all-caps names - reserved for special Perl functions
	my ( $package, $filename, $line ) = caller;
	( $name =~ /^[A-Z]+$/ ) and return;
	debug __PACKAGE__."::AUTOLOAD $name";

	# check for function in caller package
	# (WebFetch may hand an input module's object to an output module)
	if ( $package->can( $name )) {
		# make an alias of the sub
		{
			no strict 'refs';
			*{__PACKAGE__."::".$name} = \&{$package."::".$name};
		}
		#my $retval = eval $package."::".$name."( \$self, \@_ )";
		my $retval = eval { $self->$name( @_ ); };
		if ( $@ ) {
			my $e = Exception::Class->caught();
			ref $e ? $e->rethrow
				: throw_autoload_fail "failure in "
					."autoloaded function: ".$e;
		}
		return $retval;
	}

	# if we got here, we failed
	throw_autoload_fail "function $name not found - "
		."called by $package ($filename line $line)";
}

1;
__END__
# remainder of POD docs follow

=head2 WRITING WebFetch-DERIVED MODULES

The easiest way to make a new WebFetch-derived module is to start
from the module closest to your fetch operation and modify it.
Make sure to change all of the following:

=over 4

=item fetch function

The fetch function is the meat of the operation.
Get the desired info from a local file or remote site and place the
contents that need to be saved in the C<savable> parameter.

=item module name

Be sure to catch and change them all.

=item file names

The code and documentation may refer to output files by name.

=item module parameters

Change the URL, number of links, etc as necessary.

=item command-line parameters

If you need to add command-line parameters, modify both the
B<C<@Options>> and B<C<$Usage>> variables.
Don't forget to add documentation for your command-line options
and remove old documentation for any you removed.

When adding documentation, if the existing formatting isn't enough
for your changes, there's more information about
Perl's
POD ("plain old documentation")
embedded documentation format at
http://www.cpan.org/doc/manual/html/pod/perlpod.html

=item authors

Add yourself as an author if you added any significant functionality.
But if you used anyone else's code, retain the existing author credits
in any module you modify to make a new one.

=back

Please consider contributing any useful changes back to the WebFetch
project at C<maint@webfetch.org>.

=head1 ACKNOWLEDGEMENTS

WebFetch was written by Ian Kluft
Send patches, bug reports, suggestions and questions to
C<maint@webfetch.org>.

Some changes in versions 0.12-0.13 (Aug-Sep 2009) were made for and
sponsored by Twiki Inc (formerly TWiki.Net).

=head1 LICENSE

WebFetch is Open Source software distributed via the
Comprehensive Perl Archive Network (CPAN),
a worldwide network of Perl web mirror sites.
WebFetch may be copied under the same terms and licensing as Perl itelf.

=head1 SEE ALSO

=for html
A current copy of the source code and documentation may be found at
<a href="http://www.webfetch.org/">http://www.webfetch.org/</a>

=for text
A current copy of the source code and documentation may be found at
http://www.webfetch.org/

=for man
A current copy of the source code and documentation may be found at
http://www.webfetch.org/

TODO: fill in these lists

=for html
<a href="http://www.perl.org/">perl</a>(1),
<a href="WebFetch::Input::PerlStruct.html">WebFetch::Input::PerlStruct</a>,
<a href="WebFetch::Input::SiteNews.html">WebFetch::Input::SiteNews</a>,
<a href="WebFetch::Input::Atom.html">WebFetch::Input::Atom</a>,
<a href="WebFetch::Input::RSS.html">WebFetch::Input::RSS</a>,
<a href="WebFetch::Input::Dump.html">WebFetch::Input::Dump</a>,
<a href="WebFetch::Output::TT.html">WebFetch::Output::TT</a>,
<a href="WebFetch::Output::Dump.html">WebFetch::Output::Dump</a>,

=for text
perl(1), WebFetch::Input::PerlStruct, WebFetch::Input::SiteNews, 
WebFetch::Input::Atom, WebFetch::Input::RSS, WebFetch::Input::Dump,
WebFetch::Output::TT, WebFetch::Output::Dump

=for man
perl(1), WebFetch::Input::PerlStruct, WebFetch::Input::SiteNews,
WebFetch::Input::Atom, WebFetch::Input::RSS, WebFetch::Input::Dump,
WebFetch::Output::TT, WebFetch::Output::Dump

=cut
