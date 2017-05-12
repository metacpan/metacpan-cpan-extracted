package Toader::AutoDoc;

use warnings;
use strict;
use base 'Error::Helper';
use Toader::isaToaderDir;
use Script::isAperlScript;

=head1 NAME

Toader::AutoDoc - Automatically build documentation from specified directories.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 METHODS

=head2 new

This initiates the object.

One argument is required and it is a L<Toader> object.

    my $foo = Toader::AutoDoc->new( $toader );
    if ( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub new{
	my $toader=$_[1];

	my $self={
			  error=>undef,
			  errorString=>'',
			  perror=>undef,
			  dir=>undef,
			  toader=>undef,
			  errorExtra=>{
				  flags=>{
					  1=>'noDirSpecified',
					  2=>'notAtoaderDir',
					  3=>'pathsFileOpenFailed',
					  4=>'noDirSet',
					  5=>'noPathSpecified',
					  6=>'invalidPath',
					  7=>'dirCreationFailed',
					  8=>'notAtoaderObj',
					  9=>'getVCSerrored',
					  10=>'VCSusableErrored',
					  11=>'underVCSerrored',
					  12=>'VCSaddErrored',
					  13=>'noToaderObj',
				  },
			  },
			  VCSusable=>0,
			  };
	bless $self;

	#if we have a Toader object, reel it in
	if ( ! defined( $toader ) ){
		$self->{perror}=1;
		$self->{error}=13;
		$self->{errorString}='No Toader object specified';
		$self->warn;
		return $self;
	}
	if ( ref( $toader ) ne "Toader" ){
		$self->{perror}=1;
		$self->{error}=8;
		$self->{errorString}='The object specified is a "'.ref($toader).'"';
		$self->warn;
		return $self;
	}
	$self->{toader}=$toader;

	#gets the Toader::VCS object
	$self->{vcs}=$self->{toader}->getVCS;
	if ( $toader->error ){
		$self->{perror}=1;
		$self->{error}=9;
		$self->{errorString}='Toader->getVCS errored. error="'.
			$self->{toader}->error.'" errorString="'.$self->{toader}->errorString.'"';
		$self->warn;
		return $self;
	}
	
	#checks if VCS is usable
	$self->{VCSusable}=$self->{vcs}->usable;
	if ( $self->{vcs}->error ){
		$self->{perror}=1;
		$self->{error}=10;
		$self->{errorString}='Toader::VCS->usable errored. error="'.
			$self->{toader}->error.'" errorString="'.$self->{toader}->errorString.'"';
		$self->warn;
		return $self;
	}

	return $self;
}

=head2 dirGet

This gets L<Toader> directory this entry is associated with.

This will only error if a permanent error is set.

This will return undef if no directory has been set.

    my $dir=$foo->dirGet;
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub dirGet{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	return $self->{dir};
}

=head2 dirSet

This sets L<Toader> directory this entry is associated with.

One argument is taken and it is the L<Toader> directory to set it to.

    my $dir=$foo->dirSet($toaderDirectory);
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub dirSet{
	my $self=$_[0];
	my $dir=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	#make sure a directory has been specified
	if (!defined($dir)) {
		$self->{error}=1;
		$self->{errorString}='No directory specified.';
		$self->warn;
		return undef;
	}

	#cleans up the naming
	my $pathHelper=Toader::pathHelper->new($dir);
	$dir=$pathHelper->cleanup($dir);

	#checks if the directory is Toader directory or not
	my $isatd=Toader::isaToaderDir->new;
    my $returned=$isatd->isaToaderDir($dir);
	if (! $returned ) {
		$self->{error}=2;
		$self->{errorString}='"'.$dir.'" is not a Toader directory.';
		$self->warn;
		return undef;
	}

	$self->{dir}=$dir;

	return 1;
}

=head2 findDocs

Finds documentation under the specified paths.

=cut

sub findDocs{
    my $self=$_[0];
	my $cp=$_[1];

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $self->{dir} ) ){
        $self->{error}=4;
        $self->{errorString}='No directory is set';
        $self->warn;
        return undef;
    }

	#gets the paths
	my @paths;
	if ( ! defined( $cp ) ){
		# get the paths
		@paths=$self->pathsGet;
		if ( $self->error ){
			$self->warnString('Failed to get the paths');
			return undef;
		}
		$cp='';
	}else{
		my $dh;
		if ( ! opendir( $dh, $self->{dir}.'/'.$cp ) ){
			$self->warnString('Failed to open the directory "'.$self->{dir}.'/'.$cp.'"');
			return undef;
		}
		@paths=grep( !/^\./, readdir( $dh ) );
		closedir( $dh );
	}
	
	#process each path
	my $int=0;
	my @toreturn;
	while( defined( $paths[$int] ) ){
		my $item=$self->{dir}.'/'.$cp.'/'.$paths[$int];

		my $checker=Script::isAperlScript->new({
			env=>1,
			any=>1,
											   });
		
		#processes any files found
		if ( 
			( -f $item ) &&
			(
			 ( $item =~ /\/README$/ ) ||
			 ( $item =~ /\/Changes$/ ) ||
			 ( $item =~ /\/TODO$/ ) ||
			 ( $item =~ /\.pm$/ ) ||
			 ( $item =~ /\.[Pp][Oo][Dd]$/ ) ||
			 ( $item =~ /\.[Tt][Xx][Tt]$/ ) ||
			 ( $checker->isAperlScript( $item ) )
			 )
			){
			push( @toreturn, $cp.'/'.$paths[$int] );
		}
		
		#process any directories found
		if ( -d $item ){
			my @returned=$self->findDocs( $cp.'/'.$paths[$int] );
			if ( defined( $returned[0] ) ){
				push( @toreturn, @returned );
			}
		}

		$int++;
	}

	#make sure there are no //
	if ( $cp eq '' ){
		$int=0;
		while( defined( $toreturn[$int] ) ){
			$toreturn[$int]=~s/\/\//\//g;
			$toreturn[$int]=~s/^\///;

			$int++;
		}
	}

	#removes any potential dupes...
    my %found;
    $int=0;
	while ( defined( $toreturn[$int] ) ){
		$found{ $toreturn[$int] }='';

		$int++;
	}

	return keys(%found);
}

