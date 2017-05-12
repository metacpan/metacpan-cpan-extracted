package Weixin::Message;
use Weixin::Util;
use List::Util qw(first);
use Weixin::Message::Constant;
use Weixin::Client::Private::_send_text_msg;

sub _parse_send_status_data {
    my $self = shift;
    my $json = shift;
    if(defined $json){
        my $d = $self->json_decode($json);
        return {is_success => 0,status=>"数据格式错误"} unless defined $d;
        return {is_success => 0,status=>encode_utf8($d->{BaseRequest}{ErrMsg})} if $d->{BaseRequest}{Ret}!=0; 
        return {is_success => 1,status=>"发送成功"};
    }
    else{
        return {is_success => 0,status=>"请求失败"};
    } 
}

my %logout_code = qw(
    1100    0
    1101    1
    1102    1
    1205    1
);
sub _parse_synccheck_data {
    my $self = shift;
    my($retcode,$selector) = @_;
    if(first {$retcode == $_} keys %logout_code){
        $self->logout($logout_code{$retcode});
        $self->stop();
    }
    if(defined $retcode and defined $selector and $retcode == 0 and $selector != 0){
        $self->{_synccheck_error_count}=0;
        $self->_sync();
    }
    elsif(defined $retcode and defined $selector and $retcode == 0){
        $self->{_synccheck_error_count}=0;
        $self->_synccheck();
    }
    elsif($self->{_synccheck_error_count} < 3){
        $self->{_synccheck_error_count}++;
        $self->timer(5,sub{$self->_sync();});
    }
    else {
        $self->timer(2,sub{$self->_synccheck();});
    }
}
sub _parse_sync_data {
    my $self = shift;
    my $d = shift;
    if(first {$d->{BaseResponse}{Ret} == $_} keys %logout_code  ){
        $self->logout($logout_code{$d->{BaseResponse}{Ret}});
        $self->stop();
    }
    elsif($d->{BaseResponse}{Ret} !=0){
        console "收到无法识别消息，已将其忽略\n";
        return; 
    }
    $self->sync_key($d->{SyncKey}) if $d->{SyncKey}{Count}!=0;
    $self->skey($d->{SKey}) if $d->{SKey};
    if($d->{AddMsgCount} != 0){
        my @key = qw(
            CreateTime
            FromId
            ToId
            Content
            MsgType
            MsgId
        );
        for (@{$d->{AddMsgList}}){
            my $msg = {};
            $_->{FromId} = $_->{FromUserName};delete $_->{FromUserName};
            $_->{ToId} = $_->{ToUserName};delete $_->{ToUserName};
            @{$msg}{@key} = map {$_=encode_utf8($_);$_} @{$_}{@key};
            eval{
                require HTML::Entities;
                $msg->{Content} = HTML::Entities::decode_entities($msg->{Content});
            };
            $self->_add_msg($msg);
        }
    }
    if($d->{ModContactCount}!=0){
        for(@{$d->{ModContactList}}){
            if($self->is_chatroom($_->{UserName})){
                $_->{ChatRoomId} = $_->{UserName};delete $_->{UserName};
                $_->{OwnerId} = $_->{ChatRoomOwner};delete $_->{ChatRoomOwner};
                $_->{ChatRoomName} = $_->{NickName};delete $_->{NickName};
                my @chartroom_key = qw(ChatRoomUin MemberCount OwnerUin ChatRoomId ChatRoomName OwnerId);
                my @member_key = qw(HeadImgUrl NickName PYInitial PYQuanPin Alias Province City Sex Id Uin Signature DisplayName RemarkName RemarkPYInitial RemarkPYQuanPin);

                my $chatroom = $self->search_chatroom(ChatRoomId => $_->{ChatRoomId}) ;
                my $is_new_chatroom = 0;
                unless(defined $chatroom){
                    $is_new_chatroom = 1;
                    $chatroom = {};
                }
                for my $k(@chartroom_key){
                    $chatroom->{$k} = encode_utf8($_->{$k}) if defined $_->{$k};
                } 
                if($_->{MemberCount} != 0){
                    my %members ;
                    for my $m (@{$_->{MemberList}}){
                        $m->{Id} = $m->{UserName};delete $m->{UserName};
                        my $member = {};
                        for my $k(@member_key){
                            $member->{$k} = encode_utf8($m->{$k}) if defined $m->{$k};
                        }
                        $member->{$_} = $chatroom->{$_} for(grep {$_ ne "Member"} keys %$chatroom); 
                        $members{ $member->{Id} } = $member;
                    } 
                    if($is_new_chatroom){#new chatroom
                        $chatroom->{Member} = [values %members];
                        $self->add_chatroom($chatroom,1);
                    }
                    else{#chatroom modified
                        for(@{$chatroom->{Member}}){
                            next unless exists $members{$_->{Id}};
                            for my $k(keys %$_){
                                next if exists $members{$_->{Id}}{$k}; 
                                $members{$_->{Id}}{$k} = $_->{$k};
                            }    
                        }        
                        $chatroom->{Member} = [values %members];
                    }
                }
            }
            else{
                my @friend_key = qw(HeadImgUrl NickName PYInitial PYQuanPin Alias Province City Sex Id Uin Signature DisplayName RemarkName RemarkPYInitial RemarkPYQuanPin);
                $_->{Id} = $_->{UserName};delete $_->{UserName};
                $_->{Sex} = code2sex($_->{Sex}) if $_->{Sex};
                my $friend = $self->search_friend(Id=>$_->{Id});
                my $is_new_friend = 0;
                unless(defined $friend){
                    $is_new_friend = 1;
                    $friend = {};
                }
                for my $k(@friend_key){
                    $friend->{$k} = encode_utf8($_->{$k}) if defined $_->{$k};      
                }
                $self->add_friend($friend) if $is_new_friend;
            }
        } 
    }
    if($d->{DelContactCount}!=0){    
        for(@{$d->{DelContactList}}){
            if($self->is_chatroom($_->{UserName})){
                $_->{ChatRoomId} = $_->{UserName};delete $_->{UserName};
                $self->del_chatroom($_->{ChatRoomId}); 
            }
            else{
                $_->{Id} = $_->{UserName};delete $_->{UserName};
                $self->del_friend($_->{Id});
            }
        }
    }
    if($d->{ModChatRoomMemberCount}!=0){
    
    }
    if($d->{ContinueFlag}!=0){
        $self->_sync();
    }
    else{
        $self->_synccheck();
    }
     
}

