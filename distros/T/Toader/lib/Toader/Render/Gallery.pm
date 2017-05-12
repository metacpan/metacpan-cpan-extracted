package Toader::Render::Gallery;

use warnings;
use strict;
use base 'Error::Helper';
use Toader::Render::General;
use Toader::Templates;
use Date::Parse;
use Toader::pathHelper;
use File::Path qw(make_path mkpath);
use File::Copy;
use File::Find;
use GD::Thumbnail;

=head1 NAME

Toader::Render::Gallery - This renders a Toader::Gallery object.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

=head1 METHODS

=head2 new

This initiates the object.

=head3 args hash ref

=head4 obj

This is the L<Toader::Gallery> object to render.

=head4 toader

This is the L<Toader> object to use.

	my $foo=Toader::Render::Gallery->new(\%args);
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
			  toDir=>'../',
			  errorExtra=>{
				  flags=>{
					  1=>'noObj',
					  2=>'noToaderObj',
					  3=>'objPerror',
					  4=>'toaderPerror',
					  5=>'noDirSet',
					  6=>'pathhelperInitErroered',
					  7=>'realative2rootErrored',
					  9=>'notUnderSrcPath',
					  10=>'dirStartsWithPeriod',
					  11=>'srcPathDoesNotExist',
					  12=>'outputDirDoesNotExist',
					  13=>'srcDirOpenFailed',
					  14=>'smallThumbFileOpenFailed',
					  15=>'smallThumbPathCreationFailed',
					  16=>'largeThumbPathCreationFailed',
					  17=>'generalInitErrored',
					  18=>'renderTemplateErrored',
					  19=>'pathCreationFailed',
					  20=>'pathCleanupFailed',
				  },
			  },
			  };
	bless $self;

	if ( defined( $args{toDir} ) ){
		$self->{toDir}=$args{toDir};
	}

	#make sure we have a Toader::Gallery object.
	if ( ! defined( $args{obj} ) ){
		$self->{perror}=1;
		$self->{error}=1;
		$self->{errorString}='Nothing defined for the Toader::Gallery object';
		$self->warn;
		return $self;
	}
	if ( ref( $args{obj} ) ne 'Toader::Gallery' ){
        $self->{perror}=1;
        $self->{error}=1;
        $self->{errorString}='The specified object is not a Toader::Gallery object, but a "'.
			ref( $args{obj} ).'"';
		$self->warn;
		return $self;
	}
	$self->{obj}=$args{obj};

	#make sure the object does not have a permanent error set
	if( ! $self->{obj}->errorblank ){
		$self->{perror}=1;
		$self->{error}=3;
		$self->{errorString}='The Toader::Gallery object has a permanent error set';
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

    #make sure the object does not have a permanent error set
    if( ! $self->{toader}->errorblank ){
        $self->{perror}=1;
        $self->{error}=4;
        $self->{errorString}='The Toader object has a permanent error set';
        $self->warn;
        return $self;
    }

	#make sure a directory is set
    if( ! defined( $self->{obj}->dirGet ) ){
		$self->{perror}=1;
		$self->{error}=5;
		$self->{errorString}='The Toader::Gallery object does not have a directory set';
		$self->warn;
		return $self;
	}
	$self->{dir}=$self->{obj}->dirGet;

	#initialize this here for simplicity
	$self->{t}=Toader::Templates->new({ dir=>$self->{obj}->dirGet });

	#initialize the general object here for simplicity
	$self->{g}=Toader::Render::General->new(
		{
			toader=>$self->{toader},
            self=>\$self,
			obj=>$self->{obj},
			fullURL=>1,
			url=>$self->{obj}->outputURLget,
		}
		);
	if ( $self->{g}->error ){
		$self->{perror}=1;
		$self->{error}=17;
		$self->{errorString}='Failed to initialize Toader::Render::General';
		$self->warn;
		return undef;
	}

	#initialize the Toader::pathHelper
	$self->{ph}=Toader::pathHelper->new( $self->{dir} );
	if ( $self->{ph}->error ){
		$self->{perror}=1;
		$self->{error}=6;
		$self->{errorString}='Failed to initiate pathHelper. error="'.
			$self->{ph}->error.'" errorString="'.$self->{ph}->errorString.'"';
		$self->warn;
		return $self;
	}	

	#gets the r2r for the object
	$self->{r2r}=$self->{ph}->relative2root( $self->{dir} );
	if ( $self->{ph}->error ){
		$self->{perror}=1;
		$self->{error}=7;
		$self->{errorString}='pathHelper failed to find the relative2root path for "'.
			$self->{odir}.'"';
		$self->warn;
		return $self;
	}

	return $self;
}

