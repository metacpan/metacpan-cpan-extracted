package ZConf::BGSet::GUI::GTK;

use warnings;
use strict;
use ZConf::BGSet;
use Gtk2;
use Gtk2::Ex::Simple::List;

=head1 NAME

ZConf::BGSet::GUI::GTK - GTK GUI for ZConf::BGSet

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Gtk2 -init;
    use ZConf::BGSet::GUI::GTK;

    my $zbgGTK = ZConf::BGSet::GUI::GTK->new();
    
    my $window = Gtk2::Window->new ('toplevel');
    
    my $zbgGUI=ZConf::BGSet::GUI::GTK->new({autoinit=>'1'});
    
    my $item=$zbgGUI->notebook();
    
    $window->add($item);
    
    $window->signal_connect('delete-event'=>sub{exit 0});

    $window->show_all;
    
    Gtk2->main;

=head1 METHODES

=head2 new

This initiates the module.

=head3 hash values

=head4 autoinit

If this is set to true, it will automatically call
init the set and config. If this is set to false or
not defined, besure to check '$zbg->{init}' to see
if the config/module has been initiated or not.

=head4 set

This is the set to load initially.

=head4 zconf

If this key is defined, this hash will be passed to ZConf->new().

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	#
	my $self={error=>undef, errorString=>undef};
	bless $self;

	$self->{zbg}=ZConf::BGSet->new(\%args);
	if ($self->{zbg}->{error}) {
		warn('ZConf-BGSet-GUI-GTK new: Initializing "ZConf::BGSet" failed. '.
			 'error="'.$self->{zbg}->{error}.'" errorString="'.
			 $self->{zbg}->{errorString}.'"');
		$self->{error}=1;
		$self->{errorString}='Initializing "ZConf::BGSet" failed. '.
		                     'error="'.$self->{zbg}->{error}.'" errorString="'.
                             $self->{zbg}->{errorString}.'"';
		return $self;
	}

	return $self;
}

=head2 addFSPath

Utility function for '$self->{pathsBewFSPathButton}'.

=cut

sub addFSPath{
	my $widget=$_[0];
	my $self=$_[1];

	my $file_chooser =  Gtk2::FileChooserDialog->new ('test',
													  undef,
													  'select-folder',
													  'gtk-cancel' => 'cancel',
													  'gtk-ok' => 'ok'
													  );

	#gets what directory to use
	my $dir=undef;
	if ('ok' eq $file_chooser->run){
		$dir=$file_chooser->get_filename;
	}else {
		#if it was canceled destroy it and return
		$file_chooser->destroy;
		return;
	}

	#destroys the chooser
	$file_chooser->destroy;

	#get the selected index
	my @selectedIndexA=$self->{pathsSList}->get_selected_indices;
	my $selectedIndex=$selectedIndexA[0];

	#gets the path
	my $pathName=$self->{pathsSList}->{data}[$selectedIndex][0];

	#gets the path as an array
	my @path=$self->{zbg}->getPath($pathName);

	#adds the path to the the path
	push(@path, $dir);

	#
	$self->{zbg}->setPath($pathName, \@path);

	@{$self->{pathsPathSList}->{data}}= @path;

}

=head2 askNewPath

This is the utility function called by '$self->{pathsNewPathButton}'.

=cut

sub askNewPath{
	my $widget=$_[0];
	my $self=$_[1];

	my $text='Name of new path?';

	my $window = Gtk2::Dialog->new($text,
								   undef,
								   [qw/modal destroy-with-parent/],
								   'gtk-cancel'     => 'cancel',
								   'gtk-save'     => 'accept',
								   );

	$window->set_position('center-always');
	
	$window->set_response_sensitive ('accept', 0);
	$window->set_response_sensitive ('reject', 0);
	
	my $vbox = $window->vbox;
	$vbox->set_border_width(5);

	my $label = Gtk2::Label->new_with_mnemonic($text);
	$vbox->pack_start($label, 0, 0, 1);
	$label->show;
	
	my $entry = Gtk2::Entry->new();
	$vbox->pack_end($entry, 0, 0, 1);
	$entry->show;
	
	$entry->signal_connect (changed => sub {
								my $text = $entry->get_text;
								$window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								$window->set_response_sensitive ('reject', 1);
							}
							);

	my $value;
	my $pressed;
	
	$window->signal_connect(response => sub {
								$value=$entry->get_text;
								$pressed=$_[1];
							}
							);
	#runs the dailog and gets the response
	#'cancel' means the user decided not to create a new set
	#'accept' means the user wants to create a new set with the entered name
	my $response=$window->run;
	
	$window->destroy;
	
	#set the pressed to reject if 
	if (($value eq '' )&&($pressed eq 'accept')) {
		$pressed='reject';
		return;
	}

	#add a new path
	my @newpath;
	$self->{zbg}->createPath($value, @newpath);

	#rebuild the path list
	my @paths=$self->{zbg}->listPaths();
   @{$self->{pathsSList}->{data}}=@paths;

}

