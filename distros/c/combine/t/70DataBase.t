use strict;
local $^W = 0;
our $jobname;
require './t/defs.pm';
system("perl  \"-Iblib/lib\" blib/script/combineINIT --baseconfig ./blib/conf/ --jobname $jobname > /dev/null 2> /dev/null");

use Combine::XWI;
use Combine::Config;
use Combine::LogSQL;
use Combine::DataBase;
use Cwd;
Combine::Config::Init($jobname,getcwd . '/blib/conf');

use Test::More tests => 23;

my $xwi = new Combine::XWI;
my $text = 'My text in record';
my $url_str= 'http://www.it.lth.se/anders/';
$xwi->urlid(7);
#Is now set in DataBase: $xwi->md5('71701223CA83546F151B17C493B64E55');
$xwi->modifiedDate(time);
$xwi->type('text/html');
$xwi->title('A title string');
$xwi->url($url_str);
$xwi->url_add($url_str);
$xwi->text(\$text);
$xwi->heading_add('head 1');
$xwi->heading_add('My heading 2');
#$xwi->link_add('', $netlocid, $urlid, Encode::decode('utf8',$anchor), $lty)
$xwi->link_add('http://www.it.lth.se/anders/CV.html', 0, 0, 'anchor text', 'a');
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

my $sv = Combine::Config::Get('MySQLhandle');
my $log = new Combine::LogSQL "testFromHTML";
Combine::Config::Set('LogHandle', $log);
my $xhdb = new Combine::DataBase( $xwi, $sv, $log);

my($recordid, $recordid1, $recordid2, $md5, $uid1, $uid2, $md52, $md51);

$xhdb->insert; #CASE 5
my $sth =  $sv->prepare(qq{SELECT recordid,md5 FROM recordurl});
$sth->execute;
($recordid,$md5) = $sth->fetchrow_array();
is($md5,'4A71E83AE8E353A06D19FACB2EC4A3F6', 'md5 CASE 5');
my ($t,$t5) = $sth->fetchrow_array();
ok(!defined($t), 'num records case 5');

$xhdb->insert; #CASE 1
$sth =  $sv->prepare(qq{SELECT recordid,md5 FROM recordurl});
$sth->execute;
($recordid,$md5) = $sth->fetchrow_array();
is($md5,'4A71E83AE8E353A06D19FACB2EC4A3F6', 'md5 CASE 1');
($t,$t5) = $sth->fetchrow_array();
ok(!defined($t), 'num records case 1');

#$xwi->md5('71701223CA83546F151B17C493B64E56'); #new value
$text='My new text in record'; #new value => new md5 082247E3E13DE8C0E2C79C7C5497C856
$xwi->text(\$text);

$xhdb->insert; #CASE 4
$sth =  $sv->prepare(qq{SELECT recordid,md5 FROM recordurl});
$sth->execute;
($recordid,$md5) = $sth->fetchrow_array();
is($md5,'F619D8E87F5AFC7C2F75A5C7062C67DF', 'md5 CASE 4');
($t,$t5) = $sth->fetchrow_array();
ok(!defined($t), 'num records case 4');

$xhdb->delete;
$sth =  $sv->prepare(qq{SELECT recordid,md5 FROM recordurl});
$sth->execute;
($t,$t5) = $sth->fetchrow_array();
ok(!defined($t), 'delete record');

$xhdb->insert; #CASE 3
$xwi->url($url_str.'index.html');
$xwi->urlid(8);
$xhdb->insert; #CASE 3
$sth =  $sv->prepare(qq{SELECT recordid,urlid,md5 FROM recordurl});
$sth->execute;
($recordid,$uid1,$md5) = $sth->fetchrow_array();
($recordid2,$uid2,$md52) = $sth->fetchrow_array();
is($md5,$md52, 'md5 equal case 3');
is($recordid,$recordid2, 'recordid equal case 3');
isnt($uid1,$uid2, 'urlid differ case 3');
($t,$t5) = $sth->fetchrow_array();
ok(!defined($t), 'num records case 3');

$xwi->urlid(7);
$xwi->url($url_str);
$xhdb->delete;
$sth =  $sv->prepare(qq{SELECT recordid,urlid,md5 FROM recordurl});
$sth->execute;
($recordid,$uid1,$md5) = $sth->fetchrow_array();
is($md5,'F619D8E87F5AFC7C2F75A5C7062C67DF', 'md5 1 del');
is($uid1, 8, 'uid after 1 del');
($t,$t5) = $sth->fetchrow_array();
ok(!defined($t), 'num records 1 del');

$xwi->urlid(8);
$xwi->url($url_str.'index.html');
$xhdb->delete;
$sth =  $sv->prepare(qq{SELECT recordid,md5 FROM recordurl});
$sth->execute;
($t,$t5) = $sth->fetchrow_array();
ok(!defined($t), 'no records 2 del');

$xhdb->insert; #urlid=8; md5=..6
$xwi->urlid(7);
$xwi->url($url_str);
$xwi->md5('71701223CA83546F151B17C493B64E57');
$xhdb->insert;#urlid=7; md5=..7
$xwi->urlid(8);
$xhdb->insert;#urlid=8; md5=..7 #CASE 2
$sth =  $sv->prepare(qq{SELECT recordid,urlid,md5 FROM recordurl});
$sth->execute;
($recordid1,$uid1,$md51) = $sth->fetchrow_array();
($recordid2,$uid2,$md52) = $sth->fetchrow_array();
is($md51, $md52, 'md5 equal case 2');
isnt($uid1,$uid2, 'urlid differ case 2');
is($recordid1,$recordid2, 'recordid equal case 2');
($t,$t5) = $sth->fetchrow_array();
ok(!defined($t), 'num records case 2');

$xwi->location('http://combine.it.lth.se/');
$xwi->base('http://combine.it.lth.se/');
$xhdb->insert;
$xhdb->newRedirect;
$xhdb->newLinks;
my %links = ('http://www.it.lth.se/anders/CV.html' => 1,
             'http://www.it.lth.se/' => 1,
	     'http://combine.it.lth.se/' => 1
);
$sth =  $sv->prepare(qq{SELECT urlstr FROM newlinks,urls WHERE newlinks.urlid=urls.urlid});
$sth->execute;
my ($url1) = $sth->fetchrow_array();
ok(defined($links{$url1}), 'link 1'); delete($links{$url1});
($url1) = $sth->fetchrow_array();
ok(defined($links{$url1}), 'link 2'); delete($links{$url1});
($url1) = $sth->fetchrow_array();
ok(defined($links{$url1}), 'link 3'); delete($links{$url1});
($t) = $sth->fetchrow_array();
ok(!defined($t), 'num newlinks');
