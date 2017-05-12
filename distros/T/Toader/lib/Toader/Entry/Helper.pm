package Toader::Entry::Helper;

use warnings;
use strict;
use Toader::isaToaderDir;
use base 'Error::Helper';
use Toader::pathHelper;
use Toader::Entry::Manage;
use Time::HiRes qw( gettimeofday );

=head1 NAME

Toader::Entry::Helper - Misc helper methods for entries.

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 METHODS

=head2 new

This initializes this object.

On argument is required and it is a L<Toader> object.

    my $foo = Toader::Entry::Helper->new( $toader );
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub new{
	my $toader=$_[1];

	my $self={
			  error=>undef,
			  errorString=>'',
			  perror=>undef,
			  directory=>undef,
			  regex=>'[12][90][0123456789][0123456789]'.
	                 '[01][0123456789]'.
			         '[012][0123456789]-'.
			         '[012][0123456789]'.
			         '[012345][0123456789]'.
			         '[012345][0123456789].'.
			         '[0123456789]*',
			  errorExtra=>{
				  flags=>{
					  1=>'notAtoaderDir',
					  2=>'noDirSpecified',
					  3=>'noEntrySpecified',
					  4=>'noDirSet',
					  5=>'invalidEntryName',
					  6=>'entryManageErrored',
					  7=>'listEntriesErrored',
					  8=>'readEntryErrored',
					  9=>'noToaderObj',
					  10=>'notAtoaderObj',
				  },
			  },
			  };
	bless $self;

	#if we have a Toader object, reel it in
	if ( ! defined( $toader ) ){
		$self->{perror}=1;
		$self->{error}=9;
		$self->{errorString}='No Toader object specified';
		$self->warn;
		return $self;
	}
	if ( ref( $toader ) ne "Toader" ){
		$self->{perror}=1;
		$self->{error}=10;
		$self->{errorString}='The object specified is a "'.ref($toader).'"';
		$self->warn;
		return $self;
	}
	$self->{toader}=$toader;

	return $self;
}

=head2 entryDirectory

This returns the entry directory.

This requires setDir to be called previously.

If setDir has been successfully called, this will not error.

    my $entryDirectory=$foo->entryDirectory;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub entryDirectory{
	my $self=$_[0];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure setDir has been called with out issue
	if (!defined($self->{directory})) {
		$self->{error}=4;
		$self->{errorString}='No directory has been set yet';
		$self->warn;
		return undef;		
	}
	
	return $self->{directory}.'/.toader/entries/';
}

=head2 entryExists

This checks if the specified helper exists.

One argument is accepted and it is

This requires setDir to be called previously.

    my $retruned=$foo->entryExists($entry);
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }
    if($returned){
        print "It exists.\n";
    }

=cut

sub entryExists{
	my $self=$_[0];
	my $entry=$_[1];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure setDir has been called with out issue
	if (!defined($self->{directory})) {
		$self->{error}=4;
		$self->{errorString}='No directory has been set yet';
		$self->warn;
		return undef;		
	}

	#make sure a entry is specified.
	if (!defined($entry)) {
		$self->{error}=0;
		$self->{errorString}='No entry specified';
		$self->warn;
		return undef;
	}

	#make sure we have a valid entry name.
	my $returned=$self->validEntryName($entry);
	if (!$returned) {
		$self->{error}=5;
		$self->{errorString}='The entry name is not valid';
		$self->warn;
		return undef;
	}

	#check if it exists
	if (-f $self->{directory}.'/.toader/entries/'.$entry ) {
		return 1;
	}

	return 0;
}

=head2 generateEntryName

This generates a entry name.

    my $entryName=$foo->generateEntryName;

=cut

