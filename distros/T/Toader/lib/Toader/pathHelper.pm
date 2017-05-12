package Toader::pathHelper;

use warnings;
use strict;
use base 'Error::Helper';
use Toader::isaToaderDir;
use File::Spec;
use Toader::findToaderRoot;
use Cwd 'abs_path';

=head1 NAME

Toader::pathHelper - Various path related helpers.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Toader::pathHelper;

    my $foo = Toader::pathHelper->new;

=head1 METHODS

=head2 new

This initiates the object.

One argument is taken. That is the a L<Toader> directory.

    my $foo=Toader::pathHelper->new($toaderDir);
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub new{
	my $dir=$_[1];

	my $self={
			  error=>undef,
			  errorString=>'',
			  isatd=>Toader::isaToaderDir->new,
			  perror=>undef,
			  errorExtra=>{
				  flags=>{
					  1=>'noDirSpecified',
					  2=>'notAtoaderDir',
					  3=>'otherToaderDir',
					  4=>'notAbleToFindRoot',
					  5=>'notUnderToaderRoot',
				  },
			  },
			  };
	bless $self;

	#make sure a directory has been specified
	if (!defined($dir)) {
		$self->{error}=1;
		$self->{errorString}='No directory specified';
		$self->{perror}=1;
		$self->warn;
		return undef;
	}

    my $returned=$self->{isatd}->isaToaderDir($dir);
	if (! $returned ) {
		$self->{error}=2;
		$self->{errorString}='"'.$dir.'" is not a Toader directory';
		$self->{perror}=1;
		$self->warn;
		return undef;
	}

	#finds the root
	my $findroot = Toader::findToaderRoot->new;
	my $root=$findroot->findToaderRoot($dir);
	if($findroot->error){
		$self->{error}=4;
		$self->{errorString}='Could not find the root for "'.$dir.'" '.
			'error="'.$findroot->error.'" '.
			'errorString="'.$findroot->errorString.'"';
		$self->warn;
		return undef;
	}
	$self->cleanup($root);
	$self->{root}=$root;

	return $self;
}

=head2 atRoot

This checks if a directory is the root or not.

=cut

sub atRoot{
	my $self=$_[0];
	my $dir=$_[1];

	if( ! $self->errorblank ){
		return undef;
	}

	#make sure a directory has been specified
	if ( ! defined( $dir ) ) {
		$self->{error}=1;
		$self->{errorString}='No directory specified';
		$self->warn;
		return undef;
	}

	#cleans up the directory
	$dir=$self->cleanup($dir);

	#check if it is the same
	if ( $self->{root} eq $dir ){
		return 1;
	}

	return 0;
}

=head2 back2root

This returns relative path from specified directory,
back to the L<Toader> root directory.

One argument is taken and that is the Toader directory
under the root L<Toader> directory.

=cut

