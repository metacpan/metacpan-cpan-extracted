package WWW::ConfixxBackup::Confixx;

use strict;
use warnings;
use WWW::Mechanize;
use HTTP::Cookies;
use HTTP::Request;

our $VERSION = '0.05';

my %map = (
    'confixx2.0' =>
      {
        backup_id    => '',
        backup_html  => '',
        backup_files => '',
        backup_mysql => '',
        html         =>  1,
        files        =>  1,
        mysql        =>  1,
      },
    'confixx3.0' =>
      {
        'selectAll' => 1,
        'backup[]'  => ['html','files','mysql'],
        action      => 'backup',
        destination => '/backup',
      }
);

my $default_version = 'confixx3.0';

sub new{
    my ($class,%args) = @_;
    my $self = bless {},$class;
    
    $self->debug( sub{ print join "\n", @_ } );
    $self->DEBUG(0);
    
    $self->password($args{password});
    $self->user($args{user});
    $self->server($args{server});
    $self->proxy( $args{proxy} );
    $self->confixx_version( defined $args{confixx_version} ? 
                                    $args{confixx_version} : 
                                    $default_version );
    
    return $self;
}# new

sub login{
    my ($self) = @_;
    
    if(ref($self->mech) eq 'WWW::Mechanize'){
        $self->mech->post(
             $self->server . '/login.php',
             {
                 username => $self->user, 
                 password => $self->password,
             
             }
        );
        
        if( $self->DEBUG ){
            $self->debug->( 'POST: ' . $self->server . '/login.php' );
            my $msg = $self->mech->success ? 'Got login page' :
                             'Error: cannot get login page : ' . $self->mech->response->status_line;
        }

        $self->mech->get( $self->server . '/user/' . $self->user . '/' );
        
        if( $self->DEBUG ){
            $self->debug->( 'GET: ' . $self->server . '/user/' . $self->user . '/' );
            my $msg = $self->mech->success ? $self->server . ': logged in' :
                                             'Error: ' . $self->server . ': cannot login .. ' . $self->mech->response->status_line;
            $self->debug->( $msg );
        }
        
        return unless($self->mech->success);
    }
    return 1;
}# login

sub proxy{
    my ($self,$proxy) = @_;
    
    $self->{_proxy} = $proxy if @_ == 2;
    return $self->{_proxy};
}

sub _detect_version{
    my ($self,$content) = @_;
    
    my %versions = (
        'confixx2.0' => [
              '<input type="hidden" name="backup_id" value="">',
              '<input type="hidden" name="backup_html" value="">',
              '<input type="hidden" name="backup_files" value="">',
              '<input type="hidden" name="backup_mysql" value="">',
              '<input type=checkbox checked name=html value="1"  >',
              '<input type=checkbox checked name=files value="1"  >',
              '<input type=checkbox checked name=mysql value="1"  >'
            ],
        'confixx3.0' => [
              '<input onclick="javascript:checkedAll(\'backup\',this.checked,0)" name="selectAll" value="1" checked type="checkbox" >',
              '<input name="backup[]" value="html" checked type="checkbox" >',
              '<input name="backup[]" value="files" checked type="checkbox" >',
              '<input name="backup[]" value="mysql" checked type="checkbox" >',
              '<input name="action" value="backup" type="hidden" >',
              '<input name="destination" value="/backup" type="hidden" >'
            ],
    );
    
    unless( $content ){
        $self->mech->get( $self->server . '/user/' . $self->user . '/tools_backup.php' );
        $content = $self->mech->content;
        #warn $content;
    }

    my @inputs  = $content =~ m!(<input[^>]+>)!ig;
       @inputs  = grep{ !/type=.?image/ }@inputs;
    
    my $version = "";
    for my $key ( keys %versions ){
        if( join( "", @inputs ) eq join( "", @{$versions{$key}} ) ){
            $version = $key;
            last;
        }
    }
      
    if( $version ){
        $self->confixx_version( $version );
    }

    if( $self->DEBUG ){
        my $msg = $version ? 'Detected version: ' . $version :
                             'Error: cannot detect version. Maybe a new Confixx Version.';
        $self->debug->( $msg );
    }
}

sub backup{
    my ($self) = @_;
    
    $self->_detect_version unless $self->confixx_version;
    
    $self->mech->post(
        $self->server . '/user/' . $self->user . '/tools_backup2.php',
        $map{$self->confixx_version},
    );
    
    if( $self->DEBUG ){
        my %fields = %{ $map{$self->confixx_version} };
        $self->debug->( 'POST: ' . $self->server . '/user/' . $self->user . '/tools_backup2.php' );
        $self->debug->( 'Parameters: ' . join( " , ", map{ $_ . " -> " . $fields{$_} }keys %fields ) );
        $self->debug->( 'Confixx Version: ' . $self->confixx_version );
        my $msg = $self->mech->success ? 'Called backup tool' :
                                         'Error: cannot call backup tool : ' . $self->mech->response->status_line;
    }
    
    return unless($self->mech->success);
    return 1;
}# create_backup

sub confixx_version{
    my ($self,$version) = @_;
    
    $self->{__version} = $version if defined $version;
    return $self->{__version};
}

sub available_confixx_versions{
    return sort keys %map;
}

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

sub mech{
    my ($self) = @_;
    my $subref = ( $self->DEBUG ) ? $self->debug : \&mech_warnings;
    unless(ref($self->{mechanizer}) eq 'WWW::Mechanize'){
        $self->{cookie_jar} = HTTP::Cookies->new();
        $self->{mechanizer} = WWW::Mechanize->new(
            quiet       => 1,
            onwarn      => $subref,
            ondie       => $subref,
            stack_depth => 1,
            cookie_jar  => $self->{cookie_jar},
        );
        $self->{mechanizer}->proxy( [qw/http https/], $self->proxy ) if $self->proxy;
        $self->{mechanizer}->get($self->server);
        
        
        if( $self->DEBUG ){
            $self->debug->( 'GET: ' . $self->server );
            my $msg = $self->{mechanizer}->success ? 'Got start page' :
                             'Error: cannot get start page : ' . $self->{mechanizer}->response->status_line;
            $self->debug->( $msg );
        }

        return [] unless($self->{mechanizer}->success);
    }
    return $self->{mechanizer};
}# mech

sub default_version{
    return $default_version;
}

sub mech_warnings{
  #print STDERR "HALLO";
}# mech_warnings

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

1;

__END__

=pod

=head1 NAME

WWW::ConfixxBackup::Confixx - the Confixx mechanism for WWW::ConfixxBackup

=head1 SYNOPSIS

=head1 METHODS

=head2 new

=head2 user

=head2 password

=head2 server

=head2 backup

=head2 mech_warnings

=head2 mech

=head2 login

=head2 proxy

=head2 confixx_version

=over 4

=item * confixx2.0

=over 4

=item * backup_id

=item * backup_html

=item * backup_files

=item * backup_mysql

=item * html

=item * files

=item * mysql

=back

=item * confixx3.0

=over 4

=item * selectAll

=item * backup[]

=over 4

=item * html

=item * files

=item * mysql

=back

=item * destination

=item * action

=back

=back

=head2 available_confixx_versions

returns a list of all confixx versions (to be precisely versions of tools_backup2.php) 
that are supported by WWW::ConfixxBackup

=head2 default_version

returns the default value for confixx_version

=head2 debug

=head2 DEBUG

=head1 SEE ALSO

  WWW::Mechanize
  
=head1 AUTHOR

Renee Baecker, E<lt>module@renee-baecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

2006 - 2008 by Renee Baecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
