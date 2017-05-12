package Weixin::Client::Friend;
use List::Util qw(first);
use Weixin::Client::Private::_update_friend;
sub add_friend{
    my $self = shift;
    my $friend = shift;
    my $f = first {$friend->{Id} eq $_->{Id}} @{$self->{_data}{friend}};    
    if(defined $f){
        $f = $friend;
    } 
    else{
        push @{$self->{_data}{friend}},$friend;
    }
}
sub del_friend{
    my $self = shift;
    my $id = shift;
    for(my $i=0;$i<@{$self->{_data}{friend}};$i++){
        if($self->{_data}{friend}[$i]{Id} eq $id){
            splice @{$self->{_data}{friend}},$i,1;
            return 1;
        }
    }
    return 0;
}
sub search_friend{
    my $self = shift;
    my %p = @_; 
    if(wantarray){
        return grep {my $f = $_;(first {$p{$_} ne $f->{$_}} keys %p) ? 0 : 1;} @{$self->{_data}{friend}};
    }
    else{
        return first {my $f = $_;(first {$p{$_} ne $f->{$_}} keys %p) ? 0 : 1;} @{$self->{_data}{friend}};
    }
}
sub update_friend {
    my $self = shift;
    $self->_update_friend();     
}
1;
