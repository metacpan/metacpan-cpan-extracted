package WWW::ConfixxBackup;

use 5.006001;
use strict;
use warnings;
use WWW::ConfixxBackup::Confixx;
use WWW::ConfixxBackup::FTP;

our $VERSION = '0.1001';

sub new{
    my ($class,%args) = @_;
    my $self = bless {},$class;
    
    $self->waiter(120);
    $self->file_prefix( '' );
    
    $self->debug( sub{ print join "\n", @_ } );
    $self->DEBUG(0);
    
    my @unwanted = (qr/login$/, qr/^backup/, qr/download$/, qr/^_/, qr/errstr/);
    
    for my $key ( keys %args ){
        next if grep{ $key =~ $_ }@unwanted;
        if( my $sub = $self->can( $key ) ){
            $sub->( $self, $args{$key} );
        }
    }
    
    return $self;
}# new

sub http_proxy{
    my ($self,$proxy) = @_;
    
    $self->{_http_proxy} = $proxy if @_ == 2;
    return $self->{_http_proxy};
}

sub ftp_user{
    my ($self,$user) = @_;
    $self->{ftp_user} = $user if(defined $user);
    return $self->{ftp_user};
}# ftp_user

sub ftp_server{
    my ($self,$server) = @_;
    $self->{ftp_server} = $server if(defined $server);
    return $self->{ftp_server};
}# ftp_server

sub ftp_password{
    my ($self,$password) = @_;
    $self->{ftp_password} = $password if(defined $password);
    return $self->{ftp_password};
}#ftp_password

sub user{
    my ($self,$user) = @_;
    if(defined $user){
       $self->ftp_user($user);
       $self->confixx_user($user);
    }
    return $self->ftp_user;
}# user

sub server{
    my ($self,$server) = @_;
    if(defined $server){
        $self->ftp_server($server);
        $self->confixx_server($server);
    }
    return $self->ftp_server;
}# server

sub password{
    my ($self,$password) = @_;
    if(defined $password){
        $self->ftp_password($password);
        $self->confixx_password($password);
    }
    return $self->ftp_password;
}# password

sub confixx_user{
    my ($self,$user) = @_;
    $self->{confixx_user} = $user if(defined $user);
    return $self->{confixx_user};
}# confixx_user

sub confixx_server{
    my ($self,$server) = @_;
    $self->{confixx_server} = $server if(defined $server);
    return $self->{confixx_server};
}# confixx_server

sub confixx_password{
    my ($self,$password) = @_;
    $self->{confixx_password} = $password if(defined $password);
    return $self->{confixx_password};
}# confixx_pasword

sub confixx_version{
    my ($self,$version) = @_;
    $self->{_confixx_version} = $version if defined $version;
    return $self->{_confixx_version};
}

sub available_confixx_versions{
    my ($self) = @_;
    return WWW::ConfixxBackup::Confixx->available_confixx_versions;
}

sub default_confixx_version{
    return WWW::ConfixxBackup::Confixx->default_version;
}

sub login{
    my ($self) = @_;
    $self->_reset_errstr;
    $self->ftp_login     or $self->_add_errstr('' . $self->ftp_server);
    $self->confixx_login or $self->_add_errstr('' . $self->confixx_server);
    
    unless($self->errstr){
        return 1;
    }
    
    return;
}# login

sub ftp_login{
    my ($self) = @_;
    $self->{FTP} = WWW::ConfixxBackup::FTP->new(
        user     => $self->ftp_user,
        password => $self->ftp_password,
        server   => $self->ftp_server,
    );
    $self->{FTP}->debug( $self->debug );
    $self->{FTP}->DEBUG( $self->DEBUG );
    $self->{FTP}->login;
    
    return if ref($self->{FTP}->ftp) ne 'Net::FTP';
    return 1;
}# ftp_login

sub confixx_login{
    my ($self) = @_;
    $self->{CONFIXX} = WWW::ConfixxBackup::Confixx->new(
        user     => $self->confixx_user,
        password => $self->confixx_password,
        server   => $self->confixx_server,
    );
    $self->{CONFIXX}->debug( $self->debug );
    $self->{CONFIXX}->DEBUG( $self->DEBUG );
    $self->{CONFIXX}->proxy( $self->http_proxy ) if $self->http_proxy;
    $self->{CONFIXX}->login;
    
    if( ref($self->{CONFIXX}->mech) ne 'WWW::Mechanize' ){
        return;
    }
    return 1;
}# confixx_login

