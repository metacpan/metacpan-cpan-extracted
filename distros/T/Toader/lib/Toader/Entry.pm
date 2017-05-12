package Toader::Entry;

use warnings;
use strict;
use Email::MIME;
use File::MimeInfo;
use Toader::Entry::Helper;
use File::Path qw(make_path);
use base 'Error::Helper';
use Toader::pathHelper;
use Text::Tags::Parser;

=head1 NAME

Toader::Entry - This holds a blog/article/whatever entry.

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

For information on the storage and rendering of entries,
please see 'Documentation/Entry.pod'.

=head1 NEW METHODS

If any of the new methods error, the error is permanent.

=head2 new

This creates the a object that represents a entry.

One argument is taken and it s a hash reference.

=head3 args hash

=head4 renderer

This is the rendering engine the body should use.

If not defined, html will be used.

=head4 body

This is the body.

=head4 title

This is the title of the entry.

=head4 from

This is the from address to use.

=head4 publish

If it should be published or not.

The default value is '1'.

=head4 summary

This is a summary of the entry.

=head4 tags

This is a L<Text::Tags> parsable string for the tags.

=head4 files

This is a list of files that will be made available with this entry.

=head4 toader

This is a L<Toader> object.

    my $foo = Toader::Entry->new(\%args);
    if ($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
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
			  dir=>undef,
			  entryName=>undef,
			  errorExtra=>{
				  flags=>{
					  1=>'noNameSpecified',
					  2=>'emailMIMEerror',
					  3=>'notAnArray',
					  4=>'fileDoesNotExist',
					  5=>'MIMEinfoError',
					  6=>'unableToOpenFile',
					  7=>'emailMIMEerror',
					  8=>'noBody',
					  9=>'invalidEntryName',
					  10=>'notAtoaderDir',
					  11=>'noDirSpecified',
					  12=>'noDirSet',
					  13=>'noLongerAtoaderDir',
					  14=>'noEntryDir',
					  15=>'noSummarySpecified',
					  16=>'noEntryNameSet',
					  17=>'dirDNEorNAD',
					  18=>'noFileSpecified',
					  19=>'publishValError',
					  20=>'getVCSerrored',
					  21=>'VCSusableErrored',
					  22=>'underVCSerrored',
					  23=>'VCSaddErrored',
					  24=>'notAtoaderObj',
					  25=>'noToaderObj',
				  },
			  },
			  VCSusable=>0,
			  };
	bless $self;

	if (!defined($args{renderer})) {
		$args{renderer}='html';
	}

	if (!defined($args{title})) {
		$self->{error}=1;
		$self->{perror}=1;
		$self->{errorString}='No title specified';
		$self->warn;
		return $self;
	}

	if (!defined($args{from})) {
		$self->{error}=9;
		$self->{perror}=1;
		$self->{errorString}='No from specified';
		$self->warn;
		return $self;		
	}

	if (!defined($args{body})) {
		$args{body}='';
	}

	if (!defined($args{publish})) {
		$args{publish}='1';
	}

	#makes sure the publish value is 
	if (
		( $args{publish} ne "0" ) &&
		( $args{publish} ne "1" )
		){
		$self->{perror}=1;
		$self->{error}=19;
		$self->{errorString}='"'.$args{publish}.'" is not a recognized boolean value';
		$self->warn;
		return $self;
	}

	if ( !defined( $args{summary} ) ){
		$args{summary}='';
	}

	#this will hold the various parts
	my @parts;
	my $int=0;
	if (defined($args{files})) {
		if ( ref( $args{files} ne "ARRAY" ) ) {
			$self->{perror}=1;
			$self->{error}=3;
			$self->{errorString}="Has files specified, but the passed object is not a array";
			$self->warn;
			return $self;
		}

		#puts all the parts together
		while (defined( $args{files}[$int] )) {
			if (! -f $args{files}[$int] ) {
				$self->{error}=4;
				$self->{perror}=1;
				$self->{errorString}="'".$args{files}[$int]."' is not a file or does not exist";
				$self->warn;
				return $self;
			}

			#gets the MIME type
			my $mimetype=mimetype( $args{files}[$int] );

			#makes sure it is a mimetype
			if ( !defined( $mimetype ) ) {
				$self->{error}=5;
				$self->{perror}=1;
				$self->{errorString}="'".$args{files}[$int]."' could not be read or does not exist";
				$self->warn;
				return $self;
			}

			#open and read the file
			my $fh;
			if ( ! open( $fh, '<', $args{files}[$int] ) ) {
				$self->{error}=6;
				$self->{perror}=1;
				$self->{errorString}="unable to open '".$args{files}[$int]."'";
				$self->warn;
				return $self;
			}
			my $file=join('',<$fh>);
			close $fh;

			#create a short name for it... removing the path
			my $filename=$args{files}[$int];
			$filename=~s/.*\///g;
			
			my $part=Email::MIME->create(attributes=>{
													  filename=>$filename,
													  content_type=>$mimetype,
													  encode=>"base64",
													  },
										 body=>$file,
										 );

			if (!defined( $part )) {
				$self->{error}=7;
				$self->{perror}=1;
				$self->{errorString}='Unable to create a MIME object for one of the files';
				$self->warn;
				return $self;
			}

			push(@parts, $part);

			$int++;
		}

	}

	#blank the tags value if not defined
	if ( ! defined( $args{tags} ) ){
		$args{tags}='';
	}
	#clean the tag string
	my @tags=Text::Tags::Parser->new->parse_tags( $args{tags} );
	$args{tags}=Text::Tags::Parser->new->join_tags( @tags );
	

	#creates it
	my $mime=Email::MIME->create(
		header=>[
			renderer=>$args{renderer},
			title=>$args{title},
			summary=>$args{summary},
			From=>$args{from},
			publish=>$args{publish},
			tags=>$args{tags},
		],
		body=>$args{body},
		);
	#this sets the parts if needed
	if ( defined( $parts[0] ) ){
		$mime->set_parts( \@parts );
	}
	
	if (!defined($mime)) {
		$self->{error}=2;
		$self->{perror}=1;
		$self->{errorString}='Unable to create Email::MIME object';
		$self->warn;
		return $self;
	}

	$self->{mime}=$mime;

	#if we have a Toader object, reel it in
	if ( ! defined( $args{toader} ) ){
		$self->{perror}=1;
		$self->{error}=25;
		$self->{errorString}='No Toader object specified';
		$self->warn;
		return $self;
	}
	if ( ref( $args{toader} ) ne "Toader" ){
		$self->{perror}=1;
		$self->{error}=24;
		$self->{errorString}='The object specified is a "'.ref($args{toader}).'"';
		$self->warn;
		return $self;
	}
	$self->{toader}=$args{toader};

	#gets the Toader::VCS object
	$self->{vcs}=$self->{toader}->getVCS;
	if ( $self->{toader}->error ){
		$self->{perror}=1;
		$self->{error}=20;
		$self->{errorString}='Toader->getVCS errored. error="'.
			$self->{toader}->error.'" errorString="'.$self->{toader}->errorString.'"';
		$self->warn;
		return $self;
	}
	
	#checks if VCS is usable
	$self->{VCSusable}=$self->{vcs}->usable;
	if ( $self->{vcs}->error ){
		$self->{perror}=1;
		$self->{error}=21;
		$self->{errorString}='Toader::VCS->usable errored. error="'.
			$self->{toader}->error.'" errorString="'.$self->{toader}->errorString.'"';
		$self->warn;
		return $self;
	}

	return $self;
}

