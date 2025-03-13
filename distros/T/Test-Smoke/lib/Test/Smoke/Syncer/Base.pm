package Test::Smoke::Syncer::Base;
use warnings;
use strict;
use Carp;

our $VERSION = '0.001';

use Cwd qw/cwd abs_path/;
use Test::Smoke::Util qw/whereis/;
use Test::Smoke::LogMixin;

=head1 NAME

Test;:Smoke::Syncer::Base - Base class for all the syncers.

=head1 DESCRIPTION

=head2 Test::Smoke::Syncer::Baase->new(%arguments)

Return a new instance.

=cut

sub new {
    my $class = shift;

    return bless {@_}, $class;
}

=head2 $syncer->verbose

Get/Set verbosity.

=cut

sub verbose {
    my $self = shift;
    $self->{v} = shift if @_;
    return $self->{v};
}

=head2 $syncer->sync()

Abstract method.

=cut

sub sync {
    my $self = shift;
    my $class = ref $self || $self;
    Carp::croak("Should have been implemented by '$class'");
}

=head2 $syncer->_clear_souce_tree( [$tree_dir] )

[ Method | private-ish ]

C<_clear_source_tree()> removes B<all> files in the source-tree
using B<File::Path::rmtree()>. (See L<File::Path> for caveats.)

If C<$tree_dir> is not specified, C<< $self->{ddir} >> is used.

=cut

sub _clear_source_tree {
    my( $self, $tree_dir ) = @_;

    $tree_dir ||= $self->{ddir};

    $self->log_info("Clear source-tree from '$tree_dir' ");
    my $cnt = File::Path::rmtree( $tree_dir, $self->{v} > 1 );

    File::Path::mkpath( $tree_dir, $self->{v} > 1 ) unless -d $tree_dir;
    $self->log_info("clear-source-tree: $cnt items OK");

}

=head2 $syncer->_relocate_tree( $source_dir )

[ Method | Private-ish ]

C<_relocate_tree()> uses B<File::Copy::move()> to move the source-tree
from C<< $source_dir >> to its destination (C<< $self->{ddir} >>).

=cut

sub _relocate_tree {
    my( $self, $source_dir ) = @_;

    require File::Copy;

    $self->{v} and print "relocate source-tree ";

    # try to move it at once (sort of a rename)
    my $ddir = $^O eq 'VMS' ? $self->{vms_ddir} : $self->{ddir};
    my $ok = $source_dir eq $ddir
           ? 1 : File::Copy::move( $source_dir, $self->{ddir} );

    # Failing that: Copy-By-File :-(
    if ( ! $ok && -d $source_dir ) {
        my $cwd = cwd();
        chdir $source_dir or do {
            print "Cannot chdir($source_dir): $!\n";
            return 0;
        };
        require File::Find;
        File::Find::finddepth( sub {

            my $dest = File::Spec->canonpath( $File::Find::name );
            $dest =~ s/^\Q$source_dir//;
            $dest = File::Spec->catfile( $self->{ddir}, $dest );

            $self->{v} > 1 and print "move $_ $dest\n";
            File::Copy::move( $_, $dest );
        }, "./" );
        chdir $cwd or print "Cannot chdir($cwd) back: $!\n";
        File::Path::rmtree( $source_dir, $self->{v} > 1 );
        $ok = ! -d $source_dir;
    }
    die "Can't move '$source_dir' to $self->{ddir}' ($!)" unless $ok;
    $self->{v} and print "OK\n";
}

=head2 $syncer->check_dot_git_patch( )

[ Method | Public ]

C<check_dot_git_patch()> checks if there is a '.git_patch' file in the source-tree.

It returns the patchlevel found or C<undef>.

=cut

