package Toader::Directory;

use warnings;
use strict;
use base 'Error::Helper';
use Toader::pathHelper;
use Email::MIME;

=head1 NAME

Toader::Directory - This the index file for a Toader directory.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

For information on the storage and rendering of entries,
please see 'Documentation/Directory.pod'.

=head1 METHODS

=head2 new

This initializes the object.

One argument is required and it is a L<Toader> object.

    my $foo = Toader::Directory->new($toader);
    if ($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub new{
	my $toader=$_[1];

	my $self={
			  error=>undef,
			  errorString=>'',
			  perror=>undef,
			  dir=>undef,
			  errorExtra=>{
				  flags=>{
					  1=>'openIndexFailed',
					  2=>'noAtoaderDir',
					  3=>'noTitleSpecified',
					  4=>'noDirSet',
					  5=>'noLongerAtoaderDir',
					  6=>'indexOpenForWritingFailed',
					  7=>'openDirFailed',
					  8=>'noSummarySpecified',
					  9=>'notAtoaderObj',
					  10=>'getVCSerrored',
					  11=>'VCSusableErrored',
					  12=>'underVCSerrored',
					  13=>'VCSaddErrored',
					  14=>'noToaderObj',
				  },
			  },
			  VCSusable=>0,
			  };
	bless $self;

	#if we have a Toader object, reel it in
	if ( ! defined( $toader ) ){
		$self->{perror}=1;
		$self->{error}=14;
		$self->{errorString}='No Toader object specified';
		$self->warn;
		return $self;

	}
	if ( ref( $toader ) ne "Toader" ){
		$self->{perror}=1;
		$self->{error}=9;
		$self->{errorString}='The object specified is a "'.ref($toader).'"';
		$self->warn;
		return $self;
	}
	$self->{toader}=$toader;

	#gets the Toader::VCS object
	$self->{vcs}=$self->{toader}->getVCS;
	if ( $toader->error ){
		$self->{perror}=1;
		$self->{error}=10;
		$self->{errorString}='Toader->getVCS errored. error="'.
			$self->{toader}->error.'" errorString="'.$self->{toader}->errorString.'"';
		$self->warn;
		return $self;
	}
	
	#checks if VCS is usable
	$self->{VCSusable}=$self->{vcs}->usable;
	if ( $self->{vcs}->error ){
		$self->{perror}=1;
		$self->{error}=11;
		$self->{errorString}='Toader::VCS->usable errored. error="'.
			$self->{toader}->error.'" errorString="'.$self->{toader}->errorString.'"';
		$self->warn;
		return $self;
	}

	return $self;
}

=head2 as_string

This returns the directory as a string.

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

    my $dir=$foo->dirGet;
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub dirGet{
	my $self=$_[0];

	if (!$self->errorblank){
		$self->warn;
		return undef;
	}

	return $self->{dir};
}

=head2 dirSet

This sets L<Toader> directory this entry is associated with.

One argument is taken and it is the L<Toader> directory to set it to.

    $foo->dirSet($toaderDirectory);
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

	#checks if the directory is Toader directory or not
	my $isatd=Toader::isaToaderDir->new;
    my $returned=$isatd->isaToaderDir($dir);
	if (! $returned ) {
		$self->{error}=2;
		$self->{errorString}='"'.$dir.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	#clean it up and save it for later
	$self->{pathHelper}=Toader::pathHelper->new( $dir );
	$self->{dir}=$self->{pathHelper}->cleanup( $dir );	
	$self->{indexfile}=$dir.'/.toader/index';

	#cleans up the naming
	my $pathHelper=Toader::pathHelper->new($dir);
	$dir=$pathHelper->cleanup($dir);
	$self->{indexfile}=$pathHelper->cleanup( $dir ).'/.toader/index';

	#removes the old mime object
	if (defined($self->{mime})) {
		delete($self->{mime});
	}

	if ( ! -f $self->{indexfile}) {
		$self->{mime}=Email::MIME->create(
			header=>[
				renderer=>'html',
				summary=>'',
			],
			body=>'',
			);
	}else {
		#read the index file
		my $fh;
		if ( ! open( $fh, '<', $self->{indexfile} ) ) {
			$self->{error}=1;
			$self->{errorString}="unable to open '".$self->{indexfile}."'";
			$self->warn;
			return $self;
		}
		my $file=join('',<$fh>);
		close $fh;

		$self->{mime}=Email::MIME->new($file);

	}

	return 1;
}

=head2 listSubToaderDirs

This lists the sub L<Toader> directories in the current L<Toader> directory, ignoring items
starting with a '.'.

The returned value is a array containing a list of relative directory names.

This method requires dirSet to have been used previously.

    my @subToaderDirs=$foo->listSubToaderDirs;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub listSubToaderDirs{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	if ( ! defined( $self->{dir} ) ){
		$self->{error}=4;
		$self->{errorString}='No directory has been specified yet';
		$self->warn;
		return undef;
	}

	my $dh;
	if ( ! opendir( $dh, $self->{dir} ) ){
		$self->{error}=7;
		$self->{errorString}='Failed to open the directory, "'.$self->{dir}.'",';
		$self->warn;
		return undef;
	}
	my @dirEntries=readdir( $dh );
	closedir( $dh );
	
	#find the various sub directories
	my $isatd=Toader::isaToaderDir->new;
	my @subdirs;
	my $int=0;
	while ( defined( $dirEntries[$int] ) ){
		my $add=1;

		if ( ! -d $self->{dir}.'/'.$dirEntries[$int] ){
			$add=0;
		}

		if ( $dirEntries[$int] =~ /^\./ ){
			$add=0;
		}

		if ( $add ){
			my $returned=$isatd->isaToaderDir( $self->{dir}.'/'.$dirEntries[$int] );
			if (  $returned ){
				push( @subdirs, $dirEntries[$int] );
			}
		}

		$int++;
	}

	return @subdirs;
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
		$self->{error}=8;
		$self->{errorString}='No summary specified';
		$self->warn;
		return $self;
	}

	$self->{mime}->header_set('summary'=>$summary);

	return 1;
}

