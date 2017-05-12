package Tk::Help;

use vars qw($VERSION);
$VERSION = '0.3';

use Tk qw(Ev);
use Tk::widgets qw(HList ROText Tree);
use base qw(Tk::Toplevel);

use strict;
use warnings;

Construct Tk::Widget 'Help';

my %components;
my %options;

sub ClassInit {
	my($self, $args) = @_;
	$self->SUPER::ClassInit($args);
}

sub Populate {
	my($self, $args) = @_;

	$options{'globalfontfamily'}        = delete $args->{-globalfontfamily}        || undef;
	$options{'detailsbackground'}		= delete $args->{-detailsbackground}	   || 'white';
	$options{'detailsborderwidth'}		= delete $args->{-detailsborderwidth}	   || 10;
	$options{'detailsfontfamily'}       = delete $args->{-detailsfontfamily}       || $options{'globalfontfamily'};
	$options{'detailsfontsize'}			= delete $args->{-detailsfontsize}		   || 8;
	$options{'detailsforeground'}		= delete $args->{-detailsforeground}	   || (($^O eq 'MSWin32') ? 'SystemWindowText' : 'black');
	$options{'detailsheaderfontfamily'} = delete $args->{-detailsheaderfontfamily} || $options{'globalfontfamily'};
	$options{'detailsheaderfontsize'}	= delete $args->{-detailsheaderfontsize}   || 9;
	$options{'detailsheaderforeground'} = delete $args->{-detailsheaderforeground} || (($^O eq 'MSWin32') ? 'SystemWindowText' : 'black');
	$options{'detailsmenu'}				= delete $args->{-detailsmenu}			   || 0;
	$options{'detailswidth'}			= delete $args->{-detailswidth}			   || 40;
	$options{'height'}					= delete $args->{-height}				   || (($^O eq 'MSWin32') ? 30 : 40);
	$options{'icon'}					= delete $args->{-icon}					   || undef;
	$options{'listbackground'}			= delete $args->{-listbackground}		   || Tk::NORMAL_BG;
	$options{'listborderwidth'}			= delete $args->{-listborderwidth}		   || 0;
	$options{'listcursor'}				= delete $args->{-listcursor}			   || 'hand2';
	$options{'listfontfamily'}          = delete $args->{-listfontfamily}          || $options{'globalfontfamily'};
	$options{'listfontsize'}			= delete $args->{-listfontsize}			   || 8;
	$options{'listforeground'}			= delete $args->{-listforeground}		   || (($^O eq 'MSWin32') ? 'SystemWindowText' : 'black');
	$options{'listselectbackground'}	= delete $args->{-listselectbackground}	   || $options{'listbackground'};
	$options{'listselectforeground'}	= delete $args->{-listselectforeground}	   || 'blue';
	$options{'listtype'}				= delete $args->{-listtype}				   || 'HList';
	$options{'listwidth'}				= delete $args->{-listwidth}			   || 25;
	$options{'resizable'}				= delete $args->{-resizable}			   || 0;
	$options{'variable'}				= delete $args->{-variable}				   || undef;

	$self->SUPER::Populate($args);
	$self->ConfigSpecs();

	# sets the icon if specified
	if($options{'icon'}) {
		$self->iconimage(${$options{'icon'}});
	}
	# turns off resizeing
	unless($options{'resizable'}) {
		$self->resizable(0, 0);
	}
	# sets the cursor to the os default instead of hand2
	if($options{'listcursor'} eq 'default') {
		$options{'listcursor'} = undef;
	}

	# begin building the frames for the entire help system
	# one main frame to contain the other two frames, list and details
	$components{'main'} = $self->Component('Frame', 'main');
	$components{'main'}->grid();
	$components{'listframe'} = $components{'main'}->Frame(-background  => $options{'listbackground'},
														  -borderwidth => $options{'listborderwidth'})->grid(($components{'detailsframe'} = $components{'main'}->Frame(-background  => $options{'detailsbackground'},
														  																											   -borderwidth => $options{'detailsborderwidth'})), -sticky => 'nsew');

	# create the list
	$components{'list'} = $components{'listframe'}->Scrolled($options{'listtype'},
															 -background		 => $options{'listbackground'},
															 -borderwidth		 => 0,
															 -browsecmd			 => sub{&populatedetails},
															 -cursor			 => $options{'listcursor'},
															 -font				 => [-family => $options{'listfontfamily'}, -size => $options{'listfontsize'}],
															 -foreground		 => $options{'listforeground'},
															 -height			 => $options{'height'},
															 -highlightthickness => 0,
															 -relief			 => 'flat',
															 -scrollbars		 => 'osoe',
															 -selectbackground	 => $options{'listselectbackground'},
															 -selectborderwidth	 => 0,
															 -selectforeground	 => $options{'listselectforeground'},
															 -width				 => $options{'listwidth'})->grid();

	# assign a references to our hash to a scalar to simplify the iteration syntax
	my $helptext = \@{$options{'variable'}};
	# iterate through the array
	for(my $i = 0; $i < @$helptext; $i++) {
		# iterate through the arrayrefs
		for(my $n = 0; $n < @{$$helptext[$i]}; $n++) {
			# if this isn't the first arrayref in the array...
			if($i) {
				# if this isn't the first arrayref...
				if($n) {
					# insert the title in the list
					$components{'list'}->add('0.'.$i.'0.'.$n,
											 -text => $$helptext[$i]->[$n]->{'-title'});
				# if this is the first arrayref...
				} else {
					# insert the title in the list
					$components{'list'}->add('0.'.$i.$n,
											 -text => $$helptext[$i]->[$n]->{'-title'});
				}
			# if this is the first arrayref in the array...
			} else {
				# insert the title in the list
				$components{'list'}->add($i,
										 -text => $$helptext[$i]->[$n]->{'-title'});
			}
		}
	}

	# this is needed for the indicators to be created when using Tk::Tree
	if($options{'listtype'} eq 'Tree') {
		$components{'list'}->autosetmode();
	}

	# create the details
	$components{'detailstext'} = $components{'detailsframe'}->Scrolled('ROText',
																	   -background => $options{'detailsbackground'},
																	   -font	   => [-family => $options{'detailsfontfamily'}, -size => $options{'detailsfontsize'}],
																	   -foreground => $options{'detailsforeground'},
																	   -height	   => $options{'height'},
																	   -relief	   => 'flat',
																	   -scrollbars => 'oe',
																	   -width	   => $options{'detailswidth'},
																	   -wrap	   => 'word')->grid();

	# turn off the right-click menu in the ROText object
	unless($options{'detailsmenu'}) {
		$components{'detailstext'}->menu(undef);
	}
	# create the tag for the details headers
	$components{'detailstext'}->tagConfigure('header',
											 -font		 => [-family => $options{'detailsheaderfontfamily'}, -size => $options{'detailsheaderfontsize'}, -weight => 'bold'],
											 -foreground => $options{'detailsheaderforeground'});
	# insert the header into the details frame
	$components{'detailstext'}->insert('end', $$helptext[0]->[0]->{'-header'}."\n\n", 'header');
	# insert the text into the details frame
	$components{'detailstext'}->insert('end', $$helptext[0]->[0]->{'-text'});

	# bring the help window into focus
	$self->focusForce();
}

