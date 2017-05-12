package Toader::Page::Manage;

use warnings;
use strict;
use Toader::isaToaderDir;
use Toader::Page::Helper;
use Toader::Page;
use base 'Error::Helper';
use Toader::pathHelper;

=head1 NAME

Toader::Page::Manage - Manage pages for a specified Toader directory.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Toader::Page::Manage;


=head1 METHODS

=head2 new

This initiates the object.

One argument is required and that is a L<Toader> object.

After calling this, you should call setDir to set the directory to use.

    my $foo = Toader::Page::Manage->new( $toader );

=cut

sub new{
	my $toader=$_[1];

	my $self={
			  error=>undef,
			  errorString=>'',
			  dir=>undef,
			  pdir=>undef,
			  isatd=>Toader::isaToaderDir->new,
			  helper=>undef,
			  VCSusable=>0,
			  toader=>undef,
			  errorExtra=>{
				  flags=>{
					  1=>'noDirSpecified',
					  2=>'isaToaderDir',
					  3=>'notAtoaderDir',
					  4=>'noDirSpecified',
					  5=>'openDirFailed',
					  6=>'noEntrySpecified',
					  7=>'invalidEntryName',
					  8=>'pageDoesNotExist',
					  9=>'unlinkFailed',
					  10=>'openPageFailed',
					  11=>'pageObjCreationFailed',
					  12=>'notAtoaderObj',
					  13=>'getVCSerrored',
					  14=>'VCSusableErrored',
					  15=>'underVCSerrored',
					  16=>'VCSdeleteErrored',
					  17=>'noToaderObj',
					  18=>'helperNewErrored',
				  },
			  },
			  };
	bless $self;
	
	#if we have a Toader object, reel it in
	if ( ! defined( $toader ) ){
		$self->{perror}=1;
		$self->{error}=17;
		$self->{errorString}='No Toader object passed';
		$self->warn;
		return $self;
	}
	if ( ref( $toader ) ne "Toader" ){
		$self->{perror}=1;
		$self->{error}=12;
		$self->{errorString}='The object specified is a "'.ref($toader).'"';
		$self->warn;
		return $self;
	}
	$self->{toader}=$toader;

	#inits the helper object
	$self->{helper}=Toader::Page::Helper->new( $toader );
	if ( $self->{helper}->error ){
		$self->{perror}=1;
		$self->{error}=18;
		$self->{errorString}='Failed to initialize Toader::Page::Helper.'.
			'error="'.$self->{helper}->error.'" errorString="'.$self->{helper}->errorString.'"';
		$self->warn;
		return $self;
	}

	#gets the Toader::VCS object
	$self->{vcs}=$self->{toader}->getVCS;
	if ( $self->{toader}->error ){
		$self->{perror}=1;
		$self->{error}=13;
		$self->{errorString}='Toader->getVCS errored. error="'.
			$self->{toader}->error.'" errorString="'.$self->{toader}->errorString.'"';
		$self->warn;
		return $self;
	}
	
	#checks if VCS is usable
	$self->{VCSusable}=$self->{vcs}->usable;
	if ( $self->{vcs}->error ){
		$self->{perror}=1;
		$self->{error}=14;
		$self->{errorString}='Toader::VCS->usable errored. error="'.
			$self->{toader}->error.'" errorString="'.$self->{toader}->errorString.'"';
		$self->warn;
		return $self;
	}

	return $self;
}

=head2 list

