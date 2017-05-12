package ZConf::Cron::GUI;

use warnings;
use strict;
use ZConf::Cron;
use ZConf::GUI;
use base 'Error::Helper';

=head1 NAME

ZConf::Cron::GUI - Implements a GUI for ZConf::Cron.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use ZConf::Cron::GUI;


    my $zcc=$ZConf::Cron->new;
    my $zccg=ZConf::Cron::GUI->new({zccron=>$zcc});


=head1 METHODS

=head2 new

This initializes it.

One arguement is taken and that is a hash value.

=head3 hash values

=head4 zccron

This is a ZConf::Cron object to use. If it is not specified,
a new one will be created.

=head4 zcgui

This is the ZConf::GUI object. If it is not passed, a new one will be created.

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	my $self={error=>undef, errorString=>undef};
	bless $self;

	#initiates
	if (!defined($args{zccron})) {
		$self->{zcc}=ZConf::Cron->new();
	}else {
		$self->{zcc}=$args{zccron};
	}

	#handles it if initializing ZConf::Runner failed
	if ($self->{zcc}->error) {
		my $errorstring=$self->{zcc}->errorString;
		$errorstring=~s/\"/\\\"/g;
		my $error='Initializing ZConf::Cron failed. error="'.$self->{zcc}->error
		          .'" errorString="'.$self->{zcc}->errorString.'"';
	    $self->{error}=3;
		$self->{errorString}=$error;
		$self->warn;
		return $self;		
	}

	$self->{zconf}=$self->{zcc}->{zconf};

	if (!defined($args{zcgui})) {
		#initializes the GUI
		$self->{gui}=ZConf::GUI->new({zconf=>$self->zconf});
		if ($self->{gui}->error) {
			my $errorstring=$self->{gui}->errorString;
			$errorstring=~s/\"/\\\"/g;
			my $error='Initializing ZConf::GUI failed. error="'.$self->{gui}->error
				.'" errorString="'.$self->{gui}->errorString.'"';
			$self->{error}=2;
			$self->{errorString}=$error;
			$self->warn;
			return $self;
		}
	}else {
		$self->{gui}=$args{zcgui};
	}

	$self->{useX}=$self->{gui}->useX('ZConf::Cron');

	my @preferred=$self->{gui}->which('ZConf::Cron');

	if (!defined($preferred[0])) {
		$self->{perror}=1;
		$self->{error}=4;
		$self->{errorString}='No backends located';
		$self->warn;
	}

	my $toeval='use ZConf::Cron::GUI::'.$preferred[0].';'."\n".
	           '$self->{be}=ZConf::Cron::GUI::'.$preferred[0].
			   '->new({zconf=>$self->{zconf}, useX=>$self->{useX},'.
			   'zcgui=>$self->{gui}, zccron=>$self->{zcc}}); return 1';

	my $er=eval($toeval);
	
	return $self;
}

=head2 crontab

This dialog allows crontabs to be edited.

   $zccg->crontab;
   if($zccg->error){
       print "Error!\n";
   }

=cut

sub crontab{
	my $self=$_[0];

	if ( ! $self->errorblank ){
		return undef;
	}

	my $returned=$self->{be}->crontab;
	if ($self->{be}->error) {
		$self->{error}=5;
		$self->{errorString}='Backend errored. error="'.$self->{be}->error.
		                     '" errorString="'.$self->{be}->errorString.'"';
		$self->warn;
	}

	return $returned;
}

=head2 dialogs

This returns the available dailogs.

=cut

sub dialogs{
	return ('crontab');
}

=head2 windows

This returns a list of available windows.

=cut

sub windows{
	return ();
}

=head1 DIALOGS

crontab

=head1 WINDOWS

At this time, no windows are supported.

=head1 ERROR CODES

=head2 1

This means ZConf errored.

=head2 2

Initializing ZConf::GUI failed.

=head2 3

Initializing ZConf::Cron failed.

=head2 4

Failed to initailize the primary backend.

=head2 5

Backend errored.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-runner at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-Runner>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::Cron::GUI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-Cron>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-Cron>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-Cron>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-Cron>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2012 Zane C. Bowers-Hadley, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::Cron::GUI