sub check_dot_git_patch {
    my $self = shift;

    my $dot_git_patch = File::Spec->catfile( $self->{ddir}, '.git_patch' );

    local *DOTGITPATCH;
    my $patch_level = '?????';
    if ( open DOTGITPATCH, "< $dot_git_patch" ) {
        chomp( $patch_level = <DOTGITPATCH> );
        close DOTGITPATCH;

	if ( $patch_level ) {

	    return undef if ( $patch_level =~ /^\$Format/ ); # Not expanded

            my @dot_git_patch = split '\|', $patch_level;

            # As we do not use time information, we can just pick the first and
            # the last two elements
            my ($sha, $describe, $names) = @dot_git_patch[0, -2, -1];

            return $sha;
        }
    }
    return undef;
}

=head2 $syncer->check_dot_patch( )

[ Method | Public ]

C<check_dot_patch()> checks if there is a '.patch' file in the source-tree.
It will try to create one if it is not there (this is the case for snapshots).

It returns the patchlevel found or C<undef>.

=cut

sub check_dot_patch {
    my $self = shift;

    my $dot_patch = File::Spec->catfile( $self->{ddir}, '.patch' );

    local *DOTPATCH;
    my $patch_level = '?????';
    if ( open DOTPATCH, "< $dot_patch" ) {
        chomp( $patch_level = <DOTPATCH> );
        close DOTPATCH;
        # From rsync:
        # blead 2019-11-06.00:32:06 +0100 cc8ba724ccabff255f384ab68d6f6806ac2eae7c v5.31.5-174-gcc8ba72
        # from make_dot_patch.pl:
        # blead 2019-11-05.23:32:06 cc8ba724ccabff255f384ab68d6f6806ac2eae7c v5.31.5-174-gcc8ba724cc
        if ( $patch_level ) {
            my @dot_patch = split ' ', $patch_level;

            # As we do not use time information, we can just pick the first and
            # the last two elements
            my ($branch, $sha, $describe) = @dot_patch[0, -2, -1];
            # $sha      -> sysinfo.git_id
            # $describe -> sysinfo.git_describe

            $self->{patchlevel} = $sha      || $branch;
            $self->{patchdescr} = $describe || $branch;
            return $self->{patchlevel};
        }
    }

    # There does not seem to be a '.patch', try 'patchlevel.h'
    local *PATCHLEVEL_H;
    my $patchlevel_h = File::Spec->catfile( $self->{ddir}, 'patchlevel.h' );
    if ( open PATCHLEVEL_H, "< $patchlevel_h" ) {
        my $declaration_seen = 0;
        while ( <PATCHLEVEL_H> ) {
            $declaration_seen ||= /local_patches\[\]/;
            $declaration_seen && /^\s+,"(?:DEVEL|MAINT)(\d+)|(RC\d+)"/ or next;
            $patch_level = $1 || $2 || '?????';
            if ( $patch_level =~ /^RC/ ) {
                $patch_level = $self->version_from_patchlevel_h .
                               "-$patch_level";
            } else {
                $patch_level++;
            }
        }
        # save 'patchlevel.h' mtime, so you can set it on '.patch'
        my $mtime = ( stat PATCHLEVEL_H )[9];
        close PATCHLEVEL_H;
        # Now create '.patch' and return if $patch_level
        # The patchlevel is off by one in snapshots
        if ( $patch_level && $patch_level !~ /-RC\d+$/ ) {
            if ( open DOTPATCH, "> $dot_patch" ) {
                print DOTPATCH "$patch_level\n";
                close DOTPATCH; # no use generating the error
                utime $mtime, $mtime, $dot_patch;
            }
            $self->{patchlevel} = $patch_level;
            return $self->{patchlevel};
        } else {
            $self->{patchlevel} = $patch_level;
            return $self->{patchlevel}
        }
    }
    return undef;
}

=head2 version_from_patchlevel_h( $ddir )

C<version_from_patchlevel_h()> returns a "dotted" version as derived
from the F<patchlevel.h> file in the distribution.

=cut

sub version_from_patchlevel_h {
    my $self = shift;

    require Test::Smoke::Util;
    return Test::Smoke::Util::version_from_patchlevel_h( $self->{ddir} );
}

