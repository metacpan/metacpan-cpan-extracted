package ZConf::Cron::GUI::GTK;

use warnings;
use strict;
use ZConf::Cron;
use ZConf::GUI;
use String::ShellQuote;

=head1 NAME

ZConf::Cron::GUI::GTK - Implements a GTK backend for ZConf::Cron::GUI

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

    use ZConf::Cron::GUI::GTK;


    my $zcc=$ZConf::Cron->new;
    my $zccg=ZConf::Cron::GUI::GTK->new({zccron=>$zcc});


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

	my $self={error=>undef, errorString=>undef, gui=>{}};
	bless $self;

	#initiates
	if (!defined($args{zccron})) {
		$self->{zcc}=ZConf::Cron->new();
	}else {
		$self->{zcc}=$args{zccron};
	}

	#handles it if initializing ZConf::Runner failed
	if ($self->{zcc}->{error}) {
		my $errorstring=$self->{zcc}->{errorString};
		$errorstring=~s/\"/\\\"/g;
		my $error='Initializing ZConf::Cron failed. error="'.$self->{zcc}->{error}
		          .'" errorString="'.$self->{zcc}->{errorString}.'"';
	    $self->{error}=3;
		$self->{errorString}=$error;
		warn('ZConf-Cron-GUI-GTK new:1: '.$error);
		return $self;		
	}

	$self->{zconf}=$self->{zcc}->{zconf};

	return $self;
}

=head2 crontab

Allows the crontabs to be managed.

This method is blocking.

   $zccg->crontab;
   if($zccg->{error}){
       print "Error!\n";
   }

=cut

sub crontab{
	my $self=$_[0];

	$self->errorblank;
	if ($self->{error}) {
		warn('ZConf-Cron-GUI crontab: A permanent error was set');
		return undef;
	}

	system('gtk-gzccrontab');
	my $exitcode=$? >> 8;
	if ($? == -1) {
		$self->{error}=2;
		$self->{errorString}='"gtk-gzccrontab" did not run or is not in the current path';
		warn('ZConf-Cron-GUI-GTK crontab:2: '.$self->{errorString});
		return undef;
	}

	if ($exitcode ne '0') {
		$self->{error}=3;
		$self->{errorString}='"gtk-gzccrontab" exited with "'.$exitcode.'"';
		warn('ZConf-Cron-GUI-GTK crontab:3: '.$self->{errorString});
		return undef;		
	}


	return 1;
}

=head2 tray

Creates a tray icon and menu.

    use Gtk2;
    Gtk2->init;
    my $guiID=$zccg->tray;
    $trayicon->show_all;
    Gtk2->main;

=cut

sub tray{
	my $self=$_[0];

	#inits the gui hash
	my %gui;
	$gui{id}=rand().rand();

	#inits the menu
	$gui{trayiconimage}=$self->xpmGtk2Image;
	$gui{trayiconimagepixbuf}=$gui{trayiconimage}->get_pixbuf;
	$gui{statusicon}=Gtk2::StatusIcon->new_from_pixbuf($gui{trayiconimagepixbuf});

	$gui{menu}=Gtk2::Menu->new;
	$gui{menu}->set_border_width('0');
	$gui{menu}->show;

	#connects the menu stuff
	$gui{statusicon}->signal_connect(
									 'activate'=>\&popup,
									 {
									  gui=>$gui{id},
									  self=>$self,
									  }
									 );

	#refreshes
	$gui{refresh}=Gtk2::MenuItem->new('_refresh');
	$gui{refresh}->show;
	$gui{refresh}->signal_connect(activate=>\&refreshMenuItem,
								  {
								   gui=>$gui{id},
								   self=>$self,
								   }
								  );
	$gui{menu}->append($gui{refresh});

	#save the GUI
	$self->{gui}{$gui{id}}=\%gui;
				 
	#refreshes the GUI
	$self->refreshMenuItem({gui=>$gui{id}, self=>$self});
	
	return $gui{id};
}

=head2 xpm

This returns a XPM icon for this module.

    my $xpm=$zccg->xpm;

=cut

