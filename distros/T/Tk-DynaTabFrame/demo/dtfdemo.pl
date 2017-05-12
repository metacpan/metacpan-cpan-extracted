#!/usr/bin/perl -w

use Tk;
use Tk::DynaTabFrame;
use Tk::TextUndo;
use Tk::DialogBox;
use Tk::LabEntry;
use Tk::Photo;
use Tk::BrowseEntry;

use strict;
use warnings;

my %frames = ();
my %texts = ();
my $tabno = 0;
my $align = 1;
my $rotate = 1;

my $mw = MainWindow->new();
#
#	create some images
#
my @images = ();
push @images, $mw->Photo(-data => $_->(), -format => 'gif')
	foreach (\&aggudf_gif,
\&hashidx_gif,
\&jtbl16_gif,
\&scalarudf_gif,
\&xsp_gif,
\&qmark_gif,
\&projmgmt16_gif);

my $imgidx = 0;
my %args = @ARGV;
my $side = $args{-s} ||= 'nw';
my $color = $args{-c};
my $raisecolor = $args{-r};
my $lockbtn;

my $dtf = $mw->DynaTabFrame(
	-font => 'Arial 8', 
	-raisecmd => \&raise_cb,
	-tabclose => sub {
		my ($obj, $tab) = @_;
		print "Closing $tab\n";
		$obj->delete($tab);
		},
	-tabcolor => $color,
	-raisecolor => $raisecolor,
	-tabside => $side,
	-tabpadx => 3,
	-tabpady => 3,
	-tiptime => 600,
	-tipcolor => 'white'
	)
	->pack (-side => 'top', -expand => 1, -fill => 'both');

my $buttons1 = $mw->Frame()
	->pack(-side => 'bottom', -fill => 'x', -expand => 0, -pady => 5);
my $buttons2 = $mw->Frame()
	->pack(-side => 'bottom', -fill => 'x', -expand => 0, -pady => 5);

$buttons1->Button
   (
    -text => 'Ok',
    -command => sub { $mw->destroy(); }
   )->pack
   (
    -side => 'right',
    -anchor => 'ne',
    -fill => 'none',
    -padx => 10,
   );

$buttons1->Button
   (
    -text => 'Add Text Tab',
    -command => sub
       {
       		$tabno++;
       		my $caption = ($tabno == 1) ? 
       			"Caption 1 for a really\nlong caption" :
       			"Caption $tabno";

			$frames{$caption} = $dtf->add(
				-caption => $caption,
#				-label => "Tab No. $tabno",
				-tabtip => "Tip for $tabno"
				);

			$texts{$caption} = $frames{$caption}->Scrolled(
				'TextUndo', -scrollbars => 'osoe',
				-width => 50, -height => 30, -wrap => 'none',
				-font => 'Courier 10')
				->pack(-fill => 'both', -expand => 1);
			$texts{$caption}->insert('end', 
				"This is the $tabno tabframe");
       }
   )->pack
   (
    -side => 'right',
    -anchor => 'ne',
    -fill => 'none',
    -padx => 10,
   );

$buttons1->Button
   (
    -text => 'Add Image Tab',
    -command => sub
       {
       		$tabno++;
       		my $caption = ($tabno == 1) ? 'Caption 1 for a really long caption' :
       			"Caption $tabno";

			$frames{$caption} = $dtf->add(
				-image => $images[$imgidx++],
				-caption => $caption, 
				-tabtip => "Tip for $tabno"
			);
			$imgidx = 0 if ($imgidx == scalar @images);

			$texts{$caption} = $frames{$caption}->Scrolled(
				'TextUndo', -scrollbars => 'osoe',
				-width => 50, -height => 30, -wrap => 'none',
				-font => 'Courier 10')
				->pack(-fill => 'both', -expand => 1);
			$texts{$caption}->insert('end', 
				"This is the $tabno tabframe");
       }
   )->pack
   (
    -side => 'right',
    -anchor => 'ne',
    -fill => 'none',
    -padx => 10,
   );
#
#	remove only the raised tab
#
$buttons1->Button
   (
    -text => 'Remove Tab',
    -command => sub
       {
       	my $caption = $dtf->raised_name();
       	return 1 unless $caption;
       	
        delete $frames{$caption};
        delete $texts{$caption};
        $dtf->delete($caption);
       }
   )->pack
   (
    -side => 'right',
    -anchor => 'ne',
    -fill => 'none',
    -padx => 10,
   );

