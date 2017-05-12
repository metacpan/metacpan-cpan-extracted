package Webqq::Qun::Operate;
use strict;
use JSON;
use Encode;
use Webqq::Util qw(gen_url gen_url2);
my %levelname;
sub get_token{
    my $self = shift;
    my $t = $self->search_cookie("skey");
    my $n = 0;
    my $o=length($t);
    my $r;
    if($t){
        for($r=5381;$o>$n;$n++){
            $r += ($r<<5) + ord(substr($t,$n,1));
        }
        $self->{token} = 2147483647 & $r;
        return $self->{token};
    }
}


sub get_self {
    my $self = shift;
    my $api = 'http://cgi.find.qq.com/qqfind/myinfo';
    my $ua = $self->{ua}; 
    my @headers = (Referer => $self->{referer});
    my @query_string = (
        callback    => "jQuery18302889768735039979_1427194882987",
        ldw         => $self->{token} || $self->get_token(),
        _           => time(),
    );
    my $res = $ua->get(gen_url($api,@query_string));
    if($res->is_success){
        print $res->content,"\n" if $self->{debug};
        my ($data) =$res->content=~ m/^jQuery18302889768735039979_1427194882987\((.*?)\);/; 
        my $json = JSON->new->utf8->decode($data);
        return if $json->{retcode}!=0;
    }
    return;
     
}
sub get_qun {
    my $self = shift;
    return if $self->{is_load_data};
    my $api = 'http://qun.qq.com/cgi-bin/qun_mgr/get_group_list';
    my $ua = $self->{ua};
    my @headers = (Referer => $self->{referer});
    my $res = $ua->post($api,[ bkn => $self->{token} || $self->get_token()  ]);
    if($res->is_success){
        #{"ec":0,"join":[{"gc":1299322,"gn":"perl技术","owner":4866832},{"gc":144539789,"gn":"PERL学习交流","owner":419902730},{"gc":213925424,"gn":"PERL","owner":913166583}],"manage":[{"gc":390179723,"gn":"IT狂人","owner":308165330}]}
        my $json = JSON->new->utf8->decode($res->content);
        return  if  $json->{ec}!=0;
        $self->{data} = [];
        for my $t (qw(join manage create)){
            for(@{$json->{$t}}){
                $_->{qun_name} = encode("utf8",$_->{gn});
                $_->{qun_number} = $_->{gc};
                $_->{qun_type} = $t eq "join"?"attend":$t;
                delete $_->{gn};
                delete $_->{gc};
                push @{$self->{data}},$_;
                $self->get_member($_->{qun_number});
            }
        }
        $self->{is_load_data} = 1;
        return $self;
    }
    return;
}
sub get_friend {
    my $self = shift;
    return if $self->{is_load_data};
    my $api = 'http://qun.qq.com/cgi-bin/qun_mgr/get_friend_list';
    my $ua = $self->{ua};
    my @headers = (Referer => $self->{referer});
    my $res = $ua->post($api,[bkn => $self->{token}||$self->get_token()]);
    if($res->is_success){
        my $json = JSON->new->utf8->decode($res->content);
        #{"ec":0,"result":{"0":{"mems":[{"name":"卖茶叶和眼镜per","uin":744891290}]},"1":{"gname":"朋友"},"2":{"gname":"家人"},"3":{"gname":"同学"}}} 
        return if $json->{ec}!=0;
        for my $group_index (keys %{$json->{result}}){
            my $category = $group_index==0?"我的好友":encode("utf8",$json->{result}{$group_index}{gname});
            for my $f (@{ $json->{result}{$group_index}{mems} }){
                push @{ $self->{friend} },{
                    category    =>  $category,
                    nick        =>  encode("utf8",$f->{name}),
                    qq          =>  $f->{uin},
                } 

            }
        } 
        return $self;
    }
    return;
}
sub get_member {
    my $self = shift;
    my $qun_number = shift;
    my $api = "http://qun.qq.com/cgi-bin/qun_mgr/search_group_members";
    my $ua = $self->{ua};
    my @headers = (Referer => $self->{referer});
    my $res = $ua->post($api,[   gc  => $qun_number, st  => 0, end => 2000,sort => 0,bkn => $self->{token}|| $self->get_token(),]);
    if($res->is_success){
        #{"adm_max":10,"adm_num":1,"count":4,"ec":0,"levelname":{"1":"潜水","2":"冒泡","3":"吐槽","4":"活跃","5":"话唠","6":"传说"},"max_count":500,"mems":[{"card":"","flag":0,"g":0,"join_time":1410241477,"last_speak_time":1427191050,"lv":{"level":2,"point":404},"nick":"灰灰","qage":10,"role":0,"tags":"-1","uin":308165330},{"card":"","flag":0,"g":0,"join_time":1423016758,"last_speak_time":1427210847,"lv":{"level":2,"point":275},"nick":"小灰","qage":0,"role":1,"tags":"-1","uin":3072574066},{"card":"","flag":0,"g":0,"join_time":1427210502,"last_speak_time":1427210858,"lv":{"level":2,"point":1},"nick":"王鹏飞","qage":8,"role":2,"tags":"-1","uin":470869063},{"card":"小灰2号","flag":0,"g":0,"join_time":1422946743,"last_speak_time":1424144472,"lv":{"level":1,"point":0},"nick":"小灰2号","qage":0,"role":2,"tags":"-1","uin":1876225186}],"search_count":4,"svr_time":1427291710,"vecsize":1}
        my $json = JSON->new->utf8->decode($res->content);
        return if $json->{ec}!=0;  
        my %role = (
            0   =>  "owner",
            1   =>  "admin",
            2   =>  "member",
        );
        for(keys %{$json->{levelname}}){
            $levelname{$_} = encode("utf8",$json->{levelname}{$_});
        }
        delete $json->{levelname};
        delete $json->{ec};
        for(@{$json->{mems}}){
            delete $_->{tags};
            my $level = $levelname{$_->{lv}{level}};
            $_->{level} = $level;
            $_->{bad_record} = $_->{flag};
            $_->{sex} = $_->{g}?"female":"male";
            $_->{qq}  = $_->{uin};
            delete $_->{flag};
            delete $_->{g};
            delete $_->{lv};
            delete $_->{uin};
            
            $_->{role} = $role{$_->{role}};
            $_->{card} = encode("utf8",$_->{card});
            $_->{nick} = encode("utf8",$_->{nick});
        } 
        $json->{members} = $json->{mems};
        delete $json->{mems};
        for (@{$self->{data}}){
            if($_->{qun_number} eq $qun_number){
                for my $m(@{$json->{members}}){
                    $m->{qun_number} = $_->{qun_number}; 
                    $m->{qun_name} = $_->{qun_name}; 
                }
                @$_{keys %$json} = @$json{keys %$json};
                return $self;
            } 
        }
        return;
    }
    return;
}
sub add_member {
    my $self = shift;
    my($qun_number,@member) = @_;
    my $api = "http://qun.qq.com/cgi-bin/qun_mgr/add_group_member";
    my $ua = $self->{ua};
    my @headers = (Referer => $self->{referer});
    my $res = $ua->post($api,[   gc  => $qun_number, ul  => join("|",@member), bkn => $self->{token} || $self->get_token(),],@headers);
    if($res->is_success){
        print $res->content if $self->{debug};
        my $json = JSON->new->utf8->decode($res->content);
        return if $json->{ec}!=0;
        return $self;
    }
    return;
}
sub del_member {
    my $self = shift;
    my($qun_number,@member) = @_;
    my $api = "http://qun.qq.com/cgi-bin/qun_mgr/delete_group_member";
    my $ua = $self->{ua};
    my @headers = (Referer => $self->{referer});
    my $res = $ua->post($api,[   gc  => $qun_number, ul  => join("|",@member), flag => 0, bkn => $self->{token}|| $self->get_token(),],@headers);
    if($res->is_success){
        print $res->content if $self->{debug};
        my $json = JSON->new->utf8->decode($res->content);
        return if $json->{ec}!=0;
        return $self;
    }
    return;
}
sub set_admin {
    my $self = shift;
    my($qun_number,@member) = @_;
    my $api = "http://qun.qq.com/cgi-bin/qun_mgr/set_group_admin";
    my $ua = $self->{ua};
    my @headers = (Referer => $self->{referer});
    my $res = $ua->post($api,[   gc  => $qun_number, ul => join("|",@member), op  => 1, bkn => $self->{token} || $self->get_token(),],@headers);
    if($res->is_success){
        print $res->content,"\n" if $self->{debug};
        my $json = JSON->new->utf8->decode($res->content);
        return if $json->{ec}!=0;
        return $self;
    }
    return;
}

