package ZConf::RSS::GUI;

use warnings;
use strict;
use ZConf::GUI;
use ZConf::RSS;

=head1 NAME

ZConf::RSS::GUI - Provides various GUI methods for ZConf::RSS.

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';


=head1 SYNOPSIS

    use ZConf::RSS::GUI;

    my $zcrssGui = ZConf::RSS::GUI->new();
    ...

=head1 METHODS

=head2 new

=head3 args hash

=head4 obj

This is object returned by ZConf::RSS.

    my $zcrssGui=ZConf::RSS::GUI->new({obj=>$obj});
    if($zcrssGui->{error}){
         print "Error!\n";
    }

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $function='new';

	my $self={error=>undef,
			  perror=>undef,
			  errorString=>undef,
			  module=>'ZConf-RSS-GUI',
			  };
	bless $self;

	#gets the object or initiate it
	if (!defined($args{obj})) {
		$self->{obj}=ZConf::RSS->new;
		if ($self->{obj}->{error}) {
			$self->{error}=1;
			$self->{perror}=1;
			$self->{errorString}='Failed to initiate ZConf::RSS. error="'.
			                     $self->{obj}->{error}.'" errorString="'.$self->{obj}->{errorString}.'"';
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return $self;
		}
	}else {
		$self->{obj}=$args{obj};
	}

	#gets the zconf object
	$self->{zconf}=$self->{obj}->{zconf};

	#gets the gui
	$self->{gui}=ZConf::GUI->new({zconf=>$self->{zconf}});
	if ($self->{obj}->{error}) {
		$self->{error}=2;
		$self->{perror}=1;
		$self->{errorString}='Failed to initiate ZConf::GUI. error="'.
    	                     $self->{gui}->{error}.'" errorString="'.$self->{gui}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	$self->{useX}=$self->{gui}->useX('ZConf::RSS');

	my @preferred=$self->{gui}->which('ZConf::RSS');
	if ($self->{gui}->{error}) {
		$self->{error}=3;
		$self->{perror}=1;
		$self->{errorString}='Failed to get the preferred backend list. error="'.
    	                     $self->{gui}->{error}.'" errorString="'.$self->{gui}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#make sure we have something
	if (!defined($preferred[0])) {
		$self->{error}=6;
		$self->{perror}=1;
		$self->{errorString}='Which did not return any preferred backends';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#initiate the backend
	my $toeval='use ZConf::RSS::GUI::'.$preferred[0].';'."\n".
	           '$self->{be}=ZConf::RSS::GUI::'.$preferred[0].
			   '->new({obj=>$self->{obj}});';
	my $er=eval($toeval);

	#failed to initiate the backend
	if (!defined($self->{be})) {
		$self->{error}=4;
		$self->{perror}=1;
		$self->{errorString}='The backend returned undefined';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#backend errored
	if ($self->{be}->{error}) {
		$self->{error}=4;
		$self->{perror}=1;
		$self->{errorString}='The backend returned undefined. error="'.
    	                     $self->{be}->{error}.'" errorString="'.$self->{be}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	return $self;
}

=head2 addFeed

This invokes a dialog to add a new feed.

There is one optional arguement taken and it is the URL
for the feed. This will be used to automatically populate
URL feild in the dialog.

    $zcrssGui->addFeed('http://foo.bar/rss.xml');
    if($zcrssGui->{error}){
        print "Error!\n";
    }

=cut

sub addFeed{
	my $self=$_[0];
	my $feed=$_[1];
	my $function='manage';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	$self->{be}->addFeed($feed);
	if ($self->{be}->{error}) {
		$self->{error}=5;
		$self->{errorString}='The backend errored. error="'.
    	                     $self->{be}->{error}.'" errorString="'.$self->{be}->{errorString}.'"';
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;		
	}

	return 1;
}

=head2 manage

Invokes the view window.

    $zcrssGui->manage;
    if($zcrssGui->{error}){
        print "Error!\n";
    }

=cut

sub manage{
	my $self=$_[0];
	my $function='manage';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	$self->{be}->manage;
	if ($self->{be}->{error}) {
		$self->{error}=5;
		$self->{errorString}='The backend errored. error="'.
    	                     $self->{be}->{error}.'" errorString="'.$self->{be}->{errorString}.'"';
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;		
	}

	return 1;
}

=head2 view

Invokes the view window.

    $zcrssGui->view;
    if($zcrssGui->{error}){
        print "Error!\n";
    }

=cut

sub view{
	my $self=$_[0];
	my $function='view';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	$self->{be}->view;
	if ($self->{be}->{error}) {
		$self->{error}=5;
		$self->{errorString}='The backend errored. error="'.
    	                     $self->{be}->{error}.'" errorString="'.$self->{be}->{errorString}.'"';
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;		
	}

	return 1;
}

=head2 dialogs

This returns a array of available dialogs.

    my @dialogs=$zcrssGui->dialogs;
    if($zcrssGui->{error}){
        print "Error!\n";
    }

=cut

sub dialogs{
	my $self=$_[0];
	my $function='dialogs';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	my @dialogs=$self->{be}->dialogs;
	if ($self->{be}->{error}) {
		$self->{error}=5;
		$self->{errorString}='The backend errored. error="'.
    	                     $self->{be}->{error}.'" errorString="'.$self->{be}->{errorString}.'"';
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;		
	}

	return @dialogs;
}

=head2 windows

This returns a array of available dialogs.

    my @windows=$zcrssGui->windows;
    if($zcrssGui->{error}){
        print "Error!\n";
    }

=cut

sub windows{
	my $self=$_[0];
	my $function='windows';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	my @windows=$self->{be}->windows;
	if ($self->{be}->{error}) {
		$self->{error}=5;
		$self->{errorString}='The backend errored. error="'.
    	                     $self->{be}->{error}.'" errorString="'.$self->{be}->{errorString}.'"';
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;		
	}

	return @windows;
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

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

Failed to initiate ZConf::RSS.

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

=head1 DIALOGS

=head2 addFeed

This adds a new feed.

=head1 WINDOWS

Please not that unless working directly and specifically with a backend, windows and dialogs
are effectively the same in that they don't return until the window exits, generally.

=head2 view

This allows the RSS feeds to be viewed.

=head2 manage

This allows the RSS feeds to be managed along with the templates.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-devtemplate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-RSS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::RSS::GUI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf::RSS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf::RSS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf::RSS>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf::RSS/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::RSS::GUI