sub _add_msg{
    my $self = shift;
    my $msg  = shift;
    $msg->{TTL} = 5;
    if($msg->{MsgType} eq MM_DATA_TEXT){
        $msg->{MsgType} = "text";
        if($msg->{FromId} eq $self->{_data}{user}{Id}){
            $msg->{MsgClass} = "send";
        }
        elsif($msg->{ToId} eq $self->{_data}{user}{Id}){
            $msg->{MsgClass} = "recv";
        }
        
        if($msg->{MsgClass} eq "send"){
            $msg->{Type}    = $self->is_chatroom($msg->{ToId})?"chatroom_message":"friend_message";
            if($msg->{Type} eq "friend_message"){
                my $friend = $self->search_friend(Id=>$msg->{ToId}) || {}; 
                $msg->{FromNickName} = "我";
                $msg->{FromRemarkName} = "我";
                $msg->{FromUin} = $self->{_data}{user}{Uin};
                $msg->{ToUin} = $friend->{Uin};
                $msg->{ToNickName} = $friend->{NickName};
                $msg->{ToRemarkName} = $friend->{RemarkName};
            }
            elsif($msg->{Type} eq "chatroom_message"){
                my $chatroom = $self->search_chatroom(ChatRoomId=>$msg->{ToId});
                if(not defined $chatroom){
                    $self->get_chatroom($msg->{ToId});
                    $chatroom = $self->search_chatroom(ChatRoomId=>$msg->{ToId}) || {};
                }
                $msg->{FromNickName} = "我";
                $msg->{FromRemarkName} = undef;
                $msg->{FromUin} = $self->{_data}{user}{Uin};
                $msg->{ToUin} = $chatroom->{ChatRoomUin}; 
                $msg->{ToNickName} = $chatroom->{ChatRoomName};
                $msg->{ToRemarkName} = undef;
            }
            $msg = $self->_mk_ro_accessors($msg,"Send");
        }
        elsif($msg->{MsgClass} eq "recv"){
            $msg->{Type}    = $self->is_chatroom($msg->{FromId})?"chatroom_message":"friend_message"; 
            if($msg->{Type} eq "friend_message"){
                my $friend = $self->search_friend(Id=>$msg->{FromId}) || {}; 
                $msg->{FromNickName} = $friend->{NickName};
                $msg->{FromRemarkName} = $friend->{RemarkName};
                $msg->{FromUin} = $friend->{Uin};;
                $msg->{ToUin} = $self->{_data}{user}{Uin};
                $msg->{ToNickName} = "我";
                $msg->{ToRemarkName} = undef;
            }
            elsif($msg->{Type} eq "chatroom_message"){
                my ($chatroom_member_id,$content) = $msg->{Content}=~/^(\@.+):<br\/>(.*)/g; 
                $msg->{Content} = $content;
                my $member = $self->search_chatroom_member(ChatRoomId=>$msg->{FromId},Id=>$chatroom_member_id);
                if(not defined $member){
                    $self->get_chatroom($msg->{FromId});
                    $member = $self->search_chatroom_member(ChatRoomId=>$msg->{FromId},Id=>$chatroom_member_id) || {};
                }
                $msg->{FromNickName} = $member->{NickName};
                $msg->{FromId}       = $member->{Id};
                $msg->{FromRemarkName} = undef;
                $msg->{FromUin} = $member->{Uin};;
                $msg->{ToUin} = $self->{_data}{user}{Uin};
                $msg->{ToNickName} = "我";
                $msg->{ToRemarkName} = undef;
                $msg->{ChatRoomName} = $member->{ChatRoomName};
                $msg->{ChatRoomUin} = $member->{ChatRoomUin};
                $msg->{ChatRoomId}  = $member->{ChatRoomId};
            }
            $msg = $self->_mk_ro_accessors($msg,"Recv");
        }
        
        $self->{_receive_message_queue}->put($msg);
    }
    elsif($msg->{MsgType} eq MM_DATA_STATUSNOTIFY){
    }
    elsif($msg->{MsgType} eq MM_DATA_SYSNOTICE){
        
    }
    elsif($msg->{MsgType} eq MM_DATA_APPMSG){
        
    }
    elsif($msg->{MsgType} eq MM_DATA_EMOJI){

    }
}
sub _del_friend{
    my $self = shift;
}
sub _mod_chatroom_member{
    my $self = shift;
}
sub _mod_friend{
    my $self = shift;
}
sub _mod_profile {
    my $self = shift;
}