=head2 newFromString

This creates a new entry from a string.

Two argument are accepted. The first is the entry string and the second
is a L<Toader> object. 

    my $foo=Toader::Entry->newFromString($entryString, $toader);
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub newFromString{
	my $string=$_[1];
	my $toader=$_[2];

	my $self={
			  error=>undef,
			  errorString=>'',
			  module=>'Toader-Entry',
			  perror=>undef,
			  dir=>undef,
			  entryName=>undef,
			  toader=>undef,
			  errorExtra=>{
				  flags=>{
					  1=>'noNameSpecified',
					  2=>'emailMIMEerror',
					  3=>'notAnArray',
					  4=>'fileDoesNotExist',
					  5=>'MIMEinfoError',
					  6=>'unableToOpenFile',
					  7=>'emailMIMEerror',
					  8=>'noBody',
					  9=>'invalidEntryName',
					  10=>'notAtoaderDir',
					  11=>'noDirSpecified',
					  12=>'noDirSet',
					  13=>'noLongerAtoaderDir',
					  14=>'noEntryDir',
					  15=>'noSummarySpecified',
					  16=>'noEntryNameSet',
					  17=>'dirDNEorNAD',
					  18=>'noFileSpecified',
					  19=>'publishValError',
					  20=>'getVCSfailed',
					  21=>'VCSusableFailed',
					  22=>'underVCSerrored',
					  23=>'VCSaddErrored',
					  24=>'notAtoaderObj',
					  25=>'noToaderObj',
				  },
			  },
			  VCSusable=>0,
			  };
	bless $self;

	#Email::MIME will exit if we pass it a null value
	if (!defined($string)) {
		$self->{error}=8;
		$self->{perror}=1;
		$self->{errorString}='The string is null';
		$self->warn;
		return $self;
	}

	#creates the MIME object
	my $mime=Email::MIME->new($string);
	if (!defined($mime)) {
		$self->{error}=2;
		$self->{perror}=1;
		$self->{errorString}='Unable to create Email::MIME object';
		$self->warn;
		return $self;
	}

	#make sure we have a title
	if (!defined( $mime->header( "title" ) )) {
		$self->{error}=1;
		$self->{perror}=1;
		$self->{errorString}='No title specified';
		$self->warn;
		return $self;
	}

	#make sure we have a from
	if (!defined( $mime->header( "from" ) )) {
		$self->{error}=9;
		$self->{perror}=1;
		$self->{errorString}='No from specified';
		$self->warn;
		return $self;
	}

	#set the summary to blank if one is not specified
	if (!defined( $mime->header( "summary" ) )) {
		$mime->header_set(summary=>'');
	}

	#if there are no tags, make sure it is blank
	if (!defined( $mime->header( "tags" ) )) {
		$mime->header_set(tags=>'');
	}
	#clean the tags
	my @tags=Text::Tags::Parser->new->parse_tags( $mime->header("tags") );
	$mime->header_set( tags=>Text::Tags::Parser->new->join_tags( @tags ) );

	#make sure we have a renderer type
	if (!defined( $mime->header( "renderer" ) )) {
		$mime->header_set(renderer=>'html')
	}

	#make sure we have publish set
	if (!defined( $mime->header( "publish" ) )) {
		$mime->header_set(publish=>'1');
	}

	#makes sure it is a recognized boolean value
	if (
		( $mime->header( "publish" ) ne "0" ) &&
		( $mime->header( "publish" ) ne "1" )
		){
		$self->{perror}=1;
		$self->{error}=19;
		$self->{errorstring}='"'.$mime->header( "publish" ).
			'" is not a recognized boolean value';
		$self->warn;
		return $self;
	}
	
	$self->{mime}=$mime;

	#if we have a Toader object, reel it in
	if ( ! defined( $toader ) ){
		$self->{perror}=1;
		$self->{error}=25;
		$self->{errorString}='No Toader object specified';
		$self->warn;
		return $self;
	}
	if ( ref( $toader ) ne "Toader" ){
		$self->{perror}=1;
		$self->{error}=24;
		$self->{errorString}='The object specified is a "'.ref($toader).'"';
		$self->warn;
		return $self;
	}
	$self->{toader}=$toader;

	#gets the Toader::VCS object
	$self->{vcs}=$self->{toader}->getVCS;
	if ( $toader->error ){
		$self->{perror}=1;
		$self->{error}=20;
		$self->{errorString}='Toader->getVCS errored. error="'.
			$self->{toader}->error.'" errorString="'.$self->{toader}->errorString.'"';
		$self->warn;
		return $self;
	}
	
	#checks if VCS is usable
	$self->{VCSusable}=$self->{vcs}->usable;
	if ( $self->{vcs}->error ){
		$self->{perror}=1;
		$self->{error}=21;
		$self->{errorString}='Toader::VCS->usable errored. error="'.
			$self->{toader}->error.'" errorString="'.$self->{toader}->errorString.'"';
		$self->warn;
		return $self;
	}

	return $self;
}

