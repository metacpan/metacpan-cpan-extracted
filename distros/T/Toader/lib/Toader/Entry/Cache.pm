package Toader::Entry::Cache;

use warnings;
use strict;
use Toader::isaToaderDir;
use base 'Error::Helper';
use Toader::pathHelper;
use Toader::Entry::Manage;
use Toader::Entry::Helper;
use DBI;

=head1 NAME

Toader::Entry::Cache - Misc helper methods for entries.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';

=head1 METHODS

=head2 new

This initializes this object.

On argument is required and it is a L<Toader> object.

    my $foo = Toader::Entry::Cache->new( $toader );
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub new{
	my $toader=$_[1];

	my $self={
			  error=>undef,
			  errorString=>'',
			  dir=>undef,
			  edir=>undef,
			  isatd=>Toader::isaToaderDir->new,
			  VCSusable=>0,
			  toader=>undef,
			  errorExtra=>{
				  flags=>{
					  1=>'noToaderObj',
					  2=>'notAtoaderObj',
					  3=>'manageNewErrored',
					  4=>'getVCSerrored',
					  5=>'VCSusableErrored',
					  6=>'noDirSpecified',
					  7=>'notAtoaderDir',
					  8=>'noDirSet',
					  9=>'noEntrySpecified',
					  10=>'notAtoaderEntryObj',
					  11=>'DBIinitErrored',
					  12=>'DBIdoErr',
					  13=>'manageSetDirErrored',
					  14=>'manageListErrored',
					  15=>'manageReadErrored',
					  16=>'noEntryNameSpecified',
				  },
			  },
			  };
	bless $self;

	#if we have a Toader object, reel it in
	if ( ! defined( $toader ) ){
		$self->{perror}=1;
		$self->{error}=1;
		$self->{errorString}='No Toader object specified';
		$self->warn;
		return $self;
	}
	if ( ref( $toader ) ne "Toader" ){
		$self->{perror}=1;
		$self->{error}=2;
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
		$self->{error}=4;
		$self->{errorString}='Toader->getVCS errored. error="'.
			$self->{toader}->error.'" errorString="'.$self->{toader}->errorString.'"';
		$self->warn;
		return $self;
	}
	
	#checks if VCS is usable
	$self->{VCSusable}=$self->{vcs}->usable;
	if ( $self->{vcs}->error ){
		$self->{perror}=1;
		$self->{error}=5;
		$self->{errorString}='Toader::VCS->usable errored. error="'.
			$self->{toader}->error.'" errorString="'.$self->{toader}->errorString.'"';
		$self->warn;
		return $self;
	}

	return $self;
}

=head2 cachefile

This returns the SQLite file that contains the cache for this directory.

    my $cacheFile=$foo->cachefile;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub cachefile{
	my $self=$_[0];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure a directory is defined
	if ( ! defined( $self->{dir} ) ){
		$self->{error}=8;
		$self->{errorString}='No dir set';
		$self->warn;
		return undef;
	}

	return $self->{cachefile};
}

=head2 connect

This connect to the SQLite database containing
the cache and returns the database handler.

    my $dbh=$foo->connect;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }


=cut

sub connect{
	my $self=$_[0];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure a directory is defined
	if ( ! defined( $self->{dir} ) ){
		$self->{error}=8;
		$self->{errorString}='No dir set';
		$self->warn;
		return undef;
	}

	#return the stored dbh if it exists
	if ( defined( $self->{dbh} ) ){
		return $self->{dbh};
	}

	#connect the database if needed
	my $dbh=DBI->connect( 'dbi:SQLite:dbname='.$self->cachefile, "", "" );
	if ( ! defined( $dbh ) ){
		$self->{error}=11;
		$self->{errorString}='DBI->connect failed. err="'.DBI::err.'" errstr="'.DBI::errstr.'"';
		$self->warn;
		return undef;
	}
	$self->{dbh}=$dbh;

	#init... checks if it needs initialized...
	$self->init;
	if ( $self->error ){
		$self->warnString('Need to init the cache, but failed');
		return undef;
	}
	
	return $dbh;
}

=head2 deleteEntry

Deletes a specified entry from the cache.

