package Weixin::Client;
use Weixin::Client::Private::_get_qrcode_uuid;
use Weixin::Client::Private::_get_qrcode_image;
use Weixin::Client::Private::_is_need_login;
sub _login{
    my $self = shift;   
    console "客户端准备登录...\n";
    unless($self->_is_need_login()){
        console "微信登录成功\n";
        return 1;
    }
    my $show_tip = 1;
    my $api = 'https://login.weixin.qq.com/cgi-bin/mmwebwx-bin/login'; 
    
    my $qrcode_uuid = $self->_get_qrcode_uuid() ;
    unless(defined $qrcode_uuid){
        console "无法获取到登录二维码，登录失败\n";
        exit -1 ;
    }
    unless($self->_get_qrcode_image($qrcode_uuid)){
        console "下载二维码失败，客户端退出\n" ;
        exit -1 ;
    }
    my $i=1; 
    console "等待手机微信扫描二维码...\n";
    while(1){
        my @query_string = (
            uuid    =>  $qrcode_uuid,
            tip     =>  $show_tip ,
            _       =>  $self->now(),
        );
        my $r = $self->http_get(Weixin::Util::gen_url($api,@query_string));
        next unless defined $r;
        my %data = $r=~/window\.(.+?)=(.+?);/g; 
        $data{redirect_uri}=~s/^["']|["']$//g if defined $data{redirect_uri};
        if($data{code} == 408){
            select undef,undef,undef,0.5;
            if($i==5){
                console "登录二维码已失效，重新获取二维码\n";
                $qrcode_uuid = $self->_get_qrcode_uuid();    
                $self->_get_qrcode_image($qrcode_uuid);
                $i = 1;
                next;
            }
            $i++;
        }   
        elsif($data{code} == 201){
            console "手机微信扫码成功，请在手机微信上点击 [登录] 按钮...\n";
            $show_tip = 0;
            next;
            
        }
        elsif($data{code} == 200){
            console "正在进行登录...\n";
            my $data = $self->http_get($data{redirect_uri} . "&fun=new");
            #<error><ret>0</ret><message>OK</message><skey>@crypt_859d8a8a_3f3db5290570080d1db29da9507e35de</skey><wxsid>rsuMHe7xmA0aHW1D</wxsid><wxuin>138122335</wxuin><pass_ticket>hWdpMVCMqXIVfhXLcsJxYrC6bv785tVDLZAres096ZE%3D</pass_ticket></error
            my %d = $data=~/<([^<>]+?)>([^<>]+?)<\/\1>/g;
            return 0 if $d{ret} != 0;
            $self->skey($d{skey});
            $self->wxsid($d{wxsid});
            $self->wxuin($d{wxuin});
            $self->pass_ticket($d{pass_ticket});
            console "微信登录成功\n";
            return 1;
        }
        elsif($data{code} == 400){
            console "登录错误，客户端退出\n";
            exit;
        }
        elsif($data{code} == 500){
            console "登录错误，客户端尝试重新登录...\n";
            $i = 1;
            $show_tip = 1;            
            $qrcode_uuid = $self->_get_qrcode_uuid();
            $self->_get_qrcode_image($qrcode_uuid);
            next;            
        }
    }
}

1;
