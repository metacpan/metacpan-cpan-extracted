package Test::Mock::Net::FTP;
use strict;
use warnings;

use File::Copy;
use File::Spec::Functions qw( catdir splitdir rootdir catfile curdir rel2abs abs2rel );
use File::Basename;
use Cwd qw(getcwd);
use Carp;
use File::Path qw(make_path remove_tree);
use File::Slurp;

our $VERSION = '0.04';

# stopwords for Spellunker

=for stopwords pasv ascii alloc cwd cdup pwd rmdir dir mkdir ls filesize mdtm nlst retr stor stou appe login quot

=head1 NAME

Test::Mock::Net::FTP - Mock Object for Net::FTP

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Test::More;
  use Test::Mock::Net::FTP;

  Test::Mock::Net::FTP::mock_prepare(
      'somehost.example.com' => {
          'user1'=> {
              password => 'secret',
              dir      => ['./ftpserver', '/ftproot'],
              override => { 
                  ls => sub {
                      return qw(aaa bbb ccc);
                  },
              },
          },
      }
  );
  my $ftp = Test::Mock::Net::FTP->new('somehost.example.com');
  $ftp->login('user1', 'secret');
  $ftp->cwd('datadir');
  $ftp->get('file1');
  my @files = $ftp->ls();# => ('aaa', 'bbb', 'ccc');
  $ftp->quit();
  # or
  use Test::Mock::Net::FTP qw(intercept);
  some_method_using_ftp();

=head1 DESCRIPTION

Test::Mock::Net::FTP is Mock Object for Net::FTP. This module behave like FTP server, but only use local filesystem.(not using socket).

=head1 NOTICE

=over 4

=item
This module is implemented all Net::FTP's methods, but some methods are 'do nothing' currently. These methods behavior may be changed in future release.

=item
This module works in only Unix-like systems(does not work in MS-Windows).

=item
Some errors are not reproduced in this module.

=item
If you don't like default implementation of methods in this module, you can use override (or RT to me :-)

=back

=cut

my %mock_server;
my $cwd_when_prepared;

=head1 METHODS

=cut

=head2 C<mock_prepare( %params )>

prepare FTP server in your local filesystem.

=cut

sub mock_prepare {
    my %args = @_;
    %mock_server = %args;
    $cwd_when_prepared = getcwd();
}

=head2 C<mock_pwd()>

mock's current directory

=cut

sub mock_pwd {
    my ($self) = @_;
    return catdir($self->mock_physical_root, $self->_mock_cwd);
}

=head2 C<mock_physical_root()>

mock's physical root directory

=cut

sub mock_physical_root {
    my ($self) = @_;
    return $self->{mock_physical_root};
}

=head2 C<mock_connection_mode()>

return current connection mode (port or pasv)

=cut

sub mock_connection_mode {
    my ($self) = @_;

    return $self->{mock_connection_mode};
}

=head2 C<mock_port_no()>

return current port no

=cut

sub mock_port_no {
    my ($self) = @_;

    return $self->{mock_port_no};
}

=head2 C<mock_transfer_mode()>

return current transfer mode(ascii or binary)

=cut

sub mock_transfer_mode {
    my ($self) = @_;

    return $self->{mock_transfer_mode};
}

=head2 C<mock_command_history()>

return command history

  my $ftp = Test::Mock::Net::FTP->new('somehost');
  $ftp->login('somehost', 'passwd');
  $ftp->ls('dir1');
  my @history = $ftp->mock_command_history();
  # =>  ( ['login', 'somehost', 'passwd'], ['ls', 'dir1']);

=cut

sub mock_command_history {
    my ($self) = @_;

    return @{ $self->{mock_command_history} };
}

sub _push_mock_command_history {
    my ($self, $method_name, @args) = @_;
    shift @args; #discard $self;
    push @{ $self->{mock_command_history} }, [$method_name, @args];
}

=head2 C<mock_clear_command_history()>

clear command history

=cut

sub mock_clear_command_history {
    my ($self) = @_;

    $self->{mock_command_history} = [];
}


=head2 C<new( $host, %options )>

create new instance

=cut

