package Weixin::Client;
sub _update_chatroom_member{
    my $self  = shift;
    my $chatroom = shift;
    my @list;
    for(@{$chatroom->{Member}}){
        push @list,{UserName=>$_->{Id},EncryChatRoomId=>(defined $chatroom->{Id}?$chatroom->{Id}:"")} if defined $_->{Id};
    }
    my $post = {
        BaseRequest =>  {
            Uin         =>  $self->wxuin,
            DeviceID    =>  $self->deviceid,
            Sid         =>  $self->wxsid,
            Skey        =>  $self->skey,
        },
        Count       =>  $chatroom->{MemberCount},
        List        =>  \@list,
    };

    my $api = "https://wx.qq.com/cgi-bin/mmwebwx-bin/webwxbatchgetcontact";
    my @query_string = (
        type        =>  "ex",
        pass_ticket =>  $self->pass_ticket,
        r           =>  $self->now(),
        skey        =>  uri_escape($self->skey),
        pass_ticket =>  $self->pass_ticket,
    );
    my $json = $self->http_post(gen_url($api,@query_string),("Content-Type"=>"application/json; charset=UTF-8"),Content=>$self->json_encode($post)); 
    return unless defined $json;
    my $d = $self->json_decode($json);
    return unless defined $d;
    return if $d->{BaseResponse}{Ret}!=0;
    return if $d->{Count}==0;
    my %member_info; 
    my @member_key = qw(HeadImgUrl NickName PYInitial PYQuanPin Alias Province City Sex Id Uin Signature DisplayName RemarkName RemarkPYInitial RemarkPYQuanPin);
    my @chartroom_key = qw(ChatRoomUin MemberCount OwnerUin ChatRoomId ChatRoomName);
    for my $e (@{$d->{ContactList}}){
        #$e->{ChatRoomUin} = $e->{ChatRoomId};delete $e->{ChatRoomId};
        #next if $e->{ChatRoomUin} ne $chatroom->{ChatRoomUin};
        $e->{Sex} = code2sex($e->{Sex});
        $e->{Id} = $e->{UserName};delete $e->{UserName};
        @{$member_info{$e->{Id}}}{@member_key} = map {$_=encode_utf8($_);$_} (@{$e}{@member_key});
        @{$member_info{$e->{Id}}}{@chartroom_key} = @{$chatroom}{@chartroom_key};
    }

    for (@{$chatroom->{Member}}) {
        if(exists $member_info{$_->{Id}}){
            $_ = $member_info{$_->{Id}}; 
        }
    } 
}
1;