=head1 GENERAL METHODS

=head2 as_string

This returns the entry as a string.

    my $mimeString=$foo->as_string;
    if($foo->error)
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub as_string{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	return $self->{mime}->as_string;
}

=head2 bodyGet

This gets body.

    my $body=$foo->bodyGet;
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub bodyGet{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	my @parts=$self->{mime}->subparts;
	
	my $int=0;
	while ( defined( $parts[$int] ) ){
		if ( ! defined( $parts[$int]->filename ) ){
			return $parts[$int]->body;
		}

		$int++;
	}

	return $self->{mime}->body;
}

=head2 bodySet

This sets the body.

One argument is required and it is the body.

    $foo->bodySet($body);
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub bodySet{
	my $self=$_[0];
	my $body=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	if (!defined($body)) {
		$self->{error}=8;
		$self->{errorString}='No body defined';
		$self->warn;
		return undef;
	}


	my @parts=$self->{mime}->subparts;
	
	if ( defined( $parts[1] ) ){
		my $int=0;
		while ( defined( $parts[$int] ) ){
			if ( ! defined( $parts[$int]->filename ) ){
				$parts[$int]->body_set($body);
			}

			$int++;
		}

		$self->{mime}->parts_set( \@parts );

		return 1;
	}

	$self->{mime}->body_set($body);

	return 1;
}

