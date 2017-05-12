package Video::CPL::Cue;

use warnings;
use strict;
use Carp;
use Data::Dumper;
use XML::Writer;

use Video::CPL::Annotation;
use Video::CPL::AnnotationList;
use Video::CPL::TargetList;

=head1 NAME

Video::CPL::Cue - Create a Cue object.

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

    use Video::CPL::Cue;

    my $foo = Video::CPL::Cue->new(cueType=>"regular",name=>"fooba",time=23.7,interestURL="http://foo.com");

=head1 SUBROUTINES/METHODS

=cut
our @FIELDS = qw(name cueType time tags interestURL query zeroLen cannotSkip pauseOnEntry modalOnEntry soft js backgroundHTML coincidentWebPoint pauseOnDisplay canBeDestination mxmlInCPL videoBottom useLayout webViewLayout videoHCenter webBottom);

#WARNING be careful accessing time. $x->{time} will give the wrong results. time() can't be called
#directly in the module. foo(time=>1) and $x->time() work given Perl rules.
#
=head2 name([$name])

    Accessor function to get or set name.

=cut

sub name { my $obj = shift; $obj->{'name'} = shift if @_; return $obj->{'name'}; }

=head2 cueType([$type])

    Accessor function to get or set cueType.

=cut

sub cueType { my $obj = shift; $obj->{'cueType'} = shift if @_; return $obj->{'cueType'}; }

=head2 time([$time])

    Accessor function to get or set time.

=cut

sub time { my $obj = shift; $obj->{'time'} = shift if @_; return $obj->{'time'}; }

=head2 tags([$tags])

    Accessor function to get or set tags.

=cut

sub tags { my $obj = shift; $obj->{tags} = shift if @_; return $obj->{tags}; }

=head2 interestURL([$url])

    Accessor function to get or set interestURL.

=cut

sub interestURL { my $obj = shift; $obj->{interestURL} = shift if @_; return $obj->{interestURL}; }

=head2 query([$query])

    Accessor function to get or set query.

=cut

sub query { my $obj = shift; $obj->{query} = shift if @_; return $obj->{query}; }

=head2 zeroLen([$tf])

    Accessor function to get or set zeroLen.

=cut

sub zeroLen { my $obj = shift; $obj->{zeroLen} = shift if @_; return $obj->{zeroLen}; }

=head2 cannotSkip([$tf])

    Accessor function to get or set cannotSkip.

=cut

sub cannotSkip { my $obj = shift; $obj->{cannotSkip} = shift if @_; return $obj->{cannotSkip}; }

=head2 pauseOnEntry([$tf])

    Accessor function to get or set pauseOnEntry.

=cut

sub pauseOnEntry { my $obj = shift; $obj->{pauseOnEntry} = shift if @_; return $obj->{pauseOnEntry}; }

=head2 modalOnEntry([$tf])

    Accessor function to get or set modalOnEntry.

=cut

sub modalOnEntry { my $obj = shift; $obj->{modalOnEntry} = shift if @_; return $obj->{modalOnEntry}; }

=head2 soft([$tf])

    Accessor function to get or set soft.

=cut

sub soft { my $obj = shift; $obj->{soft} = shift if @_; return $obj->{soft}; }

=head2 js([$javascript])

    Accessor function to get or set js, the Javascript to be used when this cuePoint is reached.

=cut

sub js { my $obj = shift; $obj->{js} = shift if @_; return $obj->{js}; }

=head2 backgroundHTML([$url])

    Accessor function to get or set backgroundHTML.

=cut

sub backgroundHTML { my $obj = shift; $obj->{backgroundHTML} = shift if @_; return $obj->{backgroundHTML}; }

=head2 coincidentWebPoint([$value])

    Accessor function to get or set coincidentWebPoint

=cut

sub coincidentWebPoint { my $obj = shift; $obj->{coincidentWebPoint} = shift if @_; return $obj->{coincidentWebPoint}; }

=head2 pauseOnDisplay([$tf])

    Accessor function to get or set pauseOnDisplay.

=cut

sub pauseOnDisplay { my $obj = shift; $obj->{pauseOnDisplay} = shift if @_; return $obj->{pauseOnDisplay}; }

=head2 mxmlInCPL([$mxmlcode])

    Accessor function to get or set mxmlInCPL.

=cut

sub mxmlInCPL { my $obj = shift; $obj->{mxmlInCPL} = shift if @_; return $obj->{mxmlInCPL}; }

=head2 videoBottom([$value])

    Accessor function to get or set videoBottom.

=cut

