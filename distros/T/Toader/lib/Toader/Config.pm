package Toader::Config;

use warnings;
use strict;
use base 'Error::Helper';
use Sys::Hostname;
use Config::Tiny;

=head1 NAME

Toader::Config - Represents the Toader config.

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 METHODS

=head2 new

This initiates the object.

One argument is required and it is a Toader object.

    my $foo = Toader::Config->new( $toader );
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
			  errorExtra=>{
				  flags=>{
					  1=>'noToaderObj',
					  2=>'notAtoaderObj',
					  3=>'noDirSet',
					  4=>'configReadFailed',
					  5=>'sectionDoesNotExist',
					  6=>'noVariableSpecified',
					  7=>'invalidVariableOrSection',
					  8=>'configWriteFailed',
					  9=>'getVCSerrored',
					  10=>'VCSusableErrored',
					  11=>'underVCSerrored',
					  12=>'VCSaddErrored',
				  },
			  },
			  VCSusable=>0,
			  };
	bless $self;

	#make sure a Toader object is specified
	if ( ! defined( $toader ) ){
		$self->{perror}=1;
		$self->{error}=1;
		$self->{errorString}='No toader object specified';
		$self->warn;
		return $self;
	}

	#make sure it is a Toader object
	if ( ref( $toader ) ne 'Toader' ){
		$self->{perror}=1;
		$self->{error}=2;
		$self->{errorString}='The passed object is "'.ref( $toader ).'" and not a Toader object';
		$self->warn;
		return $self;
	}

	#saves the Toader object
	$self->{toader}=$toader;

	#gets the directory
	$self->{dir}=$self->{toader}->getRootDir;
	if ( ! defined( $self->{dir} ) ){
		$self->{perror}=1;
		$self->{error}=3;
		$self->{errorString}='The Toader object did not return a directory';
		$self->warn;
		return $self;		
	}

	#this handles the toader config file
	$self->{configFile}=$self->{dir}.'/.toader/config.ini';
	if ( -f $self->{configFile} ){
		$self->{config}=Config::Tiny->read( $self->{configFile} );
		if ( ! defined( $self->{config} ) ){
			$self->{perror}='1';
			$self->{error}=4;
			$self->{errorString}='Unable to read the config file, "'.
				$self->{configFile}.'",';
			$self->warn;
			return $self;
		}
	}else{
		$self->{config}=Config::Tiny->new;
	}

	#sets some defaults for the config if they are not set
	#default to the site name being the hostname
	if ( ! defined( $self->{config}->{_}->{site} ) ){
		$self->{config}->{_}->{site}=hostname;
	}
	#sets the owner if one is not specified
	if ( ! defined( $self->{config}->{_}->{'owner'} ) ){
		$self->{config}->{_}->{'owner'}=getlogin.'@'.hostname;
	}
	#sets the default last
	if ( ! defined( $self->{config}->{_}->{'last'} ) ){
		$self->{config}->{_}->{'last'}=25;
	}
	#disable vcs by default
	if ( ! defined( $self->{config}->{_}->{'vcs'} ) ){
		$self->{config}->{_}->{'vcs'}=0;
	}

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

=head2 getConfig

This returns the L<Config::Tiny> object storing the Toader
config.

There is no need to do any error checking as long as
Toader new suceeded with out issue.

    my $config=$foo->getConfig;

=cut

sub getConfig{
	my $self=$_[0];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	return $self->{config};
}

=head2 getConfigFile

This returns the config file for Toader.

    my $configFile=$foo->getConfigFile;

=cut

sub getConfigFile{
	my $self=$_[0];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	return $self->{configFile};
}

=head2 listSections

This returns a list of sections.

    my @sections=$foo->listSections;

=cut

sub listSections{
	my $self=$_[0];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	return keys( %{ $self->{config} } );
}

=head2 listVariables

This returns a list of variables for a section.

    my @variables=$foo->listVariables( $section );
    if ( $foo->error ){
        warn( 'error:'.$foo->error.': '.$foo->errorString );
    }

=cut

sub listVariables{
	my $self=$_[0];
	my $section=$_[1];

	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	# make sure a variable is specifed
	if ( ! defined( $section ) ){
		$self->{error}='6';
		$self->{erroRstring}='No variable name specified';
		$self->warn;
		return undef;
	}

	#default to _
	if ( ! defined( $section ) ){
		$section='_';
	}

	# make sure the section exists
	if ( ! defined( $self->{config}->{$section} ) ){
		$self->{error}='5';
		$self->{erroRstring}='The section "'.$section.'" does not exist';
		$self->warn;
		return undef;
	}

	return keys( %{ $self->{config}->{$section} } );
}

=head2 valueDel

This deletes a specified value.

Two arguments are taken. The first is the section. If not
specified, "_" is used. The second and required one is the
variable name.

As long as the section exists, which it always will for '_',
and a variable name is specified, this won't error.

	$foo->valueDel( $section, $variable );

=cut

