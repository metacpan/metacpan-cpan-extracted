use strict;
local $^W = 1;
#warn('Ignore mkdir and chmod errors');
our $jobname;
require './t/defs.pm';
system("perl  \"-Iblib/lib\" blib/script/combineINIT --baseconfig ./blib/conf/ --jobname $jobname > /dev/null 2> /dev/null");

require Combine::Config;
use Cwd;
Combine::Config::Init($jobname,getcwd . '/blib/conf');

use Combine::XWI;
use Combine::MySQLhdb;

#config value doOAI??

use Test::More tests => 21;

my $xwi = new Combine::XWI;

my $recordid = 5;
my $url_str= 'http://www.it.lth.se/anders/';
$xwi->recordid($recordid);
$xwi->urlid(7);
$xwi->md5('71701223CA83546F151B17C493B64E55');
$xwi->type('text/html');
$xwi->modifiedDate(time);
$xwi->title('A title string');
$xwi->url($url_str);
$xwi->url_add($url_str);
$xwi->url_add($url_str.'CV.html');
$xwi->heading_add('head 1');
$xwi->heading_add('My heading 2');
#$xwi->link_add('', $netlocid, $urlid, Encode::decode('utf8',$anchor), $lty)
$xwi->link_add('', 75, 14523, 'anchor text', 'a');
$xwi->link_add('http://www.it.lth.se/', 0, 0, 'anchor 2', 'img');
#$xwi->meta_add(Encode::decode('utf8',$name),Encode::decode('utf8',$value)) ;
$xwi->meta_add('meta1','valm1') ;
$xwi->meta_add('meta2','valm2') ;
$xwi->meta_add('meta3','valm3') ;
#$xwi->robot_add($name,Encode::decode('utf8',$value)) ;
$xwi->robot_add('lang','en') ;
$xwi->robot_add('domain','com') ;
#$xwi->topic_add(Encode::decode('utf8',$cls),$absscore,$relscore,Encode::decode('utf8',$terms),$alg) ;
$xwi->topic_add('cp.drosera',100,201,'drosera tätört','std') ;
$xwi->topic_add('673.2.3',123,456,'engineering, technical','pos') ;

Combine::MySQLhdb::DeleteKey($recordid);
Combine::MySQLhdb::Write($xwi);
my $newxwi = new Combine::XWI;
$newxwi=Combine::MySQLhdb::Get($recordid);

is($newxwi->recordid, $recordid, 'recordid()');
#is($newxwi->urlid, 7, 'urlid()');
is($newxwi->type, 'text/html', 'type()');
#is($newxwi->md5, '71701223CA83546F151B17C493B64E55', 'md5()');
is($newxwi->title, 'A title string', 'title()');

#is($newxwi->url, $url_str, 'url');
#$newxwi->url_add($url_str);
#$newxwi->url_add($url_str.'CV.html');

# headings
$newxwi->heading_rewind;
my @head = ('head 1; My heading 2');
my $i=0;
while (1) {
        my $this = $newxwi->heading_get or last; 
       is($this, $head[$i], "heading $i");
       $i++;
}

#links
# my @links=( ['', 75, 14523, 'anchor text', 'a'], ['http://www.it.lth.se/', 0, 0, 'anchor 2', 'img']);
 my $nlinks = $newxwi->link_count;
 $newxwi->link_rewind;
 $i=0;
 while(1) {
        my @val = $newxwi->link_get;
        last if !defined($val[0]);
#        is_deeply(\@val, $links[$i], "links $i");
        $i++;
 }
 is($nlinks,$i, 'link count');

#meta
 $newxwi->meta_rewind;
 my %meta = ( 'meta3' => 'valm3', 'meta2' => 'valm2', 'meta1' => 'valm1' );
 $i=0;
     while (1) {
        my @val = $newxwi->meta_get;
        last if !defined($val[0]);
        is($meta{$val[0]}, $val[1], "meta $i");
        delete($meta{$val[0]});
        $i++;
     } 
 is(scalar(keys %meta),0,'Num meta');

#robot
    my %robot = ( 'outlinks' => $nlinks, 'hostinlinks' => 0, 'inlinks' => 0, 'domain' => 'com', 'lang' => 'en' );
    $newxwi->robot_rewind;
    $i=0;
    while (1) {
        my @val = $newxwi->robot_get;
        last if !defined($val[0]);
        is($robot{$val[0]}, $val[1], "robot $i");
        delete($robot{$val[0]});
        $i++;
     }
 is(scalar(keys %robot),0,'Num robot');

#topic
    $newxwi->topic_rewind;
    my @topic = ( ['673.2.3',123,456,'engineering, technical','pos'], ['cp.drosera',100,201,'drosera tätört','std'] );
    $i=0;
    while (1) {
        my @val = $newxwi->topic_get;
        last if !defined($val[0]);
	foreach my $j (0..$#topic) {
	  if ($val[0] eq ${$topic[$j]}[0]) {
            is_deeply(\@val, $topic[$j], "topic $j"); }
        }
        $i++;
     }
 is($i, $#topic+1, 'Num topic');

Combine::MySQLhdb::DeleteKey($recordid);
my $new2xwi = new Combine::XWI;
$new2xwi=Combine::MySQLhdb::Get($recordid);

is($new2xwi->recordid, $recordid, 'del recordid()');
isnt($new2xwi->type, 'text/html', 'del type()');
isnt($new2xwi->title, 'A title string', 'del title()');
