package Toader::Render::General;

use warnings;
use strict;
use base 'Error::Helper';
use Toader::Templates;
use Toader::Entry::Helper;
use Toader::Entry::Manage;
use Toader::Page::Helper;
use Toader::Page::Manage;
use Toader::Render::CSS;
use Toader::Render::Entry;
use Toader::Render::supportedObjects;
use Toader::pathHelper;
use Toader::Gallery;
use File::Spec;
use Toader::Directory;
use Email::Address;
use Toader::AutoDoc;
use Image::ExifTool;
use Script::isAperlScript;

=head1 NAME

Toader::Render::General - Renders various general stuff for Toader as well as some other stuff.

=head1 VERSION

Version 0.5.0

=cut

our $VERSION = '0.5.0';

=head1 METHODS

=head2 new

This initiates the object.

=head3 args hash ref

=head4 toader

This is the L<Toader> object.

=head4 obj

This is the L<Toader> object being worked with.

=head4 toDir

This is the path to use for getting back down to the directory.

Lets say we have rendered a single entry to it's page, then it would
be "../../", were as if we rendered a page of multiple entries it
would be "../".

The default is "../../".

This is set to '' if fullURL is set to true.

=head4 fullURL

This is if it should make a non-relative link for when generating links. If set to 1,
it makes links non-relative. If not defined/false it uses relative links.

=head4 dir

This is the directory that it is currently in. This can differ from the object directory
and if not defined will be set to the object directory, which is found via $args{obj}->dirGet.

    my $g=Toader::Render::General->new(\%args);
    if($g->error){
        warn('error: '.$g->error.":".$g->errorString);
    }

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	my $self={
			  error=>undef,
			  errorString=>'',
			  perror=>undef,
			  isatd=>Toader::isaToaderDir->new,
			  soc=>Toader::Render::supportedObjects->new,
			  toDir=>'../../',
			  fullURL=>0,
			  locationSub=>'',
			  errorExtra=>{
				  flags=>{
					  1=>'noToaderObj',
					  2=>'notAtoaderObj',
					  3=>'toaderPerror',
					  4=>'noRenderableObj',
					  5=>'notArenderableObj',
					  6=>'objPerror',
					  7=>'noDirSet',
					  8=>'noLinkDefined',
					  9=>'templateFetchErrored',
					  11=>'noToaderdirSpecified',
					  12=>'notAtoaderDir',
					  13=>'noEntryIDspecified',
					  14=>'entryDoesNotExist',
					  15=>'noPageSpecified',
					  16=>'pageDoesNotExist',
					  17=>'noFileSpecified',
					  18=>'templateInitErrored',
					  19=>'r2rErrored',
					  20=>'b2rErrored',
					  21=>'pathhelperInitErrored',
					  22=>'subToaderDirListErrored',
					  23=>'pageManageDirSetErrored',
					  24=>'listPagesErrored',
					  25=>'entryManageErrored',
					  26=>'readEntryErrored',
					  27=>'renderEntryInitErrored',
					  28=>'renderEntryErrored',
					  29=>'noAuthorsLineSpecified',
					  30=>'authorsLineParseFailed',
					  31=>'entryManageDirSetErrored',
					  32=>'pageListErrored',
					  33=>'pageReadErrored',
					  34=>'autoDocFileDotDotError',
					  35=>'noURLinConfig',
					  36=>'noImageURLspecified',
					  37=>'noImageFileSpecified',
					  38=>'imageDoesNotExist',
					  39=>'pathCleanupErrored',
					  40=>'galleryInitErrored',
					  41=>'outputURLnotSpecified',
					  42=>'noSrcPathSpecified',
					  43=>'noURLspecified',
					  44=>'relativeDirContainsAperiod',
					  45=>'noSrcURLspecified',
				  },
			  },
			  };
	bless $self;

	if ( defined ( $args{toDir} ) ){
		$self->{toDir}=$args{toDir};
	}

	
	if ( defined( $args{fullURL} ) ){
		$self->{fullURL}=$args{fullURL};
	}

	#make sure we have a usable Toader object
	if ( ! defined( $args{toader} ) ){
		$self->{perror}=1;
		$self->{error}=1;
		$self->{errorString}='No Toader object defined';
		$self->warn;
		return $self;
	}
	if ( ref( $args{toader} ) ne 'Toader' ){
		$self->{perror}=1;
        $self->{error}=2;
        $self->{errorString}='The specified Toader object is actually a "'.ref( $args{ref} ).'"';
        $self->warn;
        return $self;
    }
	if ( ! $args{toader}->errorblank ){
		$self->{perror}=1;
        $self->{error}=3;
        $self->{errorString}='The Toader object has a permanent error set';
        $self->warn;
        return $self;
	}
	$self->{toader}=$args{toader};
	$self->{ph}=$self->{toader}->getPathHelper;
	
	#make sure we have a usable object
	if ( ! defined( $args{obj} ) ){
		$self->{perror}=1;
		$self->{error}=4;
		$self->{errorString}='No object specified for the renderable object';
		$self->warn;
		return $self;
	}
	if ( ! $self->{soc}->isSupported( $args{obj} ) ){
		$self->{perror}=1;
		$self->{error}=5;
		$self->{errorString}='"'.ref( $args{obj} ).'" does not appear to be a Toader renderable object';
		$self->warn;
		return $self;
	}
	if ( ! $args{obj}->errorblank ){
		$self->{perror}=1;
		$self->{error}=6;
		$self->{errorString}='The specified renderable object has a permanent error set';
		$self->warn;
		return $self;
	}
	$self->{obj}=$args{obj};

	#make sure the renderable object has a directory set
	$self->{odir}=$self->{obj}->dirGet;
	if ( ! defined( $self->{odir} ) ){
		$self->{perror}=1;
		$self->{error}=7;
		$self->{errorString}='The renderable object does not have a directory specified';
		$self->warn;
		return $self;
	}

	#initialize the Toader::pathHelper
	$self->{ph}=Toader::pathHelper->new( $self->{odir} );
	if ( $self->{ph}->error ){
		$self->{perror}=1;
		$self->{error}=6;
		$self->{errorString}='Failed to initiate pathHelper. error="'.
			$self->{ph}->error.'" errorString="'.$self->{ph}->errorString.'"';
		$self->warn;
		return $self;
	}

	#cleans up the object directory path
    $self->{odir}=$self->{ph}->cleanup( $self->{odir} );
    if ( $self->{ph}->error ){
		$self->{perror}=1;
		$self->{error}=39;
		$self->{errorString}='Failed to clean up the path for "'.$self->{odir}.'"';
		$self->warn;
		return undef;
    }

	#get this once as it does not change and is likely to be used
	#gets the r2r for the object
	$self->{or2r}=$self->{ph}->relative2root( $self->{odir} );
	if ( $self->{ph}->error ){
		$self->{perror}=1;
		$self->{error}=19;
		$self->{errorString}='pathHelper failed to find the relative2root path for "'.
			$self->{odir}.'"';
		$self->warn;
		return $self;
	}
	#get the b2r for the object
	$self->{ob2r}=$self->{toDir}.'/'.$self->{ph}->back2root( $self->{odir} );
	if ( $self->{ph}->error ){
		$self->{perror}=1;
		$self->{error}=20;
		$self->{errorString}='pathHelper failed to find the relative2root path for "'.
			$self->{odir}.'"';
		$self->warn;
		return $self;
	}
	#makes gets the directory to work in
	if ( defined( $args{dir} ) ){
		$self->{dir}=$args{dir};
		$self->{r2r}=$self->{ph}->relative2root( $self->{dir} );
		if ( $self->{ph}->error ){
			$self->{perror}=1;
			$self->{error}=19;
			$self->{errorString}='pathHelper failed to find the relative2root path for "'.
				$self->{dir}.'"';
			return $self;
		}
		$self->{b2r}=$self->{toDir}.'/'.$self->{toDir}.'/'.$self->{ph}->relative2root( $self->{dir} );
		if ( $self->{ph}->error ){
			$self->{perror}=1;
			$self->{error}=20;
			$self->{errorString}='pathHelper failed to find the relative2root path for "'.
				$self->{dir}.'"';
			return $self;
		}
	}else{
		$self->{dir}=$self->{odir};
		$self->{r2r}=$self->{or2r};
		$self->{b2r}=$self->{ob2r};
	}
	
	#clean up the various paths
	$self->{dir}=File::Spec->canonpath( $self->{dir} );
	$self->{r2r}=File::Spec->canonpath( $self->{r2r} );
	$self->{b2r}=File::Spec->canonpath( $self->{b2r} );
    $self->{or2r}=File::Spec->canonpath( $self->{or2r} );
    $self->{ob2r}=File::Spec->canonpath( $self->{ob2r} );

	#gets the base URL
	my $c=$self->{toader}->getConfig;
	if ( defined( $c->{'_'}->{'url'} ) ){
		$self->{url}=$c->{'_'}->{'url'};
	}
	if ( $self->{fullURL} ){
		if ( ! defined( $c->{'_'}->{url} ) ){
			$self->{perror}=1;
			$self->{error}=35;
			$self->{errorString}='No URL specified in the Toader config';
			$self->warn;
			return $self;
		}
		$self->{toDir}='';
	}

	#figures out the file directory
	$self->{toFiles}=$self->{b2r}.'/'.$self->{or2r}.'/'.$self->{obj}->filesDir;
	$self->{toFiles}=File::Spec->canonpath( $self->{toFiles} );

	#initiates the Templates object
	$self->{t}=Toader::Templates->new({ 
		dir=>$self->{dir},
		toader=>$args{toader},
									  });
	if ( $self->{t}->error ){
		$self->{perror}=1;
		$self->{error}=18;
		$self->{errorString}='Failed to initialize the Toader::Templates module';
		$self->warn;
		return $self;
	}

	#checks if it is at the root or not
	$self->{atRoot}=$self->{ph}->atRoot( $self->{odir} );

	return $self;
}

=head2 adlink

This generates a link to the the specified documentation file.

Three arguments are taken. The first is the relative directory to the
Toader root in which it resides, which if left undefined is the same
as the object used to initiate this object. The second is file found by
autodoc. The third is the text for the link, which if left undefined is
the same as the file.

If the text is left undefined and the file ends in ".html", the ".html"
part is removed.

    $g->cdlink( $directory,  $file, $text );

The template used for this is 'linkDirectory', which by default
is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed to it are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::General> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
	obj - This is the object that Toader was initiated with.

=cut

