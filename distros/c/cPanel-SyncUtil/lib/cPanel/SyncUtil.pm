package cPanel::SyncUtil;

use strict;
use warnings;
use Carp              ();
use File::Spec        ();
use File::Slurp       ();
use File::Find        ();
use Digest::MD5::File ();
use Digest::SHA       ();
use Cwd               ();
use Archive::Tar      ();

our $VERSION = '0.8';

our %ignore_name = (
    '.git' => 1,
    '.svn' => 1,
);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
  build_cpanelsync
  get_mode_string
  get_mode_string_preserve_setuid
  compress_files
  _write_file
  _read_dir
  _read_dir_recursively
  _lock
  _unlock
  _safe_cpsync_dir
  _chown_pwd_recursively
  _chown_recursively
  _raw_dir
  _sync_touchlock_pwd
  _get_opts_hash
);

our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

our $bzip;

sub get_mode_string {
    my ($file) = @_;

    my $perms = ( stat($file) )[2] || 0;
    $perms = $perms & 0777;
    return sprintf( '%o', $perms );    # Stringify the octal.
}

sub get_mode_string_preserve_setuid {
    my ($file) = @_;

    my $perms = ( stat($file) )[2] || 0;
    if ( !-l _ ) {
        $perms = $perms & 04777;
    }
    else {
        $perms = $perms & 0777;
    }
    return sprintf( '%o', $perms );    # Stringify the octal.
}

sub _write_file { goto &File::Slurp::write_file; }

sub _read_dir { goto &File::Slurp::read_dir; }

# my() not our() so that they can't be [easily] changed))
# order by: type, then length, then case insensitive name
# readdir could/will be slightly different than entry because entry
#    has varying meta data (mode, target, etc) so length and name are pidgy,
#    not critical for operation as the point of sort holds its integrity
my $sort_cpanelsync_entries = sub {
    substr( $a, 0, 1 ) cmp substr( $b, 0, 1 ) || length($a) <=> length($b) || uc($a) cmp uc($b) || $a cmp $b;
};
my %type;
my $sort_readdir = sub {
    $type{$a} ||= ( -l $a ? 'l' : ( -d $a ? 'd' : 'f' ) );
    $type{$b} ||= ( -l $b ? 'l' : ( -d $b ? 'd' : 'f' ) );
    $type{$a} cmp $type{$b} || length($a) <=> length($b) || uc($a) cmp uc($b) || $a cmp $b;
};

sub __sort_test {
    my ( $type, @args ) = @_;
    if ( $type == 1 ) {
        %type = ref( $args[-1] ) eq 'HASH' ? %{ pop @args } : ();
        return sort $sort_readdir @args;
    }
    else {
        return sort $sort_cpanelsync_entries @args;
    }
}

sub _read_dir_recursively {
    my $dir = shift;
    return if ( !$dir || !-d $dir );
    my @files;
    my $wanted = sub {
        return if $File::Find::name eq '.';

        my ($filename) = reverse( File::Spec->splitpath($File::Find::name) );
        if ( exists $ignore_name{$File::Find::name} || exists $ignore_name{$filename} ) {
            $File::Find::prune = 1;
            return;
        }

        my $clean = $File::Find::name;
        $clean =~ s/\/+$//;    # so that -l and -d are not confused

        push @files, $clean;

        # if (-l $clean) {
        #     push @links, $File::Find::name;
        # }
        # elsif(-d $clean) {
        #     push @dirs, $File::Find::name;
        # }
        # else {
        #     push @files, $clean;
        # }
    };
    File::Find::find( { 'wanted' => $wanted, 'no_chdir' => 1, 'follow' => 0, }, $dir );

    # my @results = (sort $sort_readdir_notype @dirs), (sort $sort_readdir_notype @files), (sort $sort_readdir_notype @links);
    return wantarray ? ( sort $sort_readdir @files ) : [ sort $sort_readdir @files ];
}

sub _lock {
    for (@_) {
        next if !-d $_;
        _write_file( File::Spec->catfile( $_, '.cpanelsync.lock' ), 'locked' );
    }
}

