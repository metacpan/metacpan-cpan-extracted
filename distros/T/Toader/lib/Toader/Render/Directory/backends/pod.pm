package Toader::Render::Directory::backends::pod;

use warnings;
use strict;
use base 'Error::Helper';
use Pod::Simple::HTML;
use File::Temp;
use File::Spec;

=head1 NAME

Toader::Render::Directory::backends::pod - This handles the POD backend stuff for Toader::Render::Directory.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Toader::Render::Directory::backends::pod;
    
    my $renderer=Toader::Render::Directory::backends::pod->new({ toader=>$toader, obj=>$dirObj });
    my $rendered;
    if ( $renderer->error ){
        warn( 'Error:'.$renderer->error.': '.$renderer->errorString );
    }else{
        $rendered=$renderer->render($torender);
    }

=head1 METHODS

=head2 new

This initiates the object.

=head3 args hash ref

=head4 obj

This is the L<Toader::Directory> object to render.

=head4 toader

This is the L<Toader> object to use.

	my $foo=Toader::Render::Directory::backends::pod->new(\%args);
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	my $self={
			  error=>undef,
			  errorString=>'',
			  perror=>undef,
			  errorExtra=>{
				  flags=>{
					  1=>'noObj',
					  2=>'noToaderObj',
					  3=>'notAdirectoryObj',
					  4=>'toaderPerror',
					  5=>'noDirSet',
					  6=>'nothingSpecifiedToRender',
					  7=>'tempOpenFailed',
					  8=>'tempUnlinkFailed',
					  9=>'htmlRenderFailed',
				  },
			  },
			  };
	bless $self;

	#make sure we have a Toader::Directory object.
	if ( ! defined( $args{obj} ) ){
		$self->{perror}=1;
		$self->{error}=1;
		$self->{errorString}='Nothing defined for the Toader::Directory object';
		$self->warn;
		return $self;
	}
	if ( ref( $args{obj} ) ne 'Toader::Directory' ){
        $self->{perror}=1;
        $self->{error}=1;
        $self->{errorString}='The specified object is not a Toader::Entry object, but a "'.
			ref( $args{obj} ).'"';
 		$self->warn;
		return $self;
	}
	$self->{obj}=$args{obj};

	#make sure the object does not have a permanent error set
	if( ! $self->{obj}->errorblank ){
		$self->{perror}=1;
		$self->{error}=3;
		$self->{errorString}='The Toader::Directory object has a permanent error set';
		$self->warn;
		return $self;
	}

	#make sure a Toader object is given
    if ( ! defined( $args{toader} ) ){
        $self->{perror}=1;
        $self->{error}=2;
        $self->{errorString}='Nothing defined for the Toader object';
        $self->warn;
        return $self;
    }
    if ( ref( $args{toader} ) ne 'Toader' ){
        $self->{perror}=1;
        $self->{error}=2;
        $self->{errorString}='The specified object is not a Toader object, but a "'.
            ref( $args{toader} ).'"';
        $self->warn;
        return $self;
    }
	$self->{toader}=$args{toader};

    #make sure the Toader object does not have a permanent error set
    if( ! $self->{toader}->errorblank ){
        $self->{perror}=1;
        $self->{error}=4;
        $self->{errorString}='The Toader object has an permanent error set';
        $self->warn;
        return $self;
    }

    #make sure a directory is set
    if( ! defined( $self->{obj}->dirGet ) ){
        $self->{perror}=1;
        $self->{error}=5;
        $self->{errorString}='The Toader::Directory object does not have a directory set';
        $self->warn;
        return $self;
    }

	return $self;
}

=head2 render

This renders the object.

One argument is taken and that is what is to be rendered.

=cut

sub render{
	my $self=$_[0];
	my $torender=$_[1];

	if ( ! $self->errorblank ){
		return undef;
	}

	if ( !defined( $torender ) ){
		$self->{error}=6;
		$self->{errorString}='Nothing to render specified';
		$self->warn;
		return undef;
	}

	#create a tmp file
	my $tmpfile = File::Temp::tempnam( File::Spec->tmpdir, 'tdat' );
	my $fh;
	if ( ! open( $fh, '>', $tmpfile ) ){
		$self->{error}=7;
		$self->{errorString}='Failed to open a temp file, "'.$tmpfile.'",';
		$self->warn;
		return undef;
	}
	print $fh $torender;
	close( $fh );

	#print `ls $tmpfile; cat $tmpfile`;

	#renders it
	my $p = Pod::Simple::HTML->new;
	my $html;
	$p->index(1);
	$p->output_string(\$html);
	$p->parse_file( $tmpfile );

	#unlinks the file
	if (! unlink( $tmpfile ) ){
		$self->{error}=8;
		$self->{errorString}='Failed to unlink "'.$tmpfile.'"';
		$self->warn;
		return undef;		
	}

	#makes sure something is returned for html
	if (! defined( $html ) ){
		$self->{error}=9;
		$self->{errorString}='Failed to render the html';
		$self->warn;
		return undef;		
	}

	return $html;
}

=head1 ERROR CODES

=head2 1, noObj

No L<Toader::Directory> object specified.

=head2 2, noToaderObj

No L<Toader> object specified.

=head2 3, notAdirectoryObj

The L<Toader::Directory> object has a permanent error set.

=head2 4, toaderPerror

The L<Toader> object has a permanent error set.

=head2 5, noDirSet

The L<Toader::Directory> object does not have a directory set.

=head2 6, nothingSpecifiedToRender

Nothing specified to render.

=head2 7, tempOpenFailed

Failed to open a temp file.

=head2 8, tempUnlinkFailed

Failed to unlink the the temporary file.

=head2 9, htmlRenderFailed

Failed to render the HTML.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Render::Directory::backends::pod


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

1; # End of Toader::Render::Directory::backends::pod
