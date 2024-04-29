package Test::Smoke::SourceTree;
use strict;

our $VERSION = '0.008';

use File::Spec;
use File::Find;
use Cwd 'abs_path';
use Carp;
use Test::Smoke::LogMixin;

use base 'Exporter';
our %EXPORT_TAGS = (
    mani_const => [qw( &ST_MISSING &ST_UNDECLARED )],
    const      => [qw( &ST_MISSING &ST_UNDECLARED )],
);
our @EXPORT_OK = @{ $EXPORT_TAGS{mani_const} };

our $NOCASE = $^O eq 'MSWin32' || $^O eq 'VMS';

=head1 NAME

Test::Smoke::SourceTree - Manipulate the perl source-tree

=head1 SYNOPSIS

    use Test::Smoke::SourceTree qw( :mani_const );

    my $tree = Test::Smoke::SourceTree->new( $tree_dir );

    my $mani_check = $tree->check_MANIFEST;
    foreach my $file ( sort keys %$mani_check ) {
        if ( $mani_check->{ $file } == ST_MISSING ) {
            print "MANIFEST declared '$file' but it is missing\n";
        } elsif ( $mani_check->{ $file } == ST_UNDECLARED ) {
            print "MANIFEST did not declare '$file'\n";
        }
    }

    $tree->clean_from_MANIFEST;

=head1 CONSTANTS

=over

=item ST_MISSING

=item ST_UNDECLARED

=back

=cut

# Define some constants
sub ST_MISSING()    { 1 }
sub ST_UNDECLARED() { 0 }

=head1 DESCRIPTION

=head2 Test::Smoke::SourceTree->new( $tree_dir[, $verbose] )

C<new()> creates a new object, this is a simple scalar containing
C<< File::Spec->rel2abs( $tree_dir) >>.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto ? ref $proto : $proto;
    my ($dir, $verbose) = @_;

    croak sprintf "Usage: my \$tree = %s->new( <directory> )", __PACKAGE__
        unless @_;

    # it should be a directory!
    my $cwd = abs_path(File::Spec->curdir);
    chdir $dir or croak "Cannot chdir($dir): $!";
    # try not to trip over an absolute-path to something that somehow is a
    # symlink. abs_path('.') will give you the real-path; that will fail...
    my $tree_dir = File::Spec->file_name_is_absolute($dir)
        ? $dir
        : abs_path(File::Spec->curdir);
    my $self = {
        tree_dir => $tree_dir,
        verbose => $verbose || 0,
    };
    chdir $cwd;

    return bless $self, $class;
}

=head2 $tree->tree_dir

Get the directory.

=cut

sub tree_dir { return $_[0]->{tree_dir} }

=head2 $tree->verbose

Get verbosity.

=cut

sub verbose { return $_[0]->{verbose} }

=head2 $tree->canonpath( )

C<canonpath()> returns the canonical name for the path,
see L<File::Spec>.

=cut

sub canonpath {
    my $self = shift;
    return File::Spec->canonpath( $self->tree_dir );
}

=head2 $tree->rel2abs( [$base_dir] )

C<rel2abs()> returns the absolute path, see L<File::Spec>.

=cut

sub rel2abs {
    my $self = shift;
    return File::Spec->rel2abs( $self->tree_dir, @_ );
}

=head2 $tree->abs2rel( [$base_dir] )

C<abs2rel()> returns  a relative path,
see L<File::Spec>.

=cut

sub abs2rel {
    my $self = shift;
    return File::Spec->abs2rel( $self->tree_dir, @_ );
}

=head2 $tree->mani2abs( $file[, $base_path] )

C<mani2abs()> returns the absolute filename of C<$file>, which should
be in "MANIFEST" format (i.e. using '/' as directory separator).

=cut