sub xpm{

return '/* XPM */
static char * trayicon_xpm[] = {
"32 32 77 1",
" 	c #000000",
".	c #0036FF",
"+	c #B71717",
"@	c #0E0202",
"#	c #520A0A",
"$	c #851111",
"%	c #A41515",
"&	c #B31717",
"*	c #B41717",
"=	c #801010",
"-	c #470909",
";	c #060101",
">	c #B61717",
",	c #010000",
"\'	c #530A0A",
")	c #AF1616",
"!	c #A61515",
"~	c #400808",
"{	c #280505",
"]	c #B11616",
"^	c #510A0A",
"/	c #720E0E",
"(	c #7A0F0F",
"_	c #3B0707",
":	c #140303",
"<	c #050101",
"[	c #220404",
"}	c #590B0B",
"|	c #180303",
"1	c #A81515",
"2	c #6A0D0D",
"3	c #550B0B",
"4	c #A91515",
"5	c #2C0606",
"6	c #090101",
"7	c #700E0E",
"8	c #0D0202",
"9	c #9B1313",
"0	c #811010",
"a	c #020000",
"b	c #110202",
"c	c #B01616",
"d	c #2D0606",
"e	c #5A0B0B",
"f	c #8B1111",
"g	c #941313",
"h	c #7B1010",
"i	c #760F0F",
"j	c #5F0C0C",
"k	c #150303",
"l	c #460909",
"m	c #B51717",
"n	c #310606",
"o	c #480909",
"p	c #200404",
"q	c #AD1616",
"r	c #620C0C",
"s	c #120202",
"t	c #A11414",
"u	c #790F0F",
"v	c #881111",
"w	c #931212",
"x	c #8D1212",
"y	c #AA1515",
"z	c #1B0303",
"A	c #570B0B",
"B	c #080101",
"C	c #6F0E0E",
"D	c #B31616",
"E	c #750F0F",
"F	c #390707",
"G	c #130202",
"H	c #560B0B",
"I	c #A51515",
"J	c #3E0808",
"K	c #100202",
"L	c #861111",
" ..      ..    ..   ..  ..    . ",
"  .....  ..     .....   ..    . ",
"                                ",
"                                ",
"                                ",
"                                ",
"+++++++++++++++      @#$%&*%=-; ",
"++++++++++++++>    ,\')++++++++!~",
"           {]+^   ,/+>(_:<;[}!++",
"          |1+2    3+45       67+",
"         89+0a   bc>d          e",
"        <f+g6    3+h            ",
"  ..... i.....  .....   ....... ",
" ..    j+..    ..!+k..  ..    . ",
" .    l+*..    . m+; .  ..    . ",
" .   n&+o..    . m+; .  ..    . ",
" .  pq+r ..    . !+k .  ..    . ",
" ..st+u, ..    . v+_ .  ..    . ",
" ..w+x;  ..    ..3+h..  ..    . ",
" a.....  ..     .....   ..    .}",
" 2+yz             A+45       BC+",
"#+D5              ,E+>uFG<;pH%++",
">++++++++++++++    ,3c++++++++IJ",
"+++++++++++++++      K\'LI**%=l; ",
"                                ",
"                                ",
"                                ",
"                                ",
"                                ",
"                                ",
"  .....  .....  .....   ....... ",
" ..      ..    ..   ..  ..    . "};
'

}

=head2 xpmGtk2Image

This returns a Gtk2::Image object with it. This is done as getting a Gtk2::Image object from raw data is
not a straight forward processes. It requires access to "/tmp/" to write the scratch file.

    my $image=$zccg->xpmGtk2Image;

=cut

sub xpmGtk2Image{
	my $self=$_[0];
	my $xpm=$self->xpm;

	my $file="/tmp/".rand().rand().rand().rand().".xpm";

	open(XPM, '>', $file);
	print XPM $xpm;
	close(XPM);

	my $image=Gtk2::Image->new_from_file($file);

	unlink($file);

	return $image;
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
		warn('ZConf-Cron-GUI errorblank: A permanent error is set.');
		return undef;
	}

	$self->{error}=undef;
	$self->{errorString}="";

	return 1;
}

=head1  tray Related Methods.

These methods are entirely related to the tray method.

=head2 refreshMenuItem

This method refresheses the menu.

It takes one arguement and it is a hash reference.

=head3 hash reference keys

=head4 gui

This is the GUI ID of the tray GUI.

=head4 self

This is the ZConf::Cron::GUI::GTK object.

=cut

