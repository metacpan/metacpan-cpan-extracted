package Toader::Render::CSS;

use warnings;
use strict;
use Toader::Templates;
use base 'Error::Helper';

=head1 NAME

Toader::Render::CSS - This renders the CSS file for Toader.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Toader::Render::CSS;

    my $foo = Toader::Render::CSS->new($toader);

    #renders it to a string
    my $css=$foo->renderCSS;
    if ( $foo->error ){
        warn('error: '.$foo->error.":".$foo->errorString);
    }
    
    #this renders it to a file... this unlike renderCSS
    #requires a output directory set
    $toader->setOutputDir('/foo/bar');
    if ( $toader->error ){
        #do something
    }
    $foo->render;
    if ( $foo->error ){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=head1 METHODS

=head2 new

This initiates the object.

One argument is taken. That is the a L<Toader> object.

    my $foo=Toader::Render::CSS->new($toader);
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
					  1=>'noObj',
					  2=>'noToaderObj',
					  3=>'toaderObjPerror',
					  4=>'noOutputDirSet',
					  5=>'templateFillFailed',
					  6=>'outputDirDoesNotExist',
					  7=>'outputWriteFailed',
				  },
			  },
			  };
	bless $self;

	#make sure a Toader object is given
    if ( ! defined( $toader ) ){
        $self->{perror}=1;
        $self->{error}=1;
        $self->{errorString}='Nothing defined for the Toader object';
        $self->warn;
        return $self;
    }
    if ( ref( $toader ) ne 'Toader' ){
        $self->{perror}=1;
        $self->{error}=2;
        $self->{errorString}='The specified object is not a Toader object, but a "'.
            ref( $toader ).'"';
        $self->warn;
        return $self;
    }
	$self->{toader}=$toader;

    #make sure the object does not have a permanent error set
    if( ! $self->{toader}->errorblank ){
        $self->{perror}=1;
        $self->{error}=3;
        $self->{errorString}='The Toader object has a permanent error set';
        $self->warn;
        return $self;
    }

	$self->{templates}=Toader::Templates->new( { 
		dir=>$self->{toader}->getRootDir,
		toader=>$toader,
											   } );

	return $self;
}

=head2 renderCSS

This processes the CSS template.

No arguments are accepted.

	my $css=$foo->renderCSS;

=cut

sub renderCSS{
	my $self=$_[0];

	if ( ! $self->errorblank ){
		return undef;
	}

	my $config=$self->{toader}->getConfig;
	my $css=$self->{templates}->fill_in( 'css',
										 {
											 c=>\$config,
											 toader=>\$self->{toader},
										 });
	
	if ( $self->{templates}->error ){
		$self->{error}=5;
		$self->{errorString}='Failed to render the template. error="'.
			$self->{templates}->error.'" errorString="'.
			$self->{templates}->errorString.'"';
		$self->warn;
		return undef;
	}

    my $cssInclude=$self->{templates}->fill_in( 'cssInclude',
                                         {
                                             c=>\$config,
                                             toader=>\$self->{toader},
                                         });

    if ( $self->{templates}->error ){
        $self->{error}=5;
        $self->{errorString}='Failed to render the template. error="'.
            $self->{templates}->error.'" errorString="'.
            $self->{templates}->errorString.'"';
        $self->warn;
        return undef;
    }


	return $css.$cssInclude;
}

=head2 render

This renders it to the output directory.

No arguments are taken.

    $foo->render;

=cut

sub render{
	my $self=$_[0];

	if ( ! $self->errorblank ){
		return undef;
	}

	my $dir=$self->{toader}->getOutputDir;
	if ( ! defined( $dir ) ){
		$self->{error}=4;
		$self->{errorString}='The Toader object does not have a output directory set';
		$self->warn;
		return undef;
	}

	my $css=$self->renderCSS;
	if ( $self->error ){
		$self->warnString( 'renderCSS errored' );
		return undef;
	}

	if ( ! -d $dir ){
		if ( ! mkdir( $dir )){
			$self->{error}=6;
			$self->{errorString}='The output directory,"'.$dir
				.'", does not exist and it could be created';
			$self->warn;
			return undef;
		}
	}

	my $file=$dir.'/toader.css';
	my $fh;
	if ( ! open( $fh, '>', $file ) ){
		$self->{error}=7;
		$self->{errorString}='Failed to open "'.$file.'" for writing';
		$self->warn;
		return undef;
	}
	print $fh $css;
	close( $fh );

	return 1;
}

=head1 ERROR CODES

=head2 1, noObj

Nothing defined for the L<Toader> object.

=head2 2, noToaderObj

The specified object is not a L<Toader> object.

=head2 3, toaderObjPerror

The L<Toader> object has a permanent error set.

=head2 4, noOutputDirSet

The L<Toader> object does not have a output directory set.

=head2 5, templateFillFailed

Failed to fill in the CSS template.

=head2 6, outputDirDoesNotExist

The output directory did not exist and could not be created.

=head2 7, outputWriteFailed

Failed to write the file out to the output directory.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Render:CSS

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

1; # End of Toader::Render::CSS
