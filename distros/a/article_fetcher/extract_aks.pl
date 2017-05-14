use strict;
use MyUtils;
use URI;
use Fetcher;
use Extractor;
use Filter;
use Benchmark;
use File::Slurp;
use DateTime();
use Carp;
use DBWriter;
use threads;
use Encode;
my @targets= read_file("fetch_targets.tsv");
my @thrs;
for my $line (@targets[1..scalar @targets]){
    $line =~s/\n//g;
    next if $line =~/^\s*$/;
    my ($name,$is_paper,$abbr,$seed)=split(/\t/,$line);
#    next unless $seed =~/zjfzb/;####TODO#########
    print $line;    
    my $thr = threads->create('do_it', $seed,$abbr,$is_paper);
    push @thrs ,$thr;
}
sleep(60*60);
foreach my $t (@thrs){
    if($t->is_joinable()){
        $t->join();######阻塞了。
    }
}
exit(0);

#my $t0 = Benchmark->new;

#my $t1 = Benchmark->new;
#my $td = timediff($t1, $t0);
#print "the code took:",timestr($td),"\n";
#my $seed =shift || q(http://hzdaily.hangzhou.com.cn/hzrb/paperindex.htm);# $seeds->{hzrb};
#my $abbr =shift ||q/hzrb/;
#my $is_pp = shift ||1;
#do_it($seed,$abbr,$is_pp);##开线程
sub do_it{
    my $dbh = DBWriter->get_dbh();
    my $tag = "matched";
    my ($seed,$abbr,$is_pp)=@_;
    my $nav_tmpl_file =$abbr.q/_nav.tmpl/;
    my $ak_tmpl_file =$abbr.q/_ak.tmpl/;
    my $ak_content_tmpl_file = $abbr.q/_ak_content.tmpl/;
    my $dt = DateTime->now;
    $dt->set_time_zone( 'Asia/Shanghai' );
    my $file_name = $abbr.qq/_/.$dt->ymd.qq/.txt/;
    my $sep_line = "\n".$dt->ymd." ".$dt->hms."\n";
##只有数字报需要#####
    my $index_uri;
    if($is_pp){
        $index_uri = Extractor->extract_nav_link($seed);
    }else{
        $index_uri = $seed;
    }
    print "首页面地址",$index_uri,"\n";
#my $hzrb = {is_paper=>,seed=>,nav_tmpl_file=>,ak_tmpl_file=>,ak_content_tmpl_file=>};

    my $addr = Extractor->extract_cont_addr($nav_tmpl_file) ;
    my $cp_ak_addr = Extractor->extract_cont_addr($ak_tmpl_file)  ;
    my $ak_content_addr ;
    my @cont_addrs;
    if($abbr =~/sfda/ ||$abbr =~/zjfda/){
        @cont_addrs = Extractor->extract_addrs($ak_content_tmpl_file,"id","my_content");
    }else{
        $ak_content_addr = Extractor->extract_cont_addr($ak_content_tmpl_file)  ;
    }    
    my $ak_title_addr = Extractor->extract_addrs($ak_content_tmpl_file,"id","my_title")  ;
    if(! $ak_title_addr ){
        $ak_title_addr = Extractor->extract_addrs($ak_content_tmpl_file,"_tag","title")  ;
    }
    print "\n版面链接位置\t",$addr;
    print "\n新闻链接位置\t",$cp_ak_addr;
    print "\n新闻内容位置\t",$ak_content_addr;
    print "\n新闻标题位置\t",$ak_title_addr;
    my @page_lks = Extractor->extract_links($index_uri,$addr);
#    append_file("page_lks_".$file_name,$sep_line);
#    append_file("page_lks_".$file_name,grep { $_=$_."\n"}@page_lks);
    my @ak_lks;
    foreach my $page_lk ( @page_lks){
        next if ($page_lk =~/^.*.pdf$/);
        next if ($page_lk =~/^.*.jpg$/);
        push @ak_lks ,Extractor->extract_links( $page_lk, $cp_ak_addr);
    }
    map {print $_,"\n";} @ak_lks; 
#######将文章链接存储##########
#    append_file("ar_lks_".$file_name,$sep_line);
#    append_file("ar_lks_".$file_name,grep { $_=$_."\n"}@ak_lks);

    print "版面数目",scalar @ak_lks ,"\n";
    my @visted_uris;
#    append_file("matched_".$file_name,$sep_line);
#    append_file("all_".$file_name,$sep_line);
    OUT:foreach my $ak_uri (@ak_lks){
        my $existed = 0;
        for my $v_uri (@visted_uris){
            if($ak_uri eq  $v_uri){
                $existed = 1;
                last ;
            }
        }
        if(!$existed){
            my $is_utf =$is_pp;#####数字报专用,都是utf8的
            print "抽取文章-----------------",$ak_uri,"\n";
            my $title=Extractor->extract_text($ak_uri,$ak_title_addr,$is_utf );
            print "标题---------", $title,"\n\n";
            my $text;#内容
            if($abbr =~/sfda/ ||$abbr =~/zjfda/){
                ##抽取多次
                foreach my $cont_addr (@cont_addrs){
                    print $ak_uri,"\n",$cont_addr,"\n";
                    my $text_part = Extractor->extract_text($ak_uri,$cont_addr,0);
                    print $text_part;
                    $text = $text." ".$text_part;
                    print $text,"\n";
                }

            }
            else
            {
                $text=Extractor->extract_text($ak_uri,$ak_content_addr,$is_utf );
            }

            my @lines =$ak_uri."\t".$title."\t".$text."\t".$dt->ymd." ".$dt->hms."\n";
            ########过滤的地方##########
            if(Filter->accept_it($text)){
#                append_file("matched_"."$file_name",@lines);
                $tag ="matched";
            DBWriter->insert_news($dbh,$tag,$abbr,$ak_uri, $title, $text);
            }
#            append_file("all_".$file_name,@lines);
            $title =decode("gbk",$title); 
            $tag ="visited";
            DBWriter->insert_news($dbh,$tag,$abbr,$ak_uri, $title, $text);
            push @visted_uris ,$ak_uri;
        }
    }
#    append_file($file_name."_visted",grep { $_=$_."\n"}@visted_uris);
    print "finished working.........";


    DBWriter->close_dbh($dbh) ;
}
