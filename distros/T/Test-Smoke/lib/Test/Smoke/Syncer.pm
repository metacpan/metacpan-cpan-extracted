package Test::Smoke::Syncer;
use warnings;
use strict;
use Carp;

use Test::Smoke::Syncer::Rsync;
use Test::Smoke::Syncer::Git;
use Test::Smoke::Syncer::Copy;
use Test::Smoke::Syncer::Hardlink;
use Test::Smoke::Syncer::Snapshot;
use Test::Smoke::Syncer::FTP;
use Test::Smoke::Syncer::Forest;

our $VERSION = '0.029';

use Config;
use Cwd qw( cwd abs_path);
use File::Spec;
require File::Path;

my %CONFIG = (
    df_sync     => 'rsync',
    df_ddir     => File::Spec->rel2abs( 'perl-current', abs_path() ),
    df_v        => 0,

# these settings have to do synctype==rsync
    df_rsync    => 'rsync', # you might want a path there
    df_opts     => '-az --delete',
    df_source   => 'github.com/Perl::perl-current',

    rsync       => {
        allowed  => [qw(rsync source opts)],
        required => [qw(rsync source)],
        class    => 'Test::Smoke::Syncer::Rsync',
    },

# these settings have to do with synctype==copy
    df_cdir    => undef,

    copy       => {
        allowed  => [qw(cdir)],
        required => [qw(cdir)],
        class    => 'Test::Smoke::Syncer::Copy',
    },

# these settings have to do with synctype==hardlink
    df_hdir    => undef,
    df_haslink => ($Config{d_link}||'') eq 'define',

    hardlink   => {
        allowed =>  [qw( hdir haslink )],
        required => [qw(hdir)],
        class    => 'Test::Smoke::Syncer::Hardlink',
    },

# these have to do 'forest'
    df_fsync   => 'rsync',
    df_mdir    => undef,
    df_fdir    => undef,

    forest     => {
        allowed  => [qw(fsync mdir fdir)],
        required => [qw(mdir fdir)],
        class    => 'Test::Smoke::Syncer::Forest',
    },

# these settings have to do with synctype==ftp
    df_ftphost => 'ftp.example.com',
    df_ftpport => 21,
    df_ftpsdir => '/',
    df_ftype   => undef,

    ftp        => {
        allowed  => [qw(ftphost ftpport ftpusr ftppwd ftpsdir ftype)],
        required => [qw()],
        class    => 'Test::Smoke::Syncer::FTP',
    },

# these settings have to do with synctype==snapshot
    df_snapurl => 'https://github.com/Perl/perl5/archive/refs/heads/blead.tar.gz',
    df_snaptar => '',

    snapshot   => {
        allowed  => [qw(snapurl snaptar)],
        required => [qw()],
        class    => 'Test::Smoke::Syncer::Snapshot',
    },

# synctype: git
    df_gitbin        => 'git',
    df_gitorigin     => 'https://github.com/Perl/perl5.git',
    df_gitdir        => undef,
    df_gitbare        => 0,
    df_gitdfbranch   => 'blead',
    df_gitbranchfile => undef,

    git => {
        allowed  => [qw(gitbin gitorigin gitdir gitbare gitdfbranch gitbranchfile)],
        required => [qw(gitbin gitorigin gitdir)],
        class    => 'Test::Smoke::Syncer::Git',
    },

# misc.
    valid_type => { rsync => 1, git => 1, snapshot => 1,
                    copy  => 1, hardlink => 1, ftp => 1 },
);

{
    my %allkeys = map {
        ($_ => 1)
    } map
        @{ $CONFIG{ $_ }{allowed} }
    , keys %{ $CONFIG{valid_type} };

    push @{ $CONFIG{forest}{allowed} }, keys %allkeys;
    $CONFIG{forest}{required} = [];
    $CONFIG{forest}{class} = 'Test::Smoke::Syncer::Forest';
    $CONFIG{valid_type}->{forest} = 1;
}

=head1 NAME

Test::Smoke::Syncer - Factory for syncer objects.

=head1 SYNOPSIS

    use Test::Smoke::Syncer;

    my $type = 'rsync'; # or 'snapshot' or 'copy'
    my $syncer = Test::Smoke::Syncer->new( $type => \%sync_config );
    my $patch_level = $syncer->sync;

