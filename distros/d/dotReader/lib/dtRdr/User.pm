package dtRdr::User;
$VERSION = eval{require version}?version::qv($_):$_ for(0.1.1);

use warnings;
use strict;
use Carp;

use dtRdr;
use dtRdr::Config;
use dtRdr::Library;

use File::Basename ();
use File::Spec;

use Class::Accessor::Classy;
ro 'config';
ro 'username';
ro 'name';
ls libraries => \ (my $set_libraries), add => \ (my $add_libraries);
no  Class::Accessor::Classy;

=head1 NAME

dtRdr::User.pm - user class

=cut

# TODO most of the user and config stuff is just hobbling along at the
# moment and could really use a rethink.

=head1 Constructor

=head2 new

  $user = dtRdr::User->new(username => $username);

=cut

sub new {
  my $class = shift;
  ref($class) and croak("not an object method");
  (@_%2) and croak("odd number of elements in argument list");
  my (%attr) = @_;

  unless(defined($attr{username})) {
    $attr{username} = getlogin || getpwuid($<) || "Kilroy";
  }

  my $self = {
    name      => 'me',
    %attr,
    #info      => {}, # XXX why not just self?
  };
  bless($self, $class);

  return($self);
} # end subroutine new definition
########################################################################

=head1 Methods

=head2 init_config

  $user->init_config($filename);

=cut

sub init_config {
  my $self = shift;
  my ($filename) = @_;

  $self->{config} and croak("can only init once");

  die "config requires filename" unless(defined($filename));

  # dtRdr::Plugins->init($config); # ?

  my $config = $self->{config} = dtRdr::Config->new($filename);
  my $basedir = File::Basename::dirname($filename);

  my @libraries = $config->libraries;

  # XXX should definitely go elsewhere
  $self->$set_libraries();
  foreach my $info (@libraries) {
    # lookup the type
    my $library_class = dtRdr::Library->class_by_type($info->type);
    my $library = $library_class->new();

    # let that be absolute or relative to dirname
    my $uri = $info->uri;
    unless(File::Spec->file_name_is_absolute($uri)) {
      $uri = File::Spec->catfile($basedir, $uri);
    }

    $library->load_uri($uri);

    $self->$add_libraries($library);
  }
  1;
} # end subroutine init_config definition
########################################################################

=head2 add_library

Add a library and store it.

  $self->add_library($lib);

=cut

sub add_library {
  my $self = shift;
  my ($lib) = @_;

  my ($libname, $libtype) = ($lib->location, $lib->handler);
  do('./util/BREAK_THIS') or die;
  $self->config->insert_library($libname, $libtype);
  $self->$add_libraries($lib);
} # end subroutine add_library definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

Dan Sugalski <dan@sidhe.org>

=head1 COPYRIGHT

Copyright (C) 2006-2007 by Eric L. Wilhelm, Dan Sugalski, and OSoft, All
Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

# vim:ts=2:sw=2:et:sta
1;