sub videoBottom { my $obj = shift; $obj->{videoBottom} = shift if @_; return $obj->{videoBottom}; }

=head2 useLayout([$layoutname])

    Accessor function to get or set useLayout.

=cut

sub useLayout { my $obj = shift; $obj->{useLayout} = shift if @_; return $obj->{useLayout}; }

=head2 webViewLayout([$webViewLayout])

    Accessor function to get or set webViewLayout.

=cut

sub webViewLayout { my $obj = shift; $obj->{webViewLayout} = shift if @_; return $obj->{webViewLayout}; }

=head2 videoHCenter([$value])

    Accessor function to get or set videoHCenter.

=cut

sub videoHCenter { my $obj = shift; $obj->{videoHCenter} = shift if @_; return $obj->{videoHCenter}; }

=head2 webBottom([$value])

    Accessor function to get or set webBottom.

=cut

sub webBottom { my $obj = shift; $obj->{webBottom} = shift if @_; return $obj->{webBottom}; }

=head2 annotationList([$annotationlist])

    Accessor function to get or set annotationList.

=cut

sub annotationList { my $obj = shift; $obj->{annotationList} = shift if @_; return $obj->{annotationList}; }

=head2 directoryList([$directorylist])

    Accessor function to get or set directoryList.

=cut

sub directoryList { my $obj = shift; $obj->{directoryList} = shift if @_; return $obj->{directoryList}; }

=head2 targetList([$targetList])

    Accessor function to get or set targetList.

=cut

sub targetList { my $obj = shift; $obj->{targetList} = shift if @_; return $obj->{targetList}; }

=head2 story([$story])

    Accessor function to get or set story.

=cut

sub story { my $obj = shift; $obj->{story} = shift if @_; return $obj->{story}; }
#not an attribute

=head2 parent([$videoCPLobject])

    Accessor function to get or set parent. Video::CPL::Cue tracks the parent Video::CPL object, so as to be
    able to generate an appropriate reference for external CPL files.

=cut

sub parent { my $obj = shift; $obj->{parent} = shift if @_; return $obj->{parent}; }

    #cue new is normally called from CPL.pm. Newest model is that it sets story and TargetList correctly
    #proposed
    #story
    #picLoc picOverLoc ballonText forever
    #if present will create and add story
   #target [accept array or scalar. Strings or cuePt. return array if wantarray else single target if only one else croak.]
   #backgroundPicLoc
   #operation 
   #headerText

=head2 new([name=>$name,cueType=>$type,time=>$val,tags=>$string,interestURL=>$url,query=>string,
            zeroLen=>$tf,cannotSkip=>$tf,pauseOnEntry=>$tf,modalOnEntry=>$tf,soft=>$tf,js=>$javascript,
	    backgroundHTML=>$url,coincidentWebPoint=>$val,pauseOnDisplay=>$tf,canBeDestination=>$tf,
	    mxmlInCPL=>$mxml,videoBottom=>$value,useLayout=>$layout,webViewLayout=>$layout,
	    videoHCenter=>$value,webBottom=>$value]);

    Return a new Cue object, with the parameters set as specified. An advantage of using the
    CPL::Video helper functions instead is that parent will be automatically set. Rather than:

    $cue = new Video::CPL::Cue(name=>"foo",time=>3,cueType=>regular);
    $cpl->addcue($cue);

    use:

    $cpl->regular(time=>3,name=>"foo");

    Names will be automatically created if not specified, so an even shorter version would be:

    $cpl->regular(time=>3);

=cut

sub new {
    my $pkg = shift;
    my %parms = @_;
    my $ret = {};
    bless $ret,$pkg;

    foreach my $q (@FIELDS,'story','annotationList','targetList'){
	$ret->{$q} = $parms{$q} if defined($parms{$q});
    }
    $ret->{parent} = $parms{parent} || undef;
    $ret->{zerolen} = $parms{zerolen} || ($parms{cueType} =~ /(goto|regularEnd|returnEnd)/)?"true":"false";

    return $ret;
}

=head2 adjust([name=>$name,cueType=>$type,time=>$val,tags=>$string,interestURL=>$url,query=>string,
            zeroLen=>$tf,cannotSkip=>$tf,pauseOnEntry=>$tf,modalOnEntry=>$tf,soft=>$tf,js=>$javascript,
	    backgroundHTML=>$url,coincidentWebPoint=>$val,pauseOnDisplay=>$tf,canBeDestination=>$tf,
	    mxmlInCPL=>$mxml,videoBottom=>$value,useLayout=>$layout,webViewLayout=>$layout,
	    videoHCenter=>$value,webBottom=>$value]);

    Change arbitrary fields within a Cue point.

