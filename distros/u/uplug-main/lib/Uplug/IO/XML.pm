#-*-perl-*-
#####################################################################
# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#####################################################################
#
# XML
#
#####################################################################
#
# Note: XML without encoding-specification will be treated as latin1!
#       (look at readFromHandle)
#

package Uplug::IO::XML;

use strict;

use vars qw(@ISA $PARSERENCODING $USESGGREP $SGGREP);
use vars qw(%DEFAULTOPTIONS);
use XML::Parser;
use XML::Simple;

# use our own copy of XML::Writer
# (the latest version seems to break some things ...)
use Uplug::XML::Writer;

use Uplug::Encoding;
use Uplug::IO::Text;
use Uplug::Data;


@ISA = qw( Uplug::IO::Text );
$PARSERENCODING='utf-8';
$USESGGREP=0;

sub __find_sggrep{
    if ($_=`which sggrep 2>/dev/null`){
	chomp;$SGGREP=$_;
	use autouse 'Data::Dumper';
	$Data::Dumper::Indent=0;
	$Data::Dumper::Terse=0;
	$Data::Dumper::Purity=1;
    }
}

my $IGNOREWARNINGS=0;
my $DEFAULTROOTTAG='document';

# stream options and their default values!!
#
# encoding: physical encoding in the file
# InternalEncoding: encoding within UPLUG
#

%DEFAULTOPTIONS = (
		  'root' => '.*',                   # sub-tree root: any tag!
		  'encoding' => 'utf-8',
#		  'attributes' => 1,                # save attribute values
#		  'delimiter' => ' ',               # default delimiter
		   'REMOVESPACES' => 1,
		   'EXPANDBASICENT' => 1,           # expand &lt; %gt; $amp;
#		  'DocRootTag' => 'document',
		  );

1;		  

sub new{
    my $class=shift;
    my $self=$class->SUPER::new($class);
    foreach (keys %DEFAULTOPTIONS){
	$self->setOption($_,$DEFAULTOPTIONS{$_});
    }
#    &Uplug::IO::AddHash2Hash($self->{StreamOptions},\%DEFAULTOPTIONS);
    return $self;
}


sub init{
    my $self            = shift;
    my $options         = $_[0];
    if (ref($options) ne 'HASH'){$options={};}
#    if (not defined $options->{DocRootTag}){
#	$options->{DocRootTag}='.*';
#    }
    if ($self->SUPER::init($options)){
	if (defined $options->{DocRootTag}){
	    if (not defined $self->{StreamOptions}->{DocRoot}){
		$self->{StreamOptions}->{DocRoot}={};
	    }
	}
	if (defined $options->{DocHeaderTag}){
	    if (not defined $self->{StreamOptions}->{DocHeader}){
		$self->{StreamOptions}->{DocHeader}={};
	    }
	}
	if (defined $options->{DocBodyTag}){
	    if (not defined $self->{StreamOptions}->{DocBody}){
		$self->{StreamOptions}->{DocBody}={};
	    }
	}
	return 1;
    }
    return 0;
}

#---------------------------------------------------------------------------

sub open{
    my $self            = shift;
    $self->{AccessMode} = shift;
    my $HeaderHash      = $_[0];

    my $ret=$self->SUPER::open($self->{AccessMode},$HeaderHash);

    if ($self->{AccessMode} eq 'read'){
	if (defined $self->{FileHandle}){      # read data in binary mode!!!!
	    binmode($self->{FileHandle});      # XML::Parser takes care of the
	}                                      # internal encoding!
    }
    else{
	if (not defined $self->{XmlHandle}){
	    $self->{XmlHandle}= 
		new Uplug::XML::Writer(
				DATA_MODE => 1,
				DATA_INDENT => 1,
				UNSAFE => 1,
				OUTPUT => $self->{'FileHandle'});
	}
    }

    return $ret;
}


sub close{
    my $self=shift;
    my $ret=$self->SUPER::close();
    delete $self->{XmlParser};
    delete $self->{XmlHandle};
    return $ret;
}


