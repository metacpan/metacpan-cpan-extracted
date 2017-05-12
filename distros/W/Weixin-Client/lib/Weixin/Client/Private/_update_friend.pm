package Weixin::Client;
sub _update_friend{
    my $self = shift;
    my $api = "https://wx.qq.com/cgi-bin/mmwebwx-bin/webwxgetcontact";    
    my @query_string = (
        skey        =>  uri_escape($self->skey),
        pass_ticket =>  $self->pass_ticket,
        r           =>  $self->now(),
        skey        =>  uri_escape($self->skey),
        pass_ticket =>  $self->pass_ticket,
    );      
    my $json = $self->http_post(gen_url($api,@query_string),("Content-Type"=>"application/json; charset=UTF-8"),Content=>"{}");
    return unless defined $json;
    my $d = $self->json_decode($json);
    return unless defined $d; 
    return if $d->{BaseResponse}{Ret}!=0;
    return if $d->{MemberCount} == 0; 
    my @friend_key = qw(HeadImgUrl NickName PYInitial PYQuanPin Alias Province City Sex Id Uin Signature DisplayName RemarkName RemarkPYInitial RemarkPYQuanPin); 
    for my $m (@{$d->{MemberList}}){
        next if $self->is_chatroom($m->{UserName});
        next if $m->{MemberCount}!=0;
        $m->{Id} = $m->{UserName};delete $m->{UserName};
        $m->{Sex} = code2sex($m->{Sex});
        my $friend = {};
        @{$friend}{@friend_key} =  map {$_=encode_utf8($_);$_} @{$m}{@friend_key}; 
        $self->add_friend($friend);
    }
}
1;
