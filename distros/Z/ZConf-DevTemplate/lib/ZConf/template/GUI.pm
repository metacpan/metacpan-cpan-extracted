package ZConf::template::GUI;

use warnings;
use strict;
use ZConf::GUI;
use ZConf::template;

=head1 NAME

ZConf::template::GUI - 

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use ZConf::template::GUI;

    my $foogui = ZConf::template::GUI->new();
    ...

=head1 METHODS

=head2 new

=head3 args hash

=head4 obj

This is object returned by %%%PARENT%%%.

    my $foogui=ZConf::template::GUI->new({obj=>$obj});
    if($foogui->{error}){
         print "Error!\n";
    }

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $method='new';

	my $self={error=>undef,
			  perror=>undef,
			  errorString=>undef,
			  module=>'ZConf-template-GUI',
			  };
	bless $self;

	#gets the object or initiate it
	if (!defined($args{obj})) {
		$self->{obj}=ZConf::template->new;
		if ($self->{obj}) {
			$self->{error}=1;
			$self->{perror}=1;
			$self->{errorString}='Failed to initiate %%%PARENT%%%. error="'.
			                     $self->{obj}->{error}.'" errorString="'.$self->{obj}->{errorString}.'"';
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return $self;
		}
	}else {
		$self->{obj}=$args{obj};
	}

	#gets the zconf object
	$self->{zconf}=$self->{obj}->{zconf};

	#gets the gui
	$self->{gui}=ZConf::GUI->new({zconf=>$self->{zconf}});
	if ($self->{obj}) {
		$self->{error}=2;
		$self->{perror}=1;
		$self->{errorString}='Failed to initiate ZConf::GUI. error="'.
    	                     $self->{gui}->{error}.'" errorString="'.$self->{gui}->{errorString}.'"';
		warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	$self->{useX}=$self->{gui}->useX('%%%PARENT%%%');

	my @preferred=$self->{gui}->which('%%%PARENT%%%');
	if ($self->{gui}->{error}) {
		$self->{error}=3;
		$self->{perror}=1;
		$self->{errorString}='Failed to get the preferred backend list. error="'.
    	                     $self->{gui}->{error}.'" errorString="'.$self->{gui}->{errorString}.'"';
		warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#make sure we have something
	if (!defined($preferred[0])) {
		$self->{error}=6;
		$self->{perror}=1;
		$self->{errorString}='Which did not return any preferred backends';
		warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#try the backends till we get one
	my $int=0;
	my $loop=1;
	while ($loop) {


		if (defined($preferred[0])) {
			#initiate the backend
			my $toeval='use ZConf::template::GUI::'.$preferred[$int].';'."\n".
		           '$self->{be}=ZConf::template::GUI::'.$preferred[$int].
			       '->new({zconf=>$self->{zconf}, useX=>$self->{useX},'.
			       'zcgui=>$self->{gui}, zcrunner=>$self->{zcr}}); return 1';
			my $er=eval($toeval);
		}else {
			$loop=0;
		}

		#if it returned something, see if it errored
		if (defined($self->{be})) {
			if (!$self->{be}->{error}) {
				#stop the loop and continue that we loaded a working one
				$loop=0;
			}
		}
		
		$int++;
	}
		
	#failed to initiate the backend
	if (!defined($self->{be})) {
		$self->{error}=4;
		$self->{perror}=1;
		$self->{errorString}='The backend returned undefined';
		warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#backend errored
	if (!$self->{be}->{error}) {
		$self->{error}=4;
		$self->{perror}=1;
		$self->{errorString}='The backend returned undefined. error="'.
		$self->{be}->{error}.'" errorString="'.$self->{be}->{errorString}.'"';
		warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	return $self;
}

=head2 app

Runs some application.

    $foogui->app;
    if($foogui->{error}){
        warn('error '.$foogui->error.': '.$foogui->errorString);
    }

=cut

sub app{
	my $self=$_[0];
	my $method='app';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$method.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	$self->{be}->app;

}

=head2 hasApp

If this returns true, it means it has a application.

    my $hasApp=$foogui->hasApp;
    if($foogui->{error}){
        warn('error '.$foogui->error.': '.$foogui->errorString);
    }else{
        if($hasApp){
            print "Yes\n";
        }
    }

=cut

sub hasApp{
	my $self=$_[0];
	my $method='hasApp';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$method.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	my $hasApp=$self->{be}->hasApp;
	if ($self->{be}->{error}) {
		$self->{error}=5;
		$self->{errorString}='The backend errored. error="'.
    	                     $self->{be}->{error}.'" errorString="'.$self->{be}->{errorString}.'"';
		warn($self->{module}.' '.$method.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;		
	}

	return $hasApp;
}

=head1 DIALOG/WINDOW METHODS

=head2 dialogs

This returns a array of available dialogs.

    my @dialogs=$foogui->dialogs;
    if($foogui->{error}){
        warn('error '.$foogui->error.': '.$foogui->errorString);
    }

=cut

sub dialogs{
	my $self=$_[0];
	my $method='dialogs';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$method.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	my @dialogs=$self->{be}->dialogs;
	if ($self->{be}->{error}) {
		$self->{error}=5;
		$self->{errorString}='The backend errored. error="'.
    	                     $self->{be}->{error}.'" errorString="'.$self->{be}->{errorString}.'"';
		warn($self->{module}.' '.$method.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	return @dialogs;
}

=head2 hasDialog

This checks if the loaded backend supports a specific dialog.

    my $supported=$foogui->hasDialog($dialogName);
    if($foogui->error){
        warn('error '.$foogui->error.': '.$foogui->errorString);
    }
    if(!supported){
        warn($dialogName.' is not supported');
    }

=cut

sub hasDialog{
	my $self=$_[0];
	my $dialog=$_[1];
	my $method='hasDialog';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$method.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	if (!defined($dialog)) {
		$self->{error}=7;
		$self->{errorString}='No dialog specified';
		warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
	}

	#try to fetch the supported dialogs
	my @dialogs=$self->dialogs;
	if ($self->error) {
		warn($self->{module}.' '.$method.': $self->dialogs errored');
		return undef;
	}

	#look for a match
	my $int=0;
	while (defined($dialogs[$int])) {
		#return true if a match is found
		if ($dialogs[$int] eq $dialog) {
			return 1;
		}
		$int++;
	}

	return 0;
}

=head2 hasWindow

This checks if the loaded backend supports a specific window.

    my $supported=$foogui->hasWindow($windowName);
    if($foogui->error){
        warn('error '.$foogui->error.': '.$foogui->errorString);
    }
    if(!supported){
        warn($windowName.' is not supported');
    }

=cut

sub hasWindow{
	my $self=$_[0];
	my $dialog=$_[1];
	my $method='hasDialog';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$method.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	if (!defined($dialog)) {
		$self->{error}=7;
		$self->{errorString}='No dialog specified';
		warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
	}

	#try to fetch the supported dialogs
	my @dialogs=$self->dialogs;
	if ($self->error) {
		warn($self->{module}.' '.$method.': $self->dialogs errored');
		return undef;
	}

	#look for a match
	my $int=0;
	while (defined($dialogs[$int])) {
		#return true if a match is found
		if ($dialogs[$int] eq $dialog) {
			return 1;
		}
		$int++;
	}

	return 0;
}

=head2 windows

This returns a array of available dialogs.

    my @windows=$foogui->windows;
    if($foogui->{error}){
        warn('error '.$foogui->error.': '.$foogui->errorString);
    }

=cut

sub windows{
	my $self=$_[0];
	my $method='windows';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$method.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	my @windows=$self->{be}->windows;
	if ($self->{be}->{error}) {
		$self->{error}=5;
		$self->{errorString}='The backend errored. error="'.
    	                     $self->{be}->{error}.'" errorString="'.$self->{be}->{errorString}.'"';
		warn($self->{module}.' '.$method.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;		
	}

	return @windows;
}

=head1 ERROR RELATED METHODS

=head2 error

This returns the current error code if one is set. If undef/evaulates as false
then no error is present. Other wise one is.

    if($foogui->error){
        warn('error '.$foogui->error.': '.$foogui->errorString);
    }

=cut

sub error{
	return $_[0]->{error};
}

=head2 errorString

This returns the current error string. A return of "" means no error is present.

    my $errorString=$foogui->errorString;

=cut

sub errorString{
	return $_[0]->{errorString};
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $foogui->{error}=undef;
    $foogui->{errorString}="";

=cut

#blanks the error flags
sub errorblank{
	my $self=$_[0];

	if ($self->{perror}) {
		warn('ZConf-DevTemplate errorblank: A permanent error is set');
		return undef;
	}

	$self->{error}=undef;
	$self->{errorString}="";
	
	return 1;
}

=head1 ERROR CODES

=head2 1

Failed to initiate %%%PARENT%%%.

=head2 2

Failed to initiate ZConf::GUI.

=head2 3

Failed to get the preferred.

=head2 4

Failed to initiate the backend.

=head2 5

Backend errored.

=head2 6

No backend found via ZConf::GUI->which.

=head2 7

No dialog specified.

=head1 AUTHOR

%%%AUTHOR%%%, C<< <%%%EMAIL%%%> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-devtemplate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-template>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::template::GUI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=%%%PARENT%%%>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/%%%PARENT%%%>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/%%%PARENT%%%>

=item * Search CPAN

L<http://search.cpan.org/dist/%%%PARENT%%%/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 %%%AUTHOR%%%, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::template::GUI
