package Toader::Render::Directory;

use warnings;
use strict;
use base 'Error::Helper';
use Toader::Templates;
use Date::Parse;
use File::Path qw(make_path);
use Toader::Render::Directory::Cleanup;
use Toader::Render::General;

=head1 NAME

Toader::Render::Directory - Renders a Toader::Directory object.

=head1 VERSION

Version 0.1.1

=cut

our $VERSION = '0.1.1';

=head1 SYNOPSIS

=head1 METHODS

=head2 new

This initiates the object.

=head3 args hash ref

=head4 obj

This is the L<Toader::Directory> object to render.

=head4 toader

This is the L<Toader> object to use.

=head2 toDir

This is the value used to get from the directory it is being
rendered in back to directory storing stuff for that directory. By
default this is './'.

	my $foo=Toader::Render::Directory->new(\%args);
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
			  toDir=>'./',
			  errorExtra=>{
				  flags=>{
					  1=>'noObj',
					  2=>'noToaderObj',
					  3=>'objPerror',
					  4=>'toaderObjPerror',
					  5=>'noDirSet',
					  6=>'cleanupErrored',
					  7=>'generalInitErrored',
				  },
			  },
			  };
	bless $self;

	if ( defined( $args{toDir} ) ){
		$self->{toDir}=$args{toDir};
	}

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
        $self->{errorString}='The specified object is not a Toader::Directory object, but a "'.
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

	#initialize this here for simplicity
	$self->{t}=Toader::Templates->new({ 
		dir=>$self->{obj}->dirGet,
		toader=>$args{toader},
									  });

    #make sure a directory is set
    if( ! defined( $self->{obj}->dirGet ) ){
        $self->{perror}=1;
        $self->{error}=5;
        $self->{errorString}='The Toader::Directory object does not have a directory set';
        $self->warn;
        return $self;
    }
	$self->{dir}=$self->{obj}->dirGet;

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
		$self->{error}=19;
		$self->{errorString}='pathHelper failed to find the relative2root path for "'.
			$self->{odir}.'"';
		$self->warn;
		return $self;
	}

	#initialize the general object here for simplicity
	$self->{g}=Toader::Render::General->new(
		{
			toader=>$self->{toader},
            self=>\$self,
			obj=>$self->{obj},
			toDir=>$self->{toDir},
		}
		);
	if ( $self->{g}->error ){
		$self->{perror}=1;
		$self->{error}=15;
		$self->{errorString}='Failed to initialize Toader::Render::General. error="'
			.$self->{g}->error.'" errorString="'.$self->{g}->errorString.'"';
		$self->warn;
		return $self;
	}

	return $self;
}

=head2 content

This renders the content to be included in a static
entry page.

    my $content=$foo->content;

=cut

