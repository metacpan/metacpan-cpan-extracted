#!/usr/bin/perl

use Test::More tests => 156;
use XML::Simple;
use Data::Dumper;

BEGIN {
    use_ok( 'Video::CPL' ) || print "Bail out!\n";
    use_ok( 'Video::CPL::Annotation' ) || print "Bail out!\n";
    use_ok( 'Video::CPL::AnnotationList' ) || print "Bail out!\n";
    use_ok( 'Video::CPL::Cue' ) || print "Bail out!\n";
    use_ok( 'Video::CPL::DirectoryList' ) || print "Bail out!\n";
    use_ok( 'Video::CPL::Layout' ) || print "Bail out!\n";
    use_ok( 'Video::CPL::MXML' ) || print "Bail out!\n";
    use_ok( 'Video::CPL::MXMLField' ) || print "Bail out!\n";
    use_ok( 'Video::CPL::Story' ) || print "Bail out!\n";
    use_ok( 'Video::CPL::Target' ) || print "Bail out!\n";
    use_ok( 'Video::CPL::TargetList' ) || print "Bail out!\n";
}

diag( "Testing Video::CPL $Video::CPL::VERSION, Perl $], $^X" );
#
#  Test that CPL is created correcty, written out to xml, and read in from XML.
#  First: test that it is created correctly. Create a CPL item and look through the data structure.
#
my $obj = new Video::CPL(videoSource=>'http://www.youtube.com/watch?v=0b75cl4-qRE',
       videoWidth=>500,
       videoHeight=>600,
       frameWidth=>1500,
       frameHeight=>1600,
       videoX=>100,
       videoY=>200,
       backgroundHTML=>'http://www.coincident.tv',
       xWebServiceLoc=>'http://www.foo.com/test.cgi?val="<1>"',
       loggingService=>'http://www.goo.com',
       skinButtons=>'/tmp',
       youtubeID=>'0b75cl4-qRE',
       xUniqueID=>'a1',
       xProgLevelDir=>"false",
       videoViewLayout=>"videol",
       webViewLayout=>"webl"
       );
ok(defined($obj),"create new Video::CPL");
ok($obj->isa("Video::CPL"),"Video::CPL correct type");
$obj->layout(name=>"webl",
        videoHeight=>100,
	videoVCenter=>200,
	videoTop=>300,
	videoBottom=>400,
	videoWidth=>500,
	videoHCenter=>600,
	videoLeft=>700,
	videoRight=>800,
	webHeight=>900,
	webVCenter=>1000,
	webTop=>1100,
	webBottom=>1200,
	webWidth=>1300,
	webHCenter=>1400,
	webLeft=>1500,
	webRight=>1600);
$obj->layout(name=>"videol");
my $s = new Video::CPL::Story(balloonText=>"test",
        forever=>"true",
	picLoc=>"http://www.foo.com/pic.jpg",
	picOverLoc=>"http://www.foo.com/picover.jpg");
my $anno = $obj->annotation(name=>"anno",
                 clickBehavior=>"goto",
		 targetList=>$obj->tl("#CPLBegin"),
		 x=>40,
		 y=>50,
		 story=>$s,
		 skipOnReturn=>"true",
		 showIcon=>"true",
		 alpha=>0.5);
$obj->cuebyname("CPLBegin")->addanno($anno);
$obj->cuebyname("CPLBegin")->tags("atag");
$obj->cuebyname("CPLBegin")->interestURL("http://www.zombies.com");
$obj->cuebyname("CPLBegin")->query("http://www.zombies.com/query?");
$obj->cuebyname("CPLBegin")->zeroLen("true");
$obj->cuebyname("CPLBegin")->cannotSkip("false");
$obj->cuebyname("CPLBegin")->pauseOnEntry("false");
$obj->cuebyname("CPLBegin")->modalOnEntry("false");
$obj->cuebyname("CPLBegin")->soft("false");
$obj->cuebyname("CPLBegin")->backgroundHTML("http://www.bg.com");
$obj->cuebyname("CPLBegin")->pauseOnDisplay("false");
$obj->cuebyname("CPLBegin")->webViewLayout("layout");

