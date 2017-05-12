package Weixin::Client::Plugin::SmartReply;
use Encode;
use POSIX qw(strftime);
use Weixin::Util qw(truncate console);
my $API = 'http://www.tuling123.com/openapi/api';
#my $API = 'http://www.xiaodoubi.com/bot/api.php?chat=';
my $once = 1;
sub call{
    my $client = shift;
    my $msg = shift;
    my $self_nick = $client->user->{NickName};
    my $input = $msg->{Content};
    my $userid = $msg->{FromUin};
    my @query_string = (
        "key"       =>  "4c53b48522ac4efdfe5dfb4f6149ae51",
        "userid"    =>  $userid,
        "info"      =>  $input,
    );
    #push @query_string,(loc=>$from_city."市") if $from_city;
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    $client->asyn_http_get($API . "?" . join("&",@query_string_pairs),(),sub{
        my $res =shift;
        if($client->{debug}){
            print "GET " . $API . "?" . join("&",@query_string_pairs),"\n";
            print $res->as_string,"\n";
            print $res->content(),"\n";
        }
        my $reply;
        my $data = {}; 
        eval{
            $data = $client->json_decode($res->content);
        };
        if($@){
            print $@,"\n" if $client->{debug}; 
            return 1;
        }
        return 1 if $data->{code}=~/^4000[1-7]$/;
        if($data->{code} == 100000){
            $reply = encode("utf8",$data->{text});
        } 
        elsif($data->{code}== 200000){
            $reply = encode("utf8","$data->{text}\n$data->{url}");
        }
        else{
            return 1;
        }
        $client->reply_msg($msg,$reply) if $reply;
    });
 
    return 1;
}
1;
