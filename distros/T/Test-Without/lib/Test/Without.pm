###############################################################################
#
# This file copyright (c) 2009 by Randy J. Ray, all rights reserved
#
# Copying and distribution are permitted under the terms of the Artistic
# License 2.0 (http://www.opensource.org/licenses/artistic-license-2.0.php) or
# the GNU LGPL (http://www.opensource.org/licenses/lgpl-2.1.php).
#
###############################################################################
#
#   Description:    Run tests in a localized scope
#
#   Functions:      run
#                   without
#                   with
#                   modules
#                   module
#                   libs
#                   lib
#                   params
#                   param
#
#   Libraries:      Exporter
#                   Scalar::Util
#
#   Global Consts:  $VERSION
#
###############################################################################

package Test::Without;

use 5.008;
use strict;
use warnings;
use vars qw($VERSION %CURRENT_LIST @EXPORT @EXPORT_OK %EXPORT_TAGS);
use subs qw(run without with modules module libs lib params param);
use base 'Exporter';
require lib;    # This is used to manually invoke lib->import and lib->unimport

use Scalar::Util 'blessed';

$VERSION     = '0.100';
$VERSION     = eval $VERSION; ## no critic
@EXPORT      = qw(run without with modules module libs lib params param);
@EXPORT_OK   = @EXPORT;
%EXPORT_TAGS = (all => [@EXPORT]);

## no critic (ProhibitSubroutinePrototypes)

# These are all the exact same code except for the leading label. Also
# manage the plural/singular sugary formations:
sub module  (@) { (-modules => @_) }
sub modules (@) { (-modules => @_) }
sub lib     (@) { (-libs    => @_) }
sub libs    (@) { (-libs    => @_) }
sub param   (@) { (-params  => @_) }
sub params  (@) { (-params  => @_) }

###############################################################################
#
#   Sub Name:       without
#
#   Description:    Mark all the arguments to this as being elements that
#                   should be masked from view when the enclosing "run"
#                   executes its BLOCK.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   @list     in      list      Items to be marked
#
#   Returns:        list
#
###############################################################################
sub without (@)
{
    (-without => @_);
}

###############################################################################
#
#   Sub Name:       with
#
#   Description:    As above, but marks any elements as being things that
#                   must be located/present before the block can be run.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   @list     in      list      Items to be marked
#
#   Returns:        list
#
###############################################################################
sub with (@)
{
    (-with => @_);
}

###############################################################################
#
#   Sub Name:       run
#
#   Description:    Execute the given block after localizing @INC and %INC so
#                   that any changes made are auto-rolled-back upon exit.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $block    in      coderef   The block of code to run
#                   @params   in      list      The list of params/directives
#                                                 to process and apply to @INC
#                                                 before invoking $block.
#
#   Returns:        Whatever $block returns
#
###############################################################################
sub run (&@)
{
    my ($block, @params) = @_;

    local @INC = @INC;
    local %INC = %INC;

    my ($which, $key, $index);
    my %params = (
        with    => {libs => [], modules => []},
        without => {libs => [], modules => []},
        # Make sure $params{params} exists to avoid undef-tests on last line
        params => [],
    );
    # If they don't specify a "key" (by using one of the syntactic sugar
    # faux-keywords), default to the "without modules" list since that will
    # probably be 90% or more of usage.
    $which = 'without';
    $key   = 'modules';

    while (my $param = shift(@params))
    {
        if (substr($param, 0, 1) eq '-')
        {
            # Switching to a different key or selector
            if (substr($param, 1, 4) eq 'with')
            {
                $which = substr($param, 1);
            }
            else
            {
                $key = substr($param, 1);
            }
        }
        else
        {
            $index =
              ($key eq 'params') ? $params{param} : $params{$which}->{$key};
            push(@{$index}, $param);
        }
    }

    # Any libraries the user says they need must me loadable. If any of them
    # cannot load, an exception must be thrown. The caller is responsible for
    # handling it.
    if (@{$params{with}->{libs}} + @{$params{with}->{modules}})
    {
        # Check libs first, as they're easier
        lib->import(@{$params{with}->{libs}})
          if (@{$params{with}->{libs}});

        for my $required (@{$params{with}->{modules}})
        {
            my ($module, $params) = split('=', $required, 2);
            my $evalstr = "use $module";
            if ($params)
            {
                @params = split(q{,} => $params);
                $evalstr .= " qw(@params)";
            }

            # Try it. Don't forget that we've already localized @INC and %INC
            eval "$evalstr;"; ## no critic
            die "Error loading $module: $@" if $@;
        }
    }

    if ($params{without})
    {
        # Remove any paths in @INC that (sub-string) match paths in the list
        # the user provided
        lib->unimport(@{$params{without}->{libs}})
          if (@{$params{without}->{libs}});

        # If there are modules requested for hiding, create a code block that
        # goes into the head of @INC and masks them.
        unshift(@INC, _create_masking_coderef(@{$params{without}->{modules}}))
          if (@{$params{without}->{modules}});
    }

    $block->(@{$params{params}});
}

