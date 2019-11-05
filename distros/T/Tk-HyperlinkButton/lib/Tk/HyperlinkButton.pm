package Tk::HyperlinkButton;

use 5.016003;
use strict;
use warnings;
use Browser::Open qw/ open_browser /;

use Tk;
use Tk::widgets qw/ Button /;
use base qw/ Tk::Derived Tk::Button /;

Construct Tk::Widget 'HyperlinkButton';

our $VERSION = '0.02';

=head1 NAME

Tk::HyperlinkButton - Create a clickable hyperlink button to open a web browser

=head1 SYNOPSIS

  use Tk::HyperlinkButton;
  
  my $mw = MainWindow->new();
  
  my $link_text = 'metacpan.org';
  my $link_target = 'http://www.metacpan.org';
  my $link_callback = sub{ print "your callback here\n"; };
  
  my $hyperlink_widget = $mw->HyperlinkButton(
      -text => $link_text,
      -target => $link_target,
      -command => $link_callback,
  );
  
  $hyperlink_widget->pack;
  
  $mw->MainLoop;

=head1 DESCRIPTION

Tk::Hyperlink is an adjusted L<Tk::Button> widget to display a hyperlink.
The hyperlink will be displayed with blue foreground color by default and highlighted on mouse over.
The look and feel resembles a Label (no borders by default).

A custom callback can be provided the same way as for other buttons (using the option C<-command>).
The callback will be executed when the hyperlink is clicked.
The default callback will open the system's default web browser and navigate to the URL provided by the option C<target>.
If C<target> is not defined, the URL will be what you define by the option C<-text>.

The widget is indented to only represent the hyperlink.
The intended use case is actually to have some kind of L<Tk::Label>-like widget that is a clickable hyperlink.

Text in front or after the hyperlink should be created with other means (e.g. L<Tk::Label> or L<Tk::Text>).

=head1 WIDGET-SPECIFIC OPTIONS

=head2 target

Sets the address for the hyperlink. If target is not given, C<-text> will be used as target automatically.

Using C<-text> and C<-target> in combination, you can get a clickable hyperlink that open a web browser with the address defined in C<-target>, but that displays a different text as defined in C<-text>. 
Basically, that's what you have in HTML as well.

=head2 command

A callback that will be executed when the hyperlink is clicked. Optional.
By default, clicking the hyperlink will open the system's default browser and navigate to the URL (cf. C<-target>).

=head1 WIDGET METHODS

The HyperlinkButton method creates a widget object.
This object supports the C<configure> and C<cget> methods described in L<Tk::options> which can be used to enquire and modify the options described above.
The widget also inherits all the methods provided by the generic L<Tk::Widget> class.

=cut

##=head2 Populate( %args )
##
##Handles the custom widget attributes and defaults (e.g. blue font color).
##
##Creates the bindings to change the mouse cursor and relief (raised/flat).
##Bindings are created as instance bindings, because we do not want to overwrite the L<Tk::Button> class bindings.
##
##=cut

sub Populate {
	my( $self, $args ) = @_;
	
    my $link_text = $args->{'-text'};
    
	my $target = delete $args->{'-target'};
    unless( defined $target ) {
        $target = $link_text;
    }
    
    my $link_callback = $args->{'-command'};
    
    # only use default behavior if no custom command is provided
    unless( defined $link_callback ) {
        $link_callback = sub{ $self->open_link_in_browser(); };
        $args->{'-command'} = $link_callback;
    }
    
    $self->SUPER::Populate( $args );
    
    my %defaults = (
        -relief => 'flat',
        -foreground => 'blue',
        -overrelief => 'raised',
        -activeforeground => 'blue',
        -borderwidth => 1,
    );
    
    foreach my $attr_name ( keys %defaults ) {
        if( !exists $args->{$attr_name} or !defined $args->{$attr_name} ) {
            $args->{$attr_name} = $defaults{$attr_name};
        }
    }
    
	$self->ConfigSpecs(
		'DEFAULT' 		    => [$self],
        '-target'   	=> [ 'PASSIVE', 'target', 'Target', $target ],
	);
	
	$self->Delegates(
		'DEFAULT'	=> $self,
	);
    
    $self->bind('<Any-Enter>' => sub{
        highlight_link_cursor($_[0], 'raised', 'hand2');
        return;
    });
    
    $self->bind('<Any-Leave>' => sub{
        highlight_link_cursor($_[0], 'flat', 'xterm');
        return;
    });
    
	return;
} # /Populate




##=head2 highlight_link_cursor($cursor)
##
##Changes the cursor when the mouse hovers over the hyperlink.
##On hover, y default, the cursor C<hand2> will be used. It will be reset to the cursor C<xterm>.
##
##=cut

sub highlight_link_cursor {
    my ($w, $relief, $cursor) = @_;
    $w->configure(-relief => $relief) if $relief;
    $w->configure(-cursor => $cursor) if $cursor;
} # /highlight_link_cursor




=head2 open_link_in_browser()

Open a browser and navigate to the hyperlink target (cf. C<-target>).
Uses L<Browser::Open> for starting the browser.

=cut

sub open_link_in_browser {
    my $self = shift;
    my $target = $self->cget('-target');
    
    ## debug:
    #print "target: $target\n";
    #print "command used to start the browser: " . Browser::Open::open_browser_cmd() . "\n";
    
    my $ok = open_browser($target);
    # ! defined($ok): no recognized command found
    # $ok == 0: command found and executed
    # $ok != 0: command found, error while executing
    return;
} # /open_link_in_browser



=head1 BINDINGS

When a new hyperlink is created, it has default instance event bindings to the following events:

=over

=item * C<Any-Enter>: Will highlight the hyperlink similar to what you see in a web browser. Also changes the cursor.

=item * C<Any-Leave>: Will reset the highlightning or appearance changes done by the other events.

=back

This widget is intended to be interactive.

=head1 TODO

  * Describe how to embed hyperlinks in Tk::Text / Tk::ROText.
  * configuration options for font and colors

=head1 SEE ALSO

L<Tk::Button>, L<Browser::Open>

Code is inspired by L<https://www.perlmonks.org/?node_id=667664>, downloaded 2019-11-01.

=head1 AUTHOR

Alexander Becker, E<lt>asb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Alexander Becker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 KEYWORDS

button, widget, hyperlink, link, web link

=cut

1; # /Tk::HyperlinkButton