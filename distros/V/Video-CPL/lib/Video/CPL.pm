package Video::CPL;

use warnings;
use strict;
use Carp;
use Data::Dumper;
use Fcntl;
use File::Temp;
use File::Path qw(make_path);
use List::Util qw(shuffle);
use LWP::Simple;
use XML::Simple;
use XML::Writer;

use Video::CPL::Cue;
use Video::CPL::Annotation;
use Video::CPL::Story;
use Video::CPL::Layout;

our $VAR1; #useful for evals

=head1 NAME

Video::CPL - Create and manipulate Coincident TV Programming Language (CPL) files.

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

Video::CPL provides an object-oriented module for creating CPL files. CPL files control interactive video experiences.

A simple example might be displaying a video, e.g. from Youtube, in a player on a webpage.

A more complex example might include images, which the user clicks on to jump to other videos. 

In conjunction with CGI.pm it is straightforward to create fully interactive web pages with dynamically created video experiences.

Video::CPL does not create the video file itself; it works with videos on services such as Youtube, or created with tools such as Video::FFmpeg.

A tutorial is available at http://metabase.coincident.tv/cpan.

Short code sample: create a file using CPL, and then embed a link to the file in your html as shown below.

    use CPL;
    my $ctv = new Video::CPL(videoSource=>"http://www.youtube.com/watch?v=0ZexPPDLXRA"
                             html=>$htmlfilelocation);
    $ctv->programEnd(30);   #end after 30 seconds
    print $ctv->print(); #prints out cpl file

    #and then, when writing html:
    print $ctv->embed();  #print out an HTML embed pointing to the temporary file

=head1 METHODS