sub adlink{
	my $self=$_[0];
	my $dir=$_[1];
	my $file=$_[2];
	my $txt=$_[3];

	#blanks any previous errors
	if ( ! $self->errorblank ){
        return undef;
	}

	if ( ! defined( $dir ) ){
		$dir=$self->{r2r};
	}

	# make sure a file is specified
	if ( ! defined( $file ) ){
		$self->{error}=17;
		$self->{errorString}='No file specified';
		$self->warn;
		return undef;
	}

	#make sure it does not start with ../
	if ( $file =~ /^\.\.\// ){
		$self->{error}=34;
		$self->{errorString}='File matches /^..\//';
		$self->warn;
		return undef;
	}

	my $checker=Script::isAperlScript->new({
		any=>1,
		env=>1,
										   });
	#append .html for POD docs
	if ( $file =~ /\.[Pp][Oo][Dd]$/ ){
		$file=$file.'.html';
	}
	if ( $file =~ /\.[Pp][Mm]$/ ){
		$file=$file.'.html';
	}
	if ( $checker->isAperlScript( $self->{dir}.'/'.$file ) ){
		$file=$file.'.html';
	}

	if ( ! defined( $txt ) ){
		$txt=$file;
		$txt=~s/\.html$//;
	}

	my $link='';
	if ( $self->{fullURL} ){
		$link=$dir.'/.autodoc/.files/'.$file;
		$link=~s/\/\/*/\//g;
		$link=$self->{url}.$link;
	}else{
		$link=$self->{b2r}.'/'.$dir.'/.autodoc/.files/'.$file;
		$link=~s/\/\/*/\//g;
	}

    #renders the AutoDoc link
    my $adlink=$self->{t}->fill_in(
        'autodocLink',
        {
            toDir=>$self->{toDir},
            toFiles=>$self->{toFiles},
            obj=>\$self->{obj},
            c=>\$self->{toader}->getConfig,
            toader=>\$self->{toader},
            self=>\$self,
            g=>\$self,
			url=>$link,
			text=>$txt,
        }
        );
    if ( $self->{t}->error ){
        $self->{error}=10;
        $self->{errorString}='Failed to fill in the template. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }

	return $adlink;
}

=head2 adListLink

This returns a link to the documentation list.

The template used for this is 'linkAutoDocList', which by default
is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed to it are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::General> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    obj - This is the object that Toader was initiated with.

=cut

sub adListLink{
	my $self=$_[0];
	my $text=$_[1];

    if ( ! $self->errorblank ){
        return undef;
    }

	if (! defined( $text ) ){
		$text='Documentation';
	}

    my $link='';
    if ( $self->{fullURL} ){
        $link=$self->{r2r};
		$link=~s/\/\/*/\//g;
		$link=$self->{url}.$link;
    }else{
		$link=$self->{b2r}.'/'.$self->{r2r}.'/.autodoc/';
		$link=~s/\/\/*/\//g;
    }


    #renders the beginning of the authors links
    my $adllink=$self->{t}->fill_in(
        'linkAutoDocList',
        {
            toDir=>$self->{toDir},
            toFiles=>$self->{toFiles},
            obj=>\$self->{obj},
            c=>\$self->{toader}->getConfig,
            toader=>\$self->{toader},
            self=>\$self,
            g=>\$self,
            url=>$link,
            text=>$text,
        }
        );
    if ( $self->{t}->error ){
        $self->{error}=10;
        $self->{errorString}='Failed to fill in the template. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }

    return $adllink;
}

=head2 atRoot

This returns a Perl boolean value for if the current directory
is the root L<Toader> directory or not.

    my $atRoot=$g->atRoot;
    if ( $aRoot ){
        print "At root.\n";
    }

=cut

sub atRoot{
	my $self=$_[0];

	if ( ! $self->errorblank ){
		return undef;
	}

	return $self->{atRoot};
}

=head2 authorsLink

Used for generating the author line.

This parses a From header, such as the value returned
from Toader::Entry->fromGet.

One value is requied and that is what is to be parsed and
returned as a link.

    $g->authorsLink($entry->fromGet);

=head3 Templates

=head4 authorBegin

This begins the authors link section.

The default template is blank.

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=head4 authorLink

This is a link for one of the authors.

The default template is as below.

    <a href="mailto:[== $address ==]">[== $name ==]</a>

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.
    address - The email address of the author.
    comment - The comment portion of it.
    original - The original form for this chunk.
    name - The name of the author.

=head4 authorJoin

This is used for joining multiple authors.

The default template is as below.

    , 
    

The variables passed to it are as below.

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=head4 authorEnd

This ends the authors link section.

The default template is blank.

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=cut

sub authorsLink{
	my $self=$_[0];
	my $aline=$_[1];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	#make sure we have a authors line
	if ( ! defined( $aline ) ){
		$self->{error}=29;
		$self->{errorString}='No author line defined';
		$self->warn;
		return undef;
	}

	#parses the address
	my @a=Email::Address->parse($aline);
	if ( ! defined( $a[0] ) ){
		$self->{error}=30;
		$self->{errorString}='The author line "'.$aline.'" could not be parsed';
		$self->warn;
		return undef;
	}

	#process each
	my $int=0;
	my @tojoin;
	while ( defined( $a[$int] ) ){
		my $rendered=$self->{t}->fill_in(
			'authorLink',
			{
				toDir=>$self->{toDir},
				toFiles=>$self->{toFiles},
				obj=>\$self->{obj},
				c=>\$self->{toader}->getConfig,
				toader=>\$self->{toader},
				self=>\$self,
				address=>$a[$int]->address,
				comment=>$a[$int]->comment,
				original=>$a[$int]->original,
				name=>$a[$int]->name,
				g=>\$self,
			}
			);
		if ( $self->{t}->error ){
			$self->{error}=10;
			$self->{errorString}='Failed to fill in the template. error="'.
				$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
			$self->warn;
			return undef;
		}

		push( @tojoin, $rendered );

		$int++;
	}

	#renders the joiner
	my $joiner=$self->{t}->fill_in(
		'authorJoin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the beginning of the authors links
	my $begin=$self->{t}->fill_in(
		'authorBegin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}


	#renders the end of the authors links
	my $end=$self->{t}->fill_in(
		'authorEnd',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $begin.join( $joiner, @tojoin ).$end;
}

=head2 autodocList

This a list of generates a table of the various
documents.

One argument is accepted and the directory under the l<Toader> root
directory. If not specified, it is the same as object used to initate
this object.

    $g->autodocList;

=head3 Templates

=head4 autodocListBegin

This initiates the table for the list.

The default template is as below.

    <table id="autodocList">
      <tr> <td>File</td> </tr>
    

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.
    dir - This is the directory relative to the root L<Toader> directory.

=head4 autodocListRow

This is the represents a row in the document table.

The default template is as below.

      <tr id="autodocList">
        <td id="autodocList">[== $g->adlink( $dir, $file ) ==]</td>
      </tr>

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.
    dir - This is the directory relative to the root L<Toader> directory.
    file - This is the file to show.

=head4 autodocListJoin

This is used to join the table rows.

The default template is blank.

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.
    dir - This is the directory relative to the root L<Toader> directory.

=head4 autodocListEnd

This is ends the documentation list.

The default template is as below.

    </table>

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.
    dir - This is the directory relative to the root L<Toader> directory.

=cut

sub autodocList{
	my $self=$_[0];
	my $dir=$_[1];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	if ( ! defined( $dir ) ){
		$dir=$self->{r2r};
	}

	my $fullpath=$self->{toader}->getRootDir.'/'.$dir;

	my $ad=Toader::AutoDoc->new( $self->{toader} );
	if ( $ad->error ){
		$self->{error}=46;
		$self->{errorString}='Failed to initialize Toader::AutoDoc. error="'.
			$ad->error.'" errorString="'.$ad->errorString.'"';
		$self->warn;
		return undef;
	}

	$ad->dirSet( $fullpath );
	if ( $ad->error ){
		$self->{error}=35;
		$self->{errorString}='Failed to set the directory for the Toader::AutoDoc object to "'.$fullpath.'"';
		$self->warn;
		return undef;
	}

	my @files=$ad->findDocs;
	if ( $ad->error ){
		$self->{error}=36;
		$self->{errorString}='';
		$self->warn;
		return undef;
	}
	@files=sort(@files);
	
	#puts together the list of docs
	my $int=0;
	my @links;
	while ( defined( $files[$int] ) ){
		
		my $rendered=$self->{t}->fill_in(
			'autodocListRow',
			{
				toDir=>$self->{toDir},
				toFiles=>$self->{toFiles},
				obj=>\$self->{obj},
				c=>\$self->{toader}->getConfig,
				toader=>\$self->{toader},
				self=>\$self,
				g=>\$self,
				file=>$files[$int],
				dir=>$dir,
			}
			);
        if ( $self->{t}->error ){
			$self->{error}=10;
			$self->{errorString}='Failed to fill in the template. error="'.
				$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
			$self->warn;
			return undef;
        }
		
		push( @links, $rendered );

		$int++;
	}

	my $begin=$self->{t}->fill_in(
		'autodocListBegin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
			dir=>$dir,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

    my $join=$self->{t}->fill_in(
        'autodocListJoin',
        {
            toDir=>$self->{toDir},
            toFiles=>$self->{toFiles},
            obj=>\$self->{obj},
            c=>\$self->{toader}->getConfig,
            toader=>\$self->{toader},
            self=>\$self,
            g=>\$self,
            dir=>$dir,
        }
        );
    if ( $self->{t}->error ){
        $self->{error}=10;
        $self->{errorString}='Failed to fill in the template. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }

    my $end=$self->{t}->fill_in(
        'autodocListEnd',
        {
            toDir=>$self->{toDir},
            toFiles=>$self->{toFiles},
            obj=>\$self->{obj},
            c=>\$self->{toader}->getConfig,
            toader=>\$self->{toader},
            self=>\$self,
            g=>\$self,
            dir=>$dir,
        }
        );
    if ( $self->{t}->error ){
        $self->{error}=10;
        $self->{errorString}='Failed to fill in the template. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }

	return $begin.join($join, @links).$end;
}

=head2 b2r

This returns the current value to get back to the root.

    my $b2r=$g->b2r;

=cut

sub b2r{
	my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	return $self->{b2r};
}

=head2 cdlink

This generates a link to the current directory.

There is one option arguement. This is the text for the link.
If not specified, it defaults to ".".

    $g->cdlink( "to current directory" );

The template used for this is 'linkDirectory', which by default
is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed to it are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub cdlink{
	my $self=$_[0];
	my $text=$_[1];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#set the text to the same as the link if no text is defined
	if ( ! defined( $text ) ){
		$text='./';
	}

	my $url=$self->{toDir};
	$url=~s/\/\/*/\//g;
	if ( $self->{fullURL} ){
		$url=$self->{url}.$self->{r2r};
	}

	#render it
	my $rendered=$self->{t}->fill_in(
		'linkDirectory',
		{
			url=>$url,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 copyright

This renders the copyright string for at the bottom of a page.

One optional argument is taken, this is a boolean value that if defined
will override the "showCopyright" setting in the config.

The default template is as below.

    <div id="copyright">
     [==
       my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
       $year=$year+1900;
       return "Copyright ".$year." ".$c->{_}->{owner};
      ==]
    </div

The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The being rendered object.
    c - The L<Config::Tiny> object containing the L<Toader> config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub copyright{
	my $self=$_[0];
	my $override=$_[1];

	if ( ! $self->errorblank ){
		return undef;
	}

	#return nothing if override is set to 0
	if (
		defined($override) &&
		($override eq '0')
		){
		return '';
	}

	my $rendered=$self->{t}->fill_in(
		'authorLink',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template "copyright". error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 css

This renders the CSS template and returns it.

    $g->css;

For more information on the CSS template and rendering
please see 'Documentation/CSS.pod'.

=cut

sub css{
	my $self=$_[0];

	if ( ! $self->errorblank ){
		return undef;
	}

	my $renderCSS=Toader::Render::CSS->new( $self->{toader} );

	my $css=$renderCSS->renderCSS;
	if ( $renderCSS->error ){
		$self->{error}=18;
		$self->{errorString}='Failed to render the CSS. error="'.
			$renderCSS->error.'" errorString="'.
			$renderCSS->errorString.'"';
		$self->warn;
		return undef;
	}

	return $css;
}

=head2 cssLocation

This returns the relative location to a the CSS file.

    $g->cssLocation;

=cut

sub cssLocation{
	my $self=$_[0];

	if ( ! $self->errorblank ){
		return undef;
	}

	if ( ! $self->{fullURL} ){
		return $self->{b2r}.'/toader.css';
	}else{
		return $self->{url}.'toader.css';
	}
}

=head2 dlink

This generates a link to a different directory object.

Two arguments are taken.

The first and required one is the L<Toader> directory
to link to. This needs to be relative.

The second is the text, which if not specified will will be the
same the link.

    $g->link( "./foo/bar", "more info on foo/bar" );

The template used for this is 'linkDirectory', which by default
is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed to it are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the L<Toader> config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub dlink{
	my $self=$_[0];
	my $dir=$_[1];
	my $text=$_[2];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#make sure we have a link
	if ( ! defined( $dir ) ){
		$self->{error}=11;
		$self->{errorString}='No Toader directory defined';
		$self->warn;
		return undef;
	}

	#set the text to the same as the link if no text is defined
	if ( ! defined( $text ) ){
		$text=$dir;
	}

	#handles it if it is a full path
	my $dirtest;
	if ( $dir =~ /^\// ){
		$dir=$self->{toader}->getRootDir.$dir;
		$dirtest=$dir;
		$dir=$self->{ph}->relative2root( $dir );
	}else{
		$dirtest=$self->{dir}.'/'.$dir;
	}

	#make sure it is a Toader directory
	if ( ! $self->{isatd}->isaToaderDir( $dirtest ) ){
		$self->{error}=12;
		$self->{errorString}='"'.$dirtest.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	if ( $self->{fullURL} ){
        $dir=$dir;
		$dir=~s/\/\/*/\//g;
		$dir=$self->{url}.$dir;
    }else{
		$dir=$self->{toDir}.$dir;
		$dir=~s/\/\/*/\//g;
    }
	
	#render it
	my $rendered=$self->{t}->fill_in(
		'linkDirectory',
		{
			url=>$dir,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 elink

This generates a link to a different directory object.

Two arguments are taken.

The first and required one is the L<Toader> directory containing
the L<Toader> object. This needs to be relative.

The second is the entry to link to.

The third is the text, which if not specified will will be the
same the link.

    $g->link( $dir, $entryID, "whatever at foo.bar" );

The template used is 'linkEntry' and the default is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the L<Toader> config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub elink{
	my $self=$_[0];
	my $dir=$_[1];
	my $entry=$_[2];
	my $text=$_[3];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#use the object dir if not is specified
	if ( ! defined( $dir ) ){
		$self->{error}=11;
		$self->{errorString}='No Toader directory defined';
		$self->warn;
		return undef;
	}

	#make sure we have a link
	if ( ! defined( $dir ) ){
		$self->{error}=13;
		$self->{errorString}='No Toader Entry ID defined';
		$self->warn;
		return undef;
	}

	#set the text to the same as the link if no text is defined
	if ( ! defined( $text ) ){
		$text=$entry;
	}

	#handles it if it is a full path
	my $dirtest;
	if ( $dir =~ /^\// ){
		$dir=$self->{toader}->getRootDir.$dir;
		$dirtest=$dir;
		$dir=$self->{ph}->relative2root( $dir );
	}else{
		$dirtest=$self->{dir}.'/'.$dir;
	}

	#make sure it is a Toader directory
	if ( ! $self->{isatd}->isaToaderDir( $dirtest ) ){
		$self->{error}=12;
		$self->{errorString}='"'.$dirtest.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	#make sure entry exists... will also make sure it exists
	my $eh=Toader::Entry::Helper->new( $self->{toader} );
	$eh->setDir( $dirtest );
	if ( ! $eh->entryExists( $entry ) ){
		$self->{error}=14;
		$self->{errorString}='The entry ID "'.$entry.'" does not exist for the Toader directory "'.$dirtest.'"';
		$self->warn;
		return undef;
	}

	if ( $self->{fullURL} ){
		$dir=$dir.'/.entries/'.$entry.'/';
		$dir=~s/\/\/*/\//g;
		$dir=$self->{url}.$dir;
	}else{
		$dir=$self->{toDir}.$dir.'/.entries/'.$entry.'/';
		$dir=~s/\/\/*/\//g;
	}

	#render it
	my $rendered=$self->{t}->fill_in(
		'linkEntry',
		{
			url=>$dir,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 entryArchive

This creates the entry archive for the current directory.

No arguments are taken.

    $g->entryArchive;

=head3 Templates

=head4 entryArchiveBegin

This begins the entry archive table.

    <table id="entryArchive">
      <tr> <td>Date</td> <td>Title</td> <td>Summary</td> </tr>

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=head4 entryArchiveRow

This generates a row in the entry archive table.

The default template is as below.

      <tr id="entryArchive">
        <td id="entryArchive">[== $g->elink( "./", $date, $date ) ==]</td>
        <td id="entryArchive">[== $title ==]</td>
        <td id="entryArchive">[== $summary ==]</td>
      </tr>

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.
    date - This is the entry name/date stamp.
    title - This is the title of the entyr.
    summary - This is a summary of the entry.

=head4 entryArchiveJoin

This joins the entry rows.

The default template is blank.

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the L<Toader> config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=head4 entryArchiveEnd

This ends the authors link section.

The default template is as below.

    </table>

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a Toader object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=cut

sub entryArchive{
	my $self=$_[0];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	my $em=Toader::Entry::Manage->new( $self->{toader} );
	$em->setDir( $self->{odir} );
	if ( $em->error ){
		$self->{error}=25;
		$self->{errorString}='Failed to set the directory, "'.$self->{odir}.
			'", for Toader::Entry::Manage. error="'.$em->error
			.'" errorString="'.$em->errorString.'"';
		$self->warn;
		return undef;
	}

	#lists the entries for the directory
	my @entries=$em->published;
	if ( $em->error ){
		$self->{error}=25;
		$self->{errorString}='Failed to read the entries for "'.$self->{odir}.
			'". error="'.$em->error.'" errorString="'.$em->errorString.'"';
		$self->warn;
		return undef;
	}

	#return '' if there are none
	if ( ! defined( $entries[0] ) ){
		return '';
	}

	#sort and order from last to first
	@entries=sort(@entries);
	@entries=reverse(@entries);

	#process each one
	my @tojoin;
	my $int=0;
	while ( defined( $entries[$int] ) ){
		my $entry=$em->read( $entries[$int] );
		if ( $em->error ){
			$self->{error}=26;
			$self->{errorString}='Failed to read "'.$entries[$int].'" in "'
				.$self->{odir}.'". error="'.$em->error.'" errorstring="'
				.$em->errorString.'"';
			$self->warn;
			return undef;
		}

		#renders the row
		my $rendered=$self->{t}->fill_in(
			'entryArchiveRow',
			{
				toDir=>$self->{toDir},
				toFiles=>$self->{toFiles},
				obj=>\$self->{obj},
				c=>\$self->{toader}->getConfig,
				toader=>\$self->{toader},
				self=>\$self,
				title=>$entry->titleGet,
				summary=>$entry->summaryGet,
				date=>$entry->entryNameGet,
				g=>\$self,
			}
			);
		if ( $self->{t}->error ){
			$self->{error}=10;
			$self->{errorString}='Failed to fill in the template. error="'.
				$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
			$self->warn;
			return undef;
		}		
		
		push( @tojoin, $rendered );

		$int++;
	}

	#renders the joiner
	my $joiner=$self->{t}->fill_in(
		'entryArchiveJoin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the end of the dir list
	my $end=$self->{t}->fill_in(
		'entryArchiveEnd',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the end of the dir list
	my $begin=$self->{t}->fill_in(
		'entryArchiveBegin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $begin.join( $joiner, @tojoin ).$end;
}

=head2 entriesArchiveLink

Link to the entries directory.

One argument is taken and that is the text to use.
If not specifieid, it defaults to "Index".

	$g->entriesIndexLink;

The template is 'entriesArchiveLink' and the default is
as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables used are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub entriesArchiveLink{
	my $self=$_[0];
	my $text=$_[1];

	if ( ! defined( $text ) ){
		$text='Archive';
	}

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	my $url;
	if ( $self->{fullURL} ){
		$url=$self->{r2r}.'/.entries/archive.html';
		$url=~s/\/\/*/\//g;
		$url=$self->{url}.$url;
	}else{
		$url=$self->{toDir}.'/.entries/archive.html';
		$url=~s/\/\/*/\//g;
	}

	#render it
	my $rendered=$self->{t}->fill_in(
		'entriesArchiveLink',
		{
			url=>$url,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 entriesLink

Link to the entries directory.

One argument is taken and that is the text to use.
If not specifieid, it defaults to "Latest".

	$g->entriesLink;

The template 'entriesLink' is used and the default is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub entriesLink{
	my $self=$_[0];
	my $text=$_[1];

	if ( ! defined( $text ) ){
		$text='Latest';
	}

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	my $url;
    if ( $self->{fullURL} ){
        $url=$self->{r2r}.'/.entries/';
		$url=~s/\/\/*/\//g;
		$url=$self->{url}.$url;
    }else{
		$url=$self->{toDir}.'/.entries/';
        $url=~s/\/\/*/\//g;
    }

	#render it
	my $rendered=$self->{t}->fill_in(
		'entriesLink',
		{
			url=>$url,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 entryTags

=cut

sub entryTags{

}

=head2 flink

This generates a link to a included file for the object.

Two arguements are taken. The first and required is the file.
The second and optional is the text to use, which if not specified
is the name of the file.

    $g->flink( $file );

The template 'linkFile' is used and the default is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub flink{
	my $self=$_[0];
	my $file=$_[1];
	my $text=$_[2];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#make sure we have a link
	if ( ! defined( $file ) ){
		$self->{error}=17;
		$self->{errorString}='No file specified';
		$self->warn;
		return undef;
	}

	if ( ! defined( $text ) ){
		$text=$file;
	}

	#creates the URL and cleans it up
	my $url=$self->{toFiles}.'/'.$file;
	$url=~s/\/\/*/\//g;

	#render it
	my $rendered=$self->{t}->fill_in(
		'linkFile',
		{
			url=>$self->{toFiles}.'/'.$file,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 galleryDirURL

This returns the URL for a gallery directory.

Three arguments are accepted. The first is the Toader
directory to for the gallery, if not specified it uses
the Toader directory for the current object. The
second is the relative gallery directory, which if not
specified defaults to the '', the root gallery directory.

    [== $g->galleryDirURL ==]

=cut

sub galleryDirURL{
    my $self=$_[0];
    my $dir=$_[1];
    my $gdir=$_[2];
	
    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	if ( ! defined( $gdir ) ){
		$gdir='';
	}
	
	#clean it up, removing any possible multi /
	$gdir=~s/\/\/*/\//g;
	
    #gets the directory to use if none is specified
    if ( ! defined( $dir ) ){
        $dir=$self->{r2r};
    }
	
    #puts together the full path
    my $toaderDir=$self->{toader}->getRootDir.'/'.$dir;
	
	#gets a Gallery object
	my $tg;
	if ( ref( $self->{obj} ) ne 'Toader::Gallery' ){
		$tg=Toader::Gallery->new( $self->{toader} );
		$tg->dirSet( $toaderDir );
		if ( $tg->error ){
			$self->{error}=40;
			$self->{errorString}='Failed to initialize Toader::Gallery';
			$self->warn;
			return undef;
		}
	}else{
		$tg=$self->{obj};
	}

    #gets the output URL
    my $outputURL=$tg->outputURLget;
    if ( ! defined( $outputURL ) ){
        $self->{error}=41;
        $self->{errorString}='Failed to get the output URL for Toader::Gallery for "'.$dir.'"';
        $self->warn;
        return undef;
    }

	my $link='.toader-gallery/html/'.$gdir;
	$link=~s/\/\/*/\//g;
	return $outputURL.$link;
}

=head2 galleryImageLarge

This generates the HTML for a large gallery image.

Two arguments are taken. The first and optional one is the
directory, which if not specified, it uses the Toader current
directory. The second and required is the gallery directory for
the image, which if not specified it defaults to the root
directory, ''. The third and required is the gallery image.

    [== $g->galleryImageLarge( undef, '', $someImage (.

This uses imageDiv with the content provided by imageExifTables.

=cut

sub galleryImageLarge{
	my $self=$_[0];
	my $dir=$_[1];
	my $gdir=$_[2];
	my $image=$_[3];
	
	#blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }
	
    #gets the directory to use if none is specified
    if ( ! defined( $dir ) ){
        $dir=$self->{r2r};
    }

	if ( ! defined( $gdir ) ){
		$gdir='';
	}

	#puts together the full path
	my $toaderDir=$self->{toader}->getRootDir.'/'.$dir;

	#gets a Gallery object
	my $tg;
	if ( ref( $self->{obj} ) ne 'Toader::Gallery' ){
		$tg=Toader::Gallery->new( $self->{toader} );
		$tg->dirSet( $toaderDir );
		if ( $tg->error ){
			$self->{error}=40;
			$self->{errorString}='Failed to initialize Toader::Gallery';
			$self->warn;
			return undef;
		}
	}else{
		$tg=$self->{obj};
	}
	
	#gets the output URL
	my $outputURL=$tg->outputURLget;
	if ( ! defined( $outputURL ) ){
		$self->{error}=41;
		$self->{errorString}='Failed to get the output URL for Toader::Gallery for "'.$dir.'"';
		$self->warn;
		return undef;
	}

	#gets the source path
    my $srcPath=$tg->srcPathGet;
    if ( ! defined( $srcPath ) ){
        $self->{error}=42;
        $self->{errorString}='No source path specified';
        $self->warn;
        return undef;
    }
	
	#puts together the image URL
	my $imageURL='.toader-gallery/large/'.$gdir.'/'.$image;
	$imageURL=~s/\/\/*/\//g;
	$imageURL=$outputURL.$imageURL;
	
	#returns the URL for the source gallery image
	my $srcURL=$self->gallerySrcURL( $dir, $gdir, $image );

	my $imagePath=$srcPath.'/'.$gdir.'/'.$image;
	$imagePath=~s/\/\/*/\//g;

	#puts together the EXIF table
	my $exifTables=$self->imageExifTables( $imagePath );
	if ( $self->error ){
		$self->warnString('imageExifTables failed');
		return undef;
	}

	my $rendered=$self->imageDiv( $imageURL, $srcURL, undef, $exifTables );
	if ( $self->error ){
		$self->warnString('imageDiv failed');
		return undef;
	}
	
	return $rendered;
}

=head2 galleryImageSmall

This generates the HTML for a small gallery image.

Two arguments are taken. The first and optional one is the
directory, which if not specified, it uses the Toader current
directory. The second and required is the gallery directory for
the image. The third and required is the gallery image.

This invokes imageDiv, using the name of the image as the content.

    [== $g->gallerImageSmall( undef, $gdir, $image ); ==]

This uses imageDiv with the link URL being the link to the image details
and the lower text being the image file name.

=cut

sub galleryImageSmall{
	my $self=$_[0];
	my $dir=$_[1];
	my $gdir=$_[2];
	my $image=$_[3];

	#blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	if ( ! defined( $gdir ) ){
		$gdir='';
	}

    #gets the directory to use if none is specified
    if ( ! defined( $dir ) ){
        $dir=$self->{r2r};
    }

	#puts together the full path
	my $toaderDir=$self->{toader}->getRootDir.'/'.$dir;

	#gets a Gallery object
	my $tg;
	if ( ref( $self->{obj} ) ne 'Toader::Gallery' ){
		$tg=Toader::Gallery->new( $self->{toader} );
		$tg->dirSet( $toaderDir );
		if ( $tg->error ){
			$self->{error}=40;
			$self->{errorString}='Failed to initialize Toader::Gallery';
			$self->warn;
			return undef;
		}
	}else{
		$tg=$self->{obj};
	}

	#gets the output URL
	my $outputURL=$tg->outputURLget;
	if ( ! defined( $outputURL ) ){
		$self->{error}=41;
		$self->{errorString}='Failed to get the output URL for Toader::Gallery for "'.$dir.'"';
		$self->warn;
		return undef;
	}

	#puts together the image URL
	my $imageURL='.toader-gallery/small/'.$gdir.'/'.$image;
	$imageURL=~s/\/\/*/\//g;
	$imageURL=$outputURL.$imageURL;

	#returns the URL for the large gallery image
	my $largeURL=$self->galleryLargeURL( $dir, $gdir, $image );

	my $rendered=$self->imageDiv( $imageURL, $largeURL, undef, $image );
	if ( $self->error ){
		$self->warnString('imageDiv failed');
		return undef;
	}

	return $rendered;
}

=head2 galleryLargeURL

This returns the large URL for a directory image.

Three arguments are accepted. The first is the Toader
directory to for the gallery, if not specified it uses
the Toader directory for the current object. The
second is the relative gallery directory, which if not
specified defaults to the '', the root gallery directory.
The third is the image in that directory.

    [== $g->galleryLargeURL; ==]

=cut

sub galleryLargeURL{
    my $self=$_[0];
    my $dir=$_[1];
    my $gdir=$_[2];
	my $image=$_[3];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

    #gets the directory to use if none is specified
    if ( ! defined( $dir ) ){
        $dir=$self->{r2r};
    }

	if ( ! defined( $gdir ) ){
		$gdir='';
	}

	#make sure there no multi /
	$gdir=~s/\/\/*/\//g;

    #puts together the full path
    my $toaderDir=$self->{toader}->getRootDir.'/'.$dir;

	#gets a Gallery object
	my $tg;
	if ( ref( $self->{obj} ) ne 'Toader::Gallery' ){
		$tg=Toader::Gallery->new( $self->{toader} );
		$tg->dirSet( $toaderDir );
		if ( $tg->error ){
			$self->{error}=40;
			$self->{errorString}='Failed to initialize Toader::Gallery';
			$self->warn;
			return undef;
		}
	}else{
		$tg=$self->{obj};
	}

    #gets the output URL
    my $outputURL=$tg->outputURLget;
    if ( ! defined( $outputURL ) ){
        $self->{error}=41;
        $self->{errorString}='Failed to get the output URL for Toader::Gallery for "'.$dir.'"';
        $self->warn;
        return undef;
    }

	my $url='.toader-gallery/html/'.$gdir.'/'.$image.'.html';
	$url=~s/\/\/*/\//g;
	return $outputURL.$url;
}

=head2 galleryLargeImageURL

This returns the URL for the large gallery image.

Three arguments are accepted. The first is the Toader
directory to for the gallery, if not specified it uses
the Toader directory for the current object. The
second is the relative gallery directory, which if not
specified defaults to the '', the root gallery directory.
The third is the image in that directory.

    [== $g->galleryLargeImageURL( undef, $gdir, $image ); ==]

=cut

sub galleryLargeImageURL{
    my $self=$_[0];
    my $dir=$_[1];
    my $gdir=$_[2];
    my $image=$_[3];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

    #gets the directory to use if none is specified
    if ( ! defined( $dir ) ){
        $dir=$self->{r2r};
    }

	if ( ! defined( $gdir ) ){
		$gdir='';
	}

    #puts together the full path
    my $toaderDir=$self->{toader}->getRootDir.'/'.$dir;

	#gets a Gallery object
	my $tg;
	if ( ref( $self->{obj} ) ne 'Toader::Gallery' ){
		$tg=Toader::Gallery->new( $self->{toader} );
		$tg->dirSet( $toaderDir );
		if ( $tg->error ){
			$self->{error}=40;
			$self->{errorString}='Failed to initialize Toader::Gallery';
			$self->warn;
			return undef;
		}
	}else{
		$tg=$self->{obj};
	}

    #gets the output URL
    my $outputURL=$tg->outputURLget;
    if ( ! defined( $outputURL ) ){
        $self->{error}=41;
        $self->{errorString}='Failed to get the output URL for Toader::Gallery for "'.$dir.'"';
        $self->warn;
        return undef;
    }

	my $url='.toader-gallery/large/'.$gdir.'/'.$image;
	$url=~s/\/\/*/\//g;
	return $outputURL.$url;
}

=head2 galleryLocationbar

Two arguments taken for this. The first argument is required and
it is the relative gallery directory, which if not specified
defaults to the '', the root gallery directory. The second and
optional is a image name, if any.

    [== $g->galleryLocationbar; ==]

This is largely useful for setting a locationSub for a gallery
item. See L<Toader::Render::Gallery> for a example of that.

=head3 Templates

=head4 galleryLocationStart

This starts the location bar insert.

The default template is as below.

    <h3>Gallery Location: 

The variables below are passed to it.

    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::General> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    obj - This is the object that Toader was initiated with.

=head4 galleryLocationPart

This is a one of the gallery directories in the path to the one specified.

    <a href="[== $url ==]">[== $text ==]</a>

The variables below are passed to it.

    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::General> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    obj - This is the object that Toader was initiated with.
    gdir - The gallery directory this part is for.
    url - The URL for that gallery directory.
    text - The text(directory name) for that directory.

=head4 galleryLocationJoin

This joins the gallery parts together.

     / 

The variables below are passed to it.

    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::General> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    obj - This is the object that Toader was initiated with.

=head4 galleryLocationEnd

This ends the gallery location bar.

The default template is as below.

    </h3>
    

The variables below are passed to it.

    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::General> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    obj - This is the object that Toader was initiated with.

=head4 galleryLocationImage

This is appended if something is specified for a image.

The default 

    <h3>Image: <a href="[== $url ==]">[== $image ==]</a></h3>

The variables below are passed to it.

    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::General> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    obj - This is the object that Toader was initiated with.
    gdir - The gallery directory this part is for.
    url - The URL for that large(details) image page.
    text - The text(directory name) for that directory.

=cut

sub galleryLocationbar{
	my $self=$_[0];
	my $gdir=$_[1];
	my $image=$_[2];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }
	
	if ( ! defined( $gdir ) ){
		$gdir='';
	}

	#save this for later errors, if needed
	my $gdirOrig=$gdir;

	#makes sure it does not have a ./, which can safely be removed
	$gdir=~s/^\.\///;
	#make sure it does not start with a /, which can safely be removed
	$gdir=~s/^\///;
	#make sure it does not have any multie-/, which can safely be made one
	$gdir=~s/\/\/*/\//g;
	#make sure it does not end in a /, which can safely be removed
	$gdir=~s/\/$//;

	#if we get here and it still has a period, we have an issue
	if ( $gdir=~/^\./ ){
		$self->{error}=44;
		$self->{errorString}='"'.$gdirOrig.'" can not be used as a relative gallery directory as it starts with a period';
		$self->warn;
		return undef;
	}

	#splits the gdir apart
	my @gdirSplit=split( /\//, $gdir);

	#gets a Gallery object
	my $tg;
	if ( ref( $self->{obj} ) ne 'Toader::Gallery' ){
		$tg=Toader::Gallery->new( $self->{toader} );
		$tg->dirSet( $self->{dir} );
		if ( $tg->error ){
			$self->{error}=40;
			$self->{errorString}='Failed to initialize Toader::Gallery';
			$self->warn;
			return undef;
		}
	}else{
		$tg=$self->{obj};
	}

    #renders the gallery link
    my $start=$self->{t}->fill_in(
        'galleryLocationStart',
        {
            obj=>\$self->{obj},
            c=>\$self->{toader}->getConfig,
            toader=>\$self->{toader},
            self=>\$self,
            g=>\$self,
			gdir=>$gdir,
        }
        );
    if ( $self->{t}->error ){
        $self->{error}=10;
        $self->{errorString}='Failed to fill in the template. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }

    #renders the gallery link
    my $joiner=$self->{t}->fill_in(
        'galleryLocationJoin',
        {
            obj=>\$self->{obj},
            c=>\$self->{toader}->getConfig,
            toader=>\$self->{toader},
            self=>\$self,
            g=>\$self,
			gdir=>$gdir,
        }
        );
    if ( $self->{t}->error ){
        $self->{error}=10;
        $self->{errorString}='Failed to fill in the template. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }

	#the parts that will later be joined
	my @parts;

	#gets the url to use
	my $url=$self->galleryDirURL( undef, undef );
	if ( $self->error ){
		$self->warnString('galleryDirURL errored');
		return undef;
	}

	#renders the gallery link
    my $rendered=$self->{t}->fill_in(
        'galleryLocationPart',
        {
            obj=>\$self->{obj},
            c=>\$self->{toader}->getConfig,
            toader=>\$self->{toader},
            self=>\$self,
            g=>\$self,
            gdir=>$gdir,
			url=>$url,
			text=>'root',
        }
        );
    if ( $self->{t}->error ){
        $self->{error}=10;
        $self->{errorString}='Failed to fill in the template. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }
	push( @parts, $rendered );

	#process each part
	my $int=0;
	my $currentGdir='';
	while( defined( $gdirSplit[$int] ) ){
		#gets the url to use
		$currentGdir=$currentGdir.'/'.$gdirSplit[$int];
		$currentGdir=~s/\/\/*/\//g;
		$currentGdir=~s/^\///;

		my $url=$self->galleryDirURL( undef, $currentGdir );
		if ( $self->error ){
			$self->warnString('galleryDirURL errored');
			return undef;
		}

		#renders the gallery link
		$rendered=$self->{t}->fill_in(
			'galleryLocationPart',
			{
				obj=>\$self->{obj},
				c=>\$self->{toader}->getConfig,
				toader=>\$self->{toader},
				self=>\$self,
				g=>\$self,
				gdir=>$gdir,
				url=>$url,
				text=>$gdirSplit[$int],
			}
			);
		if ( $self->{t}->error ){
			$self->{error}=10;
			$self->{errorString}='Failed to fill in the template. error="'.
				$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
			$self->warn;
			return undef;
		}
		push( @parts, $rendered );
		
		$int++;
	}

	#renders the gallery link
    my $end=$self->{t}->fill_in(
        'galleryLocationEnd',
        {
            obj=>\$self->{obj},
            c=>\$self->{toader}->getConfig,
            toader=>\$self->{toader},
            self=>\$self,
            g=>\$self,
            gdir=>$gdir,
        }
        );
    if ( $self->{t}->error ){
        $self->{error}=10;
        $self->{errorString}='Failed to fill in the template. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }

	#handles a specified image...
	my $imageLine='';
	if ( defined( $image ) ){
        my $url=$self->galleryLargeURL( undef, $gdir, $image );
        if ( $self->error ){
            $self->warnString('galleryDirURL errored');
            return undef;
        }

		#renders the image link
		$imageLine=$self->{t}->fill_in(
			'galleryLocationImage',
			{
				obj=>\$self->{obj},
				c=>\$self->{toader}->getConfig,
				toader=>\$self->{toader},
				self=>\$self,
				g=>\$self,
				gdir=>$gdir,
				image=>$image,
				url=>$url,
			}
			);
		if ( $self->{t}->error ){
			$self->{error}=10;
			$self->{errorString}='Failed to fill in the template. error="'.
				$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
			$self->warn;
			return undef;
		}
		
	}

	return $start.join( $joiner, @parts ).$end.$imageLine;
}

=head2 gallerySmallImageURL

This returns the URL for the small gallery image.

Three arguments are accepted. The first is the Toader
directory to for the gallery, if not specified it uses
the Toader directory for the current object. The
second is the relative gallery directory, which if not
specified defaults to the '', the root gallery directory.
The third is the image in that directory.

    [== $g->gallerySmallImageURL; ==]

=cut

sub gallerySmallImageURL{
    my $self=$_[0];
    my $dir=$_[1];
    my $gdir=$_[2];
    my $image=$_[3];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

    #gets the directory to use if none is specified
    if ( ! defined( $dir ) ){
        $dir=$self->{r2r};
    }

	if ( ! defined( $gdir ) ){
		$gdir='';
	}

    #puts together the full path
    my $toaderDir=$self->{toader}->getRootDir.'/'.$dir;

	#gets a Gallery object
	my $tg;
	if ( ref( $self->{obj} ) ne 'Toader::Gallery' ){
		$tg=Toader::Gallery->new( $self->{toader} ) ;
		$tg->dirSet( $toaderDir );
		if ( $tg->error ){
			$self->{error}=40;
			$self->{errorString}='Failed to initialize Toader::Gallery';
			$self->warn;
			return undef;
		}
	}else{
		$tg=$self->{obj};
	}

    #gets the output URL
    my $outputURL=$tg->outputURLget;
    if ( ! defined( $outputURL ) ){
        $self->{error}=41;
        $self->{errorString}='Failed to get the output URL for Toader::Gallery for "'.$dir.'"';
        $self->warn;
        return undef;
    }

    my $url='.toader-gallery/small/'.$gdir.'/'.$image;
	$url=~s/\/\/*/\//g;
	return $outputURL.$url;
}

=head2 galleryLink

This links to a Toader::Gallery gallery.

There are three optional arguments taken. The first is Toader
directory this is for, if it is not specified, it assumes
it is the current one. The second is the second one is the directory
under it that it should link to, which defaults to the root of it
if none is specified. The third is text of the link, which defaults
to 'Gallery' if not specified.

    [== $g->galleryLink( undef, $gdir, $text ); ==]

The template used is 'linkGallery'. It is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::General> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    obj - This is the object that Toader was initiated with.

=cut

sub galleryLink{
    my $self=$_[0];
	my $dir=$_[1];
	my $gdir=$_[2];
	my $text=$_[3];
	

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	#default to the root if nothing is defined for the directory under the gallery
	if ( ! defined( $gdir ) ){
		$gdir='';
	}

	#sets the default text if needed...
	if ( ! defined( $text ) ){
		$text='Gallery';
	}

	#gets the directory to use if none is specified
	if ( ! defined( $dir ) ){
		$dir=$self->{r2r};
	}

	#turns the relative directory into a full path and clean it up
	$dir=$self->{toader}->getRootDir.'/'.$dir;
	$dir=$self->{ph}->cleanup( $dir );
	if ( $self->{ph}->error ){
		$self->{error}=39;
		$self->{errorString}='Failed to clean up the path for "'.$dir.'"';
		$self->warn;
		return undef;
	}

	#gets a Gallery object
	my $tg;
	if ( ref( $self->{obj} ) ne 'Toader::Gallery' ){
		$tg=Toader::Gallery->new( $self->{toader} );
		$tg->dirSet( $dir );
		if ( $tg->error ){
			$self->{error}=40;
			$self->{errorString}='Failed to initialize Toader::Gallery';
			$self->warn;
			return undef;
		}
	}else{
		$tg=$self->{obj};
	}
	
	#gets the output URL
	my $outputURL=$tg->outputURLget;
	if ( ! defined( $outputURL ) ){
		$self->{error}=41;
		$self->{errorString}='Failed to get the output directory for Toader::Gallery for "'.$dir.'"';
		$self->warn;
		return undef;
	}

	#makes the URL for what is being linked to
	my $link='.toader-gallery/html/'.$gdir;
	$link=~s/\/\/*/\//g;
	$link=$outputURL.$link;

    #renders the gallery link
    my $galleryLink=$self->{t}->fill_in(
        'linkGallery',
        {
            obj=>\$self->{obj},
            c=>\$self->{toader}->getConfig,
            toader=>\$self->{toader},
            self=>\$self,
            g=>\$self,
			url=>$link,
			text=>$text,
        }
        );
    if ( $self->{t}->error ){
        $self->{error}=10;
        $self->{errorString}='Failed to fill in the template. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }

	return $galleryLink;
}

=head2 gallerySrcURL

This returns the URL for the source gallery image.

Three arguments are accepted. The first is the Toader
directory to for the gallery, if not specified it uses
the Toader directory for the current object. The
second is the relative gallery directory, which if not
specified defaults to the '', the root gallery directory.
The third is the image in that directory.

    [== $g->gallerySrcURL( undef, $gdir, $image ); ==]

=cut

sub gallerySrcURL{
    my $self=$_[0];
    my $dir=$_[1];
    my $gdir=$_[2];
    my $image=$_[3];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

    #gets the directory to use if none is specified
    if ( ! defined( $dir ) ){
        $dir=$self->{r2r};
    }

	if ( ! defined( $gdir ) ){
		$gdir='';
	}

    #puts together the full path
    my $toaderDir=$self->{toader}->getRootDir.'/'.$dir;

	#gets a Gallery object
	my $tg;
	if ( ref( $self->{obj} ) ne 'Toader::Gallery' ){
		$tg=Toader::Gallery->new( $self->{toader} );
		$tg->dirSet( $toaderDir );
		if ( $tg->error ){
			$self->{error}=40;
			$self->{errorString}='Failed to initialize Toader::Gallery';
			$self->warn;
			return undef;
		}
	}else{
		$tg=$self->{obj};
	}

    #gets the output URL
    my $srcURL=$tg->srcURLget;
    if ( ! defined( $srcURL ) ){
        $self->{error}=45;
        $self->{errorString}='Failed to get the source URL for Toader::Gallery for "'.$dir.'"';
        $self->warn;
        return undef;
    }

	my $url=$gdir.'/'.$image;
	$url=~s/\/\/*/\//g;
	return $srcURL.$url;
}

=head2 hasDocs

This returns true if the current directory has any
documentation.

    if ( $g->hasDocs ){
        print "This directory has documentation...";
    }

=cut

sub hasDocs{
    my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

    #returns true if there is a autodoc directory for the current Toader directory
    if ( -d $self->{odir}.'/.toader/autodoc/' ){
        return 1;
    }

    return 0;
}

=head2 hasEntries

Check if a entries directory exists for the
Toader directory for the current object.

A boolean value is returned.

    my $hasEntries=$g->hasEntries;

=cut

sub hasEntries{
	my $self=$_[0];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#returns true if there is a entries directory for the current Toader directory
	if ( -d $self->{odir}.'/.toader/entries/' ){
		return 1;
	}

	return 0;
}

=head2 hasGallery

This returns true if the current Toader directory has a gallery.

This is checked for by seeing if the gallery config exists.

=cut

sub hasGallery{
    my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

    #returns true if there is a autodoc directory for the current Toader directory
    if ( -f $self->{odir}.'/.toader/gallery.ini' ){
        return 1;
    }

	return 0;
}

=head2 hasAnyDirs

This returns true if there are either Toader sub directories or
it is not at root.

    if ( $g->hasAnyDirs ){
        print "Either not at root or there are Toader sub directires...";
    }

=cut

sub hasAnyDirs{
    my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	my $subs=$self->hasSubDirs;
	if ( $self->error ){
		$self->warnString('Failed to check if the directory has any Toader sub directories');
		return undef;
	}

	#return 1 as there are directories
	if ( $subs ){
		return 1;
	}

	#if we are at root and there no Toader sub directories then this is the only Toader directory
	if ( $self->atRoot ){
		return 0;
	}

	#we are not at root then there is a directory that can be go gone to
	return 1;
}

=head2 hashToTable

This renders a hash to a table.

Four arguments are taken. The first and required a hash
reference to operate on. The second and optional is the title
to use for the key column. The third and optional is the title
to use for the value column. The fourth and optional is the
CSS ID to use, which defaults to to "hashToTable".

    my $table=$foo->hashToTable( \%hash );

=head3 Templates

=head4 hashToTableBegin

This begins the table.

The default is as below.

    <table id="[== $cssID ==]">
    

The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.
    cssID - The CSS ID to use.

=head4 hashToTableTitle

This is a row that acts as the title row at the top of the table.

It is only rendered if a title is defined for either key or value.

The default is as below.

      <tr id="[== $cssID ==]">
        <td id="[== $cssID ==]"><bold>[== $keyTitle ==]</td>
        <td id="[== $cssID ==]"><bold>[== $valueTitle ==]</bold></td>
      </tr>
    

The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.
    cssID - The CSS ID to use.
    keyTitle - The title to use for the key column.
    valueTitle - The title to use for th value column.

=head4 hashToTableRow

This represents a row containing a key/value pair.

The default is as below.

      <tr id="[== $cssID ==]">
        <td id="[== $cssID ==]"><bold>[== $key ==]</td>
        <td id="[== $cssID ==]"><bold>[== $value ==]</bold></td>
      </tr>


The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.
    cssID - The CSS ID to use.
    key - The key for the row.
    value - The value for the row.

=head4 hashToTableJoin

This joins together the rendered rows.

The default is as below.

    

The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.
    cssID - The CSS ID to use.

=head4 hashToTableEnd

This ends the table.

The default is as below.

    </table>

The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.
    cssID - The CSS ID to use.

=cut

sub hashToTable{
	my $self=$_[0];
	my $hash=$_[1];
	my $keyTitle=$_[2];
	my $valueTitle=$_[3];
	my $cssID=$_[4];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	#sets the default CSS ID if none is given
	if( !defined( $cssID ) ){
		$cssID='hashToTable';
	}

	#checks if it has a column title bar for either
	my $titleRow='';
	my $renderTitleRow=0;
	if ( 
		defined( $keyTitle ) ||
		defined( $valueTitle )
		){
		if ( ! defined( $keyTitle ) ){
			$keyTitle='';
		}
		if ( ! defined( $valueTitle ) ){
			$valueTitle='';
		}
		$renderTitleRow=1;
	}

	#renders the title row if needed...
	if ( $renderTitleRow ){
		$titleRow=$self->{t}->fill_in(
			'hashToTableTitle',
			{
				toDir=>$self->{toDir},
				toFiles=>$self->{toFiles},
				obj=>\$self->{obj},
				c=>\$self->{toader}->getConfig,
				toader=>\$self->{toader},
				self=>\$self,
				g=>\$self,
				cssID=>$cssID,
				keyTitle=>$keyTitle,
				valueTitle=>$valueTitle,
			}
			);
        if ( $self->{t}->error ){
			$self->{error}=10;
			$self->{errorString}='Failed to fill in the template. error="'.
				$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
			$self->warn;
			return undef;
        }
	}

	#renders the top of the table
	my $begin=$self->{t}->fill_in(
            'hashToTableBegin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
			cssID=>$cssID,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

    #renders the bottom of the table
    my $end=$self->{t}->fill_in(
            'hashToTableEnd',
        {
            toDir=>$self->{toDir},
            toFiles=>$self->{toFiles},
            obj=>\$self->{obj},
            c=>\$self->{toader}->getConfig,
            toader=>\$self->{toader},
            self=>\$self,
            g=>\$self,
            cssID=>$cssID,
        }
        );
    if ( $self->{t}->error ){
        $self->{error}=10;
        $self->{errorString}='Failed to fill in the template. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }
	
    #renders the row joiner
    my $join=$self->{t}->fill_in(
		'hashToTableJoin',
        {
            toDir=>$self->{toDir},
            toFiles=>$self->{toFiles},
            obj=>\$self->{obj},
            c=>\$self->{toader}->getConfig,
            toader=>\$self->{toader},
            self=>\$self,
            g=>\$self,
            cssID=>$cssID,
        }
        );
    if ( $self->{t}->error ){
        $self->{error}=10;
        $self->{errorString}='Failed to fill in the template. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }

	#renders each row
	my @keys=sort {uc($a) cmp uc($b)} keys( %$hash );
	my @rows;
	my $int=0;
	while( defined( $keys[$int] ) ){
		my $row=$self->{t}->fill_in(
			'hashToTableRow',
			{
				toDir=>$self->{toDir},
				toFiles=>$self->{toFiles},
				obj=>\$self->{obj},
				c=>\$self->{toader}->getConfig,
				toader=>\$self->{toader},
				self=>\$self,
				g=>\$self,
				cssID=>$cssID,
				key=>$keys[$int],
				value=>$hash->{$keys[$int]},
			}
			);
		if ( $self->{t}->error ){
			$self->{error}=10;
			$self->{errorString}='Failed to fill in the template. error="'.
				$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
			$self->warn;
			return undef;
		}
		push( @rows, $row );

		$int++;
	}

	return $begin.$titleRow.join( $join, @rows ).$end;
}

=head2 hasSubDirs

This returns to true if the current object
directory has any Toader sub directories.

    if ( $g->hasSubDirs ){
        print "This directory has sub directories.";
    }

=cut

sub hasSubDirs{
    my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

    #gets a list of directories
	my @dirs;
	if ( ref( $self->{odir} ) eq 'Toader::Directory' ){
		@dirs=$self->{odir}->listSubToaderDirs;
		if ( $self->{odir}->error ){
			$self->{error}=22;
			$self->{errorString}='Failed to get a list of Toader sub directories. error="'
				.$self->{odir}->error.'" errorString="'.$self->{odir}->errorString.'"';
			return undef;
		}
	}else{
		my $dobj=Toader::Directory->new( $self->{toader} );
		$dobj->dirSet( $self->{odir} );
		@dirs=$dobj->listSubToaderDirs;
		if ( $dobj->error ){
			$self->{error}=22;
			$self->{errorString}='Failed to get a list of Toader sub directories. error="'
				.$dobj->error.'" errorString="'.$dobj->{odir}->errorString.'"';
			return undef;
		}
	}

	if ( defined( $dirs[0] ) ){
		return 1;
	}
	
	return 0;
}

=head2 imageDiv

This can be used for creating a captioned image.

The takes five arguments. The first and required is the URL
for the image. Second and optional is link to use for if the image
is clicked on, which if not defined, the image will not be setup
as a link. The third and optional is a caption to show above the
image, which if left undefined defaults to ''. The fourth and
optional is a caption to show below the image, which if left
undefined defaults to ''. The fifth is the CSS ID to use,
which if not defined defaults to 'imageDiv'. The sixth and
optional is the alt test to use, which if not specified defaults
to the provided image URL..

    $g-imageDiv( $imageURL, $imageLink, , 'some caption below it');

The default template, 'imageDiv' is as below.

    <div id='$cssID'>
      [== $above ==]
      [== if ( defined( $link ) ){ return '    <a href="'.$link.'"'> }else{ return '' } ==]
      <img src="[== $image ==]" alt="[== $alt ==]"/>
      [== if ( defined( $link ) ){ return '    </a>' }else{ return '' } ==]<br>
      [== $below ==]
    </div>

The variables passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::General> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    obj - This is the object that Toader was initiated with.
    image - This is the source URL to usse.
    above - This is the caption above the image.
    below - This is the caption below the image.
    link - This is a optional link to link to if the image is clicked on.
    alt - This is the alt text for the image.

=cut

sub imageDiv{
    my $self=$_[0];
	my $imageURL=$_[1];
	my $imageLink=$_[2];
	my $above=$_[3];
	my $below=$_[4];
	my $cssID=$_[5];
	my $alt=$_[6];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	#error if we have no URL for the image
	if ( ! defined( $imageURL ) ){
		$self->{error}=36;
		$self->{errorString}='No URL specified for the image';
		$self->warn;
		return undef;
	}

	#sets the default value for above if none is given
	if ( ! defined( $above ) ){
		$above='';
	}

	#sets the default value for below if none is given
	if ( ! defined( $below ) ){
		$below='';
	}

	#sets the default CSS ID if none is specified
	if ( ! defined( $cssID ) ){
		$cssID='imageDiv';
	}

	#sets alt to the URL if not specified
	if ( ! defined( $alt ) ){
		$alt=$imageURL;
	}

	my $rendered=$self->{t}->fill_in(
            'imageDiv',
            {
                toDir=>$self->{toDir},
                toFiles=>$self->{toFiles},
                obj=>\$self->{obj},
                c=>\$self->{toader}->getConfig,
                toader=>\$self->{toader},
                self=>\$self,
                g=>\$self,
                cssID=>$cssID,
				image=>$imageURL,
				above=>$above,
				below=>$below,
				alt=>$alt,
				link=>$imageLink,
            }
		);
        if ( $self->{t}->error ){
            $self->{error}=10;
            $self->{errorString}='Failed to fill in the template. error="'.
                $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
            $self->warn;
            return undef;
        }
	
	return $rendered;
}

=head2 imageExifTables

This returns the table of the tags for a image.

This puts together a tables of the common EXIF tag groups.

    [== $g->imageExifTables( $image ); ==]

this methode ignores the EXIF tables listed below.

    ExifTool
    System
    PrintIM
    File
    Printing
    Copy1

=head3 Templates

=head4 imageExifTables

This begins it.

The default template is as below.

    <b>Image: </b> [== $filename ==] <br/>
    [== $tables ==]
    

The variables passed are as below.

    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::General> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    obj - This is the object that Toader was initiated with.
    filename - This is the name of the image file.
    tables - This is the rendered tables from generated by the templates below.

=head3 imageExifTablesBegin

This begins the prefixes joining of the tables.

The default template is blank.

The variables passed are as below.

    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::General> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    obj - This is the object that Toader was initiated with.

=head3 imageExifTablesGroup

This is a EXIF tag group.

The default table is as below.

    <br />
    <b>EXIF Tag Group: [== $group ==]</b>
    [== $table ==]
    <br />
    
The variables passed are as below.

    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::General> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    obj - This is the object that Toader was initiated with.
    group - This is the EXIF tag group.
    table - This is the generated by hash2table.

=head3 imageExifTablesJoin

This joins the text rendered for imageExifTablesGroup

The default template is blank.

The variables passed are as below.

    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::General> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    obj - This is the object that Toader was initiated with.

=head3 imageExifTablesEnd

This ends the prefixes joining of the tables.

The default template is blank.

The variables passed are as below.

    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::General> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    obj - This is the object that Toader was initiated with.

=cut

sub imageExifTables{
	my $self=$_[0];
	my $image=$_[1];
	
    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }
	
	if ( ! defined( $image ) ){
		$self->{error}=37;
		$self->{errorString}='No image file specified';
		$self->warn;
		return undef;
	}

	if ( ! -f $image ){
		$self->{error}=38;
		$self->{errorString}='The specified image, "'.$image.'", does not exist';
		$self->warn;
		return undef;
	}

	my $filename=$image;
	$filename=~s/.*\///;

	my $et=Image::ExifTool->new;
	$et->ExtractInfo( $image );

	my @foundTags=$et->GetFoundTags;
	
	my %tags;
	
	my $int=0;
	while( defined( $foundTags[$int] ) ){
        my $value=$et->GetValue( $foundTags[$int] );
        
        if (ref $value eq 'SCALAR') {
			$value='(unprintable value)'
        }
        
        my @groups=$et->GetGroup( $foundTags[$int] );
        
        my $int2=0;
        while( defined( $groups[$int2] ) ){
			if ( $groups[$int2] eq "" ){
				$groups[$int2]='""';
			}
			
			if ( ( $groups[$int2] ne 'ExifTool' ) &&
				 ( $groups[$int2] ne 'System' ) &&
				 ( $groups[$int2] ne 'PrintIM' ) &&
				 ( $groups[$int2] ne 'File' ) &&
				 ( $groups[$int2] ne 'Printing' ) &&
				 ( $groups[$int2] ne 'Copy1' )
				){
				if ( ! defined( $tags{ $groups[$int2] } ) ){
					$tags{ $groups[$int2] }={};
				}
				
				$tags{ $groups[$int2] }{ $foundTags[$int] }=$value;
			}
			
			$int2++;
        }

        $int++;
	}

	my @groups=sort( keys( %tags ) );

	my @renderedGroups;

	#puts together the Composite table if needed
	$int=0;
	while ( defined( $groups[$int] ) ){
		my $table=$self->hashToTable( $tags{ $groups[$int] } );
		if ( $self->error ){
           $self->warnString('Failed to convert the hash to a table for "'.$groups[$int].'"');
            return undef;
        }
        #renders the table
        my $rendered=$self->{t}->fill_in(
            'imageExifTablesGroup',
            {
                obj=>\$self->{obj},
                c=>\$self->{toader}->getConfig,
                toader=>\$self->{toader},
                self=>\$self,
                table=>$table,
				group=>$groups[$int],
            }
            );
        if ( $self->{t}->error ){
            $self->{error}=10;
            $self->{errorString}='Failed to fill in the template. error="'.
                $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
            $self->warn;
            return undef;
        }
		push( @renderedGroups, $rendered );
		
		$int++;
	}

	#renders the table joiner
	my $begin=$self->{t}->fill_in(
		'imageExifTablesBegin',
		{
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the table joiner
	my $join=$self->{t}->fill_in(
		'imageExifTablesJoin',
		{
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the table joiner
	my $end=$self->{t}->fill_in(
		'imageExifTablesEnd',
		{
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	my $joinedtables=$begin.join('', @renderedGroups ).$end;

	#renders the tables together
    my $rendered=$self->{t}->fill_in(
        'imageExifTables',
        {
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			tables=>$joinedtables,
			filename=>$filename,
        }
        );
    if ( $self->{t}->error ){
        $self->{error}=10;
        $self->{errorString}='Failed to fill in the template. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }

	return $rendered;
}

=head2 lastEntries

This returns the last entries, post rendering each one and joining them.

There is one optional and that is number of last entries to show. If
not specified, it shows the last 15.

    $g->lastEntries;

=head3 Templates

=head4 entryListBegin

This begins the list of the last entries.

The default template is blank.

The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=head4 entryListJoin

This joins the rendered entries.

The default template is as below.

    <br>
    

The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=head4 entryListEnd

This ends the list of rendered entries.

The default template is as below.

    <br>


The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=cut

sub lastEntries{
	my $self=$_[0];
	my $show=$_[1];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#default to 15 to show
	if ( ! defined( $show ) ){
		$show=15;
	}
	
	my $em=Toader::Entry::Manage->new( $self->{toader} );
	$em->setDir( $self->{odir} );
	if ( $em->error ){
		$self->{error}=25;
		$self->{errorString}='Failed to set the directory, "'.$self->{odir}.
			'", for Toader::Entry::Manage. error="'.$em->error
			.'" errorString="'.$em->errorString.'"';
		$self->warn;
		return undef;
	}

	#lists the entries for the directory
	my @entries=$em->list;
	if ( $em->error ){
		$self->{error}=25;
		$self->{errorString}='Failed to read the entries for "'.$self->{odir}.
			'". error="'.$em->error.'" errorString="'.$em->errorString.'"';
		$self->warn;
		return undef;
	}

	#return '' if there are none
	if ( ! defined( $entries[0] ) ){
		return '';
	}

	#sort and order from last to first
	@entries=sort(@entries);
	@entries=reverse(@entries);

	#process each one
	my @tojoin;
	my $int=0;
	while ( defined( $entries[$int] ) ){
		my $entry=$em->read( $entries[$int] );
		if ( $em->error ){
			$self->{error}=26;
			$self->{errorString}='Failed to read "'.$entries[$int].'" in "'
				.$self->{odir}.'". error="'.$em->error.'" errorstring="'
				.$em->errorString.'"';
			$self->warn;
			return undef;
		}

		my $r=Toader::Render::Entry->new({
			obj=>$entry,
			toader=>$self->{toader},
			toDir=>$self->{toDir},
			});
		if ( $r->error ){
			$self->{error}=27;
			$self->{errorString}='Failed to initialize Toader::Render::Entry for "'.
				$entries[$int].'" in "'.$self->{odir}.'". error="'.$r->error.
				'" errorString="'.$r->errorString.'"';
			$self->warn;
			return undef;
		}

		my $rendered=$r->content;
		if ( $r->error ){
			$self->{error}=28;
			$self->{errorString}='Failed to render "'.$entries[$int].'" in "'
				.$self->{odir}.'". error="'.$r->error.'" errorString="'.$r->errorString.'"';
			$self->warn;
			return undef;
		}

		push( @tojoin, $rendered );

		$int++;
	}

	#renders the joiner
	my $joiner=$self->{t}->fill_in(
		'entryListJoin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the begining of the end of the last entries
	my $begin=$self->{t}->fill_in(
		'entryListBegin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the end of the end of the last entries
	my $end=$self->{t}->fill_in(
		'entryListEnd',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}


	return $begin.join( $joiner, @tojoin ).$end;
}

=head2 link

This generates a HTML link.

Two arguments are taken. The first and required one is the link.
The second is the text, which if not specified will will be the same
the link.

    $g->link( "http://foo.bar/whatever/", "whatever at foo.bar" );

The template used is 'link' and by default it is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub link{
	my $self=$_[0];
	my $link=$_[1];
	my $text=$_[2];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#make sure we have a link
	if ( ! defined( $link ) ){
		$self->{error}=8;
		$self->{errorString}='No link defined';
		$self->warn;
		return undef;
	}

	#set the text to the same as the link if no text is defined
	if ( ! defined( $text ) ){
		$text=$link;
	}

	#render it
	my $rendered=$self->{t}->fill_in(
		'link',
		{
			url=>$link,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			self=>\$self,
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 listDirs

This builds the side bar list of directories.

No options are taken.

    $g->listDirs;

This does not currently play nicely with any thing that will
set fullURL.

=head3 Templates

=head4 dirListBegin

This begins the dirlist.

The template used is 'dirListBegin' and by default is blank.

The variables passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 dirListJoin

This joins items in the directory list.

The default template is 'dirListJoin' and it is as below.

    <br> 
    

The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 dirListLink

This is a link for a directory in the directory list.

The template is 'dirListLink' and it is by default as below.

    <a href="[== $url ==]">[== $text ==]</a>

The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry>> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 dirListEnd

This ends the directory list.

The template used is 'dirListEnd' and the default is as below.

    <br> 
    

The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub listDirs{
    my $self=$_[0];
	
    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	#renders the joiner
	my $joiner=$self->{t}->fill_in(
		'dirListJoin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the beginning of the dir list
	my $begin=$self->{t}->fill_in(
		'dirListBegin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the end of the dir list
	my $end=$self->{t}->fill_in(
		'dirListEnd',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#gets a list of directories
	my @dirs;
	if ( ref( $self->{odir} ) eq 'Toader::Directory' ){
		@dirs=$self->{odir}->listSubToaderDirs;
		if ( $self->{odir}->error ){
			$self->{error}=22;
			$self->{errorString}='Failed to get a list of Toader sub directories. error="'
				.$self->{odir}->error.'" errorString="'.$self->{odir}->errorString.'"';
			return undef;
		}
	}else{
		my $dobj=Toader::Directory->new( $self->{toader} );
		$dobj->dirSet( $self->{odir} );
		@dirs=$dobj->listSubToaderDirs;
		if ( $dobj->error ){
			$self->{error}=22;
			$self->{errorString}='Failed to get a list of Toader sub directories. error="'
				.$dobj->error.'" errorString="'.$dobj->{odir}->errorString.'"';
			return undef;
		}
	}
	@dirs=sort(@dirs);

	#return black here if there is nothing
	if ( ! defined( $dirs[0] ) ){
		return '';
	}

	#will hold it all prior to joining
	my @tojoin;

	#process it all
	my $int=0;
	while ( defined( $dirs[$int] ) ){
		#add the toDir to it
		my $dir=$self->{toDir}.$dirs[$int];
		$dir=~s/\/\/*/\//g;
	
		#render it
		my $rendered=$self->{t}->fill_in(
			'dirListLink',
			{
				url=>$dir,
				text=>$dirs[$int],
				toDir=>$self->{toDir},
				toFiles=>$self->{toFiles},
				obj=>\$self->{obj},
				c=>\$self->{toader}->getConfig,
				self=>\$self,
				toader=>\$self->{toader},
				g=>\$self,
			}
			);
		if ( $self->{t}->error ){
			$self->{error}=10;
			$self->{errorString}='Failed to fill in the template. error="'.
				$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
			$self->warn;
			return undef;
		}

		push( @tojoin, $rendered );

		$int++;
	}

	return $begin.join( $joiner, @tojoin ).$end;
}

=head2 listPages

This returns returns a list of pages.

No options are taken.

    $g->listPages;

=head3 Templates

=head4 pageListBegin

This begins the page list.

The template is 'pageListBegin' and is blank.

The variables passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 pageListJoin

This joins the items in the page list.

The template is 'pageListJoin' and is blank.

    <br>
    

The variables passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 pageListLink

This is a link to a page

The template is 'pageListLink' and is blank.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 pageListEnd

This joins the items in the page list.

The template is 'pageListJoin' and is blank.

    <br>
    

The variables passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub listPages{
	my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	#renders the begin
	my $begin=$self->{t}->fill_in(
		'pageListBegin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the joiner
	my $joiner=$self->{t}->fill_in(
		'pageListJoin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the end of the dir list
	my $end=$self->{t}->fill_in(
		'pageListEnd',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#gets a list of pages
	my $pm=Toader::Page::Manage->new( $self->{toader} );
	$pm->setDir( $self->{odir} );
	if ( $pm->error ){
		$self->{error}=23;
		$self->{errorString}='Failed to set the directory for Toader::Page::Manage. '.
			'error="'.$pm->error.'" errorString="'.$pm->errorString.'"';
		$self->warn;
		return undef;
	}
	my @pages=$pm->list;
	if ( $pm->error ){
		$self->{error}=24;
		$self->{errorString}='Failed to get a list of pages. error="'
			.$pm->error.'" errorString="'.$pm->errorString.'"';
		$self->warn;
		return undef;
	}	

	#return blank if there pages
	if ( ! defined( $pages[0] ) ){
		return '';
	}

	#puts it together
	my $int=0;
	my @tojoin;
	while ( $pages[$int] ){
		#add the toDir to it
		my $dir=$self->{toDir}.'/.pages/'.$pages[$int].'/';
		$dir=~s/\/\/*/\//g;
	
		#render it
		my $rendered=$self->{t}->fill_in(
			'pageListLink',
			{
				url=>$dir,
				text=>$pages[$int],
				toDir=>$self->{toDir},
				toFiles=>$self->{toFiles},
				obj=>\$self->{obj},
				c=>\$self->{toader}->getConfig,
				self=>\$self,
				toader=>\$self->{toader},
				g=>\$self,
			}
			);
		if ( $self->{t}->error ){
			$self->{error}=10;
			$self->{errorString}='Failed to fill in the template. error="'.
				$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
			$self->warn;
			return undef;
		}

		push( @tojoin, $rendered );

		$int++;
	}

	return $begin.join( $joiner, @tojoin ).$end;
}

=head2 locationbar

This puts together the the location bar.

One argument is taken and that is what to use for the lcation ID.

    $g->locationbar( $locationID );

=head3 Templates

=head4 locationStart

This starts the location bar.

The template used is 'locationStart' and the default is as below.

    <h2>Location: 

The variabled passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 locationPart

This is a part of the path in the location bar.

The template used is 'locationPart' and the default is as below.

    <a href="[== $url ==]">[== $text ==]</a> / 

The variables passed are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 locationEnd

This is the end of the location bar.

The template used is 'locationEnd' and the default is as below.

    [== $locationID ==]</h2>
    

The variables passed are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    locationID - The string to use for the end location bar.

=cut

sub locationbar{
	my $self=$_[0];
	my $locationID=$_[1];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	my @parts=split( /\//, $self->{r2r} );

	#render it
	my $rendered=$self->{t}->fill_in(
		'locationStart',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			self=>\$self,
			c=>\$self->{toader}->getConfig,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#creates the url and cleans it up
	my $url=$self->{b2r};
	$url=~s/\/\/*/\//g;

	if ( $self->{fullURL} ){
		$url=$self->{url};
	}

	#does the initial link to the root directory
	$rendered=$rendered.$self->{t}->fill_in(
		'locationPart',
		{
			url=>$url,
			text=>'root',
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#processes each item
	my $int=0;
	my $dir=$self->{b2r}.'/';
	while ( defined( $parts[$int] ) ){

		if ( $parts[$int] ne '.' ){
			$dir=$dir.$parts[$int].'/';
			$dir=~s/\/\/*/\//g;
			$rendered=$rendered.$self->{t}->fill_in(
				'locationPart',
				{
					url=>$dir,
					text=>$parts[$int],
					toDir=>$self->{toDir},
					toFiles=>$self->{toFiles},
					obj=>\$self->{obj},
					c=>\$self->{toader}->getConfig,
					self=>\$self,
					toader=>\$self->{toader},
					g=>\$self,
				}
				);
			if ( $self->{t}->error ){
				$self->{error}=10;
				$self->{errorString}='Failed to fill in the template. error="'.
					$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
				$self->warn;
				return undef;
			}
		}

		$int++;
	}

	#gets the location ID
	if( ! defined( $locationID ) ){
		$locationID=$self->{obj}->locationID;
	}


	$rendered=$rendered.$self->{t}->fill_in(
		'locationEnd',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			locationID=>$locationID,
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 locationSubSet

This returns what ever has been set for the location sub via
L<Toader::Render::General>->locationSubSet.

    [== $g->locationSub ==]

=cut

sub locationSub{
    my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

    return $self->{locationSub};
}

=head2 locationSub

This sets the location sub.

One argument is taken and that is what to set it to.

If not defined, '' is used.

    [== $g->locationSubSet( $whatever ) ==]

=cut

sub locationSubSet{
    my $self=$_[0];
	my $locationSub=$_[1];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	if ( ! defined( $locationSub ) ){
		$locationSub='';
	}

    $self->{locationSub}=$locationSub;
	
	return 1;
}

=head2 or2r

This returns the current value to from the root directory
to directory for the object that initialized this instance
of L<Toader::Render::General>.

    my $or2r=$g->or2r;

=cut

sub or2r{
    my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

    return $self->{or2r};
}

=head2 pageSummary

This creates a summary of the pages in the current directory.

No arguments are taken.

    $g->pageSummary;

=head3 Templates

=head4 pageSummaryBegin

The begins the summary of the pages.

The template used is 'pageSummaryBegin' and the default is as below.

    <table id="pageSummary">
      <tr> <td>Name</td> <td>Summary</td> </tr>
    

The variabled passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The Toader::Entry object.
    c - The Config::Tiny object containing the Toader config.
    self - The Toader::Render::Entry object.
    toader - This is a Toader object.
    g - This is a Toader::Render::General object.

=head4 pageSummaryJoin

This joins the rows.

The template used is 'pageSummaryJoin' and by default is blank.

The variabled passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 pageSummarySummary

This is a row in the table of pages.

The template used is 'pageSummarySummary' and by default is as below.

      <tr id="pageSummary">
        <td id="pageSummary"><a href="./[== $name ==]/">[== $name ==]</a></td>
        <td id="pageSummary">[== $summary ==]</td>
      </tr>

The variabled passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    name - This is the name of the page.
    summary - This is a summary of the page.

=cut

sub pageSummary{
	my $self=$_[0];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	my $pm=Toader::Page::Manage->new( $self->{toader} );
	$pm->setDir( $self->{odir} );
	if ( $pm->error ){
		$self->{error}=31;
		$self->{errorString}='Failed to set the directory, "'.$self->{odir}.
			'", for Toader::Page::Manage. error="'.$pm->error
			.'" errorString="'.$pm->errorString.'"';
		$self->warn;
		return undef;
	}

	#lists the entries for the directory
	my @pages=$pm->published;
	if ( $pm->error ){
		$self->{error}=32;
		$self->{errorString}='Failed to list the pages for "'.$self->{odir}.
			'". error="'.$pm->error.'" errorString="'.$pm->errorString.'"';
		$self->warn;
		return undef;
	}

	#return '' if there are none
	if ( ! defined( $pages[0] ) ){
		return '';
	}

	#sort and order from last to first
	@pages=sort(@pages);
	@pages=reverse(@pages);

	#process each one
	my @tojoin;
	my $int=0;
	while ( defined( $pages[$int] ) ){
		my $entry=$pm->read( $pages[$int] );
		if ( $pm->error ){
			$self->{error}=33;
			$self->{errorString}='Failed to read "'.$pages[$int].'" in "'
				.$self->{odir}.'". error="'.$pm->error.'" errorstring="'
				.$pm->errorString.'"';
			$self->warn;
			return undef;
		}

		#renders the row
		my $rendered=$self->{t}->fill_in(
			'pageSummaryRow',
			{
				toDir=>$self->{toDir},
				toFiles=>$self->{toFiles},
				obj=>\$self->{obj},
				c=>\$self->{toader}->getConfig,
				toader=>\$self->{toader},
				self=>\$self,
				name=>$entry->nameGet,
				summary=>$entry->summaryGet,
				g=>\$self,
			}
			);
		if ( $self->{t}->error ){
			$self->{error}=10;
			$self->{errorString}='Failed to fill in the template. error="'.
				$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
			$self->warn;
			return undef;
		}		
		
		push( @tojoin, $rendered );

		$int++;
	}

	#renders the joiner
	my $joiner=$self->{t}->fill_in(
		'pageSummaryJoin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the end of the dir list
	my $end=$self->{t}->fill_in(
		'pageSummaryEnd',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the end of the dir list
	my $begin=$self->{t}->fill_in(
		'pageSummaryBegin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $begin.join( $joiner, @tojoin ).$end;
}

=head2 pageSummaryLink

This is a link to summary of the pages for directory of the object.

On argument is accepted and that is the text to use for the link. If
not specified, it defaults to 'Pages'.

    $g->pageSummaryLink;

The template used is 'pageSummaryLink' and the default is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub pageSummaryLink{
	my $self=$_[0];
	my $text=$_[1];

	if ( ! defined( $text ) ){
		$text='Pages';
	}

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	my $url;
	if ( $self->{fullURL} ){
		$url=$self->{r2r}.'/.pages/summary.html';
		$url=~s/\/\/*/\//g;
		$url=$self->{url};
	}else{
		$url=$self->{toDir}.'/.pages/summary.html';
		$url=~s/\/\/*/\//g;
	}

	#render it
	my $rendered=$self->{t}->fill_in(
		'pageSummaryLink',
		{
			url=>$url,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 plink

This generates a link to a different page object.

Two arguments are taken.

The first and required one is the Toader directory containing
the Toader object.

The second is the page to link to.

The third is the text, which if not specified will will be the
same the link.

    $g->plink( $dir, $page, "whatever at foo.bar" );

The template used is 'linkPage' and it is by default as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub plink{
	my $self=$_[0];
	my $dir=$_[1];
	my $page=$_[2];
	my $text=$_[3];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#make sure we have a link
	if ( ! defined( $dir ) ){
		$self->{error}=11;
		$self->{errorString}='No Toader directory defined';
		$self->warn;
		return undef;
	}

	#make sure we have a link
	if ( ! defined( $page ) ){
		$self->{error}=15;
		$self->{errorString}='No Toader page defined';
		$self->warn;
		return undef;
	}

	#set the text to the same as the link if no text is defined
	if ( ! defined( $text ) ){
		$text=$page;
	}

	#handles it if it is a full path
	my $dirtest;
	if ( $dir =~ /^\// ){
		$dir=$self->{toader}->getRootDir.$dir;
		$dirtest=$dir;
		$dir=$self->{ph}->relative2root( $dir );
	}else{
		$dirtest=$self->{dir}.'/'.$dir;
	}

	#make sure it is a Toader directory
	if ( ! $self->{isatd}->isaToaderDir( $dirtest ) ){
		$self->{error}=12;
		$self->{errorString}='"'.$dirtest.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	#make sure entry exists... will also make sure it exists
	my $ph=Toader::Page::Helper->new( $self->{toader} );
	$ph->setDir( $dirtest );
	if ( ! $ph->pageExists( $page ) ){
		$self->{error}=16;
		$self->{errorString}='The Toader page "'.$page.'" does not exist for the Toader directory "'.$dirtest.'"';
		$self->warn;
		return undef;
	}

	if ( $self->{fullURL} ){
		$dir=$dir.'/.pages/'.$page.'/';
		$dir=~s/\/\/*/\//g;
		$dir=$self->{url}.$dir;
	}else{
		$dir=$self->{toDir}.'/'.$dir.'/.pages/'.$page.'/';
		$dir=~s/\/\/*/\//g;
	}

	#render it
	my $rendered=$self->{t}->fill_in(
		'linkPage',
		{
			url=>$dir,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 r2r

This returns the current value to from the root directory
to current directory.

    my $r2r=$g->r2r;

=cut

sub r2r{
    my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

    return $self->{r2r};
}

=head2 rlink

This generates a link to the root directory.

One option arguement is taken. It is the text part of the link.
If not defined it defaults to the relative path to the root
directory.

    $g->rlink("to root");

The template used is 'toRootLink' and is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub rlink{
	my $self=$_[0];
	my $text=$_[1];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	if ( ! defined( $text ) ){
		$text='/';
	}

	#creates the url and cleans it up
	my $url='';
	if ( $self->{fullURL} ){
		$url=$self->{url};
	}else{
		$url=$self->{b2r};
		$url=~s/\/\/*/\//g;
	}

	#render it
	my $rendered=$self->{t}->fill_in(
		'toRootLink',
		{
			url=>$url,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 sidebar

This renders the sidebar for a page.

The template is 'sidebar' and the default is as below.

    [==
      if ( ! $g->hasEntries ){
        return "";
      }
      return "<h3>Entries</h3>\n".
        "		".$g->entriesLink." <br>\n".
        "		".$g->entriesArchiveLink." <br>\n";
    ==]
    [==
      my $pages=$g->listPages;
      if ( ( ! defined( $pages ) ) || ( $pages eq "" ) ){
        return "";
      }
      return "		<hr><h3>".$g->pageSummaryLink."</h3>\n".$pages."\n		<hr>\n";
    ==]
    [==
      if( $g->hasGallery ){
        return "<hr>\n<h3>".$g->galleryLink."</h3>";
      }else{
        return "";
      }
    ==]
    [==
      if( $g->hasAnyDirs ){
          return "<hr>\n<h3>Directories</h3>";
      }else{
        return "";
      }
    ==]
    [== 
      if ( $g->atRoot ){
        return "";
      }
      return $g->rlink("Go To The Root")."		<br>\n		".
        $g->upOneDirLink."		<br>\n		<br>";
    ==]
    
    [== 
      if ( $g->hasSubDirs ){
        return $g->listDirs;
      }
      return "";
    ==]
    [==
      if ( $g->hasDocs ){
        return "<hr>".$g->adListLink;
      }
      return "";
    ==]

The variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub sidebar{
    my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	#render it
	my $rendered=$self->{t}->fill_in(
		'sidebar',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 toDir

This returns the value that was set for toDir.

    my $toDir=>$g->toDir;

=cut

sub toDir{
    my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	return $self->{toDir};
}

=head2 top

This renders the top include.

    $g->top;

The template is 'top' and the default is as below.

    <h1>[== $c->{_}->{site} ==]</h1><br>

The variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub top{
	my $self=$_[0];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	my $dir=$self->{b2r};

	#add the toDir to it
	$dir=$self->{toDir}.$dir;
	
	#render it
	my $rendered=$self->{t}->fill_in(
		'top',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 upOneDirLink

This creates a link up to the next directory.

One argument is taken and that is text to show for the link. If
not specified, it defaults to 'Up One Directory'.

    $g->upOneDirLink;

The template is 'upOneDirLink' and the default is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The passed variables are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub upOneDirLink{
	my $self=$_[0];
	my $text=$_[1];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	if ( ! defined( $text ) ){
		$text='Up One Directory';
	}

	#creates the url and cleans it up
	my $url=$self->{toDir}.'/../';
	$url=~s/\/\/*/\//g;

	#render it
	my $rendered=$self->{t}->fill_in(
		'upOneDirLink',
		{
			url=>$url,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head1 ERROR CODES

=head2 1, noToaderObj

No L<Toader> object defined.

=head2 2, notAtoaderObj

The object specified for the L<Toader> object is not really a
L<Toader> object.

=head2 3, toaderPerror

The specified L<Toader> object has a permanent error set.

=head2 4, noRenderableObj

No object specified for the renderable object.

=head2 5, notArenderableObj

The object specified for the renderable object was not defined.

=head2 6, objPerror

The specified renderable object has a permanent error set.

=head2 7, noDirSet

The renderable object does not have a directory specified.

=head2 8, noLinkDefined

Nothing defined for the link.

=head2 9, templateFetchErrored

Failed to fetch the template.

=head2 11, noToaderDirSpecified

No Toader directory specified.

=head2 12, notAtoaderDir

The specified directory is not a L<Toader> directory.

=head2 13, noEntryIDspecified

No L<Toader::Entry> ID defined.

=head2 14, entryDoesNotExist

The entry does not exist.

=head2 15, noPageSpecified

No L<Toader> page is defined.

=head2 16, pageDoesNotExist

The page does not exist.

=head2 17, noFileSpecified

No file specified.

=head2 18, templateInitErrored

Failed to initialize the L<Toader::Templates> object.

=head2 19, r2rErrored

Failed to figure out the relative from root path.

=head2 20, b2rErrored

Failed to figure out the relative back to root path.

=head2 21, pathhelperInitErrored

Failed to initialize the L<Toader::pathHelper> object.

=head2 22, subToaderDirListErrored

Failed to get a list of L<Toader> sub directories for the
current directory.

=head2 23, pageManageDirSetErrored

Failed to set the directory for L<Toader::Page::Manage>.

=head2 24, listPagesErrored

Failed to get a list of pages.

=head2 25, entryManageErrored

L<Toader::Entry::Manage> could not have it's directory set.

=head2 26, readEntryErrored

Failed to read a entry.

=head2 27, renderEntryInitErrored

Failed to initialize L<Toader::Render::Entry>.

=head2 28, renderEntryErrored

Failed to render a entry.

=head2 29, noAuthorsLineSpecified

No authors line specified.

=head2 30, authorsLineParseFailed

Failed to parse the authors line.

=head2 31, entryManageDirSetErrored

L<Toader::Entry::Manage> could not have it's directory set.

=head2 32, pageListErrored

Failed to list the pages for the directory.

=head2 33, pageReadErrored

Failed to read the page.

=head2 34, autoDocFileDotDotError

The file specified for the AutoDoc link starts with a "../".

=head2 35, noURLinConfig

No URL specified in in the Toader Config.

=head2 36, noImageURLspecified

No URL specified for the image.

=head2 37, noImageFileSpecified

No image file specified.

=head2 38, imageDoesNotExist

The specified image does not exist.

=head2 39, pathCleanupErrored

Path cleanup failed.

=head2 40, galleryInitErrored

Failed to initialize Toader::Gallery.

=head2 41, outputURLnotSpecified

Undefined outputURL for Toader::Gallery.

=head2 42, noSrcPathSpecified

No source path specified for Toader::Gallery.

=head2 43, noURLspecified

No source URL specified for Toader::Gallery.

=head2 44, relativeDirContainsAperiod

The relative gallery directory contains a period.

=head2 45, noSrcURLspecified

No source URL specified for L<Toader::Gallery>.

=head2 46, toaderAutoDocInitErrored

Failed to initialize Toader::AutoDoc.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Render::General

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Toader>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Toader>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Toader>

=item * Search CPAN

L<http://search.cpan.org/dist/Toader/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2013. Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Toader::Render::General