=cut

sub adjust {
    my $obj = shift;
    my %parms = @_;
    %parms = $obj->parent()->converttarget(%parms) if defined $parms{target};
    %parms = $obj->parent()->convertstory(%parms) if defined($parms{picLoc}) || defined($parms{picOverLoc}) || defined($parms{balloonText});
    foreach my $q (@FIELDS,'story','annotationList','targetList'){
	$obj->{$q} = $parms{$q} if defined($parms{$q});
    }
    $obj->{parent} = $parms{parent} if exists $parms{parent};
    $obj->{zerolen} = $parms{zerolen} || ($parms{cueType} =~ /(goto|regularEnd|returnEnd)/)?"true":"false";
    return $obj;
}

=head2 fromxml()

=cut

sub fromxml {
    my $parent = shift;
    my $s = shift;
    my %s = %{$s};
    my $cueType = $s{cueType};
    my %p;
    foreach my $q (@FIELDS){
        $p{$q} = $s{$q} if defined($s{$q});
    }
    $p{parent} = $parent;

    $p{story} = Video::CPL::Story::fromxml($s{story}[0]) if defined($s{story}[0]);
    $p{targetList} = Video::CPL::TargetList::fromxml($s{targetList}[0]) if defined($s{targetList}[0]);
    $p{annotationList} = Video::CPL::AnnotationList::fromxml($s{annotationList}[0]) if defined($s{annotationList}[0]);
    return new Video::CPL::Cue(%p);
}

=head2 setdl()

=cut

sub setdl {
    my $obj = shift;
    $obj->{dl} = shift;
}

=head2 addanno()

=cut

sub addanno {
    my $obj = shift;
    my @annos = @_;
    my @ret;
    foreach my $x (@annos){
	confess("Video::CPL::Cue::addanno needs a Video::CPL::Annotation\n") if ref($x) ne "Video::CPL::Annotation";
	my $t = new Video::CPL::Target(cuePointRef=>$x->name());
	push @ret,$t;
	if (defined $obj->{annotationList}){
	    $obj->annotationList()->pusht($t);
	} else {
	    $obj->annotationList(new Video::CPL::AnnotationList(target=>[$t]));
	}
	push @{$obj->{annotations}},$t;
    }
    return @ret;
}

=head2 annotations()

=cut

sub annotations {
    my $obj = shift;
    return @{$obj->{annotations}} if defined($obj->{annotations});
    return ();
}

=head2 setstory()

=cut

sub setstory {
    my $obj = shift;
    my %parms = @_;
    my $text = $parms{text} || "no text";
    my $pic = $parms{pic} || "picofself.jpg";
    my $ret = Video::CPL::Story->new(balloon=>$text,pic=>$pic);
    $obj->{image} = $pic;
    $obj->{story} = $ret;
}

=head2 dostandard()

    dostandard is an internal utility routine for adding a cuepoint 

=cut

sub dostandard  {
    my $obj = shift;
    my $cueType = shift;
    my %parms = @_;
    die "Tried to set cue point ($obj->{name}) at time ($obj->{time}) to $cueType but it has already been set.\n" if !$obj->{setoninit};
    $obj->{cueType} = $cueType;
    $obj->{canBeDestination} = $parms{canBeDestination} if defined($parms{canBeDestination});
    $obj->{tags} = $parms{tags} if defined($parms{tags});
    $obj->{interestURL} = $parms{URL} if defined($parms{URL});
    $obj->{query} = $parms{query} if defined($parms{query});
    $obj->{zerolen} = $parms{zerolen} if defined($parms{zerolen});
    $obj->{dl} = $parms{dl} if $parms{dl};
    $obj->{dlforever} = $parms{dlforever} if $parms{dlforever};
    $obj->{al} = $parms{al} if $parms{al};
    $obj->{tl} = $parms{tl} if $parms{tl};
    $obj->{story} = $parms{story} if $parms{story};
    $obj->{name} = $parms{name};
    return $obj;
}

=head2 regular()

=cut

sub regular {
    my $obj = shift;
    my %parms = @_;
    return $obj->dostandard("regular",%parms);
}

=head2 returnend()

=cut

sub returnend {
    my $obj = shift;
    my %parms = @_;
    $obj->dostandard("returnEnd",%parms);
    return;
}

=head2 programend()

=cut

sub programend {
    my $obj = shift;
    my %parms = @_;
    $obj->dostandard("programEnd",%parms);
    return;
}

=head2 choice()

=cut

