package Weixin::Client::Plugin::ShowMsg;
use Weixin::Util qw(console);
use POSIX qw(strftime);
use Encode;
use strict;

sub call{
    my $client = shift;
    my $msg = shift;
    my $attach = shift; 
    my $msg_time = $msg->{CreateTime};
    if($msg->{Type} eq 'chatroom_message'){
        if($msg->{MsgClass} eq "send"){
            my $chatroom_name = $msg->ToNickName;
            my $msg_sender = $msg->FromNickName;
            $msg_sender = "昵称未知" unless defined $msg_sender;
            format_msg(
                    strftime("[%y/%m/%d %H:%M:%S]",localtime($msg_time))
                .   "\@$msg_sender(在群:$chatroom_name) 说: ",
                    $msg->{Content} . $attach
            );         
        }
        elsif($msg->{MsgClass} eq "recv"){
            my $msg_sender_nick = $msg->FromNickName;
            my $msg_sender_markname = $msg->FromRemarkName;
            my $msg_sender = $msg_sender_markname || $msg_sender_nick;

            #my $msg_receiever_nick = $msg->ToNickName;
            #$msg_receiever = "昵称未知" unless defined $msg_receiever;

            $msg_sender = "昵称未知" unless defined $msg_sender;

            my $chatroom_name = $msg->ChatRoomName;
            format_msg(
                    strftime("[%y/%m/%d %H:%M:%S]",localtime($msg_time))
                .   "\@$msg_sender(在群:$chatroom_name) 说: ",
                    $msg->{Content} . $attach
            );            
        }
    }
    elsif($msg->{Type} eq 'friend_message'){
        my $msg_sender_nick = $msg->FromNickName; 
        my $msg_sender_markname = $msg->FromRemarkName;
        my $msg_sender = $msg_sender_markname || $msg_sender_nick;
        my $msg_receiever_nick = $msg->ToNickName;
        my $msg_receiever_markname = $msg->ToRemarkName;
        my $msg_receiever = $msg_receiever_markname || $msg_receiever_nick;
        $msg_receiever = "昵称未知" unless defined $msg_receiever;
        $msg_sender = "昵称未知" unless defined $msg_sender;
        
        format_msg(
                strftime("[%y/%m/%d %H:%M:%S]",localtime($msg_time))
            .   "\@$msg_sender(对好友:\@$msg_receiever) 说: ",
            $msg->{Content}  . $attach
        );
    }
    return 1;
}

sub format_msg{
    my $msg_header  = shift;
    my $msg_content = shift;
    my @msg_content = split /\n/,$msg_content;
    $msg_header = decode("utf8",$msg_header);
    my $chinese_count=()=$msg_header=~/\p{Han}/g    ;
    my $total_count = length($msg_header);
    $msg_header=encode("utf8",$msg_header);

    my @msg_header = ($msg_header,(' ' x ($total_count-$chinese_count+$chinese_count*2)) x $#msg_content  );
    while(@msg_content){
        my $lh = shift @msg_header; 
        my $lc = shift @msg_content;
        #你的终端可能不是UTF8编码，为了防止乱码，做下编码自适应转换
        console $lh, $lc,"\n";
    } 
}

1;