sub new {
    my ($class, $host, %opts ) = @_;
    return if ( !exists $mock_server{$host} );

    my ($connection_mode, $port_no) = _connection_mode_and_port_no(%opts);

    my $self = {
        mock_host            => $host,
        mock_physical_root   => '',
        mock_server_root     => '',
        mock_transfer_mode   => 'ascii',
        mock_connection_mode => $connection_mode,
        mock_port_no         => $port_no,
        message              => '',
        mock_command_history => [],
    };
    bless $self, $class;
}

sub _connection_mode_and_port_no {
    my (%opts) = @_;
    my $connection_mode = ((!defined $opts{Passive} && !defined $opts{Port} ) || !!$opts{Passive}) ? 'pasv' : 'port';
    my $port_no = $connection_mode eq 'pasv' ? ''
                                             : defined $opts{Port} ? $opts{Port}
                                                                   : '20';
    return ($connection_mode, $port_no);
}

=head2 C<login( $user, $password )>

login mock FTP server. this method IS NOT allowed to be overridden.

=cut

sub login {
    my ($self, $user, $pass) = @_;
    $self->_push_mock_command_history('login', @_);

    if ( $self->_mock_login_auth( $user, $pass) ) {# auth success
        my $cwd = getcwd();
        chdir $cwd_when_prepared;# chdir for absolute path
        my $mock_server_for_user = $mock_server{$self->{mock_host}}->{$user};
        my $dir = $mock_server_for_user->{dir};
        $self->{mock_physical_root} = rel2abs($dir->[0]) if defined $dir->[0];
        $self->{mock_server_root}   = $dir->[1];
        $self->{mock_cwd}           = rootdir();
        $self->{mock_override}      = $mock_server_for_user->{override};
        chdir $cwd;
        return 1;
    }
    $self->{message} = 'Login incorrect.';
    return;
}

sub _mock_login_auth {
    my ($self, $user, $pass) = @_;

    my $server_user     = $mock_server{$self->{mock_host}}->{$user};
    return if !defined $server_user; #user not found

    my $server_password = $server_user->{password};
    return $server_password eq $pass;
}

=head2 C<authorize( [$auth, [$resp]] )>

authorize.
default implementation is 'do nothing'. this method is allowed to be overridden.

=cut


=head2 C<mock_default_authorize( [$auth, [$resp]] )>

default implementation for authorize. this method should be used in overridden method.

=cut

sub mock_default_authorize {
    my ($self, $auth, $resp) = @_;
    return 1;
}

=head2 C<site( @args )>

execute SITE command. 
default implementation is 'do nothing'. this method is allowed to be overridden.

=cut


=head2 C<mock_default_site( @args )>

default implementation for site. this method should be used in overridden method.

=cut

sub mock_default_site {
    my ($self, @args) = @_;
    return 1;
}

=head2 C<ascii()>

enter ascii mode.
mock_transfer_mode() returns 'ascii'.
this method is allowed to be overridden.

=cut


=head2 C<mock_default_ascii()>

default implementation for ascii. this method should be used in overridden method.

=cut

sub mock_default_ascii {
    my ($self) = @_;
    $self->{mock_transfer_mode} = 'ascii';
}

=head2 C<binary()>

enter binary mode.
mock_transfer_mode() returns 'binary'.
this method is allowed to be overridden.

=cut


=head2 C<mock_default_binary()>

default implementation for binary. this method should be used in overridden method.

=cut

sub mock_default_binary {
    my ($self) = @_;
    $self->{mock_transfer_mode} = 'binary';
}

=head2 C<rename($oldname, $newname)>

rename remote file.
this method is allowed to be overridden.

=cut


=head2 C<mock_default_rename($oldname, $newname)>

default implementation for rename. this method should be used in overridden method.

=cut

sub mock_default_rename {
    my ($self, $oldname, $newname) = @_;
    unless( CORE::rename $self->_abs_remote($oldname), $self->_abs_remote($newname) ) {
        $self->{message} = sprintf("%s: %s\n", $oldname, $!);
        return;
    }
}

=head2 C<delete( $filename )>

delete remote file.
this method is allowed to be overridden.

=cut


=head2 C<mock_default_delete( $filename )>

