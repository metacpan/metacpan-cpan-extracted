package Toader::Render::supportedBackends;

use warnings;
use strict;
use base 'Error::Helper';
use Toader::Render::supportedObjects;
use Module::List qw(list_modules);

=head1 NAME

Toader::Render::supportedBackends - This checks if the backend is supported or not.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

=head1 METHODS

=head2 new

This initiates the object.

There is no reason to check for any errors
as this module will not throw any errors
upon initilization.

	my $foo=Toader::Render::supportedBackends->new;

=cut

sub new{
	my $self={
			  error=>undef,
			  errorString=>'',
			  perror=>undef,
			  soc=>Toader::Render::supportedObjects->new,
			  errorExtra=>{
				  flags=>{
					  1=>'noObj',
					  2=>'unsupportedObj',
				  },
			  },
			  };
	bless $self;

	return $self;
}

=head2 checkBE

This checks if the specified for the object exists or not.

One argument is required and that is the object to check.

    my $results=$foo->checkBE( $obj );
    if ( $foo->error ){
        warn( 'Error:'.$foo->error.': '.$foo->errorString );
    }else{
        if ( $results ){
            print "It is supported.\n";
        }
    }

=cut

sub checkBE{
	my $self=$_[0];
	my $obj=$_[1];

	$self->errorblank;

    if ( ! defined( $obj ) ){
		$self->{error}=1;
		$self->{errorString}='No object defined';
		$self->warn;
		return undef;
    }

	if ( ! $self->{soc}->isSupported( $obj ) ){
		$self->{error}=2;
		$self->{errorString}='"'.ref($obj).'" is not a supported object';
		$self->warn;
		return undef;
	}

	#get what should be rendered
	my $renderUsing=$obj->renderUsing;
	my %modules=list_modules( $renderUsing.'::', { list_modules=>1 } );
	
	#get the renderer
	my $renderer=undef;
	$renderer=$obj->rendererGet;
	if ( $obj->error ){
		$self->{error}=3;
		$self->{errorString}='The object, "'.ref($obj).'", errored. error="'.
			$obj->error.'" errorString="'.$obj->errorString.'"';
		return undef;
	}

}

=head1 ERROR CODES

=head2 1, noObj

No object defined.

=head2 2, unsupportedObj

Unsupported object type.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make
changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Render::supportedBackends

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

1; # End of Toader::Render::supportedBackends