This lists the available pages.

    my @pages=$foo->list;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub list{
	my $self=$_[0];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure a directory has been set
	if (!defined($self->{dir})) {
		$self->{error}='4';
		$self->{errorString}='No directory has been set yet';
		$self->warn;
		return undef;
	}

	#this will be returned
	my @pages;

	#makes sure we have a entry directory
	if ( ! -d $self->{pdir}) {
		return @pages;
	}

 	#read what is present in the directory
	my $dh;
	if (! opendir( $dh, $self->{pdir} ) ) {
		$self->{error}='5';
		$self->{errorString}='Failed to open the directory "'.$self->{dir}.'"';
		$self->warn;
		return undef;
	}
	@pages=grep( { -f $self->{pdir}.'/'.$_ }  readdir($dh) );
	close($dh);

	my @toreturn;
	my $int=0;
	while( defined( $pages[$int] ) ){
		if ( $self->{helper}->validPageName( $pages[$int] ) ){
			push( @toreturn, $pages[$int] );
		}

		$int++;
	}

	return @toreturn;
}

=head2 published

=cut

sub published{
	my $self=$_[0];
	my $bool=$_[1];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#set the default
	if ( ! defined( $bool ) ){
		$bool='1';
	}

	#make sure the boolean is definitely zero or one
	if ( $bool ){
		$bool='1';
	}else{
		$bool='0';
	}

	my @pages=$self->list;
	if ( $self->error ){
		$self->warnString('Failed to list the pages');
		return undef;
	}
	
	#checks for them all
	my @published;
	my $int=0;
	while ( defined( $pages[$int] ) ){
		my $page=$self->read( $pages[$int] );

		if ( $self->error ){
			$self->warnString('Failed to read page "'.$pages[$int].'"');
		}else{
			my $ispublished=$page->publishGet;
			if ( $ispublished eq $bool ){
				push( @published, $pages[$int] );
			}
		}

		$int++;
	}

	return @published;
}

=head2 read

This reads a page.

One argument is required and it is entry name.

The returned value is a L<Toader::Page> object.

    my $page=$foo->read($pageName);
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub read{
	my $self=$_[0];
	my $page=$_[1];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#makes sure a directory is specified
	if (!defined($page)) {
		$self->{error}='6';
		$self->{errorString}='No pagespecified';
		$self->warn;
		return undef;
	}

	#make sure a directory has been set
	if (!defined($self->{dir})) {
		$self->{error}='4';
		$self->{errorString}='No directory has been set yet';
		$self->warn;
		return undef;
	}

	#make sure it is valid and exists
	my $returned=$self->{helper}->pageExists($page);
	if (!$returned) {
		if ($self->{helper}->error){
			$self->{error}=7;
			$self->{errorString}='The page name is not valid';
		}else {
			$self->{error}=8;
			$self->{errorString}='The page does not exist';
		}
		$self->warn;
		return undef;
	}

	#figure out the file will be
	my $file=$self->{dir}.'/.toader/pages/'.$page;

	#reads it
	my $pageString;
	my $fh;
	if ( ! open($fh, '<', $file) ){
		$self->{error}=10;
		$self->{errorString}='Unable to open "'.$file.'" for reading';
		$self->warn;
		return undef;
	}
	$pageString=join("", <$fh>);
	close($fh);

	my $pageObj=Toader::Page->newFromString($pageString, $self->{toader});
	if ($pageObj->error) {
		$self->{error}=11;
		$self->{errorString}='Unable to generate a Toader::Page object from ';
		$self->warn;
		return undef;
	}

	#sets the directory
	$pageObj->dirSet($self->{dir});

	return $pageObj;
}

=head2 remove

This removes a page.