$buttons1->Button
   (
    -text => 'Toggle Text Align',
    -command => sub { 
    	$dtf->configure(-textalign => ! $dtf->cget(-textalign));
    	}
   )->pack
   (
    -side => 'right',
    -anchor => 'ne',
    -fill => 'none',
    -padx => 10,
   );

$buttons1->Button
   (
    -text => 'Toggle Rotate',
    -command => sub { 
    	$dtf->configure(-tabrotate => ! $dtf->cget(-tabrotate));
    	}
   )->pack
   (
    -side => 'right',
    -anchor => 'ne',
    -fill => 'none',
    -padx => 10,
   );

$buttons1->Button
   (
    -text => 'Flash',
    -command => sub {
    	$dtf->flash($dtf->raised_name, 
    		-color => 'purple',
    		-interval => 400,
    		-duration => 6000
    		);}
   )->pack
   (
    -side => 'right',
    -anchor => 'nw',
    -fill => 'none',
    -padx => 10,
   );

$lockbtn = $buttons1->Button
   (
    -text => 'Lock',
    -command => \&tablock,
   )->pack
   (
    -side => 'right',
    -anchor => 'nw',
    -fill => 'none',
    -padx => 10,
   );

$buttons2->Button
   (
    -text => 'Raise...',
    -command => \&raise_tab
   )->pack
   (
    -side => 'right',
    -anchor => 'ne',
    -fill => 'none',
    -padx => 10,
   );

$buttons2->Button
   (
    -text => 'Get Tabs',
    -command => sub {my $tabs = $dtf->cget(-tabs); print join(', ', keys %$tabs), "\n";}
   )->pack
   (
    -side => 'right',
    -anchor => 'nw',
    -fill => 'none',
    -padx => 10,
   );

$buttons2->Button
   (
    -text => 'Flip Tab',
    -command => \&fliptext
   )->pack
   (
    -side => 'right',
    -anchor => 'ne',
    -fill => 'none',
    -padx => 10,
   );

my $browser = $buttons2->BrowseEntry(
	-label => 'Tab Side',
	-browsecmd => \&orient_tabs,
	-listwidth => 20,
	-width => 3,
   )->pack
   (
    -side => 'right',
    -anchor => 'ne',
    -fill => 'none',
    -padx => 10,
   );
$browser->insert('end', 'nw');
$browser->insert('end', 'ne');
$browser->insert('end', 'sw');
$browser->insert('end', 'se');
$browser->insert('end', 'en');
$browser->insert('end', 'es');
$browser->insert('end', 'wn');
$browser->insert('end', 'ws');
$browser->insert('end', 'n');
$browser->insert('end', 's');
$browser->insert('end', 'e');
$browser->insert('end', 'w');

$buttons2->Button
   (
    -text => 'Hide',
    -command => \&hide_tab
   )->pack
   (
    -side => 'right',
    -anchor => 'ne',
    -fill => 'none',
    -padx => 10,
   );

my $hider;
my $hidden = $buttons2->BrowseEntry(
	-label => 'Hidden:',
	-browse2cmd => \&reveal_tab,
#	-listwidth => 30,
	-variable => \$hider
   )->pack
   (
    -side => 'right',
    -anchor => 'ne',
    -fill => 'none',
    -padx => 10,
   );

$mw->update;

#$dtf->configure(-tipcolor => 'white');

Tk::MainLoop();
#
#	change the tab orientation:
#		- collect all existing tabs
#		- destroy the DTF
#		- create a new DTF with the new orientation
#	NOTE: DTF should handle this itself
#
sub orient_tabs {
	my ($obj, $side) = @_;
	$dtf->configure(-tabside => $side);
}

sub tablock {
   	if ($lockbtn->cget(-text) eq 'Lock') {
   		$lockbtn->configure(-text => 'Unlock');
   		$dtf->configure(-tablock => 1);
   	}
   	else {
   		$lockbtn->configure(-text => 'Lock');
   		$dtf->configure(-tablock => undef);
   	}
}

sub hide_tab {
	my $caption = $dtf->raised_name();
	return 1 unless $caption;
	$dtf->pageconfigure($caption, -hidden => 1);
	$hidden->insert('end', $caption);
	return 1;
}