=head2 write

This saves the page file. It requires dirSet to
have been called previously.

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
		$self->{error}=4;
		$self->{errorString}='No directory has been specified yet';
		$self->warn;
		return undef;
	}

	#makes sure it is still a toader directory...
	if (! -d $self->{dir}.'/.toader/' ) {
		$self->{error}=5;
		$self->{errorString}='No directory has been specified yet';
		return undef;
	}

	#figure out the file will be
	my $file=$self->{dir}.'/.toader/index';

	#converts the page to a string
	my $pageString=$self->as_string;

	#writes the file
	my $fh;
	if ( ! open($fh, '>', $file) ){
		$self->{error}=6;
		$self->{errorString}='Unable to open "'.$file.'" for writing';
		$self->warn;
		return undef;
	}
	print $fh $pageString;
	close($fh);

	#if it is under VCS, we have nothing to do
	my $underVCS=$self->{vcs}->underVCS($file);
	if ( $self->{vcs}->error ){
		$self->{error}=12;
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
		$self->{error}=13;
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

	return $self->renderDir.'/.files'
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

	return 'Index';
}

=head2 renderDir

This is the directory that it will be rendered to.

The base directory that will be used for rendering.

=cut

sub renderDir{
	return ''
}

=head2 renderUsing

This returns the module to use for rendering.

    my $module=$foo->renderUsing;

=cut

sub renderUsing{
    return 'Toader::Render::Directory';
}

=head2 toaderRenderable

This method returns true and marks it as being Toader
renderable.

=cut

sub toaderRenderable{
	return 1;
}

=head2 toDir

This returns the path to the object.

This is not a full path, but a partial path that should
be appended the directory current directory being outputted to.

=cut

sub toDir{
    my $self=$_[0];

    if (!$self->errorblank){
        return undef;
    }

    return $self->renderDir;
}

=head1 ERROR CODES

=head2 1, openIndexFailed

Unable to open the index file for the specified directory.

=head2 2, notAtoaderDir

The specified directory is not a L<Toader> directory.

=head2 3, noTitleSpecified

No title specified.

=head2 4, noDirSet

No directory has been specified yet.

=head2 5, noLongerAtoaderDir

The directory is no longer a L<Toader> directory.

=head2 6, indexOpenForWritingFailed

Failed to open the file for writing.

=head2 7, openDirFailed

Failed to open the directory.

=head2 8, noSummarySpecified

No summary specified.

=head2 9, notAtoaderObj

The specified objected is not a L<Toader> object.

=head2 10, getVCSerrored

L<Toader>->getVCS errored.

=head2 11, VCSusableErrored

L<Toader::VCS>->usable errored.

=head2 12, underVCSerrored

L<Toader::VCS>->underVCS errored.

=head2 13, VCSaddErrored

L<Toader::VCS>->add errored.

=head2 14, noToaderObj

No L<Toader> object specified.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Directory


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

Copyright 2013 Zane C. Bowers-Hadley

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Toader