default implementation for delete. this method should be used in overridden method.

=cut

sub mock_default_delete {
    my ($self, $filename) = @_;

    unless( unlink $self->_abs_remote($filename) ) {
        $self->{message} = sprintf("%s: %s\n", $filename, $!);
        return;
    }
}

=head2 C<cwd( $dir )>

change (mock) server current directory
this method is allowed to be overridden.

=cut


=head2 C<mock_default_cwd( $dir )>

default implementation for cwd. this method should be used in overridden method.

=cut

sub mock_default_cwd {
    my ($self, $dirs) = @_;

    if ( !defined $dirs ) {
        $self->{mock_cwd} = rootdir();
        $dirs = "";
    }

    # if an absolute path, start at root
    elsif ( $dirs =~ m|^/| ) {
        $self->{mock_cwd} = rootdir();
    }

    my $backup_cwd = $self->_mock_cwd;
    for my $dir ( splitdir($dirs) ) {
        $self->_mock_cwd_each($dir);
    }
    $self->{mock_cwd} =~ s/^$self->{mock_server_root}//;#for absolute path
    return $self->_mock_check_pwd($backup_cwd);
}

=head2 C<cdup()>

change (mock) server directory to parent
this method is allowed to be overridden.

=cut


=head2 C<mock_default_cdup()>

default implementation for cdup. this method should be used in overridden method.

=cut

sub mock_default_cdup {
    my ($self) = @_;
    my $backup_cwd = $self->_mock_cwd;
    $self->{mock_cwd} = dirname($self->_mock_cwd);# to updir
    return $self->_mock_check_pwd($backup_cwd);
}

=head2 C<pwd()>

return (mock) server current directory
this method is allowed to be overridden.

=cut


=head2 C<mock_default_pwd()>

default implementation for pwd. this method should be used in overridden method.

=cut 

sub mock_default_pwd {
    my ($self) = @_;
    return catdir($self->{mock_server_root}, $self->_mock_cwd);
}

sub _mock_cwd_each {
    my ($self, $dir) = @_;

    if ( $dir eq '..' ) {
        $self->cdup();
    }
    else {
        $self->{mock_cwd} = catdir($self->_mock_cwd, $dir);
    }
}

# check if mock server directory "phisically" exists.
sub _mock_check_pwd {
    my ($self, $backup_cwd) = @_;

    if ( ! -d $self->mock_pwd ) {
        $self->{mock_cwd} = $backup_cwd;
        $self->{message} = 'Failed to change directory.';
        return 0;
    }
    return 1;
}

=head2 C<restart( $where )>

restart. currently do_nothing
this method is allowed to be overridden.

=cut


=head2 C<mock_default_restart( $where )>

default implementation for restart. this method should be used in overridden method.

=cut

sub mock_default_restart {
    my ($self, $where) = @_;
    return 1;
}

=head2 C<rmdir( $dirname, $recursive_bool )>

rmdir to remove (mock) server. when $recursive_bool is true, dir is recursively removed.
this method is allowed to be overridden.

=cut


=head2 C<mock_default_rmdir( $dirname, $recursive_bool )>

default implementation for rmdir. this method should be used in overridden method.

=cut

sub mock_default_rmdir {
    my ($self, $dirname, $recursive_bool) = @_;
    if ( !!$recursive_bool ) {
        unless( remove_tree( $self->_abs_remote($dirname) ) ) {
            $self->{message} = sprintf("%s: %s", $dirname, $!);
            return;
        }
    }
    else {
        unless( CORE::rmdir $self->_abs_remote($dirname) ) {
            $self->{message} = sprintf("%s: %s", $dirname, $!);
            return;
        }
    }
}

=head2 C<mkdir( $dirname, $recursive_bool )>

mkdir to remove (mock) server. when $recursive_bool is true, dir is recursively create.
this method is allowed to be overridden.

=cut


=head2 C<mock_default_mkdir( $dirname, $recursive_bool )>

default implementation for mkdir. this method should be used in overridden method.

=cut