#our @FIELDS = qw(name clickBehavior x y skipOnReturn showIcon story alpha target parent);
ok($obj->videoSource() eq 'http://www.youtube.com/watch?v=0b75cl4-qRE',"videoSource set correctly");
ok($obj->xVersionCPL() eq '0.8.0',"xVersionCPL set correctly");
ok($obj->videoWidth() eq 500,"videoWidth set correctly");
ok($obj->videoHeight() eq 600,"videoHeight set correctly");
ok($obj->frameWidth() eq 1500,"frameWidth set correctly");
ok($obj->frameHeight() eq 1600,"frameHeight set correctly");
ok($obj->videoX() eq 100,"videoX set correctly");
ok($obj->videoY() eq 200,"videoY set correctly");
ok($obj->backgroundHTML() eq 'http://www.coincident.tv',"backgroundHTML set correctly");
ok($obj->xWebServiceLoc() eq 'http://www.foo.com/test.cgi?val="<1>"',"xWebServiceLoc set correctly");
ok($obj->loggingService() eq 'http://www.goo.com',"loggingService set correctly");
ok($obj->skinButtons() eq '/tmp',"skinButtons set correctly");
ok($obj->youtubeID() eq '0b75cl4-qRE',"youtubeID set correctly");
ok($obj->xUniqueID() eq 'a1',"xUniqueID set correctly");
ok($obj->xProgLevelDir() eq 'false',"xProgLevelDir set correctly");
ok($obj->webViewLayout() eq 'webl',"webViewLayout set correctly");
ok($obj->videoViewLayout() eq 'videol',"videoViewLayout set correctly");
ok(defined($obj->layoutbyname("webl")) &&
   ($obj->layoutbyname("webl")->videoHeight() == 100),"layout videoHeight set correctly");
ok(defined($obj->layoutbyname("webl")) &&
   ($obj->layoutbyname("webl")->videoVCenter() == 200),"layout videoVCenter set correctly");
ok(defined($obj->layoutbyname("webl")) &&
   ($obj->layoutbyname("webl")->videoTop() == 300),"layout videoTop set correctly");
ok(defined($obj->layoutbyname("webl")) &&
   ($obj->layoutbyname("webl")->videoBottom() == 400),"layout videoBottom set correctly");
ok(defined($obj->layoutbyname("webl")) &&
   ($obj->layoutbyname("webl")->videoWidth() == 500),"layout videoWidth set correctly");
ok(defined($obj->layoutbyname("webl")) &&
   ($obj->layoutbyname("webl")->videoHCenter() == 600),"layout videoHCenter set correctly");
ok(defined($obj->layoutbyname("webl")) &&
   ($obj->layoutbyname("webl")->videoLeft() == 700),"layout videoLeft set correctly");
ok(defined($obj->layoutbyname("webl")) &&
   ($obj->layoutbyname("webl")->videoRight() == 800),"layout videoRight set correctly");
ok(defined($obj->layoutbyname("webl")) &&
   ($obj->layoutbyname("webl")->webHeight() == 900),"layout webHeight set correctly");
ok(defined($obj->layoutbyname("webl")) &&
   ($obj->layoutbyname("webl")->webVCenter() == 1000),"layout webVCenter set correctly");
ok(defined($obj->layoutbyname("webl")) &&
   ($obj->layoutbyname("webl")->webTop() == 1100),"layout webTop set correctly");
ok(defined($obj->layoutbyname("webl")) &&
   ($obj->layoutbyname("webl")->webBottom() == 1200),"layout webBottom set correctly");
ok(defined($obj->layoutbyname("webl")) &&
   ($obj->layoutbyname("webl")->webWidth() == 1300),"layout webWidth set correctly");