sub back2root{
	my $self=$_[0];
	my $dir=$_[1];

	if( ! $self->errorblank ){
		return undef;
	}

	#make sure a directory has been specified
	if ( ! defined( $dir ) ) {
		$self->{error}=1;
		$self->{errorString}='No directory specified';
		$self->warn;
		return undef;
	}

	#make sure it is a Toader dir
	if (! $self->{isatd}->isaToaderDir($dir) ) {
		$self->{error}=2;
		$self->{errorString}='"'.$dir.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	#makes sure they are both under the root directory
	if( ! $self->underRoot( $dir ) ){
		$self->{error}=5;
		$self->{errorString}='"'.$dir.'" is not under the root Toader directory "'.
			$self->{root}.'",';
		return undef;
	}

	return $self->relative( $dir, $self->{root} );
}

=head2 cleanup

This cleans up the path for a L<Toader> directory.

    my $cleandir=$foo->cleanup($dir);
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub cleanup{
	my $self=$_[0];
	my $dir=$_[1];

	if(!$self->errorblank){
		return undef;
	}

	#make sure a directory has been specified
	if (!defined($dir)) {
		$self->{error}=1;
		$self->{errorString}='No directory specified';
		$self->warn;
		return undef;
	}

    my $returned=$self->{isatd}->isaToaderDir($dir);
	if (! $returned ) {
		$self->{error}=2;
		$self->{errorString}='"'.$dir.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	#cleanup the path
	$dir=File::Spec->canonpath( $dir ) ;
	$dir=abs_path( $dir );

	return $dir;
}

=head2 relative

This finds the relative path between two toader directories.

Two arguments are accepted. Both are L<Toader> directories. The first
one is the directory to start in and the second is the directory
to end in.

    my $relativePath=$foo->relative($fromDir, $toDir);
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub relative{
	my $self=$_[0];
	my $dir0=$_[1];
	my $dir1=$_[2];

	if(!$self->errorblank){
		return undef;
	}

	#make sure a directory has been specified
	if (
		(!defined($dir0)) ||
		(!defined($dir1))
		) {
		$self->{error}=1;
		$self->{errorString}='No directory specified';
		$self->warn;
		return undef;
	}

	#make sure both directories are Toader directories
	if (! $self->{isatd}->isaToaderDir($dir0) ) {
		$self->{error}=2;
		$self->{errorString}='"'.$dir0.'" is not a Toader directory';
		$self->warn;
		return undef;
	}
	if (! $self->{isatd}->isaToaderDir($dir1) ) {
		$self->{error}=2;
		$self->{errorString}='"'.$dir1.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	#makes sure they are both under the root directory
	if( ! $self->underRoot( $dir0 ) ){
		$self->{error}=5;
		$self->{errorString}='"'.$dir0.'" is not under the root Toader directory "'.
			$self->{root}.'",';
		return undef;
	}
	if( ! $self->underRoot( $dir1 ) ){
		$self->{error}=5;
		$self->{errorString}='"'.$dir1.'" is not under the root Toader directory "'.
			$self->{root}.'",';
		return undef;
	}

	$dir0=$self->cleanup($dir0);
	$dir1=$self->cleanup($dir1);

	return File::Spec->abs2rel( $dir1, $dir0 );
}

=head2 relative2root

This returns relative path from the root L<Toader> directory.

One argument is taken and that is the L<Toader> directory
under the root L<Toader> directory.

=cut

sub relative2root{
	my $self=$_[0];
	my $dir=$_[1];

	if( ! $self->errorblank ){
		return undef;
	}

	#make sure a directory has been specified
	if ( ! defined( $dir ) ) {
		$self->{error}=1;
		$self->{errorString}='No directory specified';
		$self->warn;
		return undef;
	}

	#make sure it is a Toader dir
	if (! $self->{isatd}->isaToaderDir($dir) ) {
		$self->{error}=2;
		$self->{errorString}='"'.$dir.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	#makes sure they are both under the root directory
	if( ! $self->underRoot( $dir ) ){
		$self->{error}=5;
		$self->{errorString}='"'.$dir.'" is not under the root Toader directory "'.
			$self->{root}.'",';
		return undef;
	}

	return $self->relative( $self->{root}, $dir );
}

=head2 underRoot

This checks if a specified L<Toader> directory is under the L<Toader> root
directory.

One argument is taken and that is a directory. This directory must be a L<Toader>
directory.

The returned value is a boolean value.

    my $return=$self->underRoot($dir);
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub underRoot{
	my $self=$_[0];
	my $dir=$_[1];

	if(!$self->errorblank){
		return undef;
	}

	#make sure a directory has been specified
	if ( !defined($dir) ) {
		$self->{error}=1;
		$self->{errorString}='No directory specified';
		$self->warn;
		return undef;
	}

	#make sure both directories are Toader directories
    my $returned=$self->{isatd}->isaToaderDir($dir);
	if (! $returned ) {
		$self->{error}=2;
		$self->{errorString}='"'.$dir.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	return $self->underRootNT( $dir );
}

=head2 underRootNT

This checks if a specified directory is under the L<Toader> root
directory. Unlike underRoot, no check is done on if it is a
Toader directory or not.

One argument is taken and that is a directory.

The returned value is a boolean value.

This does not check if it exists or not.

    my $return=$self->underRootNT($dir);
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub underRootNT{
	my $self=$_[0];
	my $dir=$_[1];

	if(!$self->errorblank){
		return undef;
	}

	#make sure a directory has been specified
	if ( !defined($dir) ) {
		$self->{error}=1;
		$self->{errorString}='No directory specified';
		$self->warn;
		return undef;
	}

	#cleans up the directory
	$dir=$self->cleanup($dir);
	$dir=$dir.'/'; #done to make sure other things are not matched... if it is the same as the root

	#add / to the root to make sure other items are not matched and make it into a regexp
	my $root=$self->{root}.'/';
	$root='^'.quotemeta($root);

	if( $dir =~ /$root/ ){
		return 1;
	}
	
	return 0;
}

=head1 ERROR CODES

=head2 1, noDirSpecified

No directory specified.

=head2 2, notAtoaderDir

The directory is not a L<Toader> directory.

=head2 3, otherToaderDir

The L<Toader> directory in question is not under the L<Toader>
directory root it was initialized with.

=head2 4, notAbleToFindRoot

Unable to find the root L<Toader> directory.

=head2 5, notUnderToaderRoot

The directory is not under the root L<Toader> directory.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Render


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

Copyright 2011. Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Toader