sub read{
    my $self=shift;
    my $data=shift;
    if (not ref($data)){return 0;}
    my $root=shift;
    if (not $root){$root=$self->option('root');}
    $data->init();
#    $data->setDocRootTag($self->option('DocRootTag'));

    my $fh=$self->{FileHandle};
    $data->setHeader(undef);

    my $MakeIndex = $self->option('MAKESUBTREEINDEX');
    my $FilePos = tell($fh);
    my $NewSubtree = 1;

    while ($_=$self->readFromHandle($fh)){
	my $ret = $self->parseXML($data,$_,$root);
	if ($MakeIndex){
	    if (($self->{XmlHandle}->{SubTreeStarted} || $ret) && $NewSubtree){
		my $id = $self->{XmlHandle}->{SubTreeAttr}->{id};
		$self->saveSubtreePosition($id,$FilePos);
		$NewSubtree = 0;
	    }
	    if ($self->{XmlHandle}->{SubTreeEnded}){
		$NewSubtree = 1;
	    }
	}
	return 1 if ($ret);
	$FilePos = tell($fh);
    }
    if ($data->header){
	return 1;
    }
    return 0;
}


##########################################################################
# saveSubtreePosition and gotoSubtreePosition
#
#    cache the byte position of each subtree in a DBM file
#    (this is quite ad hoc but helps to speed up searching 
#     for subtrees with select and IDs)


BEGIN { @AnyDBM_File::ISA=qw(DB_File GDBM_File SDBM_File NDBM_File ODBM_File) }
use AnyDBM_File;
use POSIX;

sub saveSubtreePosition{
    my $self = shift;
    my ($id,$pos) = @_;

    my $file=$self->option('file');
    if (-e $file){
	if (not defined $self->{SUBTREEINDEX}){
	    if (not $self->{DBH}=tie %{$self->{SUBTREEINDEX}},
		'AnyDBM_File',
		$file.'.idx',
		O_RDWR|O_CREAT,0644){
		# print STDERR "problems!";
		return 0;
	    }
	}
	$self->{SUBTREEINDEX}->{$id} = $pos;
	# print STDERR "save $id .. $pos\n";
    }
}

sub gotoSubtreePosition{
    my $self = shift;
    my ($id,$pos) = @_;

    my $file=$self->option('file');
    if (-e $file){
	if (not defined $self->{SUBTREEINDEX}){
	    if (not $self->{DBH}=tie %{$self->{SUBTREEINDEX}},
		'AnyDBM_File',
		$file.'.idx',
		O_RDWR,0644){
		## print STDERR "problems!";
		## try to open in read-only mode!
		if (not $self->{DBH}=tie %{$self->{SUBTREEINDEX}},
		    'AnyDBM_File',
		    $file.'.idx',
		    O_RDONLY,0444){
		    # print STDERR "problems!";
		    delete $self->{SUBTREEINDEX};
		    return 0;
		}
	    }
	}
    }
    if (my $pos = $self->{SUBTREEINDEX}->{$id}){
	if (my $fh=$self->{FileHandle}){
	    seek $fh,$pos,0;
	    # print STDERR "goto $id .. $pos\n";
	    return 1;
	}
    }
    return 0;
}


##########################################################################
# select .... select subtrees in the XML file
#
#   * use sggrep if defined
#   * use byte-position cache if it exists
#   * read through the file sequentially otherwise
#

sub select{
    my $self=shift;
    my ($data,$pattern) = @_;
    my $file=$self->option('file');
    if (-e $file){
	if (ref($pattern) eq 'HASH'){
	    if (defined $pattern->{id}){
		if ($self->gotoSubtreePosition($pattern->{id})){
		    if (scalar keys %{$pattern} == 1){
			# print STDERR "reading only ...\n";
			return $self->read(@_);
		    }
		}
	    }
	}

	if ($USESGGREP){
	    &__find_sggrep() if (not defined $SGGREP);
	    if (defined $SGGREP){
		return $self->sggrepSelect($file,@_);
	    }
	}
    }
    return $self->SUPER::select(@_);
}