=head2 chooseFile

Utility function for '$self->{setbgFileButton}'.

=cut

sub chooseFile{
	my $widget=$_[0];
	my $self=$_[1];

	my $file_chooser =  Gtk2::FileChooserDialog->new ('test',
													  undef,
													  'open',
													  'gtk-cancel' => 'cancel',
													  'gtk-ok' => 'ok'
													  );

	#creates a filter and adds image types to it
	my $filter=Gtk2::FileFilter->new;
	$filter->add_pattern('*.jpg');
	$filter->add_pattern('*.jpeg');
	$filter->add_pattern('*.gif');
	$filter->add_pattern('*.png');
	$filter->add_pattern('*.xmp');
	$filter->add_pattern('*.bmp');
	$filter->add_pattern('*.tif');
	$filter->add_pattern('*.tiff');

	#adds the filter to to the chooser
	$file_chooser->add_filter($filter);

	#gets what directory to use
	my $file=undef;
	if ('ok' eq $file_chooser->run){
		$file=$file_chooser->get_filename;
	}else {
		#if it was canceled destroy it and return
		$file_chooser->destroy;
		return;
	}

	#destroys the chooser
	$file_chooser->destroy;

	$self->{setbgFileEntry}->set_text($file);

}

=head2 history

This returns a scrolled window containing the last
several backgrounds.

=cut

sub history{
	my $self=$_[0];

	$self->{historySWindow}=Gtk2::ScrolledWindow->new;

	$self->{historySList} = Gtk2::Ex::Simple::List->new (
											 'Hostname'=>'text',
											 'Display'=>'text',
											 'Fill Type'=>'text',
											 'Image'=>'text'
											 );

	#add the slist to the scrolled window
	$self->{historySWindow}->add($self->{historySList});

	#sets them all as as uneditable
	$self->{historySList}->set_column_editable ('Hostname', 0);
	$self->{historySList}->set_column_editable ('Display', 0);
	$self->{historySList}->set_column_editable ('Fill Type', 0);
	$self->{historySList}->set_column_editable ('Image', 0);

	#fetches the last
	my $lastRaw=$self->{zbg}->getLastRaw;

	#splits up each line
	my @lines=split(/\n/, $lastRaw);

	my @list;

	my $int=0;#used for intering through @lines
	while (defined($lines[$int])) {
		my @line=split(/:/, $lines[$int],4);

		push(@{$self->{historySList}->{data}}, [$line[0], $line[1], $line[2], $line[3]]);

		$int++;
	}

	#shows the window
	$self->{historySWindow}->show;

	#show the list
	$self->{historySList}->show;

	return $self->{historySWindow};
}

=head2 notebook

This returns a notebook widget populated with everything.

=cut

sub notebook{
	my $self=$_[0];

	$self->{notebook}=Gtk2::Notebook->new;

	#sets up the history page
	$self->{notebookSetbgLabel}=Gtk2::Label->new('Set BG');
	$self->{notebook}->append_page($self->setbg(), $self->{notebookSetbgLabel});

	#sets up the history page
	$self->{notebookHistoryLabel}=Gtk2::Label->new('History');
	$self->{notebook}->append_page($self->history(), $self->{notebookHistoryLabel});

	#sets up the paths page
	$self->{notebookPathsLabel}=Gtk2::Label->new('Paths');
	$self->{notebook}->append_page($self->paths(), $self->{notebookPathsLabel});

	#sets up the setters page
	$self->{notebookSettersLabel}=Gtk2::Label->new('Setters');
	$self->{notebook}->append_page($self->setters(), $self->{notebookSettersLabel});

	#shows it... if this is not done set_current_page will not work
	$self->{notebook}->show_all;

	#set it to the set page
	$self->{notebook}->set_current_page('0');

	return $self->{notebook};
}