###############################################################################
#
#   Sub Name:       _create_masking_coderef
#
#   Description:    Create a coderef using the list of modules that are to be
#                   hidden from the system during the scope of the enclosing
#                   "run". Bless the coderef so that we can easily find it in
#                   @INC if we need to.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   @list     in      list      List of modules to hide from
#                                                 the user.
#
#   Returns:        Success:    coderef
#                   Failure:    dies
#
###############################################################################
sub _create_masking_coderef (@)
{
    my @list    = @_;
    my $package = __PACKAGE__ . '::coderef';

    my %mask_map = map { (my $key = $_) =~ s{::}{/}g; "$key.pm" => 1 } @list;
    my @local_inc = grep(!(blessed $_ && $_->isa($package)), @INC);

    bless sub {
        my ($self, $module) = @_;

        die "Can't locate $module in \@INC (\@INC contains @local_inc)."
          if ($mask_map{$module});

        undef;
    }, $package;
}

1;

=head1 NAME

Test::Without - Run code while hiding library paths or specific modules

=head1 SYNOPSIS

    use Test::Without;

    run {
        eval "require RPC::XML::Client";
        $client = RPC::XML::Client->new();

        ok(! $client->compress(), "Client has no compression support");
    } without 'Compress::Zlib';

    # Run a block with parameters
    run {
        my %args = @_;
        eval "require RPC::XML::Server";
        $server = RPC::XML::Server->new(@_);

        is($server->port, $args{port}, "Port set correctly");
        is($server->path, $args{path}, "Path set correctly");
        # Etc.
    } without 'Compress::Zlib', 'Net::Server',
      params port => 9000, path => '/RPC';

=head1 DESCRIPTION

The B<Test::Without> module makes it easy for test scripts to exclude specific
modules and/or directories from the Perl search-path during the execution of
blocks of code. I wrote this after needing to write a fairly ugly hack for a
different CPAN module, in order to test code that would try to load
B<Compress::Zlib>, but needed to test the logic paths that only execute when
compression is not available. This module is not for testing whether code
loads and compiles correctly; see the C<use_ok> function of B<Test::More> for
that.

The module works by creating a lexical scope in which both C<@INC> and C<%INC>
are localized, and executing the given block within that scope. The modules
(and possibly direcories) to be hidden are specified at this time. Directories
that are given are immediately removed from C<@INC>. Modules are handled by
means of a subroutine inserted at the head of C<@INC>.

Conversely, the syntax can be used to require the present of specific modules,
throwing an exception via C<die> if any request resource is not available, or
temporarily add extra paths to C<@INC>. In such a case, none of the code in the
provided block will have been run prior to the reporting of the missing
resources.

A caller can also provide parameters to be passed to the code block when it
is called. This is superfluous for inline-defined blocks, but in cases where
the block argument is a code-reference scalar that is being reused, this can
be useful.

=head1 SYNTAX

The module defines the following functions:

=over 4

=item run BLOCK LIST

Run the given code in BLOCK, with the context defined by the elements of LIST.
The items in list should be built up using the other functions defined below.
Exceptions are not inherently caught, so if you expect the that code may
C<die> (or otherwise emulate exceptions) you may with to use C<eval>.

If C<params> is used (see below) in constructing the context, these values are
passed to the code-block in C<@_>, as though it were a function call.

=item without LIST

Specify a set of resources that should be hidden within the context the
associated block is invoked. The contents of LIST should be built up using
C<modules> (and/or C<libs>), below. Because it is expected that the majority of
usage will be to mask or require modules, a bare list is assumed to be
modules. Thus, the following will work, correctly masking B<Net::Server> from
being loadable:

    run { ... } without 'Net::Server';

=item with LIST

Specify resources that must be present before the block can be invoked. The
given LIST should be built up using a combination of C<modules> and C<libs>, as
needed. Unlike using C<without>, above, this pre-confirms that modules are
available by attempting load them. Directories specified via C<libs> are added
the same way they would be with the B<libs> pragma, with the added step that
a check is first done to confirm the directory actually exists. If it does not
exist, C<die> is called to signal this.

