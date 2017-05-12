package Toader;

use warnings;
use strict;
use Toader::isaToaderDir;
use Toader::findToaderRoot;
use base 'Error::Helper';
use Toader::pathHelper;
use Toader::findToaderRoot;
use Toader::Directory;
use Sys::Hostname;
use Toader::Config;
use Toader::VCS;

=head1 NAME

Toader - A CMS meant to be integrated with a versioning system.

=head1 VERSION

Version 1.2.1

=cut

our $VERSION = '1.2.1';

=head1 SYNOPSIS

    use Toader;

    my $foo = Toader->new({dir=>$toaderDir});
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=head1 METHODS

=head2 new

=head3 args hash ref

=head4 dir

This is the directory to intiate in.

This is required and needs to be a Toader directory.

=head4 outputdir

This is the output directory to use when rendering.

    my $toader=Toader->new(\%args);
    if ( $toader->error ){
        warn('Error:'.$toader->error.':'.$toader->errorFlag.': '.$toader->errorString);
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
			  isatd=>Toader::isaToaderDir->new,
			  perror=>undef,
			  outputdir=>undef,
			  errorExtra=>{
				  flags=>{
					  1=>'noDirSpecified',
					  2=>'isaToaderDirError',
					  3=>'notAtoaderDir',
					  4=>'outputIsAtoaderDir',
					  5=>'DirectoryInitError',
					  6=>'ConfigInitError',
					  7=>'PathHerlerInitError',
					  8=>'VCSinitError',
					  9=>'VCSusableError',
				  },
			  },
			  };
	bless $self;

	#makes sure we have a directory
	if (!defined( $args{dir} )) {
		$self->{error}=1;
		$self->{errorString}='No directory specified';
		$self->warn;
		return $self;
	}

	#makes sure it is a Toader directory
	my $results=$self->{isatd}->isaToaderDir($args{dir});
	if ($self->{isatd}->error) {
		$self->{error}=2;
		$self->{errorString}='$self->{isatd}->isaToaderDir($args{dir}) errored. error='.$self->{isatd}->error.
			' errorString="'.$self->{isatd}->errorString.'"';
		$self->warn;
		return $self;
	}
	if (!$results) {
		$self->{error}=3;
		$self->{errorString}='"'.$args{dir}.'" is not a Toader directory';
		$self->warn;
		return $self;
	}
	$self->{dir}=$args{dir};

	#finds the Toader root
	my $findroot=Toader::findToaderRoot->new;
	$self->{dir}=$findroot->findToaderRoot( $self->{dir} );

	#make sure it is clean
	$self->{pathHelper}=Toader::pathHelper->new( $self->{dir} );
	$self->{dir}=$self->{pathHelper}->cleanup( $self->{dir} );

	#handles the output directory if specified
	if( defined( $args{outputdir} ) ){
		$results=$self->{isatd}->isaToaderDir( $args{outputdir} );
		if( $self->{isatd}->error ){
			$self->{perror}=1;
			$self->{error}=2;
			$self->{errorString}='$self->{isatd}->isaToaderDir($args{outputdir}) errored. error='
				.$self->{isatd}->error.' errorString="'.$self->{isatd}->errorString.'"';
			$self->warn;
			return $self;
		}
		if ($results) {
			$self->{perror}=1;
			$self->{error}=4;
			$self->{errorString}='"'.$args{outputdir}.'" can not be used as a out put directory'.
				' as it is a Toader directory';
			$self->warn;
			return $self;
		}
		$self->{outputdir}=$args{outputdir};
	}

	# intialize the VCS integration
	$self->{vcs}=Toader::VCS->new($self);
	if ( $self->{vcs}->error ){
		$self->{perror}=1;
		$self->{error}=8;
		$self->{errorString}='Failed to initiate VCS. error="'.
			$self->{vcs}->error.'" errorString="'.$self->{vcs}->errorString.'"';
		$self->warn;
		return $self;
	}
	# VCS usable
	$self->{VCSusable}=$self->{vcs}->usable;
	if ( $self->{vcs}->error ){
		$self->{perror}=1;
		$self->{error}=9;
		$self->{errorString}='Toader::VCS->usable errored. error="'.
			$self->{vcs}->error.'" errorString="'.$self->{vcs}->errorString.'"';
		$self->warn;
		return $self;
	}

	# initialize the config
	$self->{config}=Toader::Config->new( $self );
	if ( $self->{config}->error ){
		$self->{perror}=1;
		$self->{error}=6;
		$self->{errorString}='Failed to initialize Toader::Config. error="'
			.$self->{config}->error.'" errorString="'.$self->{config}->errorString.'"';
		$self->warn;
		return $self;
	}

	# initialize the path helper
	$self->{ph}=Toader::pathHelper->new( $self->{dir} );
	if ( $self->{ph}->error ){
		$self->{perror}=1;
		$self->{error}=7;
		$self->{errorString}='Failed to initiate pathHelper. error="'.
			$self->{ph}->error.'" errorString="'.$self->{ph}->errorString.'"';
		$self->warn;
		return $self;
	}

	return $self;
}

=head2 getConfig