sub mock_default_mkdir {
    my ($self, $dirname, $recursive_bool) = @_;
    if ( !!$recursive_bool ) {
        unless( make_path( $self->_abs_remote($dirname) ) ) {
            $self->{message} = sprintf("%s: %s", $dirname, $!);
            return;
        }
    }
    else {
        unless( CORE::mkdir $self->_abs_remote($dirname) ) {
            $self->{message} = sprintf("%s: %s", $dirname, $!);
            return;
        }
    }
}

=head2 C<alloc( $size, [$record_size] )>

alloc. 
default implementation is 'do nothing'. this method is allowed to be overridden.

=cut


=head2 C<mock_default_alloc( $size, [$record_size] )>

default implementation for alloc. this method should be used in overridden method.

=cut

sub mock_default_alloc {
    my ($self, $size, $record_size) = @_;
    return 1;
}

=head2 C<ls( [$dir] )>

list file(s) in server directory.
this method is allowed to be overridden.

=cut


=head2 C<mock_default_ls( [$dir] )>

default implementation for ls. this method should be used in overridden method.

=cut

sub mock_default_ls {
    my ($self, $dir) = @_;

    my @ls = $self->_list_files($dir);
    my @result =  (defined $dir)? map{ catfile($dir, $_) } @ls : @ls;

    return @result if ( wantarray() );
    return \@result;
}

sub _list_files {
    my ($self, $dir) = @_;
    my $target_dir = $self->_relative_remote($dir);
    opendir my $dh, $target_dir or die $!;
    my @files = sort grep { $_ !~ /^\.?\.$/ } readdir($dh);
    closedir $dh;
    return @files;
}

=head2 C<dir( [$dir] )>

list file(s) with detail information(ex. filesize) in server directory.
this method is allowed to be overridden.

=cut


=head2 C<mock_default_dir( [$dir] )>

default implementation for dir. this method should be used in overridden method.

=cut 

sub mock_default_dir {
    my ($self, $dir) = @_;
    my $target_dir = $self->_relative_remote($dir);
    local $ENV{LC_ALL} = "C";
    my @dir = split(/\n/, `ls -l $target_dir`);

    return @dir if ( wantarray() );
    return \@dir;
}

=head2 C<get( $remote_file, [$local_file] )>

get file from mock FTP server
this method is allowed to be overridden.

=cut


=head2 mock_default_get( $remote_file, [$local_file] )

default implementation for get. this method should be used in overridden method.

=cut

sub mock_default_get {
    my($self, $remote_file, $local_file) = @_;
    $local_file = basename($remote_file) if ( !defined $local_file );
    unless( copy( $self->_abs_remote($remote_file),
                  $self->_abs_local($local_file) )   ) {
        $self->{message} = sprintf("%s: %s", $remote_file, $!);
        return;
    }

    return $local_file;
}


=head2 C<put( $local_file, [$remote_file] )>

put a file to mock FTP server
this method is allowed to be overridden.

=cut


=head2 C<mock_default_put( $local_file, [$remote_file] )>

default implementation for put. this method should be used in overridden method.

=cut

sub mock_default_put {
    my ($self, $local_file, $remote_file) = @_;
    $remote_file = basename($local_file) if ( !defined $remote_file );
    unless ( copy( $self->_abs_local($local_file),
                   $self->_abs_remote($remote_file) ) ) {
        carp "Cannot open Local file $remote_file: $!";
        return;
    }

    return $remote_file;
}

=head2 C<put_unique( $local_file, [$remote_file] )>

same as put() but if same file exists in server. rename to unique filename
(in this module, simply add suffix .1(.2, .3...). and suffix is limited to 1024)
this method is allowed to be overridden.

=cut


sub _unique_new_name {
    my ($self, $remote_file) = @_;

    my $suffix = "";
    my $newfile = $remote_file;
    for ( my $i=1; $i<=1024; $i++ ) {
        last if ( !-e $self->_abs_remote($newfile) );
        $suffix = ".$i";
        $newfile = $remote_file . $suffix;
    }
    return $newfile;
}

=head2 C<mock_default_put_unique( $local_file, [$remote_file] )>

default implementation for put_unique. this method should be used in overridden method.

=cut