=head2 dirGet

This gets L<Toader> directory this entry is associated with.

This will only error if a permanent error is set.

This will return undef if no directory has been set.

    my $dir=$foo->dirGet;
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub dirGet{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	return $self->{dir};
}

=head2 dirSet

This sets L<Toader> directory this entry is associated with.

One argument is taken and it is the L<Toader> directory to set it to.

    my $dir=$foo->dirSet($toaderDirectory);
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub dirSet{
	my $self=$_[0];
	my $dir=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	#make sure a directory has been specified
	if (!defined($dir)) {
		$self->{error}=11;
		$self->{errorString}='No directory specified.';
		$self->warn;
		return undef;
	}

	#cleans up the naming
	my $pathHelper=Toader::pathHelper->new($dir);
	$dir=$pathHelper->cleanup($dir);

	#checks if the directory is Toader directory or not
	my $isatd=Toader::isaToaderDir->new;
    my $returned=$isatd->isaToaderDir($dir);
	if (! $returned ) {
		$self->{error}=10;
		$self->{errorString}='"'.$dir.'" is not a Toader directory.';
		$self->warn;
		return undef;
	}

	$self->{dir}=$dir;

	return 1;
}

=head2 entryNameGet

This gets L<Toader> directory this entry is associated with.

This will only error if a permanent error is set.

This will return undef if no entry name has been set.

    my $entryName=$foo->entryNameGet;
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub entryNameGet{
	my $self=$_[0];

	if (!$self->errorblank){
		$self->warn;
		return undef;
	}

	return $self->{entryName};
}

=head2 entryNameSet

This sets L<Toader> directory this entry is associated with.

One argument is taken and it is the Toader directory to set it to.
If none is specified it will be generated.

    $foo->entryNameSet($entryName);
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub entryNameSet{
	my $self=$_[0];
	my $entryName=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	#generate a entry name if one has not been
	my $ehelper=Toader::Entry::Helper->new( $self->{toader} ) ;
	if (!defined($entryName)) {
		$entryName=$ehelper->generateEntryName;
	}

	#makes sure the entry name is valid
	my $returned=$ehelper->validEntryName($entryName);
	if ( ! $returned ) {
		$self->{error}=9;
		if ( defined( $entryName ) ){
			$self->{errorString}='"'.$entryName.'" is not a valid entry name';
		}else{
			$self->{errorString}='undef is not a valid entry name';
		}
		$self->warn;
		return undef;
	}

	$self->{entryName}=$entryName;

	return 1;
}

