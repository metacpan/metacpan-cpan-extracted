package Webqq::Qun::One;
use base qw(Webqq::Qun);
use Storable qw(dclone);
sub find_member {
    my $self = shift;   
    my %p = @_;
    my @member;
    my %filter = (
        sex         =>  1,
        card        =>  1,
        qq          =>  1,
        nick        =>  1,
        role        =>  1,
        bad_record  =>  1,
    );
    for my $k  (keys %p){
        unless(exists $filter{$k}){
            delete $p{$k} ;
            next;
        }
        delete $p{$k} unless defined $p{$k};
    }
    $self->SUPER::each($self->{members},sub{
        my $m = dclone(shift);
        for my $k (keys %p){
            return if $m->{$k} ne $p{$k};
        } 
        $m->{qun_name} = $self->{qun_name};
        $m->{qun_number} = $self->{qun_number};
        push @member,bless $m,"Webqq::Qun::Member";
    });

    return wantarray?@member:$member[0];

}

#sub del_member {
#    my $self = shift;
#}

#sub add_member {
#    my $self = shift;
#}

#sub set_admin {
#    my $self = shift;
#}
1;