sub _unlock {
    for (@_) {
        next if !-d $_;
        _write_file( File::Spec->catfile( $_, '.cpanelsync.lock' ), '' );
    }
}

sub _safe_cpsync_dir {
    my $dir = shift;
    return 1
      if defined $dir
      && $dir !~ m/\.bak$/
      && $dir !~ m/^\./
      && -d $dir
      && !-l $dir;
    return 0;
}

sub _chown_pwd_recursively {
    my ( $user, $group ) = @_;
    _chown_recursively( $user, $group, '.' );
}

sub _chown_recursively {
    my ( $user, $group, $dir );

    if ( @_ == 3 ) {
        ( $user, $group, $dir ) = @_;
    }
    elsif ( @_ == 2 ) {
        ( $user, $dir ) = @_;
    }
    else {
        Carp::croak('improper arguments');
    }

    my $chown = defined $group ? "$user:$group" : $user;
    Carp::croak 'User [and group] must be ^\w+$' if $chown !~ m{^\w+(\:\w+)?$};

    Carp::croak "Invalid directory $dir" if !-d $dir;

    system 'chown', '-R', $chown, $dir;
}

sub _raw_dir {
    my ( $base, $archive, $verbose, @files ) = @_;
    my $args_hr = ref($verbose) ? $verbose : { 'verbose' => $verbose };

    my $bz2_opt = $args_hr->{'verbose'} ? '-fkv' : '-fk';
    my $pwd = Cwd::cwd();
    if ( !-d $base ) {
        Carp::cluck "Invalid base directory $base";
        return;
    }
    elsif ( !chdir $base ) {
        Carp::cluck "Unable to chdir to directory $base: $!";
        return;
    }

    if ( !-d $archive ) {
        $! = 20;
        return;
    }
    elsif ( $archive eq '.' ) {
        Carp::cluck "Current directory '.' cannot be used as the archive destination";
        return;
    }
    else {
        my $tar = Archive::Tar->new();
        foreach my $file ( _read_dir($archive) ) {
            if ( $file =~ m{\.bz2$} && !-e $file . '.bz2.bz2' ) {    # I don't believe this is correct
                next;
            }
            $tar->add_files("$archive/$file");
        }
        $tar->write( $archive . '.tar' );
        system 'bzip2', $bz2_opt, $archive . '.tar';
        unlink $archive . '.tar';
    }

    if ( !chdir $archive ) {
        Carp::cluck "Unable to complete process. Unable to chdir to $archive: $!";
        return;
    }
    if (@files) {
        foreach my $file (@files) {
            system 'bzip2', $bz2_opt, $file if -f $file;
        }
        cPanel::SyncUtil::_sync_touchlock_pwd($args_hr);
    }
    else {
        cPanel::SyncUtil::_sync_touchlock_pwd($args_hr);
    }

    if ( !chdir $pwd ) {
        Carp::cluck "Failed to return back to directory $pwd: $!";
        return;
    }
    return 1;
}

