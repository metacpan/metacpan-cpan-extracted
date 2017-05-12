package Test::Filesystem;

use 5.006;
use strict;
use warnings;

use Data::Dumper;

use Test::Builder::Module 0.98;

use Test::Deep;

our $VERSION = '0.01';

our @ISA    = qw(Test::Builder::Module);
our @EXPORT = qw(
  cmp_filesystem
);

1;

=head1 NAME

Test::Filesystem - Tester for filesystem content

=head1 SYNOPSIS

  use Test::Testfilesystem tests => 1;

  cmp_filesystem($got_root_dir, $expected_root_dir, $test_name);
  # or
  cmp_filesystem( { OPTIONS }, $got_root_dir, $expected_root_dir, $test_name);

=head1 DESCRIPTION

This test framework compare filesystems (content and meta attribute).
You can use it if your perl program
is generating files and you don't want to compare the test results file by file.

=head1 PUBLIC INTERFACE

=over 4

=item C<cmp_filesystem( {OPTIONS}, GOT_ROOT_DIR_PATH, EXPECTED_ROOT_DIR_PATH, NAME )>

Compares the two given filesystems: C<GOT/> and C<EXPECTED/>. C<OPTIONS> are unsupported
yet.

In the current implementation we compare the following attributes:

=over 4

=item 1. files and directories

Location relative to the given root directory. No symlinks or special files will be checked.

=item 2. stat attributes

C<stat()> attributes B<without> C<dev>, C<ctime>, C<blksize>, C<blocks> and C<ino>
(inode number).

=item 3. file content.

Doing the MD5 dance with every file.

=back

We're not checking the root directory itself, only the content of it. So if the
mtime from C</a> and C</b> differs, it will checked.

=cut

sub cmp_filesystem
{
    my $options = ref $_[ 0 ] eq 'HASH' ? shift : {};

    my ( $got, $expected, $name ) = @_;

    my $tb = Test::More->builder;

    my $me = Test::Filesystem::Root->new( root_directory => $got );
    $me->scan();
    my $other = Test::Filesystem::Root->new( root_directory => $expected );
    $other->scan();

    my $files = scalar( @{ $me->files } );

    if ( !$name )
    {
        $name = sprintf( 'compared %s directory entries', $files );
    }
    else
    {
        $name .= sprintf( ' (compared %s directory entries)', $files );
    }

    my $diffs = $me->changed_files_structure( $other );
    _print_diagnostics( $name, $diffs ) || return 0;

    $diffs = $me->changed_files_content( $other );
    _print_diagnostics( $name, $diffs ) || return 0;

    $tb->ok( 1, $name );

    return 1;
}

sub _print_diagnostics
{
    my ( $name, $diffs ) = @_;

    my $tb = Test::More->builder;

    if ( @$diffs )
    {
        foreach my $diff ( @$diffs )
        {
            $tb->diag( _format_diagnostic_lines( $diff ) );
        }
        $tb->ok( 0, $name );
        return 0;
    }
    return 1;
}

sub _format_diagnostic_lines
{
    my $data = shift;

    _format_single_diagnostic_line( 'got',
        $data->{ file_a } . ': ' . $data->{ message_a } )
      . _format_single_diagnostic_line( 'expected',
        $data->{ file_b } . ': ' . $data->{ message_b } );
}

sub _format_single_diagnostic_line
{
    my $key     = shift;
    my $message = shift;

    sprintf( "%12s: %s\n", $key, $message );
}

=back

=head1 EXPORT

C<cmp_filesystems> by default.

=head1 TODO

=over 4

=item Support for C<.tar.gz>.

=item Support for filelists (instead a giving a root directory)

=back

Got ideas? Send them to me.

=head1 AUTHOR

Erik Wasser, C<< <fuzz at namm.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-filesystem at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Filesystem>.  I will be n
otified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Filesystem

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Filesystem>

=item * AnnoCPAN: Annotated CPAN documentation
    
L<http://annocpan.org/dist/Test-Filesystem>
    
=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Filesystem>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Filesystem/>

=back

=head1 SEE ALSO

L<perl>.

=cut

package Test::Filesystem::Root;

use strict;
use warnings;

use Data::Dumper;

use Digest::MD5;
use File::stat qw//;
use IO::Dir;

sub new
{
    my $class = shift;
    my $opt   = { @_ };
    my $self  = {
        root_directory => $opt->{ root_directory },
        files          => [],
    };
    bless( $self, $class );
    return $self;
}

sub scan
{
    my $self = shift;

    $self->{ files } =
      $self->_collect_files( { root_directory => $self->{ root_directory } } );
}

sub complete_filename
{
    my $self = shift;
    my $name = shift;

    return $self->{ root_directory } . '/' . $name;
}

sub _collect_files
{
    my $opt = shift;

    my $root_path = $opt->{ root_directory };

    my @pathes = ( '.' );

    my @files = ();

    while ( my $path = pop @pathes )
    {
        my $handle = IO::Dir->new( $root_path . '/' . $path );

        while ( defined( $_ = $handle->read ) )
        {
            next if ( /^\.\.?$/ );

            my $name      = $path . '/' . $_;
            my $full_name = $root_path . '/' . $path . '/' . $_;

            push @files, $name;

            if ( -d $full_name )
            {
                push @pathes, $name;
            }
        }
    }
    #   Cut of the beginning './'
    [ sort map { substr( $_, 2 ) } @files ];
}