=head2 fromGet

This returns the from.

    my $from=$foo->fromGet;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub fromGet{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	return $self->{mime}->header('From');
}

=head2 fromSet

This sets the from.

One argument is taken and it is the name.

    $foo->fromSet($name);
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub fromSet{
	my $self=$_[0];
	my $from=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	if (!defined( $from )) {
		$self->{error}=9;
		$self->{errorString}='No short name specified';
		$self->warn;
		return $self;
	}

	$self->{mime}->header_set('From'=>$from);

	return 1;
}

=head2 publishGet

This returns the publish value.

    my $publish=$foo->publishGet;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub publishGet{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	my $publish=$self->{mime}->header('publish');
	
	#return the default if none is specified
	if ( ! defined( $publish ) ){
		return "1";
	}

	if (
		( $publish ne "0" ) &&
		( $publish ne "1" )
		){
		$self->{error}=19;
		$self->{errorString}='"'.$publish.'" is not a recognized boolean value';
		$self->warn;
		return undef;
	}

	return $publish;
}

=head2 publishSet

This sets the publish value.

One argument is taken and it is the publish value.

    $foo->publishSet($publish);
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub publishSet{
	my $self=$_[0];
	my $publish=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	if (!defined( $publish )) {
		$publish='0';
	}

	if (
		( $publish ne '0' ) &&
		( $publish ne '1' )
		){
		$self->error=19;
		$self->errorString='The publish value is not "0" or "1", but "'.$publish.'"';
		$self->warn;
		return undef;
	}
	

	$self->{mime}->header_set('publish'=>$publish);

	return 1;
}

=head2 summaryGet

This returns the summary.

    my $summary=$foo->summaryGet;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub summaryGet{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	my $summary=$self->{mime}->header('summary');

	if ( ! defined( $summary ) ){
		$summary='';
	}

	return $summary;
}

=head2 summarySet

This sets the summary.

One argument is taken and it is the summary.

    $foo->summarySet($summary);
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub summarySet{
	my $self=$_[0];
	my $summary=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	if (!defined( $summary )) {
		$self->{error}=15;
		$self->{errorString}='No summary specified';
		$self->warn;
		return $self;
	}

	$self->{mime}->header_set('summary'=>$summary);

	return 1;
}

=head2 titleGet

This returns the title.

    my $name=$foo->titleGet;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub titleGet{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	return $self->{mime}->header('title');
}

=head2 titleSet

This sets the title.

One argument is taken and it is the title.

    $foo->titleSet($title);
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub titleSet{
	my $self=$_[0];
	my $title=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	if (!defined( $title )) {
		$self->{error}=1;
		$self->{errorString}='No title specified';
		$self->warn;
		return $self;
	}

	$self->{mime}->header_set('title'=>$title);

	return 1;
}

=head2 rendererGet

This returns the renderer type.

    my $renderer=$foo->rendererGet;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub rendererGet{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	return $self->{mime}->header('renderer');
}

=head2 rendererSet

This sets the renderer type.

One argument is taken and it is the render type.

A value of undef sets it to the default, 'html'.

    my $renderer=$foo->rendererGet;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub rendererSet{
	my $self=$_[0];
	my $renderer=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	if (!defined( $renderer )) {
		$renderer='html';
	}

	$self->{mime}->header_set('renderer'=>$renderer);

	return 1;
}

=head2 subpartsAdd

This adds a new file as a subpart.

