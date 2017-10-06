package Win32::AutoItX::Control;

=head1 NAME

Win32::AutoItX::Control - OO interface for Window Controls

=head1 SYNOPSIS

    use Win32::AutoItX;

    my $a = Win32::AutoItX->new;

    my $pid = $a->Run('calc.exe');
    my $window = $a->get_window('Calculator');
    $window->wait;
    for my $control ($window->find_controls) {
        local $\ = "\n";
        print "Control $control";
        print "\thandle: ", $control->handle;
        print "\ttext: ", $control->text;
        print "\tx: ", $control->x, "\ty: ", $control->y;
        print "\twidth: ", $control->width, "\theight: ", $control->height;
    }

    my $button_2 = $window->find_controls('2', class => 'Button');
    my $button_3 = $window->find_controls('3', class => 'Button');
    my $button_plus = $window->find_controls('+', class => 'Button');
    my $button_eq = $window->find_controls('=', class => 'Button');
    my $result = $window->find_controls('0', class => 'Static');

    $button_2->click;
    $button_3->click;
    $button_plus->click;
    $button_3->click;
    $button_2->click;
    $button_eq->click;

    print "23 + 32 = ", $result->text, "\n";

=head1 DESCRIPTION

Win32::AutoItX::Control provides an object-oriented interface for AutoItX
methods to operate with Window Controls.

=cut

use strict;
use warnings;

our $VERSION = '1.00';

use Carp;
use Scalar::Util qw{ blessed };
use Win32::AutoItX::Control::ListView;
use Win32::AutoItX::Control::TreeView;

use overload fallback => 1, '""' => sub { $_[0]->{control} };

my %Helper_Methods = qw{
    click    ControlClick
    diable   ControlDisable
    enable   ControlEnable
    focus    ControlFocus
    handle   ControlGetHandle
    x        ControlGetPosX
    y        ControlGetPosY
    width    ControlGetPosWidth
    height   ControlGetPosHeight
    text     ControlGetText
    set_text ControlSetText
    hide     ControlHide
    show     ControlShow
    move     ControlMove
    send     ControlSend
    command  ControlCommand
    clw      ControlListView
    ctw      ControlTreeView
};

my %Control_Commands = qw{
    is_visible     IsVisible
    is_enabled     IsEnabled
    show_dropdown  ShowDropDown
    hide_dropdown  HideDropDown
    add_string     AddString
    del_string     DelString
    find_string    FindString
    set_selection  SetCurrentSelection
    select_string  SelectString
    is_checked     IsChecked
    check          Check
    uncheck        UnCheck
    line_number    GetCurrentLine
    column         GetCurrentCol
    selection      GetCurrentSelection
    line_count     GetLineCount
    line           GetLine
    selected       GetSelected
    paste          EditPaste
    tab            CurrentTab
    tab_right      TabRight
    tab_left       TabLeft
};

=head1 METHODS

=head2 new

    $control = Win32::AutoItX::Control->new(
        $autoitx, $window_title, $window_text, $control_id
    )

creates the control object.

=cut

sub new {
    my $class = shift;
    my %self;
    $self{autoitx} = shift;
    $self{title}   = shift;
    $self{text}    = shift;
    $self{control} = shift;
    $self{text} = '' unless defined $self{text};
    croak "The first argument should be a Win32::AutoItX object"
        unless blessed $self{autoitx} and $self{autoitx}->isa('Win32::AutoItX');
    return bless \%self, $class;
}
#-------------------------------------------------------------------------------

=head2 listview

    $listview = $control->listview()

returns a L<Win32::AutoItX::Control::ListView> object for the control.

=cut

sub listview { Win32::AutoItX::Control::ListView->new($_[0]) }
#-------------------------------------------------------------------------------

=head2 treeview

    $treeview = $control->treeview()

returns a L<Win32::AutoItX::Control::TreeView> object for the control.

=cut

sub treeview { Win32::AutoItX::Control::TreeView->new($_[0]) }
#-------------------------------------------------------------------------------

=head2 click

    $control->click()
    $control->click($button, $clicks, $x, $y)

sends a mouse click command to a given control. C<$button> is the button to
click: "left" (by default), "right" or "middle". C<$clicks> is the number of
times to click the mouse (default is 1). C<$x> and C<$y> is the position to
click within the control (default is center).

B<Note>: Some controls will resist clicking unless they are the active window.
Use the C<$window-E<gt>active()> to force the control's window to the top before
using C<click()>).

Using 2 for the number of clicks will send a double-click message to the control
- this can even be used to launch programs from an explorer control!

=head2 disable

    $control->disable()

disables or "grays-out" the control.

=head2 enable

    $control->enable()

enables a "grayed-out" control.

=head2 focus

    $control->focus()

sets input focus to a given control on a window.