sub _sync_touchlock_pwd {
    my $verbose = $_[0];
    my $args_hr = ref($verbose) ? $verbose : { 'verbose' => $verbose };

    $|++;
    require Cwd;
    my $cwd = Cwd::getcwd();

    print "$0 [$> $< : $cwd] Building .cpanelsync file...\n";

    my @files = split( /\n/, `find .` );

    my %oldmd5s;
    if ( -e '.cpanelsync' ) {
        open my $cps_fh, '<', '.cpanelsync' or die "$cwd/.cpanelsync read failed: $!";
        while (<$cps_fh>) {
            chomp;
            my ( $ftype, $rfile, $perm, $extra ) = split( /===/, $_ );
            $oldmd5s{$rfile} = $extra if $ftype eq 'f';
        }
        close $cps_fh;
    }

    open my $cpsw_fh, '>', '.cpanelsync' or die "$cwd/.cpanelsync write failed: $!";

  FILE:
    foreach my $file (@files) {
        if ( $file =~ /\/\.cpanelsync$/ || $file =~ /\/\.cpanelsync.lock$/ ) {
            next FILE;
        }
        elsif ( $file =~ m/===/ ) {
            Carp::cluck "improper file name detected: $file\n";
            next FILE;
        }

        if ( $file =~ /\.bz2$/ ) {
            my $tfile = $file;
            $tfile =~ s/\.bz2$//g;
            next FILE if -e $file && -e $tfile;
        }

        my $perms = ref( $args_hr->{'get_mode_string'} ) eq 'CODE' ? ( $args_hr->{'get_mode_string'}->($file) || 0 ) : get_mode_string($file);

        if ( -l $file ) {
            my $point = readlink($file);
            print {$cpsw_fh} "l===$file===$perms===$point\n";
        }
        elsif ( -d $file ) {
            print {$cpsw_fh} "d===$file===$perms\n";
        }
        else {
            print "Warning: zero sized file $file\n" if -z $file && $args_hr->{'verbose'};
            my $mtime  = ( stat(_) )[9];
            my $md5sum = Digest::MD5::File::file_md5_hex($file);
            my $sha    = Digest::SHA->new('512');
            $sha->addfile($file);
            my $sha512 = $sha->hexdigest;
            if ( exists $oldmd5s{$file} && $md5sum ne $oldmd5s{$file} ) {
                unlink $file . '.bz2';
                system( 'bzip2', '-kf', $file );
            }
            elsif ( -e $file . '.bz2' ) {
                if ( $mtime > ( stat(_) )[9] ) {
                    unlink $file . '.bz2';
                    system( 'bzip2', '-kf', $file );
                }
            }
            else {
                system( 'bzip2', '-kf', $file );
            }
            print {$cpsw_fh} "f===$file===$perms===$md5sum===$sha512\n";
        }
    }
    print {$cpsw_fh} ".\n";
    close $cpsw_fh;

    system qw(bzip2 -fk .cpanelsync);

    print "Done\n";

    system qw(touch .cpanelsync.lock);

    return 1;    # make more robust
}

sub _get_opts_hash {
    require Getopt::Std;
    my ( $args, $opts_ref ) = @_;

    $opts_ref = {} if ref $opts_ref ne 'HASH';
    Getopt::Std::getopts( $args, $opts_ref );

    return wantarray ? %{$opts_ref} : $opts_ref;
}

sub build_cpanelsync {
    my ( $dir, $verbose ) = @_;
    my $args_hr = ref($verbose) ? $verbose : { 'verbose' => $verbose };

    my $is_ok = 1;
    if ( !$dir || !-d $dir ) {
        Carp::croak "Invalid directory";
    }

    print "$0 [$> $< : $dir] Building .cpanelsync file...\n" if $args_hr->{'verbose'};

    my $pwd = Cwd::getcwd();
    if ( !chdir $dir ) {
        Carp::croak "Unable to chdir to $dir: $!";
    }

    my @files = _read_dir_recursively('.');

    my %oldmd5s;
    if ( -e '.cpanelsync' ) {
        open my $cps_fh, '<', '.cpanelsync' or Carp::croak "$dir/.cpanelsync read failed: $!";
        while ( my $line = readline $cps_fh ) {
            next if $line !~ m/^f/;
            chomp $line;
            my ( $ftype, $rfile, $perm, $extra ) = split( /===/, $line );
            $oldmd5s{$rfile} = $extra;
        }
        close $cps_fh;
    }

    open my $cpsw_fh, '>', '.cpanelsync' or Carp::croak "$dir/.cpanelsync write failed: $!";

  FILE:
    foreach my $file (@files) {
        next FILE if ( $file eq './.cpanelsync' || $file eq './.cpanelsync.lock' );

        if ( $file =~ m/===/ ) {
            Carp::cluck "Encountered improper file name: $file";
            next FILE;
        }

        # Skip cpanelsync compressed files
        elsif ( $file =~ m/\.bz2$/ ) {
            my $tfile = $file;
            $tfile =~ s/\.bz2$//g;
            next FILE if -e $tfile;
        }

        my $perms = ref( $args_hr->{'get_mode_string'} ) eq 'CODE' ? ( $args_hr->{'get_mode_string'}->($file) || 0 ) : get_mode_string($file);

        if ( -l $file ) {
            my $point = readlink($file);
            print {$cpsw_fh} "l===$file===$perms===$point\n";
        }
        elsif ( -d $file ) {
            print {$cpsw_fh} "d===$file===$perms\n" or Carp::croak "Unable write $dir/.cpanelsync: $!";
        }
        else {
            print "Warning: zero sized file $file\n" if -z $file && $args_hr->{'verbose'};
            my $mtime  = ( stat(_) )[9];
            my $md5sum = Digest::MD5::File::file_md5_hex($file);
            my $sha    = Digest::SHA->new('512');
            $sha->addfile($file);
            my $sha512 = $sha->hexdigest;
            if ( exists $oldmd5s{$file} && $md5sum ne $oldmd5s{$file} ) {    # unlink archive if file changed
                unlink $file . '.bz2';
            }
            elsif ( -e $file . '.bz2' && $mtime > ( stat(_) )[9] ) {         # unlink archive if file is newer than archive
                unlink $file . '.bz2';
            }
            print {$cpsw_fh} "f===$file===$perms===$md5sum===$sha512\n" or Carp::croak "Unable write $dir/.cpanelsync: $!";
        }
    }
    print {$cpsw_fh} ".\n" or Carp::croak "Unable write $dir/.cpanelsync: $!";
    close $cpsw_fh or Carp::croak "Unable to properly save $dir/.cpanelsync: $!";

    if ( open my $lock_fh, '>>', '.cpanelsync.lock' ) {
        print {$lock_fh} '';
        close $lock_fh;
    }
    else {
        Carp::cluck "Unable to touch $dir/.cpanelsync.lock: $!";
        $is_ok = 0;
    }

    if ( !chdir $pwd ) {
        Carp::cluck "Failed to return to $pwd: $!";
        $is_ok = 0;
    }

    print "Done\n" if $args_hr->{'verbose'};
    return $is_ok;
}

