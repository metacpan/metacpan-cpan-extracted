package Toader::findToaderRoot;

use warnings;
use strict;
use Toader::isaToaderDir;
use Cwd 'abs_path';
use base 'Error::Helper';

=head1 NAME

Toader::findToaderRoot - This finds the root Toader directory.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Toader::findToaderRoot;

    my $foo = Toader::findToaderRoot->new();

    my $root=$foo->findToaderRoot($directory);
    if($foo->error){
        warn('Error '.$foo->error.': '.$foo->errorString);
    }else{
        print $root."\n";
    }

=head1 METHODS

=head2 new

This initiates the object.

    my $foo = Toader::findToaderRoot->new();

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
					  3=>'notAtoaderDir',
					  4=>'isaToaderDirErrored',
					  5=>'rootIsAtoaderDir',
				  },
			  },
			  };
	bless $self;

	return $self;
}

=head2 findToaderRoot

This takes a directory and then finds the root for that Toader repo.

One argument is required and it is the directory to start in.

One value is returned and it is the root directory.

    my $root=$foo->findToaderRoot($directory);
    if($foo->error){
        warn('Error '.$foo->error.': '.$foo->errorString);
    }else{
        print $root."\n";
    }

=cut

sub findToaderRoot{
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
		$self->{errorString}='isaToaderDir returned "'.$isatd->error.
			'", "'.$isatd->errorString.'"';
		$self->warn;
		return undef;
	}
	if (!$returned) {
		$self->{error}=3;
		$self->{errorString}='"'.$dir.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	#makes sure we don't have /
	#There is no good reason we should ever have / as a toader directory...
	#It means some idiot really fucked something up.
	if ($dir eq '/') {
		$self->{error}=5;
		$self->{errorString}='"/" is the directory and it appears to be a Toader directory';
		$self->warn;
		return undef;
	}

	#this stores the previous directory
	my $pdir=$dir;

	$dir=abs_path($dir.'/..');
	#we will always find something below so it is just set to 1
	while (1) {
		#we hit the FS root...
		if ($dir eq '/') {
			return $pdir;
		}

		$returned=$isatd->isaToaderDir($dir);
		#If we got this far, it means, there is no point in
		#checking here again.
		if (!$returned) {
			return $pdir
		}

		$pdir=$dir;
		$dir=abs_path($dir.'/..');
	}

	#we should never get here
	return undef;
}

=head1 ERROR CODES

=head2 1, noDirSpecified

No directory specified.

=head2 2, notAdir

Not a directory.

=head2 3, notAtoaderDir

Not a Toader directory.

=head2 4, isaToaderDirErrored

L<Toader::isaToaderDir>->isaToaderDir errored.

=head2 5, rootIsAtoaderDir

"/" is the directory and it appears to be a Toader directory.

This is a major WTF and should not be even if '/.toader' exists.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::findToaderRoot


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

1; # End of Toader::findToaderRoot
