package Fetcher;
use strict;
use Carp;
#抓取指定链接，返回内容或者空
sub fetch{
    my $class = shift ;
    my $seed  = shift || Carp->croak("需要seed。。。。。");
    use LWP::UserAgent;
    use HTML::Tree;
    my $ua = LWP::UserAgent->new;
    $ua->agent("MyApp/0.1 ");
    ###多个网站####得研究网站的结构，遍历树，关键词过滤。
    # Create a request
    my $req = HTTP::Request->new(GET => $seed);
    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);
    # Check the outcome of the response
    if ($res->is_success) {
        my $content =  $res->content;
        return $content;
    }
    else {
        #print $res->status_line, "\n";
        return undef;
    }
}
1;