sub file_prefix{
    my ($self,$prefix) = @_;
    
    $self->{__prefix} = $prefix if scalar @_ > 1;
    return $self->{__prefix};
}

sub backup_download{
    my ($self,$path) = @_;
    
    $path ||= '.';
    $self->_reset_errstr();
    
    unless($self->{CONFIXX}){
        $self->confixx_login or $self->_add_errstr('Can\'t login to Confixx');
    }
    
    unless($self->{FTP}){
        $self->ftp_login or $self->_add_errstr('Can\'t login to FTP server');
    }
    
    $self->{CONFIXX}->confixx_version( $self->confixx_version );
    if(defined $path && $self->{CONFIXX} && $self->{FTP}){
        $self->{CONFIXX}->backup() or $self->_add_errstr('Can\'t create backup');
        sleep($self->{WAIT});
        $self->{FTP}->prefix( $self->file_prefix );
        $self->{FTP}->download($path) or $self->_add_errstr('Can\'t download');
    }
    
    unless($self->errstr){
        return 1;
    }
    
    return 0;
}# backup_download

sub _reset_errstr{
    my ($self) = @_;
    $self->{errstr} = '';
}

sub _add_errstr{
    my ($self,$msg) = @_;
    $self->{errstr} .= $msg if(defined $msg);
}

sub errstr{
    my ($self) = @_;
    return $self->{errstr}."\n";
}

sub waiter{
    my ($self,$wait) = @_;
    $self->{WAIT} = $wait if(defined $wait);
    return $self->{WAIT};
}# wait

sub detect_version{
    my ($self) = @_;
    
    $self->_reset_errstr;
    
    unless($self->{CONFIXX}){
        $self->confixx_login or
                $self->add_errstr('Can\'t login to Confixx' . $self->confixx_server);
    }
    if($self->{CONFIXX}){
        $self->{CONFIXX}->_detect_version;
        my $version = $self->{CONFIXX}->confixx_version;
        $self->confixx_version( $version );
        return $version;
    }

    return;
}

sub debug{
    my ($self,$coderef) = @_;
    
    if( @_ == 2 ){
        $self->DEBUG(1);
        $self->{__debug} = $coderef;
    }

    return $self->{__debug};
}

sub DEBUG{
    my ($self,$bool) = @_;
    
    if( @_ == 2 ){
        $self->{__DEBUG} = $bool;
        $self->{CONFIXX}->DEBUG( $bool ) if $self->{CONFIXX};
        $self->{FTP}->DEBUG( $bool )     if $self->{FTP};
    }

    return $self->{__DEBUG};
}

sub download{
    my ($self,$path) = @_;
    
    $self->_reset_errstr;
    
    unless($self->{FTP}){
      $self->ftp_login or 
              $self->add_errstr('Can\'t login to FTP server' . $self->ftp_server);
    }
    if($self->{FTP}){
      $self->{FTP}->download($path) or
              $self->add_errst('Can\'t download backup files');
    }
    
    unless($self->errstr){
        return 1;
    }
    return;
}# download

sub backup{
    my ($self) = @_;
    
    $self->_reset_errstr;
    
    unless($self->{CONFIXX}){
        $self->confixx_login or
                $self->add_errstr('Can\'t login to Confixx' . $self->confixx_server);
    }
    if($self->{CONFIXX}){
        $self->{CONFIXX}->confixx_version( $self->confixx_version );
        $self->{CONFIXX}->backup or
                $self->add_errstr('Can\'t create backup');
    }
    
    unless($self->errstr){
        return 1;
    }
    return 0;
}# backup


# Preloaded methods go here.

1;

__END__

=head1 NAME

WWW::ConfixxBackup - Create Backups with Confixx and download them via FTP