sub mani2abs {
    my $self = shift;

    my $path = shift;
    my @dirs = split m{/+}, $path;
    my $file = pop @dirs;
    if ( $^O eq 'VMS' ) {
        my @parts = split m/\./, $file;
        my $last = pop @parts;
        @parts and
            $file = join( "_", map { s/[^\w-]/_/g; $_ } @parts ) . ".$last";
    }
    @dirs and $file = join '/', @dirs, $file;
    my @split_path = split m|/|, $file;
    my $base_path = File::Spec->rel2abs( $self->tree_dir, @_ );
    return File::Spec->catfile( $base_path, @split_path );
}

=head2 $tree->mani2absdir( $dir[, $base_path] )

C<mani2abs()> returns the absolute dirname of C<$dir>, which should
be in "MANIFEST" format (i.e. using '/' as directory separator).

=cut

sub mani2absdir {
    my $self = shift;

    my @split_path = split m|/|, shift;
    my $base_path = File::Spec->rel2abs( $self->tree_dir, @_ );
    return File::Spec->catdir( $base_path, @split_path );
}

=head2 $tree->abs2mani( $file )

C<abs2mani()> returns the MANIFEST style filename.

=cut

sub abs2mani {
    my $self = shift;
    my ($source_file) = @_;

    my $relfile = File::Spec->abs2rel(
        File::Spec->canonpath( $source_file ), $self->tree_dir
    );
    $self->log_debug("[abs2mani($source_file)] $relfile");

    my( undef, $directories, $file ) = File::Spec->splitpath( $relfile );
    my @dirs = grep $_ && length $_ => File::Spec->splitdir( $directories );
    push @dirs, $file;
    return join '/', @dirs;
}

=head2 $tree->check_MANIFEST( @ignore )

C<check_MANIFEST()> reads the B<MANIFEST> file from C<< $self->tree_dir >> and
compares it with the actual contents of C<< $self->tree_dir >>.

Returns a hashref with suspicious entries (if any) as keys that have a
value of either B<ST_MISSING> (not in directory) or B<ST_UNDECLARED>
(not in MANIFEST).

=cut

sub check_MANIFEST {
    my $self = shift;

    my %manifest = %{ $self->_read_mani_file( 'MANIFEST' ) };
    $self->log_debug("Found %d entries in MANIFEST", scalar(keys %manifest));

    my %ignore = map {
        my $entry = $NOCASE ? uc $_ : $_;
        $entry => undef
    } ( ".patch", "MANIFEST.SKIP", '.git', '.gitignore', '.mailmap', @_ ),
      keys %{ $self->_read_mani_file( 'MANIFEST.SKIP', 1 ) };
    $self->log_debug("Found %d entries in MANIFEST.SKIP", scalar(keys %ignore));

    # Walk the tree, remove all found files from %manifest
    # and add other files to %manifest
    # unless they are in the ignore list
    my $cwd = abs_path(File::Spec->curdir);
    chdir $self->tree_dir or die "Cannot chdir($self->tree_dir): $!";
    require File::Find;
    File::Find::find(
        sub {
            -f or return;
            my $cpath = File::Spec->canonpath($File::Find::name);
            my (undef, $dirs, $file) = File::Spec->splitpath($cpath);
            my @dirs = grep $_ && length $_ => File::Spec->splitdir($dirs);
            $^O eq 'VMS' and $file =~ s/\.$//;
            my $mani_name = join '/', @dirs, $file;
            $NOCASE and $mani_name = uc $mani_name;
            if (exists $manifest{$mani_name}) {
                $self->log_debug("[manicheck] Matched $mani_name");
                delete $manifest{$mani_name};
            }
            else {
                if (!grep $mani_name =~ /$_/, keys %ignore) {
                    $self->log_debug("[manicheck] Undeclared $mani_name");
                    $manifest{$mani_name} = ST_UNDECLARED;
                }
                else {
                    $self->log_debug("[manicheck] Skipped $mani_name");
                }
            }
        },
        '.'
    );
    chdir $cwd;
    $self->log_debug("[manicheck] %d entries missing", scalar(keys %manifest));

    return \%manifest;
}