sub compress_files {
    my ( $dir, $verbose ) = @_;
    if ( !$dir || !-d $dir ) {
        Carp::croak "Invalid directory";
    }

    my $cpanelsync      = File::Spec->catfile( $dir, '.cpanelsync' );
    my $cpanelsync_lock = File::Spec->catfile( $dir, '.cpanelsync.lock' );
    if ( !-e $cpanelsync || -z _ || !-e $cpanelsync_lock ) {
        build_cpanelsync( $dir, $verbose );
    }

    my $pwd = Cwd::cwd();

    if ( !chdir $dir ) {
        Carp::croak "Unable to chdir to directory $dir: $!";
    }

    my @to_bzip_files = get_files_from_cpanelsync('.cpanelsync');
    foreach my $file ( @to_bzip_files, '.cpanelsync' ) {
        next if $file =~ m/\.bz2$/;
        if ( -e $file . '.bz2' ) {
            my $archive_mtime = ( stat(_) )[9];
            if ( ( stat($file) )[9] > $archive_mtime ) {
                unlink $file . '.bz2' or Carp::cluck "Unable to remove old archive $file.bz2: $!";
            }
            else {
                next;    # Only update files if the archive mtime is less than the source
            }
        }
        if ( !-e $file ) {
            Carp::croak "Missing file $file";
        }
        bzip_file( $file, $verbose ) or Carp::croak "Failed to compress $file";
    }

    my $tar = Archive::Tar->new();
    foreach my $file (@to_bzip_files) {
        $tar->add_files($file);
    }
    if ( !chdir $pwd ) {
        Carp::croak "Unable to chdir to directory $pwd: $!";
    }
    $tar->write( $dir . '.tar' );
    bzip_file( $dir . '.tar', $verbose ) or Carp::croak "Failed to compress $dir.tar";
    unlink $dir . '.tar';

    return 1;
}

sub get_files_from_cpanelsync {
    my $cpanelsync_file = shift;
    if ( !$cpanelsync_file || !-e $cpanelsync_file ) {
        if ( -e '.cpanelsync' ) {
            $cpanelsync_file = '.cpanelsync';
        }
        else {
            Carp::croak "Unable to locate cpanelsync file";
        }
    }
    my @files;
    if ( open my $cpanelsync_fh, '<', $cpanelsync_file ) {
        while ( my $line = readline $cpanelsync_fh ) {
            next if $line !~ m/^f/;
            my ( $ftype, $rfile, $perm, $extra ) = split( /===/, $line );
            push @files, $rfile;
        }
        close $cpanelsync_fh;
    }
    else {
        Carp::croak "Unable to read $cpanelsync_file: $!";
    }
    return wantarray ? @files : \@files;
}