ok(defined($obj->layoutbyname("webl")) &&
   ($obj->layoutbyname("webl")->webHCenter() == 1400),"layout webHCenter set correctly");
ok(defined($obj->layoutbyname("webl")) &&
   ($obj->layoutbyname("webl")->webLeft() == 1500),"layout webLeft set correctly");
ok(defined($obj->layoutbyname("webl")) &&
   ($obj->layoutbyname("webl")->webRight() == 1600),"layout webRight set correctly");
ok(defined($obj->annobyname("anno")) &&
   ($obj->annobyname("anno")->clickBehavior() eq "goto"),"annotation clickBehavior set correctly");
ok(defined($obj->annobyname("anno")) &&
   ($obj->annobyname("anno")->x() == 40),"annotation x set correctly");
ok(defined($obj->annobyname("anno")) &&
   ($obj->annobyname("anno")->y() == 50),"annotation y set correctly");
ok(defined($obj->annobyname("anno")) &&
   ($obj->annobyname("anno")->skipOnReturn() eq "true"),"annotation skipOnReturn set correctly");
ok(defined($obj->annobyname("anno")) &&
   ($obj->annobyname("anno")->showIcon() eq "true"),"annotation showIcon set correctly");
ok(defined($obj->annobyname("anno")) &&
   defined($obj->annobyname("anno")->story()) &&
   ($obj->annobyname("anno")->story()->balloonText() eq "test"),"annotation story balloonText set correctly");
ok(defined($obj->annobyname("anno")) &&
   defined($obj->annobyname("anno")->story()) &&
   ($obj->annobyname("anno")->story()->forever() eq "true"),"annotation story forever set correctly");
ok(defined($obj->annobyname("anno")) &&
   defined($obj->annobyname("anno")->story()) &&
   ($obj->annobyname("anno")->story()->picLoc() eq "http://www.foo.com/pic.jpg"),"annotation story picLoc set correctly");
ok(defined($obj->annobyname("anno")) &&
   defined($obj->annobyname("anno")->story()) &&
   ($obj->annobyname("anno")->story()->picOverLoc() eq "http://www.foo.com/picover.jpg"),"annotation story picOverLoc set correctly");
#FIGURE THIS OUT
#ok(defined($obj->cuebyname("CPLBegin")) &&
   #defined($obj->cuebyname("CPLBegin")->annotations()[0]) &&
   #$obj->cuebyname("CPLBegin")->annotations()[0]->na
   #
ok(defined($obj->cuebyname("CPLBegin")) &&
   $obj->cuebyname("CPLBegin")->tags() eq "atag","cuePt tags set correctly");
ok(defined($obj->cuebyname("CPLBegin")) &&
   $obj->cuebyname("CPLBegin")->interestURL() eq "http://www.zombies.com","cuePt interestURL set correctly");
ok(defined($obj->cuebyname("CPLBegin")) &&
   $obj->cuebyname("CPLBegin")->query() eq "http://www.zombies.com/query?","cuePt query set correctly");
ok(defined($obj->cuebyname("CPLBegin")) &&
   $obj->cuebyname("CPLBegin")->zeroLen() eq "true","cuePt zeroLen set correctly");
ok(defined($obj->cuebyname("CPLBegin")) &&
   $obj->cuebyname("CPLBegin")->cannotSkip() eq "false","cuePt cannotSkip set correctly");
ok(defined($obj->cuebyname("CPLBegin")) &&
   $obj->cuebyname("CPLBegin")->pauseOnEntry() eq "false","cuePt pauseOnEntry set correctly");
ok(defined($obj->cuebyname("CPLBegin")) &&
   $obj->cuebyname("CPLBegin")->modalOnEntry() eq "false","cuePt modalOnEntry set correctly");
ok(defined($obj->cuebyname("CPLBegin")) &&
   $obj->cuebyname("CPLBegin")->soft() eq "false","cuePt soft set correctly");
