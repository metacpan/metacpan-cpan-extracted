package UR::Context::Process;

=pod

=head1 NAME

UR::Context::Process - Implements a generic interface to the current application.

=head1 SYNOPSIS

  $name = UR::Context::Process->base_name;

  $name = UR::Context::Process->prog_name;
  UR::Context::Process->prog_name($name);

  $name = UR::Context::Process->pkg_name;
  UR::Context::Process->pkg_name($name);

  $name = UR::Context::Process->title;
  UR::Context::Process->title($name);

  $version = UR::Context::Process->version;
  UR::Context::Process->version($version);

  $author = UR::Context::Process->author;
  UR::Context::Process->author($author);

  $author_email = UR::Context::Process->author_email;
  UR::Context::Process->author_email($author_email);

  $support_email = UR::Context::Process->support_email;
  UR::Context::Process->support_email($support_email);

  $login = UR::Context::Process->real_user_name;

=head1 DESCRIPTION

This module provides methods to set and retrieve various names
associated with the program and the program version number.

=cut

package UR::Context::Process;

our $VERSION = "0.47"; # UR $VERSION;

require 5.006_000;

use strict;
use warnings;
use Sys::Hostname;
use File::Basename;
require UR;

UR::Object::Type->define(
    class_name => 'UR::Context::Process',
    is => ['UR::Context'],
    is_transactional => 0,
    has => [
        host_name       => { is => 'Text' },
        process_id      => { is => 'Integer' },
        access_level    => { is => 'Text', default_value => '??' },
        debug_level     => { is => 'Integer', default_value => 0 },
    ],
    doc => 'A context for a given process.',
);

=pod

=head1 METHODS

These methods provide the accessor and set methods for various names
associated with an application.

=over

=item get_current

 $ctx = UR::Context::Process->get_current();

This is the context which represents the current process.

Also available as UR::Context->get_process();

=back

=cut


sub get_current {
    return $UR::Context::process;
}

=pod 

=over

=item has_changes()

 $bool = UR::Context::Process->has_changes();

Returns true if the current process has changes which might be committed back to
the underlying context.

=back

=cut

sub has_changes {
    my $self = shift;
    my @ns = $self->all_objects_loaded('UR::Namespace');
    for my $ns (@ns) {
        my @ds = $ns->get_data_sources();
        for my $ds (@ds) {
            return 1 if $ds->has_changes_in_base_context();
        }
    }
    return; 
}

=pod 

=over

=item _create_for_current_process

 $ctx = UR::Context::Process->_create_for_current_process(@PARAMS)

This is only used internally by UR.
It materializes a new object to represent a real process somewhere.

TODO: Remove the exception from create(), and allow other processes to be
created explicitly w/ the appropriate characteristics.

=back

=cut

sub _create_for_current_process {
    my $class = shift;

    die "Process object for the current process already exists!" if $UR::Context::process;

    #my $rule = $class->define_boolexpr(@_);        
    my $rule = UR::BoolExpr->resolve($class, @_);
    
    my $host_name = Sys::Hostname::hostname();
    
    my $id = $host_name . "\t" . $$;
    
    my $self = $class->SUPER::create(id => $id, process_id => $$, host_name => $host_name, $rule->params_list);
    return $self;
}

sub create {
    # Note that the above method does creation by going straight to SUPER::create()
    # for the current process only.
    die "Creation of parallel/child processes not yet supported!"
}

# TODO: the remaining methods are from the old App::Name module.
# They currently only work for the current process, and operate as class methods.
# They should be re-written to work as class methods on $this_process, or 
# instance methods on any process.  For now, only the class methods are needed.

=pod

=over

=item base_name

  $name = UR::Context::Process->base_name;

This is C<basename($0, '.pl'))>.

=back

=cut

our $base_name = basename($0, '.pl');
sub base_name { return $base_name }

=pod

=over

=item prog_name

  $name = UR::Context::Process->prog_name;
  UR::Context::Process->prog_name($name);

This method is used to access and set the name of the program name.  

This name is used in the output of the C<version> and C<usage>
subroutines (see L<"version"> and L<"usage">).  If given an argument,
this method sets the program name and returns the new name or C<undef>
if unsuccessful.

It defaults to C<basename> if unspecified.

=back

=cut

our $prog_name;
sub prog_name
{
    my $class = shift;
    my ($name) = @_;

    if (@_)
    {
    $prog_name = $name;
    }
    return $prog_name || $class->base_name;
}

=pod

=over

=item pkg_name

  $name = UR::Context::Process->pkg_name;
  UR::Context::Process->pkg_name($name);

