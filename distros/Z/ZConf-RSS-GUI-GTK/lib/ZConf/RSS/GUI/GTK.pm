package ZConf::RSS::GUI::GTK;

use warnings;
use strict;
use ZConf::GUI;
use ZConf::RSS;
use ZConf::RSS::GUI;
use Gtk2;
use Gtk2::SimpleList;

=head1 NAME

ZConf::RSS::GUI::GTK - Providees the GTK backend for ZConf::RSS::GUI.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

    use ZConf::RSS::GUI::GTK;

    my $zcrssgtk = ZConf::RSS::GUI::GTK->new();
    ...

=head1 METHODS

=head2 new

=head3 args hash

=head4 obj

This is object returned by ZConf::RSS.

    my $zcrssgtk=ZConf::RSS::GUI::GTK->new({obj=>$obj});
    if($zcrssgtk->{error}){
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
			  module=>'ZConf-RSS-GUI-GTK',
			  gui=>{},
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

	Gtk2->init;

	return $self;
}

=head2 addFeed

This calls a dialog for creating a new feed. It will also init
Gtk2 and start it's main loop.

If GTK is already inited and you don't want the main loop exited,
use addFeedDialog.

One agruement is accepted and it is the URL to set it to by default.
If not specified, '' is used.

    $zcrssgtk->addFeed('http://foo.bar/rss.xml');
    if($zcrssgtk->{error}){
        print "Error!\n";
    }

=cut

sub addFeed{
	my $self=$_[0];
	my $url=$_[1];
	my $function='addFeed';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	Gtk2->init;

	my $guiID=$self->addFeedDialog({
									url=>$url,
									killmain=>1,
									});

	if ($self->{error}) {
		warn($self->{module}.' '.$function.': addFeedDialog errored');
		return undef;
	}

	return 1;
}

=head2 addFeedDialog

A dialog for adding a new feed.

One arguement is taken and it is a hash.

=head3 hash args

=head4 id

This is GUI ID to update after it is called. If this is not defined,
no attempted to update it will be made.

=head4 url

This is the URL to set it to initially. If this is not defined,
it is set to ''.

    $zcrssgtk->addFeedDialog({
                             url=>'http://foo.bar/rss.xml',
                             })
    if($zcrssgtk->{error}){
        print "Error!\n";
    }

=cut