=head2 render

This is just here for compatibiltiy reasons. It returns true.

=cut

sub render{
	my $self=$_[0];
	
	if ( ! $self->errorblank ){
		return undef;
	}

	my $updateIndexes=$self->{obj}->renderUpdateIndexesGet;
	my $updateScaled=$self->{obj}->renderUpdateScaledGet;
	my $updateDetails=$self->{obj}->renderUpdateDetailsGet;

	if ( $updateIndexes ){
		$self->updateIndex;
		if ( $self->error ){
			$self->warnString('Failed to update indexes');
			return undef;
		}
	}

	if ( $updateScaled ){
		$self->updateScaled;
		if ( $self->error ){
			$self->warnString('Failed to update scaled images');
			return undef;
		}
	}

	if ( $updateDetails ){
		$self->updateDetails;
		if ( $self->error ){
			$self->warnString('Failed to update details');
			return undef;
		}
	}

	return 1;
}

=head2 updateDetails

=cut

sub updateDetails{
    my $self=$_[0];

    #make sure we are error clean
    if ( ! $self->errorblank ){
        return undef;
    }
	
	#gets the various paths
	my $srcPath=$self->{obj}->srcPathGet;
	my $outputPath=$self->{obj}->outputPathGet;
	
	#make sure it does not have multiple //
	$srcPath=$srcPath.'/';
	$srcPath=~s/\/*\//\//g;

	#gets the relative path from the source directory
	my $regexp='^'.quotemeta( $srcPath );

	#make sure the source directory exists
	if ( ! -d $srcPath ){
		$self->{error}=11;
		$self->{errorString}='The source directory,"'.$srcPath.'", does not exist';
		$self->warn;
		return undef;
	}
	#make sure the output directory exists
	if ( ! -d $outputPath ){
		$self->{error}=12;
		$self->{errorString}='The output directory,"'.$outputPath.'", does not exist';
		$self->warn;
		return undef;
	}

	#finds the images and directories
	my %found;
	find(sub{
        #makes sure that it is not a hiddten item
        if (
			( $File::Find::name !~ /\/\./ ) &&
			( -f $File::Find::name ) &&
			(
			 ( $File::Find::name =~ /jpg$/i ) ||
			 ( $File::Find::name =~ /jpeg$/i ) ||
			 ( $File::Find::name =~ /png$/i ) ||
			 ( $File::Find::name =~ /gif$/i )
			)
			){
			
			if ( ! defined( $found{$File::Find::dir} ) ){
				$found{$File::Find::dir}={};

				$found{$File::Find::dir}{'images'}=[];

				$found{$File::Find::dir}{'gdir'}=$File::Find::dir;
				$found{$File::Find::dir}{'gdir'}=~s/$regexp//;
	
				$found{$File::Find::dir}{'outputDir'}=$outputPath.'/.toader-gallery/html/'.$found{$File::Find::dir}{'gdir'};

				$found{$File::Find::dir}{'outputDir'}=~s/\/\/*/\//g;

			}

			push( @{ $found{$File::Find::dir}{'images'} }, $_ );

			};
		 }
		 , $srcPath);
	my @dirs=keys( %found );

	#make sure all the directories exist
	my $int=0;
	while( defined( $dirs[$int] ) ){
		if ( ! -e $found{ $dirs[$int] }{'outputDir'}  ){
			if ( ! mkpath( $found{ $dirs[$int] }{'outputDir'} ) 
				){
				$self->{error}=19;
				$self->{errorString}='Failed to create the output directory "'.
					$found{ $dirs[$int] }{'outputDir'}.'"';
				$self->warn;
				return undef;
			}
		}
		
		$int++;
	}

    #process each image listed in the directory
	$int=0;
	while( defined( $dirs[$int] ) ){
		my $gdir=$found{ $dirs[$int] }{'gdir'};

		#process each image
		my $imageInt=0;
		my $image;
		while( defined( $found{ $dirs[$int] }{'images'}[$imageInt] ) ){

			$image=$found{ $dirs[$int] }{'images'}[$imageInt];

			my $content=$self->{g}->galleryImageLarge( undef, $gdir, $image );
			if ( $self->{g}->error ){
				$self->{error}=21;
				$self->{errorString}='Failed to render the HTML for a description of "'.$gdir.'/'.$image.'"';
				$self->warn;
				return undef;
			}

			$self->{g}->locationSubSet( $self->{g}->galleryLocationbar( $gdir, $image ) );
			
			my $rendered=$self->{t}->fill_in(
				'pageGallery',
				{
					obj=>\$self->{obj},
					c=>\$self->{toader}->getConfig,
					self=>\$self,
					toader=>\$self->{toader},
					g=>\$self->{g},
					dir=>$self->{r2r},
					gdir=>$gdir,
					image=>$image,
					content=>$content,
				}
				);
			if ( $self->{t}->error ){
				$self->{error}=18;
				$self->{errorString}='Failed to fill in the template. error="'.
					$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
				$self->warn;
				return undef;
			}
			
			my $detailFile=$outputPath.'/.toader-gallery/html/'.$gdir.'/'.$image.'.html';
			
			my $fh;
			if ( ! open( $fh, '>', $detailFile ) ){
				$self->{error}=19;
				$self->{errorString}='Failed to open "'.$detailFile.'" for writing';
				$self->warn;
				return undef;
			}
			print $fh $rendered;
			close $fh;

			$imageInt++;
		}		
		
		$int++;
	}

	return 1;
}