=head2 $self->_read_mani_file( $path[, $no_croak] )

C<_read_mani_file()> reads the contents of C<$path> like it is a
MANIFEST typeof file and returns a ref to hash with all values set
C<ST_MISSING>.

=cut

sub _read_mani_file {
    my $self = shift;
    my( $path, $no_croak ) = @_;

    my $manifile = $self->mani2abs( $path );
    local *MANIFEST;
    open MANIFEST, "< $manifile" or do {
        $no_croak and return { };
        croak( "Can't open '$manifile': $!" );
    };

    my %manifest = map {
        m|(\S+)|;
        my $entry = $NOCASE ? uc $1 : $1;
        if ( $^O eq 'VMS' ) {
            my @dirs = split m|/|, $entry;
            my $file = pop @dirs;
            my @parts = split /[.@#]/, $file;
            if ( @parts > 1 ) {
                my $ext = ( pop @parts ) || '';
                $file = join( "_", @parts ) . ".$ext";
            }
            $entry = @dirs ? join( "/", @dirs, $file ) : $file;
        }
        ( $entry => ST_MISSING );
    } <MANIFEST>;
    close MANIFEST;

    return \%manifest;
}

=head2 $tree->clean_from_MANIFEST( )

C<clean_from_MANIFEST()> removes all files from the source-tree that are
not declared in the B<MANIFEST> file.

=cut

sub clean_from_MANIFEST {
    my $self = shift;

    my $mani_check = $self->check_MANIFEST( @_ );
    my @to_remove = grep {
        $mani_check->{ $_ } == ST_UNDECLARED
    } keys %$mani_check;

    foreach my $entry ( @to_remove ) {
        my $file = $self->mani2abs( $entry );
        1 while unlink $file;
    }
}

=head2 copy_from_MANIFEST( $dest_dir )

C<_copy_from_MANIFEST()> uses the B<MANIFEST> file from C<$self->tree_dir>
to copy a source-tree to C<< $dest_dir >>.

=cut

sub copy_from_MANIFEST {
    my ($self, $dest_dir) = @_;

    my $manifest = $self->mani2abs( 'MANIFEST' );

    local *MANIFEST;
    open MANIFEST, "< $manifest" or do {
        carp "Can't open '$manifest': $!\n";
        return undef;
    };

    $self->log_info("Reading from '%s'", $manifest);
    my @manifest_files = map {
        /^([^\s]+)/ ? $1 : $_
    } <MANIFEST>;
    close MANIFEST;
    my $dot_patch = $self->mani2abs( '.patch' );
    -f $dot_patch and push @manifest_files, '.patch';

    $self->log_info("%s: %d items OK", $manifest, scalar @manifest_files);

    File::Path::mkpath( $dest_dir, $self->verbose ) unless -d $dest_dir;
    my $dest = $self->new( $dest_dir );

    require File::Basename;
    require File::Copy;
    foreach my $file ( @manifest_files ) {
        $file or next;

        my $dest_name = $dest->mani2abs( $file );
        my $dest_path = File::Basename::dirname( $dest_name );

        File::Path::mkpath( $dest_path, $self->verbose ) unless -d $dest_path;

        my $abs_file = $self->mani2abs( $file );
        my $mode = ( stat $abs_file )[2] & 07777;
        -f $dest_name and 1 while unlink $dest_name;
        my $ok = File::Copy::syscopy( $abs_file, $dest_name );
        $ok and $ok &&= chmod $mode, $dest_name;
        if ($ok) {
            $self->log_debug("%s -> %s: %sOK", $abs_file, $dest_name, ($ok ? "" : "NOT "));
        }
        else {
            $self->log_warn("copy '$file' ($dest_path): $!");
        }
    }
}

1;

=head1 COPYRIGHT

(c) 2002-2015, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
