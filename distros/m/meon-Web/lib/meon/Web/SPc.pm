package meon::Web::SPc;

=head1 NAME

meon::Web::SPc - build-time system path configuration

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use File::Spec;

sub _path_types {qw(
    prefix
    localstatedir
    sysconfdir
    datadir
    cachedir
    logdir
    sharedstatedir
    srvdir
)};

=head1 PATHS

=head2 sysconfdir

=head2 datadir

=head2 cachedir

=head2 logdir

=head2 sharedstatedir

=head2 lockdir

=head2 srvdir

=cut

sub prefix        { use Sys::Path; Sys::Path->find_distribution_root(__PACKAGE__); };
sub localstatedir { File::Spec->catdir(__PACKAGE__->prefix, 'var') };

sub sysconfdir { File::Spec->catdir(__PACKAGE__->prefix, 'etc') };
sub datadir    { File::Spec->catdir(__PACKAGE__->prefix, 'share') };
sub cachedir   { File::Spec->catdir(__PACKAGE__->localstatedir, 'cache') };
sub logdir     { File::Spec->catdir(__PACKAGE__->localstatedir, 'log') };
sub sharedstatedir { File::Spec->catdir(__PACKAGE__->localstatedir, 'lib') };
sub lockdir    { File::Spec->catdir(__PACKAGE__->localstatedir, 'lock') };
sub srvdir     { File::Spec->catdir(__PACKAGE__->prefix, 'srv') };

1;
