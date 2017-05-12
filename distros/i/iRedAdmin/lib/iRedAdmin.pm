package iRedAdmin;

use Moo;
use Email::Valid;
use Encode;
use WWW::Mechanize;
use HTTP::Cookies;
use iRedAdmin::Admin;
use iRedAdmin::Domain;
use iRedAdmin::User;

our $VERSION = '0.04';

has 'url' => (
    is => 'ro',
    isa => sub {
        my $url = $_[0];
        $url =~ s/^https?:\/\///;
        $url =~ s/\/.*$//;
        die "Domain is invalid! $url" unless Email::Valid->address('domain@'.$url)
    }
);

has 'username' => (
    is => 'ro',
    isa => sub {
        die "Username is invalid!" unless Email::Valid->address($_[0])
    }
);

has 'password' => (
    is => 'ro',
    isa => sub {
        die "Password this empty!" unless $_[0] =~ /.{1,}/
    }
);

has 'cookie' => (
    is => 'ro',
    isa => sub {
        die "Cookie this empty!" unless $_[0] =~ /.{1,}/
    }
);

has 'lang' => (
    is => 'ro',
    default => sub {
        'en_US'
    }
);

has 'mech' => (is => 'ro', writer => 'set_mech');

has 'error' => (is => 'ro', writer => 'set_error');

sub BUILD {
    my $self = shift;
    
    my $cookie_jar = HTTP::Cookies->new(
        file => $self->cookie,
        ignore_discard => 1,
        autosave => 1
    );
    
    my $mech = WWW::Mechanize->new(
        autocheck => 0,
        cookie_jar => $cookie_jar,
        ssl_opts => {
            verify_hostname => 0
        }
    );
    
    $self->set_mech($mech);
    
    if (-e $self->cookie) {
        my $result = undef;
        open FILE, '<', $self->cookie or die $!;
        while (<FILE>) {
            chomp;
            $result = $_ unless $result;
        }
        close FILE;
        $result =~ s/\s//g if $result;
        unless($result){
            $self->_connect;
        }
    }else{
        $self->_connect;
    }
}

sub _connect {
    my $self = shift;
             
    $self->mech->post($self->_address . '/login',
        [
            username => $self->username,
            password => $self->password,
            login => 'Login',
            lang => $self->_lang($self->lang),
            save_pass => 'yes'
        ]    
    );
    
    if($self->mech->content =~ /login_form/){
        $self->mech->content =~ m!</strong> (.*?)</p>!i;
        $self->set_error(encode('utf-8', $1));
        return 0;
    }
    
    return 2;
};

sub _success {
    my $self = shift;
    
    if($self->mech->content =~ /login_form/){
        $self->_connect;
    }elsif($self->mech->content =~ /error/i) {
        $self->mech->content =~ m!</strong> (.*?)</p>!i;
        $self->set_error(encode('utf-8', $1));
        return 0;
    }else{
        return 1;
    }
}

sub _address {
    my $self = shift;
    
    my $url = $self->url;
    $url =~ s/\/$//;
    return $url;
}

sub _lang {
    my ($self, $value) = @_;
    
    my @lang = qw/
        cs_CZ
        de_DE
        en_US
        es_ES
        fi_FI
        fr_FR
        hu_HU
        it_IT
        ko_KR
        nl_NL
        pl_PL
        pt_BR
        ru_RU
        sl_SI
        zh_CN
        zh_TW
    /;
    
    if ($value =~ /\d/) {
        return $lang[$value-1] if $lang[$value-1];
        return 'en_US';
    }elsif($value =~ /\w/){
        return $value if grep(/^$value$/, @lang);
        return 'en_US';
    }else{
        return 'en_US';
    }
}

sub Admin {
    return iRedAdmin::Admin->new(ref => shift);
}

sub Domain {
    return iRedAdmin::Domain->new(ref => shift);
}

sub User {
    return iRedAdmin::User->new(ref => shift);
}

sub Logout {
    my $self = shift;
    $self->mech->get($self->url . '/logout');
    return 1 if $self->mech->content =~ /login_form/;
}

1;


__END__

=encoding utf8
 
=head1 NAME

iRedAdmin - API interface to the panel iRedMail (http://www.iredmail.org)

=cut

=head1 VERSION
 
Version 0.04
 
=cut
 
=head1 SYNOPSIS
 
    use iRedAdmin;
     
    my $iredadmin = iRedAdmin->new(
        url => 'https://hostname.mydomain.com/iredadmin',
        username => 'postmaster@mydomain.com',
        password => 'your_password',
        cookie => '/home/user/cookie.txt',
        lang => 3
    );
    
=cut
     
=head1 ATTRIBUTES

=head2 url

set url of panel iRedAdmin, example: 'https://hostname.mydomain.com/iredadmin'.

=cut

=head2 username

set username your account of panel.

=cut

=head2 password

set password your account of panel.

=cut

=head2 cookie

set path of file cookie, is optional but always will do login in panel and will be more slow.

=cut

=head2 lang

set language in access, return error in language selected, list:

1 or cs_CZ to Čeština

2 or de_DE to Deutsch (Deutsch)

3 or en_US to English (US) # is default

4 or es_ES to Español

5 or fi_FI to Finnish (Suomi)

6 or fr_FR to Français

7 or hu_HU to Hungarian

8 or it_IT to Italiano

9 or ko_KR to Korean

10 or nl_NL to Netherlands

11 or pl_PL to Polski

12 or pt_BR to Portuguese (Brazilian)

13 or ru_RU to Русский

14 or sl_SI to Slovenian

15 or zh_CN to 简体中文

16 or zh_TW to 繁體中文

=cut

=head2 error

get message error when methods return 0.

=cut

=head1 METHODS

=head2 Admin

get reference of instance Admin, see in L<iRedAdmin::Admin> for read document.

    my $admin = $iredadmin->Admin;
    
=cut

=head2 Domain

get reference of instance Domain, see in L<iRedAdmin::Domain> for read document.

    my $domain = $iredadmin->Domain;
    
=cut

=head2 User

get reference of instance User, see in L<iRedAdmin::User> for read document.

    my $user = $iredadmin->User;
    
=cut

=head2 Logout

logout user current.

=cut

=head1 AUTHOR

Lucas Tiago de Moraes, C<< <lucastiagodemoraes@gmail.com> >>

=cut

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have available.

=cut