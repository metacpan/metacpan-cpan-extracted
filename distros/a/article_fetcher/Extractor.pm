package Extractor;
use strict;
use MyUtils;
use HTML::TreeBuilder;
use Fetcher;
use Carp;
#数字报专用#
sub extract_nav_link{
    my ($class,$seed,$is_utf) = @_;
    my $content = Fetcher->fetch($seed) ;
    if($is_utf){
        $content =MyUtils->u8_to_gbk($content);
    }
    my $tree= HTML::TreeBuilder->new_from_content($content);
    my $addr = q/@0.0.3/;
    my $str =$tree->address($addr)->attr('content');
    $tree->delete;
    $str =~s/0;\sURL=//;
    my $seed_uri = URI->new($seed);
    my $index_uri = URI->new_abs( $str, $seed_uri );
    return $index_uri ; 
}


####extract current page article links####
sub extract_ak_lks{
    my $class = shift ;
    my $index_uri  = shift || Carp->croak("需要index_uri。。。。。");
    my $cp_ak_addr = shift || Carp->croak("需要地址。。。。。"); 
    my $is_utf =shift;
    my $nav_page_content =Fetcher->fetch($index_uri) ;
    if($is_utf){
        $nav_page_content =MyUtils->u8_to_gbk($nav_page_content );
    }

    my $tree= HTML::TreeBuilder->new_from_content($nav_page_content);
#当前版面主要新闻链接 currentpage_article_addr
    my $cp_aks_tree=$tree->address($cp_ak_addr);
    my @cp_aks;
    for (@{ $cp_aks_tree->extract_links("a") }) {
        my($link, $element, $attr, $tag) = @$_;
        my $abs_link = URI->new_abs( $link, $index_uri );
        push @cp_aks,$abs_link;

    }
    $tree->delete;

    return @cp_aks; 
}
##extract article content######
sub extract_ak{
    my $class = shift ;
    my $ak_uri  = shift || Carp->croak("需要ak_uri。。。。。");
    my $is_utf =shift;   
    my $content =Fetcher-> fetch($ak_uri);
    if($is_utf){
        $content=MyUtils->u8_to_gbk($content);
    }
    my $tree= HTML::TreeBuilder->new_from_content($content);
###不同网站使用不同但是相对固定的模板####nav_page=>(article_page_link)=>article
    my $addr_title =q/@0.0.1/;
    my $addr_content=q/@0.1.4.0.0.4.1.0.0/;#q/@0.1.4.0.1.5.0.0.0.0.0.0/;
    my $title=$tree->address($addr_title)->as_text();
    my $news = $tree->address($addr_content)->as_text();
    $tree->delete;
    #print $news;
    my $time = localtime(time);
    my %ak = ("uri",$ak_uri,"title",$title,"content",$news,"ftime",$time);
    return %ak;
}


#######################################
#通用方法                              
#######################################
###抽取链接,根下所有<A>类型超链接###
sub extract_links{
    my $class = shift ;
    my $index_uri  = shift || Carp->croak("需要page页链接。。。。。");
    my $lk_addr = shift; 

    print "\n抓取---------".$index_uri;
    my $c =Fetcher->fetch($index_uri);

    my $nav_page_content =MyUtils->u8_to_gbk($c) if $c;
    my $tree= HTML::TreeBuilder->new_from_content($nav_page_content);
#当前版面主要新闻链接 currentpage_article_addr
    my $cp_lks_tree=$tree->address($lk_addr);
#    print "\n treeeeeee----------",$cp_lks_tree->address();
    my @cp_lks;
    for (@{ $cp_lks_tree->extract_links("a") }) {
        my($link, $element, $attr, $tag) = @$_;
        my $abs_link = URI->new_abs( $link, $index_uri );
        push @cp_lks,$abs_link;

    }
    $tree->delete;

    return @cp_lks;
}
##抽取文本内容,调用子树as_text方法###
sub extract_text{
    my $class = shift ;
    my $ak_uri  = shift || Carp->croak("需要新闻链接");
    my $content_addr = shift || Carp->croak("需要新闻内容位置信息");    
    my $is_utf = shift;
    my $content =Fetcher-> fetch($ak_uri);
    if($is_utf) {
        $content=MyUtils->u8_to_gbk( $content) if $content;
    } 
    $content =~s/&.*quo;//g;##不去掉会乱码的，浙江药监网
    my $tree= HTML::TreeBuilder->new_from_content($content);
    my $stree =$tree->address($content_addr);
    if($stree == undef) {
        return '';
    }
    my $news = $stree->as_text() ;
    $tree->delete;
    return $news || '';
}
##从模板中获得地址######
##############
#模板不能使用浏览器优化过的代码，得使用程序下载的版本，否则不匹配的哦。衰~~~~
#######
sub extract_cont_addr{
    #  my ($class,$tmpl_file ) = @_;
    my $class = shift;
    my $tmpl_file =shift;
    my @crit =@_;
    @crit = ("id","my_content") unless @_;
    
    my $tree =HTML::TreeBuilder->new_from_file($tmpl_file);

    if(wantarray){
        my @strees =$tree->look_down("id","my_content");# || $tree;
        croak qq"
        Error:No desired content marked in the template\t$tmpl_file!
        请先标记模板文件。
        \n
        " unless @strees;

        my @cont_addrs=();
        for my $stree ( @strees){
            push @cont_addrs,$stree->address();
        }
        $tree->delete;
        return @cont_addrs;
    }else{

        my $stree =$tree->look_down("id","my_content");# || $tree;
        croak qq"
        Error:No desired content marked in the template\t$tmpl_file!!
        请先标记模板文件。
        \n
        " unless $stree;
        my $addr = $stree->address();
        $tree->delete;
        return $addr;
    }

}

###根据过滤条件，返回一个或者多个地址######
sub extract_addrs{
    my $class = shift;
    my $tmpl_file =shift;
    my @crit =@_;
    @crit = ("id","my_content") unless @_;
#    print "crit----------",@crit;

    my $tree =HTML::TreeBuilder->new_from_file($tmpl_file);

    my @strees =$tree->look_down(@crit);
    my @cont_addrs ;
    for my $stree ( @strees){
        my $addr =$stree->address();
        push @cont_addrs,$addr;
        print $stree->address(),"\n";
    }
    $tree->delete;
    if(wantarray){
        return @cont_addrs ;
    }else{
        return pop @cont_addrs;
    } 
}

1;

