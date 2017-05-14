use Fetcher;
use strict;
use Carp;
use Extractor;
sub f{
    #################################
    #抓取特定网址，制作模板页面用
    #################################
    my ($seed,$fh) =@_;
    $fh    = *STDOUT{IO} unless defined $fh;
    print $fh Fetcher->fetch($seed);

}

=begin  BlockComment  # BlockCommentNo_1


my $seed = shift;
f($seed);

=end    BlockComment  # BlockCommentNo_1

=cut


my $seed = shift;
if($seed){
    f($seed);

}else{

    use File::Slurp;
    use threads;
    my $fn = "fetch_targets.tsv";
    $fn = "tgs.txt";
    my @targets= read_file($fn);
    my @thrs;
    for my $line (@targets[0..scalar @targets]){
        print $line;
        $line =~s/\n//g;
        next if $line =~/^\s*$/;
        my $thr = threads->create('f2', $line);
        push @thrs ,$thr;
    }

    for(@thrs){
        $_->join();
    }
}
sub f2{
    my $line = shift;
#    my ($name,$is_paper,$abbr,$seed)=split(/\t/,$line);
my ($v,$is_paper,$abbr,$seed,$nav_tmpl_file,$ak_tmpl_file,$ak_content_tmpl_file,$ak_content)
= split(/\t/,$line);
    
    use IO::File (); 
    my $fh = new IO::File ("> ./tt/$abbr"."_ak.tmpl");
    my $fh2 = new IO::File ("> ./tt/$abbr"."_nav.tmpl");
    my $fh3 = new IO::File ("> ./tt/$abbr"."_ak_content.tmpl");
    if($is_paper){
        $seed = Extractor-> extract_nav_link($seed,$is_paper);
    }
    f($seed,$fh);
    f($seed,$fh2);
    f($ak_content,$fh3);
}
