package Webqq::Qun;
use strict;
use JSON;
use Storable qw(dclone);
use Scalar::Util qw(blessed reftype);
use base qw(Webqq::Qun::Authorize Webqq::Qun::Operate Webqq::Qun::Base);
use HTTP::Cookies;
use LWP::UserAgent;
use LWP::Protocol::https;
use Webqq::Qun::One;
use Webqq::Qun::Member;

our $VERSION = "1.5";
sub new {
    my $class  = shift;
    my %p = @_;
    my $agent = 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062';
    my $self = {
        cookie_jar  =>  HTTP::Cookies->new(hide_cookie2=>1),
        debug       =>  $p{debug} || 0,
        qq          =>  $p{qq},
        pwd         =>  $p{pwd}, 
        referer     =>  "http://qun.qq.com/member.html",
        token       =>  undef,
        _authorize  =>  {},
        data        =>  [],
        self        =>  {},
        friend      =>  [],
        is_load_data => 0,
        is_authorize => 0,
        
    };
    $self->{ua} = LWP::UserAgent->new(
        cookie_jar      =>  $self->{cookie_jar},
        agent           =>  $agent,
        timeout         =>  300,
        ssl_opts        =>  {verify_hostname => 0},
    );
    if($self->{debug}){
        $self->{ua}->add_handler(request_send => sub {
            my($request, $ua, $h) = @_;
            print $request->as_string;
            return;
        });
        $self->{ua}->add_handler(
            response_header => sub { my($response, $ua, $h) = @_;
            print $response->as_string;
            return;
        });
    }
    bless $self,$class;
}

sub each_qun {
    my $self = shift;
    $self->get_qun();
    my $callback = shift;
    $self->SUPER::each($self->{data},sub{
        my $q = shift;
        $callback->(bless $q,__PACKAGE__."::One");
    });
}
sub find_qun{
    my $self = shift;
    $self->get_qun();
    my %p = @_;
    my ($qun_type,$qun_number,$qun_name) = @p{qw(qun_type qun_number qun_name)};
    my @qun; 
    $self->SUPER::each($self->{data},sub{
        my $q = shift;
        return if defined $qun_type and $q->{qun_type} ne $qun_type;
        return if defined $qun_number and $q->{qun_number} ne $qun_number;
        return if defined $qun_name and $q->{qun_name} ne $qun_name;
        push @qun,bless dclone($q),__PACKAGE__ ."::One";
    }); 
    return wantarray?@qun:$qun[0];
}

sub find_member {
    my $self = shift;
    $self->get_qun();
    my %p = @_;
    my @member;
    my %filter = (
        sex         =>  1,
        card        =>  1,
        qq          =>  1,
        nick        =>  1,
        role        =>  1,
        bad_record  =>  1,
        qun_name    =>  1,
        qun_number  =>  1,
    );
    for my $k  (keys %p){
        unless(exists $filter{$k}){
            delete $p{$k} ;
            next;
        }
        delete $p{$k} unless defined $p{$k};
    }
    my @tmp;
    push @tmp,@{$_->{members}} for @{$self->{data}};    
    $self->SUPER::each(@tmp,sub{
        my $m = shift;
        for my $k (keys %p){
            return if $m->{$k} ne $p{$k};
        } 
        push @member,bless dclone($m),"Webqq::Qun::Member";
    });

    return wantarray?@member:$member[0];
}

sub each_member {
    my $self = shift;
    $self->get_qun();
    my $callback = shift;
    $self->SUPER::each($self->{data},sub{
        my $q = shift;
        for (@{$q->{members}}){
            my $m = dclone($_);
            bless $m,"Webqq::Qun::Member";
            $callback->($m);
        } 
    });      
}

sub del_member {
    my $self = shift;   
    my %opt;
    for my $p (@_){
        my ($qq,$qun_number);
        if(blessed($p) eq "Webqq::Qun::Member"){
            $qq            = $p->{qq};
            $qun_number  = $p->{qun_number};
            push @{ $opt{$qun_number} },$qq;
        }
    }
    for my $qun_number (keys %opt){
        $self->SUPER::del_member($qun_number,@{$opt{$qun_number}});
    }
}

sub add_member {
    my $self = shift;
    my %opt;
    for my $p (@_){
        my ($qq,$qun_number);
        if(blessed($p) eq "Webqq::Qun::Member"){
            $qq            = $p->{qq};
            $qun_number  = $p->{qun_number};
            push @{ $opt{$qun_number} },$qq; 
        }                                      
    }                                          
    for my $qun_number (keys %opt){          
        $self->SUPER::add_member($qun_number,@{$opt{$qun_number}});
    } 
}


sub set_admin {
    my $self = shift;
    my %opt;
    for my $p (@_){
        my ($qq,$qun_number);
        if(blessed($p) eq "Webqq::Qun::Member"){
            $qq            = $p->{qq};
            $qun_number  = $p->{qun_number};
            push @{ $opt{$qun_number} },$qq;
        }
    }
    for my $qun_number (keys %opt){
        $self->SUPER::set_admin($qun_number,@{$opt{$qun_number}});
    }
}

sub del_admin {
    my $self = shift;
    for my $p (@_){
        my ($qq,$qun_number);
        if(blessed($p) eq "Webqq::Qun::Member"){
            $qq            = $p->{qq};
            $qun_number  = $p->{qun_number};
        }
        $self->SUPER::del_admin($qun_number,$qq);
    }
}


sub set_card{
    my $self = shift;
    my $m = shift;
    my $card = shift;
    my %opt;
    my ($qq,$qun_number);
    if(blessed($m) eq "Webqq::Qun::Member"){
        $qq            = $m->{qq};
        $qun_number  = $m->{qun_number};
        push @{ $opt{$qun_number} },$qq;
    }
    for my $qun_number (keys %opt){
        $self->SUPER::set_card($qun_number,$qq,$card);
    }
}
1;