One argument is required and it is the path to the file.

    $foo->subpartsAdd( $file );
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub subpartsAdd{
	my $self=$_[0];
	my $file=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	#makes sure a file is specified
	if ( ! defined( $file ) ){
		$self->{error}=18;
		$self->{errorstring}='No file specified';
		$self->warn;
		return undef;
	}

	#makes sure the file exists and is a file
	if ( ! -f $file ){
		$self->{error}=4;
		$self->{errorString}='The file, "'.$file.'", does not exist or is not a file';
		$self->warn;
		return undef;
	}

	#gets the MIME type
	my $mimetype=mimetype( $file );
	
	#makes sure it is a mimetype
	if ( !defined( $mimetype ) ) {
		$self->{error}=5;
		$self->{errorString}="'".$file."' could not be read or does not exist";
		$self->warn;
		return $self;
	}

	#create a short name for it... removing the path
	my $filename=$file;
	$filename=~s/.*\///g;

	#open and read the file
	my $fh;
	if ( ! open( $fh, '<', $file ) ) {
		$self->{error}=6;
		$self->{errorString}="Unable to open '".$file."'";
		$self->warn;
		return undef;
	}
	my $body=join('',<$fh>);
	close $fh;


	#creates the part
	my $part=Email::MIME->create(attributes=>{
		filename=>$filename,
		content_type=>$mimetype,
		encode=>"base64",
								 },
								 body=>$body,
		);
	my @parts;
	push( @parts, $part );
	$self->{mime}->parts_add( \@parts );

	return 1;
}

=head2 subpartsExtract

This extracts the subparts of a entry.

One argument is extracted, it is the directory
to extract the files to.

    $foo->subpartsExtract( $dir );
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub subpartsExtract{
	my $self=$_[0];
	my $dir=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	if ( ! defined( $dir ) ){
		$self->{error}=11;
		$self->{errorString}='No directory specified';
		$self->warn;
		return undef;
	}

	#make sure it exists and is a directory
	if ( ! -d $dir ){
		$self->{error}=17;
		$self->{errorString}='"'.$dir.'" is not a directory or does not exist';
		$self->warn;
		return undef;
	}

	my @subparts=$self->subpartsGet;
	if ( $self->error ){
		$self->warnString('Failed to get the subparts');
		return undef;
	}

	# no subparts to write to the FS
	if ( ! defined( $subparts[0] ) ){
		return 1;
	}

	my $int=0;
	while ( defined( $subparts[$int]  ) ){
		my $file=$subparts[$int]->filename;
		if( defined( $file ) ){
			my $file=$dir.'/'.$file;
			
			my $fh;
			if ( ! open( $fh, '>', $file ) ){
				$self->{error}=18;
				$self->{errorString}='"Failed to open "'.$file.
					'" for writing the body of a subpart out to';
				$self->warn;
				return undef;
			}
			print $fh $subparts[$int]->body;
			close( $fh );
		}

		$int++;
	}

	return 1;
}

=head2 subpartsGet

This returns the results from the subparts
methods from the internal L<Email::MIME> object.

    my @parts=$foo->subpartsGet;
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub subpartsGet{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	return $self->{mime}->subparts;
}

=head2 subpartsList

This returns a list filenames for the subparts.

    my @files=$foo->subpartsList;
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub subpartsList{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	my @subparts=$self->subpartsGet;
	if ( $self->error ){
		$self->warnString('Failed to get the subparts');
		return undef;
	}

	my @files;
	my $int=0;
	while( defined( $subparts[$int] ) ){
		if ( defined( $subparts[$int]->filename ) ){
			push( @files, $subparts[$int]->filename );
		}

		$int++;
	}

	return @files;
}

=head2 subpartsRemove

This removes the specified subpart.

One argument is required and it is the name of the
file to remove.

    $foo->subpartsRemove( $filename );
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub subpartsRemove{
	my $self=$_[0];
	my $file=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	#makes sure a file is specified
	if ( ! defined( $file ) ){
		$self->{error}=18;
		$self->{errorstring}='No file specified';
		$self->warn;
		return undef;
	}

	my @parts=$self->{mime}->parts;
	my @newparts;
	my $int=0;
	while ( defined( $parts[$int] ) ){
		my $partFilename=$parts[$int]->filename;
		if ( ( ! defined( $partFilename ) ) ||
			 ( $file ne $partFilename ) ){
			push( @newparts, $parts[$int] );
		}

		$int++;
	}

	$self->{mime}->parts_set( \@newparts );

	return 1;
}

