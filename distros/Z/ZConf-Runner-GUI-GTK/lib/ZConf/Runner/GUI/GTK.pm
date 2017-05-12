package ZConf::Runner::GUI::GTK;

use warnings;
use strict;
use Gtk2;
use Gtk2::SimpleList;
use ZConf::Runner;
use File::MimeInfo::Magic;
use File::MimeInfo::Applications;

=head1 NAME

ZConf::Runner::GUI::GTK - The GTK GUI backend for ZConf::Runner.

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';


=head1 SYNOPSIS

    use ZConf::Runner::GUI::GTK;

    my $zcrgg = ZConf::Runner::GUI::GTK->new();
    ...

=head1 METHODS

=head2 new

This initializes it.

One arguement is taken and that is a hash value.

=head3 hash values

=head4 zcrunner

This is a ZConf::Runner object to use. If it is not specified,
a new one will be created.

    my $zcrgg = ZConf::Runner::GUI::GTK->new({zcrunner=>$zcrunner});
    if($zcrgg->{error}){
        print "Error!\n";
    }

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

	#get the ZConf object
	$self->{zconf}=$self->{zcr}->{zconf};

	return $self;
}

=head2 ask

See ZConf::Runner::GUI for more information.

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

	#check if it is setup already
    my $isSetup=$self->{zcr}->actionIsSetup($mimetype, $action);
	my %action;
	if ($isSetup) {
		%action=$self->{zcr}->getAction($mimetype, $action);
		if ($self->{zcr}->{error}) {
			$self->{error}=3;
			$self->{errorString}='ZConf::Runner errored. error="'.
			                     $self->{zcr}->{error}.'" errorString="'.
								 $self->{zcr}->{errorString}.'"';
			warn('ZConf-Runner-GUI-GTK ask:3: '.$self->{errorString});
			return undef;
		}
		if (!defined($action{do})) {
			$isSetup=0;
		}
		if (!defined($action{type})) {
			$isSetup=0;
		}else {
			if (($action{type} ne 'desktop') && ($action{type} ne 'exec')) {
				$isSetup=0;
			}
		}
	}

	#get possible applications
	my ($default, @others) = mime_applications_all($mimetype);
	my @othersNames;
	my $int=0;
	while ( defined($others[$int]) ) {
		$othersNames[$int]=$others[$int]->{file};
		$othersNames[$int]=~s/.*\///;
		$othersNames[$int]=~s/\.desktop$//;
		$othersNames[$int]=~s/\n//;		

		$int++;
	}

	#this makes sure we got a mimetype
	if (!defined($mimetype)) {
		$self->{error}=1;
		$self->{errorString}='Could not determime the mimetype for "'.$object.'"';
		warn('ZConf-Runner-GUI-GTK ask:2: '.$self->{errorString});
		return undef;
	}

	my %gui;

	Gtk2->init;

	$gui{window}=Gtk2::Window->new();

	$gui{VH}=Gtk2::VBox->new;
	$gui{VH}->show;

	#puts together the part that displays the object
	$gui{objectHB}=Gtk2::HBox->new;
	$gui{objectHB}->show;
	$gui{objectInfo}=Gtk2::Entry->new;
	$gui{objectInfo}->set_editable(0);
	$gui{objectInfo}->set_text($object);
	$gui{objectInfo}->show;
	$gui{objectLabel}=Gtk2::Label->new('Object:');
	$gui{objectLabel}->show;
	$gui{objectHB}->pack_start($gui{objectLabel}, 0, 0, 0);
	$gui{objectHB}->pack_start($gui{objectInfo}, 1, 1, 0);
	$gui{VH}->pack_start($gui{objectHB}, 0, 0, 0);

	#the action stuff
	$gui{actionHB}=Gtk2::HBox->new;	
	$gui{actionHB}->show;
	$gui{actionInfo}=Gtk2::Entry->new;
	$gui{actionInfo}->set_editable(0);
	$gui{actionInfo}->set_text($action);
	$gui{actionInfo}->show;
	$gui{actionLabel}=Gtk2::Label->new('Action:');
	$gui{actionLabel}->show;
	$gui{actionHB}->pack_start($gui{actionLabel}, 0, 0, 0);
	$gui{actionHB}->pack_start($gui{actionInfo}, 1, 1, 0);
	$gui{VH}->pack_start($gui{actionHB}, 0, 0, 0);

	#the mime stuff stuff
	$gui{mimeHB}=Gtk2::HBox->new;
	$gui{mimeHB}->show;
	$gui{mimeInfo}=Gtk2::Entry->new;
	$gui{mimeInfo}->set_editable(0);
	$gui{mimeInfo}->set_text($mimetype);
	$gui{mimeInfo}->show;
	$gui{mimeLabel}=Gtk2::Label->new('MIME type:');
	$gui{mimeLabel}->show;
	$gui{mimeHB}->pack_start($gui{mimeLabel}, 0, 0, 0);
	$gui{mimeHB}->pack_start($gui{mimeInfo}, 1, 1, 0);
	$gui{VH}->pack_start($gui{mimeHB}, 0, 0, 0);

	#add a seperator
	$gui{hbar1}=Gtk2::HSeparator->new;
	$gui{hbar1}->show;
	$gui{VH}->pack_start($gui{hbar1}, 0, 0, 0);

	#entry stuff
	$gui{desktopLabel}=Gtk2::Label->new('Desktop Entries');
	$gui{desktopLabel}->show;
	$gui{VH}->pack_start($gui{desktopLabel}, 0, 0, 0);
	$gui{defaultHB}=Gtk2::HBox->new;
	$gui{defaultHB}->show;
	$gui{defaultInfo}=Gtk2::Entry->new;
	if (defined($default)) {
		$gui{defaultInfo}->set_text($default);
		$gui{defaultInfo}->set_editable(0);
		$gui{defaultInfo}->show;
		$gui{defaultLabel}=Gtk2::Label->new('Default:');
		$gui{defaultLabel}->show;
		$gui{defaultHB}->pack_start($gui{defaultLabel}, 0, 0, 0);
		$gui{defaultHB}->pack_start($gui{defaultInfo}, 1, 1, 0);
	}else {
		$gui{defaultLabel}=Gtk2::Label->new('Default: n/a');
		$gui{defaultLabel}->show;
		$gui{defaultHB}->pack_start($gui{defaultLabel}, 0, 0, 0);
	}
	$gui{VH}->pack_start($gui{defaultHB}, 0, 0, 0);
	$gui{entriesSL}=Gtk2::SimpleList->new(
										   'Entries'=>'text',
										   );
	$gui{entriesSL}->get_selection->set_mode('single');
	$gui{entriesSL}->show;
	push(@{$gui{entriesSL}->{data}}, @othersNames);
	$int=0;
	if (!defined($default)) {
		$default='';
	}
	#if this is the current type, select the specified one if possible
	#otherwise select the default
	#failing the default, select the first
	if ($isSetup && ($action{type} eq 'desktop')) {
		while (defined($othersNames[$int])) {
			if ($othersNames[$int] eq $action{do}) {
				$gui{entriesSL}->select($int);
			}
			
			$int++;
		}
	}else {
		#select the default on in the list if possible
		my $othersMatched=0;
		while (defined($othersNames[$int])) {
			if ($othersNames[$int] eq $default) {
				$gui{entriesSL}->select($int);
				$othersMatched=1;
			}
			
			$int++;
		}
		#if not found, select the first one if possible
		if (!$othersMatched && defined($othersNames[0])) {
			$gui{entriesSL}->select(0);
		}
	}
	$gui{VH}->pack_start($gui{entriesSL}, 1, 1, 0);

	#add a seperator
	$gui{hbar2}=Gtk2::HSeparator->new;
	$gui{hbar2}->show;
	$gui{VH}->pack_start($gui{hbar2}, 0, 0, 0);


	#execute stuff
	$gui{executeLabel}=Gtk2::Label->new('Manual');
	$gui{executeLabel}->show;
    $gui{execHB}=Gtk2::HBox->new;
	$gui{execHB}->show;
	$gui{execLabel}=Gtk2::Label->new('exec:');
	$gui{execLabel}->show;
	$gui{execEntry}=Gtk2::Entry->new();
	$gui{execEntry}->set_editable(1);
	if ($isSetup && ($action{type} eq 'exec')) {
		$gui{execEntry}->set_text($action{do});		
	}
	$gui{execEntry}->show;
	$gui{execLabel2}=Gtk2::Label->new('"%f" will be replaced by the filename when it is ran.');
	$gui{execLabel2}->show;
	$gui{VH}->pack_start($gui{executeLabel}, 0, 0, 0);
	$gui{execHB}->pack_start($gui{execLabel}, 0, 0, 0);
	$gui{execHB}->pack_start($gui{execEntry}, 1, 1, 0);
	$gui{VH}->pack_start($gui{execHB}, 0, 0, 0);
	$gui{VH}->pack_start($gui{execLabel2}, 0, 0, 0);

	#add a seperator
	$gui{hbar3}=Gtk2::HSeparator->new;
	$gui{hbar3}->show;
	$gui{VH}->pack_start($gui{hbar3}, 0, 0, 0);	
	
	#select which to use
	$gui{selectLabel}=Gtk2::Label->new('Do you wish to use a desktop entry or a manualy specified program?');
	$gui{selectLabel}->show;
	$gui{VH}->pack_start($gui{selectLabel}, 0, 0, 0);
	$gui{selectCB}=Gtk2::ComboBox->new_text();
	$gui{selectCB}->append_text('Desktop Entry');
	$gui{selectCB}->append_text('Manual');
	#select which it should be set to
	if ($isSetup) {
		if ($action{type} eq 'desktop') {
			$gui{selectCB}->set_active(0);
		}else {
			$gui{selectCB}->set_active(1);
		}
	}else {
		$gui{selectCB}->set_active(0);
	}
	$gui{selectCB}->show;
	$gui{VH}->pack_start($gui{selectCB}, 0, 0, 0);

	#add a seperator
	$gui{hbar4}=Gtk2::HSeparator->new;
	$gui{hbar4}->show;
	$gui{VH}->pack_start($gui{hbar4}, 0, 0, 0);	

	#this is what will be returned
	my $toreturn=undef;

	#cancel and accept buttons
	$gui{buttonHB}=Gtk2::HBox->new;
	$gui{acceptLabel}=Gtk2::Label->new('Accept');
	$gui{cancelLabel}=Gtk2::Label->new('Cancel');
	$gui{accept}=Gtk2::Button->new();
	$gui{accept}->add($gui{acceptLabel});
	$gui{accept}->signal_connect(clicked=>sub{
									 #get the select type and convert it to the proper value
									 my $typeInt=$gui{selectCB}->get_active;
									 my $type;
									 if ($typeInt eq '0') {
										 $type='desktop';
									 }else {
										 $type='exec';
									 }

									 #get what to do for a exec type
									 my $do;
									 if ($type eq 'exec') {
										 $do=$gui{execEntry}->get_text;
									 }
									 if ($type eq 'desktop') {
										 my @selectedA=$gui{entriesSL}->get_selected_indices;
										 my $selected=$selectedA[0];
										 $do=$othersNames[$selected];
									 }

									 #update it
									 $self->{zcr}->newRunner({
															  mimetype=>$mimetype,
															  action=>$action,
															  type=>$type,
															  do=>$do,
															  });
									 if ($self->{zcr}->{error}) {
										 $self->{error}=2;
										 $self->{errorString}='Failed to update ZConf';
										 warn('ZConf-Runner-GUI-GTK ask:2: '.$self->{errorString});
										 return undef;
									 }

									 $toreturn=1;

									 Gtk2->main_quit;
								 });
	$gui{cancel}=Gtk2::Button->new();
	$gui{cancel}->add($gui{cancelLabel});	
	$gui{cancel}->signal_connect(clicked=>sub{
									 Gtk2->main_quit;
								 });
	$gui{buttonHB}->pack_start($gui{accept}, 1, 1, 0);
	$gui{buttonHB}->pack_start($gui{cancel}, 1, 1, 0);
	$gui{VH}->pack_start($gui{buttonHB}, 0, 0, 0);

	#
	$gui{window}->signal_connect('delete-event'=>sub{
									 Gtk2->main_quit;
								 });

	$gui{window}->add($gui{VH});

	$gui{window}->show_all;
	Gtk2->main;

	return $toreturn;
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

=head1 ERROR CODEs

=head2 1

Could not get the mimetype.

=head2 2

Failed to update ZConf.

=head2 3

ZConf::Runner issued an error.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-runner-gui-gtk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-Runner-GUI-GTK>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::Runner::GUI::GTK


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-Runner-GUI-GTK>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-Runner-GUI-GTK>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-Runner-GUI-GTK>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-Runner-GUI-GTK>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::Runner::GUI::GTK