sub changed_files_structure
{
    my $self  = shift;
    my $other = shift;

    my $fs_a = { map { $_, undef } @{ $self->files } };
    my $fs_b = { map { $_, undef } @{ $other->files } };

    my @changes = ();

    foreach my $file ( sort ( keys %$fs_a, keys %$fs_b ) )
    {
        push @changes,
          {
            file_a    => $self->complete_filename( $file ),
            message_a => 'exists',
            file_b    => $other->complete_filename( $file ),
            message_b => 'missing',
          }
          if ( exists $fs_a->{ $file } && !exists $fs_b->{ $file } );

        push @changes,
          {
            file_a    => $self->complete_filename( $file ),
            message_a => 'missing',
            file_b    => $other->complete_filename( $file ),
            message_b => 'exists',
          }
          if ( !exists $fs_a->{ $file } && exists $fs_b->{ $file } );
    }

    return [ sort { $a->{ file_a } cmp $b->{ file_a } } @changes ];
}

sub changed_files_content
{
    my $self  = shift;
    my $other = shift;

    my $fs_a = { map { $_, undef } @{ $self->files } };
    my $fs_b = { map { $_, undef } @{ $other->files } };

    my @removed = ();

    my @diffs = ();

    foreach my $file ( sort keys %$fs_a )
    {
        my $filename_a = $self->{ root_directory } . '/' . $file;
        my $filename_b = $other->{ root_directory } . '/' . $file;

        my $stat_a = File::stat::stat( $filename_a );
        my $stat_b = File::stat::stat( $filename_b );

        #   Skip if both files are now missing
        next if ( !$stat_a && !$stat_b );

        if ( $stat_a && !$stat_b )
        {
            push @diffs,
              {
                file_a    => $filename_a,
                message_a => 'exists',
                file_b    => $filename_b,
                message_b => 'missing',
              };

            next;
        }

        if ( !$stat_a && $stat_b )
        {
            push @diffs,
              {
                file_a    => $filename_a,
                message_b => 'missing',
                file_b    => $filename_b,
                message_b => 'exists',
              };

            next;
        }

        my $message = $self->_changed_stats(
            {
                file_a => $filename_a,
                stat_a => $stat_a,
                file_b => $filename_b,
                stat_b => $stat_b,
            }
        );

        if ( $message )
        {
            push @diffs, $message;
            next;
        }

        my $handle_a = IO::File->new( $filename_a, '<' );
        my $handle_b = IO::File->new( $filename_b, '<' );

        my $hexdigest_a = Digest::MD5->new->addfile( $handle_a )->hexdigest;
        my $hexdigest_b = Digest::MD5->new->addfile( $handle_b )->hexdigest;

        if ( $hexdigest_a ne $hexdigest_b )
        {
            push @diffs,
              {
                file_a    => $filename_a,
                message_a => sprintf( "MD5 is %s'", $hexdigest_a ),
                file_b    => $filename_b,
                message_b => sprintf( "MD5 is %s'", $hexdigest_b ),
              };
            next;
        }

    }
    \@diffs;
}

sub _changed_stats
{
    my $self = shift;
    my $opt  = shift;

    foreach my $stat_options ( @{ _stat_options() } )
    {
        next
          if ( exists $stat_options->{ flags }
            && $stat_options->{ flags }->{ ignore } );

        my $method = $stat_options->{ method };

        my $stat_option_a = $opt->{ stat_a }->$method();
        my $stat_option_b = $opt->{ stat_b }->$method();

        if ( defined $stat_option_a && !defined $stat_option_b )
        {
            return {
                file_a    => $opt->{ file_a },
                message_a => sprintf( "Attribute '%s' is %s'", $stat_option_a ),
                file_b    => $opt->{ file_b },
                message_b => sprintf( "Attribute '%s' is %s'", 'undef' )
            };
        }

        if ( !defined $stat_option_a && defined $stat_option_b )
        {
            return {
                file_a    => $opt->{ file_a },
                message_a => sprintf( "Attribute '%s' is %s'", 'undef' ),
                file_b    => $opt->{ file_b },
                message_b => sprintf( "Attribute '%s' is %s'", $stat_option_b )
            };
        }

        if ( $stat_option_a ne $stat_option_b )
        {
            return {
                file_a => $opt->{ file_a },
                message_a =>
                  sprintf( "attribute '%s' is %s'", $method, $stat_option_a ),
                file_b => $opt->{ file_b },
                message_b =>
                  sprintf( "attribute '%s' is %s'", $method, $stat_option_b )
            };
        }
    }
    return;
}

sub _stat_options
{
    my $c = [
        {
            method  => 'dev',
            message => 'device number of filesystem',
            flags   => { ignore => 1 },
        },
        {
            method  => 'ino',
            message => 'inode number',
            flags   => { ignore => 1 },
        },
        {
            method  => 'mode',
            message => 'file mode  (type and permissions)',
        },
        {
            method  => 'nlink',
            message => 'number of (hard) links to the file',
        },
        {
            method  => 'uid',
            message => 'numeric user ID of file\'s owner',
        },
        {
            method  => 'gid',
            message => 'numeric group ID of file\'s owner',
        },
        {
            method  => 'rdev',
            message => 'the device identifier (special files only)',
        },
        {
            method  => 'size',
            message => 'total size of file, in bytes',
        },
        {
            method  => 'atime',
            message => 'last access time in seconds since the epoch',
        },
        {
            method  => 'mtime',
            message => 'last modify time in seconds since the epoch',
        },
        {
            method  => 'ctime',
            message => 'inode change time in seconds since the epoch',
            flags   => { ignore => 1 },

        },
        {
            method  => 'blksize',
            message => 'preferred block size for file system I/O',
            flags   => { ignore => 1 },
        },
        {
            method  => 'blocks',
            message => 'actual number of blocks allocated',
            flags   => { ignore => 1 },

        },
    ];
    return $c;
}

sub files
{
    my $self = shift;

    $self->{ files };
}

