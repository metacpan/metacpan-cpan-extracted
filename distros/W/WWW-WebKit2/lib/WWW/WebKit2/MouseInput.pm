package WWW::WebKit2::MouseInput;

use Moose::Role;
use Carp qw(carp croak);
use WWW::WebKit2::MouseInput::DragAndDropSimulator;

has event_send_delay => (
    is  => 'rw',
    isa => 'Int',
    default => 0, # ms
);

has drag_and_drop_simulator => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        return WWW::WebKit2::MouseInput::DragAndDropSimulator->new->javascript_string;
    },
);

sub select {
    my ($self, $select, $option) = @_;

    $select = $self->resolve_locator($select) or return;
    $option = $self->resolve_locator($option, $select) or return;

    my $option_value = $option->get_value;
    my $set_select =
        $select->prepare_element .
        'var options = element.options;
        var found = 0;
        for (var i = 0; i < options.length; i++) {
            if (options[i].value === ' . "'$option_value'" . qq/ ) {
                element.selectedIndex = i;
                options[i].selected = true;
                found = 1;
                break;
            }
        }
        if (!found)
            throw 'Did not find value "$option_value" for select $select';
        window.event_fired = "initialized";
        element.addEventListener("change", function(e) {
           window.event_fired = "fired";
        }, { once: true });
        var event = new Event("change", { "bubbles": true, "cancelable": true });
        element.dispatchEvent(event);
    /;

    $self->run_javascript($set_select);
    $self->wait_for_condition(sub {
        my $event_fired = $self->run_javascript("return window.event_fired");
        # event_fired will be undef if the event triggered a page load
        return 1 if (not $event_fired or $event_fired eq "fired");
        return 0;
    });


    $self->process_page_load;

    return 1;
}

sub change_check {
    my ($self, $element, $set_checked) = @_;

    if ($set_checked) {
        $element->set_attribute('checked', 'checked');
    }
    else {
        $element->remove_attribute('checked');
    }
    $element->fire_event('change');
    $self->process_page_load;

    return 1;
}

=head3 check($locator)

=cut

sub check {
    my ($self, $locator) = @_;

    my $element = $self->resolve_locator($locator);
    return $self->change_check($element, 'true');
}

=head3 uncheck($locator)

=cut

sub uncheck {
    my ($self, $locator) = @_;

    my $element = $self->resolve_locator($locator);
    return $self->change_check($element, undef);
}

