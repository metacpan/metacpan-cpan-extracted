package Weixin::Client;
sub _init {
    my $self = shift;
    my $api = "https://wx.qq.com/cgi-bin/mmwebwx-bin/webwxinit";
    my @query_string = (
        pass_ticket =>  $self->pass_ticket,
        r           =>  $self->now(),
        skey        =>  uri_escape($self->skey),
        pass_ticket =>  $self->pass_ticket,
    );
    my $post = {
        BaseRequest =>  {
            Uin         =>  $self->wxuin,
            Sid         =>  $self->wxsid,
            Skey        =>  $self->skey,
            DeviceID    =>  $self->deviceid,
        },
    };
    
    my @headers = (
        Referer => "https://wx.qq.com/?&lang=zh_CN",
    );
    my $json = $self->http_post(Weixin::Util::gen_url($api,@query_string),@headers,("Content-Type"=>"application/json; charset=UTF-8"),Content=>$self->json_encode($post));
    my $d = $self->json_decode($json);
    return if $d->{BaseResponse}{Ret}!=0;
    my @user_key = qw(Uin Id NickName HeadImgUrl Sex Signature PYInitial PYQuanPin RemarkName RemarkPYInitial RemarkPYQuanPin );
    my @chartroom_key = qw(ChatRoomUin MemberCount OwnerUin ChatRoomId ChatRoomName);
    my @member_key = qw(Uin Id NickName);
    my @friend_key = qw(HeadImgUrl NickName PYInitial PYQuanPin Alias Province City Sex Id Uin Signature DisplayName RemarkName RemarkPYInitial RemarkPYQuanPin);

    $d->{User}{Id} = $d->{User}{UserName} ;delete $d->{User}{UserName};
    $d->{User}{Sex} = Weixin::Util::code2sex($d->{User}{Sex});
    $self->sync_key($d->{SyncKey}) if $d->{SyncKey}{Count}!=0;
    $self->skey($d->{SKey}) if $d->{SKey};
    @{$self->{_data}{user}}{@user_key}  = map {$_=encode_utf8($_);$_;} @{$d->{User}}{@user_key};

    if($d->{Count}!=0){
        for my $each(@{$d->{ContactList}}) {
            if($self->is_chatroom($each->{UserName})){#chatroom
                $each->{ChatRoomUin}  = $each->{Uin};delete $each->{Uin};
                $each->{ChatRoomId}  = $each->{UserName};delete $each->{UserName};
                $each->{ChatRoomName}  = $each->{NickName};delete $each->{NickName};
                my $chatroom = {};
                @{$chatroom}{@chartroom_key} = map {$_=encode_utf8($_);$_;} @{$each}{@chartroom_key}; 
                $chatroom->{Member} = [];
                for my $m (@{$each->{MemberList}}){
                    $m->{Id} = $m->{UserName};delete $m->{UserName};
                    my $member = {};
                    @{$member}{@member_key} = map {$_=encode_utf8($_);$_;} @{$m}{@member_key};
                    @{$member}{@chartroom_key} = @{$chatroom}{@chartroom_key};  
                    push @{$chatroom->{Member}},$member;
                }
                $self->add_chatroom($chatroom,1);
            }
            else{#friend
                $each->{Id} = $each->{UserName};delete $each->{UserName};
                $each->{Sex} = Weixin::Util::code2sex($each->{Sex});
                my $friend = {};
                @{$friend}{@friend_key} =  map {$_=encode_utf8($_);$_;} @{$each}{@friend_key};
                $self->add_friend($friend);
            }
        }
    }
    
    my @chatrooms = $self->get_chatroom(map {$_->{ChatRoomId}} @{ $self->{_data}{chatroom} });
}
1;