sub mock_default_put_unique {
    my ($self, $local_file, $remote_file) = @_;
    $remote_file = basename($local_file) if ( !defined $remote_file );

    my $newfile = $self->_unique_new_name($remote_file);
    unless ( copy( $self->_abs_local($local_file),
                   $self->_abs_remote($newfile) ) ) {
        carp "Cannot open Local file $remote_file: $!";
        $self->{mock_unique_name} = undef;
        return;
    }
    $self->{mock_unique_name} = $newfile;
}


=head2 C<append( $local_file, [$remote_file] )>

put a file to mock FTP server. if file already exists, append file contents in server file.
this method is allowed to be overridden.

=cut


=head2 C<mock_default_append( $local_file, [$remote_file] )>

default implementation for append. this method should be used in overridden method.

=cut

sub mock_default_append {
    my ($self, $local_file, $remote_file) = @_;

    $remote_file = basename($local_file) if ( !defined $remote_file );
    my $local_contents = eval { read_file( $self->_abs_local($local_file) ) };
    if ( $@ ) {
        carp "Cannot open Local file $remote_file: $!";
        return;
    }
    write_file( $self->_abs_remote($remote_file), { append => 1 }, $local_contents);
}

=head2 C<unique_name()>

return unique filename when put_unique() called.
this method is allowed to be overridden.

=cut


=head2 C<mock_default_unique_name()>

default implementation for unique_name. this method should be used in overridden method.

=cut

sub mock_default_unique_name {
    my($self) = @_;

    return $self->{mock_unique_name};
}

=head2 C<mdtm( $file )>

returns file modification time in remote (mock) server.
this method is allowed to be overridden.

=cut

=head2 C<mock_default_mdtm()>

default implementation for mdtm. this method should be used in overridden method.

=cut

sub mock_default_mdtm {
    my ($self, $filename) = @_;
    my $mdtm = ( stat $self->_abs_remote($filename) )[9];
    return $mdtm;
}

=head2 C<size( $file )>

returns filesize in remote (mock) server.
this method is allowed to be overridden.

=cut


=head2 C<mock_default_size( $file )>

default implementation for size. this method should be used in overridden method.

=cut

sub mock_default_size {
    my ($self, $filename) = @_;
    my $size = ( stat $self->_abs_remote($filename) )[7];
    return $size;
}

=head2 C<supported( $cmd )>

supported. 
default implementation is 'do nothing'. this method is allowed to be overridden.

=cut


=head2 C<mock_default_supported( $cmd )>

default implementation for supported. this method should be used in overridden method.

=cut

sub mock_default_supported {
    my ($self, $cmd) = @_;
    return 1;
}


=head2 C<hash( [$filehandle_glob_ref], [$bytes_per_hash_mark] )>

hash.
default implementation is 'do nothing'. this method is allowed to be overridden.

=cut


=head2 C<mock_default_hash( [$filehandle_glob_ref], [$bytes_per_hash_mark] )>

default implementation for hash. this method should be used in overridden method.

=cut

sub mock_default_hash {
    my ($self, $filehandle_glob_ref, $bytes_per_hash_mark) = @_;
    return 1;
}


=head2 C<feature( $cmd )>

feature. currently returns list of $cmd.
this method is allowed to be overridden.

=cut


=head2 C<mock_default_feature( $cmd )>

default implementation for feature. this method should be used in overridden method.

=cut

sub mock_default_feature {
    my ($self, $cmd) = @_;
    return ($cmd);
}

=head2 C<nlst( [$dir] )>

nlst.
default implementation is 'do nothing'. this method is allowed to be overridden.

=cut

=head2 C<mock_default_nlst( [$dir] )>

default implementation for nlst. this method should be used in overridden method.

=cut

sub mock_default_nlst {
    my ($self, $dir) = @_;
    return 1;
}

=head2 C<list( [$dir] )>

list.
default implementation is 'do nothing'. this method is allowed to be overridden.

=cut


=head2 C<mock_default_list( [$dir] )>

default implementation for list. this method should be used in overridden method.

=cut

sub mock_default_list {
    my ($self, $dir) = @_;
    return 1;
}

=head2 C<retr( $file )>

retr.
default implementation is 'do nothing'. this method is allowed to be overridden.

=cut