sub sggrepSelect{
    my $self=shift;
    my ($file,$data,$pattern,$attr,$operator)=@_;
    $data->init();
    my $patternkey=Dumper($pattern);

    my $ret=$self->readSggrepResult($data,$patternkey);
    if ($ret<0){
	my $root=$self->option('root');
	my $query=&MakeSggrepQuery($root,$pattern);
	my $subquery=&MakeSggrepSubQuery($pattern);
	my $regexp=&MakeSggrepRegExp($pattern);

	my $result;
	if ($file=~/\.gz$/){
	    $result=`gzip -cd $file | $SGGREP -r $query $subquery $regexp 2>/dev/null`;
	}
	else{
	    $result=`$SGGREP -r $query $subquery $regexp <$file 2>/dev/null`;
	}
	if ($?){
	    print STDERR "something went wrong when executing sggrep!\n";
	    print STDERR "command: $SGGREP -r $query $subquery $regexp <$file";
	    return $self->SUPER::select($data,$pattern,$attr,$operator);
	}
	my @lines=split(/\n/,$result);
	my @header=();
	while (@lines and $lines[0]!~/^\<$root/){push(@header,shift @lines);}
	unshift (@lines,'<sggrep>');
	push (@lines,'</sggrep>');
	@{$self->{SGGREPRESULT}->{$patternkey}}=@lines;
	return $self->readSggrepResult($data,$patternkey);
    }
    return $ret;
}

#------------
# read sggrep results
#    return 1 + data if sggrep result is found and ok
#    return 0 if sggrep result is found but empty
#    return -1 if the query pattern is new

sub readSggrepResult{
    my $self=shift;
    my $data=shift;
    my $key=shift;
    if (ref($self->{SGGREPRESULT}) ne 'HASH'){
	$self->{SGGREPRESULT}={};
    }
    if (ref($self->{SGGREPRESULT}->{$key}) eq 'ARRAY'){
	my $fh=$self->{FileHandle};
	$self->{FileHandle}=$self->{SGGREPRESULT}->{$key};
	if ($self->read($data)){
	    $self->{FileHandle}=$fh;
	    return $self->Uplug::IO::read($data);
	}
	$self->{FileHandle}=$fh;
	delete $self->{SGGREPRESULT}->{$key};
	return 0;
    }
    return -1;
}

sub MakeSggrepQuery{
    my $root=shift;
    my $pattern=shift;
    my $query=".*/$root";
    my %attr=();
    if (ref($pattern) eq 'HASH'){
	foreach (keys %{$pattern}){
	    if ($pattern->{$_}!~/\//){
		$attr{$_}=$pattern->{$_};
	    }
	}
    }
    if (keys %attr){
	$query.='[';
	foreach (keys %attr){
	    $query.="$_\=\"$attr{$_}\" ";
	}
	chop $query;                     
	$query.=']';
    }
    $query="'$query'";
    return $query;
}

sub MakeSggrepSubQuery{     # doesn't do anything yet
    my $pattern=shift;
    return '';
}

sub MakeSggrepRegExp{       # doesn't do anything yet
    my $pattern=shift;
    return '';
}


sub readFromHandle{
    my $self=shift;
    my $fh=shift;

    if (ref($fh) eq 'ARRAY'){
	return shift @{$fh};
    }

    my $InputDel=$/;                          # save old input delimiter
    $/='>';                                   # set delimiter to '>'

    #-------------------------------------
    # don't change the encoding! just read the original string!
    # (the XML-parser changes everything to UTF-8!)
    # (don't do 'my $content=$self->SUPER::readFromHandle(@_);')

    my $content=<$fh>;
    $/=$InputDel;                             # restore old input delimiter

    #------------------------------------------------
    # fixing a bug in the PLUG corpus:
    #   set the default encoding (to 'iso-8859-1')
    #   if not specified in the xml declaration

    if ($content=~/\<\?xml\s/){
	if ($content!~/encoding/s){
	    $content=~s/\?\>/ encoding="iso-8859-1"\?\>/s;
	}
    }
    return $content;
}



#-------------------------------------------------------------------
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#

sub write{
    my $self=shift;
    my $data=shift;

    $self->Uplug::IO::write($data);

    my $fh=$self->{FileHandle};
    if (not $self->{StreamOptions}->{SkipDataHeader}){
	my $before=$data->header;
	if (defined $before){
	    $self->writeToHandle($fh,$before);
	}
    }

    $self->printXML($fh,$data->root());       # print XML-node!
#    $self->writeToHandle($fh,$data->toXML);

    if (not $self->{StreamOptions}->{SkipDataTail}){
	my $after=$data->tail;
	if (defined $after){
	    $self->writeToHandle($fh,$after);
	}
    }
    return 1;
}

