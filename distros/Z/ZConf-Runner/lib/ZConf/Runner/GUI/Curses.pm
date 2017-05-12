package ZConf::Runner::GUI::Curses;

use warnings;
use strict;
use ZConf::Runner;
use File::MimeInfo::Magic;
use File::MimeInfo::Applications;

=head1 NAME

ZConf::Runner::GUI::Curses - Run a file using a choosen methode, desktop entry or mimetype.

=head1 VERSION

Version 1.0.1

=cut

our $VERSION = '1.0.1';

=head1 SYNOPSIS

This provides the Curses backend for ZConf::Runner::GUI.

    use ZConf::Runner::GUI::Curses;

    my $zcr=ZConf::Runner::GUI::Curses->new();

=head1 METHODES

=head2 new

This initializes it.

One arguement is taken and that is a hash value.

=head3 hash values

=head4 useX

This is if it should try to use X or not. If it is not defined,
ZConf::GUI->useX is used.

=head4 zcgui

This is the ZConf::GUI object. A new one will be created if it is
not passed.

=head4 zcrunner

This is a ZConf::Runner object to use. If it is not specified,
a new one will be created.

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	my $self={error=>undef, errorString=>undef};
	bless $self;

	#initiates
	if (defined($args{zcrunner})) {
		$self->{zcr}=$args{zcrunner};
	}else {
		$self->{zcr}=ZConf::Runner->new();
	}

	$self->{zconf}=$self->{zcr}->{zconf};

	#
	if (defined($args{useX})) {
		$self->{useX}=$args{useX};
	}else {
		use ZConf::GUI;
		$self->{useX}=ZConf::GUI->new({zconf=>$self->{zconf}});
	}
	
	return $self;
}

=head2 ask

Please see the documentation for ZConf::Runner::GUI->ask.

=cut

sub ask{
	my $self=$_[0];
	my %args;
	if (defined($_[1])) {
		%args= %{$_[1]};
	}
	#blanks any previous errors
	$self->errorblank;

	my $action=$args{action};
	my $object=$args{object};

	#gets the mimetype for the object
	my $mimetype=mimetype($object);

	#this makes sure we got a mimetype
	if (!defined($mimetype)) {
		warn('ZConf-Runner ask:12: Could not determime the mimetype for "'.$object.'"');
		$self->{error}=12;
		$self->{errorString}='Could not determime the mimetype for "'.$object.'"';
		return undef;;
	}

	my $terminal='xterm -rv -e ';
	#if the enviromental variable 'TERMINAL' is set, use 
	if(defined($ENV{TERMINAL})){
		$terminal=$ENV{TERMINAL};
	}

	#escapes it for executing it
	my $eAction=$action;
	$eAction=~s/\"/\\\"/g;
	my $eObject=$object;
	$eObject=~s/\"/\\\"/g;

	my $askcommand='perl -e \'use ZConf::Runner::GUI::Curses;'.
	               'my $zcr=ZConf::Runner::GUI::Curses->new(); '.
			       '$zcr->askGUI({action=>"'.$eAction.'", object=>"'.$eObject.'"});\'';

	if ($self->{useX}) {
		system($terminal.' '.$askcommand);
		if ($? == -1) {
			warn("ZConf-Runner ask:15: Failed to '".$terminal.' '.$askcommand."'");
			$self->{error}=15;
			$self->{errorString}="Failed to '".$terminal.' '.$askcommand."'";
			return undef;
		}

		#we reread it to get any changes
		$self->{zconf}->read({config=>'runner'});
		if ($self->{zconf}->{error}) {
			warn('ZConf-Runner-GUI-Curses ask:2: ZConf errored with "'.$self->{zconf}->{error}.
				 '" when trying to reread the ZConf config "runner". errorString="'.
				 $self->{zconf}->{errorString}.'"');
			return undef;
		}

		my $returned=$self->{zcr}->actionIsSetup($mimetype, $action);
		if ($self->{error}) {
			warn('ZConf-Runner ask: actionIsSetup("'.$mimetype.'", "'
				 .$action.'") failed');
			return undef;
		}

		#we just assume yes was pushed right now as it is impossible to get
		#the exit status from something executed using xterm
		return $returned;
	}else {
		system($askcommand);
		my $exitcode=$? >> 8;
		if ($? == -1) {
			warn("ZConf-Runner-GUI-Curses ask:15: Failed to '".$askcommand."'");
			$self->{error}=15;
			$self->{errorString}="Failed to '".$askcommand."'";
			return undef;
		}

		#if Quit was selected, just return undef, but don't error
		if ($exitcode == 14) {
			return undef;
		}

		#if ok was selected and it added with out issue
		if ($exitcode == 15) {
			return 1;
		}

		#if we get here, it means we errored
		warn("ZConf-Runner ask:16: '".$askcommand."' failed with a exit of '".
			 $exitcode."'");
		$self->{error}=16;
		$self->{errorString}="'".$askcommand."' failed with a exit of '".$exitcode."'";
		return undef;
	}
}

