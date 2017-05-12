#########
# Author:        setitesuk
use strict;
use warnings;
use Test::More;
use Test::MockObject;

# variables - scalar
my (  $output, $mocked_tws,
      $speed, $alert, $alert_present, $prompt, $prompt_present, $confirmation, $confirmation_present,
      $location, $title, $body_text, $value, $text, $eval, $is_checked, $table_cell, $selected_label,
      $selected_value, $selected_index, $selected_id, $is_something_selected, $attribute,
      $is_text_present, $is_el_present, $is_visible, $is_editable, $html, $is_ordered, $el_pos_left,
      $el_pos_top, $el_width, $el_height, $cursor_position, $expression, $xpath_count, $id, $cookie,
      $script, $is_location, $is_selected, $text_loc, $is_text_present_ok, $type_ok, $click_ok, $wait_for_page_to_load_ok, $open_ok, $title_is );
# variables - array
my (  @selected_values, @selected_labels, @selected_indexes, @selected_ids, @select_options, @buttons,
      @links, @fields, @window_ids, @window_names, @window_titles );

sub BEGIN {
  $mocked_tws = Test::MockObject->new();
  $mocked_tws->fake_module( q{Test::WWW::Selenium} );
  $mocked_tws->set_isa( q{Test::WWW::Selenium} );
  $mocked_tws->fake_new( q{Test::WWW::Selenium} );
  $mocked_tws->set_true( qw{
    pause click double_click context_menu click_at double_click_at
    context_menu_at fire_event focus key_press shift_key_down shift_key_up
    meta_key_down meta_key_up alt_key_down alt_key_up control_key_up
    control_key_down key_down key_up mouse_over mouse_out mouse_down_right
    mouse_down_at mouse_right_down_at mouse_up mouse_up_right mouse_up_at
    mouse_up_right_up mouse_move mouse_move_at type type_keys
    check uncheck select submit open open_window select_window select_pop_up
    deselect_pop_up select_frame wait_for_pop_up choose_cancel_on_next_confirmation
    choose_ok_on_next_confirmation answer_on_next_prompt go_back refresh
    close highlight set_mouse_speed get_mouse_speed drag_and_drop
    drag_and_drop_to_object window_focus window_maximise set_cursor_position
    get_element_index wait_for_condition wait_for_page_to_load wait_for_frame_to_load
    create_cookie delete_cookie delete_all_visible_cookies set_browser_log_level
    attach_file shut_down_selenium_server stop key_down_native key_up_native
    key_press_native wait_for_text_present wait_for_element_present set_timeout
    open_ok is_text_present_ok type_ok click_ok open_ok wait_for_page_to_load_ok
  } );
  $mocked_tws->set_bound( q{set_speed}, \$speed );
  $mocked_tws->set_bound( q{get_speed}, \$speed );
  $mocked_tws->set_bound( q{is_alert_present}, \$alert_present );
  $mocked_tws->set_bound( q{is_prompt_present}, \$prompt_present );
  $mocked_tws->set_bound( q{is_confirmation_present}, \$confirmation_present );
  $mocked_tws->set_bound( q{get_alert}, \$alert );
  $mocked_tws->set_bound( q{get_prompt}, \$prompt );
  $mocked_tws->set_bound( q{get_confirmation}, \$confirmation );
  $mocked_tws->set_bound( q{get_location}, \$location );
  $mocked_tws->set_bound( q{get_title}, \$title );
  $mocked_tws->set_bound( q{get_body_text}, \$body_text );
  $mocked_tws->mock( q{get_value}, sub { return $value } );
  $mocked_tws->mock( q{get_text}, sub { my $loc = shift; if ( $loc ) { return $text_loc; }; return $text } );
  $mocked_tws->mock( q{get_eval}, sub { return $eval } );
  $mocked_tws->set_bound( q{is_checked}, \$is_checked );
  $mocked_tws->mock( q{get_table}, sub { return $table_cell } );
  $mocked_tws->mock( q{get_selected_labels}, sub { return @selected_labels } );
  $mocked_tws->mock( q{get_selected_label}, sub { return $selected_label } );
  $mocked_tws->mock( q{get_selected_values}, sub { return @selected_values } );
  $mocked_tws->mock( q{get_selected_value}, sub { return $selected_value } );
  $mocked_tws->mock( q{get_selected_indexes}, sub { return @selected_indexes } );
  $mocked_tws->mock( q{get_selected_index}, sub { return $selected_index } );
  $mocked_tws->mock( q{get_selected_ids}, sub { return @selected_ids } );
  $mocked_tws->mock( q{get_selected_id}, sub { return $selected_id } );
  $mocked_tws->mock( q{is_something_selected}, sub { return $is_something_selected } );
  $mocked_tws->mock( q{get_select_options}, sub { return @select_options } );
  $mocked_tws->mock( q{get_attribute}, sub { return $attribute } );
  $mocked_tws->mock( q{is_text_present}, sub { return $is_text_present } );
  $mocked_tws->mock( q{is_element_present}, sub { return $is_el_present } );
  $mocked_tws->mock( q{is_visible}, sub { return $is_visible } );
  $mocked_tws->mock( q{is_editable}, sub { return $is_editable } );
  $mocked_tws->mock( q{title_is}, sub { return \$title } );
  $mocked_tws->set_bound( q{get_all_buttons}, \@buttons );
  $mocked_tws->set_bound( q{get_all_links}, \@links );
  $mocked_tws->set_bound( q{get_all_fields}, \@fields );
  $mocked_tws->set_bound( q{get_all_window_ids}, \@window_ids );
  $mocked_tws->set_bound( q{get_all_window_names}, \@window_names );
  $mocked_tws->set_bound( q{get_all_window_titles}, \@window_titles );
  $mocked_tws->set_bound( q{get_all_html_source}, \$html );
  $mocked_tws->mock( q{is_ordered}, sub { return $is_ordered } );
  $mocked_tws->mock( q{get_element_position_left}, sub { return $el_pos_left } );
  $mocked_tws->mock( q{get_element_position_top}, sub { return $el_pos_top } );
  $mocked_tws->mock( q{get_element_width}, sub { return $el_width } );
  $mocked_tws->mock( q{get_element_height}, sub { return $el_height } );
  $mocked_tws->mock( q{set_cursor_position}, sub { my ( $self, $loc, $pos) = @_; $cursor_position = $pos; return $cursor_position } );
  $mocked_tws->mock( q{get_cursor_position}, sub { return $cursor_position } );
  $mocked_tws->mock( q{get_expression}, sub { return $expression } );
  $mocked_tws->mock( q{get_xpath_count}, sub { return $xpath_count } );
  $mocked_tws->mock( q{assign_id}, sub { my ( $self, $loc, $arg_id ) = @_; $id = $arg_id; return $id } );
  $mocked_tws->set_bound( q{get_cookie}, \$cookie );
  $mocked_tws->mock( q{get_cookie_by_name}, sub { return $cookie } );
  $mocked_tws->mock( q{is_cookie_present}, sub { return !! $cookie } );
  $mocked_tws->mock( q{run_script}, sub { return $script } );
}

my $ide = q{Test::WWW::Selenium::Conversion::IDE};
use_ok( $ide );

my $sel = Test::WWW::Selenium->new();
isa_ok( $sel, q{Test::WWW::Selenium} );

$location = q{home};
is( $sel->get_location(), $location, q{mock TWS object} );
@buttons = (1..10);
is_deeply( [$sel->get_all_buttons()], \@buttons, q{buttons returned ok} );
$expression = q{an expression};
is( $sel->get_expression(q{id=some_id}), $expression, q{inputs ignored} );
is( $sel->assign_id( q{loc}, q{temp_id} ), q{temp_id}, q{inputs used} );

$is_el_present = 1;
$text_loc = q{UK};
$title = q{Andy Brown - search.cpan.org};
$body_text = q{SETITESUK};
$is_text_present = 1;
ide_to_TWS_run_from_test_file( $sel, { test_file => q{1_test.html} } );
ide_to_TWS_run_from_suite_file( $sel, q{suite_file.html} );

done_testing();