package dtRdr::GUI::Wx::Plugins;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


use Module::Finder;

use Class::Accessor::Classy;
with 'new';
ro 'plugins';
no  Class::Accessor::Classy;

=head1 NAME

dtRdr::GUI::Wx::Plugins - plugins for the wx gui

=head1 SYNOPSIS

This is quite a bit different than the other plugins.

=cut

=head2 init

Find, plus construct and/or init plugins and pass each one the frame
object.

  $plugins = $plugins->init($frame);

=cut

sub init {
  my $self = shift;
  my ($frame) = @_;

  # TODO should we use class data or be a singleton or ___ ?
  # Our Frame.pm almost definitely doesn't cleanly support multiple
  # instances right now, but it shouldn't be completely out of the
  # question.

  $self->{plugins} and die "didn't plan for that";
  my $plugins = $self->{plugins} = {};
  foreach my $info ($self->_find_plugins) {
    my %details;
    my $plugin; # maybe an instance
    my $pclass = $info->module_name;
    # expand short name
    $pclass =~ s/^dotplug-Wx/dtRdr::GUI::Wx::Plugins/;

    # try to load it, which might fail or get denied for any number of reasons
    eval { # BIG eval
      if(exists($plugins->{$pclass})) {
        die "$pclass appears to have already been instantiated";
      }

      # print STDERR join("\n", @INC, '');
      # PLUGIN RULES:
      #    you get to be at the *back* of @INC
      #    and even that is *only* at compile-time
      local @INC = (@INC, dtRdr->plugin_dirs);
      require $info->filename;

      %details = $self->query_plugin($pclass);

      # let it be class or instance based
      # TODO a multi-frame situation would imply that class-based
      # plugins have to install some sort of hook rather than add a
      # button, etc.  The frame would have a plugin instance, so I guess
      # that just means class-method init() has to be able to be called
      # once per frame.
      $plugin = $pclass;
      if($pclass->can('new')) {
        $plugin = $pclass->new(); # XXX args?
      }
      if($plugin->can('init')) {
        $plugin->init($frame);
      }
      else {
        warn "'$plugin' cannot init";
      }
    }; # end BIG eval

    if($@) {
      my $message = "problem loading plugin '$pclass':\n\n  $@";
      $frame->error($message) or die $message;
      # TODO kill the package(s)
      next;
    }

    $plugins->{$pclass} = {
      %details,
      class    => $pclass,
      instance => $plugin,
    };
  }
  return($self);
} # end subroutine init definition
########################################################################

=head2 query_plugin

Plugins must answer to NAME and DESCRIPTION methods.

  my %details = $self->query_plugin($pclass);

=cut

sub query_plugin {
  my $self = shift;
  my ($plugin) = @_;

  my @fields = qw(name description);
  my %details;
  foreach my $field (@fields) {
    my $method = uc($field);
    die "'$plugin' does not provide required method '$method'"
      unless($plugin->can($method));
    my $answer = $plugin->$method;
    die "'$plugin' does not provide a valid response to method '$method'"
      unless(defined($answer));
    $details{$field} = $answer;
  }
  return(%details);
} # end subroutine query_plugin definition
########################################################################

=head2 _find_plugins

  my @plugins = dtRdr::GUI::Wx::Plugins->_find_plugins;

=cut

{
my @finders;
my @found;
sub _find_plugins {
  my $package = shift;

  @found and return(@found);
  @finders =  (
    Module::Finder->new(
      paths => {
        'dotplug-Wx' => '+',
        'dtRdr::GUI::Wx::Plugins' => '+',
      },
      dirs => [dtRdr->plugin_dirs],
    ),
    Module::Finder->new(
      paths => {
        'dtRdr::GUI::Wx::Plugins' => '+',
      },
      dirs => [@INC],
    ),
  ) unless(@finders);

  foreach my $finder (@finders) {
    my %infos = $finder->module_infos;
    if(0) {
      local $SIG{__WARN__};
      warn "found ", join("|", keys(%infos)), ' in ',
        join(", ", @{$finder->{dirs}});
    }
    push(@found, values(%infos));
  }
  return(@found);
} # end subroutine _find_plugins definition
########################################################################
}




=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006-2007 Eric L. Wilhelm and OSoft, All Rights Reserved.

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

# vi:ts=2:sw=2:et:sta
1;