sub _mk_ro_accessors {
    my $self = shift;
    my $msg =shift;
    my $msg_pkg = shift;
    no strict 'refs';
    for my $field (keys %$msg){
        *{__PACKAGE__ . "::${msg_pkg}::$field"} = sub{
            my $obj = shift;
            my $pkg = ref $obj;
            die "the value of \"$field\" in $pkg is read-only\n" if @_!=0;
            return $obj->{$field};
        };
    }
    return bless $msg,__PACKAGE__."::$msg_pkg";
}

sub send_friend_msg {
    my $self = shift;
    my ($friend,$content) = @_;
    unless(defined $friend and $friend->{Id}){
        console "send_friend_msg 参数无效\n";
        return;
    }
    unless($content){
        console "send_friend_msg 发送内容不能为空\n";
        return ;
    }
    my $msg = $self->_create_text_msg($friend,$content,"friend_message"); 
    $self->{_send_message_queue}->put($msg);
}

sub send_chatroom_msg {
    my $self = shift;
    my ($chatroom,$content) = @_;
    unless(defined $chatroom and $chatroom->{ChatRoomId}){
        console "send_chatroom_msg 参数无效\n";
        return;
    }
    unless($content){
        console "send_chatroom_msg 发送内容不能为空\n";
        return ;
    }
    my $msg = $self->_create_text_msg($chatroom,$content,"chatroom_message");
    $self->{_send_message_queue}->put($msg);
}

sub reply_msg {
    my $self = shift;
    my $msg = shift;
    my $content = shift;
    return if $msg->{MsgClass} ne "recv";
    if($msg->{Type} eq "chatroom_message"){
        my $chatroom = $self->search_chatroom(ChatRoomId=>$msg->{ChatRoomId});
        $self->send_chatroom_msg($chatroom,$content);
    }
    elsif($msg->{Type} eq "friend_message"){
        my $friend = $self->search_friend(Id=>$msg->{FromId});
        $self->send_friend_msg($friend,$content);
    }
}

sub _create_text_msg{
    my $self = shift;
    my ($obj,$content,$type)= @_;
    my $to_id;
    my $to_uin;
    my $to_nickname;
    my $remark_name;
    if($type eq "chatroom_message"){
        $to_id = $obj->{ChatRoomId};
        $to_uin = $obj->{ChatRoomUin};
        $to_nickname = $obj->{ChatRoomName}; 
    }
    elsif($type eq "friend_message"){
        $to_id = $obj->{Id};
        $to_uin = $obj->{Uin};
        $to_nickname = $obj->{NickName};
        $remark_name = $obj->{RemarkName};
    }
    my $t = $self->now();
    my $msg = {
        CreateTime  => time(),
        MsgId       => $t,
        Content     => $content,
        FromId      => $self->user->{Id},
        FromNickName=> "我",
        FromRemarkName => undef,
        FromUin     => $self->user->{Uin},
        ToId        => $to_id,
        ToNickName  => $to_nickname,
        ToRemarkName=> $remark_name, 
        ToUin       => $to_uin,
        MsgType     => "text",
        MsgClass    => "send", 
        Type        => $type,
        TTL         => 5,
    };      
    return $self->_mk_ro_accessors($msg,"Send"); 
}

1;
