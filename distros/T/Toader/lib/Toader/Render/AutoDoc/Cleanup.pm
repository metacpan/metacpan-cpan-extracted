package Toader::Render::AutoDoc::Cleanup;

use warnings;
use strict;
use base 'Error::Helper';
use Toader::pathHelper;
use File::Path qw(remove_tree);

=head1 NAME

Toader::Render::AutoDoc::Cleanup - This is used for cleaning up the output directory prior to rendering.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

=head1 METHODS

=head2 new

This initiates the object.

One argument is required and it is a L<Toader> object.

	my $foo=Toader::Render::AutoDoc::Cleanup->new($toader);
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
			  errorExtra=>{
				  flags=>{
					  1=>'noToaderObj',
					  2=>'notAtoaderObj',
					  3=>'toaderPerror',
					  4=>'notApageObj',
					  5=>'noObj',
					  6=>'noOutputdirSet',
					  7=>'outputDirDoesNotExist',
					  8=>'objPerror',
					  9=>'noDirSet',
					  10=>'pathhelperErrored',
					  11=>'autodocsDirCleanupFailed',
				  },
			  },
			  };
	bless $self;

	#make sure something passed to this method
	if ( ! defined( $toader ) ){
		$self->{error}=1;
		$self->{errorString}='No Toader object passed';
		$self->{perror}=1;
		$self->warn;
		return $self;
	}

	#makes sure the object passed is a Toader object
	if ( ref( $toader ) ne 'Toader' ){
		$self->{error}=2;
		$self->{errorString}='The passed object is not a Toader object, but a "'
			.ref( $toader ).'"';
		$self->{perror}=1;
		$self->warn;
		return $self;
	}

	#makes sure the toader object is not in a permanent error state
	$toader->errorblank;
	if ( $toader->error ){
		$self->{perror}=1;
		$self->{error}=3;
		$self->{errorString}='The Toader object passed has a permanent error set. error="'.
			$toader->error.'" errorString="'.$toader->errorString.'"';
		$self->warn;
		return $self;
	}

	$self->{toader}=$toader;

	#makes sure a output directory is set
	my $outputdir=$self->{toader}->getOutputDir;
	if( ! defined( $outputdir ) ){
		$self->{error}=6;
		$self->{errorString}='The Toader object has not had a output directory set';
		$self->warn;
		return undef;
	}
	$self->{outputdir}=$outputdir;

	#make sure the output directory exists
	if( ! -d $outputdir ){
		$self->{error}=7;
		$self->{errorString}='The output directory does not exist or does not appear to be a directory';
		$self->warn;
		return undef;
	}

	#gets the pathhelper for later usage
	$self->{pathhelper}=$self->{toader}->getPathHelper;

	return $self;
}

=head2 cleanup

This cleans up the output directory for a specified object.

One argument is taken and that is the object to be cleaned from
the output directory.

    $foo->cleanup( $obj );
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub cleanup{
	my $self=$_[0];
	my $obj=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	#make sure a object was passed
	if ( ! defined( $obj ) ){
		$self->{error}=5;
		$self->{errorString}='No object passed';
		$self->warn;
		return $self;
	}

	#make sure it is a supported type
	if ( ref( $obj ) ne 'Toader::AutoDoc' ){
		$self->{error}=4;
		$self->{errorString}='"'.ref( $obj ).'" is not a supported object type';
		$self->warn;
		return $self;		
	}

	#make sure a permanent error is not set
	$obj->errorblank;
	if( $obj->error ){
		$self->{error}=8;
		$self->{errorString}='The object error has a permanent error set. error="'
			.$obj->error.'" errorString="'.$obj->errorString.'"';
		$self->warn;
		return undef;
	}

	#gets the directory
	my $dir=$obj->dirGet;
	if ( ! defined( $dir ) ){
		$self->{error}=9;
		$self->{errorString}='The object has not had a directory set for it';
		$self->warn;
		return undef;
	}

	#puts together the base directory
	$dir=$self->{outputdir}.'/'.$self->{pathhelper}->relative2root($dir).'/';
	if( $self->{pathhelper}->error ){
		$self->{error}=10;
		$self->{errorString}='Toader::pathHelper errored. error="'.
			$self->{pathhelper}->error.'" errorString="'.
			$self->{pathhelper}->errorString.'"';
		$self->warn;
		return undef;
	}
	$dir=$dir.'.autodoc/';

	#if the directory does not exist, there is nothing to clean up
	if ( ! -e $dir ){
		return 1;
	}

	#remove it
	my $err;
	remove_tree( $dir, { error=>\$err } );
	my @errors=@{ $err };
	if ( defined( $errors[0] ) ){
		$self->{error}=11;
		$self->{errorString}='Failed to remove "'.$dir.'"';
		$self->warn;
		return undef;
	}

	return 1;
}

=head1 ERROR CODES

=head2 1, noToaderObj

No L<Toader> object passed.

=head2 2, notAtoaderObj

The passed object is not a L<Toader> object.

=head2 3, toaderPerror

The L<Toader> object passed has a permanent error set.

=head2 4, notApageObj

The passed object is not a L<Toader::Page> object.

=head2 5, noObj

No object passed.

=head2 6, noOutputDirSet

The L<Toader> object has not had a output directory set.

=head2 7, outputDirDoesNotExist

The output directory does not appear to exist or is not a directory.

=head2 8, objPerror

The object has a permanent error set.

=head2 9, noDirSet

The object has not had a directory set for it.

=head2 10, pathhelperErrored

L<Toader::pathHelper> errored.

=head2 11, autodocsDirCleanupFailed

Failed to clean the autodocs directory.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Render::Page::Cleanup

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

1; # End of Toader::Render::Page::Cleanup