=head2 is_git_dir()

Checks, in a git way, if we are in a real git repository directory.

=cut

sub is_git_dir {
    my $self = shift;

    my $gitbin = whereis('git');
    if (!$gitbin) {
        $self->log_debug("Could not find a git-binary to run for 'is_git_dir'");
        return 0;
    }
    $self->log_debug("Found '$gitbin' for 'is_git_dir'");

    my $git = Test::Smoke::Util::Execute->new(
        command => $gitbin,
        verbose => $self->verbose,
    );
    my $out = $git->run(
        'rev-parse' => '--is-inside-work-tree',
        '2>&1'
    );
    $self->log_debug("git rev-parse --is-inside-work-tree: " . $out);
    return $out eq 'true' ? 1 : 0;
}

=head2 make_dot_patch

If this is a git repo, run the C<< Porting/make_dot_patch.pl >> to generate the
.patch file

=cut

sub make_dot_patch {
    my $self = shift;

    my $mk_dot_patch = Test::Smoke::Util::Execute->new(
        command => "$^X",
        verbose => $self->verbose,
    );
    my $perlout = $mk_dot_patch->run("Porting/make_dot_patch.pl", ">", ".patch");
    $self->log_debug($perlout);
}

=head2 $syncer->clean_from_directory( $source_dir[, @leave_these] )

C<clean_from_directory()> uses File::Find to get the contents of
C<$source_dir> and compare these to {ddir} and remove all other files.

The contents of @leave_these should be in "MANIFEST-format"
(See L<Test::Smoke::SourceTree>).

=cut

sub clean_from_directory {
    my $self = shift;
    my ($clean_dir, @leave_these) = @_;
    my $this_dir = abs_path(File::Spec->curdir);

    my $source_dir = File::Spec->file_name_is_absolute($clean_dir)
        ? $clean_dir
        : File::Spec->rel2abs($clean_dir, $this_dir);
    $self->log_debug("[clean_from_directory($this_dir)] $clean_dir => $source_dir\n");

    require Test::Smoke::SourceTree;
    my $tree = Test::Smoke::SourceTree->new($source_dir, $self->{v});

    my %orig_dir = map { ( $_ => 1) } @leave_these;
    File::Find::find( sub {
        return unless -f;
        my $file = $tree->abs2mani( $File::Find::name );
        $orig_dir{ $file } = 1;
    }, $source_dir );

    $tree = Test::Smoke::SourceTree->new( $self->{ddir}, $self->{v} );
    File::Find::find( sub {
        return unless -f;
        my $file = $tree->abs2mani( $File::Find::name );
        return if exists $orig_dir{ $file };
        1 while unlink $_;
        $self->log_debug("Unlink '$file': " . (-e $_ ? "$!" : "ok"));
    }, $self->{ddir} );
}

=head2 $syncer->pre_sync

C<pre_sync()> should be called by the C<sync()> methods to setup the
sync environment. Currently only useful on I<OpenVMS>.

=cut

sub pre_sync {
    return 1 unless $^O eq 'VMS';
    my $self = shift;
    require Test::Smoke::Util;

    Test::Smoke::Util::set_vms_rooted_logical( TSP5SRC => $self->{ddir} );
    $self->{vms_ddir} = $self->{ddir};
    $self->{ddir} = 'TSP5SRC:[000000]';
}

=head2 $syncer->post_sync

C<post_sync()> should be called by the C<sync()> methods to unset the
sync environment. Currently only useful on I<OpenVMS>.

=cut

sub post_sync {
    return 1 unless $^O eq 'VMS';
    my $self = shift;

    ( my $logical = $self->{ddir} || '' ) =~ s/:\[000000\]$//;
    return unless $logical;
    my $result = system "DEASSIGN/JOB $logical";

    $self->{ddir} = delete $self->{vms_ddir};
    return $result == 0;
}

1;

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
