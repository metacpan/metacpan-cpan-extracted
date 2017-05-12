package Weixin::Client::Chatroom;
use strict;
use List::Util qw(first);
use Weixin::Client::Private::_update_chatroom_member;
use Weixin::Client::Private::_get_chatroom;
sub add_chatroom{
    my $self = shift;
    my $chatroom = shift;
    my $is_update_member = shift || 0;
    $chatroom->{ChatRoomName} = $self->get_default_chatroomname($chatroom) if $chatroom->{ChatRoomName} eq "";
    #$self->update_chatroom_member($chatroom) if ($is_update_member and  $chatroom->{MemberCount}!=0);
    my $c = first {$chatroom->{ChatRoomId} eq $_->{ChatRoomId}} @{$self->{_data}{chatroom}} ;
    if(defined $c){
        %$c = %$chatroom;
    }
    else{
        push @{$self->{_data}{chatroom}},$chatroom;
    }
}
sub del_chatroom{
    my $self = shift;
    my $chatroom_id = shift;
    for(my $i = 0;$i<@{$self->{_data}{chatroom}};$i++){
        if($self->{_data}{chatroom}[$i]{ChatRoomId} eq $chatroom_id){
            splice @{$self->{_data}{chatroom}},$i,1;
            return 1;        
        } 
    }
    return 0;
}

sub search_chatroom {
    my $self = shift;
    my %p = @_;
    if(wantarray){
        return grep {my $c = $_;(first {$p{$_} ne $c->{$_}} keys %p) ? 0 : 1;}  @{$self->{_data}{chatroom}} ;
    }
    else{
        return first {my $c = $_;(first {$p{$_} ne $c->{$_}} keys %p) ? 0 : 1;}  @{$self->{_data}{chatroom}} ;
    }
}
sub search_chatroom_member{
    my $self = shift;
    my %p = @_;
    my @member;
    for(@{$self->{_data}{chatroom}}){
        next if $_->{MemberCount}== 0;
        push @member, @{$_->{Member}};
    }
    if(wantarray){
        return grep {my $m = $_;(first {$p{$_} ne $m->{$_}} keys %p) ? 0 : 1;}  @member ;
    }
    else{
        return first {my $m = $_;(first {$p{$_} ne $m->{$_}} keys %p) ? 0 : 1;}  @member ; 
    }
}
sub add_chatroom_member{
    my $self = shift;
    my $chatroom_id = shift;
    my $member = shift;
    my $c = first {$chatroom_id eq $_->{ChatRoomId}} @{$self->{_data}{chatroom}} ;
    return unless defined $c;
    my $m = first {$member->{Id} eq $_->{Id}} @{$c->{Member}} ;
    defined $m?($m = $member):(push @{$c->{Member}},$member);
}
sub del_chatroom_member{
    my $self = shift;
    my $chatroom_id = shift;
    my $member_id  = shift;
    for(my $i = 0;$i<@{$self->{_data}{chatroom}};$i++){
        if($self->{_data}{chatroom}[$i]{ChatRoomId} eq $chatroom_id){
            for(my $j=0;$j<@{$self->{_data}{chatroom}[$i]{Member}};$j++){
                if($self->{_data}{chatroom}[$i]{Member}[$j]{Id} eq $member_id){
                    splice @{$self->{_data}{chatroom}[$i]{Member}[$j]},$j,1;
                    return 1;
                }
            }
        }        
    }     
      
    return 0;
}

sub update_chatroom_member{
    my $self = shift;
    my $chatroom = shift;
    $self->_update_chatroom_member($chatroom);
}
sub get_chatroom {
    my $self = shift;
    my @chatroom_id = @_;
    my @chatroom = $self->_get_chatroom(@chatroom_id);
    $self->add_chatroom($_,1) for @chatroom;
    return @chatroom;
}
sub is_chatroom {
    my $self = shift;
    my $chatroom_id = shift;
    return index($chatroom_id,'@@')==0?1:0;
}

sub get_default_chatroomname {
    my $self = shift;
    my $chatroom = shift;
    return $chatroom->{ChatRoomName} if $chatroom->{ChatRoomName} ne "";
    my $max_count = 3;
    my $i=0;
    my @name;
    for(@{$chatroom->{Member}}){
        last if $i > $max_count;
        push @name,$_->{DisplayName}||$_->{RemarkName}||$_->{NickName};
        $i++;
    }
    return join "、",@name if @name;
    return "[未命名]";
}

1;