sub populatedetails {
	my $number	  = shift();
	my $intnumber = 0;
	my $helptext  = \@{$options{'variable'}};

	if($number =~ m/^0\.(\d)\d\.(\d+)/) {
		$number = $1;
		$intnumber = $2;
	} elsif($number =~ m/^0\.(\d)\d/) {
		$number = $1;
	}
	# remove all the existing text from the details frame
	$components{'detailstext'}->delete('1.0', 'end');
	# insert the header and text for the listitem that was clicked
	$components{'detailstext'}->insert('end', $$helptext[$number]->[$intnumber]->{'-header'}."\n\n", 'header');
	$components{'detailstext'}->insert('end', $$helptext[$number]->[$intnumber]->{'-text'});
}

1;

__END__

=head1 NAME

Tk::Help - Simple widget for creating a help system for Perl/Tk applications

=head1 SYNOPSIS

    use Tk::Help;
    my $help = $main->Help(-variable => \@array);

=head1 DESCRIPTION

This is an answer to a personal need to be able to create help
systems for my Perl/Tk applications.  Originally, I just created a
really big dialog and formatted all the text, which was tedious and
clumsy.  I wanted to create something that looked 'similar' to the
Windows help.  This is by no means as featured or fluid as the
Windows help, but it should provide a (somewhat) simple means to
create a help dialog where all someone should need to do is create
the array with their help content.

=head1 OPTIONS

=over 4

=item B<-globalfontfamily>

Set the font family for all text in the Help widget.

=item B<-detailsbackground>

Sets the background color of the details section (right side) of the
help window.  Default is C<white>.

=item B<-detailsborderwidth>

Sets the borderwidth around the inside of the details section (right
side) of the help window.  Default is C<10>.

=item B<-detailsfontsize>

Sets the font size of the details text.  This is separate from the
header text that appears in each detail window.  Default is C<8>.

=item B<-detailsforeground>

Sets the color of the details text.  This is separate from the header
color that appears in each detail window.  Default is the OS's
default text color for Windows and C<black> otherwise.

=item B<-detailsheaderfontsize>

Sets the font size of the headers in the details window above the
text.  This is separate from the details text.  Default is C<9>.

