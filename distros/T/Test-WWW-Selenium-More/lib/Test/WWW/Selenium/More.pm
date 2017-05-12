package Test::WWW::Selenium::More;

use Carp;
use Moose;
use Test::WWW::Selenium;
use namespace::autoclean;

our $VERSION = '0.12'; # VERSION


has host    => ( is => 'rw', isa => 'Str', builder => '_host' );
has port    => ( is => 'rw', isa => 'Int', builder => '_port' );
has browser => ( is => 'rw', isa => 'Str', builder => '_browser' );
has browser_url => (
    is       => 'rw',
    isa      => 'Str',
    builder  => '_browser_url',
    required => 1,
    lazy     => 1
);
has autostop => ( is => 'rw', isa => 'Bool',    builder => '_autostop' );
has slow     => ( is => 'rw', isa => 'Int',     builder => '_slow' );
has _stash   => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

sub _host     { $ENV{SELENIUM_HOST}     || 'localhost' }
sub _port     { $ENV{SELENIUM_PORT}     || 4444 }
sub _browser  { $ENV{SELENIUM_BROWSER}  || '*chrome' }
sub _autostop { $ENV{SELENIUM_AUTOSTOP} || 1 }
sub _slow     { $ENV{SELENIUM_SLOW}     || 0 }

sub _browser_url {
    $ENV{SELENIUM_BROWSER_URL} || confess 'browser_url is required';
}

# Delegation.  This effectively wraps Test::WWW::Selenium.
# TODO I think this is kinda slow.  Or maybe Moose is always slow?
has selenium => (
    is      => 'ro',
    isa     => 'Test::WWW::Selenium',
    handles => sub {
        map { chomp; $_ => $_ } <DATA>;
    },
    builder => '_selenium',
    lazy    => 1,             # to ensure the builder works right
);

sub _selenium {
    my $self     = shift;
    my $selenium = Test::WWW::Selenium->new(
        port        => $self->port,
        host        => $self->host,
        browser     => $self->browser,
        browser_url => $self->browser_url,
        autostop    => $self->autostop,
    );
    $selenium->open('/');
    $selenium->delete_all_visible_cookies;
    return $selenium;
}

has _timeout => (
    is      => 'rw',
    isa     => 'Int',
    default => 30000,
);

# Override some of the Test::WWW::Selenium methods so that they return $self.
# This enables us to chain commands.
around qr/
            (
                _ok$   | # methods that end in _ok or 
                _is$   | # methods that end in _is or 
                _isnt$ | # methods that end in _isnt or 
                _like$   # methods that end in _like
            )
         /ix => sub {
    my $orig = shift;
    my $self = shift;
    $self->$orig(@_);
    sleep $self->slow;
    return $self;
};

# Selenium has a bug where it (sometimes?) doesn't really wait for the page to
# load unless you pass an argument to this sub.  Also return $self so that we
# can have chained commands.
around wait_for_page_to_load_ok => sub {
    my $orig = shift;
    my $self = shift;
    if ( scalar @_ == 0 ) {
        $self->$orig( $self->_timeout );
    } else {
        $self->$orig(@_);
    }
    return $self;
};

# Selenium has a bug where it (sometimes?) doesn't really wait for the page to
# load unless you pass an argument to this sub.  But don't return $self.  We
# want to preserve return values from non test methods so that people can get
# return values when they really want them.
around wait_for_page_to_load => sub {
    my $orig = shift;
    my $self = shift;
    if ( scalar @_ == 0 ) {
        return $self->$orig( $self->_timeout );
    } else {
        return $self->$orig(@_);
    }
};

__PACKAGE__->meta->make_immutable;


sub load_data {
    my ( $self, $file ) = @_;
    die $! unless ( my @test_data = do $file );
    die $@ if $@;
    return do $file;
}