sub content{
    my $self=$_[0];

    if ( ! $self->errorblank ){
        return undef;
    }

	#puts together the date stuff
	my $date=$self->{obj}->{mime}->header("Date");
	my ($sec,$min,$hour,$day,$month,$year,$zone) = strptime($date);
	$year=1900+$year;

	#make sure everything is double digits
	if( $sec < 10 ){
		$sec='0'.$sec;
	}
    if( $min < 10 ){
        $min='0'.$min;
    }
    if( $hour < 10 ){
        $hour='0'.$hour;
    }
    if( $day < 10 ){
        $day='0'.$day;
    }
    if( $month < 10 ){
        $month='0'.$month;
    }

	my $body=$self->{t}->fill_in_string( $self->{obj}->bodyGet,
										 {
											 g=>\$self->{g},
											 toader=>\$self->{toader},
											 sec=>$sec,
											 min=>$min,
											 hour=>$hour,
											 day=>$day,
											 month=>$month,
											 year=>$year,
											 zone=>$zone,
											 obj=>\$self->{obj},
											 self=>\$self,
											 c=>\$self->{toader}->getConfig,
										 });
	if ( $self->{t}->error ){
		$self->{error}=8;
		$self->{errorString}='Filling in the template failed. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	my $content=$self->{t}->fill_in( 'dirContent',
									 {
										 body=>$body,
										 g=>\$self->{g},
										 toader=>\$self->{toader},
										 sec=>$sec,
										 min=>$min,
										 hour=>$hour,
										 day=>$day,
										 month=>$month,
										 year=>$year,
										 zone=>$zone,
										 self=>\$self,
										 obj=>\$self->{obj},
										 c=>\$self->{toader}->getConfig,
									 });
    if ( $self->{t}->error ){
        $self->{error}=8;
        $self->{errorString}='Filling in the template failed. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }

	#this prepares to run it through the specified renderer
	my $renderer;
	my $torun='use Toader::Render::Directory::backends::'.$self->{obj}->rendererGet.'; '.
		'$renderer=Toader::Render::Directory::backends::'.$self->{obj}->rendererGet.'->new({'.
		'obj=>$self->{obj}, toader=>$self->{toader}, });';
	eval( $torun );
	if ( ! defined( $renderer ) ){
		$self->{error}=8;
		$self->{errorString}='Failed to initialize the backend. It returned undef. '.
			'renderer="'.$self->{obj}->rendererGet.'"';
		$self->warn;
		return undef;
	}
	if ( $renderer->error ){
		$self->{error}=8;
		$self->{errorString}='Failed to initialize the backend. It returned with an error. '.
			'error="'.$renderer->error.'" errorString="'.$renderer->errorString.'"';
		$self->warn;
		return undef;
	}

	#render it
	$content=$renderer->render( $content );
	if ( $renderer->error ){
		$self->{error}=9;
		$self->{errorString}='Failed to render the content. It returned an error. '.
			'error="'.$renderer->error.'" errorString="'.$renderer->errorString.'"';
		$self->warn;
		return undef;
	}

	return $content;
}

=head2 render

This renders the object.

No arguments are taken.

=cut

sub render{
	my $self=$_[0];
	
	if ( ! $self->errorblank ){
		return undef;
	}

	#makes sure we have a output directory set...
	#while we don't care about this for rendering the content, we do need to
	#know this for actually fully rendering it
	my $output=$self->{toader}->getOutputDir;
	if ( ! defined( $output ) ){
		$self->{error}=11;
		$self->{errorString}='No output directory has been set for the Toader object';
		$self->warn;
		return undef;
	}

	#makes sure the output directory exists
	if ( ! -d $output ){
		$self->{error}=12;
		$self->{errorString}='The output directory, "'.$output.'", does not exist';
		$self->warn;
		return undef;
	}

	#clean up the old entry
	my $cleanup=Toader::Render::Directory::Cleanup->new( $self->{toader} );
	if ( $cleanup->error ){
		$self->{error}=6;
		$self->{errorString}='Initialing the cleanup module failed. error="'.
			$cleanup->error.'" errorString="'.$cleanup->errorString.'"';
		$self->warn;
		return undef;
	}
	$cleanup->cleanup( $self->{obj} );
	if ( $cleanup->error ){
		$self->{error}=7;
		$self->{errorString}='Cleanup failed. error="'.$cleanup->error.
			'" errorString="'.$cleanup->errorString.'"';
		$self->warn;
		return undef;
	}

	#this renders the content of it
	my $content=$self->content;
	if ( $self->error ){
		$self->warnString('Failed to render the content to include');
		return undef;
	}

    my $page=$self->{t}->fill_in( 'page',
                                     {
                                         toader=>\$self->{toader},
										 g=>\$self->{g},
										 self=>\$self,
										 obj=>\$self->{obj},
										 c=>\$self->{toader}->getConfig,
										 content=>$content,
										 locationID=>'',
                                     });
    if ( $self->{t}->error ){
        $self->{error}=8;
        $self->{errorString}='Filling in the template failed. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }

	#put together some paths for later use
	my $dir=$output.'/'.$self->{r2r}.'/';
	my $index=$dir.'/index.html';
	my $fileDir=$dir.'/.files';

	#make sure the files and entry directory exist
	if ( ! -d $dir ){
		if ( ! make_path( $dir ) ){
			$self->{error}=13;
			$self->{errorString}='The output directry, "'.$dir.'", could not be created';
			$self->warn;
			return undef;
		}
	}
    if ( ! -d $fileDir ){
        if ( ! make_path( $fileDir ) ){
            $self->{error}=14;
            $self->{errorString}='The output file directry, "'.$fileDir.'", could not be created';
            $self->warn;
            return undef;
        }
    }

	#write the index out
	my $fh;
	if ( ! open( $fh, '>', $index ) ){
		$self->{error}=15;
		$self->{errorString}='Failed to open the index, "'.$index.'", for writing';
		$self->warn;
		return undef;
	}
	print $fh $page;
	close( $fh );

	#extract the files
	$self->{obj}->subpartsExtract( $fileDir );
	if ( $self->{obj}->error ){
		$self->{error}=16;
		$self->{errorString}='Failed to extract the subparts. error="'.
			$self->{obj}->error.'" errorString="'.$self->{obj}->errorString.'"';
		$self->warn;
		return undef;
	}

	return 1;
}

=head1 ERROR CODES

=head2 1, noObj

No L<Toader::Directory> object specified.

=head2 2, noToaderObj

No L<Toader> object specified.

=head2 3, objPerror

The L<Toader::Directory> object has a permanent error set.

=head2 4, toaderObjPerror

The L<Toader> object has a permanent error set.

=head2 5, noDirSet

The L<Toader::Directory> object does not have a directory set.

=head2 6, cleanupErrored

Initializing L<Toader::Render::Directory::Cleanup> failed.

=head2 7, generalInitErrored

Failed to initialize L<Toader::Render::General>.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Render


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

1; # End of Toader::Render::Directory