=head2 handle

    $handle = $control->handle()

retrieves the internal handle of the control.

=head2 x

    $x = $control->x()

retrieves the X coordinate of the control relative to it's window.

=head2 y

    $y = $control->y()

retrieves the Y coordinate of the control relative to it's window.

=head2 width

    $width = $control->width()

retrieves the width of the control.

=head2 height

    $height = $control->height()

retrieves the height of the control.

=head2 text

    $text = $control->text()

retrieves text from the control.

=head2 set_text

    $control->set_text($text)

sets text of the control.

=head2 hide

    $text = $control->hide()

hides the control.

=head2 show

    $control->show()

shows a control that was hidden.

=head2 move

    $control->move($x, $y)
    $control->move($x, $y, $width)
    $control->move($x, $y, $width, $height)

moves a control within a window.

=head2 send

    $control->send($string)
    $control->send($string, $flag)

sends a string of characters to the control. If C<$flag> is true send a raw
C<$string> otherwise special characters like C<+> or C<{LEFT}> mean SHIFT and
left arrow.

=head2 command

    $result = $control->command($command, $option)

sends a command to the control.

=head2 is_visible

    $boolean = $control->is_visible()

returns true if the control is visible.

=head2 is_enabled

    $boolean = $control->is_enabled()

returns true if the control is enabled.

=head2 show_dropdown

    $control->show_dropdown()

drops a ComboBox.

=head2 hide_dropdown

    $control->hide_dropdown()

undrops a ComboBox.

=head2 add_string

    $control->add_string($string)

adds a string to the end in a ListBox or ComboBox.

=head2 del_string

    $control->del_string($occurrence)

deletes a string according to occurrence in a ListBox or ComboBox.

=head2 find_string

    $control->find_string($string)

returns occurrence ref of the exact string in a ListBox or ComboBox.

=head2 set_selection

    $control->set_selection($occurrence)

sets selection to occurrence ref in a ListBox or ComboBox.

=head2 select_string

    $control->select_string($string)

sets selection according to string in a ListBox or ComboBox.

=head2 is_checked

    $boolean = $control->is_checked()

returns true if a Button is checked.

=head2 check

    $control->check()

checks a radio or check Button.

=head2 uncheck

    $control->uncheck()

unchecks a radio or check Button.

=head2 line_number

    $current_line_number = $control->line_number()

returns the line # where the caret is in an Edit.

=head2 column

    $current_column = $control->column()

returns the column # where the caret is in an Edit.

=head2 selection

    $current_selection = $control->selection()

returns name of the currently selected item in a ListBox or ComboBox.

=head2 line_count

    $line_count = $control->line_count()

returns # of lines in an Edit.

=head2 line

    $text = $control->line($line_number)

returns text at line # passed of an Edit.

=head2 selected

    $text = $control->selected()

returns selected text of an Edit.

=head2 paste

    $control->paste($string)

pastes the 'string' at the Edit's caret position.

=head2 tab

    $current_tab = $control->tab()

returns the current Tab shown of a SysTabControl32.

=head2 tab_right

    $control->tab_right()

moves to the next tab to the right of a SysTabControl32.

=head2 tab_left

    $control->tab_left()

moves to the next tab to the left of a SysTabControl32.

=head2 AutoItX native methods

This module also autoloads all AutoItX methods. For example:

    $control->WinActivate($win_title) unless $control->WinActive($win_title);

Please see AutoItX Help file for documenation of all available methods.

=cut

sub AUTOLOAD {
    my $self = shift;
    my $method = our $AUTOLOAD;
    $method =~ s/.*:://;

    my @params = @_;
    if (exists $Helper_Methods{$method}) {
        $method = $Helper_Methods{$method};
        unshift @params, $self->{title}, $self->{text}, $self->{control};
    }
    if (exists $Control_Commands{$method}) {
        push @params, '' unless @params;
        unshift @params, $self->{title}, $self->{text}, $self->{control},
                         $Control_Commands{$method};
        $method = 'ControlCommand';
    }
    print "Call AutoItX method $method with params: @params\n"
        if $self->{autoitx}->debug;
    $self->{autoitx}->{autoit}->$method(@params);
}
#-------------------------------------------------------------------------------

=head1 SEE ALSO

=over

=item L<Win32::AutoItX::Control::ListView>

=item L<Win32::AutoItX::Control::TreeView>

=item L<Win32::AutoItX::Window>

=item L<Win32::AutoItX>

=item AutoItX Help

=back

=head1 AUTHOR

Mikhail Telnov E<lt>Mikhail.Telnov@gmail.comE<gt>

=head1 COPYRIGHT

This software is copyright (c) 2017 by Mikhail Telnov.

This library is free software; you may redistribute and/or modify it
under the same terms as Perl itself.

=cut

1;