sub _wait_with_message {
    my ($self) = @_;
    my $t      = $self->_timeout;
    my $msg    = "waited ${t} milliseconds but page never loaded";
    $self->wait_for_page_to_load
        or Test::Most::diag($msg);
    return $self;
}


sub follow_link_ok {
    my ( $self, $locator, $text ) = @_;

    my $test_description = "follow_link, ${locator} ";
    $test_description .= $text
        if defined $text;

    my $return_value = $self->click($locator)
        && $self->_wait_with_message();

    Test::Most::ok( $return_value, $test_description );

    return $self;
}


sub fill_form_ok {
    my ( $self, $form ) = @_;

    if ( $form->{input} ) {
        foreach my $locator ( keys %{ $form->{input} } ) {
            $self->type_ok( $locator, $form->{input}->{$locator} );
        }
    }

    if ( $form->{select} ) {
        foreach my $locator ( keys %{ $form->{select} } ) {
            $self->select_ok( $locator, $form->{select}->{$locator} );
        }
    }

    return $self;
}


sub submit_form_ok {
    my ( $self, $form ) = @_;

    die "submit or click keys are required"
        unless ( $form->{click} || $form->{submit} );

    $self->fill_form_ok($form);

    $self->follow_link_ok( $form->{click} )
        if $form->{click};

    if ( $form->{submit} ) {
        $self->submit_ok( $form->{submit} )
            && $self->_wait_with_message();
    }

    return $self;
}


sub wait_for_jquery_ok {
    my ($self) = @_;

    $self->wait_for_condition_ok(
        'selenium.browserbot.getCurrentWindow().jQuery.active == 0',
        $self->_timeout,                                 #
        'wait_for_jquery_to_load, ' . $self->_timeout    #
    );

    return $self;
}


sub jquery_select_ok {
    my $self = shift;
    $self->select_ok(@_) && $self->wait_for_jquery_ok;
    return $self;
}


sub select_and_page_load_ok {
    my $self = shift;
    $self->select_ok(@_)
        && $self->wait_for_page_to_load_ok;
    return $self;
}


sub jquery_click_ok {
    my $self = shift;
    $self->click_ok(@_) && $self->wait_for_jquery_ok;
    return $self;
}


sub stash_text {
    my $self    = shift;
    my $locator = shift;
    my $key     = shift;
    $self->_stash->{$key} = $self->get_text( $locator, @_ );
    return $self;
}


sub stash_location {
    my $self = shift;
    my $key  = shift;
    $self->_stash->{$key} = $self->get_location(@_);
    return $self;
}


sub from_stash {
    my $self = shift;
    my $key  = shift;
    return $self->_stash->{$key};
}


sub stash {
    my $self  = shift;
    my $value = shift;
    my $key   = shift;
    $self->_stash->{$key} = $value;
    return $self;
}


sub note {
    my ( $self, $msg ) = @_;
    Test::Most::note($msg);
    return $self;
}


sub is_text_not_present_ok {
    my ( $self, $text, $name ) = @_;
    $name //= "is_text_not_present, $text";
    Test::Most::ok( !$self->is_text_present($text), $name );
    return $self;
}


sub note_line {
    my ( $self, $msg ) = @_;
    my $length = length($msg) || 80;
    $self->note( "_" x $length );
    $self->note( " " x $length );
    $self->note($msg) if $msg;
    $self->note( "_" x $length );
    $self->note( " " x $length );
    return $self;
}


sub download_file_ok {
    my $self    = shift or die;
    my $locator = shift or die;
    my $url     = $self->get_attribute( $locator . '@href' );

    my $return_value = $self->get_eval(
        qq{1 + 1},
        $self->_timeout,    #
        qq{downloading $url, } . $self->_timeout
    );                      #
    Test::Most::is( $return_value, 2,
        qq{Download host is reachable: $return_value} )
        or return $self;

    $self->run_script(
        'function seleniumDownloadFileOk() {
             var xmlhttp=new XMLHttpRequest();
             xmlhttp.open("GET","' . $url . '",false);
             xmlhttp.send("");
             return xmlhttp.status;
         }',
        $self->_timeout,                            #
        '0 downloading $url, ' . $self->_timeout    #
    );

    my $status = $self->get_eval(
        'selenium.browserbot.getCurrentWindow().seleniumDownloadFileOk()',
        $self->_timeout,                            #
        "downloading ${url}" . $self->_timeout
    );                                              #

    Test::Most::is( $status, 200, qq{Download status: $status} );
    return $self;
}


