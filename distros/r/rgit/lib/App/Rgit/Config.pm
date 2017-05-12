package App::Rgit::Config;

use strict;
use warnings;

use Carp       (); # confess
use Cwd        (); # cwd
use File::Spec (); # canonpath, catfile, path

use App::Rgit::Repository;
use App::Rgit::Utils qw/:levels/; # :levels, abs_path

use constant IS_WIN32 => $^O eq 'MSWin32';

=head1 NAME

App::Rgit::Config - Base class for App::Rgit configurations.

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 DESCRIPTION

Base class for L<App::Rgit> configurations.

This is an internal class to L<rgit>.

=head1 METHODS

=head2 C<< new root => $root, git => $git >>

Creates a new configuration object based on the root directory C<$root> and using C<$git> as F<git> executable.

=cut

sub new {
 my $class = shift;
 $class = ref $class || $class;

 my %args = @_;

 my $root = defined $args{root}
              ? $args{root}
              : defined $ENV{GIT_DIR}
                  ? $ENV{GIT_DIR}
                  : Cwd::cwd;
 Carp::confess("Invalid root directory") unless -d $root;
 $root = File::Spec->canonpath(App::Rgit::Utils::abs_path($root));

 my $git;
 my @candidates = (
  defined $args{git}
    ? $args{git}
    : defined $ENV{GIT_EXEC_PATH}
        ? $ENV{GIT_EXEC_PATH}
        : map File::Spec->catfile($_, 'git'), File::Spec->path
 );
 if (IS_WIN32) {
  my @acc;
  for my $c (@candidates) {
   push @acc, $c, map "$c.$_", qw/exe com bat cmd/;
  }
  @candidates = @acc;
 }
 for my $c (@candidates) {
  if (-x $c) {
   $git = $c;
   last;
  }
 }
 Carp::confess("Couldn't find a proper git executable") unless defined $git;
 $git = File::Spec->canonpath(App::Rgit::Utils::abs_path($git));

 my $conf = 'App::Rgit::Config::Default';
 eval "require $conf; 1" or Carp::confess("Couldn't load $conf: $@");

 my $r = App::Rgit::Repository->new(fake => 1);
 return unless defined $r;

 bless {
  root     => $root,
  git      => $git,
  cwd_repo => $r,
  debug    => defined $args{debug} ? int $args{debug} : WARN,
 }, $conf;
}

=head2 C<info $msg>

=head2 C<warn $msg>

=head2 C<err $msg>

=head2 C<crit $msg>

Notifies a message C<$msg> of the corresponding level.

=cut

sub _notify {
 my $self = shift;
 my $level = shift;
 if ($self->debug >= $level) {
  print STDERR @_;
  return 1;
 }
 return 0;
}

sub info { shift->_notify(INFO, @_) }

sub warn { shift->_notify(WARN, @_) }

sub err  { shift->_notify(ERR, @_) }

sub crit { shift->_notify(CRIT, @_) }

=head2 C<root>

=head2 C<git>

=head2 C<repos>

=head2 C<cwd_repo>

=head2 C<debug>

Read-only accessors.

=cut

BEGIN {
 eval "sub $_ { \$_[0]->{$_} }" for qw/root git cwd_repo debug/;
}

=head1 SEE ALSO

L<rgit>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-rgit at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=rgit>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Rgit::Config

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009,2010 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of App::Rgit::Config