sub del_admin {
    my $self = shift;
    my($qun_number,$member) = @_;
    my $api = "http://qun.qq.com/cgi-bin/qun_mgr/set_group_admin";
    my $ua = $self->{ua};
    my @headers = (Referer => $self->{referer});
    my $res = $ua->post($api,[   gc  => $qun_number, ul => $member, op  => 0, bkn => $self->{token} || $self->get_token(),],@headers);
    if($res->is_success){
        print $res->content,"\n" if $self->{debug};
        my $json = JSON->new->utf8->decode($res->content);
        return if $json->{ec}!=0;
        return $self;
    }
    return;
}

sub _report1{
    my $self = shift;
    my $qq = shift;
    my $qun_number = shift;
    my $api = 'http://cgi.connect.qq.com/report/tdw/report';
    my $ua = $self->{ua};
    my @headers = (Referer => $self->{referer});
    my $ts = time() . "000";
    my @query_string = (
        table   =>  "dc00141",
        fields  =>  qq{["uin","ts","opername","module","action","obj1"]},
        datas   =>  qq{[["$qq",$ts,"Grp_website","mana_mber","Clk_set","$qun_number"]]},
        t       =>  time(),
    );
    my $res  = $ua->get(gen_url2($api,@query_string),@headers);
    if($res->is_success){
        print $res->content,"\n" if $self->{debug};
    }
}

sub _report2 {
    my $self = shift;
    my $ua = $self->{ua};
    my $api = "http://cgi.connect.qq.com/report/report";
    my @headers = (Referer => $self->{referer});
    my $res  = $ua->get($api."?tag=0&strValue=0&nValue=12094&t=".time(),@headers);
    if($res->is_success){
        print $res->content,"\n" if $self->{debug};
    }
}
sub set_card {
    my $self = shift;
    my($qun_number,$member,$card) = @_;
    my $api = "http://qun.qq.com/cgi-bin/qun_mgr/set_group_card";
    my $ua = $self->{ua};
    my @headers = (Referer => $self->{referer});
    my $res = $ua->post($api,[   gc  => $qun_number, u  => $member, name  => $card, bkn => $self->{token}|| $self->get_token(),],@headers);
    if($res->is_success){
        print $res->content if $self->{debug};
        my $json = JSON->new->utf8->decode($res->content);
        return if $json->{ec}!=0;
        return $self;    
    }
    return;
}

sub create {}
sub dismiss {}
sub upgrate{}
sub transfer {}
sub recover {}
1;