sub change_speed {
    my $self = shift or die;
    my $seconds = shift || 0;
    $self->slow($seconds);
    return $self;
}

1;

# ABSTRACT: More tools for Selenium testing



# I used this command to get the list of functions in WWW::Selenium:
#    grep '=item $sel-' /usr/local/lib/perl/5.10.0/WWW/Selenium.pm
# Then I used vim to get rid of the extra stuff.  Then I used vim to add the
# additional functions from Test::WWW::Selenium.


=pod

=encoding utf-8

=head1 NAME

Test::WWW::Selenium::More - More tools for Selenium testing

=head1 SYNOPSIS

    use Test::WWW::Selenium::More;

    Test::WWW::Selenium::More->new()
      ->note('this is a test.  this is only a test.')
      ->open_ok("/") 
      ->is_text_present_ok("Welcome to the internet") 
      ->download_file_ok('link=Download my file');

=head1 DESCRIPTION

This module provides method chaining and some useful tools for Selenium
testing.

If you are new to this module or Selenium testing in general, see the
L<Test::WWW::Selenium::More::Manual>.

This library extends L<Test::WWW::Selenium>.   Method chaining is available for
all Test::WWW::Selenium::More methods and all Test::WWW::Selenium methods whose
names end in _ok, _is, _isnt or _like.  

=head1 ATTRIBUTES

=head2 host

The hostname or ip address of the Selenium server.  Defaults to 'localhost'.

=head2 port

The port of the Selenium server.  Defaults to '4444'.

=head2 browser

The browser to run tests against on the Selenium server.  Defaults to
'*chrome'.

=head2 browser_url

The Selenium server runs tests against this website.  

=head2 autostop

When $selenium goes out of scope the browser will be automatically shut down if
this attribute is set to true.  Otherwise stop() must be called explicitly.
Defaults to 1.

=head2 slow

The number of seconds to sleep after each call to any Test::WWW::Selenium
method.  This is useful for slowing down tests if you are watching them run in
a browser.  Defaults to 0.

=head2 stash

A HashRef of saved values.  This behaves similar to the Catalyst stash.

=head1 METHODS

=head2 load_data( $file )

Returns a data structure from $file.  $file must have valid Perl syntax.

This method is for use with data driven tests.  It helps you to separate your
Perl code from your test data.

Here is an example of what the contents of $file could look like:

(
    {
         name => 'Name of my test',
         link => 'Click me',
         text => 'Ponies',
    },
    {
         name => 'Test downloading stuff',
         link => 'Download',
         text => 'Download worked',
    },
    ...
);

=head2 follow_link_ok( $locator, $test_description )

Returns $self.

This method performs a click_ok on the page element specified by $locator and
then does a wait_for_page_to_load().  $test_description is optional.  It will
be set to something appropriate if you don't set it. 

=head2 fill_form_ok( $form )

Returns $self.

$form must be a hashref that looks like this:

    $selenium->fill_form_ok(
        { select => { locator => value, ... },
          input  => { locator => value, ... },
        }
    );

The 'select' key indicates dropdown menus that will be selected.  The 'input'
key indicates text input, hidden input, checkboxes, and radio buttons.

The form is not submitted.

=head2 submit_form_ok( $form )

Returns $self.

$form must be a hashref that looks like this:

    $selenium->submit_form_ok(
        { select => { locator => value, ... },
          input  => { locator => value, ... },
          click  => 'locator', # or 'submit' instead of 'click'
        }
    );