This method is used to access and set the GNU-standard package name
for the package to which this program belongs.  This is does B<NOT>
refer-to a Perl package.  It allows a set of specific programs to be
grouped together under a common name, which is used in standard
message output, and is used in the output of the C<version> subroutine
(see L<"version"> output.

If given an argument, this method sets the package name and returns
the the new name or C<undef> if unsuccessful.  Without an argument,
the current package name is returned.

It defaults to C<prog_name> when unspecified, which in turn
defaults to C<base_name>, which in turn defaults to
C<basename($0)>.

=back

=cut

# NOTE: this should not use App::Debug because App::Debug::level calls it
our $pkg_name;
sub pkg_name
{
    my $class = shift;
    my ($name) = @_;

    if (@_)
    {
    $pkg_name = $name;
    }
    return $pkg_name || $class->prog_name;
}

=pod

=over

=item title

  $name = UR::Context::Process->title;
  UR::Context::Process->title($name);

This gets and sets the "friendly name" for an application.  It is
often mixed-case, with spaces, and is used in autogenerated
documentation, and sometimes as a header in generic GUI components.
Without an argument, it returns the current title.  If an argument is
specified, this method sets the application title and returns the new
title or C<undef> if unsuccessful.

It defaults to C<pkg_name> when otherwise unspecified, which
in turn defaults to C<prog_name> when unspecified, which in
turn defaults to C<base_name> when unspecified, which
defaults to C<basename($0)> when unspecified.

=back

=cut

our $title;
sub title
{
    my $class = shift;
    my ($name) = @_;

    if (@_)
    {
    $title = $name;
    }
    return $title || $class->pkg_name;
}

=pod

=over

=item version

  $version = UR::Context::Process->version;
  UR::Context::Process->version($version);

This method is used to access and set the package version.  This
version is used in the output of the C<print_version> method (see
L<App::Getopt/"print_version">).  If given an argument, this method
sets the package version and returns the version or C<undef> if
unsuccessful.  Without an argument, the current package version is
returned.

This message defaults to C<$main::VERSION> if not set.  Note that
C<$main::VERSION> may be C<undef>.

=back

=cut

# set/get version
# use $main::VERSION for compatibility with non-App animals.
sub version
{
    my $class = shift;
    my ($version) = @_;

    if (@_)
    {
    $main::VERSION = $version;
    }
    return $main::VERSION;
}

=pod

=over

=item author

  $author = UR::Context::Process->author;
  UR::Context::Process->author($author);

This method is used to access and set the package author.  If given an
argument, this method sets the package author and returns the author
or C<undef> if unsuccessful.  Without an argument, the current author
is returned.

=back

=cut

# set/get author
our $author;
sub author
{
    my $class = shift;
    my ($name) = @_;

    if (@_)
    {
    $author = $name;
    }
    return $author;
}

=pod

=over

=item author_email

  $author_email = UR::Context::Process->author_email;
  UR::Context::Process->author_email($author_email);

This method is used to access and set the package author's email
address.  This information is used in the output of the C<usage>
method (see L<App::Getopt/"usage">).  If given an argument, this
method sets the package author's email address and returns email
address or C<undef> if unsuccessful.  Without an argument, the current
email address is returned.

=back

=cut

# set/return author email address
our $author_email;
sub author_email
{
    my $class = shift;
    my ($email) = @_;

    if (@_)
    {
    $author_email = $email;
    }
    return $author_email;
}

=pod

=over

=item support_email

  $support_email = UR::Context::Process->support_email;
  UR::Context::Process->support_email($support_email);

This method is used to access and set the email address to which the
user should go for support.  This information is used in the output of
the C<usage> method (see L<App::Getopt/"usage">).  If given an
argument, this method sets the support email address and returns that
email address or C<undef> if unsuccessful.  Without an argument, the
current email address is returned.

=back

=cut

# set/return author email address
our $support_email;
sub support_email
{
    my $class = shift;
    my ($email) = @_;

    if (@_)
    {
    $support_email = $email;
    }
    return $support_email;
}

=pod

=over

=item real_user_name

  $login = UR::Context::Process->real_user_name;

This method is used to get the login name of the effective user id of
the running script.

=back

=cut

# return the name of the user running the program
our $real_user_name;
sub real_user_name
{
    my $class = shift;

    if (!$real_user_name)
    {
        if ($^O eq 'MSWin32' || $^O eq 'cygwin')
        {
            $real_user_name = 'WindowsUser';
        }
        else
        {
            $real_user_name = getpwuid($<) || getlogin || 'unknown';
        }
    }
    return $real_user_name;
}

=pod 

=over

=item fork
    $pid = UR::Context::Process->fork;

Safe fork() wrapper.

Handles properly disconnecting database handles if necessary so that data sources in children
are still valid.  Also ensures that the active UR::Context::process has the child's PID 
recorded within.

=back

=cut

sub fork 
{
    my $class = shift;

    my @ds = UR::DataSource->is_loaded();

    for (grep {defined $_} @ds) {
        $_->prepare_for_fork;
    }

    my $pid = fork();

    unless(defined $pid) {
        Carp::confess('Failed to fork process. ' . $!);
    }

    if (!$pid) {
        $UR::Context::process = undef;
        $UR::Context::process = $class->_create_for_current_process;
        for (grep {defined $_} @ds) {
            $_->do_after_fork_in_child;
        }
    }

    for (grep {defined $_} @ds) {
        $_->finish_up_after_fork;
    }

    return $pid;
}

=pod

=over

=item effective_user_name

  $login = UR::Context::Process->effective_user_name;

This method is used to get the login name of the effective user id of
the running script.

=back

=cut

# return the name of the user running the program
our $effective_user_name;
sub effective_user_name
{
    my $class = shift;

    if (!$effective_user_name)
    {
    $effective_user_name = getpwuid($>) || 'unknown';
    }
    return $effective_user_name;
}

=pod

=over

=item original_program_path

 $path = UR::Context::Process->original_program_path;

This method is used to (try to) get the original program path of the running script.
This will not change even if the current working directory is changed.
(In truth it will find the path at the time UR::Context::Process was used.  So, a chdir
before that happens will cause incorrect results; in that case, undef will be returned.

=back

=cut

our ($original_program_name, $original_program_dir);
eval '
use FindBin;
$original_program_dir=$FindBin::Bin;
$original_program_name=__PACKAGE__->base_name;
';

sub original_program_path {
    my $class=shift;

    my $original_program_dir=$class->original_program_dir;
    return unless($original_program_dir);

    my $original_program_name=$class->original_program_name;
    return unless($original_program_name);

    return $original_program_dir.q(/).$original_program_name;
}

sub original_program_dir {
    return unless($original_program_dir);
    return $original_program_dir;
}

sub original_program_name {
    return unless($original_program_name);
    return $original_program_name;
}


1;

__END__

=pod

=head1 SEE ALSO

L<UR::Context>

=cut


1;