One argument is taken and the is the name of the entry.

	$foo->deleteEntry( $entryName );
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub deleteEntry{
	my $self=$_[0];
	my $entryName=$_[1];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure we have an entry
	if ( ! defined ( $entryName ) ){
		$self->{error}=16;
		$self->{errorString}='No entryName specified';
		$self->warn;
		return undef;
	}

	#gets the DBH to use
	my $dbh=$self->connect;
	if ( $self->error ){
		$self->warnString('Failed to get the DBH via $self->connect');
		return undef;
	}

	#delete it if it exists
	my $sql='DELETE FROM Entries WHERE entry=?;';
	$dbh->do( $sql, undef, $entryName );
	if ( $dbh->err ){
		$self->{error}=12;
		$self->{errorString}='DBI->do("'.$sql.'") failed. err="'.
			DBI::err.'" errstr="'.DBI::errstr.'"';
		$self->warn;
		return undef;
	}

	#remove any old tags
	$sql='DELETE FROM Tags WHERE entry=?;';
	$dbh->do( $sql, undef, $entryName );
	if ( $dbh->err ){
		$self->{error}=12;
		$self->{errorString}='DBI->do("'.$sql.'") failed. err="'.
			DBI::err.'" errstr="'.DBI::errstr.'"';
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 disconnect

This disconnect from the SQLite database containing
the cache and returns the database handler.

    my $dbh=$foo->connect;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub disconnect{
	my $self=$_[0];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure a directory is defined
	if ( ! defined( $self->{dir} ) ){
		$self->{error}=8;
		$self->{errorString}='No dir set';
		$self->warn;
		return undef;
	}

	#if there is no stored dbh, we are good
	if ( ! defined( $self->{dbh} ) ){
		return 1;
	}

	#disconnects and removes the handler
	$self->{dbh}->disconnect;
	delete( $self->{dbh} );

	return 1;
}

=head2 init

This checks if the cache needs initialized for the directory. If it
does need initialized it will do so.

    $foo->init
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub init{
	my $self=$_[0];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure a directory is defined
	if ( ! defined( $self->{dir} ) ){
		$self->{error}=8;
		$self->{errorString}='No dir set';
		$self->warn;
		return undef;
	}

	#cache exists
	if ( -f $self->{cachefile} ){
		return 1;
	}

	#if VCS is not usable, stop here
	if ( ! $self->{VCSusable} ){
		return 1;
	}

	#initialize it as it has not been created
	$self->reinit;
	if ( $self->error ){
		$self->warnString( 'Failed to call reinit' );
		return undef;
	}

	#if it is under VCS, we have nothing to do
	my $underVCS=$self->{vcs}->underVCS( $self->cachefile );
	if ( $self->{vcs}->error ){
		$self->{error}=17;
		$self->{errorString}='Toader::VCS->underVCS errored. error="'.
			$self->{vcs}->error.'" errorString="'.$self->{vcs}->errorString.'"';
		$self->warn;
		return undef;
	}
	if ( $underVCS ){
		return 1;
	}

	#add it as if we reach here it is not under VCS and VCS is being used
	$self->{vcs}->add( $self->cachefile );
	if ( $self->{vcs}->error ){
		$self->{error}=18;
		$self->{errorString}='Toader::VCS->add errored. error="'.
			$self->{vcs}->error.'" errorString="'.$self->{vcs}->errorString.'"';
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 reinit

Re-initializes the SQLite database. This will
connect to it, drop the tables, and then recreate
the tables.

    $foo->reinit;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub reinit{
	my $self=$_[0];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure a directory is defined
	if ( ! defined( $self->{dir} ) ){
		$self->{error}=8;
		$self->{errorString}='No dir set';
		$self->warn;
		return undef;
	}

	#connects to the database
	my $dbh=$self->connect;
	if ( $self->error ){
		$self->warnString();
		return undef;
	}

	#drops the Tags table
	my $do="DROP TABLE IF EXISTS Tags;";
	$dbh->do( $do );
	if ( $dbh->err ){
		$self->{error}=12;
		$self->{errorString}='DBI->do("'.$do.'") failed. err="'.
			DBI::err.'" errstr="'.DBI::errstr.'"';
		$self->warn;
		return undef;
	}

	#create the Tags table
	$do="CREATE TABLE Tags( entry TEXT, tag TEXT );";
	$dbh->do( $do );
	if ( $dbh->err ){
		$self->{error}=12;
		$self->{errorString}='DBI->do("'.$do.'") failed. err="'.
			DBI::err.'" errstr="'.DBI::errstr.'"';
		$self->warn;
		return undef;
	}

	#drop the Entries table
	$do="DROP TABLE IF EXISTS Entries;";
	$dbh->do( $do );
	if ( $dbh->err ){
		$self->{error}=12;
		$self->{errorString}='DBI->do("'.$do.'") failed. err="'.
			DBI::err.'" errstr="'.DBI::errstr.'"';
		$self->warn;
		return undef;
	}

	#create the Entries table
	$do="CREATE TABLE Entries( entry TEXT PRIMARY KEY, renderer TEXT, title TEXT, summary TEXT, From TEXT, publish INT );";
	$dbh->do( $do );
	if ( $dbh->err ){
		$self->{error}=12;
		$self->{errorString}='DBI->do("'.$do.'") failed. err="'.
			DBI::err.'" errstr="'.DBI::errstr.'"';
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 setDir

This sets the directory to operate on.

One argument is required. It is the directory to use.

    $foo->setDir($directory);
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

	#error if no directory is specified
	if (!defined( $directory )) {
		$self->{error}=6;
		$self->{errorString}='No directory specified';
		$self->warn;
		return undef;
	}

	#cleans up the naming
	my $pathHelper=Toader::pathHelper->new( $directory );
	$directory=$pathHelper->cleanup( $directory );

	#make sure it is a Toader directory
	my $tdc=Toader::isaToaderDir->new;
	my $isaToaderDir=$tdc->isaToaderDir($directory);
	if ( ! $isaToaderDir ) {
		$self->{error}=7;
		$self->{errorString}='Not a Toader directory according to Toader::isaToaderDir->isaToaderDir ';
		$self->warn;
		return undef;
	}

	#delete the dbh if needed
	if ( defined( $self->{dbh} ) ){
		$self->{dbh}->disconnect;
		delete( $self->{dbh} );
	}

	#save the directory
	$self->{dir}=$directory;
	
	#sets the cache file
	$self->{cachefile}=$self->{helper}->entryDirectory.'/cache.sqlite';

	return 1;
}

=head2 updateAll

Updates the cache for all entries in that directory.

    $foo->updateAll;
    if ( $foo->error ){
        warn( 'error:'.$foo->error.':'.$foo->errorString );
    }

=cut

sub updateAll{
	my $self=$_[0];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure a directory is defined
	if ( ! defined( $self->{dir} ) ){
		$self->{error}=8;
		$self->{errorString}='No dir set';
		$self->warn;
		return undef;
	}

	#gets the entry manager
	my $em=Toader::Entry::Manage->new( $self->{toader} );
	if ( $em->error ){
		$self->{error}=3;
		$self->{errorString}='Failed to invoke Toader::Entry::Manage->new. error="'.$em->error.
			'" errorFlag="'.$em->errorFlag.'" errorString="'.$em->errorString.'"';
		$self->warn;
		return undef;
	}

	#sets the directory for the manager
	$em->setDir( $self->{dir} );
	if ( $em->error ){
		$self->{error}=13;
		$self->{errorString}='Failed to invoke Toader::Entry::Manage->setDir. error="'.$em->error.
			'" errorFlag="'.$em->errorFlag.'" errorString="'.$em->errorString.'"';
		$self->warn;
		return undef;
	}

	#gets a list of all the entries
	my @entries=$em->list;
	if ( $em->error ){
		$self->{error}=14;
		$self->{errorString}='Failed to invoke Toader::Entry::Manage->list. error="'.$em->error.
			'" errorFlag="'.$em->errorFlag.'" errorString="'.$em->errorString.'"';
		$self->warn;
		return undef;
	}

	#go through each one
	my $int=0;
	while ( defined $entries[$int] ){
		#gets the entry
		my $entry=$em->read( $entries[$int] );
		if ( $em->error ){
			$self->{error}=15;
			$self->{errorString}='Failed to invoke Toader::Entry::Manage->read. error="'.$em->error.
				'" errorFlag="'.$em->errorFlag.'" errorString="'.$em->errorString.'"';
			$self->warn;
			return undef;
		}

		#updates the cache for the entry
		$self->updateEntry( $entry );
		if ( $self->error ){
			$self->warnString('updateEntry errored for "'.$entries[$int].'"');
			return undef
		}

		$int++;
	}

	return 1;
}

=head2 updateEntry

Updates the cache for the passed entry.

One argument is taken and that is the Toader::Entry object that
the cache is being updated for.

	$foo->updateEntry( $entry );
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub updateEntry{
	my $self=$_[0];
	my $entry=$_[1];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure we have an entry
	if ( ! defined ( $entry ) ){
		$self->{error}=9;
		$self->{errorString}='No entry specified';
		$self->warn;
		return undef;
	}

	#make sure we have a Toader::Entry object
	if ( ref( $entry ) ne "Toader::Entry" ){
		$self->{error}=10;
		$self->{errorString}='Not a Toader::Entry object';
		$self->warn;
		return undef;
	}

	#make sure a directory is defined
	if ( ! defined( $self->{dir} ) ){
		$self->{error}=8;
		$self->{errorString}='No dir set';
		$self->warn;
		return undef;
	}

	my $entryID=$entry->entryNameGet;
	my $renderer=$entry->rendererGet;
	my $title=$entry->titleGet;
	my $summary=$entry->summaryGet;
	my $From=$entry->fromGet;
	my $publish=$entry->publishGet;
	my @tags=$entry->tagsGet;

	#gets the DBH to use
	my $dbh=$self->connect;
	if ( $self->error ){
		$self->warnString('Failed to get the DBH via $self->connect');
		return undef;
	}

	#delete it if it exists
	my $sql='DELETE FROM Entries WHERE entry=?;';
	$dbh->do( $sql, undef, $entryID );
	if ( $dbh->err ){
		$self->{error}=12;
		$self->{errorString}='DBI->do("'.$sql.'") failed. err="'.
			DBI::err.'" errstr="'.DBI::errstr.'"';
		$self->warn;
		return undef;
	}
	
	#adds it
	$sql='INSERT INTO Entries ( entry, renderer, title, summary, From, publish ) values ( ?, ?, ?, ?, ?, ? );';
	$dbh->do( $sql, undef, $entryID, $renderer, $title, $summary, $From, $publish );
	if ( $dbh->err ){
		$self->{error}=12;
		$self->{errorString}='DBI->do("'.$sql.'") failed. err="'.
			DBI::err.'" errstr="'.DBI::errstr.'"';
		$self->warn;
		return undef;
	}

	#remove any old tags
	$sql='DELETE FROM Tags WHERE entry=?;';
	$dbh->do( $sql, undef, $entryID );
	if ( $dbh->err ){
		$self->{error}=12;
		$self->{errorString}='DBI->do("'.$sql.'") failed. err="'.
			DBI::err.'" errstr="'.DBI::errstr.'"';
		$self->warn;
		return undef;
	}

	#processes each tag
	my $int=0;
	while( defined( $tags[ $int ] ) ){
		#add the tag for that entry
		$sql='INSERT INTO Tags ( entry, tag ) VALUES ( ?, ? );';
		$dbh->do( $sql, undef, $entryID, $tags[ $int ] );
		if ( $dbh->err ){
			$self->{error}=12;
			$self->{errorString}='DBI->do("'.$sql.'") failed. err="'.
				DBI::err.'" errstr="'.DBI::errstr.'"';
			$self->warn;
			return undef;
		}

		$int++;
	}

	return 1;
}

=head1 ERROR CODES/Flags

=head2 1, noToaderObj

The object supplied for the L<Toader> object.

=head2 2, notAtoaderObj

The supplies object is not a L<Toader> object.

=head2 3, manageNewErrored

L<Toader::Entry::Manage>->new errored.

=head2 4, getVCSerrored

Failed to get L<Toader::VCS> object.

=head2 5, VCSusableErrored

L<Toader::VCS>->usable errored.

=head2 6, noDirSpecified

Nothing was passed as a directory.

=head2 7, notAtoaderDir

The specified directory is not a L<Toader> directory.

=head2 8, noDirSet

No dir has been set yet.

=head2 9, noEntrySpecified

No entry was specified to processes. This needs to be a L<Toader::Entry> object.

=head2 10, notAtoaderEntryObj

Not a L<Toader::Entry> object.

=head2 11, DBIinitErrored

Failed to initialize the SQLite database via 
L<DBI>->connect.

=head2 12, DBIdoErr

Error with L<DBI>->do.

=head2 13, manageSetDirErrored

Failed when calling L<Toader::Entry::Manage>->setDir.

=head2 14, manageListErrored

Failed when calling L<Toader::Entry::Manage>->list.

=head2 15, manageReadErrored

Failed when calling L<Toader::Entry::Manage>->read.

=head2 16, noEntryNameSpecified

No entryName was specified to processes. This id different from noEntrySpecified
as noEntrySpecified requires a L<Toader::Entry> object and this just requires a
entry name.

=head2 17, underVCS errored

L<Toader::VCS>->underVCS errored.

=head2 18, VCSaddErrored

L<Toader::VCS>->add errored.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Entry::Cache


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

1; # End of Toader::Entry::Cache