ok(defined($obj->cuebyname("CPLBegin")) &&
   $obj->cuebyname("CPLBegin")->backgroundHTML() eq "http://www.bg.com","cuePt backgroundHTML set correctly");
ok(defined($obj->cuebyname("CPLBegin")) &&
   $obj->cuebyname("CPLBegin")->pauseOnDisplay() eq "false","cuePt pauseOnDisplay set correctly");
ok(defined($obj->cuebyname("CPLBegin")) &&
   $obj->cuebyname("CPLBegin")->webViewLayout() eq "layout","cuePt webViewLayout set correctly");

#
# Second, test that everything makes it to the XML by reading it back in
#
my $xml = $obj->xml();
print "\n=========\n$xml\n";
ok(defined($xml) && length($xml),"XML was created");
my $x = XMLin($xml,ForceArray=>1);
ok(defined($x),"XML parsed");
ok(defined($x->{progLevelMetadata}[0]{videoSource}) &&
   ($x->{progLevelMetadata}[0]{videoSource} eq 'http://www.youtube.com/watch?v=0b75cl4-qRE'),"videoSource set in XML");
ok(defined($x->{progLevelMetadata}[0]{xVersionCPL}) &&
   ($x->{progLevelMetadata}[0]{xVersionCPL} eq '0.8.0'),"xVersionCPL set in XML");
ok(defined($x->{progLevelMetadata}[0]{videoWidth}) &&
   ($x->{progLevelMetadata}[0]{videoWidth} == 500),"videoWidth set in XML");
ok(defined($x->{progLevelMetadata}[0]{videoHeight}) &&
   ($x->{progLevelMetadata}[0]{videoHeight} == 600),"videoHeight set in XML");
ok(defined($x->{progLevelMetadata}[0]{frameWidth}) &&
   ($x->{progLevelMetadata}[0]{frameWidth} == 1500),"frameWidth set in XML");
ok(defined($x->{progLevelMetadata}[0]{frameHeight}) &&
   ($x->{progLevelMetadata}[0]{frameHeight} == 1600),"frameHeight set in XML");
ok(defined($x->{progLevelMetadata}[0]{videoX}) &&
   ($x->{progLevelMetadata}[0]{videoX} == 100),"videoX set in XML");
ok(defined($x->{progLevelMetadata}[0]{videoY}) &&
   ($x->{progLevelMetadata}[0]{videoY} == 200),"videoY set in XML");
ok(defined($x->{progLevelMetadata}[0]{backgroundHTML}) &&
   ($x->{progLevelMetadata}[0]{backgroundHTML} eq 'http://www.coincident.tv'),"backgroundHTML set in XML");
ok(defined($x->{progLevelMetadata}[0]{xWebServiceLoc}) &&
   ($x->{progLevelMetadata}[0]{xWebServiceLoc} eq 'http://www.foo.com/test.cgi?val="<1>"'),"xWebServiceLoc set in XML");
ok(defined($x->{progLevelMetadata}[0]{loggingService}) &&
   ($x->{progLevelMetadata}[0]{loggingService} eq 'http://www.goo.com'),"loggingService set in XML");
ok(defined($x->{progLevelMetadata}[0]{skinButtons}) &&
   ($x->{progLevelMetadata}[0]{skinButtons} eq '/tmp'),"skinButtons set in XML");
ok(defined($x->{progLevelMetadata}[0]{youtubeID}) &&
   ($x->{progLevelMetadata}[0]{youtubeID} eq '0b75cl4-qRE'),"youtubeID set in XML");
ok(defined($x->{progLevelMetadata}[0]{xUniqueID}) &&
   ($x->{progLevelMetadata}[0]{xUniqueID} eq 'a1'),"xUniqueID set in XML");
ok(defined($x->{progLevelMetadata}[0]{xProgLevelDir}) &&
   ($x->{progLevelMetadata}[0]{xProgLevelDir} eq 'false'),"xProgLevelDir set in XML");
