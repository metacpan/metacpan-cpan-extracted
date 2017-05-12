package Toader::Page::Helper;

use warnings;
use strict;
use Toader::isaToaderDir;
use base 'Error::Helper';
use Toader::pathHelper;
use Toader::Page::Manage;

=head1 NAME

Toader::Page::Helper - Misc helper methods for pages.

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 METHODS

=head2 new

This initializes this object.

This method will not error.

    my $foo = Toader::Page::FileHelper->new();

=cut

sub new{
	my $toader=$_[1];

	my $self={
			  error=>undef,
			  errorString=>'',
			  perror=>undef,
			  directory=>undef,
			  errorExtra=>{
				  flags=>{
					  1=>'notAtoaderDir',
					  2=>'noDirSpecified',
					  3=>'noPageSpecified',
					  4=>'noDirSet',
					  5=>'invalidPageName',
					  6=>'pageManageErrored',
					  7=>'noToaderObj',
					  8=>'notAtoaderObj',
				  },
			  },
			  };
	bless $self;

	#if we have a Toader object, reel it in
	if ( ! defined( $toader ) ){
		$self->{perror}=1;
		$self->{error}=7;
		$self->{errorString}='No Toader object specified';
		$self->warn;
		return $self;
	}
	if ( ref( $toader ) ne "Toader" ){
		$self->{perror}=1;
		$self->{error}=8;
		$self->{errorString}='The object specified is a "'.ref($toader).'"';
		$self->warn;
		return $self;
	}
	$self->{toader}=$toader;

	return $self;
}

=head2 pageDirectory

This returns the page directory.

This requires setDir to be called previously.

If setDir has been successfully called, this will not error.

    my $pageDirectory=$foo->pageDirectory;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub pageDirectory{
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
	
	return $self->{directory}.'/.toader/pages/';
}

=head2 pageExists

This checks if the specified page exists.

One argument is accepted and it is the page in question.

This requires setDir to be called previously.

    my $retruned=$foo->pageExists($page);
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }
    if($returned){
        print "It exists.\n";
    }

=cut

sub pageExists{
	my $self=$_[0];
	my $page=$_[1];

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

	#make sure a page is specified.
	if (!defined($page)) {
		$self->{error}=0;
		$self->{errorString}='No page specified';
		$self->warn;
		return undef;
	}

	#make sure we have a valid page name.
	my $returned=$self->validPageName($page);
	if (!$returned) {
		$self->{error}=5;
		$self->{errorString}='The page name is not valid';
		$self->warn;
		return undef;
	}
	
	#check if it exists
	if (-f $self->{directory}.'/.toader/pages/'.$page ) {
		return 1;
	}

	return 0;
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

This builds a summary of of the the pages.



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
	my $pmanage=Toader::Page::Manage->new;
	$pmanage->setDir( $self->{directory} );
	if ( $pmanage->error  ){
		$self->{error}=6;
		$self->{errorString}='Failed to initialize Toader::Page::Manage. '.
			'error="'.$pmanage->error.'" errorString="'.$pmanage->errorString.'"';
		$self->warn;
		return undef;
	}
	
	my @pages=$pmanage->list;
	my $int=0;
	while ( defined[$int] ){
		

		$int++;
	}

}

=head2 validPageName

This verifies that the name is a valid file name.

One arguemnet is taken and that is the name of the page
name to check.

This will not error. If the name is not defined, false, '0', will
be returned as undefined is not a valid name.

    my $valid=$foo->validPageName($name);
    if($valid){
        print '"'.$name.'" is a valid name.';
    }

=cut

sub validPageName{
	my $self=$_[0];
	my $name=$_[1];

	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	if (!defined($name)) {
		return undef;
	}

	#checks for invalid characters
	if ($name =~ /\n/) {
		return 0;
	}
	if ($name =~ /\t/) {
		return 0;
	}
	if ($name =~ /\//) {
		return 0;
	}
	if ($name =~ /^ /) {
		return 0;
	}
	if ($name =~ / $/) {
		return 0;
	}
	if ($name =~ /^\./) {
		return 0;
	}
	
	return 1;
}

=head1 ERROR CODES

=head2 1, notAtoaderDir

Not a L<Toader> directory.

=head2 2, noDirSpecified

No directory specified.

=head2 3, noPageSpecified

No page specified.

=head2 4, noDirSet

No directory has been set yet.

=head2 5, invalidPageName

The page name is not valid.

=head2 6, pageManageErrored

Failed to initialize L<Toader::Page::Manage>.

=head2 7, noToaderObj

No L<Toader> object specified.

=head2 8, notAtoaderObj

The object specified is not a L<Toader> object.


=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Page::Helper


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

1; # End of Toader::Page::Helper