=head2 C<mock_default_retr($file)>

default implementation for retr. this method should be used in overridden method.

=cut

sub mock_default_retr {
    my ($self, $file) = @_;
    return 1;
}

=head2 C<stor( $file )>

stor.
default implementation is 'do nothing'. this method is allowed to be overridden.

=cut


=head2 C<mock_default_stor( $file )>

default implementation for stor. this method should be used in overridden method.

=cut

sub mock_default_stor {
    my ($self, $file) = @_;
    return 1;
}

=head2 C<stou( $file )>

stou. currently do_nothing.

=cut


=head2 C<mock_default_stou( $file )>

default implementation for stor. this method should be used in overridden method.

=cut

sub mock_default_stou {
    my ($self, $file) = @_;
    return 1;
}

=head2 C<appe( $file )>

appe.
default implementation is 'do nothing'. this method is allowed to be overridden.

=cut


=head2 C<mock_default_appe( $file )>

default implementation for appe. this method should be used in overridden method.

=cut

sub mock_default_appe {
    my ($self, $file) = @_;
    return 1;
}

=head2 C<port( $port_no )>

specify data connection to port-mode.

after called this method, mock_connection_mode() returns 'port' and 
mock_port_no() returns specified $port_no.

this method is allowed to be overridden.

=cut


=head2 C<mock_default_port( $port_no )>

default implementation for port. this method should be used in overridden method.

=cut

sub mock_default_port {
    my ($self, $port_no) = @_;
    $self->{mock_connection_mode} = 'port';
    $self->{mock_port_no} = $port_no;
}

=head2 C<pasv()>

specify data connection to passive-mode.
after called this method, mock_connection_mode() returns 'pasv' and
mock_port_no() returns ''

this method is allowed to be overridden.

=cut


=head2 C<mock_default_pasv()>

default implementation for pasv. this method should be used in overridden method.

=cut

sub mock_default_pasv {
    my ($self) = @_;
    $self->{mock_connection_mode} = 'pasv';
    $self->{mock_port_no} = '';
}

=head2 C<pasv_xfer( $src_file, $dest_server, [$dest_file] )>

pasv_xfer.
default implementation is 'do nothing'. this method is allowed to be overridden.

=cut


=head2 C<mock_default_pasv_xfer( $src_file, $dest_server, [$dest_file] )>

default implementation for psv_xfer. this method should be used in overridden method.

=cut

sub mock_default_pasv_xfer {
    my ($self) = @_;
    return 1;
}


=head2 C<pasv_xfer_unique( $src_file, $dest_server, [$dest_file] )>

pasv_xfer_unique.
default implementation is 'do nothing'. this method is allowed to be overridden.

=cut


=head2 C<mock_default_pasv_xfer_unique( $src_file, $dest_server, [$dest_file] )>

default implementation for psv_xfer_unique. this method should be used in overridden method.

=cut

sub mock_default_pasv_xfer_unique {
    my ($self) = @_;
    return 1;
}

=head2 C<pasv_wait( $non_pasv_server )>

pasv_wait.
default implementation is 'do nothing'. this method is allowed to be overridden.

=cut


=head2 C<mock_default_pasv_wait( $non_pasv_server )>

default implementation for pasv_wait. this method should be used in overridden method.

=cut

sub mock_default_pasv_wait {
    my ($self) = @_;
    return 1;
}


=head2 C<abort()>

abort.
default implementation is 'do nothing'. this method is allowed to be overridden.

=cut


=head2 C<mock_default_abort()>

default implementation for abort. this method should be used in overridden method.

=cut

sub mock_default_abort {
    my ($self) = @_;
    return 1;
}

=head2 C<quit()>

quit.
default implementation is 'do nothing'. this method is allowed to be overridden.

=cut


=head2 C<mock_default_quit()>

default implementation for quit. this method should be used in overridden method.

=cut

sub mock_default_quit {
    my ($self) = @_;
    return 1;
}


=head2 C<quot( $cmd, @args )>

quot.
default implementation is 'do nothing'. this method is allowed to be overridden.

=cut


=head2 C<mock_default_quot( $cmd, @args )>

default implementation for quot. this method should be used in overridden method.