ok(defined($x->{progLevelMetadata}[0]{webViewLayout}) &&
   ($x->{progLevelMetadata}[0]{webViewLayout} eq 'webl'),"webViewLayout set in XML");
ok(defined($x->{progLevelMetadata}[0]{webViewLayout}) &&
   ($x->{progLevelMetadata}[0]{videoViewLayout} eq 'videol'),"videoViewLayout set in XML");
ok(defined($x->{layouts}[0]{layout}{webl}{videoHeight}) &&
   ($x->{layouts}[0]{layout}{webl}{videoHeight} == 100),"layout videoHeight set in XML");
ok(defined($x->{layouts}[0]{layout}{webl}{videoVCenter}) &&
   ($x->{layouts}[0]{layout}{webl}{videoVCenter} == 200),"layout videoVCenter set in XML");
ok(defined($x->{layouts}[0]{layout}{webl}{videoTop}) &&
   ($x->{layouts}[0]{layout}{webl}{videoTop} == 300),"layout videoTop set in XML");
ok(defined($x->{layouts}[0]{layout}{webl}{videoBottom}) &&
   ($x->{layouts}[0]{layout}{webl}{videoBottom} == 400),"layout videoBottom set in XML");
ok(defined($x->{layouts}[0]{layout}{webl}{videoWidth}) &&
   ($x->{layouts}[0]{layout}{webl}{videoWidth} == 500),"layout videoWidth set in XML");
ok(defined($x->{layouts}[0]{layout}{webl}{videoHCenter}) &&
   ($x->{layouts}[0]{layout}{webl}{videoHCenter} == 600),"layout videoHCenter set in XML");
ok(defined($x->{layouts}[0]{layout}{webl}{videoLeft}) &&
   ($x->{layouts}[0]{layout}{webl}{videoLeft} == 700),"layout videoLeft set in XML");
ok(defined($x->{layouts}[0]{layout}{webl}{videoRight}) &&
   ($x->{layouts}[0]{layout}{webl}{videoRight} == 800),"layout videoRight set in XML");
ok(defined($x->{layouts}[0]{layout}{webl}{webHeight}) &&
   ($x->{layouts}[0]{layout}{webl}{webHeight} == 900),"layout webHeight set in XML");
ok(defined($x->{layouts}[0]{layout}{webl}{webVCenter}) &&
   ($x->{layouts}[0]{layout}{webl}{webVCenter} == 1000),"layout webVCenter set in XML");
ok(defined($x->{layouts}[0]{layout}{webl}{webTop}) &&
   ($x->{layouts}[0]{layout}{webl}{webTop} == 1100),"layout webTop set in XML");
ok(defined($x->{layouts}[0]{layout}{webl}{webBottom}) &&
   ($x->{layouts}[0]{layout}{webl}{webBottom} == 1200),"layout webBottom set in XML");
ok(defined($x->{layouts}[0]{layout}{webl}{webWidth}) &&
   ($x->{layouts}[0]{layout}{webl}{webWidth} == 1300),"layout webWidth set in XML");
ok(defined($x->{layouts}[0]{layout}{webl}{webHCenter}) &&
   ($x->{layouts}[0]{layout}{webl}{webHCenter} == 1400),"layout webHCenter set in XML");
ok(defined($x->{layouts}[0]{layout}{webl}{webLeft}) &&
   ($x->{layouts}[0]{layout}{webl}{webLeft} == 1500),"layout webLeft set in XML");
ok(defined($x->{layouts}[0]{layout}{webl}{webRight}) &&
   ($x->{layouts}[0]{layout}{webl}{webRight} == 1600),"layout webRight set in XML");