=head2 removeFSPath

This is the utility function used by '$self->{pathsRemoveFSPathButton}'.

=cut

sub removeFSPath{
	my $widget=$_[0];
	my $self=$_[1];

	#get the selected index
	my @selectedIndexA=$self->{pathsSList}->get_selected_indices;
	my $selectedIndex=$selectedIndexA[0];

	#gets the path
	my $pathName=$self->{pathsSList}->{data}[$selectedIndex][0];

	#get the selected index
	@selectedIndexA=$self->{pathsPathSList}->get_selected_indices;
	$selectedIndex=$selectedIndexA[0];

 	#gets the path
	my $FSpathName=$self->{pathsPathSList}->{data}[$selectedIndex][0];

	#gets the path as an array
	my @path=$self->{zbg}->getPath($pathName);

	my @newPath;
	my $int=0;
	while (defined($path[$int])) {
		if ($path[$int] ne $FSpathName) {
			push (@newPath, $path[$int]);
		}

		$int++;
	}

	$self->{zbg}->setPath($pathName, \@newPath);
	#don't update pathsPathSList if there was an error
	if ($self->{zbg}->{error}){
		return;
	}

	@{$self->{pathsPathSList}->{data}}=@newPath;
}

=head2 removePath

This is a utility function called by '$self->{pathsRemovePathButton}'.

=cut

sub removePath{
	my $widget=$_[0];
	my $self=$_[1];

	#get the selected index
	my @selectedIndexA=$self->{pathsSList}->get_selected_indices;
	my $selectedIndex=$selectedIndexA[0];

	#gets the path
	my $path=$self->{pathsSList}->{data}[$selectedIndex][0];

	#removes the path
	$self->{zbg}->delPath($path);


	#gets the paths and dumps them into the lists
	my @paths=$self->{zbg}->listPaths();
	@{$self->{pathsSList}->{data}}=@paths;

}


=head2 pathChanged

This is a utility function called by '$self->{pathsSList}'
upon a row being clicked on.

=cut

sub pathChanged{
	my $widget=$_[0];
	my $self=$_[1];

	#get the selected index
	my @selectedIndexA=$self->{pathsSList}->get_selected_indices;
	my $selectedIndex=$selectedIndexA[0];

	#get the list of paths
	my @paths=$self->{zbg}->listPaths();

	#gets the path
	my $pathName=$self->{pathsSList}->{data}[$selectedIndex][0];

	my $path=$self->{zbg}->{zconf}->{conf}{zbgset}{'paths/'.$pathName};
	my @pathA=split(/\n/, $path);
	@{$self->{pathsPathSList}->{data}}=@pathA;
}

=head2 paths

This returns a VBox for manipulating the paths.

=cut