=head2 pathAdd

This adds a new path.



=cut

sub pathAdd{
	my $self=$_[0];
	my $path=$_[1];

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $self->{dir} ) ){
        $self->{error}=4;
        $self->{errorString}='No directory is set';
        $self->warn;
        return undef;
    }

	if ( ! defined( $path ) ){
		$self->{error}=5;
		$self->{errorString}='No path specified';
		$self->warn;
		return undef;
	}

	if ( ! $self->validPath( $path ) ){
		$self->{error}=6;
		$self->{errorString}='Invalid path specified';
		$self->warn;
		return undef;
	}

	my @paths=$self->pathsGet;
	if ( $self->error ){
		$self->warnString('Failed to get the current paths');
		return undef;
	}

	push( @paths, $path );

	$self->pathsSet( \@paths );
	if ( $self->error ){
		$self->warnString('Failed to set save the paths list');
		return undef;
	}

	return 1;
}

=head2 pathRemove

Remove a specified path.

=cut

sub pathRemove{
    my $self=$_[0];
	my $path=$_[1];

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $self->{dir} ) ){
        $self->{error}=4;
        $self->{errorString}='No directory is set';
        $self->warn;
        return undef;
    }

	if ( ! defined( $path ) ){
		$self->{error}='5';
		$self->{errorString}='No path specified';
		$self->warn;
		return undef;
	}

    my @paths=$self->pathsGet;
    if ( $self->error ){
        $self->warnString('Failed to get the current paths');
        return undef;
    }

	#
	my $int=0;
	my @newpaths;
	while ( defined( $paths[$int] ) ){
		if ( $paths[$int] ne $path ){
			push( @newpaths, $paths[$int] );
		}

		$int++;
	}

    $self->pathsSet( \@newpaths );
    if ( $self->error ){
        $self->warnString('Failed to set save the paths list');
        return undef;
    }

	return 1;
}

=head2 pathsGet

This gets the list of what is to by handled.

No arguments are taken.

The returned value is a list. Each item in the
list is a path to recursively search.

    my @paths=$foo->pathsGet;

=cut

sub pathsGet{
    my $self=$_[0];

    if (!$self->errorblank){
        return undef;
    }

	if ( ! defined( $self->{dir} ) ){
		$self->{error}=4;
		$self->{errorString}='No directory is set';
		$self->warn;
		return undef;
	}

	my $file=$self->{dir}.'/.toader/autodoc/dirs';

	#it does not exist... no directories to search
	if ( ! -f $file ){
		return;
	}

	#read the file
	my $fh;
	if ( ! open( $fh, '<', $file ) ){
		$self->{error}=3;
		$self->{errorString}='Failed to open "'.$file.'"';
		$self->warn;
		return undef;
	}
	my $line=<$fh>;
	my @data;
	while( defined( $line ) ){
		chomp( $line );
		if ( $line ne '' ){
			push( @data, $line );
		}

		$line=<$fh>;
	}
	close $fh;

	return @data;
}

=head2 pathsSet

This sets the AutoDoc paths for a directory.