This returns the L<Config::Tiny> object storing the Toader
config.

There is no need to do any error checking as long as
Toader new suceeded with out issue.

    my $config=$toader->getConfig;
    if ( $toader->error ){
        warn('Error:'.$toader->error.':'.$toader->errorFlag.': '.$toader->errorString);
    }

=cut

sub getConfig{
	my $self=$_[0];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	return $self->{config}->getConfig;
}

=head2 getConfigObj

This returns the L<Toader::Config> object that was created
when this module was created.

    my $configObj=$toader->getConfigObj;
    if ( $toader->error ){
        warn('Error:'.$toader->error.':'.$toader->errorFlag.': '.$toader->errorString);
    }

=cut

sub getConfigObj{
	my $self=$_[0];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	return $self->{config};
}

=head2 getDirObj

This returns a L<Toader::Directory> object with the directory
set to the Toader root.

    my $dirobj=$toader->getDirObj;
    if ( $toader->error ){
        warn('Error:'.$toader->error.':'.$toader->errorFlag.': '.$toader->errorString);
    }

=cut

sub getDirObj{
	my $self=$_[0];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	my $dirobj=Toader::Directory->new( $self );

	$dirobj->dirSet( $self->{dir} );
	if ( $dirobj->error ){
		$self->{error}=5;
		$self->{errorString}='Could not set the directory for the newly created '.
			'Toader::Directory object to "'.$self->{dir}.'"';
		$self->warn;
		return undef;
	}

	return $dirobj;
}

=head2 getOutputDir

This returns the output directory.

If none is specified, undef is returned.

There is no reason for check for errors if new
succeeded with out error.

    my $outputdir=$toader->getOutputDir;
    if( defined( $outputdir ) ){
        print "outputdir='".$outputdir."'\n";
    }else{
        print "No output directory defined.\n";
    }

=cut

sub getOutputDir{
	my $self=$_[0];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	return $self->{outputdir};
}

=head2 getPathHelper

This returns a L<Toader::pathHelper> object for this Toader object.

If the Toader object initialized with out issue, then there is no reason
to check for an error.

    my $pathHelper=$toader->getPathHelper;
    if ( $toader->error ){
        warn('Error:'.$toader->error.':'.$toader->errorFlag.': '.$toader->errorString);
    }

=cut

sub getPathHelper{
	my $self=$_[0];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	return $self->{ph};
}

=head2 getRootDir

This returns the root directory for what Toader is using.

If the returned value is not defined, one has not been set yet.

    my $rootdir=$toader->getRootDir;
    if ( $foo->error ){
        warn('Error:'.$foo->error.':'.$toader->errorFlag.': '.$foo->errorString);
    }

=cut

sub getRootDir{
	my $self=$_[0];
	my $dir=$_[1];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	return $self->{dir};
}

=head2 setOutputDir

This sets the output directory.

    $foo->setOutputDir( $dir );
    if ( $foo->error ){
        warn('Error:'.$foo->error.':'.$toader->errorFlag.': '.$foo->errorString);
    }

=cut

sub setOutputDir{
	my $self=$_[0];
	my $dir=$_[1];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	#makes sure it is a directory
	if ( ! defined($dir) ){
		$self->{error}=1;
		$self->{errorString}='No directory defined';
		$self->warn;
		return undef;
	}

	my $results=$self->{isatd}->isaToaderDir( $dir );
	if( $self->{isatd}->error ){
		$self->{perror}=1;
		$self->{error}=2;
		$self->{errorString}='$self->{isatd}->isaToaderDir($args{outputdir}) errored. error='
			.$self->{isatd}->error.' errorString="'.$self->{isatd}->errorString.'"';
		$self->warn;
		return undef;
	}
	if ($results) {
		$self->{error}=4;
		$self->{errorString}='"'.$dir.'" can not be used as a out put directory'.
			'as it is a Toader directory';
		$self->warn;
		return undef;
	}
	$self->{outputdir}=$dir;

	return 1;
}

=head2 getVCS

This returns to the L<Toader::VCS> object.

    my $vcs=$toader->getVCS;
    if ( $toader->error ){
        warn('Error:'.$toader->error.':'.$toader->errorFlag.': '.$toader->errorString);
    }

=cut

sub getVCS{
	my $self=$_[0];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	return $self->{vcs};
}

=head1 ERROR CODES

=head2 1, noDirSpecified

No directory specified.

=head2 2, isaToaderDirError

Toader::isaToaderDir->isaToaderDir errored.

=head2 3, notAtoaderDir

The specified directory is not a Toader directory.

=head2 4, outputIsAtoaderDir

The specified output directory is a Toader directory.

=head2 5, DirectoryInitError

Could initialize the L<Toader::Directory> object.

=head2 6, ConfigInitError

Failed to initialize L<Toader::Config>.

=head2 7, PathHerlerInitError

Failed to initiate the path helper.

=head2 8, VCSinitError

Failed to initiate VCS integration.

=head2 9, VCSusableError

Toader::VCS->usable errored.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader


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

Copyright 2013 Zane C. Bowers-Hadley

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Toader
