package Toader::Render;

use warnings;
use strict;
use Toader::isaToaderDir;
use base 'Error::Helper';

=head1 NAME

Toader::Render - This renders supported Toader objects.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';


=head1 SYNOPSIS

    use Toader::Render;

    my $foo = Toader::Render->new(\%args);

=head1 METHODS

=head2 new

This initiates the object.

On argument is required and it is a L<Toader> object.

    my $foo->new($toader);
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
			  isatd=>Toader::isaToaderDir->new(),
			  toader=>undef,
			  outputdir=>undef,
			  errorExtra=>{
				  flags=>{
					  1=>'noObj',
					  2=>'noDirSet',
					  3=>'noToaderObj',
					  4=>'notAtoaderObj',
					  5=>'noOutputDirSet',
					  6=>'outputDirDoesNotExist',
					  7=>'notAuserableObj',
					  8=>'rendererInitErrored',
					  9=>'renderErrored',
					  10=>'renderReturnedUndef',
					  11=>'rendererInitReturnedUndef',
				  },
			  },
			  };
	bless $self;

	#make sure that a Toader object is specifed
	if(!defined( $toader )){
		$self->{perror}=1;
		$self->{error}=3;
		$self->{errorString}='No Toader object specified';
		$self->warn;
		return $self;
	}
	#make sure that a Toader object is specifed
	if( ref( $toader ) ne 'Toader' ){
		$self->{perror}=1;
		$self->{error}=4;
		$self->{errorString}='The passed Toader object is not really a Toader object';
		$self->warn;
		return $self;
	}
	$self->{toader}=$toader;

	#get the output dir
	if(!defined( $toader->getOutputDir )){
		$self->{perror}=1;
		$self->{error}=5;
		$self->{errorString}='No outputdir defined';
		$self->warn;
		return $self;
	}
	$self->{outputdir}=$toader->getOutputDir;

	#make sure the output directory is really a directory
	if( ! -d $self->{outputdir} ){
		$self->{perror}=1;
		$self->{error}=6;
		$self->{errorString}='The outputdir is not a directory or does not exist';
		$self->warn;
		return $self;
	}

	return $self;
}

=head2 isAsupportedObj

This checks if a object is supported.

A return of true means it is supported, otherwise it is false.

This does not mean that the object is usable. For that use the
method isAusableObj.

    my $supported=$self->isAsupportedObj($someObject);
    if(!$supported){
        warn('The object is not supported.')
    }

=cut

sub isAsupportedObj{
	my $self=$_[0];
	my $obj=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	#make sure we have a object
	if (!defined($obj)) {
		$self->{error}=1;
		$self->{errorString}='No object specified';
		$self->warn;
		return undef;
	}

	#error if it is a string... this avoids possible injections
	if ( ref($obj) eq 'STRING' ){
		return undef;
	}

	#test if it is renderable
	my $renderable=0;
	my $test='$renderable=$obj->toaderRenderable;';
	eval($test);
	if ( ! $renderable ){
		return undef;
	}

	return 1;
}

=head2 isAusableObj

This checks if a object is supported and usable.

A return of true means it is supported, otherwise it is false.

    my $supported=$self->isAsupportedObj($someObject);
    if(!$supported){
        warn('The object is not supported.')
    }

=cut

sub isAusableObj{
	my $self=$_[0];
	my $obj=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	#make sure we have a object
	if (!defined($obj)) {
		$self->{error}=1;
		$self->{errorString}='No object specified';
		$self->warn;
		return undef;
	}

	#makes sure it is supported
	my $supported=$self->isAsupportedObj($obj);
	if ( ! $supported ) {
		return undef;
	}

	#makes sure the object has a directory specified
	my $dir=$obj->dirGet;
	if (!defined($dir)) {
		$self->{error}=2;
		$self->{errorString}='The object does not have a directory associated with it';
		$self->warn;
		return undef;		
	}

	#makes sure the directory is really a toader directory
	my $returned=$self->{isatd}->isaToaderDir($dir);
	if (!$returned) {
		$self->{error}=3;
		$self->{errorString}='"'.$dir.'" is not a Toader directory';
		$self->warn;
		return undef;		
	}

	return 1;
}

=head2 renderObj

This renders a object.

	$foo->renderObj($obj);

=cut

sub renderObj{
	my $self=$_[0];
	my $obj=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	if(!defined($obj)){
		$self->{error}=1;
		$self->{errorString}='No object specified';
		$self->warn;
		return undef;
	}

	if(!$self->isAusableObj($obj)){
		$self->{error}=7;
		$self->{errorString}='"'.ref($obj).'" is not a usable object';
		$self->warn;
		return undef;
	}

	#gets what object to use for rendering
	my $renderUsing;
	my $rendererGet='$renderUsing=$obj->renderUsing;';
	eval( $rendererGet );
	if ( ! defined( $renderUsing ) ){
		$self->{error}=10;
		$self->{errorString}='Failed to get the renderer to use. obj="'.ref($obj).'"';
		$self->warn;
		return undef;
	}

	#initiates the renderer
	my $renderer;
	my $rendererInit='use '.$renderUsing.'; $renderer='.$renderUsing.'->new( { obj=>$obj, toader=>$self->{toader} } );';
	eval( $rendererInit );
	if ( ! defined( $renderer ) ){
		$self->{error}=11;
		$self->{errorString}='Rendering initialize resulted in a undef. init string="'.$rendererInit.'"';
		$self->warn;
		return undef;
	}
	if($renderer->error){
		$self->{error}=8;
		$self->{errorString}='Unable to initialize the renderer. render="'.ref($obj).'" '.
			'error="'.$renderer->error.'" errorString="'.$renderer->errorString.'"';
		$self->warn;
		return undef;
	}

	$renderer->render;
	if($renderer->error){
		$self->{error}=9;
		$self->{errorString}='Rendering failed. render="'.ref($obj).'" '.
			'error="'.$renderer->error.'" errorString="'.$renderer->errorString.'"';
		$self->warn;
		return undef;
	}

	return 1;
}

=head1 ERROR CODES

=head2 1, noObj

No object specified.

=head2 2, noDirSet

The object does not have a directory associated with it.

=head2 3, noToaderObj

No Toader object specified.

=head2 4, notAtoaderObj

The object passed as a L<Toader> object is not a L<Toader> object.

=head2 5, noOutputDirSet

No outputdir specified.

=head2 6, outputDirDoesNotExist

The specified outputdir does not exist or is not a directory.

=head2 7, notAusableObj

The specified object is not usable.

=head2 8, rendererInitErrored

Unable to initialize the render for the object.

=head2 9, renderErrored

Rendering failed at rendering the object.

=head2 10, renderReturnedUndef

Renderer returned undef.

=head2 11, rendererInitReturnedUndef

Attempting to initialize the renderer returned undefined.

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

Copyright 2013. Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Toader::Render