Modules specified in a C<with> list may provide import-style arguments in a
way similar to Perl's B<-M> command-line argument. See the section for
C<modules>, below.

As is the case for C<without>, above, a bare list is assumed to be modules.
The following works as a counter to the previous example:

    run { ... } with 'Net::Server';

=item modules LIST

Build a list of modules for use by C<without> or C<with>. Does no processing of
LIST itself.

If the modules being specified are for use with the C<with> function, then any
elements of list may contain parameters using the same specification syntax
used for the B<-M> command-line switch of Perl itself:

    run {
        # Create an image, then test that it was correct
        our $image = ...;
        ($width, $height) = imgsize($image);
        # Then test to see if we got what was expected
    } with 'Image::Size=imgsize';
    # Requires that Image::Size is present, and imports 'imgsize'
    # from it.

For syntactic-sugar purposes, you can use the singular C<module> as a
synonym for this function.

=item libs LIST

Build a list of directories that should be either excluded or required in the
Perl search path for the context being constructed. The way these paths are
treated depends on whether the list is being used for inclusion or exclusion:

=over 8

=item *

When the list of directories is given to the C<without> function, each element
is I<removed from> C<@INC> by calling the B<unimport> method from the B<lib>
module. This will also remove architecture-specific sub-directories related
to the directory being removed, just as if you invoked C<no lib $dir>.

=item *

When the list is given to the C<with> function, each element is I<added to>
C<@INC>, along with any related architecture-specific sub-directories, just
as if you had invoked C<use lib $dir>.

=back

For syntactic-sugar purposes, you can use the singular C<lib> as a
synonym for this function.

=item params LIST

Build a list of parameters that are passed in as the arguments-list (via C<@_>)
to the code-block when it is invoked. This can be useful for cases where the
code argument is a scalar containing a code-reference that is intended to be
reused several times over.

For syntactic-sugar purposes, you can use the singular C<param> as a
synonym for this function.

=back

See the following section for example usage of all the routines defined here.

=head1 EXAMPLES

=over 4

=item Test that a class acts correctly in absence of Compress::Zlib:

    run {
        require RPC::XML::Client;
        $client = RPC::XML::Client->new('http://test.com');
        ok(! $client->can_compress(),
           '$client has no compression support');
    } without 'Compress::Zlib';

=item Semi-emulate the "blib" pragma:

    run {
        eval "require Some::Lib;";
        ok(Some::Lib->can('some_method'), 'Some::Lib loaded OK');
    } with libs 'lib', 'blib', '../lib', '../blib';

=item Load code from a local lib while hiding a module:

    run {
        ...
    } with lib 'local', without module 'HTTP::Daemon';

=item Run the same code several times, with varying parameters:

    $code = sub { ... };
    $db_credentials = read_all_database_credentials();

    for my $db_type (keys %$db_credentials)
    {
        my ($user, $pass) = @{$db_credentials->{$db_type}};

        # You could say "with params", but it's redundant for params
        run $code without 'DBD::DB2', params $db_type, $user, $pass;
    }

=back

=head1 DIAGNOSTICS

Any problems are signalled with B<die>. The user must catch these with either
the C<__DIE__> pseudo-signal handler or by B<eval> (or some other syntactic
construct).

The code-block that gets inserted into B<@INC> uses B<die> as well, if one of
the blocked modules is requested for loading. If your tests are themselves
likely to try loading any of these (as opposed to using this framework to hide
modules from other code you are loading), you will want to use B<eval> or the
signal handler.

=head1 CAVEATS

If a module loads that also alters B<@INC>, it could interfere with this module
catching and blocking the requests modules or libraries.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-without at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Without>. I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Without>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Without>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Without>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Without>

=item * Source code on GitHub

L<http://github.com/rjray/test-without/tree/master>

=back

=head1 COPYRIGHT & LICENSE

This file and the code within are copyright (c) 2009 by Randy J. Ray.

Copying and distribution are permitted under the terms of the Artistic
License 2.0 (L<http://www.opensource.org/licenses/artistic-license-2.0.php>) or
the GNU LGPL 2.1 (L<http://www.opensource.org/licenses/lgpl-2.1.php>).

=head1 CREDITS

Thanks to Andy Wardley C<< abw @ cpan.org >> for providing the idea for
inverting the control-point of the logic and making the scoping issues with
B<@INC> and B<%INC> work.

=head1 SEE ALSO

L<Module::Mask>, L<Test::Without::Module>, L<Test::More>

=head1 AUTHOR

Randy J. Ray <rjray@blackperl.com>

=cut