=head2 tagsGet

Returns a array of tags tags.

The returned value is an array.

    my @tags=$foo->tagsGet;
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub tagsGet{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}
	
	#if there are no tags, make sure it is blank
	if (!defined( $self->{mime}->header( "tags" ) )) {
		$self->{mime}->header_set(tags=>'');
	}
	#clean the tags
	my @tags=Text::Tags::Parser->new->parse_tags( $self->{mime}->header("tags") );

	return @tags;
}

=head2 tagsGetAsString

This returns the tags as a string.

As long as this object has initiated with
out issue, then there is no need to do error
checking for this method.

    my $tagsString=$foo->tagsGetAsString;

=cut

sub tagsGetAsString{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	my $tags=$self->{mime}->header( "tags" );

	if ( ! defined( $tags ) ){
		$tags='';
	}

	return $tags;
}

=head2 tagsSet

This sets the tags.

One value is taken and that is the a array reference.

    $foo->tagsSet( \@tags );
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub tagsSet{
	my $self=$_[0];
	my @tags;
	if ( defined( $_[1] ) ){
		@tags=@{ $_[1] };
	}

	if (!$self->errorblank){
		return undef;
	}

	$self->{mime}->header_set( Text::Tags::Parser->new->join_tags( @tags ) );
	
	return @tags;
}

=head2 tagsSetFromString

This sets the tags.

One value is taken and that is a L<Text::Tags> parsable
string. A value of undef will blank the tags.

    $foo->tagsSetFromString( $tagsString );
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub tagsSetFromString{
	my $self=$_[0];
	my $tagsString=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	if ( ! defined( $tagsString ) ){
		$tagsString='';
	}

	my @tags=Text::Tags::Parser->new->parse_tags( $tagsString );
	$self->{mime}->header_set( tags=>Text::Tags::Parser->new->join_tags( @tags ) );
	
	return @tags;
}

=head2 write

This writes the entry out to a file.

This requires a L<Toader> directory to have been specified.

	$foo->write;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub write{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	#makes so a directory has been specified
	if (!defined( $self->{dir} )) {
		$self->{error}=12;
		$self->{errorString}='No directory has been specified yet';
		$self->warn;
		return undef;
	}

	#makes sure it is still a toader directory...
	if (! -d $self->{dir}.'/.toader/' ) {
		$self->{error}=13;
		$self->{errorString}='No directory has been specified yet';
		$self->warn;
		return undef;		
	}

	#if we don't have a entry title, generate one
	if (!defined( $self->{entryName} )) {
		$self->entryNameSet;
	}

	#if there is no entry directory, generate one...
	if (! -d $self->{dir}.'/.toader/entries/' ) {
		if (! make_path( $self->{dir}.'/.toader/entries/' ) ) {
			$self->{error}=14;
			$self->{errorString}='The entries directory did not exist and was not able to create it';
			$self->warn;
			return undef;
		}
	}

	#the file that will be writen
	my $file=$self->{dir}.'/.toader/entries/'.$self->{entryName};

	#dump the entry to a string
	my $entry=$self->as_string;

	#writes the file
	my $fh;
	if ( ! open($fh, '>', $file) ){
		$self->{error}=15;
		$self->{errorString}='Unable to open "'.$file.'" for writing';
		$self->warn;
		return undef;
	}
	print $fh $entry;
	close($fh);

	#if VCS is not usable, stop here
	if ( ! $self->{VCSusable} ){
		return 1;
	}

	#if it is under VCS, we have nothing to do
	my $underVCS=$self->{vcs}->underVCS($file);
	if ( $self->{vcs}->error ){
		$self->{error}=22;
		$self->{errorString}='Toader::VCS->underVCS errored. error="'.
			$self->{vcs}->error.'" errorString="'.$self->{vcs}->errorString.'"';
		$self->warn;
		return undef;
	}
	if ( $underVCS ){
		return 1;
	}

	#add it as if we reach here it is not under VCS and VCS is being used
	$self->{vcs}->add( $file );
	if ( $self->{vcs}->error ){
		$self->{error}=23;
		$self->{errorString}='Toader::VCS->add errored. error="'.
			$self->{vcs}->error.'" errorString="'.$self->{vcs}->errorString.'"';
		$self->warn;
		return undef;
	}

	return 1;
}

