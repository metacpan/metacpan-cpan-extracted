use Combine::XWI;

use Test::More tests => 18;

#my %xwiData = (
#  ( 'recordid' => 'MyID', type => 'text/html', title => 'A title string',
#    'url' => 'http://www.it.lth.se/anders/',
#    'link => [
 
my $xwi = new Combine::XWI;

ok(defined($xwi), 'new()');
ok($xwi->isa('Combine::XWI'), 'right class');

$url_str= 'http://www.it.lth.se/anders/';
$xwi->recordid('MyID');
$xwi->type('text/html');
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

is($xwi->recordid, 'MyID', 'recordid()');
is($xwi->type, 'text/html', 'type()');
is($xwi->title, 'A title string', 'title()');

is($xwi->url, $url_str, 'url');
#$xwi->url_add($url_str);
#$xwi->url_add($url_str.'CV.html');

# headings
$xwi->heading_rewind;
my @head = ('head 1', 'My heading 2');
my $i=0;
while (1) {
        my $this = $xwi->heading_get or last; 
       is($this, $head[$i], "heading $i");
       $i++;
}

#links
 my @links=( ['', 75, 14523, 'anchor text', 'a'], ['http://www.it.lth.se/', 0, 0, 'anchor 2', 'img']);
 my $nlinks = $xwi->link_count;
 $xwi->link_rewind;
 $i=0;
 while(1) {
        my @val = $xwi->link_get;
        last if !defined($val[0]);
        is_deeply(\@val, $links[$i], "links $i");
        $i++;
 }
 is($nlinks,$i, 'link count');

#meta
 $xwi->meta_rewind;
 my @meta = ( ['meta1','valm1'], ['meta2','valm2'], ['meta3','valm3'] );
 $i=0;
     while (1) {
        my @val = $xwi->meta_get;
        last if !defined($val[0]);
        is_deeply(\@val, $meta[$i], "meta $i");
        $i++;
     } 

#robot
    my @robot = ( ['lang','en'], ['domain','com'] );
    $xwi->robot_rewind;
    $i=0;
    while (1) {
        my @val = $xwi->robot_get;
        last if !defined($val[0]);
        is_deeply(\@val, $robot[$i], "robot $i");
        $i++;
     }

#topic
    $xwi->topic_rewind;
    my @topic = ( ['cp.drosera',100,201,'drosera tätört','std'], ['673.2.3',123,456,'engineering, technical','pos'] );
    $i=0;
    while (1) {
        my @val = $xwi->topic_get;
        last if !defined($val[0]);
        is_deeply(\@val, $topic[$i], "topic $i");
        $i++;
     }

