package WWW::ConfixxBackup::FTP;

use strict;
use warnings;
use Net::FTP;

our $VERSION = '0.04';

sub new{
    my ($class,%args) = @_;
    my $self = {};
    bless $self,$class;
    
    $self->debug( sub{ print join "\n", @_ } );
    $self->DEBUG(0);
    
    $self->password($args{password});
    $self->user($args{user});
    $self->server($args{server});
    $self->prefix( '' );
    
    return $self;
}# new

sub prefix{
    my ($self,$prefix) = @_;
    
    $self->{__prefix} = $prefix if scalar @_ > 1;
    return $self->{__prefix};
}

sub login{
    my ($self) = @_;
    if( ref($self->ftp) eq 'Net::FTP' ){
        my $res = $self->ftp->login($self->user,$self->password);
        
        if( $self->DEBUG ){
            my $msg = $res ? 'FTP server: logged in' :
                             'Error: FTP server: cannot login .. ' . $self->ftp->message;
            $self->debug->( $msg );
        }
        
        return 0 unless $res;
    }
    else{
        return 0;
    }
    return 1;
}# login

sub download{
    my ($self,$path) = @_;
    $path ||= '.';
    my $error = "";
    eval{
        $self->ftp->cwd('/backup');
        for my $file ( qw/mysql.tar.gz files.tar.gz html.tar.gz/ ){
            $self->ftp->binary;
            my $res = $self->ftp->get( $file, $path . '/' . $self->prefix . $file );
            if( $self->DEBUG ){
                my $msg = $res ? "Downloaded $file" : "Error: Cannot download $file : " . $self->ftp->message;
                $self->debug->( $msg );
            }
        }
        1;
    } or $error = $@;
    
    if( $error and $self->DEBUG ){
        if( $error =~ /Can't call method/ ){
            $error = "Can't connect to FTP server";
        }
        $self->debug->( "Error: cannot download files: $error" );
    }
    
    return if($error);
    return 1;
}# download

sub password{
    my ($self,$pwd) = @_;
    $self->{password} = $pwd if(defined $pwd);
    return $self->{password};
}# password

sub user{
    my ($self,$user) = @_;
    $self->{user} = $user if(defined $user);
    return $self->{user};
}# user

sub server{
    my ($self,$server) = @_;
    $self->{server} = $server if(defined $server);
    return $self->{server};
}# server

sub ftp{
    my ($self) = @_;
    unless(ref($self->{ftp}) eq 'Net::FTP'){
        $self->{ftp} = Net::FTP->new(
            $self->server,
            Passive => 1,
            #Debug   => 1,
        );
    }
    return $self->{ftp};
}# mech

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
    }

    return $self->{__DEBUG};
}

sub DESTROY{
    my ($self) = @_;
    $self->ftp->quit if( ref($self->ftp) eq 'Net::FTP' );
}

1;

__END__
=pod

=head1 NAME

WWW::ConfixxBackup::FTP - the FTP client for WWW::ConfixxBackup

=head1 SYNOPSIS

  use WWW::ConfixxBackup::FTP;
  
  my $ftp = WWW::ConfixxBackup::FTP->new(server => 'server');
  $ftp->user('username');
  $ftp->password('password');
  
  $ftp->login;
  $ftp->download('/path/for/download');

=head1 METHODS

=head2 new

=head2 user

=head2 password

=head2 server

=head2 login

=head2 download

=head2 ftp

=head2 prefix

=head2 debug

=head2 DEBUG

=head1 SEE ALSO

  Net::FTP
  
=head1 AUTHOR

Renee Baecker, E<lt>module@renee-baecker.deE<gt>

=head1 LICENSE

2006 - 2008 by Renee Baecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut