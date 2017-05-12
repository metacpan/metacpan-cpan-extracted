package Webqq::Qun::Authorize;
use strict;
use Carp;
use File::Temp qw/tempfile/;
use Webqq::Util qw(gen_url);
use Webqq::Encryption qw(pwd_encrypt pwd_encrypt_js);
sub authorize {
    my $self = shift;
    $self->{_authorize}{appid}  = 715030901;
    $self->{_authorize}{daid}   = 73;
    $self->{_authorize}{qq}     = $self->{qq};
    $self->{_authorize}{pwd}    = $self->{pwd};
    if(    
        $self->_prepare()
    &&  $self->_checkVC()
    &&  $self->_getimage()
    &&  $self->_login()
    &&  $self->_check_sig()
    
    ){
        $self->{is_authorize} = 1;
        return 1;
    }
    return;
    
    
}
sub _prepare {
    my $self = shift;
    my $ua = $self->{ua};
    my $api = 'http://ui.ptlogin2.qq.com/cgi-bin/login';
    my @query_string = (
        appid   =>  $self->{_authorize}{appid},
        daid    =>  $self->{_authorize}{daid},
        pt_no_auth  =>  1,
        s_url   =>  'http%3A%2F%2Fqun.qq.com%2F',
    );
    my @headers = (Referer => 'http://qun.qq.com/');
    my $url = gen_url($api,@query_string);
    my $res = $ua->get($url,@headers);
    if($res->is_success){
        #my $ptui = $res->content =~ /pt\.ptui\s*=\s*{.*?};/s;
        my ($login_sig) = $res->content =~/login_sig:\s*"([^"]+)"/;
        $self->{_authorize}{login_sig} = $login_sig; 
        $self->{_authorize}{referer} = $url;
        return 1;
    }
    else{
        return 0;
    }       
}

sub search_cookie{
    my $self = shift;
    my $cookie_name = shift;
    my $result = undef;
    $self->{ua}->cookie_jar->scan(sub{
        my($version,$key,$val,$path,$domain,$port,$path_spec,$secure,$expires,$discard,$rest) =@_;
        if($key eq $cookie_name){
            $result = $val ;
            return;
        }
    });
    return $result;
}

sub _checkVC{
    my $self = shift;
    my $ua = $self->{ua};
    my $api = 'http://check.ptlogin2.qq.com/check';
    my @query_string = (
        regmaster   =>  undef,
        pt_tea      =>  1,  
        uin         =>  $self->{_authorize}{qq},
        appid       =>  $self->{_authorize}{appid},
        js_ver      =>  10116,
        js_type     =>  1,  
        login_sig   =>  $self->{_authorize}{login_sig},
        ul          =>  'http%3A%2F%2Fqun.qq.com%2F',
        r           =>  rand(),
    );
    my @headers = (Referer => $self->{_authorize}{referer});
    my $res = $ua->get(gen_url($api,@query_string),@headers);
    if($res->is_success){
        print $res->content,"\n" if $self->{debug};
        my($retcode,$verifycode,$md5_salt,$verifysession,$isRandSalt) = $res->content =~/'([^']*)'/g;
        if($retcode == 0){
            $self->{_authorize}{verifycode} = $verifycode;
            $self->{_authorize}{md5_salt} = $md5_salt;
            $self->{_authorize}{isRandSalt} = $isRandSalt;
            $self->{_authorize}{verifysession} = $verifysession;
            return 1;
        }   
        elsif($retcode == 1){
            $self->{_authorize}{cap_cd} = $verifycode;
            $self->{_authorize}{md5_salt} = $md5_salt;
            $self->{_authorize}{isRandSalt} = $isRandSalt;
            $self->{_authorize}{verifysession} = $verifysession;
            $self->{_authorize}{is_need_img_verifycode} = 1;
            return 1;
        }
        else{
            return 0;
        }
    }   
    else{
        return 0;
    }   
}

sub _getimage {
    my $self = shift;
    return 1 if $self->{_authorize}{is_need_img_verifycode} !=  1;
    my $ua = $self->{ua};
    my $api = 'http://captcha.qq.com/getimage';
    my @query_string = (
        uin     =>  $self->{_authorize}{qq},
        aid     =>  $self->{_authorize}{appid},
        cap_cd  =>  $self->{_authorize}{cap_cd},
    );
    my @headers = (Referer => $self->{_authorize}{referer});
    my $res = $ua->get(gen_url($api,@query_string) . "&" . rand(),@headers);
    if($res->is_success){
        my ($fh, $filename) = tempfile("webqq_img_verify_XXXX",SUFFIX =>".jpg",TMPDIR => 1);        
        binmode $fh;
        print $fh $res->content();
        close $fh;
        if(-t STDIN){
            print "input verifycode [ $filename ]: ";
            chomp($self->{_authorize}{verifycode} = <STDIN>);
            return 1;
        }
        else{
            return 0;
        }
    }
    else{return 0;}
}

sub _login {
    my $self = shift;
    my $ua = $self->{ua};
    my $api = 'http://ptlogin2.qq.com/login';
    my $p = pwd_encrypt($self->{_authorize}{pwd},$self->{_authorize}{md5_salt},$self->{_authorize}{verifycode},1);
    my @query_string = (
        u                   => $self->{_authorize}{qq},
        verifycode          => $self->{_authorize}{verifycode},
        pt_vcode_v1         =>  0,
        pt_verifysession_v1 => $self->{_authorize}{verifysession} || $self->search_cookie("verifysession") ,
        pt_randsalt         => 0,
        ptredirect          => 1,
        p                   => $p,
        u1                  => 'http%3A%2F%2Fqun.qq.com%2F',
        h                   => 1,
        t                   => 1,
        g                   => 1,
        from_ui             => 1,
        ptlang              => 2052,
        action              => '1-10-1427007348452',
        js_ver              => 10116,
        js_type             => 1,
        login_sig           => $self->{_authorize}{login_sig},
        pt_uistyle          => 20,
        aid                 => $self->{_authorize}{appid},
        daid                => $self->{_authorize}{daid},
    );
    my @headers = (Referer => $self->{_authorize}{referer});
    my $res = $ua->get(gen_url($api,@query_string) . "&",@headers);
    if($res->is_success){
        print $res->content,"\n" if $self->{debug};
        my($retcode,undef,$api_check_sig,undef,$status,$uin) = $res->content =~/'([^']*)'/g;
        if($retcode == 0){

        }
        elsif($retcode == 4){

        }
        elsif($retcode != 0){

        }
        $self->{_authorize}{api_check_sig} = $api_check_sig;
    }
    
    return 1;
    
}
sub _check_sig {
    my $self = shift;
    my $ua = $self->{ua};
    my $api =  $self->{_authorize}{api_check_sig};
    my @headers = (Referer => $self->{_authorize}{referer});
    my $res =  $ua->get($api,@headers); 
    return 1; 
}


1;