sub addFeedDialog{
	my $self=$_[0];
	my $url=$_[1]{url};
	my $guiID=$_[1]{id};
	my $function='addFeedDialog';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	Gtk2->init;

	if (!defined($url)) {
		$url='';
	}

	my $window = Gtk2::Dialog->new('ZConf::RSS - Add new RSS feed?',
								   undef,
								   [qw/modal destroy-with-parent/],
								   'gtk-cancel'     => 'cancel',
								   'gtk-ok'     => 'accept',
								   );
	
	$window->set_position('center-always');
	
	$window->set_response_sensitive ('accept', 0);
	$window->set_response_sensitive ('reject', 0);
	
	my $vbox = $window->vbox;
	$vbox->set_border_width(5);
	
	my $label = Gtk2::Label->new_with_mnemonic('Add new RSS feed?');
	$vbox->pack_start($label, 0, 0, 1);
	$label->show;

	#url stuff
	my $ubox=Gtk2::HBox->new;
	$ubox->show;
	my $ulabel=Gtk2::Label->new('URL: ');
	$ulabel->show;
	$ubox->pack_start($ulabel, 0, 1, 0);
	my $uentry = Gtk2::Entry->new();
	$uentry->set_editable(1);
	$uentry->set_text($url);
	$uentry->show;
	$ubox->pack_start($uentry, 1, 1, 0);
	$vbox->pack_start($ubox, 0, 0, 1);
	
	#name stuff
	my $nhbox=Gtk2::HBox->new;
	$nhbox->show;
	my $nlabel=Gtk2::Label->new('name: ');
	$nlabel->show;
	$nhbox->pack_start($nlabel, 0, 1, 0);
	my $nentry = Gtk2::Entry->new();
	$nentry->set_text('');
	$nhbox->pack_start($nentry, 1, 1, 0);
	$nentry->show;	
	$vbox->pack_start($nhbox, 0, 0, 1);

	#top template stuff
	my $tthbox=Gtk2::HBox->new;
	$tthbox->show;
	my $ttlabel=Gtk2::Label->new('top template: ');
	$ttlabel->show;
	$tthbox->pack_start($ttlabel, 0, 1, 0);
	my $ttentry = Gtk2::Entry->new();
	$ttentry->set_text('defaultTop');
	$tthbox->pack_start($ttentry, 1, 1, 0);
	$ttentry->show;	
	$vbox->pack_start($tthbox, 0, 0, 1);

	#item template stuff
	my $ithbox=Gtk2::HBox->new;
	$ithbox->show;
	my $itlabel=Gtk2::Label->new('item template: ');
	$itlabel->show;
	$ithbox->pack_start($itlabel, 0, 1, 0);
	my $itentry = Gtk2::Entry->new();
	$itentry->set_text('defaultItem');
	$ithbox->pack_start($itentry, 1, 1, 0);
	$itentry->show;	
	$vbox->pack_start($ithbox, 0, 0, 1);

	#bottom template stuff
	my $bthbox=Gtk2::HBox->new;
	$bthbox->show;
	my $btlabel=Gtk2::Label->new('bottom template: ');
	$btlabel->show;
	$bthbox->pack_start($btlabel, 0, 1, 0);
	my $btentry = Gtk2::Entry->new();
	$btentry->set_text('defaultBottom');
	$bthbox->pack_start($btentry, 1, 1, 0);
	$btentry->show;	
	$vbox->pack_start($bthbox, 0, 0, 1);

	$uentry->signal_connect (changed => sub {
								my $text = $uentry->get_text;
								$window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								$window->set_response_sensitive ('reject', 1);
							}
							);

	$nentry->signal_connect (changed => sub {
								my $text = $nentry->get_text;
								$window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								$window->set_response_sensitive ('reject', 1);
							}
							);

	$ttentry->signal_connect (changed => sub {
								  my $text = $ttentry->get_text;
								  $window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								  $window->set_response_sensitive ('reject', 1);
							  }
							);

	$itentry->signal_connect (changed => sub {
								  my $text = $itentry->get_text;
								  $window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								  $window->set_response_sensitive ('reject', 1);
							  }
							);

	$btentry->signal_connect (changed => sub {
								  my $text = $btentry->get_text;
								  $window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								  $window->set_response_sensitive ('reject', 1);
							  }
							);
	
	my $name;
	my $top;
	my $item;
	my $bottom;
	my $pressed;
	
	
	$window->signal_connect(response => sub {
								$url=$uentry->get_text;
								$name=$nentry->get_text;
								$top=$ttentry->get_text;
								$item=$itentry->get_text;
								$bottom=$btentry->get_text;
								$pressed=$_[1];
							}
							);
	#runs the dailog and gets the response
	#'cancel' means the user decided not to create a new set
	#'accept' means the user wants to create a new set with the entered name
	my $response=$window->run;

	$window->destroy;

	if ($pressed ne 'accept') {
		return undef;
	}

	#add the bookmark
	$self->{obj}->setFeed({
						   feed=>$url,
						   name=>$name,
						   topTemplate=>$top,
						   bottomTemplate=>$bottom,
						   itemTemplate=>$item,
						   });
	if ($self->{obj}->{error}) {
		$self->{error}=3;
		$self->{errorString}='setFeed errored. error="'.$self->{obj}->{error}.'" errorstring="'.$self->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	if (!defined($guiID)) {
		return 1;
	}

	#update the stuff
	$self->updateFeedList( $guiID );
	
	return 1;
}

=head2 addTemplateDialog

A dialog for adding a new feed.

One arguement is taken and it is a the GUI ID for the manage VBox in question.


    $zcrssgtk->addFeedDialog( $guiID );
    if($zcrssgtk->{error}){
        print "Error!\n";
    }

=cut

sub addTemplateDialog{
	my $self=$_[0];
	my $guiID=$_[1];
	my $function='addTemplateDialog';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	if (!defined($guiID)) {
		$self->{error}=4;
		$self->{errorString}='No GUI ID specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	my $window = Gtk2::Dialog->new('ZConf::RSS - Add new template?',
								   undef,
								   [qw/modal destroy-with-parent/],
								   'gtk-cancel'     => 'cancel',
								   'gtk-ok'     => 'accept',
								   );
	
	$window->set_position('center-always');
	
	$window->set_response_sensitive ('accept', 0);
	$window->set_response_sensitive ('reject', 0);
	
	my $vbox = $window->vbox;
	$vbox->set_border_width(5);
	
	my $label = Gtk2::Label->new_with_mnemonic('Add new template?');
	$vbox->pack_start($label, 0, 0, 1);
	$label->show;

	
	#name stuff
	my $nhbox=Gtk2::HBox->new;
	$nhbox->show;
	my $nlabel=Gtk2::Label->new('name: ');
	$nlabel->show;
	$nhbox->pack_start($nlabel, 0, 1, 0);
	my $nentry = Gtk2::Entry->new();
	$nentry->set_text('');
	$nhbox->pack_start($nentry, 1, 1, 0);
	$nentry->show;	
	$vbox->pack_start($nhbox, 0, 0, 1);

	$nentry->signal_connect (changed => sub {
								my $text = $nentry->get_text;
								$window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								$window->set_response_sensitive ('reject', 1);
							}
							);
	
	my $name;
	my $pressed;
	
	$window->signal_connect(response => sub {
								$name=$nentry->get_text;
								$pressed=$_[1];
							}
							);
	#runs the dailog and gets the response
	#'cancel' means the user decided not to create a new set
	#'accept' means the user wants to create a new set with the entered name
	my $response=$window->run;

	$window->destroy;

	#kill the main if needed
	if ($_[1]{killmain}) {
		Gtk2->main_quit;
	}

	if ($pressed ne 'accept') {
		return undef;
	}

	#add the bookmark
	$self->{obj}->setTemplate($name, '');
	if ($self->{obj}->{error}) {
		$self->{error}=3;
		$self->{errorString}='setTemplate errored. error="'.$self->{obj}->{error}.'" errorstring="'.$self->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	if (!defined($guiID)) {
		return 1;
	}

	#update the stuff
	$self->updateTemplateList( $guiID );
	
	return 1;
}

=head2 manage

Invokes the view window.

    $zcrssgtk->manage;
    if($zcrssgtk->{error}){
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

	Gtk2->init;

	my $guiID=$self->manageWindow;
	$self->{gui}{$guiID}{window}->show;

	Gtk2->main;

	return 1;
}

=head2 manageVBox

This creates a VBox for the manage GUI and returns the GUI ID of it.

=head3 args hash

=head4 disableQuit

If this is set to true, the quit selection under the misc functions menu will not be present.

    my $guiID=$zcrssgtk->manageVBox;
    if($zcrssgtk->{error}){
        print "Error!\n";
    }else{
 	    $window=Gtk2::Window->new;
	    $window->set_default_size(750, 400);
	    $window->set_title('ZConf::RSS: manage');
        $window->add($zcrssgtk->{gui}{$guiID}{vbox});
    }

=cut

sub manageVBox{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $function='manageVBox';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	my %gui;

	$gui{id}=rand().rand().rand();

	#the main box
	$gui{vbox}=Gtk2::VBox->new;
	$gui{vbox}->show;
	$gui{hpaned}=Gtk2::HPaned->new;
	$gui{hpaned}->set_position(0);
	$gui{hpaned}->show;
	$gui{hpaned}->set_position(200);
	$gui{vbox}->pack_start($gui{hpaned}, 1, 1, 0);

	#puts together the basics for the list box
	$gui{listbox}=Gtk2::VBox->new;
	$gui{listbox}->show;
	$gui{hpaned}->add1($gui{listbox});
	#this is the menu bar that goes in the list box
	$gui{menubar}=Gtk2::MenuBar->new;
	$gui{menubarmenu}=Gtk2::MenuItem->new('_misc functions');
	$gui{menubar}->show;
	$gui{menubarmenu}->show;
	$gui{menubar}->append($gui{menubarmenu});
 	$gui{listbox}->pack_start($gui{menubar}, 0, 1, 0);
	#the window that holdes
	$gui{listSW}=Gtk2::ScrolledWindow->new;
	$gui{listSW}->show;
	$gui{listbox}->pack_start($gui{listSW}, 1, 1, 0);
	#puts the feed list stuff together
	$gui{templatelist}=Gtk2::SimpleList->new(
									   'Templates'=>'text',
									   );
	$gui{templatelist}->get_selection->set_mode ('single');
	$gui{templatelist}->show;
	$gui{templatelist}->signal_connect(row_activated=>sub{
									   $_[3]{self}->updateTemplateText($_[3]{id});
								   },
								   {
									self=>$self,
									id=>$gui{id},
									}
								   );
	$gui{listSW}->add($gui{templatelist});

	#puts together the menu
	$gui{menu}=Gtk2::Menu->new;
	$gui{menu}->show;
	#add
	$gui{menuAdd}=Gtk2::MenuItem->new('_add');
	$gui{menuAdd}->show;
	$gui{menuAdd}->signal_connect(activate=>sub{
									  $_[1]{self}->addTemplateDialog({id=>$_[1]{id}});
								  },
								  {
								   id=>$gui{id},
								   self=>$self,
								   }
								   );
	$gui{menu}->append($gui{menuAdd});	
	#remove
	$gui{menuRemove}=Gtk2::MenuItem->new('_remove');
	$gui{menuRemove}->show;
	$gui{menuRemove}->signal_connect(activate=>sub{
										 $_[1]{self}->removeTemplateDialog($_[1]{id});
									 },
									 {
									  id=>$gui{id},
									  self=>$self,
									  }
									 );
	$gui{menu}->append($gui{menuRemove});
	#quit
	if (!$args{disableQuit}) {
		$gui{menuQuit}=Gtk2::MenuItem->new('_quit');
		$gui{menuQuit}->show;
		$gui{menuQuit}->signal_connect(activate=>sub{
										   Gtk2->main_quit;
									   },
									   {
										id=>$gui{id},
										self=>$self,
										}
									   );
		$gui{menu}->append($gui{menuQuit});
	}
	#attaches it
	$gui{menubarmenu}->set_submenu($gui{menu});

	#puts together the view section
	$gui{textVBox}=Gtk2::VBox->new;
	$gui{textVBox}->show;
	$gui{hpaned}->add2($gui{textVBox});
	#adds the hbox that will hold the save/reload button
	$gui{buttonHBox}=Gtk2::HBox->new;
	$gui{buttonHBox}->show;
	$gui{textVBox}->pack_start($gui{buttonHBox}, 0, 1, 0);
	#reload button
	$gui{reloadTemplate}=Gtk2::Button->new();
	$gui{reloadTemplateLabel}=Gtk2::Label->new('Reload Selected Template');
	$gui{reloadTemplateLabel}->show;
	$gui{reloadTemplate}->add($gui{reloadTemplateLabel});
	$gui{reloadTemplate}->show;
	$gui{buttonHBox}->pack_start($gui{reloadTemplate}, 0, 1, 0);
	$gui{reloadTemplate}->signal_connect(clicked=>sub{
										 $_[1]{self}->updateTemplateText($_[1]{id});
									 },
									 {
									  id=>$gui{id},
									  self=>$self,
									  }
									 );
	#save button
	$gui{saveTemplate}=Gtk2::Button->new();
	$gui{saveTemplateLabel}=Gtk2::Label->new('Save Selected Template');
	$gui{saveTemplateLabel}->show;
	$gui{saveTemplate}->add($gui{saveTemplateLabel});
	$gui{saveTemplate}->show;
	$gui{buttonHBox}->pack_start($gui{saveTemplate}, 0, 1, 0);
	$gui{saveTemplate}->signal_connect(clicked=>sub{
										   my $self=$_[1]{self};
										   my $guiID=$_[1]{id};

										   #get the current template name
										   my @selected=$self->{gui}{ $guiID }{templatelist}->get_selected_indices;
										   if(!defined($selected[0])){
											   return undef;
										   }
										   my $templateName=$self->{templates}[$selected[0]];
										   if (!defined($templateName)) {
											   return undef;
										   }
										   my $template=$self->{gui}{ $guiID }{buffer}->get_text(
																								 $self->{gui}{ $guiID }{buffer}->get_start_iter,
																								 $self->{gui}{ $guiID }{buffer}->get_end_iter,
																								 1
																								 );
										   $self->{obj}->setTemplate($templateName, $template);
									 },
									 {
									  id=>$gui{id},
									  self=>$self,
									  }
									 );
	#adds the VPaned that will hold the template and the template info
	$gui{textVPaned}=Gtk2::VPaned->new;
	$gui{textVPaned}->show;
	$gui{textVPaned}->set_position(200);
	$gui{textVBox}->pack_start($gui{textVPaned}, 1, 1, 1);
	#adds the template info text view
	$gui{templateInfo}=Gtk2::TextView->new;
	$gui{templateInfo}->show;
	$gui{templateInfo}->set_editable(0);
	$gui{templateInfoSW}=Gtk2::ScrolledWindow->new;
	$gui{templateInfoSW}->show;
	$gui{templateInfoSW}->add($gui{templateInfo});
	$gui{textVPaned}->add1($gui{templateInfoSW});
	$gui{templateInfoBuffer}=Gtk2::TextBuffer->new;
	$gui{templateInfoBuffer}->set_text(
									   'TEMPLATE VARIABLES
The templating system used is \'Text::NeatTemplate\'. The varialbes are as below.

CHANNEL
{$ctitle} - This is the title for the channel.
{$cdesc} - This is the description for the channel.
{$cpubdate} - This is the publication date for the channel.
{$ccopyright} - This is the copyright info for the channel.
{$clink} - This is the link for the channel.
{$clang} - This is the language for the channel.
{$cimage} - This is the image for the channel.

ITEM
{$ititle} - This is the title for a item.
{$idesc} - This is the description for a item.
{$idescFTWL} - This is the description for a item that has been has been formated with \'HTML::FormatText::WithLinks\'
{$ipubdate} - This is the date published for a item.
{$icat} - This is the category for a item.
{$iauthor} - This is the author for a item.
{$iguid} - This is the item\'s guid element.
{$ilink} - This is the link for a item.'
									   );
	$gui{templateInfo}->set_buffer($gui{templateInfoBuffer});
	#puts together the template text view
	$gui{text}=Gtk2::TextView->new;
	$gui{text}->show;
	$gui{text}->set_editable(1);
	$gui{textSW}=Gtk2::ScrolledWindow->new;
	$gui{textSW}->show;
	$gui{textSW}->add($gui{text});
	$gui{textVPaned}->add2($gui{textSW});
	$gui{buffer}=Gtk2::TextBuffer->new;
	$gui{buffer}->set_text('');
	$gui{text}->set_buffer($gui{buffer});

	$self->{gui}{ $gui{id} }=\%gui;

	#this updates it
	$self->updateTemplateList($gui{id});

	return $gui{id};
}

=head2 manageWindow

This generates the manage window.

=head3 args hash

=head4 disableQuit

Do not show the quit selection in the menu.

=head4 quitOnClose

If the window is closed, quit the main GTK loop.

=head4 removeOnClose

Removes the GUI upon close.


    Gtk2->init;
    my $guiID=$zcrssgtk->manageWindow;
    if($zcrssgtk->{error}){
        print "Error!\n";
    }else{
        $zcrssgtk->{gui}{$guiID}{window}->show;
        $Gtk2->main;
    }

=cut

sub manageWindow{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $function='manageWindow';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

    my $guiID=$self->manageVBox({disableQuit=>$args{disableQuit}});

	$self->{gui}{ $guiID }{window}=Gtk2::Window->new;
	$self->{gui}{ $guiID }{window}->set_default_size(750, 500);
	$self->{gui}{ $guiID }{window}->set_title('ZConf::RSS: manage');
	$self->{gui}{ $guiID }{window}->add($self->{gui}{$guiID}{vbox});

	#handles the closure stuff
	if ($args{quitOnClose}) {
		$self->{gui}{ $guiID }{window}->signal_connect(delete_event=>sub{
											 Gtk2->main_quit;
										 }
										 );
	}
	if ($args{quitOnClose}) {
		$self->{gui}{ $guiID }{window}->signal_connect(delete_event=>sub{
											 delete($self->{gui}{ $guiID });
										 });
	}

	return $guiID;
}

=head2 modifyFeedDialog

This is the modifies the currently selected feed.

Only one arguement is required and it is GUI ID.

    $zcrssgtk->modifyFeedDialog($guiID);
    if($zcrssgtk->{error}){
        print "Error!\n";
    }

=cut

sub modifyFeedDialog{
	my $self=$_[0];
	my $guiID=$_[1];
	my $function='addFeedDialog';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	if (!defined($guiID)) {
		$self->{error}=4;
		$self->{errorString}='No GUI ID specified';
		warn($self->{module}.' '.$function.':"'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#get the feed
	my @selected=$self->{gui}{ $guiID }{feedlist}->get_selected_indices;
	if(!defined($selected[0])){
		return undef;
	}
	my $feed=$self->{feeds}[$selected[0]];

	#gets the feed args
	my %feedArgs=$self->{obj}->getFeedArgs($feed);

	my $window = Gtk2::Dialog->new('ZConf::RSS - Modify the feed "'.$feed.'"?',
								   undef,
								   [qw/modal destroy-with-parent/],
								   'gtk-cancel'     => 'cancel',
								   'gtk-ok'     => 'accept',
								   );
	
	$window->set_position('center-always');
	
	$window->set_response_sensitive ('accept', 0);
	$window->set_response_sensitive ('reject', 0);
	
	my $vbox = $window->vbox;
	$vbox->set_border_width(5);
	
	#url stuff
	my $ubox=Gtk2::HBox->new;
	$ubox->show;
	my $ulabel=Gtk2::Label->new('URL: ');
	$ulabel->show;
	$ubox->pack_start($ulabel, 0, 1, 0);
	my $uentry = Gtk2::Entry->new();
	$uentry->set_editable(1);
	$uentry->set_text($feedArgs{feed});
	$uentry->show;
	$ubox->pack_start($uentry, 1, 1, 0);
	$vbox->pack_start($ubox, 0, 0, 1);
	
	#name stuff
	my $nhbox=Gtk2::HBox->new;
	$nhbox->show;
	my $nlabel=Gtk2::Label->new('name: ');
	$nlabel->show;
	$nhbox->pack_start($nlabel, 0, 1, 0);
	my $nentry = Gtk2::Entry->new();
	$nentry->set_text($feedArgs{name});
	$nhbox->pack_start($nentry, 1, 1, 0);
	$nentry->show;	
	$vbox->pack_start($nhbox, 0, 0, 1);

	#top template stuff
	my $tthbox=Gtk2::HBox->new;
	$tthbox->show;
	my $ttlabel=Gtk2::Label->new('top template: ');
	$ttlabel->show;
	$tthbox->pack_start($ttlabel, 0, 1, 0);
	my $ttentry = Gtk2::Entry->new();
	$ttentry->set_text($feedArgs{topTemplate});
	$tthbox->pack_start($ttentry, 1, 1, 0);
	$ttentry->show;	
	$vbox->pack_start($tthbox, 0, 0, 1);

	#item template stuff
	my $ithbox=Gtk2::HBox->new;
	$ithbox->show;
	my $itlabel=Gtk2::Label->new('item template: ');
	$itlabel->show;
	$ithbox->pack_start($itlabel, 0, 1, 0);
	my $itentry = Gtk2::Entry->new();
	$itentry->set_text($feedArgs{itemTemplate});
	$ithbox->pack_start($itentry, 1, 1, 0);
	$itentry->show;	
	$vbox->pack_start($ithbox, 0, 0, 1);

	#bottom template stuff
	my $bthbox=Gtk2::HBox->new;
	$bthbox->show;
	my $btlabel=Gtk2::Label->new('bottom template: ');
	$btlabel->show;
	$bthbox->pack_start($btlabel, 0, 1, 0);
	my $btentry = Gtk2::Entry->new();
	$btentry->set_text($feedArgs{bottomTemplate});
	$bthbox->pack_start($btentry, 1, 1, 0);
	$btentry->show;	
	$vbox->pack_start($bthbox, 0, 0, 1);

	$uentry->signal_connect (changed => sub {
								my $text = $uentry->get_text;
								$window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								$window->set_response_sensitive ('reject', 1);
							}
							);

	$nentry->signal_connect (changed => sub {
								my $text = $nentry->get_text;
								$window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								$window->set_response_sensitive ('reject', 1);
							}
							);

	$ttentry->signal_connect (changed => sub {
								  my $text = $ttentry->get_text;
								  $window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								  $window->set_response_sensitive ('reject', 1);
							  }
							);

	$itentry->signal_connect (changed => sub {
								  my $text = $itentry->get_text;
								  $window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								  $window->set_response_sensitive ('reject', 1);
							  }
							);

	$btentry->signal_connect (changed => sub {
								  my $text = $btentry->get_text;
								  $window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								  $window->set_response_sensitive ('reject', 1);
							  }
							);
	
	my $name;
	my $top;
	my $item;
	my $bottom;
	my $pressed;
	my $url;
	
	
	$window->signal_connect(response => sub {
								$url=$uentry->get_text;
								$name=$nentry->get_text;
								$top=$ttentry->get_text;
								$item=$itentry->get_text;
								$bottom=$btentry->get_text;
								$pressed=$_[1];
							}
							);
	#runs the dailog and gets the response
	#'cancel' means the user decided not to create a new set
	#'accept' means the user wants to create a new set with the entered name
	my $response=$window->run;

	$window->destroy;

	if ($pressed ne 'accept') {
		return undef;
	}

	#remove the old one if we are renaming it
	if ($name ne $feedArgs{name}) {
		$self->{obj}->delFeed($feed);
		if ($self->{obj}->{error}) {
			$self->{error}=3;
			$self->{errorString}='setFeed errored. error="'.$self->{obj}->{error}.'" errorstring="'.$self->{errorString}.'"';
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return undef;
		}
	}


	#add the bookmark
	$self->{obj}->setFeed({
						   feed=>$url,
						   name=>$name,
						   topTemplate=>$top,
						   bottomTemplate=>$bottom,
						   itemTemplate=>$item,
						   });
	if ($self->{obj}->{error}) {
		$self->{error}=3;
		$self->{errorString}='setFeed errored. error="'.$self->{obj}->{error}.'" errorstring="'.$self->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#update the stuff
	$self->updateFeedList( $guiID );
	
	return 1;
}

=head2 removeFeedDialog

A dialog for adding a new feed.

One arguement is taken and it is the GUI ID.

    $zcrssgtk->removeFeedDialog($guiID);
    if($zcrssgtk->{error}){
        print "Error!\n";
    }

=cut

sub removeFeedDialog{
	my $self=$_[0];
	my $guiID=$_[1];
	my $function='removeFeedDialog';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	if (!defined($guiID)) {
		$self->{error}=4;
		$self->{errorString}='No GUI ID specified';
		warn($self->{module}.' '.$function.':"'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	my @selected=$self->{gui}{ $guiID }{feedlist}->get_selected_indices;

	if(!defined($selected[0])){
		return undef;
	}

	my $feed=$self->{feeds}[$selected[0]];
	
	my $window = Gtk2::Dialog->new('ZConf::RSS - Remove the feed "'.$feed.'"?',
								   undef,
								   [qw/modal destroy-with-parent/],
								   'gtk-cancel'     => 'cancel',
								   'gtk-ok'     => 'ok',
								   );
	
	$window->set_position('center-always');
	
	$window->set_response_sensitive ('accept', 0);
	$window->set_response_sensitive ('reject', 0);
	
	my $vbox = $window->vbox;
	$vbox->set_border_width(5);
	
	my $label = Gtk2::Label->new_with_mnemonic('Remove the feed "'.$feed.'"?');
	$vbox->pack_start($label, 0, 0, 1);
	$label->show;

	my $pressed;
	
 	$window->signal_connect(response => sub {
								$pressed=$_[1];
							}
							);
	#runs the dailog and gets the response
	#'cancel' means the user decided not to create a new set
	#'accept' means the user wants to create a new set with the entered name
	my $response=$window->run;

	$window->destroy;

	if ($pressed ne 'ok') {
		return undef;
	}

	#remove the feed
	$self->{obj}->delFeed($feed);
	if ($self->{obj}->{error}) {
		$self->{error}=3;
		$self->{errorString}='delFeed errored. error="'.$self->{obj}->{error}.'" errorstring="'.$self->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	if (!defined($guiID)) {
		return 1;
	}

	#update the stuff
	$self->updateFeedList( $guiID );
	
	return 1;
}

=head2 removeTemplateDialog

A dialog for adding a new feed.

One arguement is taken and it is the GUI ID.

    $zcrssgtk->removeTemplateDialog($guiID);
    if($zcrssgtk->{error}){
        print "Error!\n";
    }

=cut

sub removeTemplateDialog{
	my $self=$_[0];
	my $guiID=$_[1];
	my $function='removeTemplateDialog';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	if (!defined($guiID)) {
		$self->{error}=4;
		$self->{errorString}='No GUI ID specified';
		warn($self->{module}.' '.$function.':"'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	my @selected=$self->{gui}{ $guiID }{templatelist}->get_selected_indices;

	if(!defined($selected[0])){
		return undef;
	}

	my $template=$self->{templates}[$selected[0]];
	
	my $window = Gtk2::Dialog->new('ZConf::RSS - Remove the template "'.$template.'"?',
								   undef,
								   [qw/modal destroy-with-parent/],
								   'gtk-cancel'     => 'cancel',
								   'gtk-ok'     => 'ok',
								   );
	
	$window->set_position('center-always');
	
	$window->set_response_sensitive ('accept', 0);
	$window->set_response_sensitive ('reject', 0);
	
	my $vbox = $window->vbox;
	$vbox->set_border_width(5);
	
	my $label = Gtk2::Label->new_with_mnemonic('Remove the template "'.$template.'"?');
	$vbox->pack_start($label, 0, 0, 1);
	$label->show;

	my $pressed;
	
 	$window->signal_connect(response => sub {
								$pressed=$_[1];
							}
							);
	#runs the dailog and gets the response
	#'cancel' means the user decided not to create a new set
	#'accept' means the user wants to create a new set with the entered name
	my $response=$window->run;

	$window->destroy;

	if ($pressed ne 'ok') {
		return undef;
	}

	#remove the feed
	$self->{obj}->delTemplate($template);
	if ($self->{obj}->{error}) {
		$self->{error}=3;
		$self->{errorString}='delTemplate errored. error="'.$self->{obj}->{error}.'" errorstring="'.$self->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#update the stuff
	$self->updateTemplateList( $guiID );
	
	return 1;
}

=head2 view

Invokes the view window.

    $zcrssgtk->view;
    if($zcrssgtk->{error}){
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

	Gtk2->init;

	my $guiID=$self->viewWindow({quitOnClose=>1, removeOnClose=>1});
	$self->{gui}{$guiID}{window}->show;

	Gtk2->main;

	return 1;
}

=head2 viewVBox

This creates a VBox for the view GUI and returns the GUI ID of it.

=head3 args hash

=head4 disableQuit

If this is set to true, the quit selection under the misc functions menu will not be present.

    my $guiID=$zcrssgtk->viewVBox;
    if($zcrssgtk->{error}){
        print "Error!\n";
    }else{
	    $window=Gtk2::Window->new;
	    $window->set_default_size(750, 400);
	    $window->set_title('ZConf::RSS: view');
        $window->add($zcrssgtk->{gui}{$guiID}{vbox});
    }

=cut

sub viewVBox{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $function='viewVBox';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	my %gui;

	$gui{id}=rand().rand().rand();

	#the main box
	$gui{vbox}=Gtk2::VBox->new;
	$gui{vbox}->show;
	$gui{hpaned}=Gtk2::HPaned->new;
	$gui{hpaned}->set_position(0);
	$gui{hpaned}->show;
	$gui{hpaned}->set_position(200);
	$gui{vbox}->pack_start($gui{hpaned}, 1, 1, 0);

	#puts together the basics for the list box
	$gui{listbox}=Gtk2::VBox->new;
	$gui{listbox}->show;
	$gui{hpaned}->add1($gui{listbox});
	#this is the menu bar that goes in the list box
	$gui{menubar}=Gtk2::MenuBar->new;
	$gui{menubarmenu}=Gtk2::MenuItem->new('_misc functions');
	$gui{menubar}->show;
	$gui{menubarmenu}->show;
	$gui{menubar}->append($gui{menubarmenu});
 	$gui{listbox}->pack_start($gui{menubar}, 0, 1, 0);
	#the window that holdes
	$gui{listSW}=Gtk2::ScrolledWindow->new;
	$gui{listSW}->show;
	$gui{listbox}->pack_start($gui{listSW}, 1, 1, 0);
	#puts the feed list stuff together
	$gui{feedlist}=Gtk2::SimpleList->new(
									   'RSS feeds'=>'text',
									   );
	$gui{feedlist}->get_selection->set_mode ('single');
	$gui{feedlist}->show;
	$gui{feedlist}->signal_connect(row_activated=>sub{
									   $_[3]{self}->updateFeed($_[3]{id});
								   },
								   {
									self=>$self,
									id=>$gui{id},
									}
								   );
	$gui{listSW}->add($gui{feedlist});
	
	#puts together the menu
	$gui{menu}=Gtk2::Menu->new;
	$gui{menu}->show;
	#add
	$gui{menuAdd}=Gtk2::MenuItem->new('_add');
	$gui{menuAdd}->show;
	$gui{menuAdd}->signal_connect(activate=>sub{
									  $_[1]{self}->addFeedDialog({id=>$_[1]{id}});
								  },
								  {
								   id=>$gui{id},
								   self=>$self,
								   }
								   );
	$gui{menu}->append($gui{menuAdd});	
	#modify
	$gui{menuModify}=Gtk2::MenuItem->new('_modify');
	$gui{menuModify}->show;
	$gui{menuModify}->signal_connect(activate=>sub{
										 $_[1]{self}->modifyFeedDialog($_[1]{id});
									 },
									 {
									  id=>$gui{id},
									  self=>$self,
									  }
									 );
	$gui{menu}->append($gui{menuModify});
	#remove
	$gui{menuRemove}=Gtk2::MenuItem->new('_remove');
	$gui{menuRemove}->show;
	$gui{menuRemove}->signal_connect(activate=>sub{
										 $_[1]{self}->removeFeedDialog($_[1]{id});
									 },
									 {
									  id=>$gui{id},
									  self=>$self,
									  }
									 );
	$gui{menu}->append($gui{menuRemove});
	#manage templates
	$gui{menuManage}=Gtk2::MenuItem->new('manage _templates');
	$gui{menuManage}->show;
	$gui{menuManage}->signal_connect(activate=>sub{
										 my $guiID=$_[1]{self}->manageWindow({disableQuit=>1});
										 $_[1]{self}->{gui}{ $guiID }{window}->show;
									 },
									 {
									  id=>$gui{id},
									  self=>$self,
									  }
									 );
	$gui{menu}->append($gui{menuManage});
	#quit
	if (!$args{disableQuit}) {
		$gui{menuQuit}=Gtk2::MenuItem->new('_quit');
		$gui{menuQuit}->show;
		$gui{menuQuit}->signal_connect(activate=>sub{
										   Gtk2->main_quit;
									   },
									   {
										id=>$gui{id},
										self=>$self,
										}
									   );
		$gui{menu}->append($gui{menuQuit});
	}
	#attaches it
	$gui{menubarmenu}->set_submenu($gui{menu});

	#puts together the view section
	$gui{text}=Gtk2::TextView->new;
	$gui{text}->show;
	$gui{text}->set_editable(0);
	$gui{textSW}=Gtk2::ScrolledWindow->new;
	$gui{textSW}->show;
	$gui{textSW}->add($gui{text});
	$gui{hpaned}->add2($gui{textSW});
	$gui{buffer}=Gtk2::TextBuffer->new;
	$gui{buffer}->set_text('');
	$gui{text}->set_buffer($gui{buffer});

	$self->{gui}{ $gui{id} }=\%gui;

	#this updates it
	$self->updateFeedList($gui{id});

	return $gui{id};
}

=head2 viewWindow

This generates the view window.

=head3 args hash

=head4 disableQuit

Do not show the quit selection the menu.

=head4 quitOnClose

If the window is closed, quit the main GTK loop.

=head4 removeOnClose

Removes the GUI upon close.

    Gtk2->init;
    my $guiID=$zcrssgtk->viewWindow;
    if($zcrssgtk->{error}){
        print "Error!\n";
    }else{
        $zcrssgtk->{gui}{$guiID}{window}->show;
        $Gtk2->main;
    }

=cut

sub viewWindow{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $function='viewWindow';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

    my $guiID=$self->viewVBox({disableQuit=>$args{disableQuit}});

	$self->{gui}{ $guiID }{window}=Gtk2::Window->new;
	$self->{gui}{ $guiID }{window}->set_default_size(750, 400);
	$self->{gui}{ $guiID }{window}->set_title('ZConf::RSS');
	$self->{gui}{ $guiID }{window}->add($self->{gui}{$guiID}{vbox});

	#handles the closure stuff
	if ($args{quitOnClose}) {
		$self->{gui}{ $guiID }{window}->signal_connect(delete_event=>sub{
											 Gtk2->main_quit;
										 }
										 );
	}
	if ($args{quitOnClose}) {
		$self->{gui}{ $guiID }{window}->signal_connect(delete_event=>sub{
											 delete($self->{gui}{ $guiID });
										 }
										 );
	}

	return $guiID;
}

=head2 updateFeed

This updates the updates the feed view.

    $zcrssgtk->updateFeed($guiID);

=cut

sub updateFeed{
	my $self=$_[0];
	my $guiID=$_[1];
	my $function='updateFeed';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	my @selected=$self->{gui}{ $guiID }{feedlist}->get_selected_indices;

	if(!defined($selected[0])){
		return undef;
	}

	my $feed=$self->{feeds}[$selected[0]];

	my $feedString=$self->{obj}->getFeedAsTemplatedString($feed);

	if (!defined($feedString)) {
		return undef;
	}

	$self->{gui}{ $guiID }{buffer}->set_text($feedString);
	
	$self->{gui}{ $guiID }{text}->set_buffer($self->{gui}{ $guiID }{buffer});

	return 1;
}

=head2 updateFeedList

This updates the feed list.

    $zcrssgtk->updateFeed($guiID);

=cut

sub updateFeedList{
	my $self=$_[0];
	my $guiID=$_[1];
	my $function='updateFeedList';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	#get the feeds and sort them
	my @feeds=$self->{obj}->listFeeds();
	@feeds=sort(@feeds);

	#make save it for later easy recall
	$self->{feeds}=\@feeds;

	#puts it together
	my @int=0;

	@{$self->{gui}{ $guiID }{feedlist}->{data}}=@feeds;

	return 1;
}

=head2 updateTemplateList

This updates the template list for a manage window.

One arguement is required and it is a GUI ID for the manage window in question.

    $zcrssgtk->updateTemplateList($guiID);
    if($zcrssgtk->{error}){
        print "Error!\n";
    }

=cut

sub updateTemplateList{
	my $self=$_[0];
	my $guiID=$_[1];
	my $function='updateFeedList';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	#get the feeds and sort them
	my @templates=$self->{obj}->listTemplates();
	@templates=sort(@templates);

	#make save it for later easy recall
	$self->{templates}=\@templates;

	#puts it together
	my @int=0;

	@{$self->{gui}{ $guiID }{templatelist}->{data}}=@templates;

	return 1;
}

=head2 updateTemplateText

This updates template text for the specified GUI ID.

    $zcrssgtl->updateTemplateText($guiID);
    if($zcrssgtk->{error}){
        print "Error!\n";
    }

=cut

sub updateTemplateText{
	my $self=$_[0];
	my $guiID=$_[1];

	my @selected=$self->{gui}{ $guiID }{templatelist}->get_selected_indices;

	if(!defined($selected[0])){
		return undef;
	}

	my $template=$self->{templates}[$selected[0]];

	my $templateText=$self->{obj}->getTemplate($template);

	if (!defined($templateText)) {
		return undef;
	}

	$self->{gui}{ $guiID }{buffer}->set_text($templateText);
	
	$self->{gui}{ $guiID }{text}->set_buffer($self->{gui}{ $guiID }{buffer});

}

=head2 dialogs

This returns a array of available dialogs.

    my @dialogs=$zcrssgtk->dialogs;
    if($zcrssgtk->{error}){
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

	return ('addFeed');
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

	return ('view', 'manage');
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

Adding the new feed failed.

=head2 4

No GUI ID specified.

=head2 5

Backend errored.

=head2 6

Removing the old feed for the purpose of renaming it failed.

=head1 WINDOWS

Please not that unless working directly and specifically with a backend, windows and dialogs
are effectively the same in that they don't return until the window exits, generally.

=head2 add

This adds a new a new feed.

=head2 manage

This allows the RSS feeds to be managed along with the templates.

=head2 view

This allows the RSS feeds to be viewed.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-devtemplate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-RSS-GUI-GTK>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::RSS::GUI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf::RSS::GUI::GTK>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf::RSS::GUI::GTK>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf::RSS::GUI::GTK>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf::RSS::GUI::GTK/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::RSS::GUI
