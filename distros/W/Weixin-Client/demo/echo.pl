use lib "../lib";
use Weixin::Client;
my $client = Weixin::Client->new(debug=>0);
$client->load("ShowMsg");
$client->login();
$client->on_receive_msg = sub{
    my $msg = shift ;
    #打印收到的消息
    $client->call("ShowMsg",$msg);
    #对收到的消息，以相同的内容回复
    $client->reply_msg($msg,$msg->{Content});
};
$client->on_send_msg = sub {
    my ($msg,$is_success,$status) = @_;    
    #打印发送的消息
    $client->call("ShowMsg",$msg);
};
$client->run();
