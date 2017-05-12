package Toader::Render::supportedObjects;

use warnings;
use strict;
use base 'Error::Helper';

=head1 NAME

Toader::Render::supportedObjects - This checks if a object is supported or not for rendering.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

=head1 METHODS

=head2 new

This initiates the object.

	my $foo=Toader::Render::supportedObjects->new;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub new{
	my $self={
			  error=>undef,
			  errorString=>'',
			  perror=>undef,
			  errorExtra=>{
				  flags=>{
					  1=>'noObj',
				  },
			  },
			  };
	bless $self;

	return $self;
}

=head2 isSupported

This checks if a object is supported or not.

One argument is required and it is the object to check.

Error checking is only needed as long as what is passed
is known to be defined.

    my $supported=$foo->isSupported( $obj );
    if ( $foo->error ){
        warn( 'Error:'.$foo->error.': '.$foo->errorString );
    }else{
        if ( $supported ){
            print "The object is supported.\n";
        }
    }

=cut

sub isSupported{
	my $self=$_[0];
	my $obj=$_[1];

	$self->errorblank;

	if ( ! defined( $obj ) ){
		$self->{error}=1;
		$self->{errorString}='No object passed';
		$self->warn;
		return undef;
	}

	my $toaderRenderable=0;
	eval( '$toaderRenderable=$obj->toaderRenderable;' );

	return $toaderRenderable;
}

=head1 ERROR CODES

=head2 1, noObj

No object has been passed.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make
changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Render::supportedObjects

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

1; # End of Toader::Render::supportedObjects