=head2 askGUI

This handles the actual GUI. Do to the nature of Curses::UI, do not call this directly
as it will result in your application exiting.

=cut

sub askGUI{
	my $self=$_[0];
	my %args;
	if (defined($_[1])) {
		%args= %{$_[1]};
	}

	my $action=$args{action};
	my $object=$args{object};

	#blanks any previous errors
	$self->errorblank;

	#gets the mimetype for the object
	my $mimetype=mimetype($object);

	#this makes sure we got a mimetype
	if (!defined($mimetype)) {
		warn('ZConf-Runner-GUI-Curses ask:12: Could not determime the mimetype for "'.$object.'"');
		$self->{error}=12;
		$self->{errorString}='Could not determime the mimetype for "'.$object.'"';
		exit 12;
	}

	#get possible applications
	my ($default, @others) = mime_applications_all($mimetype);

	#builds the desktop entry array and  desktop entry array
	#the array is used for the values
	#the hash is used for the the listbox display
	my @deA;
	my %deH;
	my $int=0;
	#only do the following if it is defined
	if (defined($default)){
		$deA[0]=$default->{file};
		$deA[0]=~s/.*\///;
		$deA[0]=~s/\.desktop$//;
		$deA[0]=~s/\n//;
		
		$deH{$deA[0]}='*'.$default->get('Name');
		
		#we bump this to one as $deA[0] has been setup already
		$int=1;
	}
	my $otherInt=0;
	while (defined($others[$int])) {
		$deA[$int]=$others[$otherInt]->{file};
		$deA[$int]=~s/.*\///;
		$deA[$int]=~s/\.desktop$//;
		$deA[$int]=~s/\n//;		

		$deH{$deA[$int]}=$others[$otherInt]->get('Name');

		$otherInt++;
		$int++;
	}

	use Curses::UI;
	my $cui = Curses::UI->new( -clear_on_exit => 1);

	#creates the window
	my $win = $cui->add('window', 'Window', {});

	#creates the container
	my $container = $win->add('container', 'Container');

	#creates the label for the subject text entry
	my $mimetypeLabel=$container->add('mimetypeLabel', 'Label', -y=>0,
									  -Text=>'Mimetype: '.$mimetype );

	#this is the label for the desktop entry list box
	my $desktopLBlabel=$container->add('desktopLBlabel', 'Label', -y=>2, -width=>26,
									   -Text=>'Available Desktop Entries:');

	#this just labels the three items after it as being desktop values
	my $desktopValues=$container->add('desktopValues', 'Label', -y=>13,
									   -Text=>'Desktop Entry Values:');

	#the name of the desktop entry
	my $desktopName=$container->add('desktopName', 'Label', -y=>14, -width=>80,
									   -Text=>'Name: ');

	#what the desktop entry executes
	my $desktopExec=$container->add('desktopExec', 'Label', -y=>15, -width=>80,
									   -Text=>'Exec: ');

	#the comment for the desktop entry
	my $desktopComment=$container->add('desktopComment', 'Label', -y=>16, -width=>80,
									   -Text=>'Comment: ');

	#this allows selection of the what desktop entry to use
	my $desktopLB=$container->add('desktopLB', , 'Listbox', -y=>3,
								  -width=>30, -height=>8, -border=>1,
								  -values=>\@deA,
								  -labels=>\%deH,
								  -radio=>1,
								  name=>$desktopName,
								  exec=>$desktopExec,
								  comment=>$desktopComment,
								  -onchange=>sub{
									  my $self=$_[0];
									  my $entry = File::DesktopEntry->new($self->get());
									  $self->{name}->text('Name: '.$entry->get('Name'));
									  $self->{exec}->text('Exec: '.$entry->get('Exec'));
									  $self->{comment}->text('Comment: '.$entry->get('Comment'));
											 }
								  );

	#sets the selection to the first one
	if (defined($deA[0])) {
		$desktopLB->set_selection($deA[0]);
	}

	#the label for the type
	my $typeLabel=$container->add('typeLabel', 'Label', -y=>2, -x=>30,
									   -Text=>'Type:');

	#this is the type
	my $typeLB=$container->add('typeLB', , 'Listbox', -y=>3, -x=>30,
								  -width=>'13', -height=>8, -border=>1,
								  -values=>['desktop', 'exec'],
								  -labels=>{'desktop'=>'Desktop', 'exec'=>'Exec'},
								  -radio=>1
								  );
	$typeLB->set_selection('desktop'); #default to desktop

	#various notes
	my $defaultSymbol=$container->add('defaultSymbol', 'Label', -y=>11,
									   -Text=>'*=default        Exec: %f=file');

	#label the exec
	my $execLabel=$container->add('execLabel', 'Label', -y=>12,
									   -Text=>'Exec:');

	#allows the exec to be updated
	my $execEditor=$container->add('execEditor', 'TextEntry', -y=>12, -x=>6);


	#the various buttons...
	my $buttons=$container->add('buttons',
								'Buttonbox',
								-y=>1,
								desktopLB=>$desktopLB,
								typeLB=>$typeLB,
								exec=>$execEditor,
								zcr=>$self->{zcr},
								mimetype=>$mimetype,
								action=>$action,
								-buttons=>[{-label=>'Quit',
											-value=>'quit',
											-onpress=>sub{
												exit 14;
											},
											},
										   {
											-label=>'Ok',
											-value=>'ok',
											-onpress=>sub{
												my $self=$_[0];
												my $entry=$self->{desktopLB}->get();
												my $type=$self->{typeLB}->get();
												my $exec=$self->{exec}->get();
												my $mimetype=$self->{mimetype};

												#error if desktop is selected and none
												#exist or is selected
												if (($type eq 'desktop') &&
													!defined($entry)) {
													warn('ZConf-Runner-GUI-Curses askGUI:14: No desktop entry'.
														 'specified or none exists for this mimetype.');
													#we are not going to set the error or etc here
													#as we exit.
													exit 16;
												}
												
												
												#figures out what the do should be
												my $do=undef;
												if ($type eq 'desktop') {
													$do=$entry;
												}else {
													$do=$exec;
												}

												#
												$self->{zcr}->newRunner({
																		 mimetype=>$mimetype,
																		 action=>$action,
																		 type=>$type,
																		 do=>$do
																		 }
																		);

												#checks for any errors
												if ($self->{zcr}->{error}) {
													exit 17;
												}

												#exit ok
												exit 15;
											}
											}
										   ]
								);

	#start the CUI loop...
	#there is no return outside of exit from here :(
	$cui->mainloop;
	return;
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
	return undef;
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

=head1 dialogs

ask

=head1 windows

At this time, no windows are supported.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-runner at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-Runner>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::Runner::GUI::Curses


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

1; # End of ZConf::Runner::GUI::Curses