=head2 new(videoSource=>$url,[backgroundHTML=>$url,frameHeight=>$k,
           frameWidth=>$k,loggingService=>$url,skinButtons=>$url,
	   videoHeight=>$k,videoViewLayout=>$name,videoWidth=>$k,
	   videoX=>$k,videoY=>$k,webViewLayout=>$name,
	   xUniqueID=$string,xVersionCPL=>$string,
	   xWebServiceLog=>$string],[html=>$loc,ref=>$url],[htmldir=>$dir,htmlurl=>$url)
       or
       new(initfromctv=$urlORxml);

    Create a new Video::CPL object. There is one videoSource per Video::CPL object.

    A videoSource such as videoSource=>"http://www.youtube.com/watch?v=0b75cl4-qRE", must be specified unless initializing from another Video::CPL file. All other parameters are optional; most of them are specified in the CPL language definition available from Coincident.tv. Additional file placement options are described below.

    initfromctv=>"foo.ctv" . Given a string which is either valid XML or a filename, use it to initialize the Video::CPL object.

    If the Video::CPL object will be output using the <b>xml()</b> method, there is no need to specify a location for it. It is convenient to specify a location where the Video::CPL XML can be accessed, if multiple Video::CPL objects interact, or if the <b>embed</b> or <b>print</b> methods will be used. 

    For automatic creation of a Video::CPL file, the location of a directory where the file can be created, along with the matching URL to reach that location, must be provided. An example would be <b>htmldir="/var/www/tmp"</b> and <b>htmlref=>"http://www.foo.com/tmp" </b>


=cut

sub new {
    my $pkg = shift;
    my %parms = @_;
    my $ret = {};
    bless $ret,$pkg;

    $ret->{xVersionCPL} = $parms{xVersionCPL} || "0.8.0";

    #The directory on the host system which is the top level html directory.
    #normally used in embed when printing out the html. 
    #If not used, i.e. if you are collecting the ctv and placing it yourself, this can be invalid.
    $ret->{html} = $parms{html} || $ENV{CPLDIR};

    #ref is the base of the URL to be used for intra-ctv references. It should point to the same location as html
    $ret->{ref} = $parms{ref} || $ENV{CPLURL};

    #XML-isms
    $ret->{'xsi:noNamespaceSchemaLocation'} = $parms{'xsi:noNamespaceSchemaLocation'} || ($ret->{xVersionCPL} eq "0.7.0")?"CPL_v0.7_validator.xsd":"CPL_v0.8_validator.xsd";
    $ret->{'xmlns:xsi'} = $parms{'xmlns:xsi'} || "http://www.w3.org/2001/XMLSchema-instance";

    $ret->parsectv($parms{initfromctv}) if $parms{initfromctv};
    warn("CPL new v1($parms{v1})\n");
    $ret->v1($parms{v1}) if exists $parms{v1};
    delete $parms{v1} if exists $parms{v1};
    $ret->v2($parms{v2}) if exists $parms{v2};
    delete $parms{v2} if exists $parms{v2};
    $ret->v3($parms{v3}) if exists $parms{v3};
    delete $parms{v3} if exists $parms{v3};
    #check parameters; confess on typos etc.
    foreach my $q (keys %parms){
	next if $q =~ /xVersionCPL|videoSource|videoWidth|videoHeight|backgroundHTML|xWebServiceLoc|xUniqueID|xProgLevelDir|loggingService|html|ref|xsi:noNamespaceSchemaLocation|xmlns:xsi|xProgLevelData|skinButtons|webViewLayout|videoViewLayout|frameWidth|frameHeight|videoX|videoY|youtubeID|initfromctv/;
	confess("new CPL does not know what to do with parameter($q)\n");
    }

    foreach my $q (qw(xVersionCPL videoSource videoWidth videoHeight backgroundHTML xWebServiceLoc xUniqueID xProgLevelDir loggingService xProgLevelData skinButtons webViewLayout videoViewLayout frameWidth frameHeight videoX videoY youtubeID)){
	$ret->{$q} = $parms{$q} if defined($parms{$q});
    }

    #Errors: no source file specified
    #Error: parameter given but not used
    ##Errors: no source file specified
    #Error: parameter given but not used
    if (!defined($parms{initfromctv})){
	$ret->{cuePoints} = [];
	$ret->{cuePoints}[0] = Video::CPL::Cue->new(name=>"CPLBegin",time=>0,cueType=>"regular",parent=>$ret);
    }

    if (exists($parms{htmlurl})){
        $ret->{htmlrel} = $parms{htmlrel} || ".";
	$ret->{htmlurl} = $parms{htmlurl};
    } elsif (defined($ret->{html})){
	#open up a temporary file now to avoid race conditions. Might not even be used.
	my $fh = File::Temp->new(UNLINK=>0,DIR=>"$ret->{html}",SUFFIX=>".ctv");
	my $filename = $fh->filename;
	$ret->{fullfilename} = $filename;
	chmod 0644,$filename;
	$filename =~ s/.*\///;
	$ret->{ctvfilename} = $filename;
	$ret->{fh} = $fh;
    }
    return $ret;
}

sub datepref {
    my $x = shift;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($x);
    $year+=1900;
    $mon++;
    $mon = "0".$mon if length($mon) == 1;
    $mday = "0".$mday if length($mday) == 1;
    return "$year-$mon-$mday";
}

sub fixfile {
    my $obj = shift;
    return if $obj->{filefixed};
    my $dseg = datepref($^T); #convert time of script starting to 2010-01-01 format
    $obj->{htmlrel} = "." if !exists($obj->{htmlrel});
    my $dir = $obj->{htmlrel}."/".$dseg;
    make_path($dir) if !-d $dir;
    confess("$0: Video::CPL Fatal Error. Could not create or access directory ($dir).\n") if !-d $dir;
    #create file with File::Temp chmod 0644 etc.
    my $fh = File::Temp->new(UNLINK=>0,DIR=>$dir,SUFFIX=>".ctv");
    $obj->{fh} = $fh;
    my $filename = $fh->filename;
    chmod 0644,$filename;
    $filename =~ s/.*\///;
    $obj->{ctvfilename} = $filename;
    $obj->{relfilename} = "$dir/$filename";
    $obj->{relfilename} =~ s/^\.\///;   #if we are ./foo.ctv become foo.ctv
    $obj->{relfilename} =~ s/\/\//\//g;
    $obj->{url} = $obj->{htmlurl}."/$dseg/$filename";
    #set full relative pathname and fh
    $obj->{filefixed} = 1;;
    return;
}

=head2 asurl()

    Returns the URL which will recreate this URL. This will be a file or a reference to this script.

    Used when creating the media parameter for the CTV player, which requires a full URL.

=cut

sub asurl {
    my $obj = shift;

    confess("$0: Fatal Error. URL reference to a Video::CPL object which is marked 'noref'.\n") if $obj->{noref};

    if ($obj->{isdyn}){
        confess("NYI");
    } else {
        $obj->fixfile() if !$obj->{filefixed};
	return $obj->{url};
    }
}

=head2 asrel([$otherCPL])

    Returns the URL fragment (e.g. foo/goo.ctv) which will access this file from the current directory. If given
    a parameter of another Video::CPL object, will return a URL fragment which is valid in that objects context.

=cut

sub asrel {
    my $obj = shift;
    #optional second param. Return from the perspective of this cpl.
    confess("$0: Fatal Error. URL reference to a Video::CPL object which is marked 'noref'.\n") if $obj->{noref};

    if ($obj->{isdyn}){
        confess("NYI");
    } else {
        $obj->fixfile() if !$obj->{filefixed};
        return $obj->{relfilename};
    }
}

sub asreldir {
    my $obj = shift;
    my $x = $obj->asrel();
    return $1 if $x =~ /^(.*)\//; #normal case, foo/goo/hoo.ctv, return foo/goo
    return "."; #if there was no slash, current directory
}

sub asreltail {
    my $obj = shift;
    my $x = $obj->asrel();
    return $1 if $x =~ /^.*\/(.*)$/; #normal case, foo/goo/hoo.ctv, return hoo.ctv
    return "$x"; #if there was no slash, return self
}

sub reffrom {
    my $obj = shift;
    my $from = shift;
    if ($from && ($from != $obj)){
        if ($obj->{noref}){
	    warn("Video::CPL: this object has noref set, cannot be referenced from other objects, fatal error.\n");
	    return undef;
	}
    } else {
        return $obj->{tail};
    }
}

#=head2 tmpfile(ext=>".ctv")
#
#     Create a temporary file. Return the filehandle, and an address usable in the current CTV.
#
#=cut
#
#sub tmpfile {
#    my $obj = shift;
#    my %p = @_;
#    confess; #this is a placeholder
#}

=head2 xVersionCPL([$string])

    Accessor routine to set or read xVersionCPL.

=cut

sub xVersionCPL { my $obj = shift; $obj->{xVersionCPL} = shift if @_; return $obj->{xVersionCPL};};

=head2 videoSource([$url])

    Accessor routine to set or read videoSource. 

=cut

sub videoSource { my $obj = shift; $obj->{videoSource} = shift if @_; return $obj->{videoSource};};

=head2 xWebServiceLoc([$url])

    Accessor routine to set or read xWebServiceLoc.

=cut

sub xWebServiceLoc { my $obj = shift; $obj->{xWebServiceLoc} = shift if @_; return $obj->{xWebServiceLoc};};

=head2 loggingService([$url])

    Accessor routine to set or read loggingService.

=cut

sub loggingService { my $obj = shift; $obj->{loggingService} = shift if @_; return $obj->{loggingService};};

=head2 skinButtons([$url])

    Accessor routine to set or read skinButtons. These are optional, and used to form the control bar.

=cut

sub skinButtons { my $obj = shift; $obj->{skinButtons} = shift if @_; return $obj->{skinButtons};};

=head2 backgroundHTML([$url])

    Accessor routine to set or read backgroundHTML.

=cut

sub backgroundHTML { my $obj = shift; $obj->{backgroundHTML} = shift if @_; return $obj->{backgroundHTML};};

=head2 videoWidth([$string])

    Accessor routine to set or read videoWidth (the width of the video image within the overall CPL layout).

=cut

sub videoWidth { my $obj = shift; $obj->{videoWidth} = shift if @_; return $obj->{videoWidth};};

=head2 videoHeight([$string])

    Accessor routine to set or read videoHeight (the height of the video image).

=cut

sub videoHeight { my $obj = shift; $obj->{videoHeight} = shift if @_; return $obj->{videoHeight};};

=head2 frameWidth([$string])

    Accessor routine to set or read frameWidth (the width of the entire CPL frame).

=cut

sub frameWidth { my $obj = shift; $obj->{frameWidth} = shift if @_; return $obj->{frameWidth};};

=head2 frameHeight([$string])

    Accessor routine to set or read frameHeight (the height of the entire CPL frame).

=cut

sub frameHeight { my $obj = shift; $obj->{frameHeight} = shift if @_; return $obj->{frameHeight};};

=head2 videoX([$string])

    Accessor routine to set or read videoX.

=cut

sub videoX { my $obj = shift; $obj->{videoX} = shift if @_; return $obj->{videoX};};

=head2 videoY([$string])

    Accessor routine to set or read videoY.

=cut

sub videoY { my $obj = shift; $obj->{videoY} = shift if @_; return $obj->{videoY};};

=head2 videoViewLayout([$layoutname])

    Accessor routine to set or read videoViewLayout.

=cut

sub videoViewLayout { my $obj = shift; $obj->{videoViewLayout} = shift if @_; return $obj->{videoViewLayout};};

=head2 webViewLayout([$layoutname])

    Accessor routine to set or read webViewLayout.

=cut

sub webViewLayout { my $obj = shift; $obj->{webViewLayout} = shift if @_; return $obj->{webViewLayout};};

=head2 youtubeID([$id])

    Accessor routine to set or read youtubeID.

=cut

sub youtubeID { my $obj = shift; $obj->{youtubeID} = shift if @_; return $obj->{youtubeID};};

=head2 xUniqueID([$id])

    Accessor routine to set or read xUniqueID.

=cut

sub xUniqueID { my $obj = shift; $obj->{xUniqueID} = shift if @_; return $obj->{xUniqueID};};

=head2 xProgLevelDir([$id])

    Accessor routine to set or read xProgLevelDir.

=cut

sub xProgLevelDir { my $obj = shift; $obj->{xProgLevelDir} = shift if @_; return $obj->{xProgLevelDir};};

=head2 video([$video1,$video2,$video3}])

    Accessor routine for the video field, which contains an array of three different video sources which can be used.
    Returns an array, or undef if it has not been set.
    Takes an array of 3 urls.
    There is no way to set an individual URL with this accessor; read and then write to set one.