sub readheader{
    my $self=shift;

    if (defined $self->{StreamOptions}->{DocHeaderTag}){
	$self->{StreamOptions}->{DocHeader}={};
	my $data=Uplug::Data->new();
#	$data->setDocRoot($self->{StreamHeader}->{DocRootTag});
	$self->read($data,$self->{StreamOptions}->{DocHeaderTag});
	my $attr=$data->attribute();
	$self->addheader($attr);
#	$self->{StreamHeader}->{DocRootTag}=$data->DocRootTag;
    }
    elsif (ref($self->{FileHandle})){
	my $fh=$self->{FileHandle};
	my $root=shift;
	if (not $root){$root=$self->option('root');}
	my $data=Uplug::Data->new();
	binmode($fh);
	while ($_=$self->readFromHandle($fh)){
	    # print STDERR "\n header: $_";
	    my $ret = $self->parseXML($data,$_,$root);
	    if ($self->{XmlHandle}->{NewDoc}){last;}
#	    if (defined $self->{XmlHandle}->{XmlProlog}){last;}
	}
    }
}

sub writeheader{
    my $self=shift;
    if (not defined $self->{XmlHandle}){
	$self->{XmlHandle}= new Uplug::XML::Writer(
					    DATA_MODE => 1,
					    DATA_INDENT => 1,
					    UNSAFE => 1,
#					    NEWLINES => 1,
					    OUTPUT => $self->{'FileHandle'});
    }
    $self->{XmlHandle}->xmlDecl($self->{StreamOptions}->{encoding});
    if (defined $self->{StreamOptions}->{DTDname}){
	# print STDERR "$self->{StreamOptions}->{DTDname}\n";
	# print STDERR "$self->{StreamOptions}->{DTDpublicID}\n";
	# print STDERR "$self->{StreamOptions}->{DTDsystemID}\n";
	$self->{XmlHandle}->doctype($self->{StreamOptions}->{DTDname},
				    $self->{StreamOptions}->{DTDpublicID},
				    $self->{StreamOptions}->{DTDsystemID});
    }
    my $ret;
    my $fh=$self->{'FileHandle'};
    if (defined $self->{StreamHeader}->{BeforeDocRoot}){
	if ($self->{StreamHeader}->{BeforeDocRoot}=~/\S/s){
	    $self->writeToHandle($fh,$self->{StreamHeader}->{BeforeDocRoot});
	}
    }
    if (defined $self->{StreamOptions}->{DocRootTag}){
	$ret*=$self->OpenTag($self->{StreamOptions}->{DocRootTag},
			     $self->{StreamOptions}->{DocRoot});
    }

    my $string=&XMLout($self->{StreamOptions}->{DocHeader},
		       keyattr => ['id'],
		       rootname => $self->{StreamOptions}->{DocHeaderTag});
    if ($string=~/\S/s){
	$self->writeToHandle($fh,$string);
    }

    if (defined $self->{StreamOptions}->{DocBodyTag}){
	$ret*=$self->OpenTag($self->{StreamOptions}->{DocBodyTag},
			     $self->{StreamOptions}->{DocBody});
    }
    return $ret;
}


sub writetail{
    my $self=shift;
    $self->CloseAllTags;
    $self->{XmlHandle}->end();
}





#------------------------------------------------------------------------

sub keepSpaces{$_[0]->setOption('REMOVESPACES',0);}
sub removeSpaces{$_[0]->setOption('REMOVESPACES',1);}


sub CompileTagREs{
    my $self=shift;
    foreach my $t ('DocRootTag','SubTreeRoot','DocBodyTag'){
	if (defined $self->{XmlHandle}->{$t}){
	    $self->{XmlHandle}->{$t.'RE'}=qr/^($self->{XmlHandle}->{$t})$/;
	}
    }
}