sub refreshMenuItem{
	my %args;
	%args=%{$_[1]};

	#makes sure we have a gui ID
	if (!defined($args{gui})) {
		return undef;
	}

	#make sure we have our self
	if (!defined($args{self})) {
		return undef;
	}

	#gets the gui ID
	my $guiID=$args{gui};

	#easier to use
	my $gui=$args{gui};
	my $self=$args{self};

	#makes sure the GUI exists
	if (!defined($self->{gui}{$gui})) {
		return undef;
	}

	#rebuilds the basic menu items
	$self->{gui}{$gui}{menu}=Gtk2::Menu->new;
	$self->{gui}{$gui}{menu}->show;
	$self->{gui}{$gui}{menuTearoff}=Gtk2::TearoffMenuItem->new;
	$self->{gui}{$gui}{menuTearoff}->show;
	$self->{gui}{$gui}{menu}->append($self->{gui}{$gui}{menuTearoff});

	#adds the refresh menu item
	$self->{gui}{$gui}{refresh}=Gtk2::MenuItem->new('_refresh');
	$self->{gui}{$gui}{refresh}->show;
	$self->{gui}{$gui}{refresh}->signal_connect(activate=>\&refreshMenuItem,
												{
												 gui=>$guiID,
												 self=>$self,
												 }
												);
	$self->{gui}{$gui}{menu}->append($self->{gui}{$gui}{refresh});
	
	#adds the edit item
	$self->{gui}{$gui}{edit}=Gtk2::MenuItem->new('_edit');
	$self->{gui}{$gui}{edit}->show;
	$self->{gui}{$gui}{edit}->signal_connect(activate=>sub{
												 $_[1]{self}->crontab;
												 $_[1]{self}->refreshMenuItem( {
																	gui=>$_[1]{gui},
																	self=>$_[1]{self}
																	}
																  );
											 },
											 \%args
											 );
	$self->{gui}{$gui}{menu}->append($self->{gui}{$gui}{edit});

	#adds the seperator item
	$self->{gui}{$gui}{seperator}=Gtk2::SeparatorMenuItem->new();
	$self->{gui}{$gui}{seperator}->show;
	$self->{gui}{$gui}{menu}->append($self->{gui}{$gui}{seperator});

	#gets the tabs
	my @tabs=$self->{zcc}->getTabs;

	#creates the object to hold the cron tabs to run
	my $int=0;
	while (defined($tabs[$int])) {
		my $name='item'.$int;

		#adds the a new item
		$self->{gui}{$gui}{$name}=Gtk2::MenuItem->new('_'.$tabs[$int]);
		$self->{gui}{$gui}{$name}->show;
		$self->{gui}{$gui}{$name}->signal_connect(activate=>sub{
													  my $safetab=shell_quote($_[1]{tab});
													  #my $sef=$_[1]{self}->{zcc}->
													  system('zccron -t '.$safetab);
												 },
												 {
												  gui=>$guiID,
												  self=>$self,
												  tab=>$tabs[$int],
												  }
												 );
		$self->{gui}{$gui}{menu}->append($self->{gui}{$gui}{$name});		
		
		$int++;
	}

	#adds the seperator item
	$self->{gui}{$gui}{seperator2}=Gtk2::SeparatorMenuItem->new();
	$self->{gui}{$gui}{seperator2}->show;
	$self->{gui}{$gui}{menu}->append($self->{gui}{$gui}{seperator2});

	#the quit button
	$self->{gui}{$gui}{quit}=Gtk2::MenuItem->new('_quit');
	$self->{gui}{$gui}{quit}->show;
	$self->{gui}{$gui}{quit}->signal_connect(activate=>sub{
												 exit 0;
											 }
											 );
	$self->{gui}{$gui}{menu}->append($self->{gui}{$gui}{quit});	

	#adds the new menu

	return 1;
}

=head2 popup

This pops the menu up.

=cut

sub popup{
	my $widget=$_[0];
	my %args=%{ $_[1] };
	my $menu=$args{self}->{gui}{ $args{gui} }{menu};

	my ($x, $y, $push_in) = Gtk2::StatusIcon::position_menu($menu, $widget);
	
	$menu->show_all();
	$menu->popup( undef, undef,
				  sub{return ($x,$y,0)} ,
				  undef, 0, 0 );
}

=head1 DIALOGS

ask

=head1 WINDOWS

At this time, no windows are supported.

=head1 ERROR CODES

=head2 1

Initializing ZConf::Cron failed.

=head2 2

Could not run "gtk-gzccrontab" as it was not found in the path.

=head2 3

'gtk-gzccrontab' exited with a non-zero.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

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

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-Cron-GUI-GTK>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-Cron-GUI-GTK>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-Cron-GUI-GTK>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-Cron-GUI-GTK>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::Cron::GUI::GTK