#
# Third, test that an object created using initctv on the above xml is set correctly
#
my $or = new Video::CPL(initfromctv=>$xml);
ok(defined($or),"initfromctv create new CPL");
ok($or->isa("Video::CPL"),"initfromctv CPL correct type");
ok($or->videoSource() eq 'http://www.youtube.com/watch?v=0b75cl4-qRE',"initfromctv videoSource set correctly");
ok($or->xVersionCPL() eq '0.8.0',"initfromctv xVersionCPL set correctly");
ok($or->videoWidth() eq 500,"initfromctv videoWidth set correctly");
ok($or->videoHeight() eq 600,"initfromctv videoHeight set correctly");
ok($or->frameWidth() eq 1500,"initfromctv frameWidth set correctly");
ok($or->frameHeight() eq 1600,"initfromctv frameHeight set correctly");
ok($or->videoX() eq 100,"initfromctv videoX set correctly");
ok($or->videoY() eq 200,"initfromctv videoY set correctly");
ok($or->backgroundHTML() eq 'http://www.coincident.tv',"initfromctv backgroundHTML set correctly");
ok($or->xWebServiceLoc() eq 'http://www.foo.com/test.cgi?val="<1>"',"initfromctv xWebServiceLoc set correctly");
ok($or->loggingService() eq 'http://www.goo.com',"initfromctv loggingService set correctly");
ok($or->skinButtons() eq '/tmp',"initfromctv skinButtons set correctly");
ok($or->youtubeID() eq '0b75cl4-qRE',"initfromctv youtubeID set correctly");
ok($or->xUniqueID() eq 'a1',"initfromctv xUniqueID set correctly");
ok($or->xProgLevelDir() eq 'false',"initfromctv xProgLevelDir set correctly");
ok($or->webViewLayout() eq 'webl',"initfromctv webViewLayout set correctly");
ok($or->videoViewLayout() eq 'videol',"initfromctv videoViewLayout set correctly");
ok(defined($or->layoutbyname("webl")) &&
   ($or->layoutbyname("webl")->videoHeight() == 100),"layout videoHeight set correctly");
ok(defined($or->layoutbyname("webl")) &&
   ($or->layoutbyname("webl")->videoVCenter() == 200),"layout videoVCenter set correctly");
ok(defined($or->layoutbyname("webl")) &&
   ($or->layoutbyname("webl")->videoTop() == 300),"layout videoTop set correctly");
ok(defined($or->layoutbyname("webl")) &&
   ($or->layoutbyname("webl")->videoBottom() == 400),"layout videoBottom set correctly");
ok(defined($or->layoutbyname("webl")) &&
   ($or->layoutbyname("webl")->videoWidth() == 500),"layout videoWidth set correctly");
ok(defined($or->layoutbyname("webl")) &&
   ($or->layoutbyname("webl")->videoHCenter() == 600),"layout videoHCenter set correctly");
ok(defined($or->layoutbyname("webl")) &&
   ($or->layoutbyname("webl")->videoLeft() == 700),"layout videoLeft set correctly");
ok(defined($or->layoutbyname("webl")) &&
   ($or->layoutbyname("webl")->videoRight() == 800),"layout videoRight set correctly");
ok(defined($or->layoutbyname("webl")) &&
   ($or->layoutbyname("webl")->webHeight() == 900),"layout webHeight set correctly");
ok(defined($or->layoutbyname("webl")) &&
   ($or->layoutbyname("webl")->webVCenter() == 1000),"layout webVCenter set correctly");
ok(defined($or->layoutbyname("webl")) &&
   ($or->layoutbyname("webl")->webTop() == 1100),"layout webTop set correctly");
ok(defined($or->layoutbyname("webl")) &&
   ($or->layoutbyname("webl")->webBottom() == 1200),"layout webBottom set correctly");
ok(defined($or->layoutbyname("webl")) &&
   ($or->layoutbyname("webl")->webWidth() == 1300),"layout webWidth set correctly");
ok(defined($or->layoutbyname("webl")) &&
   ($or->layoutbyname("webl")->webHCenter() == 1400),"layout webHCenter set correctly");
ok(defined($or->layoutbyname("webl")) &&
   ($or->layoutbyname("webl")->webLeft() == 1500),"layout webLeft set correctly");