sub parseXML{
    my $self=shift;
    my ($data,$xml,$root)=@_;

    if ($root and ($root ne $self->{SubTreeRoot})){
	$self->{SubTreeRoot}=$root;
	$self->CompileTagREs;
    }

    if (not ref($self->{XmlParser})){
	$self->{XmlParser}=
	    new XML::Parser(Handlers => {Start => \&XmlTagStart,
					 End => \&XmlTagEnd,
					 Default => \&XmlChar,
					 XMLDecl => \&XmlDecl,
#					 Doctype => \&XmlDoctype
					 },);
	$self->{XmlHandle}=$self->{XmlParser}->parse_start;
	$self->{XmlHandle}->{XmlProlog}='';
	#
	# set some parameters for the parser:
	#
	$self->{XmlHandle}->{REMOVESPACES}=$self->option('REMOVESPACES');
	$self->{XmlHandle}->{EXPANDBASICENT}=$self->option('EXPANDBASICENT');
	$self->{XmlHandle}->{SubTreeRoot}=$self->option('root');
	$self->{XmlHandle}->{DocRootTag}=$self->option('DocRootTag');
	$self->{XmlHandle}->{DocBodyTag}=$self->option('DocBodyTag');
	$self->CompileTagREs;
    }

    $self->{XmlHandle}->{XmlData}=$data;

    if (not $self->{XmlHandle}->{LastNode}){        # --> new data!
	delete $self->{XmlHandle}->{BeforeSubTree}; # delete header
	delete $self->{XmlHandle}->{SubTreeEnded};  # reset subtree flag
	$self->{XmlHandle}->{LastNode}=1;
    }

    eval { $self->{XmlHandle}->parse_more($xml); }; # call xml-parser

    if ($@){                                        # and catch possible errors
	if (not $IGNOREWARNINGS){                   # print warnings
	    warn $@;
	    print STDERR $xml;
	}
	$data->setHeader($self->{XmlHandle}->{BeforeSubTree}.$xml);
	$self->{XmlHandle}->{SubTreeEnded}=undef;
	$self->{XmlHandle}=$self->{XmlParser}->parse_start;  # re-start
	my $ParseStr=$self->{XmlHandle}->{XmlProlog};        # XML parsern!
	eval { $self->{XmlHandle}->parse_more($ParseStr); };
	return -1;                                           # return error!
    }
    if ($self->{XmlHandle}->{REMOVESPACES}){
	$self->{XmlHandle}->{BeforeSubTree}=~s/(\S)\s*$/$1/s;
	$self->{XmlHandle}->{BeforeSubTree}=~s/^\s*(\S)/$1/s;
    }
    $data->setHeader($self->{XmlHandle}->{BeforeSubTree});
    if ($self->{XmlHandle}->{SubTreeEnded}){                 # complete SubTree
	delete $self->{XmlHandle}->{LastNode};
	delete $self->{XmlHandle}->{SubTreeEnded};
	delete $self->{XmlHandle}->{BeforeSubTree};
	delete $self->{XmlHandle}->{SubTreeString};
	return 1;
    }
    return 0;                                                # incomplete!
}



#---------------------------------------------------------------------------
# subroutine-handles for the XML-parser
#

sub XmlTagStart{
    my ($p,$e,%a)=@_;

    #--------------------------------------------------
    # document root tags are parsed ... but ignored
    #--------------------------------------------------
    if ((defined $p->{DocRootTag}) and      # if DocRootTag is specified
	($e=~/$p->{DocRootTagRE}/)){      # and the current tag matches
	$p->{BeforeSubTree}='';              # --> this is the doc root tag
	$p->{DocRootTag}=$e;
	$p->{DocRootTagRE}=qr/^($p->{DocRootTag})$/;
	$p->{NewDoc}=1;                      # --> the beginning of a new doc!
	%{$p->{DocRoot}}=%a;
	return;
    }
    if ((not defined $p->{DocRootTag}) and  # DocRootTag is not specified and
	(not $p->{NewDoc})){                # no doc-root-tag is parsed yet:
	$p->{BeforeSubTree}.=$p->recognized_string;
	$p->{NewDoc}=1;                      # --> the beginning of a new doc!
	%{$p->{DocRoot}}=%a;
	return;
    }
    #--------------------------------------------------
    # a new subtree starts!
    #--------------------------------------------------
    if ($e=~/$p->{SubTreeRootRE}/){
	$p->{SubTreeStarted}=$e;
	$p->{SubTreeEnded}=0;
	if ($p->{SubTreeString}){                       # check previous data
	    $p->{BeforeSubTree}.=$p->{SubTreeString};
	    $p->{SubTreeString}=undef;
#	    $p->{XmlData}=Uplug::Data::Node->new($p->{XmlData}->label,\%a);
#	    $p->{LastNode}=$p->{XmlData};
	}
	$p->{XmlData}->init($e,\%a);
	$p->{LastNode}=$p->{XmlData}->root;
	$p->{SubTreeString}.=$p->recognized_string();
	%{$p->{SubTreeAttr}}=%a;
    }

    elsif ($p->{SubTreeStarted}){

	#--------------------------------------------------
	# we are inside a valid subtree!
	#--------------------------------------------------

	$p->{LastNode}=
	    $p->{XmlData}->addNode($p->{LastNode},$e,\%a);
	$p->{SubTreeString}.=$p->recognized_string();
    }

    #--------------------------------------------------
    # still before a sub-tree
    #--------------------------------------------------

    else{
	if ((defined $p->{DocBodyTagRE}) and ($e=~/$p->{DocBodyTagRE}/)){
	    $p->{DocBodyTag}=$e;
	    $p->{DocBodyTagRE}=qr/^($p->{DocBodyTag})$/;
	    $p->{NewBody}=1;
	    %{$p->{DocBody}}=%a;
	}
	$p->{BeforeSubTree}.=$p->recognized_string;
    }
}