sub paths{
	my $self=$_[0];

	#
	my @paths=$self->{zbg}->listPaths();

	#gets the name of the path
	my $pathName=$self->{zbg}->{zconf}->{conf}->{zbgset}{path};

	#
	$self->{pathsIndex}=undef;

	#
	my $int=0;
	while ($paths[$int]) {
		if ($pathName eq $paths[$int]) {
			$self->{pathsIndex}=$int;
		}

		$int++;
	}

	#creates the VBox
	$self->{pathsVBox}=Gtk2::VBox->new;

	#creates the VBox
	$self->{pathsHBox}=Gtk2::HBox->new;

	#adds the VBox to the HBox
	$self->{pathsVBox}->pack_start($self->{pathsHBox}, 1, 1, 0);

	#creates the SWindow
	$self->{pathsSWindow}=Gtk2::ScrolledWindow->new;

	#adds the paths to the SWindow
	$self->{pathsHBox}->pack_start($self->{pathsSWindow}, 1, 1, 0);

	#creates the SList of paths
	$self->{pathsSList} = Gtk2::Ex::Simple::List->new (
													   'Paths'=>'text',
													   );

	#
	$self->{pathsSList}->signal_connect("cursor-changed"=>\&pathChanged, $self);

	#this adds pathsSList to pathsSWindow
	$self->{pathsSWindow}->add($self->{pathsSList});

	#adds the paths to the SList
	push(@{$self->{pathsSList}->{data}}, @paths);

	#if the pathsIndex is defined, select it
	if (defined($self->{pathsIndex})) {
		$self->{pathsSList}->select($self->{pathsIndex});
	}

	#creates the SList of the paths in the path in question
	$self->{pathsPathSList} = Gtk2::Ex::Simple::List->new (
													   'File System Paths'=>'text',
													   );

	#creates the SWindow for the Path
	$self->{pathsPathSWindow}=Gtk2::ScrolledWindow->new;

	#this adds pathsPathSList to pathsPathSWindow
	$self->{pathsPathSWindow}->add($self->{pathsPathSList});

	#this adds pathsPathSWindow to pathsHBox
	$self->{pathsHBox}->pack_start($self->{pathsPathSWindow}, 1, 1, 0);

	#gets the path
	my $path=$self->{zbg}->{zconf}->{conf}{zbgset}{'paths/'.$pathName};

	#split up the path and add it to the SList for the path
	my @pathA=split(/\n/, $path);
	push(@{$self->{pathsPathSList}->{data}}, @pathA);

	#create and add the button bar
	$self->{pathsButtonBar}=Gtk2::HBox->new;
	$self->{pathsVBox}->pack_start($self->{pathsButtonBar}, 0, 0, 0);

	#creates the new path button
	$self->{pathsNewPathButton}=Gtk2::Button->new();
	$self->{pathsNewPathButtonLabel}=Gtk2::Label->new('New Path');
	$self->{pathsNewPathButton}->add($self->{pathsNewPathButtonLabel});
	$self->{pathsNewPathButton}->signal_connect("clicked"=>\&askNewPath,$self);
	$self->{pathsButtonBar}->pack_start($self->{pathsNewPathButton}, 1, 0, 0);

	#creates the remove path button
	$self->{pathsRemovePathButton}=Gtk2::Button->new();
	$self->{pathsRemovePathButtonLabel}=Gtk2::Label->new('Remove Path');
	$self->{pathsRemovePathButton}->add($self->{pathsRemovePathButtonLabel});
	$self->{pathsRemovePathButton}->signal_connect("clicked"=>\&removePath,$self);
	$self->{pathsButtonBar}->pack_start($self->{pathsRemovePathButton}, 1, 0, 0);

	#creates the new path button
	$self->{pathsNewFSPathButton}=Gtk2::Button->new();
	$self->{pathsNewFSPathButtonLabel}=Gtk2::Label->new('New FS Path');
	$self->{pathsNewFSPathButton}->add($self->{pathsNewFSPathButtonLabel});
	$self->{pathsNewFSPathButton}->signal_connect("clicked"=>\&addFSPath,$self);
	$self->{pathsButtonBar}->pack_start($self->{pathsNewFSPathButton}, 1, 0, 0);

	#creates the remove FS path button
	$self->{pathsRemoveFSPathButton}=Gtk2::Button->new();
	$self->{pathsRemoveFSPathButtonLabel}=Gtk2::Label->new('Remove FS Path');
	$self->{pathsRemoveFSPathButton}->add($self->{pathsRemoveFSPathButtonLabel});
	$self->{pathsRemoveFSPathButton}->signal_connect("clicked"=>\&removeFSPath,$self);
	$self->{pathsButtonBar}->pack_start($self->{pathsRemoveFSPathButton}, 1, 0, 0);

	return $self->{pathsVBox};
}

=head2 setbg

This returns a VBox containing widgets for setting the background.

=cut

