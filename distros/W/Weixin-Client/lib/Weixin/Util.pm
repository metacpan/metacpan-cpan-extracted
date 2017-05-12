package Weixin::Util;
use Exporter 'import';
use Encode ();
use Encode::Locale;
our @EXPORT = qw(gen_url gen_url2 code2sex console truncate uri_escape encode decode encode_utf8) ;
our @EXPORT_OK = qw(gen_url gen_url2 code2sex console truncate uri_escape encode decode encode_utf8) ;
use URI::Escape ();
BEGIN{
    *uri_escape= *URI::Escape::uri_escape;
    *encode = *Encode::encode;
    *decode = *Encode::decode;
    *encode_utf8 = *Encode::encode_utf8;
}
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

sub console{
    my $bytes = join "",@_;
    print encode("locale",decode("utf8",$bytes));
}   

sub truncate {
    my $out_and_err = shift;
    my %p = @_;
    my $max_bytes = $p{max_bytes} || 200;
    my $max_lines = $p{max_lines} || 10;
    my $is_truncated = 0;
    if(length($out_and_err)>$max_bytes){
        $out_and_err = substr($out_and_err,0,$max_bytes);
        $is_truncated = 1;
    }
    my @l =split /\n/,$out_and_err,$max_lines+1;
    if(@l>$max_lines){
        $out_and_err = join "\n",@l[0..$max_lines-1];
        $is_truncated = 1;
    }
    return $out_and_err. ($is_truncated?"\n(已截断)":"");
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

sub code2sex{
    my $c = shift;
    my %h = qw(
        0   none
        1   male
        2   female
    );
    return $h{$c} || "none";
}
1;