ok(defined($or->layoutbyname("webl")) &&
   ($or->layoutbyname("webl")->webRight() == 1600),"layout webRight set correctly");
ok(defined($or->annobyname("anno")) &&
   ($or->annobyname("anno")->clickBehavior() eq "goto"),"annotation clickBehavior set correctly");
ok(defined($or->annobyname("anno")) &&
   ($or->annobyname("anno")->x() == 40),"annotation x set correctly");
ok(defined($or->annobyname("anno")) &&
   ($or->annobyname("anno")->y() == 50),"annotation y set correctly");
ok(defined($or->annobyname("anno")) &&
   ($or->annobyname("anno")->skipOnReturn() eq "true"),"annotation skipOnReturn set correctly");
ok(defined($or->annobyname("anno")) &&
   ($or->annobyname("anno")->showIcon() eq "true"),"annotation showIcon set correctly");
ok(defined($or->annobyname("anno")) &&
   defined($or->annobyname("anno")->story()) &&
   ($or->annobyname("anno")->story()->balloonText() eq "test"),"annotation story alpha set correctly");
ok(defined($or->annobyname("anno")) &&
   defined($or->annobyname("anno")->story()) &&
   ($or->annobyname("anno")->story()->forever() eq "true"),"annotation story forever set correctly");
ok(defined($or->annobyname("anno")) &&
   defined($or->annobyname("anno")->story()) &&
   ($or->annobyname("anno")->story()->picLoc() eq "http://www.foo.com/pic.jpg"),"annotation story picLoc set correctly");
ok(defined($or->annobyname("anno")) &&
   defined($or->annobyname("anno")->story()) &&
   ($or->annobyname("anno")->story()->picOverLoc() eq "http://www.foo.com/picover.jpg"),"annotation story picOverLoc set correctly");
ok(defined($or->cuebyname("CPLBegin")) &&
   $or->cuebyname("CPLBegin")->tags() eq "atag","cuePt tags set correctly");
ok(defined($or->cuebyname("CPLBegin")) &&
   $or->cuebyname("CPLBegin")->interestURL() eq "http://www.zombies.com","cuePt interestURL set correctly");
ok(defined($or->cuebyname("CPLBegin")) &&
   $or->cuebyname("CPLBegin")->query() eq "http://www.zombies.com/query?","cuePt query set correctly");
ok(defined($or->cuebyname("CPLBegin")) &&
   $or->cuebyname("CPLBegin")->zeroLen() eq "true","cuePt zeroLen set correctly");
ok(defined($or->cuebyname("CPLBegin")) &&
   $or->cuebyname("CPLBegin")->cannotSkip() eq "false","cuePt cannotSkip set correctly");
ok(defined($or->cuebyname("CPLBegin")) &&
   $or->cuebyname("CPLBegin")->pauseOnEntry() eq "false","cuePt pauseOnEntry set correctly");
ok(defined($or->cuebyname("CPLBegin")) &&
   $or->cuebyname("CPLBegin")->modalOnEntry() eq "false","cuePt modalOnEntry set correctly");
ok(defined($or->cuebyname("CPLBegin")) &&
   $or->cuebyname("CPLBegin")->soft() eq "false","cuePt soft set correctly");
ok(defined($or->cuebyname("CPLBegin")) &&
   $or->cuebyname("CPLBegin")->backgroundHTML() eq "http://www.bg.com","cuePt backgroundHTML set correctly");
ok(defined($or->cuebyname("CPLBegin")) &&
   $or->cuebyname("CPLBegin")->pauseOnDisplay() eq "false","cuePt pauseOnDisplay set correctly");
ok(defined($or->cuebyname("CPLBegin")) &&
   $or->cuebyname("CPLBegin")->webViewLayout() eq "layout","cuePt webViewLayout set correctly");
   

if(1){
    print Dumper($obj);
    print "\n---that was obj now XMLIN====\n";
    print Dumper($x);
    print "\n====From initctv\n";
    print Dumper($or);
}