=item B<-detailsheaderforeground>

Sets the color of the headers in the details window above the text.
This is separate from the details text.  Default is the OS's default
text color for Windows and C<black> otherwise.

=item B<-detailsmenu>

Determines if the right-click menu is active for the details section.
Takes a boolean value.  Default is C<0>.

=item B<-detailswidth>

Sets the width of the details section.  Default is C<40>.

=item B<-height>

Sets the height for the help window.  Default is C<30> for Windows
and C<40> otherwise.

=item B<-icon>

Sets the icon on the title bar of the application.  This must be
passed as a reference.  Default is the red 'Tk' icon for
Windows and the system default otherwise.

=item B<-listbackground>

Sets the background color of the list section (left side) of the
help window.  Default is the OS's default application color,
C<(Tk::NORMAL_BG)>.

=item B<-listborderwidth>

Sets the borderwidth around the inside of the list section (left
side) of the help window.  Default is C<0>.

=item B<-listcursor>

Sets the mouse cursor that is used over items in the list section
(left side).  Default is Perl/Tk's C<hand2> cursor.  To use the OS's
default cursor, set C<-listcursor =E<gt> 'default'>.

=item B<-listfontsize>

Sets the font size of the list text.  Default is C<8>.

=item B<-listforeground>

Sets the color of the list text.  Default is the OS's default text
color for Windows and C<black> otherwise.

=item B<-listselectbackground>

Sets the background color of the selected list item.  Default is
whatever C<-listbackground> is set to.

=item B<-listselectforeground>

Sets the color of the selected list item's text.  Default is C<blue>.

=item B<-listtype>

Sets the type of listbox Help is to use, either HList or Tree.
Default is C<HList>.

=item B<-listwidth>

Sets the width of the list section of the help window.  Default
is C<25>.

=item B<-resizable>

Determines if the help window is resizable or not.  Takes a boolean
value.  The default is set to C<0>.

=item B<-title>

Sets the title on the top of the window.  Default is C<'Help'>.

=item B<-variable>

The structure should be an array of arrayrefs of hashrefs.  The very
first arrayref should contain only one hashref and this will be the
root of your entire help tree.  This must be passed as a reference.
This is required and there is no default.

=back

=head1 EXAMPLES

    use Tk;
    use Tk::Help;

    my $main = MainWindow->new(-title => "My Application");
    $main->configure(-menu => my $menubar = $main->Menu);
    my $filemenu = $menubar->cascade(-label   => "~File",
                                     -tearoff => 0);
    my $helpmenu = $menubar->cascade(-label   => "~Help",
                                     -tearoff => 0);
    $filemenu->command(-label   => "E~xit",
                       -command => sub{$main->destroy});
    $helpmenu->command(-label   => "~Help Contents",
                       -command => sub{showhelp()});

    MainLoop;
    1;

    sub showhelp {
        my @helparray = ([{-title  => "My Application",
                           -header => "My Application Help",
                           -text   => "This is a description of my application for the help."}],
                         [{-title  => "Section 1",
                           -header => "\n\nSection 1 Help",
                           -text   => ""},
                          {-title  => "1st Feature",
                           -header => "The 1st Feature",
                           -text   => "This is the text describing the 1st feature of section 1."},
                          {-title  => "2nd Feature",
                           -header => "The 2nd Feature",
                           -text   => "This is the text describing the 2nd feature of section 1."}],
                         [{-title  => "Section 2",
                           -header => "\n\nSection 2 Help",
                           -text   => ""},
                          {-title  => "1st Feature",
                           -header => "The 1st Feature",
                           -text   => "This is the text describing the 1st feature of section 2."},
                          {-title  => "2nd Feature",
                           -header => "The 2nd Feature",
                           -text   => "This is the text describing the 2nd feature of section 2."}]);

        my $helpicon = $main->Photo(-file => "/path/to/some/gif/or/bmp");
        my $help = $main->Help(-icon     => \$helpicon,
                               -title    => "My Application - Help",
                               -variable => \@helparray);
    }

=head1 TODO

- Bind mouse events to the list items to create a mouseover and mouseout effect.
- Figure out how to remove the dashed line around a selected item in the list.
- Add individual font family switches for each text group.

=head1 SEE ALSO

L<Tk::Toplevel|Tk::Toplevel>, L<Tk::HList|Tk::HList>,
L<Tk::Tree|Tk::Tree>

=head1 KEYWORDS

help

=head1 AUTHOR

Doug Gruber <dougthug@cpan.org>
http://www.dougthug.com/

=head1 COPYRIGHT

Copyright (c) 2005 Doug Gruber.  All rights reserved.  This module is
free software; you can redistribute it and/or modify it under the
same terms as Perl itself.