sub bzip_file {
    my ( $file, $verbose ) = @_;
    my $bz2_opt = $verbose ? '-fkv' : '-fk';
    return if !-f $file;
    if ( !$bzip ) {
        _get_bzip_binary();
    }
    system $bzip, $bz2_opt, $file;
    return if !-e $file . '.bz2';
    return 1;
}

sub _get_bzip_binary {
    return $bzip if $bzip;
    foreach my $dir ( split( /:/, $ENV{'PATH'} ) ) {
        if ( -x File::Spec->catfile( $dir, 'bzip2' ) ) {
            $bzip = File::Spec->catfile( $dir, 'bzip2' );
            last;
        }
    }
    if ( !$bzip ) {
        Carp::croak "Missing bzip2";
    }
    return $bzip;
}

1;

__END__

=head1 NAME

cPanel::SyncUtil - Perl extension for creating utilities that work with cpanelsync aware directories

=head1 SYNOPSIS

  use cPanel::SyncUtil;

=head1 DESCRIPTION

These utility functions can be used to in scripts that create and work with cpanelsync environments. 

=head1 EXAMPLE

See scripts/cpanelsync_build for a working example that can be used to build cPanel's cPAddon Vendor cpanelsync directory for your website.

=head1 EXPORT

None by default, all functions are exportable if you wish:

    use cPanel::SyncUtil qw(_raw_dir);
    
    use cPanel::SyncUtil qw(:all);

=head1 FUNCTIONS

=head2 build_cpanelsync

Builds the .cpanelsync database for the given directory. Arguments are a directory (required) and a boolean to turn on verbose output.

The second argument can also be a hashref with the following keys:

=over 4

=item 'verbose'

The value is a boolean to turn on verbose output.

=item 'get_mode_string'

The value can be a coderef that takes the path you are interested in and returns a stringified mode value.

It defaults to cPanel::SycnUtil::get_mode_string() which does not preserve setuid for security.

If you have binaries that need to be setuid you can use \&cPanel::SycnUtil::get_mode_string_preserve_setuid or roll your own instead (e.g. to only preserve setuid on specific ones and warn about files that are setuid that need review).

=back

=head2 compress_files

Creates the compressed files for the given directory. Arguments are a directory (required) and a boolean to turn on verbose output.

If no .cpanelsync database is located then build_cpanelsync will be called prior to compressing and files.

=head2 _chown_pwd_recursively

Takes as its first argument a user that matches ^\w+$ (and optionally a group as its second argument, also matching ^\w+$)
and recursively chown's the current working directory to the given user (and group if given).

Currently the return value is from a system() call to chown.

=head2 get_files_from_cpanelsync

Returns an array (array ref in scalar context) of files in a given cpanelsync file. If none is passed it uses the one in the current directory.

=head2 bzip_file

Creates the .bz2 version of the given file. A second boolean argument can be passed for verbosity. Returns true if it worked false otherwise.

=head2 get_mode_string

Takes a path and returns a string suitable the .cpanelsync format and oct().

For security, it does not retain setuid and is the default "mode determining" function. Alternate "mode determining" funcionality can be had as documented in functions where it is applicable.

=head2 get_mode_string_preserve_setuid

Takes a path and returns a string suitable the .cpanelsync format and oct().

This will retain setuid unless the given file is a symlink.

=head2 _read_dir_recursively

Returns an array (array ref in scalar context ) of all files recursively in the given directory.

    @articles =  @files;

The list is sorted by directories, files, then symlinks and those are each sorted case-insensitively

You can add file names to ignore as keys in %cPanel::SyncUtil::ignore_name which has by default '.svn' and '.git'.

The name can be the file name only or the path (that will start w/ the path given to _read_dir_recursively()).

=head2 _chown_recursively()

Like _chown_pwd_recursively but takes a third argument of the path to process. 