=head1 SYNOPSIS

  use WWW::ConfixxBackup;
  
  #shortes way (and Confixx and FTP use the same login data)
  my $backup = WWW::ConfixxBackup->new(user => 'user', password => 'user', server => 'server');
  my $path = './backups/today/';
  $backup->backup_download($path);
  
  #longer way (and different Confixx and FTP login data)
  my $backup = WWW::ConfixxBackup->new();
  $backup->ftp_user('ftp_user');
  $backup->ftp_password('ftp_password');
  $backup->ftp_server('server');
  $backup->ftp_login();
  $backup->confixx_user('confixx_user');
  $backup->confixx_password('confixx_password');
  $backup->confixx_server('confixx_server');
  $backup->confixx_login();
  $backup->confixx_version( 'confixx3.0' );
  $backup->backup();
  $backup->download($path);
  $backup->waiter($seconds);

=head1 DESCRIPTION

This module aims to simplify backups via Confixx and FTP. It logs in Confixx,
creates the backups and downloads the backups via FTP.

=head2 METHODS

=head3 new

  my $backup = WWW::ConfixxBackup->new();
  
creates a new C<WWW::ConfixxBackup> object.

=head3 user

  $backup->user('username');
  print $backup->user();

=head3 password

  $backup->password('password');
  print $backup->password();

=head3 server

  $backup->server('server');
  print $backup->server();

=head3 confixx_user

  $backup->confixx_user('confixx_username');
  print $backup->confixx_user();

=head3 confixx_password

  $backup->confixx_password('confixx_password');
  print $backup->confixx_password();

=head3 confixx_server

  $backup->confixx_server('confixx_server');
  print $backup->confixx_server();

=head3 confixx_version

  $backup->confixx_version( 'confixx3.0' );
  print $backup->confixx_version;

The parameters for the confixx script have been changed. If you know which version
is used, you can set the versionstring. If you don't know it, you ask for it via
C<detect_version>.

=head3 detect_version

  print $backup->detect_version;

=head3 available_confixx_versions

returns a list of all confixx versions (to be precisely versions of tools_backup2.php) 
that are supported by WWW::ConfixxBackup

=head3 default_confixx_version

returns the default value for confixx_version

=head3 http_proxy

  $backup->http_proxy( $proxy );

sets a proxy for HTTP requests

=head3 ftp_user

  $backup->ftp_user('ftp_user');
  print $backup->ftp_user();

=head3 ftp_password

  $backup->ftp_password('ftp_password');
  print $backup->ftp_password();

=head3 ftp_server

  $backup->ftp_server('ftp_server');
  print $backup->ftp_server();

=head3 file_prefix

  $backup->file_prefix( 'account_name' );
  print $backup->file_prefix

set/get a prefix for the backup files. This is necessary if you do parallel
backups.

=head3 confixx_login

  $backup->confixx_login();

=head3 ftp_login

  $backup->ftp_login();

login on FTP server

=head3 login

login on Confixx server and FTP server

=head3 backup

  $backup->backup();

Logs in to Confixx and creates the backups

=head3 download

  $backup->download('/path/to/directory');

downloads the three files that are created by Confixx:

=over 4

=item * mysql.tar.gz

=item * html.tar.gz

=item * files.tar.gz

=back

to the given path. If path is omitted, the files are downloaded to the
current directory.

=head3 backup_download

  $backup->backup_download('/path/to/directory/');

logs in to Confixx, create the backup files and downloads the three files that 
are created by Confixx:

=over 4

=item * mysql.tar.gz

=item * html.tar.gz

=item * files.tar.gz

=back

to the given path. If path is omitted, the files are downloaded to the
current directory.

=head3 waiter

  $backup->waiter(100);

sets the value for the sleep-time in seconds

=head3 errstr

  print $backup->errstr();

returns an error message when an error occured

=head3 debug

If you want more debugging, you can use your own subroutine. This subroutine will
get the debug message as an argument.

  $backup->debug( sub{ print @_ } );

=head3 DEBUG

With C<DEBUG> you can switch on and off the debugging mode. If you don't use your
own subroutine (see L<debug>), a default subroutine is used that just prints the
messages to STDOUT

  $backup->DEBUG(1);

The debugging mode is turned off by default.

=head1 SEE ALSO

  WWW::ConfixxBackup::Confixx
  WWW::ConfixxBackup::FTP
  WWW::Mechanize
  Net::FTP

=head1 AUTHOR

Renee Baecker, E<lt>module@renee-baecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

2006 - 2008 by Renee Baecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
