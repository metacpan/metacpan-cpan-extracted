package Toader::Templates;

use warnings;
use strict;
use Toader::isaToaderDir;
use Cwd 'abs_path';
use base 'Error::Helper';
use Text::Template;
use Toader::Templates::Defaults;

=head1 NAME

Toader::Templates - This handles fetching Toader templates.

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

For information on the storage and rendering of entries,
please see 'Documentation/Templates.pod'.

=head1 METHODS

=head2 new

=head3 args hash ref

=head4 dir

This is the directory to intiate in.

=head4 toader

This is a L<Toader> object.

    my $foo = Toader::Templates->new( \%args );
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
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
			  isatd=>Toader::isaToaderDir->new(),
			  dir=>undef,
			  defaults=>Toader::Templates::Defaults->new,
			  errorExtra=>{
				  flags=>{
					  1=>'noDirSpecified',
					  2=>'isaToaderDirErrored',
					  3=>'notAtoaderDir',
					  4=>'invalidTemplateName',
					  5=>'openTemplateFailed',
					  6=>'noDefaultTemplate',
					  7=>'templateFillErrored',
					  8=>'templateStringUndef',
					  9=>'templateNameUndef',
					  10=>'notAtoaderObj',
					  11=>'getVCSerrored',
					  12=>'VCSusableErrored',
					  13=>'noTemplateSpecified',
					  14=>'underVCSerrored',
					  15=>'VCSaddErrored',
					  16=>'VCSdeleteErrored',
					  17=>'unlinkFailed',
					  18=>'notInDir',
					  19=>'noToaderObj',
				  },
			  },
			  VCSusable=>0,
			  };
	bless $self;

	if ( defined( $args{dir} ) ){
		if ( ! $self->{isatd}->isaToaderDir( $args{dir} ) ){
			$self->{perror}=1;
			$self->{error}=1,
			$self->{errorString}='The specified directory is not a Toader directory';
			$self->warn;
			return $self;
		}
		$self->{dir}=$args{dir};
	}

	#if we have a Toader object, reel it in
	if ( ! defined( $args{toader} ) ){
		$self->{error}=19;
		$self->{perror}=1;
		$self->{errorString}='No $args{toader} specified';
		$self->warn;
		return $self;
	}
	if ( ref( $args{toader} ) ne "Toader" ){
		$self->{perror}=1;
		$self->{error}=10;
		$self->{errorString}='The object specified is a "'.ref($args{toader}).'"';
		$self->warn;
		return $self;
	}
	$self->{toader}=$args{toader};

	#gets the Toader::VCS object
	$self->{vcs}=$self->{toader}->getVCS;
	if ( $self->{toader}->error ){
		$self->{perror}=1;
		$self->{error}=11;
		$self->{errorString}='Toader->getVCS errored. error="'.
			$self->{toader}->error.'" errorString="'.$self->{toader}->errorString.'"';
		$self->warn;
		return $self;
	}
	
	#checks if VCS is usable
	$self->{VCSusable}=$self->{vcs}->usable;
	if ( $self->{vcs}->error ){
		$self->{perror}=1;
		$self->{error}=12;
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

    $foo->dirSet($toaderDirectory);
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

	#checks if the directory is Toader directory or not
    my $returned=$self->{isatd}->isaToaderDir($dir);
	if (! $returned ) {
		$self->{error}=1;
		$self->{errorString}='"'.$dir.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	$self->{dir}=$dir;

	return 1;
}

=head2 fill_in

This fills in a template that has been passed to it.

Two arguments are taken. The first is the template name.
The second is a hash reference. 

The returned string is the filled out template.

    my $rendered=$foo->fill_in( $templateName, \%hash );
    if ( $foo->error ){
        warn( 'Error:'.$foo->error.': '.$foo->errorString );
    }

=cut

sub fill_in{
	my $self=$_[0];
	my $name=$_[1];
	my $hash=$_[2];

	if( ! $self->errorblank ){
		return undef;
	}

	#make sure a template name is specified
	if ( ! defined( $name ) ){
		$self->{error}=9;
		$self->{errorString}='No template name specified';
		$self->warn;
		return undef;
	}

	#gets the template
	my $template=$self->getTemplate( $name );
	if ( $self->error ){
		return undef;
	}

	return $self->fill_in_string( $template, $hash );
}

=head2 fill_in_string

This fills in a template that has been passed to it.

Two arguments are required and the first is the template string to use and
second it is the hash to pass to it.

The returned string is the filled out template.

    my $rendered=$foo->fill_in_string( $templateString, \%hash );
    if ( $foo->error ){
        warn( 'Error:'.$foo->error.': '.$foo->errorString );
    }

=cut

sub fill_in_string{
	my $self=$_[0];
	my $string=$_[1];
	my $hash=$_[2];

	if( ! $self->errorblank ){
		return undef;
	}

	if ( ! defined( $string ) ){
		$self->{error}=8;
		$self->{errorString}='No template string specified';
		$self->warn;
		return undef;
	}

	my $template = Text::Template->new(
		TYPE => 'STRING',
		SOURCE => $string,
		DELIMITERS=>[ '[==', '==]' ],
		);

	my $rendered=$template->fill_in(
		HASH=>$hash,
		);

	if ( ! defined ( $rendered ) ){
		$self->{error}=7;
		$self->{errorString}='Error encountered filling in the template';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 findTemplate

This finds a specified template.

One arguement is taken and it is the name of the template.

A return of undef can mean either a error or it was not found.
If there was an error, the method error will return true.

    my $templateFile=$foo->findTemplate($templateName);
    if( !defined( $templateFile ) ){
        if($foo->error){
            warn('Error:'.$foo->error.': '.$foo->errorString);
        }else{
            print("Not found\n");
        }
    }else{
        print $templateFile."\n";
    }

=cut

sub findTemplate{
	my $self=$_[0];
	my $name=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	#make sure a directory has been set
	if (!defined( $self->{dir} )) {
		$self->{error}=2;
		$self->{errorString}='No directory has been set yet';
		$self->warn;
		return undef;		
	}

	#checks if the name is valid
	my $returned=$self->templateNameCheck($name);
	if (! $returned ) {
		$self->{error}=4;
		$self->{errorString}='"'.$name.'" is not a valid template name';
		$self->warn;
		return undef;
	}

	#checks if the directory is Toader directory or not
    $returned=$self->{isatd}->isaToaderDir( $self->{dir} );
	if (! $returned ) {
		$self->{error}=3;
		$self->{errorString}='"'.$self->{dir}.'" is no longer a Toader directory';
		$self->warn;
		return undef;
	}

	#initial stuff to check
	my $dir=$self->{dir};
	my $template=$dir.'/.toader/templates/'.$name;

	#checks if the template exists
	if (-f $template) {
		return $template;
	}

	#recurse down trying to find the last one
	$dir=abs_path($dir.'/..');
	#we will always find something below so it is just set to 1
	while (1) {
		#we hit the FS root...
		#if he hit this, something is definitely wrong
		if ($dir eq '/') {
			return undef;
		}

		#make sure
		$returned=$self->{isatd}->isaToaderDir($dir);
		if (!$returned) {
			return undef;
		}

		#check if it exists
		$template=$dir.'/.toader/templates/'.$name;
		if (-f $template) {
			return $template;
		}

		#check the next directory
		$dir=abs_path($dir.'/..');
	}
}

=head2 getTemplate

This finds a template and then returns it.

The method findTemplate will be used and if that fails the default
template will be returned.

One arguement is required and it is the template name.

    my $template=$foo->getTemplate($templateName);
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub getTemplate{
	my $self=$_[0];
	my $name=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	#make sure a template name is specified
    if ( ! defined( $name ) ){
        $self->{error}=9;
        $self->{errorString}='No template name specified';
        $self->warn;
        return undef;
    }

	#try to find it as a file
	#also allow this to do the error checking as it is the same
	my $file=$self->findTemplate($name);
	if ($self->error) {
		$self->warnString('findTemplate errored');
		return undef;
	}

	#the contents of the template to be returned
	my $template;

	#if we found a file, read it and return it
	if (defined($file)) {
		my $fh;
		if ( ! open( $fh, '<', $file ) ) {
			$self->{error}=5;
			$self->{errorString}="Unable to open '".$file."'";
			$self->warn;
			return undef;
		}
		$template=join('',<$fh>);
		close $fh;
		return $template;
	}

	#tries to fetch the default template
	$template=$self->{defaults}->getTemplate($name);
	if ( ! defined( $template ) ) {
			$self->{error}=6;
			$self->{errorString}='No default template';
			$self->warn;
			return undef;
	}

	return $template;
}

=head2 getTemplateDefault

This finds a default template and then returns it.

One arguement is required and it is the template name.

    my $template=$foo->getTemplate($templateName);
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub getTemplateDefault{
    my $self=$_[0];
    my $name=$_[1];

    if (!$self->errorblank){
        return undef;
    }

    #make sure a template name is specified
    if ( ! defined( $name ) ){
        $self->{error}=9;
        $self->{errorString}='No template name specified';
        $self->warn;
        return undef;
	}

    #tries to fetch the default template
    my $template=$self->{defaults}->getTemplate($name);
    if ( ! defined( $template ) ) {
		$self->{error}=6;
		$self->{errorString}='No default template';
		$self->warn;
		return undef;
    }
	
    return $template;
}

=head2 listTemplates

This lists the various templates in the directory.

    my @templates=$foo->listTemplates;
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub listTemplates{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	#make sure a directory has been set
	if (!defined( $self->{dir} )) {
		$self->{error}=2;
		$self->{errorString}='No directory has been set yet';
		$self->warn;
		return undef;
	}

	#checks if the directory is Toader directory or not
    my $returned=$self->{isatd}->isaToaderDir( $self->{dir} );
	if (! $returned ) {
		$self->{error}=3;
		$self->{errorString}='"'.$self->{dir}.'" is no longer a Toader directory';
		$self->warn;
		return undef;
	}

	#the directory to list
	my $dir=$self->{dir}.'/.toader/templates/';

	#makes sure the template exists and if it does not, return only having the default
	if (! -d $dir) {
		return;
	}

	#lists each theme
	my $dh;
	if (opendir($dh, $dir )) {
		$self->{error}='4';
		$self->{errorString}='Failed to open the directory "'.$dir.'"';
		$self->warn;
		return undef;
	}
	my @templates=grep( { -f $dir.'/'.$_ } readdir($dh) );
	close($dh);
	
	return \@templates;
}

=head2 listDefaultTemplates

This lists the various templates in the directory.

    my @templates=$foo->listTemplates;
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub listDefaultTemplates{
    my $self=$_[0];

    if (!$self->errorblank){
        return undef;
    }

	return $self->{defaults}->listTemplates;
}

=head2 remove

This removes a template from the current directory.

One argument is required and that is the name of the template.

    $foo->remove( $name );
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub remove{
	my $self=$_[0];
	my $name=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	#make sure a directory has been set
	if (!defined( $self->{dir} )) {
		$self->{error}=2;
		$self->{errorString}='No directory has been set yet';
		$self->warn;
		return undef;
	}

	#make sure a template name is specified
    if ( ! defined( $name ) ){
        $self->{error}=9;
        $self->{errorString}='No template name specified';
        $self->warn;
        return undef;
    }

	#checks if the name is valid
	my $returned=$self->templateNameCheck($name);
	if (! $returned ) {
		$self->{error}=4;
		$self->{errorString}='"'.$name.'" is not a valid template name';
		$self->warn;
		return undef;
	}

	#make sure the template is in this directory
	if ( ! $self->templateInDir( $name ) ){
		$self->{error}=18;
		$self->{errorString}='Template "'.$name.'" is not in "'.
			$self->{dir}.'"';
		$self->warn;
		return undef;
	}

	#the file in question
	my $file=$self->{dir}.'/.toader/templates/'.$name;

	#try to unlink the file
	if ( ! unlink( $file ) ) {
		$self->{error}=17;
		$self->{errorString}='Unlink of "'.$file.'" failed';
		$self->warn;		
		return undef;
	}

	#if VCS is not usable, return here
	if ( ! $self->{VCSusable} ){
		return 1;
	}
	
	#if it is not under VCS, we have nothing to do
	my $underVCS=$self->{vcs}->underVCS($file);
	if ( $self->{vcs}->error ){
		$self->{error}=14;
		$self->{errorString}='Toader::VCS->underVCS errored. error="'.
			$self->{vcs}->error.'" errorString="'.$self->{vcs}->errorString.'"';
		$self->warn;
		return undef;
	}
	if ( $underVCS ){
		return 1;
	}

	#delete it as if we reach here it is not under VCS and VCS is being used
	$self->{vcs}->delete( $file );
	if ( $self->{vcs}->error ){
		$self->{error}=16;
		$self->{errorString}='Toader::VCS->delete errored. error="'.
			$self->{vcs}->error.'" errorString="'.$self->{vcs}->errorString.'"';
		$self->warn;
		return undef;
	}


	return 1;
}

=head2 set

This sets a template in the current directory.

Two arguments are required and those in order are the name
template and the template.

    $foo->set( $name, $template );
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub set{
	my $self=$_[0];
	my $name=$_[1];
	my $template=$_[2];

	if (!$self->errorblank){
		return undef;
	}

	#make sure a directory has been set
	if (!defined( $self->{dir} )) {
		$self->{error}=2;
		$self->{errorString}='No directory has been set yet';
		$self->warn;
		return undef;
	}

	#make sure a template name is specified
    if ( ! defined( $name ) ){
        $self->{error}=9;
        $self->{errorString}='No template name specified';
        $self->warn;
        return undef;
    }

	#checks if the name is valid
	my $returned=$self->templateNameCheck($name);
	if (! $returned ) {
		$self->{error}=4;
		$self->{errorString}='"'.$name.'" is not a valid template name';
		$self->warn;
		return undef;
	}

	#make sure a template name is specified
    if ( ! defined( $template ) ){
        $self->{error}=13;
        $self->{errorString}='No template specified';
        $self->warn;
        return undef;
    }	

	#the file in question
	my $file=$self->{dir}.'/.toader/templates/'.$name;

	#write the template out
	my $fh;
	if ( ! open( $fh, '>', $file ) ){
		$self->{error}=5;
		$self->{errorString}='Unable to open "'.$file.'" for writing';
		$self->warn;
		return undef;
	}
	print $fh $template;
	close $fh;

	#if VCS is not usable, return here
	if ( ! $self->{VCSusable} ){
		return 1;
	}
	
	#if it is not under VCS, we have nothing to do
	my $underVCS=$self->{vcs}->underVCS($file);
	if ( $self->{vcs}->error ){
		$self->{error}=14;
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
		$self->{error}=15;
		$self->{errorString}='Toader::VCS->add errored. error="'.
			$self->{vcs}->error.'" errorString="'.$self->{vcs}->errorString.'"';
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 templateInDir

This checks if the template is in the current directory.

One argument is required and that is the name of the template.

    $foo->templateInDir( $name );
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub templateInDir{
	my $self=$_[0];
	my $name=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	#make sure a directory has been set
	if (!defined( $self->{dir} )) {
		$self->{error}=2;
		$self->{errorString}='No directory has been set yet';
		$self->warn;
		return undef;
	}

	#make sure a template name is specified
    if ( ! defined( $name ) ){
        $self->{error}=9;
        $self->{errorString}='No template name specified';
        $self->warn;
        return undef;
    }

	#checks if the name is valid
	my $returned=$self->templateNameCheck($name);
	if (! $returned ) {
		$self->{error}=4;
		$self->{errorString}='"'.$name.'" is not a valid template name';
		$self->warn;
		return undef;
	}

	#the file in question
	my $file=$self->{dir}.'/.toader/templates/'.$name;

	#checks if it exists
	if ( -f $file ){
		return 1;
	}
	
	return 0;
}

=head2 templateNameCheck

This makes sure checks to make sure a template name is valid.

    my $returned=$foo->templateNameCheck($name);
    if ($returned){
        print "Valid\n";
    }

=cut

sub templateNameCheck{
	my $self=$_[0];
	my $name=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	if (!defined($name)) {
		return 0;
	}
	if ($name =~ /^ /) {
		return 0;
	}
	if ($name =~ /\t/) {
		return 0;
	}
	if ($name =~ /\n/) {
		return 0;
	}
	if ($name =~ / $/) {
		return 0;
	}

	return 1;
}

=head1 ERROR CODES

=head2 1, noDirSpecified

The specified directory is not a L<Toader> directory.

=head2 2, isaToaderDirErrored

No directory has been specified yet.

=head2 3, notAtoaderDir

The directory in question is no longer a toader directory.

=head2 4, invalidTemplateName

Not a valid template name.

=head2 5, openTemplateFailed

Unable to open the template file.

=head2 6, noDefaultTemplate

Unable to fetch the default template. It does not exist.

=head2 7, templateFillErrored

Errored filling out the template string.

=head2 8, templateStringUndef

Nothing specified for the template string.

=head2 9, templateNameUndef

Template name is not defined.

=head2 10, notAtoaderObj

The object in question is not a Toader object.

=head2 11, getVCSerrored

L<Toader>->getVCS errored.

=head2 12, VCSusableErrored

L<Toader::VCS>->usable errored.

=head2 13, noTemplateSpecified

Nothing specified for the data for a template.

=head2 14, underVCSerrored

L<Toader::VCS>->underVCS errored.

=head2 15, VCSaddErrored

L<Toader::VCS>->add errored.

=head2 16, VCSdeleteErrored

L<Toader::VCS>->delete errored.

=head2 17, unlinkFailed

Failed to unlink the template.

=head2 18, notInDir

The requested template is not in this Toader dir.

=head2 19, noToaderObj

No L<Toader> object is given.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Templates


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

1; # End of Toader::Templates