One argument is required and it is page name.

    $foo->remove($page);
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub remove{
	my $self=$_[0];
	my $page=$_[1];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}
	
	#makes sure a directory is specified
	if (defined($page)) {
		$self->{error}='6';
		$self->{errorString}='No page specified';
		$self->warn;
		return undef;
	}

	#make sure a directory has been set
	if (!defined($self->{dir})) {
		$self->{error}='4';
		$self->{errorString}='No directory has been set yet';
		$self->warn;
		return undef;
	}
	
	#make sure it is valid and exists
	my $returned=$self->{helper}->pageExists($page);
	if (!$returned) {
		if ($self->{helper}->error){
			$self->{error}=7;
			$self->{errorString}='The page name is not valid';
		}else {
			$self->{error}=8;
			$self->{errorString}='The page does not exist';
		}
		$self->warn;
		return undef;
	}

	#the file in question
	my $file=$self->{pdir}.'/'.$page;
	
	if (!unlink( $file ) ){
		$self->{error}=9;
		$self->{errorString}='Failed to unlink the page, "'.$file.'",';
		$self->warn;
		return undef;
	}

	#if VCS is not usable, return here
	if ( ! $self->{VCSusable} ){
		return 1;
	}
	
	#if it is not under VCS, we have nothing to do
	my $underVCS=$self->{vcs}->underVCS( $file );
	if ( $self->{vcs}->error ){
		$self->{error}=15;
		$self->{errorString}='Toader::VCS->underVCS errored. error="'.
			$self->{vcs}->error.'" errorString="'.$self->{vcs}->errorString.'"';
		$self->warn;
		return undef;
	}
	if ( $underVCS ){
		return 1;
	}
	
	#delete it as if we reach here it is not under VCS and VCS is being used
	$self->{vcs}->delete( $file );
	if ( $self->{vcs}->error ){
		$self->{error}=16;
		$self->{errorString}='Toader::VCS->delete errored. error="'.
			$self->{vcs}->error.'" errorString="'.$self->{vcs}->errorString.'"';
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 setDir

This sets the directory the module will work on.

One argument is taken and that is the path for the Toader directory
in question.

    $foo->setDir($toaderDirectory)
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub setDir{
	my $self=$_[0];
	my $directory=$_[1];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#makes sure a directory is specified
	if (!defined($directory)) {
		$self->{error}='1';
		$self->{errorString}='No directory specified';
		$self->warn;
		return undef;
	}

	#cleans up the naming
	my $pathHelper=Toader::pathHelper->new( $directory );
	$directory=$pathHelper->cleanup( $directory );
	
	#makes sure it is a directory
	my $returned=$self->{isatd}->isaToaderDir($directory);
	if(!$returned){
        if($self->{isatd}->error){
			$self->{error}='2';
			$self->{errorString}='isaToaderDir errored. error="'.$self->{isatd}->error.'" errorString="'.$self->{isatd}->errorString.'"';
			$self->warn;
			return undef;
        }
		$self->{error}='3';
		$self->{errorString}='"'.$directory.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	#it has been verified, so set it
	$self->{dir}=$directory;
	$self->{helper}->setDir($directory); #if the previous check has been worked, then this well
	$self->{pdir}=$self->{helper}->pageDirectory;

	return 1;
}

=head1 ERROR CODES/FLAGS

=head2 1, noDirSpecified

No directory specified.

=head2 2, isaToaderDirErrored

isaToaderDir errored.

=head2 3, notAtoaderDir

Is not a L<Toader> directory.

=head2 4, noDirDefined

No directory has been defined.

=head2 5, openDirFailed

Failed to open the directory.

=head2 6, noEntrySpecified

No entry specified.

=head2 7, invalidEntryName

The entry is not a valid name.

=head2 8, pageDoesNotExist

The entry does not exist.

=head2 9, unlinkFailed

Failed to unlink the entry.

=head2 10, openPageFailed

Unable to open the page file for reading.

=head2 11, pageObjCreationFailed

Unable to generate a L<Toader::Page> object from the file.

=head2 12, notAtoaderObj

The object specified is not a Toader object.

=head2 13, getVCSerrored

L<Toader>->getVCS errored.

=head2 14, VCSusableErrored

L<Toader::VCS>->usable errored.

=head2 15, underVCSerrored

L<Toader::VCS>->underVCS errored.

=head2 16, VCSdeleteErrored

L<Toader::VCS>->delete errored.

=head2 17, noToaderObj

No L<Toader> object specified.

=head2 18, helperNewErrored

L<Toader::Page::Helper>->new errored.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Page::Manage


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

Copyright 2011 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Toader
