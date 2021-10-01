package Test2::Tools::LoadModule;

use 5.008001;

use strict;
use warnings;

# OK, the following is probably paranoia. But if Perl 7 decides to
# change this particular default I'm ready. Unless they eliminate $].
no if $] ge '5.020', feature => qw{ signatures };

use Carp;
use Exporter 5.567;	# Comes with Perl 5.8.1.
# use File::Find ();
# use File::Spec ();
# use Getopt::Long 2.34;	# Comes with Perl 5.8.1.
use Test2::API ();
use Test2::Util ();

use base qw{ Exporter };

our $VERSION = '0.007';
$VERSION =~ s/ _ //smxg;

{
    my @test2 = qw{
	all_modules_tried_ok
	clear_modules_tried
	load_module_ok
	load_module_or_skip
	load_module_or_skip_all
    };

    my @more = qw{
	require_ok
	use_ok
    };

    my @private = qw{
	__build_load_eval
	__get_hint_hash
	DEFAULT_LOAD_ERROR
	ERR_IMPORT_BAD
	ERR_MODULE_UNDEF
	ERR_OPTION_BAD
	ERR_SKIP_NUM_BAD
	ERR_VERSION_BAD
	HINTS_AVAILABLE
	TEST_MORE_ERROR_CONTEXT
	TEST_MORE_LOAD_ERROR
    };

    our @EXPORT_OK = ( @test2, @more, @private );

    our %EXPORT_TAGS = (
	all		=> [ @test2, @more ],
	default	=> \@test2,
	more	=> \@more,
	private	=> \@private,
	test2	=> \@test2,
    );

    our @EXPORT = @{ $EXPORT_TAGS{default} };	## no critic (ProhibitAutomaticExportation)
}

use constant ARRAY_REF		=> ref [];
use constant HASH_REF		=> ref {};

use constant CALLER_HINT_HASH	=> 10;

use constant DEFAULT_LOAD_ERROR	=> '%s';

use constant ERR_IMPORT_BAD	=>
	'Import list must be an array reference, or undef';
use constant ERR_MODULE_UNDEF	=> 'Module name must be defined';
use constant ERR_OPTION_BAD	=> 'Bad option';
use constant ERR_SKIP_NUM_BAD	=>
	'Number of skipped tests must be an unsigned integer';
use constant ERR_VERSION_BAD	=> q/Version '%s' is invalid/;

use constant HINTS_AVAILABLE	=> $] ge '5.010';

# The following cribbed shamelessly from version::regex 0.9924,
# after being munged to suit by tools/version_regex 0.000_010.
# This technical debt is incurred to avoid having to require a version
# of the version module large enough to export the is_lax() subroutine.
use constant LAX_VERSION	=> qr/(?x: (?x:
	v (?-x:[0-9]+) (?-x: (?-x:\.[0-9]+)+ (?-x:_[0-9]+)? )?
	|
	(?-x:[0-9]+)? (?-x:\.[0-9]+){2,} (?-x:_[0-9]+)?
    ) | (?x: (?-x:[0-9]+) (?-x: (?-x:\.[0-9]+) | \. )? (?-x:_[0-9]+)?
	|
	(?-x:\.[0-9]+) (?-x:_[0-9]+)?
    ) )/;

use constant TEST_MORE_ERROR_CONTEXT	=> q/Tried to %s '%s'./;
use constant TEST_MORE_LOAD_ERROR	=> 'Error:  %s';
use constant TEST_MORE_OPT		=> {
    load_error	=> TEST_MORE_LOAD_ERROR,
    require	=> 1,
};