sub reveal_tab {
	my ($obj, $index) = @_;
	my $caption = $hidden->get($index);
	$dtf->pageconfigure($caption, -hidden => undef);
#
#	scan for and remove the hidden entry
#
	$hidden->delete($index);
#	$hidden->SubWidget('entry')->delete(0, 'end');
	$hider = '';
	return 1;
}

sub raise_cb { print shift, "\n"; }

sub raise_tab {
#
#	create dialog to enter a tab text
#
	my $dlg = $mw->DialogBox(
		-title => 'Enter Tab to Raise', 
		-buttons => [ 'OK', 'Cancel' ],
		-default_button => 'OK');
	my $caption;
	$dlg->add('LabEntry' , 
		-textvariable => \$caption, 
		-width => 40,
		-background => 'white',
		-label => 'Tab Name',
		-labelPack => [ -side => 'left'])
		->pack;
	my $answer = $dlg->Show();
	return 1 if ($answer eq 'Cancel');
	
	$dtf->raise($caption);
	1;
}

sub fliptext {
	my $caption = $dtf->raised_name();
	return 1 unless $caption;
	my $text = $dtf->pagecget($caption, -label);
	return 1 unless $text;
	$text = join('', reverse(split(//, $text)));
	$dtf->pageconfigure($caption, -label => $text);
	return 1;
}


sub aggudf_gif {
	# FILENAME: C:/Perl/TeraForge/TeraForge-0.20/src/icons/aggudf.gif
	# THIS FUNCTION RETURNS A BASE64 ENCODED
	# REPRESENTATION OF THE ABOVE FILE.
	# SUITABLE FOR USE BY THE -data PROPERTY.
	# OF A Perl/Tk PHOTO.
	my $binary_data = <<EOD;
R0lGODlhEAAQAPcAAAAAAAEBAQICAgMDAwQEBAUFBQYGBgcHBwgICAkJCQoKCgsLCwwMDA0NDQ4O
Dg8PDxAQEBERERISEhMTExQUFBUVFRYWFhcXFxgYGBkZGRoaGhsbGxwcHB0dHR4eHh8fHyAgICEh
ISIiIiMjIyQkJCUlJSYmJicnJygoKCkpKSoqKisrKywsLC0tLS4uLi8vLzAwMDExMTIyMjMzMzQ0
NDU1NTY2Njc3Nzg4ODk5OTo6Ojs7Ozw8PD09PT4+Pj8/P0BAQEFBQUJCQkNDQ0REREVFRUZGRkdH
R0hISElJSUpKSktLS0xMTE1NTU5OTk9PT1BQUFFRUVJSUlNTU1RUVFZWVldYV1lZWVtbW1xdXF5f
Xl9gX2BhYGFiYWJjYmNkY2NlY2RlZGRmZGRmZGRmZGRlZWJjZl5fZ1laaVNVa0xNbkVGcTw9dDIy
eCUmfRobghAQhwoKigYGjAICjQAAjgAAjwAAjgAAigAAggAAfAAAdwAAcQAAbgAAbAAAawAAagAA
agEBagICawMDawYGbQoKbxMTch4edS0seDk4ekVEfE9OflpZgF5dgWRig2dmhWlohmtqhm1shnBv
hnFwhXNyhHRzhHV0hHd2g3l4gnp6gnx8gX19gH9/gH9/gH9/gH9/gH9/gH9/gICAgICAgIGBgIGC
gIKDgIOEgISFgIaHgIeJgIqMgYyOgo6Rg5OWhpibiZyfi6Onj6uvlLW4mr2/n8HDo8PGpsTGqcXH
rMfHs8nHvMjHwcjIxMvJxtDOyNLQydPQzNTSzNbTztjV0NrY0t3b1eHg2ufm4O/v6fX18vz8/P39
/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39
/f39/f39/f39/f39/f39/f39/f39/P38+f368/325/3tzv3hrf3Sgv3La/3HYv3GX/3GXv3GXv3G
Xv3GXv3GXv3GXvzFXvzFXvzFXvzFXvzFXvzFXvzFXvzFXvzFXvzFXiH5BAkAAKQALAAAAAAQABAA
AAh4AKmRGUiwYCRqCBHCmsewIUNS1A4mjOTQIamLEBG+qlgxWEaBDevU+VOnoa+PZBiSVFly3q2P
G+eNZDhznseEC2X+4djrI0WdLBneVBh03kqXPkOSbDmv50SODl8+hSrU5y1fwW4F83WrV9aTCTGK
HfsxodmzCQMCADs=
EOD
	return($binary_data);
	} # END aggudf_gif...


sub hashidx_gif {
	# FILENAME: C:/Perl/TeraForge/TeraForge-0.20/src/icons/hashidx.gif
	# THIS FUNCTION RETURNS A BASE64 ENCODED
	# REPRESENTATION OF THE ABOVE FILE.
	# SUITABLE FOR USE BY THE -data PROPERTY.
	# OF A Perl/Tk PHOTO.
	my $binary_data = <<EOD;
R0lGODlhIAAgAKIAAP8A/wAAAP///8DAwAD//4CAgAD/AP//ACH5BAUAAAAALAAAAAAgACAAAgO2
CLrcDiHK8KqFIotBr1eRQIxF900TBA1FW36glnEdGsGYoRsvbgWCHc9kM3mAwlJNxlkUiSzXiwIc
EXoYZu0JCkRbRMFhfJheqDanmKzsFk/rMRaodaZj5HI4GdY08WwoQTtKEiIkYXlzgzpzX4uKUFJz
dxiRW29HcXoqPxCVXpOYdyF+RJlZpipViDhIhDcrUkZnjEN2KK62WD4OobOjEq5vVHW9DyFWvMcM
v2DMyJXQ09TVOAkAOw==
EOD
	return($binary_data);
	} # END hashidx_gif...


sub jtbl16_gif {
	# FILENAME: C:/Perl/TeraForge/TeraForge-0.20/src/icons/jtbl16.gif
	# THIS FUNCTION RETURNS A BASE64 ENCODED
	# REPRESENTATION OF THE ABOVE FILE.
	# SUITABLE FOR USE BY THE -data PROPERTY.
	# OF A Perl/Tk PHOTO.
	my $binary_data = <<EOD;
R0lGODlhEAAQAPcZAP4AAP4AAP4AAP4AAP4AAP0AAPkAAPAAAOIAANIAAL8AAK0AAKIAAJcAAI8A
AIkAAIQAAHsAAGoAAFoAAEQAACQAABAAAAYAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAQMDAwYG
BgsLCxERERkZGSMjIy8vLzY2Njs7Ozw8PD09PT4+Pj8/P0BAQEFBQUJCQkNDQ0REREVFRUZGRkdH
R0hISElJSUpKSktLS0xMTE1NTU5OTk9PT1BQUFFRUVJSUlNTU1RUVFVVVVZWVldXV1hYWFlZWVpa
WltbW1xcXF1dXV5eXl9fX2BgYGFhYWJiYmNjY2RkZGVlZWZmZmdnZ2hoaGlpaWpqamtra2xsbG1t
bW5ubm9vb3BwcHFxcXJycnNzc3R0dHV1dXZ2dnd3d3h4eHl5eXp6ent7e3x8fH19fX5+fn9/f4CA
gIGBgYKCgoODg4SEhIWFhYaGhoeHh4iIiImJiYqKiouLi4yMjI2NjY6Ojo+Pj5CQkJGRkZKSkpOT
k5SUlJWVlZaWlpeXl5iYmJmZmZqampubm5ycnJ2dnZ6enp+fn6CgoKGhoaKioqOjo6SkpKWlpaam
pqenp6ioqKmpqaqqqqurq6ysrK2tra6urq+vr7CwsLGxsbKysrOzs7S0tLW1tba2tre3t7i4uLm5
ubq6uru7u7y8vL29vb6+vr+/v8DAwMHBwcLCwsPDw8TExMXFxcbGxsfHx8jIyMnJycrKysvLy8zM
zM3Nzc7Ozs/Pz9DQ0NHR0dLS0tPT09TU1NXV1dbW1tfX19jY2NnZ2dra2tvb29zc3N3d3d7e3t/f
3+Dg4OHh4eLi4uPj4+Tk5OXl5efn5+np6e3t7fDw8PT09Pf39/r6+vz8/P39/f7+/v7+/v7+/v7+
/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v///yH5BAkAAIAALAAAAAAQABAA
AAhXADMIHEiwoMB/CDMg/KeQgMMHDBUmXNjwYUSDAx0SeICxoEaOBydO/BiRokmSHTM+HIgQ5T+U
El3CbGmx4saLGTTq/MiS5s6NEEMy/MkxoUSGJkWm7BgQADs=
EOD
	return($binary_data);
	} # END jtbl16_gif...

sub scalarudf_gif {
	# FILENAME: C:/Perl/TeraForge/TeraForge-0.20/src/icons/scalarudf.gif
	# THIS FUNCTION RETURNS A BASE64 ENCODED
	# REPRESENTATION OF THE ABOVE FILE.
	# SUITABLE FOR USE BY THE -data PROPERTY.
	# OF A Perl/Tk PHOTO.
	my $binary_data = <<EOD;
R0lGODlhEAAQAPcAAAAAAAEBAQICAgMDAwQEBAUFBQYGBgcHBwgICAkJCQoKCgsLCwwMDA0NDQ4O
Dg8PDxAQEBERERISEhMTExQUFBUVFRYWFhcXFxgYGBkZGRoaGhsbGxwcHB0dHR4eHh8fHyAgICEh
ISIiIiMjIyQkJCUlJSYmJicnJygoKCkpKSoqKisrKywsLC0tLS4uLi8vLzAwMDExMTIyMjMzMzQ0
NDU1NTY2Njc3Nzg4ODk5OTo6Ojs7Ozw8PD09PT4+Pj8/P0BAQEFBQUJCQkNDQ0REREVFRUZGRkdH
R0hISElJSUpKSktLS0xMTE1NTU5OTk9PT1BQUFFRUVJSUlNTU1RUVFVVVVZWVldXV1hYWFlZWVpa
WltbW1xcXF1dXV5eXl9fX2BgYGFhYWJiYmNjY2VnZWJia1dXb0VFdzY2fSkpgh8fhRgYiBERiwoK
jQYGjgMDkAICkQEBkgEBkwAAlAAAlAAAlAAAkgAAjwAAiwAAhgAAfwAAdwAAcQAAbQAAawAAaQAA
aAAAaAAAaAAAaAAAaQEBagQEawcHbBUVcCoqd0NDflxchWtpinJyiHl5hH5+gX9/gH9/gH9/gH9/
gH9/gIB/gIB/gIB/gIGAf4KBfoeDeoqFdo2IdI6Lc5CPd5CSepKXgJWahZadipugj6KmlrCspryz
sse9wsvBydPO0uTk4e3t7PX19Pv7+v7+/f7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+
/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+
/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v39/fz8/Pv7
+/r6+vn5+fX29vDx8ens7Njg4MHS0q/GxqO/v5u6upi3tJa2sJW1rJW1qZa1p5i1pZm2o5u2op23
oKK5n6e7nq2+oLHAorXBpLjDpbzEpr/GpsHHpsPIpMXIo8bJo8bJoiH5BAkAAJcALAAAAAAQABAA
AAh3AIOBCkawIMFLjApeCibKoMGFCYNBdKjwkkWJAikaTLVwIZmCdeoAqlMQVcdgH4ONJLgy2L+T
A4OJJDgzGEeMDWUConjuZMSaLW8uzNmy5UuMEXWGLNgTqcaCRyc+tenzH6pU/1Kh+ncOq0mMFsOK
FYtxqsNLAQEAOw==
EOD
	return($binary_data);
	} # END scalarudf_gif...


sub xsp_gif {
	# FILENAME: C:/Perl/TeraForge/TeraForge-0.20/src/icons/xsp.gif
	# THIS FUNCTION RETURNS A BASE64 ENCODED
	# REPRESENTATION OF THE ABOVE FILE.
	# SUITABLE FOR USE BY THE -data PROPERTY.
	# OF A Perl/Tk PHOTO.
	my $binary_data = <<EOD;
R0lGODlhEAAQALMAAOA4OPDo6NhwcPgAANigoPj4+ABlAGEAcgBGAHIAbwBnAFwAZQBUAHIAZQBh
AG8ARiH5BAkAAAAALAAAAAAQABAAAAQ/sMhJawFEjmHrCAXXUYMgjpQ5bWcFCBIBE4A1ECI+BnUB
hyfWBnTJaGAb1KSW7AhgAU6zAxgCpyisUpttKSkRADs=
EOD
	return($binary_data);
	} # END xsp_gif...


sub qmark_gif {
	# FILENAME: C:/Perl/TeraForge/TeraForge-0.20/src/icons/qmark.gif
	# THIS FUNCTION RETURNS A BASE64 ENCODED
	# REPRESENTATION OF THE ABOVE FILE.
	# SUITABLE FOR USE BY THE -data PROPERTY.
	# OF A Perl/Tk PHOTO.
	my $binary_data = <<EOD;
R0lGODlhGAAYAPe4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAEBAQMDAwQEBAcHBwoKCgwMDA8PDxISEhQUFBYWFhkZGRwcHB0dHR4eHh8fHyAgICEh
ISIiIiMjIyQkJCUlJSYmJicnJygoKCkpKSoqKisrKywsLC0tLS4uLi8vLzAwMDExMTIyMjMzMzQ0
NDU1NTY2Njc3Nzg4ODk5OTo6Ojs7Ozw8PD09PT4+Pj8/P0BAQEFBQUJCQkNDQ0REREVFRUZGRkdH
R0hISElJSUpKSktLS0xMTE1NTU5OTk9PT1BQUFFRUVJSUlNTU1RUVFVVVVZWVldXV1hYWFlZWVpa
WltbW1xcXF1dXV5eXl9fX2BgYGhoWm5uU3BwS3FxQ3BwPG1tNGpqLmVlJ2FhIVtbHFZWF2RkEXJy
DKGhBszMAufnAfT0APv7AP39AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+
AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+
AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+
AP7+AP7+AP7+AP7+AP7+AP7+AP7+AP7+Af39Av39A/z8Bfv7Cfn5Dfb2FPLyHu3pLOjhO+LXTdnS
ZM7Kg8LCpby8vL29vb6+vr+/v8HBwcLCwsPDw8TExMXFxcXFxcbGxsbGxsbGxsPDw729vbi2s7St
pq+jl6yaia2Xgq6VfLCUd7OTc7WScK+QcaOMdZWIe4yGf4eFgoWEg4SEg4SEg4SEg4SEg4SEg4SE
g4SEg4SEg4SEg4SEg4SEg4SEg4SDg4ODg4ODg4ODg4ODg4ODg4ODg4KCgoGBgYCAgICAgICAgICA
gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCH5BAkAAPcALAAAAAAYABgA
AAirAO8JHCgQgcGDBBMqvPft27GHD/0w/LYw4cGLfo758YOg4kAE3zaK9NNQZMeKCEaq5JiR4sKU
K1XCPGkxpsqSND+uDLkSZE6BPE2CDLoRwbGfDEd2XHoTaUmTLmEKfXmRplSOSD1+u8rR40KiHBuK
FVsRrMGxaL8qDYuWbMKnRbtSTKsW6kS3HquCvOvSq0Fc3wBvbeh14NaNuFjuLQyUaMqsWpX2ZVyw
auGAADs=
EOD
	return($binary_data);
	} # END qmark_gif...

sub projmgmt16_gif {
	# FILENAME: C:/Perl/TeraForge/TeraForge-0.20/src/icons/projmgmt16.gif
	# THIS FUNCTION RETURNS A BASE64 ENCODED
	# REPRESENTATION OF THE ABOVE FILE.
	# SUITABLE FOR USE BY THE -data PROPERTY.
	# OF A Perl/Tk PHOTO.
	my $binary_data = <<EOD;
R0lGODlhEgASAPcAAOecUgAAAMbGxv8A/wD//4QAhACEhISEhP///wD/AACEAISEAAAA/wAAhP//
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACwAAAAAEgASAAAIrwAFCBSw
IECAAgYBDFwocIEBAwcHDCgAIABDgQcaEIB4EOGBAAdCHhh44OFGgxYRWFyAAMHCAwpQDlSZsWVI
gQgWAABwwKaCBiMF5By4QIDBAkENIjhQMGhRlwIbBFgqgGnBhj0RIBX6sSdTgwNBMs3YwGjDAFeJ
tmwpVGhOBWmFTnVAly6AugviGkVQty/dvBbD8vWLV+9cwn/jqhSA+C/ahQUYIy5YdCHKy5cZBgQA
Ow==
EOD
	return($binary_data);
	} # END projmgmt16_gif...
