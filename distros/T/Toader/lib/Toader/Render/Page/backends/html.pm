package Toader::Render::Page::backends::html;

use warnings;
use strict;
use base 'Error::Helper';

=head1 NAME

Toader::Render::Page::backends::html - This handles the html backend stuff for Toader::Render::Directory.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Toader::Render::Page::backends::html;
    
    my $renderer=Toader::Render::Page::backends::html->new({ toader=>$oader, obj=>$pageObj });
    my $rendered;
    if ( $renderer->error ){
        warn( 'Error:'.$renderer->error.': '.$renderer->errorString );
    }else{
        $rendered=$renderer->render($torender);
    }

While this will error etc, this module is basically a pass through as HTML the native.

=head1 METHODS

=head2 new

This initiates the object.

=head3 args hash ref

=head4 obj

This is the L<Toader::Page> object to render.

=head4 toader

This is the L<Toader> object to use.

	my $foo=Toader::Render::Page::backends::html->new(\%args);
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
	if ( ref( $args{obj} ) ne 'Toader::Page' ){
        $self->{perror}=1;
        $self->{error}=1;
        $self->{errorString}='The specified object is not a Toader::Page object, but a "'.
			ref( $args{obj} ).'"';
 		$self->warn;
		return $self;
	}
	$self->{obj}=$args{obj};

	#make sure the object does not have a permanent error set
	if( ! $self->{obj}->errorblank ){
		$self->{perror}=1;
		$self->{error}=3;
		$self->{errorString}='The Toader::Page object has a permanent error set';
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

No arguments are taken.

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
	
	return $torender;
}

=head1 ERROR CODES

=head2 1

No L<Toader::Page> object specified.

=head2 2

No L<Toader> object specified.

=head2 3

The L<Toader::Page> object has a permanent error set.

=head2 4

The L<Toader> object has a permanent error set.

=head2 5

The L<Toader::Page> object does not have a directory set.

=head2 6

Nothing specified to render.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Render::Page::backends::html


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

1; # End of Toader::Render::Directory::backends::html