{
    my %module_tried;

    sub load_module_ok (@) {	## no critic (RequireArgUnpacking)
	my @arg = _validate_args( 0, @_ );

	# We do this now in case _load_module_ok() throws an uncaught
	# exception, just so we have SOME record we tried.
	$module_tried{ $arg[1] } = undef;

	my $ctx = Test2::API::context();

	my $rslt = _load_module_ok( @arg );

	$module_tried{ $arg[1] } = $rslt;

	$ctx->release();

	return $rslt;
    }

    sub all_modules_tried_ok (@) {
	my @where = @_;
	@where
	    or @where = ( 'blib/lib', 'blib/arch' );

	require File::Find;
	require File::Spec;

	my @not_tried;
	foreach my $d ( @where ) {
	    File::Find::find( sub {
		    m/ [.] pm \z /smx
			or return;
		    my ( undef, $dir, $name ) = File::Spec->splitpath(
			File::Spec->abs2rel( $File::Find::name, $d ) );
		    my @dir = File::Spec->splitdir( $dir );
		    $dir[-1]
			or pop @dir;
		    ( my $module = join '::', @dir, $name ) =~ s/ [.] pm //smx;
		    exists $module_tried{$module}
			or push @not_tried, $module;
		}, $d );
	}

	if ( @not_tried ) {

	    my $ctx = Test2::API::context();

	    $ctx->fail( "Module $_ not tried" ) for sort @not_tried;

	    $ctx->release();

	    return 0;
	}
    }

    sub clear_modules_tried () {
	%module_tried = ();
	return;
    }
}

sub _load_module_ok {
    my ( $opt, $module, $version, $import, $name, @diag ) = @_;

    local $@ = undef;

    my $eval = __build_load_eval( $opt, $module, $version, $import );

    defined $name
	or $name = $eval;

    my $ctx = Test2::API::context();

    _eval_in_pkg( $eval, $ctx->trace()->call() )
	and return $ctx->pass_and_release( $name );

    chomp $@;

    $opt->{load_error}
	and push @diag, sprintf $opt->{load_error}, $@;

    return $ctx->fail_and_release( $name, @diag );
}

sub load_module_or_skip (@) {	## no critic (RequireArgUnpacking,RequireFinalReturn)
    my ( $opt, $module, $version, $import, $name, $num ) = _validate_args( 5, @_ );

    _load_module( $opt, $module, $version, $import )
	and return;

    defined $name
	or $name = sprintf 'Unable to %s',
	    __build_load_eval( $opt, $module, $version, $import );
    defined $num
	and $num =~ m/ [^0-9] /smx
	and croak ERR_SKIP_NUM_BAD;

    my $ctx = Test2::API::context();
    $num ||= 1;
    $ctx->skip( 'skipped test', $name ) for 1 .. $num;

    $ctx->release();
    no warnings qw{ exiting };
    last SKIP;
}

sub load_module_or_skip_all (@) {	## no critic (RequireArgUnpacking)
    my ( $opt, $module, $version, $import, $name ) = _validate_args( 4, @_ );

    _load_module( $opt, $module, $version, $import )
	and return;

    defined $name
	or $name = sprintf 'Unable to %s',
	    __build_load_eval( $opt, $module, $version, $import );

    my $ctx = Test2::API::context();
    $ctx->plan( 0, SKIP => $name );
    $ctx->release();

    return;
}

sub _load_module {
    my ( $opt, $module, $version, $import ) = @_;

    local $@ = undef;

    my $eval = __build_load_eval( $opt, $module, $version, $import );

    return _eval_in_pkg( $eval, _get_call_info() )
}

