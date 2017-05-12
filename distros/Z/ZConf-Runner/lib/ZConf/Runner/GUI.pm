package ZConf::Runner::GUI;

use warnings;
use strict;
use ZConf::Runner;
use ZConf::GUI;

=head1 NAME

ZConf::Runner::GUI - Various GUI stuff for ZConf::Runner.

=head1 VERSION

Version 1.0.1

=cut

our $VERSION = '1.0.1';

=head1 SYNOPSIS

This provides the ask dialog used by ZConf::Runner.

    use ZConf::Runner::GUI;

    my $zcr=ZConf::Runner->new();

=head1 METHODS

=head2 new

This initializes it.

One arguement is taken and that is a hash value.

=head3 hash values

=head4 zcrunner

This is a ZConf::Runner object to use. If it is not specified,
a new one will be created.

=head4 zcgui

This is the ZConf::GUI object. If it is not passed, a new one will be created.

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $function='new';

	my $self={error=>undef, errorString=>undef, module=>'ZConf-Runner-GUI'};
	bless $self;

	#initiates
	if (!defined($args{zcrunner})) {
		$self->{zcr}=ZConf::Runner->new();
	}else {
		$self->{zcr}=$args{zcrunner};
	}

	#handles it if initializing ZConf::Runner failed
	if ($self->{zcr}->{error}) {
		my $errorstring=$self->{zcr}->{errorString};
		$errorstring=~s/\"/\\\"/g;
		my $error='Initializing ZConf::Runner failed. error="'.$self->{zcr}->{error}
		          .'" errorString="'.$self->{zcr}->{errorString}.'"';
	    $self->{error}=3;
		$self->{errorString}=$error;
		warn('ZConf-GUI new:3: '.$error);
		return $self;		
	}

	$self->{zconf}=$self->{zcr}->{zconf};

	if (!defined($args{zcgui})) {
		#initializes the GUI
		$self->{gui}=ZConf::GUI->new({zconf=>$self->{zconf}});
		if ($self->{gui}->{error}) {
			my $errorstring=$self->{gui}->{errorString};
			$errorstring=~s/\"/\\\"/g;
			my $error='Initializing ZConf::GUI failed. error="'.$self->{gui}->{error}
		          .'" errorString="'.$self->{gui}->{errorString}.'"';
			$self->{error}=2;
			$self->{errorString}=$error;
			warn('ZConf-Runner-GUI new:2: '.$error);
			return $self;
		}
	}else {
		$self->{gui}=$args{zcgui};
	}

	$self->{useX}=$self->{gui}->useX('ZConf::Runner');

	my @preferred=$self->{gui}->which('ZConf::Runner');

	my $toeval='use ZConf::Runner::GUI::'.$preferred[0].';'."\n".
	           '$self->{be}=ZConf::Runner::GUI::'.$preferred[0].
			   '->new({zconf=>$self->{zconf}, useX=>$self->{useX},'.
			   'zcgui=>$self->{gui}, zcrunner=>$self->{zcr}}); return 1';

	my $er=eval($toeval);
	
	return $self;
}

=head2 ask

This is creates a dialog window asking what to do.

The first agruement is the action to be performed. The
second is the file it is to be performed on. The third
is an optional hash. It's accepted keys are as below.

=head3 hash args

Both hash args are currently required.

=head4 action

This is the action to be performed on the object.

=head4 object

This is the object to act on.

    my $returned=$zcr->ask({action=>'view', object=>'/tmp/test.rdf'});
    if($zcr->{error}){
        print "Error!\n";
    }else{
        if($returned){
            print "Action setup.\n";
        }
    }

=cut

sub ask{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	$self->errorblank;

	my $returned=$self->{be}->ask(\%args);
	if ($self->{be}->{error}) {
		$self->{error}=5;
		$self->{errorString}='Backend errored. error="'.$self->{error}.'" '.
		                     'errorString=>"'.$self->{errorString}.'"';
		warn('ZConf-Runner-GUI ask:5: '.$self->{errorString});
		return undef;
	}

	return $returned;
}

=head2 dialogs

This returns the available dailogs.

=cut

sub dialogs{
	return ('ask');
}

=head2 windows

This returns a list of available windows.

=cut

sub windows{
	return ();
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

	$self->{error}=undef;
	$self->{errorString}="";

	return 1;
}

=head1 DIALOGS

ask

=head1 WINDOWS

At this time, no windows are supported.

=head1 ERROR CODES

=head2 1

This means ZConf errored.

=head2 2

Initializing ZConf::GUI failed.

=head2 3

Initializing ZConf::Runner failed.

=head2 4

Failed to initailize the primary backend.

=head2 5

Backend errored.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-runner at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-Runner>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::Runner


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-Runner>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-Runner>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-Runner>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-Runner>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::Runner