One argument is required and that is a array ref of
relative paths.

    $foo->pathsSet( \@paths );

=cut

sub pathsSet{
	my $self=$_[0];
	my @paths;
	if ( defined( $_[1] ) ){
		@paths=@{ $_[1] };
	}

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $self->{dir} ) ){
        $self->{error}=4;
        $self->{errorString}='No directory is set';
        $self->warn;
        return undef;
    }

	my $dir=$self->{dir}.'/.toader/autodoc/';
    my $file=$self->{dir}.'/.toader/autodoc/dirs';

	#try to create to autodoc config directory
	if ( ! -e $dir ){
		if ( ! mkdir( $dir ) ){
			$self->{error}=7;
			$self->{errorString}='Failed to create to Autodoc configuration directory, "'.$dir.'",';
			$self->warn;
			return undef;
		}
	}

	my $data=join("\n", @paths)."\n";
	
	#open and write it
	my $fh;
    if ( ! open( $fh, '>', $file ) ){
        $self->{error}=3;
        $self->{errorString}='Failed to open "'.$file.'"';
        $self->warn;
        return undef;
    }
	print $fh $data;
    close $fh;

	#if VCS is not usable, stop here
	if ( ! $self->{VCSusable} ){
		return 1;
	}

	#if it is under VCS, we have nothing to do
	my $underVCS=$self->{vcs}->underVCS($file);
	if ( $self->{vcs}->error ){
		$self->{error}=11;
		$self->{errorString}='Toader::VCS->underVCS errored. error="'.
			$self->{vcs}->error.'" errorString="'.$self->{vcs}->errorString.'"';
		$self->warn;
		return undef;
	}
	if ( $underVCS ){
		return 1;
	}

	#add it as if we reach here it is not under VCS and VCS is being used
	$self->{vcs}->add( $file );
	if ( $self->{vcs}->error ){
		$self->{error}=12;
		$self->{errorString}='Toader::VCS->add errored. error="'.
			$self->{vcs}->error.'" errorString="'.$self->{vcs}->errorString.'"';
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 validPath

This verifies that a path is valid.

It makes sure it defined and does not match any thing below.

    ^..\/
    \/..\/
	\/..$

=cut

sub validPath{
	my $path=$_[1];

	if ( ! defined( $path ) ){
		return 0;
	}

	if ( $path =~ /^\.\.\// ){
		return 0;
	}

	if ( $path =~ /\/\.\.\// ){
		return 0;
	}

	if ( $path =~ /\/.\.$/ ){
		return 0;
	}

	return 1;
}

=head1 REQUIRED RENDERING METHODS

=head2 filesDir

This returns the file directory for the object.

This is not a full path, but a partial path that should
be appended the directory current directory being outputted to.

=cut

sub filesDir{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	return $self->renderDir.'/.files';
}

=head2 locationID

This returns the location ID.

This one requires the object to be initialized.

=cut

sub locationID{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	return 'Documentation';
}

=head2 renderDir

This is the directory that it will be rendered to.

The base directory that will be used for rendering.

=cut

sub renderDir{
	return '.autodoc';
}

=head2 renderUsing

This returns the module to use for rendering.

    my $module=$foo->renderUsing;

=cut

sub renderUsing{
    return 'Toader::Render::AutoDoc';
}

=head2 toaderRenderable

This method returns true and marks it as being L<Toader>
renderable.

=cut

sub toaderRenderable{
	return 1;
}

=head2 toDir

This returns the relative path to the object.

This is not a full path, but a partial path that should
be appended the directory current directory being outputted to.

=cut

sub toDir{
    my $self=$_[0];

    if (!$self->errorblank){
        return undef;
    }

    return $self->renderDir;
}

=head1 ERROR CODES

=head2 1, noDirSpecified

No directory specified.

=head2 2, notAtoaderDir

The directory is not a Toader directory.

=head2 3, pathsFileOpenFailed

Failed to open the paths file.

=head2 4, noDirSet

No directory set.

=head2 5, noPathSpecified

No path specified.

=head2 6, invalidPath

Invalid path.

=head2 7, dirCreationFailed

The AutoDoc configuration directory could not be created.

=head2 8, notAtoaderObj

The specified object is not a Toader object.

=head2 9, getVCSerrored

L<Toader::VCS>->getVCS errored.

=head2 10, VCSusableFailedErrored

L<Toader::VCS>->VCSusable errored.

=head2 11, underVCSerrored

L<Toader::VCS>->underVCS errored.

=head2 12, VCSaddErrored

L<Toader::VCS>->add errored.

=head2 13, noToaderObj

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::AutoDoc


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

1; # End of Toader::AutoDoc
