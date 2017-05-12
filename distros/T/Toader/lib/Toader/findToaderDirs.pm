package Toader::findToaderDirs;

use warnings;
use strict;
use Toader::isaToaderDir;
use base 'Error::Helper';

=head1 NAME

Toader::findToaderDirs - Finds all Toader directories under a specified Toader directory.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Toader::findToaderDirs;

    my $foo = Toader::findToaderDirs->new();

    my @dirs=$foo->findToaderDirs($directory);
    if($foo->error){
        warn('Error '.$foo->error.': '.$foo->errorString);
    }else{
        print join("\n", @dirs)."\n";
    }

=head1 METHODS

=head2 new

This initiates the object.

    my $foo = Toader::findToaderDirs->new();

=cut

sub new{
	my $self={
			  error=>undef,
			  errorString=>'',
			  isatd=>Toader::isaToaderDir->new,
			  errorExtra=>{
				  flags=>{
					  1=>'noDirSpecified',
					  2=>'notAdir',
					  3=>'notAtoaderDir',
					  4=>'isaToaderDirErrored',
					  5=>'rootIsAtoaderDir',
					  6=>'dirOpenFailed',
				  },
			  },
			  };
	bless $self;

	return $self;
}

=head2 findToaderDirs

This returns all found L<Toader> directories under the path.

One argument is taken and it a L<Toader> directory.

The returned array will also include the one it started in.

    my @dirs=$foo->findToaderDirs($directory);
    if($foo->error){
        warn('Error '.$foo->error.': '.$foo->errorString);
    }else{
        print join("\n", @dirs)."\n";
    }

=cut

sub findToaderDirs{
	my $self=$_[0];
	my $dir=$_[1];
	my $recursive=$_[2];

	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	# Makes sure a directory is specified.
	if (!defined( $dir )) {
		$self->{error}=1;
		$self->{errorString}='No directory defined';
		$self->warn;
		return undef;
	}

	# Make sure the what is a directory.
	if (! -d $dir ) {
		$self->{error}=2;
		$self->{errorString}='The specified item is not a directory';
		$self->warn;
		return undef;
	}	

	#make sure the directory we were passed is a Toader directory
	my $returned=$self->{isatd}->isaToaderDir($dir);
	if ($self->{isatd}->error) {
		$self->{error}=4;
		$self->{errorString}='isaToaderDir returned "'.$self->{isatd}->error.'", "'.$self->{isatd}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (!$returned) {
		$self->{error}=3;
		$self->{errorString}='"'.$dir.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	#this returns a list of found directories
	my @dirs;

	#gets the subdirs to start
	my @sdirs=$self->findToaderSubDirs($dir);

	#puts together the first one
	my $int=0;
	while( defined( $sdirs[$int] ) ){
		push( @dirs, $dir.'/'.$sdirs[$int] );

		$int++;
	}
	#prevents duplicates
	if( ! $recursive ){
		push(@dirs, $dir);
	}

	#process each subdir
	$int=0;
	while( defined( $sdirs[$int] ) ){
		my $newdir=$dir.'/'.$sdirs[$int];

		#set the recursive arg to true as we don't want to add it twice
		my @newdirs=$self->findToaderDirs( $newdir, '1' );
		
		push( @dirs, @newdirs );

		$int++;
	}

	return @dirs;
}

=head2 findToaderSubDirs

This lists all sub L<Toader> directories under a specified L<Toader> directory.

This only returns the found directory names under the directory.

    my @sub=$foo->findToaderSubDirs($dir);
    if($foo->error){
        warn('Error '.$foo->error.': '.$foo->errorString);
    }else{
        print join("\n", @dirs)."\n";
    }

=cut

sub findToaderSubDirs{
	my $self=$_[0];
	my $dir=$_[1];

	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	# Makes sure a directory is specified.
	if (!defined( $dir )) {
		$self->{error}=1;
		$self->{errorString}='No directory defined';
		$self->warn;
		return undef;
	}

	# Make sure the what is a directory.
	if (! -d $dir ) {
		$self->{error}=2;
		$self->{errorString}='The specified item is not a directory';
		$self->warn;
		return undef;
	}	

	#initiates the directory checker
	my $isatd=Toader::isaToaderDir->new;

	#make sure the directory we were passed is a Toader directory
	my $returned=$isatd->isaToaderDir($dir);
	if ($isatd->error) {
		$self->{error}=4;
		$self->{errorString}='isaToaderDir returned "'.$isatd->error.'", "'.$isatd->errorString.'"';
		$self->warn;
		return undef;
	}
	if (!$returned) {
		$self->{error}=3;
		$self->{errorString}='"'.$dir.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	my @dirs;

	#opens the directory handle
	my $dh;
	if(!opendir($dh,$dir)){
		$self->{error}=6;
		$self->{errorString}='Unable to open the specified directory';
		$self->warn;
		return undef;		
	}
	#process each item
	while(readdir($dh)){
		if ( 
			( $_ ne '.' ) &&
			( $_ ne '..' ) &&
			( -d $dir.'/'.$_.'/.toader' )
			) {
			push(@dirs, $_);
		}
	}
	#done with the directory handle
	closedir($dh);

	return @dirs;
}

=head1 ERROR CODES

=head2 1, noDirSpecified

No directory specified.

=head2 2, notAdir

Not a directory.

=head2 3, notAtoaderDir

Not a L<Toader> directory.

=head2 4, isaToaderDirErrored

L<Toader::isaToaderDir>->isaToaderDir errored.

=head2 5, rootIsAtoaderDir

"/" is the directory and it appears to be a L<Toader> directory.

This is a major WTF and should not be even if '/.toader' exists.

=head2 6, dirOpenFailed

Could not open one of the directories.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::findToaderDirs


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

1; # End of Toader::findToaderDirs