=cut

sub mock_default_quot {
    my ($self) = @_;
    return 1;
}


=head2 C<close()>

close connection mock FTP server.
default implementation is 'do nothing'. this method is allowed to be overridden.

=cut


=head2 C<mock_default_close()>

default implementation for close. this method should be used in overridden method.

=cut

sub mock_default_close {
    my ($self) = @_;
    return 1;
}

sub _mock_abs2rel {
    my ($self, $path) = @_;

    if (defined $path && $path =~ /^$self->{mock_server_root}/ ) { #absolute path
        $path =~ s/^$self->{mock_server_root}//;
    }
    return $path;
}

sub _relative_remote {
    my ($self, $path) = @_;

    $path = $self->_mock_abs2rel($path);

    return $self->mock_pwd if !defined $path;
    return catdir($self->mock_pwd, $path);
}


sub _abs_remote {
    my ($self, $remote_path) = @_;

    my $remote_dir = dirname($remote_path) eq curdir() ? $self->{mock_cwd} : dirname($remote_path) ;
    $remote_dir = $self->_mock_abs2rel($remote_dir);

    return catfile($self->{mock_physical_root}, $remote_dir, basename($remote_path))
}

sub _abs_local {
    my ($self, $local_path) = @_;

    my $root = rootdir();
    return $local_path if ( $local_path =~ m{^$root} );

    my $local_dir = dirname($local_path) eq curdir() ? getcwd() : dirname($local_path);
    return catfile($local_dir, basename($local_path));
}

=head2 C<message()>

return messages from mock FTP server
this method is allowed to be overridden.

=cut

sub message {
    my ($self) = @_;

    $self->_push_mock_command_history('message', @_);
    # do not clear $self->{message}, that's why this definition is still remain(not in AUTOLOAD)
    goto &{ $self->{mock_override}->{message} } if ( exists $self->{mock_override}->{message} );

    return $self->mock_default_message();
}

=head2 C<mock_default_message()>

default implementation for message. this method should be used in overridden method.

=cut

sub mock_default_message {
    my ($self) = @_;
    return $self->{message};
}

sub _mock_cwd {
    my ($self) = @_;
    return (defined $self->{mock_cwd}) ? $self->{mock_cwd} : "";
}


sub import {
    my ($package, @args) = @_;
    for my $arg ( @args ) {
        _mock_intercept() if ( $arg eq 'intercept' );
    }
}

sub _mock_intercept {
    use Net::FTP;
    no warnings 'redefine';
    *Net::FTP::new = sub {
        my $class = shift;#discard $class
        return Test::Mock::Net::FTP->new(@_);
    }
}

sub DESTROY {} #for AUTOLOAD

sub AUTOLOAD {
    my ($self) = @_;
    my $method = our $AUTOLOAD;
    $method =~ s/.*:://o;

    my @methods = (
        'unique_name',      'size',       'mdtm',
        'message',          'cwd',        'cdup',
        'put',              'append',     'put_unique',
        'get',              'rename',     'delete',
        'mkdir',            'rmdir',      'port',
        'pasv',             'binary',     'ascii',
        'quit',             'close',      'abort',
        'site',             'hash',       'alloc',
        'nlst',             'list',       'retr',
        'stou',             'stor',       'appe',
        'quot',             'supported',  'authorize',
        'feature',          'restart',    'pasv_xfer',
        'pasv_xfer_unique', 'pasv_wait',  'ls',
        'dir',              'pwd',
    );

    if( grep{ $_ eq $method } @methods ) {
        $self->_push_mock_command_history($method, @_);
        $self->{message} = '';

        if ( exists $self->{mock_override}->{$method} ) {# override in mock_prepare
            goto &{ $self->{mock_override}->{$method} }
        }
        else { #not overridden (call default method)
            goto &{ "mock_default_$method" };
        }
    }
}

1;


=head1 AUTHOR

Takuya Tsuchida E<lt>tsucchi at cpan.orgE<gt>

=head1 SEE ALSO

L<Net::FTP>

=head1 REPOSITORY

L<http://github.com/tsucchi/Test-Mock-Net-FTP>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009-2011 Takuya Tsuchida

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
