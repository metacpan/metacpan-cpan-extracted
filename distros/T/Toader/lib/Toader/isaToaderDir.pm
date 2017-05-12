package Toader::isaToaderDir;

use warnings;
use strict;
use base 'Error::Helper';

=head1 NAME

Toader::isaToaderDir - Checks if a directory has Toader support or not.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';


=head1 SYNOPSIS

    use Toader::isaToaderDir;

    my $foo = Toader::isaToaderDir->new();

    my $returned=$foo->isaToaderDir($directory);
    if(!$returned){
        if($foo->error){
            warn('Error '.$foo->error.': '.$foo->errorString);
        }
    }else{
        print "It is a Toader directory";
    }

=head1 METHODS

=head2 new

This initiates the object.

    my $foo = Toader::isaToaderDir->new();

=cut

sub new{
	my $self={
			  error=>undef,
			  errorString=>'',
			  perror=>undef,
			  errorExtra=>{
				  flags=>{
					  1=>'noDirSpecified',
					  2=>'notAdir',
				  },
			  },
			  };
	bless $self;

	return $self;
}

=head2 isaToaderDir

This checks if a directory is a L<Toader> directory.

If it is it returns true, it is a L<Toader> directory.

A error will only be generated if a directory is not specified
or it does not exist.

    my $returned=$foo->isaToaderDir($directory);
    if(!$returned){
        if($foo->error){
            warn('Error '.$foo->error.': '.$foo->errorString);
        }
    }else{
        print "It is a Toader directory";
    }

=cut

sub isaToaderDir{
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
		return undef;
	}

	# Make sure the what is a directory.
	if (! -d $dir ) {
		$self->{error}=2;
		$self->{errorString}='The specified item is not a directory';
		return undef;
	}	

	#makes sure the required toader directory exists
	if (! -d $dir.'/.toader') {
		return undef;
	}

	return 1;
}

=head1 ERROR CODES

=head2 1, noDirSpecified

No directory specified.

=head2 2, notAdir

Not a directory.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::isaToaderDir


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

1; # End of Toader::isaToaderDir