=head1 REQUIRED RENDERING METHODS

=head2 filesDir

This returns the file directory for the object.

This is not a full path, but a partial path that should
be appended the directory current directory being outputted to.

=cut

sub filesDir{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	if ( ! defined( $self->{entryName} ) ){
		$self->{error}=16;
		$self->{errorString}='No entry name has been set';
		$self->warn;
		return undef;
	}

	return $self->renderDir.'/'.$self->{entryName}.'/.files';
}

=head2 locationID

This returns the location ID.

This one requires the object to be initialized.

=cut

sub locationID{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	return 'Entry='.$self->entryNameGet;
}

=head2 renderDir

This is the directory that it will be rendered to.

The base directory that will be used for rendering.

=cut

sub renderDir{
	return '.entries';
}

=head2 renderUsing

This returns the module to use for rendering.

    my $module=$foo->renderUsing;

=cut

sub renderUsing{
    return 'Toader::Render::Entry';
}

=head2 toaderRenderable

This method returns true and marks it as being L<Toader>
renderable.

=cut

sub toaderRenderable{
	return 1;
}

=head2 toDir

This returns the directory that will return the directory
that contains where this object should be rendered to.

This is not a full path, but a partial path that should
be appended the directory current directory being outputted to.

=cut

sub toDir{
    my $self=$_[0];

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $self->{entryName} ) ){
        $self->{error}=16;
        $self->{errorString}='No entry name has been set';
        $self->warn;
        return undef;
    }

    return $self->renderDir.'/'.$self->{entryName};
}


=head1 ERROR CODES

=head2 1, noNameSpecified

No name specified.

=head2 2, emailMIMEerror

Unable to create L<Email::MIME> object.

=head2 3, notAnArray

Has files specified, but the passed object is not a array.

=head2 4, fileDoesNotExist

The file does not exist or is not a file.

=head2 5, MIMEinfoError

File::MimeInfo->mimetype returned undef, meaning the file does not exist or is not readable.

=head2 6, unableToOpenFile

Unable to open the file.

=head2 7, emailMIMEerror

Unable to create a L<Email::MIME> object for one of the parts/files.

=head2 8, noBody

No body defined.

=head2 9, invalidEntryName

Not a valid entry name.

=head2 10. notAtoaderDir

The specified directory is not a Toader directory.

=head2 11, noDirSpecified

No directory specified.

=head2 12, noDirSet

No directory has been set yet.

=head2 13, noLongerAtoaderDir

The directory is no longer a L<Toader> directory. It looks like
it has been removed.

=head2 14, noEntryDir

The entries directory did not exist and was not able to create it.

=head2 15, noSummarySpecified

No summary specified.

=head2 16, noEntryNameSet

No entry name has been set.

=head2 17, dirDNEorNAD

The directory does not exist or is a not a directory.

=head2 18, noFileSpecified

No file specified.

=head2 19, publishValError

Invalid publish value. It is not a recognized boolean value of
either "0" or "1".

=head2 20, getVCSerrored

L<Toader>->getVCS errored.

=head2 21, VCSusableErrored

L<Toader::VCS>->usable errored.

=head2 22, underVCSerrored

L<Toader::VCS>->underVCS errored.

=head2 23, VCSaddErrored

L<Toader::VCS>->add errored.

=head2 24, notAtoaderObj

The specified object is not a L<Toader> object.

=head2 25, noToaderObj

Nothing passed for a L<Toader> object.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Entry


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

Copyright 2013 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Toader
