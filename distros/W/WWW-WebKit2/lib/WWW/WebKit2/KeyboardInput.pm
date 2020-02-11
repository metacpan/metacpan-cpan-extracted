package WWW::WebKit2::KeyboardInput;

use Moose::Role;
use Time::HiRes qw(time usleep);

=head3 type($locator, $text)

=cut

sub type {
    my ($self, $locator, $text) = @_;

    # javascript can not deal with regular linebreaks
    $text =~ s/\n/ \\n/g;
    $self->resolve_locator($locator)->set_value($text);

    $self->process_page_load;

    return 1;
}

=head3 type_keys($locator, $string)

=cut

sub type_keys {
    my ($self, $locator, $string) = @_;

    my $element = $self->resolve_locator($locator);

    foreach (split //, $string) {
        $self->shift_key_down if $self->is_upper_case($_);
        $self->key_press($locator, $_, $element) or return;
        $self->shift_key_up if $self->is_upper_case($_);
    }

    $self->process_page_load;

    return 1;
}

sub is_upper_case {
    my ($self, $char) = @_;

    return $char =~ /[A-Z]/;
}

sub control_key_down {
    my ($self) = @_;

    $self->modifiers->{control} = 1;
}

sub control_key_up {
    my ($self) = @_;

    $self->modifiers->{control} = 0;
}

sub shift_key_down {
    my ($self) = @_;

    $self->modifiers->{'shift'} = 1;
}

sub shift_key_up {
    my ($self) = @_;

    $self->modifiers->{'shift'} = 0;
}

my %keycodes = (
    '\013' => 36,  # Carriage Return
    "\n"   => 36,  # Carriage Return
    '\9'   => 23,  # Tabulator
    "\t"   => 23,  # Tabulator
    '\027' => 9,   # Escape
    ' '    => 65,  # Space
    '\032' => 65,  # Space
    '\127' => 119, # Delete
    '\8'   => 22,  # Backspace
    '\044' => 59,  # Comma
    ','    => 59,  # Comma
    '\045' => 20,  # Hyphen
    '-'    => 20,  # Hyphen
    '\046' => 60,  # Dot
    '.'    => 60,  # Dot
);

sub key_press {
    my ($self, $locator, $key, $element) = @_;

    my $display = X11::Xlib->new;

    my $keycode = exists $keycodes{$key}
        ? $keycodes{$key}
        : $display->XKeysymToKeycode(X11::Xlib::XStringToKeysym($key));

    $element ||= $self->resolve_locator($locator) or return;
    $element->focus;

    my $shift_keycode = 62;
    $display->XTestFakeKeyEvent($shift_keycode, 1, 1) if $self->modifiers->{'shift'};
    $display->XTestFakeKeyEvent($keycode, 1, 1);
    $display->XTestFakeKeyEvent($keycode, 0, 1);
    $display->XTestFakeKeyEvent($shift_keycode, 0, 1) if $self->modifiers->{'shift'};
    $display->XFlush;

    usleep 50000; # time for the X server to deliver the event

    $self->process_page_load;

    return 1;
}

=head3 delete_text($locator)

Delete text in elements where contenteditable="true".

=cut

sub delete_text {
    my ($self, $locator) = @_;

    my $element = $self->resolve_locator($locator) or return;

    while ($self->get_text($locator)) {
        $self->key_press($locator, '\127', $element); # Delete
    };

    return 1;
}

=head3 answer_on_next_confirm

=cut

sub answer_on_next_confirm {
    my ($self, $answer) = @_;

    push @{ $self->confirm_answers }, $answer;
}

=head3 answer_on_next_prompt($answer)

=cut

sub answer_on_next_prompt {
    my ($self, $answer) = @_;

    push @{ $self->prompt_answers }, $answer;
}

1;