$form is simply passed to fill_form_ok().  Afterwards submit_form_ok() looks
for 2 keys to process: 'click' and 'submit'.  The form is submitted via 
a click on page element indicated by 'locator' when 'click' is used.  The form
is submitted without a click when 'submit' is used.  This is useful for forms
without submit buttons.

=head2 wait_for_jquery_ok()

Returns $self.

This blocks until jQuery.active returns false.

=head2 jquery_select_ok($locator, $menu_option)

Returns $self.

$locator should point to a dropdown menu on the page.  This method will select
the $menu_option from the dropdown.  Then it will call wait_for_jquery().

=head2 select_and_page_load_ok($locator, $menu_option)

Returns $self.

$locator should point to a dropdown menu on the page.  This method will select
the $menu_option from the dropdown.  Then it will call wait_for_page_to_load().

=head2 jquery_click_ok($locator, $menu_option)

Returns $self.

Click whatever is located at $locator.  Then wait for jquery to finish by
calling wait_for_jquery().

=head2 stash_text( $locator => $key )

Returns $self.

Retrieves the value of $locator from selenium and stores it in the stash under
the name $key.

=head2 stash_location( $key )

Returns $self.

Retrieves the location from selenium and stores it in the stash under the name $key.

=head2 from_stash( $key )

Returns a value from the stash.

=head2 stash( $value => $key )

Returns $self.

Saves $value to the stash under the name $key.

=head2 note( $msg )

Returns $self.

calls Test::Most::note($msg);

=head2 is_text_not_present_ok( $text )

Returns $self.

The opposite of is_text_present_ok().

=head2 note_line( $msg )

Outputs an underlined message, useful for dividing up test output. If no
message specified, then just prints the separator line.

=head2 download_file_ok($locator)

Parses the href attribute from a link on the current page.  Downloads that url
via javascript's XMLHttpRequest.  Checks that response status is 200.

=head2 change_speed($seconds)

This just updates the slow() attribute.  The only difference is that it
returns $self so that you can do method chaining. 

=head1 ENVIRONMENT VARIABLES

The following is a list of environment variables that affect the behavior of
this library.  Each corresponds to an attribute (see the ATTRIBUTES
section).

=head2 SELENIUM_HOST

=head2 SELENIUM_PORT

=head2 SELENIUM_BROWSER

=head2 SELENIUM_BROWSER_URL

=head2 SELENIUM_TIMEOUT

=head2 SELENIUM_AUTOSTOP

=head2 SELENIUM_SLOW

=head1 AUTHOR