sub choice {
    my $obj = shift;
    my %parms = @_;
    die "Tried to set cue point ($obj->{name}) at time ($obj->{time}) to choice but it has already been set.\n" if !$obj->{setoninit};
    $obj->{setoninit} = 0;
    $obj->{cueType} = "userChoice";
    $obj->{tl} = $parms{tl} if defined($parms{tl});
    #set up target list;
#$ctv->numcue(1)->choice(tltext=>"Where do you want to go?",tl=>[@newlabels]);
    return $obj;
}

=head2 goto()

=cut

sub goto {
    #OLD CODE
    #my $obj = shift;
    #my %parms = @_;
    #if just a Video::CPL::Cue, throw a warning about deprecated, and make this a goto.
    #otherwise we mean add a goto annotation to this cue point, which therefore
    #needs to have its parent set.
    #my $dest = shift;
    #my $destcue;
    #if (ref($dest) eq "Video::CPL::Cue"){
        #$destcue = $dest;
    #} else {
	#$destcue = $obj->{parent}->cue($dest);
    #}
    #$obj->{cueType} = "goto";
    #$obj->{tl} = [$parms{dest}];
    #$obj->{story} = $parms{story} if defined($parms{story});
    #return $obj;
    #
    #NEW CODE
    #  For the common case that we want to create a unique goto annotation right here
    #  That means creating an annotation, 
    #             adding it to the CPL, 
    #             and adding a cuePointRef to it to this Cue
    my $obj = shift;
    confess("Bad hash to Video::CPL::Cue::goto. Are you using an old version? Try creating a whole new Cue and adding it which will replace the old.\n") if $#_ == 0;
    my %p = @_;
    confess("Video::CPL::Cue::Annotation called without parent\n") if !defined $obj->parent();
    $p{clickBehavior} = "goto";
    $p{parent} = $obj->parent() if !exists $p{parent};
    %p = $obj->parent()->converttarget(%p) if exists $p{target};
    confess("Video::CPL::Cue::goto still has a target, this can not be happening.\n") if exists $p{target};
    my $a = new Video::CPL::Annotation(%p);
    $obj->parent()->addanno($a);
    $obj->addanno($a);
    return $a;
}

=head2 decoration(%parms)

    Add a new clickBehavior=decoration annotation to the parent of this Video::CPL::Cue, and add a cuePointRef to it from this object. Parameters are the same as for CPL::Annotation::new except that clickBehavior=decoration is implied. An 

=cut

sub decoration {
    my $obj = shift;
    my %p = @_;
    confess("Video::CPL::Cue::Annotation called without parent\n") if !defined $obj->parent();
    $p{clickBehavior} = "decoration";
    $p{parent} = $obj->parent() if !exists $p{parent};
    my $a = new Video::CPL::Annotation(%p);
    $obj->parent()->addanno($a);
    $obj->addanno($a);
    return $a;
}

=head2 javascript(%parms)

    Add a new clickBehavior=javascript annotation to this Video::CPL::Cue. Parameters are the same as for CPL::Annotation::new except that clickBehavior=javascript is implied.

=cut

sub javascript {
    my $obj = shift;
    my %p = @_;
    confess("Video::CPL::Cue::javascript called without parent\n") if !defined $obj->parent();
    $p{clickBehavior} = "javascript";
    $p{parent} = $obj->parent() if !exists $p{parent};
    my $a = new Video::CPL::Annotation(%p);
    $obj->parent()->addanno($a);
    $obj->addanno($a);
    return $a;
}

=head2 returnEnd(%parms)

    Add a new clickBehavior=returnEnd annotation to this Video::CPL::Cue. Parameters are the same as for Video::CPL::Annotation::new except that clickBehavior=returnEnd is implied. 

=cut

sub returnEnd {
    my $obj = shift;
    my %p = @_;
    confess("Video::CPL::Cue::Annotation called without parent\n") if !defined $obj->parent();
    $p{clickBehavior} = "returnEnd";
    $p{parent} = $obj->parent() if !exists $p{parent};
    my $a = new Video::CPL::Annotation(%p);
    $obj->parent()->addanno($a);
    $obj->addanno($a);
    return $a;
}

=head2 xml()

    Return the text form of a Cue object.

=cut

sub xmlo {
    my $obj = shift;
    my $xo = shift;
    my %p;
    foreach my $q (@FIELDS){
        $p{$q} = $obj->{$q} if defined($obj->{$q});
    }
    $xo->startTag("cuePt",%p);
    $obj->story()->xmlo($xo) if defined $obj->story();
    #$obj->mxmlInCPL()->xmlo($xo) if $obj->mxmlInCPL();#seems wrong, it is not a list
    #$obj->directoryList()->xmlo($xo) if $obj->directoryList();
    $obj->targetList()->xmlo($xo) if $obj->targetList();
    $obj->annotationList()->xmlo($xo) if defined $obj->annotationList();
    $xo->endTag("cuePt");
    return;
}

