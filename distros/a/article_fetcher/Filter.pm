package Filter;
use strict;
use Carp;
use File::Slurp;
##根据关键字过滤####
sub accept_it {
    my $class = shift;
    my  $news_content = shift ||"";
    ##从配置文件中取关键字###
    my @kws= read_file( 'keywords/kws.txt' ) ;
    foreach my $kw (@kws){
        $kw =~ s/\n//;
        ##只要匹配一个关键字就ok##
        if($news_content =~ /$kw/im){
            return 1;
        }else{
            return 0;
        }
    }

}



1;