{
    my $psr;

    # Because we want to work with Perl 5.8.1 we are limited to
    # Getopt::Long 2.34, and therefore getoptions(). So we expect the
    # arguments to be in a suitably-localized @ARGV. The optional
    # argument is a reference to a hash into which we place the option
    # values. If omitted, we create a reference to a new hash. Either
    # way the hash reference gets returned.
    sub _parse_opts {
	my ( $opt ) = @_;
	$opt ||= {};
	{
	    unless ( $psr ) {
		require Getopt::Long;
		Getopt::Long->VERSION( 2.34 );
		$psr = Getopt::Long::Parser->new();
		$psr->configure( qw{ posix_default } );
	    }

	    my $opt_err;
	    local $SIG{__WARN__} = sub { $opt_err = $_[0] };
	    $psr->getoptions( $opt, qw{
		    load_error=s
		    require|req!
		},
	    ) or do {
		if ( defined $opt_err ) {
		    chomp $opt_err;
		    croak $opt_err;
		} else {
		    croak ERR_OPTION_BAD;
		}
	    };
	}
	if ( $opt->{load_error} ) {
	    $opt->{load_error} =~ m/ ( %+ ) [ #0+-]* [0-9]* s /smx
		and length( $1 ) % 2
		or $opt->{load_error} = '%s';
	}
	return $opt;
    }
}

sub import {	## no critic (RequireArgUnpacking,ProhibitBuiltinHomonyms)
    ( my $class, local @ARGV ) = @_;	# See _parse_opts
    if ( @ARGV ) {
	my %opt;
	_parse_opts( \%opt );
	if ( HINTS_AVAILABLE ) {
	    $^H{ _make_pragma_key() } = $opt{$_} for keys %opt;
	} else {
	    keys %opt
		and carp "Import options ignored under Perl $]";
	}
	@ARGV
	    or return;
    }
    return $class->export_to_level( 1, $class, @ARGV );
}

sub require_ok ($) {
    my ( $module ) = @_;
    defined $module
	or croak ERR_MODULE_UNDEF;
    my $ctx = Test2::API::context();
    my $rslt = _load_module_ok( TEST_MORE_OPT,
	$module, undef, undef, "require $module;",
	sprintf( TEST_MORE_ERROR_CONTEXT, require => $module ),
    );
    $ctx->release();
    return $rslt;
}

sub use_ok ($;@) {
    my ( $module, @arg ) = @_;
    defined $module
	or croak ERR_MODULE_UNDEF;
    my $version = ( defined $arg[0] && $arg[0] =~ LAX_VERSION ) ?
	shift @arg : undef;
    my $ctx = Test2::API::context();
    my $rslt = _load_module_ok( TEST_MORE_OPT,
	$module, $version, \@arg, undef,
	sprintf( TEST_MORE_ERROR_CONTEXT, use => $module ),
    );
    $ctx->release();
    return $rslt;
}

sub _make_pragma_key {
    return join '', __PACKAGE__, '/', $_;
}

sub _caller_class {
    my ( $lvl ) = @_;
    my ( $pkg ) = caller( $lvl || 1 );
    my $code = $pkg->can( 'CLASS' )
	or croak ERR_MODULE_UNDEF;
    return $code->();
}

{

    my %default_hint = (
	load_error	=> DEFAULT_LOAD_ERROR,
    );

    sub __get_hint_hash {
	my ( $level ) = @_;
	$level ||= 0;
	my $hint_hash = ( caller( $level ) )[ CALLER_HINT_HASH ];
	my %rslt = %default_hint;
	if ( HINTS_AVAILABLE ) {
	    foreach ( keys %{ $hint_hash } ) {
		my ( $hint_pkg, $hint_key ) = split qr< / >smx;
		__PACKAGE__ eq $hint_pkg
		    and $rslt{$hint_key} = $hint_hash->{$_};
	    }
	}
	return \%rslt;
    }
}

sub __build_load_eval {
    my @arg = @_;
    HASH_REF eq ref $arg[0]
	or unshift @arg, {};
    my ( $opt, $module, $version, $import ) = @arg;
    my @eval = "use $module";

    defined $version
	and push @eval, $version;

    if ( $import && @{ $import } ) {
	push @eval, "qw{ @{ $import } }";
    } elsif ( defined $import xor not $opt->{require} ) {
	# Do nothing.
    } else {
	push @eval, '()';
    }

    return "@eval;";
}

sub _validate_args {
    ( my $max_arg, local @ARGV ) = @_;
    my $opt = _parse_opts( __get_hint_hash( 2 ) );

    if ( $max_arg && @ARGV > $max_arg ) {
	( my $sub_name = ( caller 1 )[3] ) =~ s/ .* :: //smx;
	croak sprintf '%s() takes at most %d arguments', $sub_name, $max_arg;
    }

    my ( $module, $version, $import, $name, @diag ) = @ARGV;

    defined $module
	or $module = _caller_class( 2 );

    if ( defined $version ) {
	$version =~ LAX_VERSION
	    or croak sprintf ERR_VERSION_BAD, $version;
    }

    not defined $import
	or ARRAY_REF eq ref $import
	or croak ERR_IMPORT_BAD;

    return ( $opt, $module, $version, $import, $name, @diag );
}

sub _eval_in_pkg {
    my ( $eval, $pkg, $file, $line ) = @_;

    my $e = <<"EOD";
package $pkg;
#line $line "$file"
$eval;
1;
EOD

    # We need the stringy eval() so we can mess with Perl's concept of
    # what the current file and line number are for the purpose of
    # formatting the exception, AND as a convenience to get symbols
    # imported.
    my $rslt = eval $e;	## no critic (ProhibitStringyEval)

    return $rslt;
}

sub _get_call_info {
    my $lvl = 0;
    while ( my @info = caller $lvl++ ) {
	__PACKAGE__ eq $info[0]
	    and next;
	$info[1] =~ m/ \A [(] eval \b /smx	# )
	    or return @info;
    }
    confess 'Bug - Unable to determine caller';
}

1;

__END__

=head1 NAME

Test2::Tools::LoadModule - Test whether a module can be successfully loaded.

=head1 SYNOPSIS

 use Test2::V0;
 use Test2::Tools::LoadModule;
 
 load_module_ok 'My::Module';
 
 done_testing();

=head1 DESCRIPTION

This L<Test2::Tools|Test2::Tools> module tests whether a module can be
loaded, and optionally whether it has at least a given version, and
exports specified symbols. It can also skip tests, or skip all tests,
based on these criteria.

L<Test2::Manual::Testing::Migrating|Test2::Manual::Testing::Migrating>
deals with migrating from L<Test::More|Test::More> to
L<Test2::V0|Test2::V0>. It states that instead of C<require_ok()> you
should simply use the C<require()> built-in, since a failure to load the
required module or file will cause the test script to fail anyway. The
same is said for C<use_ok()>.

In my perhaps-not-so-humble opinion this overlooks the fact that if you
can not load the module you are testing, it may make sense to abort not
just the individual test script but the entire test run. Put another
way, the absence of an analogue to L<Test::More|Test::More>'s
C<require_ok()> means there is no analogue to

 require_ok( 'My::Module' ) or BAIL_OUT();

This module restores that functionality.

B<Note> that if you are using this module with testing tools that are
not based on L<Test2::V0|Test2::V0> you may have to tweak the load order
of modules. I ran into this in the early phases of implementation, and
fixed it for my own use by initializing the testing system as late as
possible, but I can not promise that all such problems have been
eliminated.

=head1 CAVEAT

Accurately testing whether a module can be loaded is more complicated
than it might first appear. One known issue is that you can get a false
pass if the module under test forgets to load a module it needs, but
this module loads it for its own use.

Ideally this module would use nothing that C<Test2> does not, but that
seems to require a fair amount of wheel-reinventing. What this module
does try to do is to load the extra modules only if it really needs
them. Specifically:

L<Getopt::Long|Getopt::Long> is loaded only if arguments are passed to
the C<use Test::Tools::LoadModule> statement.

L<File::Find|File::Find> and L<File::Spec|File::Spec> are loaded only if
L<all_modules_tried_ok()|/all_modules_tried_ok> is called.

Because L<Carp|Carp> and L<Exporter|Exporter> are used by
L<Test2::API|Test2::API> (at least as of version C<1.302181>), this
module makes no attempt to avoid their use.

=head1 SUBROUTINES

All subroutines documented below are exportable, either by name or using
one of the following tags:

=over

=item :all exports all public exports;

=item :default exports the default exports (i.e. :test2);

=item :more exports require_ok() and use_ok();

=item :test2 exports load_module_*(), and is the default.

=back

=head2 load_module_ok

 load_module_ok $module, $ver, $import, $name, @diag;

Prototype: C<(@)>.

This subroutine tests whether the specified module (B<not> file) can be
loaded. All arguments are optional. The arguments are:

=over

=item $module - the module name

This is the name of the module to be loaded. If unspecified or specified
as C<undef>, it defaults to the caller's C<CLASS> if that exists;
otherwise an exception is thrown.

=item $ver - the desired version number, or undef

If defined, the test fails if the installed module is not at least this
version. An exception is thrown if the version number is invalid.

If C<undef>, no version check is done.

=item $import - the import list as an array ref, or undef

This argument specifies the import list. C<undef> means to import the
default symbols, C<[]> means not to import anything, and a non-empty
array reference means to import the specified symbols.

=item $name - the test name, or undef

If C<undef>, the name defaults to the code used to load the module.
B<Note> that this code, and therefore the default name, may change
without notice.

=item @diag - the desired diagnostics

Diagnostics are only issued on failure.

=back

Argument validation failures are signalled by C<croak()>.

The module is loaded, and version checks and imports are done if
specified. The test passes if all these succeed, and fails otherwise.

B<Note> that any imports from the loaded module take place when this
subroutine is called, which is normally at run time. Imported
subroutines will be callable, provided you do not make use of prototypes
or attributes.

If you want anything imported from the loaded module to be available for
subsequent compilation (e.g. variables, subroutine prototypes) you will
need to put the call to this subroutine in a C<BEGIN { }> block:

 BEGIN { load_module_ok 'My::Module'; }

By default, C<$@> is appended to the diagnostics issued in the event of
a load failure. If you want to omit this, or embed the value in your own
text, see L<CONFIGURATION|/CONFIGURATION>, below.

As a side effect, the names of all modules tried with this test are
recorded, along with test results (pass/fail) for the use of
L<all_modules_tried_ok()|/all_modules_tried_ok>.

=head2 load_module_or_skip

 load_module_or_skip $module, $ver, $import, $name, $num;

Prototype: C<(@)>.

This subroutine performs the same loading actions as
L<load_module_ok()|/load_module_ok>, but no tests are performed.
Instead, the specified number of tests is skipped if the load fails.

The arguments are the same as L<load_module_ok()|/load_module_ok>,
except that the fifth argument (C<$num> in the example) is the number of
tests to skip, defaulting to C<1>.

The C<$name> argument gives the skip message, and defaults to
C<"Unable to ..."> where the ellipsis is the code used to load the
module.

=head2 load_module_or_skip_all

 load_module_or_skip_all $module, $ver, $import, $name;

Prototype: C<(@)>.

This subroutine performs the same loading actions as
L<load_module_ok()|/load_module_ok>, but no tests are performed.
Instead, all tests are skipped if any part of the load fails.

The arguments are the same as L<load_module_ok()|/load_module_ok>,
except for the fact that diagnostics are not specified.

The C<$name> argument gives the skip message, and defaults to
C<"Unable to ..."> where the ellipsis is the code used to load the
module.

This subroutine can be called either at the top level or in a subtest,
but either way it B<must> be called before any actual tests in the file
or subtest.

=head2 all_modules_tried_ok

 all_modules_tried_ok

Added in version C<0.002>.

Prototype: C<(@)>.

This test traverses any directories specified as arguments looking for
Perl modules (defined as files whose names end in F<.pm>). A failing
test is generated for any such file not previously tested using
L<load_module_ok()|/load_module_ok>.

If no directory is specified, the default is
C< ( '/blib/lib', '/blib/arch' ) >.

B<NOTE> that no attempt is made to parse the file and determine its
module name. The module is assumed from the part of the file path below
the specified directory. So an explicit specification of F<lib/> will
work (if that is where the modules are stored) but an explicit F<blib/>
will not.

=head2 clear_modules_tried

 clear_modules_tried

Added in version C<0.002>.

Prototype: C<()>.

This is not a test. It clears the record of modules tried by
L<load_module_ok()|/load_module_ok>.

=head2 require_ok

 require_ok $module;

Prototype: C<($)>.

This subroutine is more or less the same as the L<Test::More|Test::More>
subroutine of the same name. The argument is the name of the module to
load.

=head2 use_ok

 use_ok $module, @imports;
 use_ok $module, $version, @imports;

Prototype: C<($;@)>.

This subroutine is more or less the same as the L<Test::More|Test::More>
subroutine of the same name. The arguments are the name of the module to
load, and optional version (recognized by the equivalent of
C<version::is_lax()>, and optional imports.

=head1 CONFIGURATION

The action of the C<load_module_*()> subroutines is configurable using
POSIX-style options. If used as subroutine arguments they apply only to
that subroutine call. If used as arguments to C<use()>, they apply to
everything in the scope of the C<use()>, though this requires Perl 5.10
or above, and you must specify any desired imports.

These options are parsed by L<Getopt::Long|Getopt::Long> (q.v.) in POSIX
mode, so they must appear before non-option arguments. They are all
documented double-dashed. A single leading dash is tolerated except in
the form C<--option=argument>, where the double dash is required.

The following configuration options are available.

=head2 --require

If asserted, this possibly-badly-named Boolean option specifies that an
C<undef> or unspecified import list imports nothing, while C<[]> does
the default import.

The default is C<-norequire>, which is the other way around. This is the
way C<use()> works, which is what inspired the name of the option.

=head2 --req

This is just a shorter synonym for L<--require|/--require>.

=head2 --load_error

 --load_error 'Error: %s'

This option specifies the formatting of the load error for those
subroutines that append it to the diagnostics. The value is interpreted
as follows:

=over

=item A string containing C<'%s'>

or anything that looks like an C<sprintf()> string substitution is
interpreted verbatim as the L<sprintf> format to use to format the
error;

=item Any other true value (e.g. C<1>)

specifies the default, C<'%s'>;

=item Any false value (e.g. C<0>)

specifies that C<$@> should not be appended to the diagnostics at all.

=back

For example, if you want your diagnostics to look like the
L<Test::More|Test::More> C<require_ok()> diagnostics, you can do
something like this (at least under Perl 5.10 or above):

 {	# Begin scope
   use Test2::Tools::LoadModule -load_error => 'Error:  %s';
   load_module_ok $my_module, undef, undef,
     "require $my_module;", "Tried to require '$my_module'.";
   ...
 }
 # -load_error reverts to whatever it was before.

If you want your code to work under Perl 5.8, you can equivalently do

 load_module_ok -load_error => 'Error:  %s',
     $my_module, undef, undef, "require $my_module;"
     "Tried to require '$my_module'.";

B<Note> that, while you can specify options on your initial load,
if you do so you must specify your desired imports explicitly, as (e.g.)

 use Test2::Tools::LoadModule
    -load_error => 'Bummer! %s', ':default';

=head1 SEE ALSO

L<Test::More|Test::More>

L<Test2::V0|Test2::V0>

L<Test2::Require|Test2::Require>

L<Test2::Manual::Testing::Migrating|Test2::Manual::Testing::Migrating>

L<Test2::Plugin::BailOnFail|Test2::Plugin::BailOnFail>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test2-Tools-LoadModule>,
L<https://github.com/trwyant/perl-Test2-Tools-LoadModule/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