sub xml {
    my $obj = shift;
    my $ret;
    my $a = "";
    confess "Video::CPL::Cue::xml not updated\n";
    my $xo = new XML::Writer(OUTPUT=>\$a);
    my $cueType = $obj->{cueType};
    my $name = $obj->{name};
    $ret .= "<cuePt cueType=\"$cueType\" name=\"$name\" ";
    foreach my $q (@FIELDS){
	$ret .= "$q=\"$obj->{$q}\" " if defined($obj->{$q});
    }
    $ret .= ">\n";
    if ($obj->{story}){
        my $st = $obj->{story};
	$ret .= $st->xml();
	#my $btext = $st->{balloonText};
	#my $picloc = $st->{picLoc};
	#$ret .= "<story balloonText=\"$btext\" picLoc=\"$picloc\"/>\n";
    }
    if ($obj->{mxmlInCPL}){
        $ret .= XMLout($obj->{mxmlInCPL});
    }
    if ($obj->{dl}){
        my $dl = $obj->{dl};
	my $dltext = $obj->{dltext};
	$ret .= "<directoryList ";
	$ret .= "forever=\"$obj->{dlforever}\" " if $obj->{dlforever};
	$ret .= "headerText=\"$dltext\">\n";
	foreach my $t (@$dl){
	     $ret .= $t->printref($obj->{parent});
	}
	$ret .= "</directoryList>\n";
    }
    if ($obj->{tl}){
        #and here, we will always have an array of cue points?
	#YES until further notice
        my $tl = $obj->{tl};
	my $tltext = $obj->{tltext};
	my $tlpic = $obj->{tlpic};
	$ret .= "<targetList ";
	$ret .= "headerText=\"$tltext\" " if $tltext;
	$ret .= "backgroundPicLoc=\"$tlpic\"" if $tlpic;
	$ret .= ">\n";
	foreach my $t (@$tl){
	    if (ref($t)){
		$ret .= $t->printref($obj->{parent});
	    } else {
	        #presumed string
		$ret .= "<target cuePointRef=\"$t\"/>\n";
	    }
	}
	$ret .= "</targetList>\n";
    }
    my @anno = @{$obj->{annotations}};
    if (@anno){
        $ret .= "<annotationList>\n";
	foreach my $x (@anno){
	    confess("Video::CPL::Cue::xml is trying to print out annotations but parent is missing obj(".Dumper($obj).") x(".Dumper($x).")anno(".Dumper(\@anno).")\n") if !$obj->{parent} || !$x;
	    $ret .= $x->printref($obj->{parent});
	    #my $name = $x->{name};
	    #$ret .= "<target cuePointRef=\"$name\"/>\n";
	}
	$ret .= "</annotationList>\n";
    }
    $ret .= "</cuePt>\n";
    return $ret;
}

=head2 reffromobj($cplobj)

    return the string needed to refer to this in the context of a particular CPL object.

=cut

sub reffromobj {
    my $obj = shift;
    my $cpl = shift;
    confess("reffromobj but no parent\n") if !defined($obj->{parent});
    return $obj->{name} if $obj->parent() == $cpl;
    my $ctvfile = $obj->parent()->{ctvfilename};
    return "/$ctvfile\#$obj->{name}";
    #TODO: support for CPL objects with a different domain, think about dynamic
}

=head2 printref()

=cut

sub printref {
    my $obj = shift;
    my $par = shift;
    confess("printref but no parent\n") if !defined($obj->{parent});
    if ($par eq $obj->{parent}){
        #local reference
	return "<target cuePointRef=\"$obj->{name}\"/>\n";
    } else {
     #This is a bit fragile and does not support remote or non-top level directories Thought needed
        #remote reference
	#my $ref = $obj->{parent}->{ref};
	my $ctvfile = $obj->{parent}->{ctvfilename};
	#return "<target cuePointRef=\"$ref/$ctvfile\#$obj->{name}\"/>\n";
	return "<target cuePointRef=\"/$ctvfile\#$obj->{name}\"/>\n";
    }
}
=head1 AUTHOR

Carl Rosenberg, C<< <perl at coincident.tv> >>

=head1 BUGS

Please report any bugs or feature requests to Coincident TV.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Video::CPL::Cue


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

1; # End of Video::CPL::Cue