sub valueDel{
	my $self=$_[0];
	my $section=$_[1];
	my $variable=$_[2];

	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	# make sure a variable is specifed
	if ( ! defined( $variable ) ){
		$self->{error}='6';
		$self->{erroRstring}='No variable name specified';
		$self->warn;
		return undef;
	}

	#default to _
	if ( ! defined( $section ) ){
		$section='_';
	}

	# make sure the section exists
	if ( ! defined( $self->{config}->{$section} ) ){
		$self->{error}='5';
		$self->{erroRstring}='The section "'.$section.'" does not exist';
		$self->warn;
		return undef;
	}

	if ( ! defined( $self->{config}->{$section}->{$variable} ) ){
		return 1;
	}
	
	delete( $self->{config}->{$section}->{$variable} );
	
	return 1;
}

=head2 valueGet

This returns a value that has been set for a variable.

Two arguments are taken. The first is the section. If not
specified, "_" is used. The second and required one is the
variable name.

As long as the section exists, which it always will for '_',
and a variable name is specified, this won't error.

If a value does not exist, undef is returned.

    my $value=$foo->valueGet( $section, $variable );

=cut

sub valueGet{
	my $self=$_[0];
	my $section=$_[1];
	my $variable=$_[2];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}
	
	# make sure a variable is specifed
	if ( ! defined( $variable ) ){
		$self->{error}='6';
		$self->{erroRstring}='No variable name specified';
		$self->warn;
		return undef;
	}
	
	#default to _
	if ( ! defined( $section ) ){
		$section='_';
	}
	
	# make sure the section exists
	if ( ! defined( $self->{config}->{$section} ) ){
		$self->{error}='5';
		$self->{erroRstring}='The section "'.$section.'" does not exist';
		$self->warn;
		return undef;
	}
	
	return $self->{config}->{$section}->{$variable};
}

=head2 valueSet

This sets a new value for the config.

Third arguments are taken. The first is the section. If not
specified, "_" is used. The second and required one is the
variable name. The third and required is the the value.

If the specified section does not exist, a new one will be created.

Neither the section or variable name can match /[\t \n\=\#\;]/.

    my $value=$foo->valueSet( $section, $variable, $value );

=cut

sub valueSet{
	my $self=$_[0];
	my $section=$_[1];
	my $variable=$_[2];
	my $value=$_[2];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	# make sure a variable is specifed
	if ( ! defined( $variable ) ){
		$self->{error}=6;
		$self->{erroRstring}='No variable name specified';
		$self->warn;
		return undef;
	}

	#default to _
	if ( ! defined( $section ) ){
		$section='_';
	}

	#makes sure a valid section and variable is specified
	if ( $variable =~ /[\t \n\=\#\;]/  ){
		$self->{error}=7;
		$self->{errorString}='The variable,"'.$variable.'", matched /[\t \n\=\#\;]/';
		$self->warn;
		return undef;
	}
	if ( $section =~ /[\t \n\=\#\;]/  ){
		$self->{error}=7;
		$self->{errorString}='The section,"'.$section.'", matched /[\t \n\=\#\;]/';
		$self->warn;
		return undef;
	}

	#set it if no section has been created yet
	if ( ! defined( $self->{config}->{$section} ) ){
		$self->{config}->{$section}={ $variable=>$value };
	}

	return 1;
}

=head2 write

Writes the config out to the Toader config file.

    $foo->write;
    if ( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub write{
	my $self=$_[0];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	#try to write the config out and error if it does not
	if ( ! $self->{config}->write( $self->{configFile} ) ){
		$self->{error}=8;
		$self->{errorString}='Failed to write the config out';
		$self->warn;
		return undef;
	}

	#if VCS is not usable, stop here
	if ( ! $self->{VCSusable} ){
		return 1;
	}

	#if it is under VCS, we have nothing to do
	my $underVCS=$self->{vcs}->underVCS( $self->{configFile} );
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
	$self->{vcs}->add( $self->{configFile} );
	if ( $self->{vcs}->error ){
		$self->{error}=12;
		$self->{errorString}='Toader::VCS->add errored. error="'.
			$self->{vcs}->error.'" errorString="'.$self->{vcs}->errorString.'"';
		$self->warn;
		return undef;
	}

	return 1;
}

=head1 ERROR CODES/FLAGS

=head2 1, noToaderObj

No L<Toader> object specified.

=head2 2, notAtoaderObj

The specified object is not a L<Toader> object.

=head2 3, noDirSet

The L<Toader> object did not return a directory.

=head2 4, configReadFailed

Failed to read the config file.

=head2 5, sectionDoesNotExist

The section does not exist.

=head2 6, noVariableSpecified

No variable name specified.

=head2 7, invalidVariableOrSection

Variable or section matched /[\t \n\=\#\;]/.

=head2 8, configWriteFailed

Failed to write the config out.

=head2 9, getVCSerrored

L<Toader>->getVCS errored.

=head2 10, VCSusableErrored

L<Toader::VCS>->usable errored.

=head2 11, underVCSerrored

L<Toader::VCS>->underVCS errored.

=head2 12, VCSaddErrored

L<Toader::VCS>->add errored.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Config


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

Copyright 2011 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Toader::Config
