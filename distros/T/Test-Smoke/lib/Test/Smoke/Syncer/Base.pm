package Test::Smoke::Syncer::Base;
use warnings;
use strict;
use Carp;

our $VERSION = '0.001';

use Cwd qw/cwd abs_path/;
use Test::Smoke::Util qw/whereis/;

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

    $self->{v} and print "Clear source-tree from '$tree_dir' ";
    my $cnt = File::Path::rmtree( $tree_dir, $self->{v} > 1 );

    File::Path::mkpath( $tree_dir, $self->{v} > 1 ) unless -d $tree_dir;
    $self->{v} and print "$cnt items OK\n";

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
        if ( $patch_level ) {
            my @dot_patch = split ' ', $patch_level;
            $self->{patchlevel} = $dot_patch[2] || $dot_patch[0];
            $self->{patchdescr} = $dot_patch[3] || $dot_patch[0];
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
    return Test::Smoke::Util::version_from_patchelevel( $self->{ddir} );
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
        command => "$^X Porting/make_dot_patch.pl > .patch",
        verbose => $self->verbose,
    );
    my $perlout = $mk_dot_patch->run();
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
    my $source_dir = File::Spec->rel2abs( shift, abs_path() );

    require Test::Smoke::SourceTree;
    my $tree = Test::Smoke::SourceTree->new( $source_dir );

    my @leave_these = @_ ? @_ : ();
    my %orig_dir = map { ( $_ => 1) } @leave_these;
    File::Find::find( sub {
        return unless -f;
        my $file = $tree->abs2mani( $File::Find::name );
        $orig_dir{ $file } = 1;
    }, $source_dir );

    $tree = Test::Smoke::SourceTree->new( $self->{ddir} );
    File::Find::find( sub {
        return unless -f;
        my $file = $tree->abs2mani( $File::Find::name );
        return if exists $orig_dir{ $file };
        $self->{v} > 1 and print "Unlink '$file'";
        1 while unlink $_;
        $self->{v} > 1 and print -e $_ ? ": $!\n" : "\n";
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
