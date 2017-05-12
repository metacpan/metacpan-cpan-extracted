#!/usr/bin/perl -w

BEGIN {print "1..13\n"}
END {print "not ok 1\n" unless $loaded;}

use WWW::Link::Repair::Substitutor;

#$::verbose=0xFF;
$::verbose=0 unless defined $::verbose;
$WWW::Link::Repair::Substitutor::verbose=0xFFF if $::verbose;

$loaded = 1;

sub nogo {print "not "}
sub ok {my $t=shift; print "ok $t\n";}

#create substitutiors

#$WWW::Link::Repair::Substitutor::verbose=0xFFFF;
$linksubs = WWW::Link::Repair::Substitutor::gen_substitutor
  (
   "http://bounce.bounce.com/frodo/dogo",
   "http://thing.thong/ding/dong",
  );
#$WWW::Link::Repair::Substitutor::verbose=0;


ref $linksubs or nogo;
ok(1);

#create substitutiors

$fragtolinksubs = WWW::Link::Repair::Substitutor::gen_substitutor
  (
   "http://bounce.bounce.com/frodo/dogo#middle",
   "http://thing.thong/ding/dong",
  );


ref $fragtolinksubs or nogo;
ok(2);

#create substitutiors

$linktofragsubs = WWW::Link::Repair::Substitutor::gen_substitutor
  (
   "http://bounce.bounce.com/frodo/dogo",
   "http://thing.thong/ding/dong#middle",
  );


ref $linktofragsubs or nogo;
ok(3);

#check we don't create an invalid tree subtitutor with a fragment.
$badsubs=undef;
eval {
    $badsubs = WWW::Link::Repair::Substitutor::gen_substitutor
	(
	 "http://bounce.bounce.com/frodo/dogo",
	 "http://thing.thong/ding/dong#middle",
	 1, #directory substitution
	 );
};

nogo unless $@;
ok(4);

$dirsubs = WWW::Link::Repair::Substitutor::gen_substitutor
  (
   "http://bounce.bounce.com/frodo/dogo" ,
   "http://thing.thong/ding/dong",
   1, #directory substitution
  );

ref $dirsubs or nogo;
ok(5);

#check that they substitute right

$start = 'this is some text <A HREF="http://bounce.bounce.com/frodo/dogo">';
$target = 'this is some text <A HREF="http://thing.thong/ding/dong">';

$subsme=$start;
&$linksubs($subsme); 
$subsme eq $target or nogo;
ok(6);

#check that the fragment substitutor works

$start = 'this is some text <A HREF="http://bounce.bounce.com/frodo/dogo">';
$target = 'this is some text <A HREF="http://thing.thong/ding/dong#middle">';

$subsme=$start;
&$linktofragsubs($subsme);
$subsme eq $target or nogo;
ok(7);

#check that fragments are substituted correctly by the normal substitutor

$start = 'this is some text <A HREF="http://bounce.bounce.com/frodo/dogo#middle">';
$target = 'this is some text <A HREF="http://thing.thong/ding/dong#middle">';

$subsme=$start;
print "before: $subsme \n" if $verbose;
&$linksubs($subsme);
print "after : $subsme \n" if $verbose;
$subsme eq $target or nogo;
ok(8);


#check that fragments are substituted correctly by the tree subs

$start = 'this is some text <A HREF="http://bounce.bounce.com/frodo/dogo/woggo#middle">';
$target = 'this is some text <A HREF="http://thing.thong/ding/dong/woggo#middle">';

$subsme=$start;
&$dirsubs($subsme);
$subsme eq $target or nogo;
ok(9);



#check behavior on directory substitutions

$start = 'this is some text <A HREF="http://bounce.bounce.com/frodo/dogo/woggo">';
$target = 'this is some text <A HREF="http://thing.thong/ding/dong/woggo">';


$subsme=$start;
&$dirsubs($subsme);
$subsme eq $target or nogo;
ok(10);

#check linksubs DOESN'T change.
$subsme=$start;
&$linksubs($subsme);
$subsme eq $start or nogo;
ok(11);


$start = 'this is some text <A HREF="woggo">';
$target = 'this is some text <A HREF="http://thing.thong/ding/dong">';

#now try relative substitution

$relsubs = WWW::Link::Repair::Substitutor::gen_substitutor
  (
   "http://bounce.bounce.com/frodo/woggo",
   "http://thing.thong/ding/dong",
   1,
   "http://bounce.bounce.com/frodo/dogo",
  );

ref $linksubs or nogo;
ok(12);

$subsme=$start;
&$relsubs($subsme);
$subsme eq $target or nogo;
ok(13);