sub setbg{
	my $self=$_[0];

	#creates the VBox
	$self->{setbgVBox}=Gtk2::VBox->new;

	#sets up the file HBox
	$self->{setbgFileHBox}=Gtk2::HBox->new(0,0);
	$self->{setbgVBox}->pack_start($self->{setbgFileHBox}, 0, 0, 0);
	$self->{setbgFileLabel}=Gtk2::Label->new('File');
	$self->{setbgFileHBox}->pack_start($self->{setbgFileLabel}, 0, 0, 0);
	$self->{setbgFileEntry}=Gtk2::Entry->new();
	$self->{setbgFileHBox}->pack_start($self->{setbgFileEntry}, 1, 1, 0);
	$self->{setbgFileButton}=Gtk2::Button->new();
	$self->{setbgFileButton}->signal_connect("clicked"=>\&chooseFile,$self);
	$self->{setbgFileButtonLabel}=Gtk2::Label->new('Select');
	$self->{setbgFileButton}->add($self->{setbgFileButtonLabel});
	$self->{setbgFileHBox}->pack_start($self->{setbgFileButton}, 0, 1, 0);
	$self->{setbgFT}=Gtk2::ComboBox->new_text();
	$self->{setbgFT}->append_text('auto');
	$self->{setbgFT}->append_text('center');
	$self->{setbgFT}->append_text('fill');
	$self->{setbgFT}->append_text('full');
	$self->{setbgFT}->append_text('tile');
	$self->{setbgFT}->set_active(0);
	$self->{setbgFileHBox}->pack_start($self->{setbgFT}, 0, 1, 0);
	$self->{setbgSet}=Gtk2::Button->new();
	$self->{setbgSet}->signal_connect("clicked"=>\&setFile,$self);
	$self->{setbgSetLabel}=Gtk2::Label->new('Set');
	$self->{setbgSet}->add($self->{setbgSetLabel});
	$self->{setbgFileHBox}->pack_start($self->{setbgSet}, 0, 1, 0);

	#sets up the rand HBox
	$self->{setbgRandHBox}=Gtk2::HBox->new(0,0);
	$self->{setbgVBox}->pack_start($self->{setbgRandHBox}, 0, 0, 0);
	$self->{setbgRandLabel}=Gtk2::Label->new('Random Path');
	$self->{setbgRandHBox}->pack_start($self->{setbgRandLabel}, 0, 0, 0);
	$self->{setbgPath}=Gtk2::ComboBox->new_text();
	$self->{setbgRandHBox}->pack_start($self->{setbgPath}, 0, 1, 0);
	$self->{setbgRandButton}=Gtk2::Button->new();
	$self->{setbgRandButton}->signal_connect("clicked"=>\&setRand,$self);
	$self->{setbgRandButtonLabel}=Gtk2::Label->new('Set Random');
	$self->{setbgRandButton}->add($self->{setbgRandButtonLabel});
	$self->{setbgRandHBox}->pack_start($self->{setbgRandButton}, 0, 1, 0);
	#builds the path list and set it to the default
	my @paths=$self->{zbg}->listPaths;
	my $path=$self->{zbg}->getDefaultPath;
	my $int=0;
	while (defined($paths[$int])) {
		$self->{setbgPath}->append_text($paths[$int]);
		if ($paths[$int] eq $path) {
			$self->{setbgPath}->set_active($int);
		}
		$int++;
	}

	#creates a  setlast line
	$self->{setbgLastHBox}=Gtk2::HBox->new(0,0);
	$self->{setbgVBox}->pack_start($self->{setbgLastHBox}, 0, 0, 0);
	$self->{setbgLastButton}=Gtk2::Button->new();
	$self->{setbgLastButtonLabel}=Gtk2::Label->new('Set Last');
	$self->{setbgLastButton}->add($self->{setbgLastButtonLabel});
	$self->{setbgLastHBox}->pack_start($self->{setbgLastButton}, 0, 1, 0);
	

	return $self->{setbgVBox};
}

=head2 setFile

Utility function for '$self->{setbgSet}'.

=cut

sub setFile{
	my $widget=$_[0];
	my $self=$_[1];

	my $file=$self->{setbgFileEntry}->get_text;

	my $ft=$self->{setbgFT}->get_active_text;

	$self->{zbg}->setBG({image=>$file, filltype=>$ft});

}

=head2 setRand

This is the utility function used by '$self->{setbgRandButton}'.

=cut