It can take 2 args : 'user, dir' or 3 args: 'user, group, dir'

=head2 _safe_cpsync_dir

Returns true if the given argument is a directory that it is safe to be cpanelsync'ified.

See the simple, scripts/cpanelsync_build_dir script for example useage while recursing directories.

=head2 _raw_dir

This function makes the .tar and .bz2 version of the file system.

Its arguments are the following:

   _raw_dir($base, $archive, $verbose, @files);

$base and $archive are the only required arguments.

$archive is a directory in $base.

It will chdir in $base and the process the directory $archive

If $verbose is true, output will be verbose.

$verbose can also be a hashref with the following keys:

=over 4

=item 'verbose'

The value is a boolean to turn on verbose output.

=item 'get_mode_string'

The value can be a coderef that takes the path you are interested in and returns a stringified mode value.

It defaults to cPanel::SycnUtil::get_mode_string() which does not preserve setuid for security.

If you have binaries that need to be setuid you can use \&cPanel::SycnUtil::get_mode_string_preserve_setuid or roll your own instead (e.g. to only preserve setuid on specific ones and warn about files that are setuid that need review).

=back

If @files is specified each item in it is also processed.

Each item in @files must be a file (-f) in $base/$archive.

If it returns false the error is in $!

    _raw_dir($base, $archive, $verbose, @files) 
        or Carp::croak "_raw_dir($base, $archive, $verbose, @files) failed: $!";

Its very important to check the return value because if its failed its possible you will not be in the directory you think and then subsequent file operations will either fail or not work like you expect. Plus if its returned false then there is either a file system problem or the input to the function is not valid. In other words, if it fails you need to resolve the problem before continuing so croaking()ing is a good idea generally.

_sync_touchlock_pwd is then run on $base/$archive so that its now a cpanelsync directory

=head2 _get_opts_hash 

Shortcut to get a hash (in array context) or hash ref (in scalar context) of the script using this module's command line options.

Takes the same exact input as L<Getopt::Std> getopts()

=head2 _sync_touchlock_pwd

Creates the .cpanelsync file (and its .bz2 version) and .cpanelsync.lock for the current working directory

The argument can be a boolean to turn on verbose output or a hashref with the following keys:

=over 4

=item 'verbose'

The value is a boolean to turn on verbose output.

=item 'get_mode_string'

The value can be a coderef that takes the path you are interested in and returns a stringified mode value.

It defaults to cPanel::SycnUtil::get_mode_string() which does not preserve setuid for security.

If you have binaries that need to be setuid you can use \&cPanel::SycnUtil::get_mode_string_preserve_setuid or roll your own instead (e.g. to only preserve setuid on specific ones and warn about files that are setuid that need review).

=back

=head2 _read_dir

Shortcut to L<File::Slurp>'s read_dir

=head2 _write_file

Shortcut to L<File::Slurp>'s write_file

=head2 _lock

Locks the given directories.

    _lock(qw(foo bar baz));

=head2 _unlock

Unlocks the given directories.

    _unlock(qw(foo bar baz));

=head1 Your webserver and cpanelsync aware directories

Since a cpanelsycn directory is meant for downloading files you need to have the 
webserver handle files in the given path differently than it normally does.

For example typically you may have .cgi set up to so that it is executed and 
it's output retuned to the user. If it in a cpanelsync directory then you want 
users to download the source code of the .cgi file.

Here is an example of one way to configure this behavior in Apache 2.0 and Apache 2.2:

    <Directory /path/to/cpanelsync/dir>
        # ForceType and Header are not strictly necessary but 
        # may help ensure browsers can figure out what you want
        ForceType application/octet-stream
        Header set Content-Disposition attachment
        DefaultType application/octet-stream
        SetHandler default
    </Directory>

Note: You could also set the "filename" for the "attachment" by using rewrite 
rules to set an environment variable and use that variable in the "Header set" 
above. That is typically not necessary and beyond the scope of this document.

=head1 SEE ALSO

L<cPanel>, L<http://www.cpanel.net>

=head1 TODO

replace system() calls with perl versions.

anything mentioned in the source

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 cPanel, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