sub click {
    my ($self, $locator, $wait) = @_;

    my $element = $self->resolve_locator($locator);

    die "Element doesn't exist: " . $locator unless $element->get_length;

    my $tag  = lc $element->get_node_name;
    my $type = lc ($element->get_attribute('type') // '');

    if ($tag eq 'input' and ($type eq 'checkbox' or $type eq 'radio')) {
        $element->property_search('click()');
    }
    else {
        $element->fire_event('click');
    }

    if ($wait) {
        $self->wait_for_condition(sub {
            $self->is_loading;
        }, $wait);
    }

    $self->process_page_load;

    return 1;
}

sub click_and_wait {
    my ($self, $locator, $timeout) = @_;

    $timeout //= $self->default_timeout;
    return $self->click($locator, $timeout);
}

sub left_click {
    my ($self) = @_;

    $self->clear_events;
    $self->press_mouse_button(1);
    $self->wait_for_mouse_click_event;
    $self->pause(100);

    $self->clear_events;
    $self->release_mouse_button(1);
    $self->wait_for_mouse_click_event;
    $self->pause(100);

    return 1;
}

sub wait_for_mouse_motion_event {
    my ($self) = @_;

    $self->wait_for_condition(sub {
        $self->find_event(sub {
            my $event_type = scalar $_;
            return $event_type =~ /EventMotion/;
        });
    });
}

sub wait_for_mouse_click_event {
    my ($self) = @_;

    $self->wait_for_condition(sub {
        $self->find_event(sub {
            my $event_type = scalar $_;
            return $event_type =~ /EventButton/;
        });
    });
}

sub mouse_over {
    my ($self, $locator) = @_;

    my $mouse_over = $self->resolve_locator($locator);

    return $self->fire_mouse_event($mouse_over, 'mouseover');
}

=head3 mouse_down($locator)

=cut

sub mouse_down {
    my ($self, $locator) = @_;

    my $mouse_down = $self->resolve_locator($locator);

    return $self->fire_mouse_event($mouse_down, 'mousedown');
}

=head3 mouse_up($locator)

=cut

sub mouse_up {
    my ($self, $locator) = @_;

    my $mouse_up = $self->resolve_locator($locator);

    return $self->fire_mouse_event($mouse_up, 'mouseup');
}

=head2 double_click

=cut

sub double_click {
    my ($self, $locator) = @_;

    my $element = $self->resolve_locator($locator);

    $self->fire_mouse_event(
        $element,
        'dblclick'
    );
}

sub fire_mouse_event {
    my ($self, $element, $event) = @_;

    my $ctrl_down  = $self->modifiers->{control} ? 'true' : 'false';
    my $shift_down = $self->modifiers->{shift}   ? 'true' : 'false';

    my $mouse_up_script = $element->prepare_element .
        " var clickEvent = document.createEvent('MouseEvents');
        clickEvent.initMouseEvent(
            '$event',
            true,
            true,
            window,
            0,
            0,
            0,
            0,
            0,
            $ctrl_down,
            $shift_down
        );

        return element.dispatchEvent(clickEvent);";

    $self->run_javascript($mouse_up_script);

    return 1;
}

sub move_mouse_abs {
    my ($self, $x, $y) = @_;

    $self->display->XTestFakeMotionEvent(0, $x, $y, $self->event_send_delay);
    $self->display->XFlush;
}

sub press_mouse_button {
    my ($self, $button) = @_;

    $self->display->XTestFakeButtonEvent($button, 1, $self->event_send_delay);
    $self->display->XFlush;
}

sub release_mouse_button {
    my ($self, $button) = @_;

    $self->display->XTestFakeButtonEvent($button, 0, $self->event_send_delay);
    $self->display->XFlush;
}

=head3 native_drag_and_drop_to_position($source_locator, $target_x, $target_y, $options)

Drag source element and drop it to position $target_x, $target_y.

=cut

sub native_drag_and_drop_to_position {
    my ($self, $source_locator, $target_x, $target_y, $options) = @_;
    $self->check_window_bounds($target_x, $target_y, "target");

    my $steps = $options->{steps} // 5;
    my $step_delay =  $options->{step_delay} // 150; # ms
    $self->event_send_delay($options->{event_send_delay}) if $options->{event_send_delay};

    my ($source_x, $source_y) = $self->get_center_screen_position($source_locator);
    $self->check_window_bounds($source_x, $source_y, "source '$source_locator'");

    my ($delta_x, $delta_y) = ($target_x - $source_x, $target_y - $source_y);
    my ($step_x, $step_y) = (int($delta_x / $steps), int($delta_y / $steps));
    my ($x, $y) = ($source_x, $source_y);

    $self->move_mouse_abs($source_x, $source_y);
    $self->pause($step_delay);
    $self->clear_events;
    $self->press_mouse_button(1);
    $self->wait_for_mouse_click_event;
    $self->pause($step_delay);

    foreach (1..$steps) {
        $self->move_mouse_abs($x += $step_x, $y += $step_y);
        $self->pause($step_delay);
    }

    $self->move_mouse_abs($target_x, $target_y);
    $self->pause($step_delay);
    $self->release_mouse_button(1);
    $self->pause($step_delay);
    $self->move_mouse_abs($target_x, $target_y);
    $self->pause($step_delay);

    $self->process_page_load;
}


=head3 native_drag_and_drop_to_object($source_locator, $target_locator, $options)

Drag source element and drop it into target element.

=cut

sub native_drag_and_drop_to_object {
    my ($self, $source_locator, $target_locator) = @_;

    my $simulator = $self->drag_and_drop_simulator;
    my $source_element = $self->resolve_locator($source_locator)->prepare_element('source');
    my $target_element = $self->resolve_locator($target_locator)->prepare_element('target');
    my $js_string = qq{
        $simulator
        $source_element
        $target_element
        DndSimulator.simulate(source, target);
        return 1;
    };

    $self->run_javascript($js_string);

    $self->process_page_load;
}

=head3 mouse_input_drag_and_drop_to_object($source_locator, $target_locator, $options)

Drag source element and drop it into target element.
This method is similar to native_drag_and_drop_to_object but will do the action using X11libs XTest input simulation methods

=cut


sub mouse_input_drag_and_drop_to_object {
    my ($self, $source_locator, $target_locator, $options) =@_;

    croak "did not find element $source_locator" unless $self->resolve_locator($source_locator)->get_length;
    croak "did not find element $target_locator" unless $self->resolve_locator($target_locator)->get_length;

    my $steps = $options->{steps} // 5;
    my $step_delay = $options->{step_delay} // 150; #ms
    $self->event_send_delay($options->{event_send_delay}) if $options->{event_send_delay};

    my ($x, $y) = $self->get_center_screen_position($source_locator);
    $self->check_window_bounds($x, $y, "source '$source_locator'");

    $self->pause($step_delay);
    $self->move_mouse_abs($x, $y);
    $self->pause($step_delay);
    $self->press_mouse_button(1);
    $self->pause($step_delay);

    my ($target_x, $target_y) = $self->get_center_screen_position($target_locator);
    $self->check_window_bounds($target_x, $target_y, "target '$target_locator'");

    foreach (0 .. $steps -1) {
        my $delta_x = $target_x - $x;
        my $delta_y = $target_y - $y;
        my $step_x = int($delta_x / ($steps - $_));
        my $step_y = int($delta_y / ($steps - $_));

        $self->move_mouse_abs($x += $step_x, $y += $step_y);
        $self->pause($step_delay);
    }

    # "move" mouse again to cause a dragover event on the target
    # otherwise a drop may not work
    $self->move_mouse_abs($x, $y);
    $self->pause($step_delay);

    $self->release_mouse_button(1);
    $self->pause($step_delay);
    $self->move_mouse_abs($x, $y);
    $self->pause($step_delay);
    $self->pause(300);

    return $self;
}

1;