sub setRand{
	my $widget=$_[0];
	my $self=$_[1];

	my $pathIndex=$self->{setbgPath}->get_active;
	my @paths=$self->{zbg}->listPaths;
	my $path=$paths[$pathIndex];

	#sets it to a random file
	$self->{zbg}->setRand($path);

	#fetches the last
	my $lastRaw=$self->{zbg}->getLastRaw;

	#splits up each line
	my @lines=split(/\n/, $lastRaw);

	my @list;

	my @newHistory;
	my $int=0;#used for intering through @lines
	while (defined($lines[$int])) {
		my @line=split(/:/, $lines[$int],4);

		push(@newHistory, [$line[0], $line[1], $line[2], $line[3]]);

		$int++;
	}
	@{$self->{historySList}->{data}}=@newHistory;

}

=head2 setters

This returns a VBox that allow the setters to be edited.

=cut

sub setters{
	my $self=$_[0];

	#creates the VBox
	$self->{settersVBox}=Gtk2::VBox->new;

	#sets up the HBoxes
	$self->{settersHBoxFill}=Gtk2::HBox->new(0,0);
	$self->{settersHBoxFull}=Gtk2::HBox->new(0,0);
	$self->{settersHBoxTile}=Gtk2::HBox->new(0,0);
	$self->{settersHBoxCenter}=Gtk2::HBox->new(0,0);

	#creates the labels
	$self->{settersLabelCenter}=Gtk2::Label->new('Center');
	$self->{settersLabelFill}=Gtk2::Label->new('Fill');
	$self->{settersLabelFull}=Gtk2::Label->new('Full');
	$self->{settersLabelTile}=Gtk2::Label->new('Tile');

	#adds the labels
	$self->{settersHBoxCenter}->pack_start($self->{settersLabelCenter}, 0, 0, 0);
	$self->{settersHBoxFill}->pack_start($self->{settersLabelFill}, 0, 0, 0);
	$self->{settersHBoxFull}->pack_start($self->{settersLabelFull}, 0, 0, 0);
	$self->{settersHBoxTile}->pack_start($self->{settersLabelTile}, 0, 0, 0);

	#adds them all to the HBox
	$self->{settersVBox}->add($self->{settersHBoxCenter});
	$self->{settersVBox}->add($self->{settersHBoxFull});
	$self->{settersVBox}->add($self->{settersHBoxFill});
	$self->{settersVBox}->add($self->{settersHBoxTile});

	#adds the various text boxes
	$self->{settersEntryCenter}=Gtk2::Entry->new;
	$self->{settersEntryFull}=Gtk2::Entry->new;
	$self->{settersEntryFill}=Gtk2::Entry->new;
	$self->{settersEntryTile}=Gtk2::Entry->new;

	#sets the various texts
	$self->{settersEntryCenter}->set_text($self->{zbg}->getSetter('center'));
	$self->{settersEntryFill}->set_text($self->{zbg}->getSetter('fill'));
	$self->{settersEntryFull}->set_text($self->{zbg}->getSetter('full'));
	$self->{settersEntryTile}->set_text($self->{zbg}->getSetter('tile'));

	#adds the text entries to the HBoxes
	$self->{settersHBoxCenter}->pack_start($self->{settersEntryCenter}, 1, 1, 0);
	$self->{settersHBoxFill}->pack_start($self->{settersEntryFill}, 1, 1, 0);
	$self->{settersHBoxFull}->pack_start($self->{settersEntryFull}, 1, 1, 0);
	$self->{settersHBoxTile}->pack_start($self->{settersEntryTile}, 1, 1, 0);

	#sets up the info part
	$self->{settersInfo}=Gtk2::Label->new('"%%%THEFILE%%%" is replaced with the name of the file.');
	$self->{settersVBox}->add($self->{settersInfo});

	return $self->{settersVBox};
}


=head1 ERROR CODES

This can be found by checking $zbg->{error}. Only errors currently upon new.

=head2 1

Failed to initailize 'ZConf::BGSet'.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-bgset-gui-gtk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-BGSet-GUI-GTK>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::BGSet::GUI::GTK


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-BGSet-GUI-GTK>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-BGSet-GUI-GTK>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-BGSet-GUI-GTK>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-BGSet-GUI-GTK>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::BGSet::GUI::GTK