sub generateEntryName{
	my $self=$_[0];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#gets the time
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year += 1900;

	#makes sure there are no single digit time items
	if ($mon=~/^[0123456789]$/) {
		$mon='0'.$mon;
	}
	if ($mday=~/^[0123456789]$/) {
		$mday='0'.$mday;
	}
	if ($hour=~/^[0123456789]$/) {
		$hour='0'.$hour;
	}
	if ($min=~/^[0123456789]$/) {
		$min='0'.$min;
	}
	if ($sec=~/^[0123456789]$/) {
		$sec='0'.$sec;
	}
	$mon++;
	my $hsec=gettimeofday;
	$hsec=~s/.*\.//;

	#generate it and return it
	return $year.$mon.$mday.'-'.$hour.$min.$sec.'.'.$hsec;
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
		$self->{error}=2;
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
		$self->{error}=1;
		$self->{errorString}='Not a Toader directory according to Toader::isaToaderDir->isaToaderDir ';
		$self->warn;
		return undef;
	}

	#save the directory
	$self->{directory}=$directory;

	return 1;
}

=head2 summary

This builds a summary of the of the entries in the directory.

=head3 returned hash

The key values are the entry IDs. Each subhash then
contains the following keys.

    from
    renderer
    title
    summary

=cut

sub summary{
	my $self=$_[0];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure setDir has been called with out issue
	if (!defined($self->{directory})) {
		$self->{error}=4;
		$self->{errorString}='No directory has been set yet';
		$self->warn;
		return undef;		
	}

	#initalize Toader::Entry::Manage
	my $emanage=Toader::Entry::Manage->new( $self->{toader} ) ;
	$emanage->setDir( $self->{directory} );
	if ( $emanage->error  ){
		$self->{error}=6;
		$self->{errorString}='Failed to initialize Toader::Entry::Manage. '.
			'error="'.$emanage->error.'" errorString="'.$emanage->errorString.'"';
		$self->warn;
		return undef;
	}

	my @entries=$emanage->list;
	if ( $emanage->error  ){
		$self->{error}=7;
		$self->{errorString}='Failed to list the entries. error="'
			.$emanage->error.'" errorString="'.$emanage->errorString.'"';
		$self->warn;
		return undef;
	}

	my %summary;

	my $int=0;
	while( defined( $entries[$int] )  ){
		my $entry=$emanage->read( $entries[$int] );
		if( $emanage->error ){
			$self->{error}=8;
			$self->{errorString}='Failed to read the entry "'.$entries[$int].'". error="'
				.$emanage->error.'" errorString="'.$emanage->errorString.'"';
			$self->warn;
			return undef;
		}

		$summary{$entries[$int]}={
			from=>$entry->fromGet,
			title=>$entry->titleGet,
			renderer=>$entry->rendererGet,
			summary=>$entry->summaryGet,
		};
		
		$int++;
	}

	return %summary;	
}

=head2 validEntryName

This verifies that the name is a valid file name.

One arguemnet is taken and that is the name of the entry
name to check.

This will not error. If the name is not defined, false, '0', will
be returned as undefined is not a valid name.

    my $valid=$foo->validEntryName($name);
    if($valid){
        print '"'.$name.'" is a valid name.';
    }

=cut

sub validEntryName{
	my $self=$_[0];
	my $name=$_[1];

	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	if (!defined($name)) {
		return undef;
	}

	if ($name =~ /$self->{regex}/) {
		return 1;
	}
	
	return 0;
}

=head2 validEntryNameRegex

This returns the regular expression for validating a entry name.

This method does not call errorBlank for ease simplicity. This means
a error check should not be done on this message as if any error was
set previously then one will still be set.

    my $regex=$foo->validEntryNameRegex($name);

=cut

sub validEntryNameRegex{
	return $_[0]->{regex};
}

=head1 ERROR CODES

=head2 1, notAtoaderDir

Not a L<Toader> directory.

=head2 2, noDirSpecified

No directory specified.

=head2 3, noEntrySpecified

No entry specified.

=head2 4, noDirSet

No directory has been set yet.

=head2 5, invalidEntryName

The entry name is not valid.

=head2 6, entryManageErrored

Failed to initialize L<Toader::Entry::Manage>.

=head2 7, listEntriesErrored

Failed to list the entires.

=head2 8, readEntryErrored

Failed to read a entry.

=head2 9, noToaderObj

No L<Toader> object specified.

=head2 10, notAtoaderObj

The object specified is not a L<Toader> object.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Entry::Helper


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