sub XmlTagEnd{
    my ($p,$e)=@_;
    #--------------------------------------------------
    # document root tags are parsed ... but ignored
    #--------------------------------------------------
    if ((defined $p->{DocRootTagRE}) and ($e=~/$p->{DocRootTagRE}/)){
	delete $p->{NewDoc};
	return;
    }
    if ($p->{SubTreeStarted}){
	if (ref($p->{LastNode})){
	    $p->{LastNode}=
		$p->{XmlData}->parent($p->{LastNode});
	}
    }
    else{
	$p->{BeforeSubTree}.=$p->recognized_string;
    }
    #--------------------------------------------------
    # the subtree ended!
    #--------------------------------------------------
    if (($e=~/$p->{SubTreeRootRE}/) and 
	($p->{SubTreeStarted} eq $e)){
	$p->{XmlData}->setLabel($e);
	$p->{SubTreeEnded}=$e;
	$p->{SubTreeStarted}=0;
    }
}


sub XmlChar{
    my ($p,$c)=@_;


    #--------------------------------------------------
    # inside a subtree -> save the string
    #--------------------------------------------------
    if ($p->{SubTreeStarted}){
	if (($c!~/\S/) and $p->{REMOVESPACES}){
	    return;
	}
	if ($p->{EXPANDBASICENT}){
	    $c=~s/\&gt\;/\>/gis;
	    $c=~s/\&lt\;/\</gis;
	    $c=~s/\&amp\;/\&/gis;
	    $c=~s/\&apos\;/\'/gis;
	    $c=~s/\&d?quot\;/\"/gis;
	}

	$p->{XmlData}->addContent($p->{LastNode},$c);  # add new content!
#	$p->{LastNode}->addTextNode($c);
# 	$p->{LastNode}->addContent($c);
    }
    #--------------------------------------------------
    # not inside?! -> save string as header
    #--------------------------------------------------
    else{
	$p->{BeforeSubTree}.=$c;
    }
}

sub XmlDecl{
    my ($p,$v,$e,$s)=@_;

    $p->{XmlProlog}=$p->original_string;
    $p->{XmlEncoding}=$e;
    $p->{XmlVersion}=$v;
}

#sub XmlDoctype{
#    my ($p,$name,$sysid,$publid,$internal)=@_;
#    my $ll;
#}






#------------------------------------
# links to the SubTree-parser
#------------------------------------
# information from the XML SubTree parser:
#        XmlProlog: xml declaration (and more?)
#    SubTreeHeader: everything before SubTreeRoot
#   SubTreeRootTag: XML-tag of current sub-tree
#   LastDocRootTag: document root tag
#   LastDocBodyTag: document body tag
#      DocRootAttr: document root attributes
#      DocBodyAttr: document body attributes
#       NewDocRoot: 1 --> new document root
#       NewDocBody: 1 --> new document body

