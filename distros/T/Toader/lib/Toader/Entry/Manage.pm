package Toader::Entry::Manage;

use warnings;
use strict;
use Toader::isaToaderDir;
use Toader::Entry::Helper;
use Toader::Entry;
use base 'Error::Helper';
use Toader::Entry::Cache;

=head1 NAME

Toader::Entry::Manage - Manage entries.

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 METHODS

=head2 new

This initiates the object.

One argument is required and it is a L<Toader> object.

After calling this, you should call setDir to set the directory to use.

    my $foo = Toader::New->new( $toader );

=cut

sub new{
	my $toader=$_[1];

	my $self={
			  error=>undef,
			  errorString=>'',
			  dir=>undef,
			  edir=>undef,
			  isatd=>Toader::isaToaderDir->new,
			  helper=>undef,
			  VCSusable=>0,
			  toader=>undef,
			  errorExtra=>{
				  flags=>{
					  1=>'noDirSpecified',
					  2=>'isaToaderDirErrored',
					  3=>'notAtoaderDir',
					  4=>'noDirDefined',
					  5=>'openDirFailed',
					  6=>'noEntrySpecified',
					  7=>'invalidEntryName',
					  8=>'entryDoesNotExist',
					  9=>'unlinkFailed',
					  10=>'openEntryFailed',
					  11=>'entryObjCreationFailed',
					  12=>'notAtoaderObj',
					  13=>'getVCSerrored',
					  14=>'VCSusableErrored',
					  15=>'underVCSerrored',
					  16=>'VCSdeleteErrored',
					  17=>'noToaderObj',
					  18=>'helperNewErrored',
					  19=>'cacheNewErrored',
					  20=>'cacheDirSetErrored',
					  21=>'cacheUpdateAllErrored',
					  22=>'entryNameSetErrored',
					  23=>'entryWriteErrored',
				  },
			  },
			  };
	bless $self;

	#if we have a Toader object, reel it in
	if ( ! defined( $toader ) ){
		$self->{perror}=1;
		$self->{error}=17;
		$self->{errorString}='No Toader object specified';
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

	#init the helper
	$self->{helper}=Toader::Entry::Helper->new( $self->{toader} );
	if ( $self->{helper}->error ){
		$self->{perror}=1;
		$self->{error}=18;
		$self->{errorString}='Failed to initialize Toader::Entry::Helper.'.
			'error="'.$self->{helper}->error.'" errorString="'.$self->{helper}->errorString.'"';
		$self->warn;
		return $self;
	}
	
	#gets the Toader::VCS object
	$self->{vcs}=$self->{toader}->getVCS;
	if ( $toader->error ){
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

	#inits the cache
	my $cache=Toader::Entry::Cache->new( $toader );
	if ( $cache->error ){
		$self->{perror}=1;
		$self->{error}=19;
		$self->{errorString}='Toader::Entry::Cache->new errored. error="'.
			$cache->error.'" errorString="'.$cache->errorString.'"';
		$self->warn;
		return $self;
	}
	$self->{cache}=$cache;

	return $self;
}

=head2 cacheGet

This returns the L<Toader::Entry::Cache> object.

There are no arguments taken.

    my $cache=$foo->cacheGet;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub cacheGet{
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

	return $self->{cache};
}

=head2 cacheUpdateAll

This updates the cache for all entries.

There are no arguments taken.

	$foo->cacheUpdateAll;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub cacheUpdateAll{
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

	$self->{cache}->updateAll;
	if ( $self->{cache}->error ){
		$self->{error}=21;
		$self->{errorString}='Toader::Entry::Cache->updateAll errored. error="'.
			$self->{cache}->error.'" errorString="'.$self->{cache}->errorString.'"';
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 list

This lists the available entries.

    my @entries=$foo->list;
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
	my @entries;

	#makes sure we have a entry directory
	if (!-d $self->{edir}) {
		return @entries;
	}

	#read what is present in the directory
	my $dh;
	if (!opendir($dh, $self->{edir})) {
		$self->{error}='5';
		$self->{errorString}='Failed to open the directory "'.$self->{dir}.'"';
		$self->warn;
		return undef;
	}
	@entries=grep( { -f $self->{edir}.'/'.$_ && /$self->{helper}->{regex}/ }  readdir($dh) );
	close($dh);

	return @entries;
}

=head2 published

This returns a list of published or unpublished entries.

One argument is accepted and that is the return value from
Toader::Entry->publishGet. If that is not defined, then '1'
is used.

This will throw a warning for entries that can not be read,
it will not throw a error.

    my @published=$foo->published;
    if ( $foo->error ){
        warn( 'Error:'.$foo->error.': '.$foo->errorStrin );
    }

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

	my @entries=$self->list;
	if ( $self->error ){
		$self->warnString('Failed to list the entries');
		return undef;
	}
	
	#checks for them all
	my @published;
	my $int=0;
	while ( defined( $entries[$int] ) ){
		my $entry=$self->read( $entries[$int] );

		if ( $self->error ){
			$self->warnString('Failed to read entry "'.$entries[$int].'"');
		}else{
			my $ispublished=$entry->publishGet;
			if ( $ispublished eq $bool ){
				push( @published, $entries[$int] );
			}
		}

		$int++;
	}

	return @published;
}

=head2 read

This reads a entry.

One argument is taken and that is the entry name.

    my $entry=$foo->read( $entryName );
    if ( $foo->error ){
        warn( 'Error:'.$foo->error.': '.$foo->errorStrin );
    }

=cut

sub read{
	my $self=$_[0];
	my $entry=$_[1];

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

	#make sure it is valid and exists
	my $returned=$self->{helper}->entryExists($entry);
	if (!$returned) {
		if ($self->{helper}->error){
			$self->{error}=7;
			$self->{errorString}='The entry name is not valid';
		}else {
			$self->{error}=8;
			$self->{errorString}='The entry does not exist';
		}
		$self->warn;
		return undef;
	}

	#the file that will be read
	my $file=$self->{dir}.'/.toader/entries/'.$entry;

	#reads it
	my $entryString;
	my $fh;
	if ( ! open($fh, '<', $file) ){
		$self->{error}=10;
		$self->{errorString}='Unable to open "'.$file.'" for writing';
		$self->warn;
		return undef;
	}
	$entryString=join("", <$fh>);
	close($fh);

	my $entryObj=Toader::Entry->newFromString($entryString, $self->{toader});
	if ($entryObj->error) {
		$self->{error}=11;
		$self->{errorString}='Unable to generate a Toader::Entry object from ';
		$self->warn;
		return undef;		
	}

	#sets the directory
	$entryObj->dirSet($self->{dir});
	$entryObj->entryNameSet($entry);

	return $entryObj;
}

=head2 remove

This removes a entry. It will remove it from VCS and the cache as well.

One argument is required and it is entry name.

    $foo->remove($entry);
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub remove{
	my $self=$_[0];
	my $entry=$_[1];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#makes sure a entry is specified
	if (!defined($entry)) {
		$self->{error}='6';
		$self->{errorString}='No entry specified';
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
	my $returned=$self->{helper}->entryExists($entry);
	if (!$returned) {
		if ($self->{helper}->error){
			$self->{error}=7;
			$self->{errorString}='The entry name is not valid';
		}else {
			$self->{error}=8;
			$self->{errorString}='The entry does not exist';
		}
		$self->warn;
		return undef;
	}

	#saves this for later
	my $file=$self->{edir}.'/'.$entry;
	
	#unlinks it
	if (!unlink( $file )) {
		$self->{error}=9;
		$self->{errorString}='Failed to unlink the entry';
		$self->warn;
		return undef;		
	}

	#if VCS is not usable, return here
	if ( ! $self->{VCSusable} ){
		return 1;
	}
	
	#if it is not under VCS, we have nothing to do
	my $underVCS=$self->{vcs}->underVCS($file);
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

	#deletes the entry from the cache
	$self->{cache}->deleteEntry( $entry );
	if ( $self->{cache}->error ){
		$self->{error}=24;
		$self->{errorString}='Toader::Entry::Cache->deleteEntry errored. error="'.
			$self->{cache}->error.' errorString="'.$self->{cache}->errorString.'"';
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 setDir

This sets the directory the module will work on.

One argument is taken and that is the path for the L<Toader> directory
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
	$self->{edir}=$self->{helper}->entryDirectory;

	#sets it for the cache
	$self->{cache}->setDir( $directory );
	if ( $self->{cache}->error ){
		$self->{error}=20;
		$self->{errorString}='Toader::Entry::Cache->setDir errored. error="'.
			$self->{cache}->error.'" errorString="'.$self->{cache}->errorString.'"';
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 touch

This updates the entry name to a newer one.

=cut

sub touch{
	my $self=$_[0];
	my $entryName=$_[1];

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

	my $entry=$self->read( $entryName );
	if ( $self->error ){
		return undef;
	}

	#sets a new entryname
	$entry->entryNameSet;
	if ( $entry->error ){
		$self->{error}=22;
		$self->{errorString}='Toader::Entry->entyNameSet errored. error="'.
			$entry->error.' errorString="'.$entry->errorString.'"';
		$self->warn;
		return undef;
	}

	#writes it out
	$entry->write;
	if ( $entry->error ){
		$self->{error}=23;
		$self->{errorString}='Toader::Entry->write errored. error="'.
			$entry->error.' errorString="'.$entry->errorString.'"';
		$self->warn;
		return undef;
	}

	#deletes the old one
	$self->remove( $entryName );
	if ( $self->error ){
		return undef;
	}

	return 1;
}

=head1 ERROR CODES/Flags

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

=head2 8, entryDoesNotExist

The entry does not exist.

=head2 9, unlinkFailed

Failed to unlink the entry.

=head2 10, openEntryFailed

Unable to open the entry file for reading.

=head2 11, entryObjCreationFailed

Generating a L<Toader::Entry> object from a alredy existing entry failed.

=head2 12, notAtoaderObj

The object specified is not a L<Toader> object.

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

L<Toader::Entry::Helper>->new errored.

=head2 19, cacheNewErrored

L<Toader::Entry::Cache>->new errored.

=head2 20, cacheDirSetErrored

L<Toader::Entry::Cache>->setDir errored.

=head2 21, cacheUpdateAllErrored

L<Toader::Entry::Cache>->updateAll errored.

=head2 22, entryNameSetErrored

L<Toader::Entry>->entryNameSet errored.

=head2 23, entryWriteErrored

L<Toader::Entry>->write errored.

=head2 24, cacheDeleteEntryErrored

L<Toader::Entry::Cache>->deleteEntry errored.

If this errors it means the cache is screwed in some manner and
needs reinited via L<Toader::Entry::Cache>->reinit.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Entry::Manage


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

Copyright 2014 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Toader