=cut

sub video {
    my $obj = shift;
    if (@_){
        if ($obj->{video}){
	    warn("Video called with ".join('/',@_).", video exists\n");
	    my @a = @{$obj->{video}[0]{source}};
	    my @new = @_;
	    #who knows if the number of video fields will change in the future
	    confess("confused on video a $#a new $#new\n") if ($#a != $#new) && (($#a != 2) || ($#new != 2));
	    foreach my $ia (0..$#a){
		my %h = %{$a[$ia]};
		$h{src} = $new[$ia];
	    }
	    warn("Video returning ".join('/',@new)."\n");
	    return @new;
	} else {
	    warn("Video called with ".join('/',@_).", video does not exist\n");
	    $obj->{video} = [{source => []}];
	    foreach my $s (@_){
	        push @{$obj->{video}[0]{source}},{src => $s};
	    }
	    warn("Video returning ".join('/',@_)."\n");
	    return @_;
	}
    } else {
        warn("Video not there, returning undefs\n") if !$obj->{video};
        return (undef,undef,undef) if !$obj->{video};
	my @a = @{$obj->{video}[0]{source}};
	my @ret;
	foreach my $ia (0..$#a){
	    my %h = %{$a[$ia]};
	    push @ret,$h{src};
	}
	warn("Video accessor returning ".join('/',@ret)."\n");
	return @ret;
    }
}

=head2 v1($url)
  
    Accessor routine to get or set the first element of the video array.

=cut

sub v1 {
    my $obj = shift;
    if (@_){
        my @a = $obj->video();
	$a[0] = shift;
	$obj->video(@a);
    }
    my @a = $obj->video();
    warn("v1 returning ($a[0]) from ".join('/',@a)."\n");
    return $a[0];
}

=head2 v2($url)
  
    Accessor routine to get or set the second element of the video array.

=cut

sub v2 {
    my $obj = shift;
    if (@_){
        my @a = $obj->video();
	$a[1] = shift;
	warn("CPL v2 set a1 to $a[1]\n");
	$obj->video(@a);
    }
    my @a = $obj->video();
    return $a[1];
}

=head2 v3($url)
  
    Accessor routine to get or set the third element of the video array.

=cut

sub v3 {
    my $obj = shift;
    if (@_){
        my @a = $obj->video();
	$a[2] = shift;
	$obj->video(@a);
    }
    my @a = $obj->video();
    return $a[2];
}

=head2 tl($cuepointname)
 
    Create a targetList with one element.

=cut

sub tl {
    my $obj = shift;
    my $s = shift;
    my $t = new Video::CPL::Target(cuePointRef=>$s);
    my $tl = new Video::CPL::TargetList(target=>[$t]);
    #print "tl returning:\n",Dumper($tl);
    return $tl;
}

=head2 parsectv()

=cut

my @FIELDS = qw(backgroundHTML frameHeight frameWidth loggingService skinButtons
    videoHeight videoSource videoViewLayout videoWidth videoX videoY
    webViewLayout xProgLevelData xProgLevelDir xUniqueID xVersionCPL
    xWebServiceLoc xmlns:xsi xsi:noNamespaceSchemaLocation youtubeID);
my @MPFIELDS = qw(xmlns:xsi xsi:noNamespaceSchemaLocation);
my @PLMFIELDS = qw(backgroundHTML frameHeight frameWidth loggingService skinButtons
    videoHeight videoSource videoViewLayout videoWidth videoX videoY
    webViewLayout xProgLevelData xProgLevelDir xUniqueID xVersionCPL
    xWebServiceLoc youtubeID);

sub parsectv {
    my $obj = shift;
    my $initfromctv = shift;
    my $ref = XMLin($initfromctv,ForceArray=>1,KeyAttr=>{},KeepRoot=>1);
    my %d = %{$ref};
    $obj->{'xsi:noNamespaceSchemaLocation'} = $d{"xsi:noNamespaceSchemaLocation"};
    $obj->{'xmlns:xsi'} = $d{"xmlns:xsi"};
    foreach my $q (@MPFIELDS){
	$obj->{$q} = $d{MediaProgram}[0]{$q} if defined($d{MediaProgram}[0]{$q});
    }
    foreach my $q (@PLMFIELDS){
	$obj->{$q} = $d{MediaProgram}[0]{progLevelMetadata}[0]{$q} if defined($d{MediaProgram}[0]{progLevelMetadata}[0]{$q});
    }
    foreach my $q ("video"){
	$obj->{$q} = $d{MediaProgram}[0]{progLevelMetadata}[0]{$q} if defined($d{MediaProgram}[0]{progLevelMetadata}[0]{$q});
    }
    #$obj->{video} = $d{MediaProgram}[0]{progLevelMetadata[0]{video}
    #process annotations
    if (defined $d{MediaProgram}[0]{annotations}){
	my @a;
	foreach my $x (@{$d{MediaProgram}[0]{annotations}[0]{annotation}}){
	    push @a,Video::CPL::Annotation::fromxml($obj,$x);
	}
	$obj->{annotations} = \@a;
    }

    #process layouts
    if (defined $d{MediaProgram}[0]{layouts}){
	my @l;
	foreach my $x (@{$d{MediaProgram}[0]{layouts}[0]{layout}}){
	    push @l,Video::CPL::Layout::fromxml($x);
	}
	$obj->{layouts} = \@l;
    }

    #process cuePoints
    if (defined $d{MediaProgram}[0]{cuePoints}){
	foreach my $x (@{$d{MediaProgram}[0]{cuePoints}[0]{cuePt}}){
	    $obj->addcue(Video::CPL::Cue::fromxml($obj,$x));
	}
    }

    #process webPoints
    if (defined $d{MediaProgram}[0]{webPoints}){
	foreach my $x (@{$d{MediaProgram}[0]{webPoints}[0]{cuePt}}){
	    $obj->addwp(Video::CPL::Cue::fromxml($obj,$x));
	}
    }
    #done
}

=head2 newname("base")

    Returns a name of the form "basedddddddd" which is not used by any other cue point or annotation in this CPL object.

=cut

sub newname {
    my $obj = shift;
    my $base = shift || "name";
    my $name;
    do {
	$name = $base.int(rand(100000000));
    } until ! defined($obj->cuebyname($name)) && !defined($obj->annobyname($name));
    return $name;
}


=head2 addcue($cue);

     Adds the created cue to the CPL object. This is not needed if reading the cue points from the video file itself, e.g. with a local .flv file.

=cut

sub addcue {
    my $obj = shift;
    my $cue = shift;
    $cue->parent($obj);
    confess("addcue needs a time in cuePt\n") if !defined($cue->time());
    push @{$obj->{cuePoints}},$cue;
    my @a = @{$obj->{cuePoints}};
    if ($#a > 0){
        my $last = $a[$#a];
	my $nexttolast = $a[$#a-1];
	if ($last->time() <= $nexttolast->time()) {
	    @{$obj->{cuePoints}} = sort {$a->time() <=> $b->time()} @a;
	}
    }
    return $cue;
}

sub getcptimes {
    my $obj = shift;
    my @ret;
    return @ret if !exists($obj->{cuePoints});
    my @a = @{$obj->{cuePoints}};
    foreach my $a (@a){
        push @ret, $a->time();
    }
    return @ret;
}

sub cuetostring {
    my $obj = shift;
    my $cue = shift;
    if ($cue->parent() == $obj){
        return "#".$cue->name();
    }
    #if same object then #foo
    #if same directory (think: dynamic, html and ref but no file) then foo.ctv#foo
    #think. user specified full html and ref or no ref.  Only need http if not specified.
    #else full url
    confess;
}

sub annotostring {
    my $obj = shift;
    my $anno = shift;
    #see comments for cuetostring re local versus same versus remote
    confess;
}

sub converttarget {
    my $obj = shift;
    my %p = @_;
    return %p if !exists $p{target};
    confess("converttarget given a null target\n") if !defined $p{target};
    my $t = $p{target};
    my @a;
    if (ref($t) eq "ARRAY"){
        @a = @{$t}
    } else {
        push @a,$t;
    }
    delete $p{target};
    $p{targetList} = new Video::CPL::TargetList();
    if (defined $p{backgroundPicLoc}){
	$p{targetList}->backgroundPicLoc($p{backgroundPicLoc});
	delete $p{backgroundPicLoc};
    }
    if (defined $p{headerText}){
	$p{targetList}->headerText($p{headerText});
	delete $p{headerText};
    }
    if (defined $p{operation}){
        $p{targetList}->operation($p{operation});
	delete $p{operation};
    }
    my @t;
    foreach my $q (@a){
        my $s;
        if (ref($q) eq "Video::CPL::Cue"){
	    $s = $q->reffromobj($obj);
	} elsif (ref($q) eq "Video::CPL::Annotation"){
	    $s = $q->reffromobj($obj);
	} else {
	     #confess if not scalar.
	    $s = $q;
	}
	my %targp = (cuePointRef=>$s);
	if (defined $p{modal}){
	    $targp{modal} = $p{modal};
	}
	if (defined $p{association}){ #hmm, works best for a single target
	    $targp{association} = $p{association};
	}
	#push @t,new Video::CPL::Target(cuePointRef=>$s);
	push @t,new Video::CPL::Target(%targp);
    }
    delete $p{modal} if defined $p{modal};
    delete $p{association} if defined $p{association};
    $p{targetList}->target(\@t);
    return %p;
}

sub convertstory {
    my $obj = shift;
our @FIELDS = qw(balloonText forever picLoc picOverLoc);
    my %p = @_;
    return %p if !defined($p{forever}) && !defined($p{balloonText}) &&
                 !defined($p{picLoc}) && !defined($p{picOverLoc});
    $p{story} = new Video::CPL::Story();
    if (defined($p{forever})){
        $p{story}->forever($p{forever});
	delete $p{forever};
    }
    if (defined($p{balloonText})){
        $p{story}->balloonText($p{balloonText});
	delete $p{balloonText};
    }
    if (defined($p{picLoc})){
        $p{story}->picLoc($p{picLoc});
	delete $p{picLoc};
    }
    if (defined($p{picOverLoc})){
        $p{story}->picOverLoc($p{picOverLoc});
	delete $p{picLoc};
    }
    return %p;
}

=head2 newcue(%cueparms)

    Create a new Cue point with the given parameters, and set the parent to this CPL object.

=cut

sub newcue {
    my $obj = shift;
    my %parms = @_;
    confess("newcue needs a time in cuePt\n") if !defined($parms{'time'});
    $parms{name} = $obj->newname("cue") if !defined($parms{name});
    #convert target to a targetlist with one entry. If there are other Targetlist
    %parms = $obj->converttarget(%parms) if defined $parms{target};
    %parms = $obj->convertstory(%parms) if defined($parms{picLoc}) || defined($parms{picOverLoc}) || defined($parms{balloonText});
    my $ret = new Video::CPL::Cue(%parms);
    return $obj->addcue($ret);
}

=head2 story(text=>"some text",pic=>"foo.jpg")

     Shorthand to create a Video::CPL::Story object.

=cut

sub story {
    my $obj = shift;
    my %parms = @_;
    my $ret = Video::CPL::Story->new(%parms);
#    my $text = $parms{balloonText};
#    my $pic = $parms{picLoc};
#    my $ret;
#    if ($pic){
#        if ($text){
#	} else {
#	    $ret = Video::CPL::Story->new(picLoc=>$pic);
#	}
#    } else {
#	$ret = Video::CPL::Story->new(balloonText=>$text);
#    }
    return $ret;
}

=head2 layout(%parms)

    Create a new layout and install it in this CPL. Pass the parameters on to Video::CPL::Layout::new.

=cut

sub layout {
    my $obj = shift;
    my %parms = @_;
    my $ret = new Video::CPL::Layout(%parms);
    push @{$obj->{layouts}},$ret;
    return $ret;
}

=head2 layouts() return all layouts for the current Video::CPL as an array

=cut

sub layouts {
    my $obj = shift;
    return () if !exists($obj->{layouts});
    return @{$obj->{layouts}};
}

=head2 layoutbyname($name)

    Return the layout with the given name.

=cut

sub layoutbyname {
    my $obj = shift;
    my $name = shift;
    return undef if !defined($obj->{layouts});
    my @l = @{$obj->{layouts}};
    foreach my $l (@l){
        return $l if $l->name() eq $name;
    }
    return undef;
}

=head2 allstories()

    Return an array with all of the Annotation based Story objects in this CPL.

=cut

sub allstories {
    my $obj = shift;
    my @ret = ();
    my @a = $obj->annotations();
    foreach my $a (@a){
        push @ret,$a->story() if $a->story();
    }
    return @ret;
}

=head2 numcue($k)

     Returns the k-th cuePoint Cue object. Note that a normally created CPL object will always create a cue point a the beginning, easily obtained with firstcue(), below.

=cut

sub numcue {
    my $obj = shift;
    my $num = shift;
    if (defined($obj->{cuePoints}[$num])){
        return $obj->{cuePoints}[$num];
    }
    return undef;
}

=head2 cuePoints()

    Returns all Cue objects.

=cut

sub cuePoints {
    my $obj = shift;
    return @{$obj->{cuePoints}};
}

=head2 numwebcue(4)

     Returns the 4th webPoint object. 

=cut

sub numwebcue {
    my $obj = shift;
    my $num = shift;
    if (defined($obj->{webPoints}[$num])){
        return $obj->{webPoints}[$num];
    }
    die "Error: There is no web cue numbered $num for ($obj->{videoSource}). Does it not have any web cue points?\n";
    return undef;
}

=head2 maxweb()

=cut

sub maxweb {
    my $obj = shift;
    my @a = @{$obj->{webPoints}};
    return $#a;
}

=head2 max()

=cut

sub max {
    my $obj = shift;
    my @a = @{$obj->{cuePoints}};
    return $#a;
}

=head2 firstcue()

     Returns the first cuePoint Cue object.

=cut

sub firstcue {
    my $obj = shift;
    if (defined($obj->{cuePoints}[0])){
        return $obj->{cuePoints}[0];
    }
    die "Error: There is no first cue for ($obj->{videoSource}). Does it not have any cue points?\n";
    return undef;
}

=head2 lastcue()

=cut

sub lastcue {
    my $obj = shift;
    my @a = @{$obj->{cuePoints}};
    return $a[$#a] if $#a > -1;
    die "Error: There is no last cue (last is $#a) for ($obj->{videoSource}). Does it not have any cue points?\n";
    return undef;
}

=head2 add()
    Adds a cue point to the end of the cue point list. The parent of the cue point should either
    not be set, or be correctly set. Cue points may only have one parent, and can therefore not be used
    in multiple CPL objects.

=cut

sub add {
    my $obj = shift;
    my $cue = shift;
    confess("adding a cue that belongs to someone else\n") if $cue->{parent} && ($cue->{parent} ne $obj);
    $cue->{parent} = $obj;
    push @{$obj->{cuePoints}},$cue;
}

=head2 webPoints() return all webPoints for the current Video::CPL as an array

=cut

sub webPoints {
    my $obj = shift;
    return () if !exists($obj->{webPoints});
    return @{$obj->{webPoints}};
}

=head2 addwp()

=cut

sub addwp {
    my $obj = shift;
    my $cue = shift;
    $cue->{parent} = $obj;
    push @{$obj->{webPoints}},$cue;
}

=head2 addanno()

=cut

sub addanno {
    my $obj = shift;
    my $anno = shift;
    push @{$obj->{annotations}},$anno;
    return $anno;
}

=head2 annotations()

=cut

sub annotations {
    my $obj = shift;
    return @{$obj->{annotations}} if defined($obj->{annotations});
    return ();
}

=head2 webPoint(name=>"aname",interestURL=>"http://somewhere.com/foo.jpg",story=>{picLoc=>"foo.jpg"},tl=>[$target]});

    Create and add a new webPoint object.

    Target can be created with something like Video::CPL::Cue->new("Lost A");

    Story is currently just an anonymous hash. It may become an object in a future release.

=cut

sub webPoint {
    my $obj = shift;
    my %parms = @_;
    $parms{name} = $obj->newname("webcue") if !defined($parms{name});
    %parms = $obj->convertstory(%parms) if defined($parms{picLoc}) || defined($parms{picOverLoc}) || defined($parms{balloonText});
    my $cue = Video::CPL::Cue->new(cueType=>'webPoint',%parms);
    $obj->addwp($cue);
    return $cue;
}

=head2 goto(name=>"aname",tl=>[$target]});

    Create and add a new goto object.

    Target can be created with something like Video::CPL::Cue->new("Lost A");

=cut

sub goto {
    my $obj = shift;
    my %parms = @_;
    #support old code for a while
    if (defined($parms{dest}) && !defined($parms{target})){
        $parms{target} = $parms{dest};
	undef($parms{dest});
    }
    if (defined($parms{tl}) && !defined($parms{target})){
        $parms{target} = shift @{$parms{tl}};
	undef($parms{tl});
    }
    $parms{zeroLen} = "true" if !defined $parms{zeroLen};
    return $obj->newcue(cueType=>'goto',%parms);
}

=head2 regular(name=>"cuename",time=>1.0,interestURL=>"http://somewhere.com/foo.html");

    Create and add a new regular object.

=cut

sub regular {
    my $obj = shift;
    my %parms = @_;
    return $obj->newcue(cueType=>'regular',%parms);
}

=head2 insertPt(name=>"cuename",time=>1.0);

    Create and add a new regular object.

=cut

sub insertPt {
    my $obj = shift;
    my %parms = @_;
    return $obj->newcue(cueType=>'insertPt',%parms);
}

=head2 cuebyname($name)

    Return the first cue with the given name.

=cut

sub cuebyname {
    my $obj = shift;
    my $name = shift;
    return $obj->cuePointbyname($name) || $obj->webPointbyname($name);
}

=head2 cuePointbyname($name)

    Return the first cuePoint with the given name.

=cut

sub cuePointbyname {
    my $obj = shift;
    my $name = shift;
    confess "cuePointbyname no name\n" if !$name;
    if (defined($obj->{cuePoints})){
        my @cuePoints = @{$obj->{cuePoints}};
	foreach my $q (@cuePoints){
	    return $q if $q->name() eq $name;
	}
    }
    return undef;
}

=head2 webPointbyname($name)

    Return the first webPoint with the given name.

=cut

sub webPointbyname {
    my $obj = shift;
    my $name = shift;
    if (defined($obj->{webPoints})){
	my @webPoints = @{$obj->{webPoints}};
	foreach my $q (@webPoints){
	    return $q if $q->name() eq $name;
	}
    }
    return undef;
}

=head2 cuebytime($time)

    Return the cuePt with the given time, or undef.

=cut

sub cuebytime {
    my $obj = shift;
    my $time = shift;
    return undef if !defined($obj->{cuePoints});
    my @cuePoints = @{$obj->{cuePoints}};
    foreach my $q (@cuePoints){
	return $q if $q->time() eq $time;
    }
    return undef;
}


=head2 annobyname("name")

    Return the first annotation with the given name.

=cut

sub annobyname {
    my $obj = shift;
    my $name = shift;
    return undef if !defined $obj->{annotations};
    my @annos = @{$obj->{annotations}};
    #print STDERR "in annobyanme annos is ",Dumper(\@annos),"\n";
    foreach my $q (@annos){
        return $q if $q->name() eq $name;
    }
    return undef;
}

=head2 programEnd()

=cut

sub programEnd {
    my $obj = shift;
    my %parms = @_;
    $parms{zeroLen} = "true" if !defined $parms{zeroLen};
    return $obj->newcue(cueType=>'programEnd',%parms);
}

=head2 returnEnd()

=cut

sub returnEnd {
    my $obj = shift;
    my %parms = @_;
    $parms{zeroLen} = "true" if !defined $parms{zeroLen};
    return $obj->newcue(cueType=>'returnEnd',%parms);
}

=head2 annotation()
    
    Create an annotation and add it to the object.

=cut

sub annotation {
    my $obj = shift;
    my %parms = @_;
    $parms{parent} = $obj if !defined($parms{parent});
    my $anno = Video::CPL::Annotation->new(%parms);
    $obj->addanno($anno);
    return $anno;
}

=head2 adecoration([annotation parameters])

=cut

sub adecoration {
    my $obj = shift;
    my %parms = @_;
    $parms{clickBehavior} = "decoration";
    $parms{parent} = $obj if !defined($parms{parent});
    my $anno = Video::CPL::Annotation->new(%parms);
    $obj->addanno($anno);
    return $anno;
}

=head2 agoto([annotation parameters]) 

    adecoration,agoto,ajavascript, and areturnend are shorthand notations to create an annotation and add it
    to the current Video::CPL object, setting the parent correctly. Generally they are recommended if the annotation
    will be used more than once.

    $anno = $cpl->agoto(balloonText=>"go somewhere",x=>10,y=>10,target=>$somecue);
    $cpl->numcue(1)->addanno($anno);

    For a single-use annotation, Annotation::goto may be more convenient.

    $cpl->regular(time=>10)->goto(balloontext=>"go somewhere",x=>10,y=>10);

    This would create a Cue and add an annotation in one statement.

    The annotation parameters are used with normal Annotation constructor; therefore Story parameters such as
    picLoc will cause a Story to be automatically generated. 

=cut

sub agoto {
    my $obj = shift;
    my %parms = @_;
    $parms{clickBehavior} = "goto";
    $parms{tl} = [$parms{dest}] if defined($parms{dest});
    delete($parms{dest});
    $parms{parent} = $obj if !defined($parms{parent});
    my $anno = Video::CPL::Annotation->new(%parms);
    $obj->addanno($anno);
    return $anno;
}

=head2 ajavascript([annotation paramters])

=cut

sub ajavascript {
    my $obj = shift;
    my %parms = @_;
    $parms{clickBehavior} = "javascript";
    $parms{parent} = $obj if !defined($parms{parent});
    my $anno = Video::CPL::Annotation->new(%parms);
    $obj->addanno($anno);
    return $anno;
}

=head2 areturnend()

     my $anno = $cpl->areturnend(balloonText=>"Return please",x=>10,y=>10);
     $cpl->numcue(0)->addanno($anno);

=cut

sub areturnend {
    my $obj = shift;
    my %parms = @_;
    $parms{clickBehavior} = "returnEnd";
    $parms{parent} = $obj if !defined($parms{parent});
    my $anno = Video::CPL::Annotation->new(%parms);
    $obj->addanno($anno);
    return $anno;
}

=head2 userChoice()

=cut

sub userChoice {
    my $obj = shift;
    my %parms = @_;
    return $obj->newcue(cueType=>'userChoice',%parms);
}

=head2 xmlo($xo)

    Add the XML to output this object to the existing XML::Writer object xo. Creation and printing is done outside this routine.

=cut

sub xmlo {
    my $obj = shift;
    my $xo = shift;

    my %p;
    foreach my $q (@MPFIELDS){
        $p{$q} = $obj->{$q} if defined $obj->{$q};
    }

    $xo->startTag("MediaProgram",%p);
    %p = ();
    #the qw defines the order of the attributes, if some order is preferred.
    foreach my $q (@PLMFIELDS){
        $p{$q} = $obj->{$q} if defined($obj->{$q});
    }
    if (exists($obj->{video})){
        $xo->startTag("progLevelMetadata",%p);
	$xo->startTag("video");
	my @a = @{$obj->{video}[0]{source}};
	foreach my $ia (0..$#a){
	    my %h = %{$a[$ia]};
	    $xo->emptyTag("source",%h);
	}
	$xo->endTag("video");
	$xo->endTag("progLevelMetadata");
    } else {
	$xo->emptyTag("progLevelMetadata",%p);
    }

    foreach my $a (qw(cuePoints webPoints annotations layouts)){
        if ($obj->{$a}){
	    $xo->startTag($a);
	    foreach my $c (@{$obj->{$a}}){
		$c->xmlo($xo);
	    }
	    $xo->endTag($a);
	}
    }
    $xo->endTag("MediaProgram");
}

=head2 xml()

    Return the xml format of the current CPL object. This is normally called from print, but can
    be called directly.

=cut

sub xml {
    my $obj = shift;
    my $a = "";
    my $xo = new XML::Writer(OUTPUT=>\$a,NEWLINES=>1);
    $obj->xmlo($xo);
    $xo->end();
    return $a;
}

=head2 print()

    Print out the current xml in the automatically created temporary file within the web-viewable file hiearchy. Use before calling embed.

=cut

sub print {
    my $obj = shift;
    $obj->fixfile() if !$obj->{filefixed};
    my $fh = $obj->{fh};
    print $fh $obj->xml();
    close $fh;
} 

=head2 embed([height=>yyy,width=>xxx])

    Return the html code used to embed a CPL screen within an html file. 

    The height and width parameters are optional, and may be specified as percent or pixels. If not specified, height will be set to 392 pixels and width to 680 pixels.

    CPL parameters that can be specified:
       height: Height in pixels or percent. Defaults to frameHeight else videoHeight else 680 pixels.
       width: Width in pixels or percent. Defaults to frameWidth else videoWidth else 415 pixels.
       player:  a URL that reaches the desired Flash player. If not specified, will default to a player
           at Coincident TV. This will not be able to access images etc. from a different server unless
	   there is a file "crossdomain.xml" at the top level of that server. This file should look like

	   <?xml version="1.0"?>
	   <!DOCTYPE cross-domain-policy SYSTEM "http://www.macromedia.com/xml/dtds/cross-domain-policy.dtd">
	   <cross-domain-policy>
	   <allow-access-from domain="*" />
	   <site-control permitted-cross-domain-policies="all"/>
	   </cross-domain-policy>

       media: the URL of the media CTV. If a partial URL, it will be relative to the player.
       mergedstyle: if true, include the media as a CGI parameter to the player. This is the norm when using the full CPL experience.

    Additional Adobe parameters:
        align:  defaults to "middle".
	play:   defaults to "true".
	quality: defaults to "autohigh".
	allowfullscreen: defaults to "true".
	allowScriptAccess: defaults to "always". In this mode, a webPoint reached from "embed"-ed player
	    will overwrite the window.
	type:   defaults to "application/x-shockwave-flash".
	pluginspage: defaults to "http://www.adobecom/go/getflashplayer".
	bgcolor: Hex value,defaults to "#869ca7".

=cut

sub embed {
    my $obj = shift;
    my %parms = @_;
    my $ret;
    my $media = $parms{media} || $obj->{ctvfilename};
    my $player = $parms{flexplayer} || "http://metabase.coincident.tv/cpan/player/CTVWebPlayerS.swf";
    my $mergedstyle = $parms{mergedstyle};

    my %pr;
    #my %pr = $obj->print(%parms);
    $media = $pr{url} if !$parms{media};

    #good values are 680x415 435x276 314x208 or 1000x595
    #use parameter else frameWidth else videoWidth else 680 (415)
    my $width = 680;
    $width = $obj->{videoWidth} if exists($obj->{videoWidth});
    $width = $obj->{frameWidth} if exists($obj->{frameWidth});
    $width = $parms{width} if exists($parms{width});    
    my $height = 415;
    $height = $obj->{videoHeight} if exists($obj->{videoHeight});
    $height = $obj->{frameHeight} if exists($obj->{frameHeight});
    $height = $parms{height} if exists($parms{height});    

    $media = $obj->{ctvfilename} if !$media && exists($obj->{ctvfilename});
    confess("No media in embed\n") if !$media;
    #print '<embed src="/flash_flex_player.swf" quality="high" bgcolor="#869ca7"'."\n";
    my %ret;
    $ret{src} = $mergedstyle?"$player?media=$media":$player;
    $ret{flashvars} = "media=".$media if !$mergedstyle;
    $ret{width} = $width;
    $ret{height} = $height;
    $ret{align} = exists($parms{align})?$parms{align}:"middle";
    $ret{play} = exists($parms{play})?$parms{play}:"true";
    $ret{quality} = exists($parms{quality})?$parms{quality}:"autohigh";
    $ret{allowfullscreen} = exists($parms{allowfullscreen})?$parms{allowfullscreen}:"true";
    $ret{allowScriptAccess} = exists($parms{allowScriptAccess})?$parms{allowScriptAccess}:"always";
    $ret{type} = exists($parms{type})?$parms{type}:"application/x-shockwave-flash";
    $ret{pluginspage} = exists($parms{pluginspage})?$parms{pluginspage}:"http://www.adobe.com/go/getflashplayer";
    $ret{bgcolor} = exists($parms{bgcolor})?$parms{bgcolor}:"#869ca7";
    my @ret;
    foreach my $k (keys %ret){
        push @ret, "$k=\"$ret{$k}\"";
    }
    return "<embed ".join("\n",@ret).">\n";
}

=head2 Video::CPL::checkready(local=>$file)

     This is a function, and not a method. Typically it is called before creating a CPL object

=cut

sub checkready {
    my %p = @_;
    my $SRC = "http://metabase.coincident.tv/cpan/player/";
    #if local, just get the player
    #if dir, get everything into said directory
    if ($p{local}){
	return 1 if -r $p{local} && (-s $p{local} > 200000);
	return 1 if getfile("$SRC/CTVWebPlayerS.swf",$p{local},200000);
	return 0;
    } elsif ($p{dir}){
        my %files = ("CTVWebPlayerS.swf"=>400000,
	             "defaultSkin.html"=>100,
		     "index.html"=>2000,
		     "styles.css"=>500,
		     "preLoader/CTVPreLoader.swf"=>2000,
		     "scripts/CTVLayoutFunc.js"=>5000,
		     "scripts/expressInstall.swf"=>100,
		     "scripts/jquery-1.3.2.min.js"=>10000,
		     "scripts/swfobject.js"=>3000,
		     "ui/CTVCloseButton-over.png"=>100,
		     "ui/CTVCloseButton.png"=>100);
	make_path($p{dir}) if !-d $p{dir};
	foreach my $x (keys %files){
	    if ($x =~ /(.*)\//){
	        my $prefix = $1;
		make_path("$p{dir}/$prefix") if !-d "$p{dir}/$prefix";
	    }
	    getfile("$SRC$x","$p{dir}/$x",$files{$x});
	}
    }
}

sub getfile {
    my $url = shift;
    my $file = shift;
    my $minsize = shift;
    my $fil = get($url);
    if (length($fil) < $minsize){
	warn("Video::CPL checkready/getfile: tried to fetch ($file) from ($url) but it was shorter than expected ($minsize), failing.\n");
	return 0;
    }
    if (open(FSWF,">$file")){
	print FSWF $fil;
	close FSWF;
	my $actual = -s $file;
	if ($actual != length($fil)){
	    warn("Video::CPL checkready/getfile: fetched ($file) from ($url) of length ".length($fil)." but only wrote $actual bytes, failing.\n");
	    return 0;
	}
	return 1;
    } else {
	warn("Video::CPL checkready/getfile: fetched from ($url), could not write to ($file), failing.\n");
	return 0;
    }
}

=head2 isyoutube($url)

    Return true if this URL appears to be a Youtube video.

=cut

sub isyoutube {
    #utility routine, not an object method
    my $x = shift;
    return undef if $x !~ /http:\/\/www.youtube.com\/watch\?v=([A-Za-z0-9\-\_]{11})/;
    my $code = $1;
    return youtubefromcode($code);
}

=head1 AUTHOR

Carl Rosenberg, C<< <perl at coincident.tv> >>

=head1 BUGS

Please report any bugs to Coincident TV.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CPL

=head1 ACKNOWLEDGEMENTS

This is actually just a straightforward interface to the work done by the rest of the Coincident team.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Coincident TV

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1; # End of CPL