sub XmlProlog{return $_[0]->{XmlHandle}->{XmlProlog};}
sub SubTreeHeader{return $_[0]->{XmlHandle}->{BeforeSubTree};}
sub SubTreeRootTag{return $_[0]->{SubTreeRootTag};}
sub LastDocRootTag{return $_[0]->{XmlHandle}->{DocRootTag};}
sub LastBodyRootTag{return $_[0]->{XmlHandle}->{DocBodyTag};}
sub DocRootAttr{return $_[0]->{XmlHandle}->{DocRoot};}
sub DocBodyAttr{return $_[0]->{XmlHandle}->{DocBody};}
sub NewDocRoot{
    my $self=shift;
    if ($self->{XmlHandle}->{NewDoc}){
	$self->{XmlHandle}->{NewDoc}=0;
	return 1;
    }
    return 0;
}
sub NewDocBody{
    my $self=shift;
    if ($self->{XmlHandle}->{NewBody}){
	$self->{XmlHandle}->{NewBody}=0;
	return 1;
    }
    return 0;
}








sub printXML{
    my $self=shift;
    my $fh=shift;
    my $node=shift;
    my $writer=shift;

    my $internal=$self->getInternalEncoding();
    my $external=$self->getExternalEncoding();
    my $rmSpaces=$self->option('REMOVESPACES');

    if (not defined $node){return undef;}

    if (not ref($fh)){$fh=*STDOUT;}
    if (not $writer){
	if (not $self->{XmlWriter}){
	    $self->{XmlWriter}=
		new Uplug::XML::Writer(
				DATA_MODE => $rmSpaces,
				DATA_INDENT => $rmSpaces,
				UNSAFE => $rmSpaces,
				OUTPUT => $fh,
				);
	}
	$writer=$self->{XmlWriter};
    }

    if (not ref($node)){next;}
    elsif ($node->isTextNode){
	my $str=$node->text;
	if ($rmSpaces and $node!~/\S/){next;}
	if ($internal ne $external){
	    $str=&Uplug::Encoding::convert($str,$internal,$external);
#	    $str=&Uplug::Encoding::encode($str,$external,$internal);
	}
	$writer->characters($str);
    }
    else{
	my $attr=$node->attributes();
	my $name=$node->getNodeName();
	if (not $node->hasChildNodes()){
	    if (ref($attr) eq 'HASH'){
		if ($internal ne $external){
		    &Uplug::Encoding::encodeArray($attr,$internal,$external);
		}
		$writer->emptyTag($name,%{$attr});
	    }
	    else{
		$writer->emptyTag($name);
	    }
	}
	else{
	    if (ref($attr) eq 'HASH'){
		if ($internal ne $external){
		    &Uplug::Encoding::encodeArray($attr,$internal,$external);
		}
		$writer->startTag($name,%{$attr});
	    }
	    else{
		$writer->startTag($name);
	    }

	    foreach my $n ($node->children()){
		$self->printXML($fh,$n,$writer);
	    }

	    $writer->endTag($name);
	}
    }


}


sub prettyPrintXML{
    my $self=shift;
    return $self->printXML(@_);
}






sub OpenTag{
    my ($self,$tag,$attr)=@_;
    if (ref($attr) eq 'HASH'){
	$self->{XmlHandle}->startTag($tag,%{$attr});
    }
    else{
	$self->{XmlHandle}->startTag($tag);
    }
    push (@{$self->{OpenTagStack}},$tag);
}

sub CloseTag{
    my ($self,$tag)=@_;
    if (not defined $self->{OpenTagStack}){
	return 0;
    }
    if (not $tag){
	$tag=$self->{OpenTagStack}->[-1];
    }
    while ((@{$self->{OpenTagStack}}) and 
	   ($self->{OpenTagStack}->[-1] ne $tag)){
	$self->CloseTag($self->{OpenTagStack}->[-1]);
    }
    if ($self->{OpenTagStack}->[-1] eq $tag){
	pop @{$self->{OpenTagStack}};
	$self->{XmlHandle}->endTag($tag);
	return 1;
    }
    return 0;
}

sub CloseAllTags{
    my ($self)=@_;
    if (defined $self->{OpenTagStack}){
	while (@{$self->{OpenTagStack}}){
	    $self->CloseTag;
	}
    }
}