Eric Johnson <kablamo at iijo dot nospamthanks dot org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Eric Johnson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__
get_absolute_location
absolute_location_is
absolute_location_isnt
absolute_location_like
absolute_location_unlike
get_alert
alert_is
alert_isnt
alert_like
alert_unlike
get_all_buttons
all_buttons_is
all_buttons_isnt
all_buttons_like
all_buttons_unlike
get_all_fields
all_fields_is
all_fields_isnt
all_fields_like
all_fields_unlike
get_all_links
all_links_is
all_links_isnt
all_links_like
all_links_unlike
get_all_window_ids
all_window_ids_is
all_window_ids_isnt
all_window_ids_like
all_window_ids_unlike
get_all_window_names
all_window_names_is
all_window_names_isnt
all_window_names_like
all_window_names_unlike
get_all_window_titles
all_window_titles_is
all_window_titles_isnt
all_window_titles_like
all_window_titles_unlike
get_attribute
attribute_is
attribute_isnt
attribute_like
attribute_unlike
get_attribute_from_all_windows
attribute_from_all_windows_is
attribute_from_all_windows_isnt
attribute_from_all_windows_like
attribute_from_all_windows_unlike
get_body_text
body_text_is
body_text_isnt
body_text_like
body_text_unlike
get_checked
checked_is
checked_isnt
checked_like
checked_unlike
get_confirmation
confirmation_is
confirmation_isnt
confirmation_like
confirmation_unlike
get_cookie
cookie_is
cookie_isnt
cookie_like
cookie_unlike
get_cookie_by_name
cookie_by_name_is
cookie_by_name_isnt
cookie_by_name_like
cookie_by_name_unlike
get_cursor_position
cursor_position_is
cursor_position_isnt
cursor_position_like
cursor_position_unlike
get_element_height
element_height_is
element_height_isnt
element_height_like
element_height_unlike
get_element_index
element_index_is
element_index_isnt
element_index_like
element_index_unlike
get_element_position_left
element_position_left_is
element_position_left_isnt
element_position_left_like
element_position_left_unlike
get_element_position_top
element_position_top_is
element_position_top_isnt
element_position_top_like
element_position_top_unlike
get_element_width
element_width_is
element_width_isnt
element_width_like
element_width_unlike
get_eval
eval_is
eval_isnt
eval_like
eval_unlike
get_expression
expression_is
expression_isnt
expression_like
expression_unlike
get_html_source
html_source_is
html_source_isnt
html_source_like
html_source_unlike
get_location
location_is
location_isnt
location_like
location_unlike
get_mouse_speed
mouse_speed_is
mouse_speed_isnt
mouse_speed_like
mouse_speed_unlike
get_prompt
prompt_is
prompt_isnt
prompt_like
prompt_unlike
get_select_options
select_options_is
select_options_isnt
select_options_like
select_options_unlike
get_selected_id
selected_id_is
selected_id_isnt
selected_id_like
selected_id_unlike
get_selected_ids
selected_ids_is
selected_ids_isnt
selected_ids_like
selected_ids_unlike
get_selected_index
selected_index_is
selected_index_isnt
selected_index_like
selected_index_unlike
get_selected_indexes
selected_indexes_is
selected_indexes_isnt
selected_indexes_like
selected_indexes_unlike
get_selected_label
selected_label_is
selected_label_isnt
selected_label_like
selected_label_unlike
get_selected_labels
selected_labels_is
selected_labels_isnt
selected_labels_like
selected_labels_unlike
get_selected_options
selected_options_is
selected_options_isnt
selected_options_like
selected_options_unlike
get_selected_value
selected_value_is
selected_value_isnt
selected_value_like
selected_value_unlike
get_selected_values
selected_values_is
selected_values_isnt
selected_values_like
selected_values_unlike
get_speed
speed_is
speed_isnt
speed_like
speed_unlike
get_table
table_is
table_isnt
table_like
table_unlike
get_text
text_is
text_isnt
text_like
text_unlike
get_title
title_is
title_isnt
title_like
title_unlike
get_value
value_is
value_isnt
value_like
value_unlike
get_whether_this_frame_match_frame_expression
whether_this_frame_match_frame_expression_is
whether_this_frame_match_frame_expression_isnt
whether_this_frame_match_frame_expression_like
whether_this_frame_match_frame_expression_unlike
get_whether_this_window_match_window_expression
whether_this_window_match_window_expression_is
whether_this_window_match_window_expression_isnt
whether_this_window_match_window_expression_like
whether_this_window_match_window_expression_unlike
get_xpath_count
xpath_count_is
xpath_count_isnt
xpath_count_like
xpath_count_unlike
add_location_strategy
add_location_strategy_ok
add_script
add_script_ok
add_selection
add_selection_ok
allow_native_xpath
allow_native_xpath_ok
alt_key_down
alt_key_down_ok
alt_key_up
alt_key_up_ok
answer_on_next_prompt
answer_on_next_prompt_ok
assign_id
assign_id_ok
attach_file
attach_file_ok
capture_entire_page_screenshot
capture_entire_page_screenshot_ok
capture_entire_page_screenshot_to_string
capture_entire_page_screenshot_to_string_ok
capture_screenshot
capture_screenshot_ok
capture_screenshot_to_string
capture_screenshot_to_string_ok
check
check_ok
choose_cancel_on_next_confirmation
choose_cancel_on_next_confirmation_ok
choose_ok_on_next_confirmation
choose_ok_on_next_confirmation_ok
click
click_ok
click_at
click_at_ok
close
close_ok
context_menu
context_menu_ok
context_menu_at
context_menu_at_ok
control_key_down
control_key_down_ok
control_key_up
control_key_up_ok
create_cookie
create_cookie_ok
delete_all_visible_cookies
delete_all_visible_cookies_ok
delete_cookie
delete_cookie_ok
deselect_pop_up
deselect_pop_up_ok
double_click
double_click_ok
double_click_at
double_click_at_ok
drag_and_drop
drag_and_drop_ok
drag_and_drop_to_object
drag_and_drop_to_object_ok
dragdrop
dragdrop_ok
fire_event
fire_event_ok
focus
focus_ok
go_back
go_back_ok
highlight
highlight_ok
ignore_attributes_without_value
ignore_attributes_without_value_ok
is_alert_present
is_alert_present_ok
is_checked
is_checked_ok
is_confirmation_present
is_confirmation_present_ok
is_cookie_present
is_cookie_present_ok
is_editable
is_editable_ok
is_element_present
is_element_present_ok
is_location
is_location_ok
is_ordered
is_ordered_ok
is_prompt_present
is_prompt_present_ok
is_selected
is_selected_ok
is_something_selected
is_something_selected_ok
is_text_present
is_text_present_ok
is_visible
is_visible_ok
key_down
key_down_ok
key_down_native
key_down_native_ok
key_press
key_press_ok
key_press_native
key_press_native_ok
key_up
key_up_ok
key_up_native
key_up_native_ok
meta_key_down
meta_key_down_ok
meta_key_up
meta_key_up_ok
mouse_down
mouse_down_ok
mouse_down_at
mouse_down_at_ok
mouse_down_right
mouse_down_right_ok
mouse_down_right_at
mouse_down_right_at_ok
mouse_move
mouse_move_ok
mouse_move_at
mouse_move_at_ok
mouse_out
mouse_out_ok
mouse_over
mouse_over_ok
mouse_up
mouse_up_ok
mouse_up_at
mouse_up_at_ok
mouse_up_right
mouse_up_right_ok
mouse_up_right_at
mouse_up_right_at_ok
open
open_ok
open_window
open_window_ok
pause
pause_ok
refresh
refresh_ok
remove_all_selections
remove_all_selections_ok
remove_script
remove_script_ok
remove_selection
remove_selection_ok
retrieve_last_remote_control_logs
retrieve_last_remote_control_logs_ok
rollup
rollup_ok
run_script
run_script_ok
select
select_ok
select_frame
select_frame_ok
select_pop_up
select_pop_up_ok
select_window
select_window_ok
set_browser_log_level
set_browser_log_level_ok
set_context
set_context_ok
set_cursor_position
set_cursor_position_ok
set_mouse_speed
set_mouse_speed_ok
set_speed
set_speed_ok
set_timeout
set_timeout_ok
shift_key_down
shift_key_down_ok
shift_key_up
shift_key_up_ok
shut_down_selenium_server
shut_down_selenium_server_ok
submit
submit_ok
type
type_ok
type_keys
type_keys_ok
uncheck
uncheck_ok
use_xpath_library
use_xpath_library_ok
wait_for_condition
wait_for_condition_ok
wait_for_element_present
wait_for_element_present_ok
wait_for_frame_to_load
wait_for_frame_to_load_ok
wait_for_page_to_load
wait_for_page_to_load_ok
wait_for_pop_up
wait_for_pop_up_ok
wait_for_text_present
wait_for_text_present_ok
window_focus
window_focus_ok
window_maximize
window_maximize_ok
stop
