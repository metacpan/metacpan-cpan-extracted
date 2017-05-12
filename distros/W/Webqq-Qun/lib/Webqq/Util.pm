package Webqq::Util;
use Exporter 'import';
our @EXPORT_OK = qw(gen_url gen_url2) ;
use URI::Escape qw(uri_escape);
sub gen_url{
    my ($url,@query_string) = @_;
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    return $url . '?' . join("&",@query_string_pairs);
}
sub gen_url2 {
    my ($url,@query_string) = @_;
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . uri_escape(shift(@query_string)) while(@query_string);
    return $url . '?' . join("&",@query_string_pairs);
}
sub each {
    my $callback = pop;
    my @data;
    if(@_ == 1 and reftype $_[0] eq 'ARRAY'){
        @data = @$_[0];  
    }
    else{
        @data = @_;
    } 
    for (@data){
        $callback->($_);
    }
}
1;