=head2 updateIndexes

This updates the index.html file for a gallery directory.

Two arguments are taken. The first and required is the directory
act upon. The second and optional is if it should be recursive or
not, which defaults to false.

=cut

sub updateIndexes{
    my $self=$_[0];
    my $dir=$_[1];
    my $recursive=$_[2];

    #make sure we are error clean
    if ( ! $self->errorblank ){
        return undef;
    }

	#gets the various paths
	my $srcPath=$self->{obj}->srcPathGet;
	my $outputPath=$self->{obj}->outputPathGet;
	
	#default to the source directory if none is specified
	if ( ! defined( $dir ) ){
		$dir=$srcPath;
	}

	#make sure the directory is not hidden any place in the path
	if ( $dir =~ /\/\./ ){
		$self->{eror}=10;
		$self->{errorString}='The specified directory,"'.$dir.'", contains a directory that starts with a period';
		$self->warn;
		return undef;
	}
	
	#make sure all end in / and don't have any multiple //
	$dir=$dir.'/';
	$dir=~s/\/*\//\//g;
	$srcPath=$srcPath.'/';
	$srcPath=~s/\/*\//\//g;

	#make sure that the directory is under/is the source directory
	my $regexp='^'.quotemeta( $srcPath );
	if ( $dir !~ /$regexp/ ){
		$self->{error}=9;
		$self->{errorString}='"'.$dir.'" is not under "'.$srcPath.'"';
		$self->warn;
		return undef;
	}

	#gets the relative path from the source directory
	my $relative=$dir;
	$relative=~s/$regexp//g;

	#make sure the source directory exists
	if ( ! -d $dir ){
		$self->{error}=11;
		$self->{errorString}='The source directory,"'.$dir.'", does not exist';
		$self->warn;
		return undef;
	}
	#make sure the output directory exists
	if ( ! -d $outputPath ){
		$self->{error}=12;
		$self->{errorString}='The output directory,"'.$outputPath.'", does not exist';
		$self->warn;
		return undef;
	}
	
	#opens the directory and reads everything not starting with a period
	my $dh;
	if ( ! opendir( $dh, $dir ) ){
		$self->{error}=13;
		$self->{errorString}='Failed to open the source directory';
		$self->warn;
		return undef;
	}
	my @dirList=grep( !/^\./, readdir($dh) );
	closedir( $dh );

	@dirList=sort( @dirList );

	#process each item in listed in the directory
	my $int=0;
	my @smallDivs;
	my @dirDivs;
	while( defined( $dirList[$int] ) ){
		my $path=$dir.$dirList[$int];

		#if it is a directory, process it if we are doing it recursively
		if ( -d $path &&
			 $recursive
			){
			$self->updateIndexes( $path, 1 );

			my $link=$self->{g}->galleryLink( undef, $relative.'/'.$dirList[$int], $dirList[$int].'/');
			
            my $rendered=$self->{t}->fill_in(
                'galleryDir',
                {
                    obj=>\$self->{obj},
                    c=>\$self->{toader}->getConfig,
                    self=>\$self,
                    toader=>\$self->{toader},
                    g=>\$self->{g},
                    dir=>$self->{r2r},
					gdir=>$relative.'/'.$dirList[$int],
					link=>$link,
                }
                );
            if ( $self->{t}->error ){
                $self->{error}=18;
                $self->{errorString}='Failed to fill in the template. error="'.
                    $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
                $self->warn;
                return undef;
            }
			
			push( @dirDivs, $rendered );
		}
		#scale it if it is a image
		if (
			( -f $path ) &&
			(
			 ( $path =~ /[Jj][Pp][Gg]$/ ) ||
			 ( $path =~ /[Jj][Pp][Ee][Gg]$/ ) ||
			 ( $path =~ /[Pp][Nn][Gg]$/ ) ||
			 ( $path =~ /[Gg][Ii][Ff]$/ )
			)
			){
			
			my $rendered=$self->{t}->fill_in(
				'gallerySmallImage',
				{
					obj=>\$self->{obj},
					c=>\$self->{toader}->getConfig,
					self=>\$self,
					toader=>\$self->{toader},
					g=>\$self->{g},
					dir=>$self->{r2r},
					gdir=>$relative,
					image=>$dirList[$int],
				}
				);
			if ( $self->{t}->error ){
				$self->{error}=18;
				$self->{errorString}='Failed to fill in the template. error="'.
					$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
				$self->warn;
				return undef;
			}
			push( @smallDivs, $rendered );
		}
		
		$int++;
	}

	my $begin=$self->{t}->fill_in(
		'gallerySmallImageBegin',
		{
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self->{g},
			dir=>$self->{r2r},
			gdir=>$relative,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=18;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	my $join=$self->{t}->fill_in(
		'gallerySmallImageJoin',
		{
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self->{g},
			dir=>$self->{r2r},
			gdir=>$relative,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=18;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	my $end=$self->{t}->fill_in(
		'gallerySmallImageEnd',
		{
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self->{g},
			dir=>$self->{r2r},
			gdir=>$relative,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=18;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	
	my $content=$begin.join( $join, @dirDivs ).$join.join( $join, @smallDivs ).$end;

	$self->{g}->locationSubSet( $self->{g}->galleryLocationbar( $relative ) );

	my $page=$self->{t}->fill_in(
		'pageGallery',
		{
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self->{g},
			dir=>$self->{r2r},
			gdir=>$relative,
			content=>$content,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=18;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	my $indexDir=$outputPath.'/.toader-gallery/html/'.$relative;
	my $indexFile=$indexDir.'/index.html';
	my $indexFile2=$outputPath.'/index.html';

	if ( ! -d $indexDir ){
		if ( ! mkpath( $indexDir ) ){
			$self->{error}=19;
			$self->{errorString}='Failed to create the path, "'.$indexDir.'", for the index.html file';
			$self->warn;
			return undef;
		}
	}
	
	my $fh;
	if ( ! open( $fh, '>', $indexFile ) ){
		$self->{error}=19;
		$self->{errorString}='Failed to open "'.$indexFile.'" for writing';
		$self->warn;
		return undef;
	}
	print $fh $page;
	close $fh;

	$fh=undef;
	if ( ! open( $fh, '>', $indexFile2 ) ){
		$self->{error}=19;
		$self->{errorString}='Failed to open "'.$indexFile2.'" for writing';
		$self->warn;
		return undef;
	}
	print $fh $page;
	close $fh;

	return 1;
}

=head2 updateScaled

This updates scaled images. If a scaled image is found to
already exist, it does not rerocess it.

Two arguments are taken. The first and required is the directory
act upon. The second and optional is if it should be recursive or
not, which defaults to false.

=cut

sub updateScaled{
	my $self=$_[0];
	my $dir=$_[1];
	my $recursive=$_[2];

	#make sure we are error clean
	if ( ! $self->errorblank ){
		return undef;
	}
	
	#gets the various paths
	my $srcPath=$self->{obj}->srcPathGet;
	my $outputPath=$self->{obj}->outputPathGet;
	my $smallRes=$self->{obj}->resolutionSmallGet;
	my $largeRes=$self->{obj}->resolutionLargeGet;

	#default to the source directory if none is specified
	if ( ! defined( $dir ) ){
		$dir=$srcPath;
	}

	#make sure the directory is not hidden any place in the path
	if ( $dir =~ /\/\./ ){
		$self->{eror}=10;
		$self->{errorString}='The specified directory,"'.$dir.'", contains a directory that starts with a period';
		$self->warn;
		return undef;
	}

	#make sure all end in / and don't have any multiple //
	$dir=$dir.'/';
	$dir=~s/\/*\//\//g;
	$srcPath=$srcPath.'/';
	$srcPath=~s/\/*\//\//g;

	#make sure that the directory is under/is the source directory
	my $regexp='^'.quotemeta( $srcPath );
	if ( $dir !~ /$regexp/ ){
		$self->{error}=9;
		$self->{errorString}='"'.$dir.'" is not under "'.$srcPath.'"';
		$self->warn;
		return undef;
	}

	#gets the relative path from the source directory
	my $relative=$dir;
	$relative=~s/$regexp//g;

	#make sure the source directory exists
	if ( ! -d $dir ){
		$self->{error}=11;
		$self->{errorString}='The source directory,"'.$dir.'", does not exist';
		$self->warn;
		return undef;
	}

	#make sure the output directory exists
	if ( ! -d $outputPath ){
		$self->{error}=12;
		$self->{errorString}='The output directory,"'.$outputPath.'", does not exist';
		$self->warn;
		return undef;
	}

	#opens the directory and reads everything not starting with a period
	my $dh;
	if ( ! opendir( $dh, $dir ) ){
		$self->{error}=13;
		$self->{errorString}='Failed to open the source directory';
		$self->warn;
		return undef;
	}
	my @dirList=grep( !/^\./, readdir($dh) );
	closedir( $dh );

	#process each item in listed in the directory
	my $int=0;
	while( defined( $dirList[$int] ) ){
		my $path=$dir.$dirList[$int];
		
		#if it is a directory, process it if we are doing it recursively
		if ( -d $path &&
			 $recursive
			){
			$self->updateScaled( $path, 1 );
		}
		#scale it if it is a image
		if ( -f $path ){
			if (
				( $path =~ /[Jj][Pp][Gg]$/ ) ||
				( $path =~ /[Jj][Pp][Ee][Gg]$/ ) ||
				( $path =~ /[Pp][Nn][Gg]$/ ) ||
				( $path =~ /[Gg][Ii][Ff]$/ )
				){
				my $newpathSmall=$outputPath.'/.toader-gallery/small/'.$relative;
				my $newpathLarge=$outputPath.'/.toader-gallery/large/'.$relative;
				my $smallFile=$newpathSmall.'/'.$dirList[$int];
				my $largeFile=$newpathLarge.'/'.$dirList[$int];
				
				#the thumbnailing object
				my $thumb = GD::Thumbnail->new;
				
				if ( ! -d $newpathSmall ){
					if ( ! mkpath( $newpathSmall ) ){
						$self->{error}=15;
						$self->{errorString}='Failed to create the path for the small thumbnails';
						$self->warn;
						return undef;
					}
				}
				
				if ( ! -d $newpathLarge ){
					if ( ! mkpath( $newpathLarge ) ){
						$self->{error}=16;
						$self->{errorString}='Failed to create the path for the large thumbnails';
						$self->warn;
						return undef;
					}
				}
				
				#creates the small thumbnail
				my $smallImage;
				#GD::Thumbnail will bail out if it does not like something... so eval it to prevent that...
				my $toeval='$smallImage=$thumb->create($dir."/".$dirList[$int], $smallRes);';
				eval( $toeval );
				if ( defined( $smallImage ) ){
					my $fh;
					if ( ! open( $fh, '>', $smallFile ) ){
						$self->{error}=14;
						$self->{errorString}='Failed to open "'.$smallFile.'" for writing';
						$self->warn;
						return undef;
					}
					print $fh $smallImage;
					close $fh;
				}else{
					$self->warnString('Failed to create the small thumbnail for "'.$path.'"');
				}
				
				#creates the large thumbnail
				my $largeImage;
				#GD::Thumbnail will bail out if it does not like something... so eval it to prevent that...
				$toeval='$largeImage=$thumb->create($dir."/".$dirList[$int], $largeRes);';
				eval( $toeval );
				if (defined( $largeImage )){
					my $fh;
					if ( ! open( $fh, '>', $largeFile ) ){
						$self->{error}=14;
						$self->{errorString}='Failed to open "'.$smallFile.'" for writing';
						$self->warn;
						return undef;
					}
					print $fh $largeImage;
					close $fh;
				}else{
					$self->warnString('Failed to create the large thumbnail for "'.$path.'"');
				}
				
			}
			
		}
		
		
		$int++;
	}

}

=head1 ERROR CODES

=head2 1, noObj

No L<Toader::Gallery> object specified.

=head2 2, noToaderObj

No L<Toader> object specified.

=head2 3, objPerror

The L<Toader::Gallery> object has a permanent error set.

=head2 4, toaderPerror

The L<Toader> object has a permanent error set.

=head2 5, noDirSet

The L<Toader::Gallery> object does not have a directory set

=head2 6, pathhalperInitErrored

Failed to initialize a Toader::pathHelper.

=head2 7, realative2rootErrored

Failed to get relative to root.

=head2 9, notUnderSrcPath

The specified directory does not appear to be under the source path.

=head2 10, dirStartsWithPeriod

The specified directory contains a directory that starts with a period.

=head2 11, srcPathDoesNotExit

The source directory does not exist.

=head2 12, outputDirDoesNotExist

The output directory does not exist.

=head2 13, srcDirOpenFailed

Could not open the source directory.

=head2 14, smallThumbFileOpenFailed

Failed to open the small thumbnail file.

=head2 15, smallThumbPathCreationFailed

Failed to create the new path for the small thumbnails.

=head2 16, largeThumbPathCreationFailed

Failed to create the new path for the large thumbnails.

=head2 17, generalInitErrored

Failed to initialize L<Toader::Render::General>.

=head2 18, renderTemplateErrored

Failed to render a template.

=head2 19, pathCreationFailed

Failed to create the new path for the index.html.

=head2 20, pathCleanupFailed

Path cleanup failed.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make
changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Render::AutoDoc

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

Copyright 2012. Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Toader::Render::AutoDoc