=head1 DESCRIPTION

At this moment we support three basic types of syncing the perl source-tree.

=over

=item rsync

This method uses the B<rsync> program with the C<< --delete >> option
to get your perl source-tree up to date.

=item snapshot

This method uses the B<Net::FTP> or the B<LWP> module to get the
latest snapshot. When the B<server> attribute starts with I<http://>
the fetching is done by C<LWP::Simple::mirror()>.
To emulate the C<< rsync --delete >> effect, the current source-tree
is removed.

The snapshot tarball is handled by either B<tar>/B<gzip> or
B<Archive::Tar>/B<Compress::Zlib>.

=item copy

This method uses the B<File::Copy> module to copy an existing source-tree
from somewhere on the system (in case rsync doesn't work), this also
removes the current source-tree first.

=item forest

This method will sync the source-tree in one of the above basic methods.
After that, it will create an intermediate copy of the master directory
as hardlinks and run the F<regen_headers.pl> script. This should yield
an up-to-date source-tree. The intermediate directory is now copied as
hardlinks to its final directory ({ddir}).

This can be used to change the way B<make distclean> is run from
F<mktest.pl> (removes all files that are not in the intermediate
directory, which may prove faster than traditional B<make distclean>).

=back

=head1 METHODS

=head2 Test::Smoke::Syncer->new( $type, \%sync_config )

[ Constructor | Public ]

Initialise a new object and check all relevant arguments.
It returns an object of the appropriate B<Test::Smoke::Syncer::*> class.

=cut

sub new {
    my $factory = shift;

    my $sync_type = lc(shift || $CONFIG{df_sync});

    if ( !exists $CONFIG{valid_type}{$sync_type} ) {
        croak( "Invalid sync_type '$sync_type'" );
    };

    my %args_raw = @_ ? UNIVERSAL::isa( $_[0], 'HASH' ) ? %{ $_[0] } : @_ : ();

    my %args = map {
        ( my $key = $_ ) =~ s/^-?(.+)$/lc $1/e;
        ( $key => $args_raw{ $_ } );
    } keys %args_raw;

    my %fields = map {
        my $value = exists $args{$_} ? $args{ $_ } : $CONFIG{ "df_$_" };
        ( $_ => $value )
    } ( v => ddir => @{ $CONFIG{$sync_type}{allowed} } );
    if ( ! File::Spec->file_name_is_absolute( $fields{ddir} ) ) {
        $fields{ddir} = File::Spec->catdir( abs_path(), $fields{ddir} );
    }
    $fields{ddir} = File::Spec->rel2abs( $fields{ddir}, abs_path() );

    my @missing;
    for my $required (@{ $CONFIG{$sync_type}{required} }) {
        push(
            @missing,
            "option '$required' missing for '$CONFIG{$sync_type}{class}'"
        ) if !defined $fields{$required};
    }
    if (@missing) {
        croak("Missing option:\n\t", join("\n\t", @missing));
    }

    my $class = $CONFIG{$sync_type}{class};
    return $class->new(%fields);
}

=head2 Test::Smoke::Syncer->config( $key[, $value] )

[ Accessor | Public ]

C<config()> is an interface to the package lexical C<%CONFIG>,
which holds all the default values for the C<new()> arguments.

With the special key B<all_defaults> this returns a reference
to a hash holding all the default values.

=cut

sub config {
    my $dummy = shift;

    my $key = lc shift;

    if ( $key eq 'all_defaults' ) {
        my %default = map {
            my( $pass_key ) = $_ =~ /^df_(.+)/;
            ( $pass_key => $CONFIG{ $_ } );
        } grep /^df_/ => keys %CONFIG;
        return \%default;
    }

    return undef unless exists $CONFIG{ "df_$key" };

    $CONFIG{ "df_$key" } = shift if @_;

    return $CONFIG{ "df_$key" };
}

=head1 SEE ALSO

L<rsync>, L<gzip>, L<tar>, L<Archive::Tar>, L<Compress::Zlib>,
L<File::Copy>, L<Test::Smoke::SourceTree>

=head1 COPYRIGHT

(c) 2002-2013, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

  * <http://www.perl.com/perl/misc/Artistic.html>,
  * <http://www.gnu.org/copyleft/gpl.html>

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
