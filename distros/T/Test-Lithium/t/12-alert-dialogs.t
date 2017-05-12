#!/usr/bin/perl

use strict;
use warnings;
use Test::Builder::Tester;
use t::common;


my $site = start_depends;

# Connect to the test site and click click on the popup button in the footer
# this will manually click on buttons and ensure visibility and invisibility
# It does not create generic functions to handle "popups"
start_webdriver sel_conf(site => $site);

maximize();

# set up variables to enable easier cross-browser testing;
my $ok = "ok";
my $nok = "not ok";
my $confirm_alert = "OK!";
my $cancel_alert = "Cancel!";
if (is_phantom) {
	note "Testing under phantomjs, ensuring oks are now not oks, as phantom doesn't support modals";
	$ok = $nok;
	$confirm_alert = $cancel_alert;
}

### NOTE: None of these test blocks can be converted to subtests, as that will interfere
###       with Test::Builder::Tester's testing of the tests.

{
	# Use default message on confirm_alert
	visit "/";
	is(text("p#ok_cancel"), "", "No alert confirm/cancel state at initialization");
	click "button.popup.confirm";
	test_out "$ok 1 - Confirming alertbox";
	confirm_alert;
	test_test name => "Default test name for confirm_alert comes through",
		skip_err => 1;
	is(text("p#ok_cancel"), $confirm_alert, "Confirm state shown after confirming");

	# Now with custom message for confirm_alert
	visit "/";
	is(text("p#ok_cancel"), "", "No alert confirm/cancel state at initialization");
	click "button.popup.confirm";
	test_out "$ok 1 - I can confirm";
	confirm_alert "I can confirm";
	test_test name => "Test name for confirm_alert is correctly overridden",
		skip_err => 1;
	is(text("p#ok_cancel"), $confirm_alert, "Confirm state shown after confirming");

	# Make sure confirming with lack of alert dialog works
	visit "/";
	is(text("p#ok_cancel"), "", "No alert confirm/cancel state at initialization");
	test_out "$nok 1 - There is no alert to confirm";
	test_fail(+1);
	confirm_alert "There is no alert to confirm";
	test_test name => "Properly failed the confirm_alert test if no alert available",
		skip_err => 1;
	is(text("p#ok_cancel"), "", "No alert confirm/cancel state after testing");
}

{
	# Use default message on cancel_alert
	visit "/";
	is(text("p#ok_cancel"), "", "No alert confirm/cancel state at initialization");
	click "button.popup.confirm";
	test_out "$ok 1 - Canceling alertbox";
	cancel_alert;
	test_test name => "Default test name for cancel_alert comes through",
		skip_err => 1;
	is(text("p#ok_cancel"), $cancel_alert, "Cancel state shown after canceling");

	# Now with custom message for cancel_alert
	visit "/";
	is(text("p#ok_cancel"), "", "No alert confirm/cancel state at initialization");
	click "button.popup.confirm";
	test_out "$ok 1 - I can cancel";
	cancel_alert "I can cancel";
	test_test name => "Test name for cancel_alert is correctly overridden",
		skip_err => 1;
	is(text("p#ok_cancel"), $cancel_alert, "Cancel state shown after canceling");

	# Make sure confirming with lack of alert dialog works
	visit "/";
	is(text("p#ok_cancel"), "", "No alert confirm/cancel state at initialization");
	test_out "$nok 1 - There is no alert to cancel";
	test_fail +1;
	confirm_alert "There is no alert to cancel";
	test_test name => "Properly failed the cancel_alert test if no alert available",
		skip_err => 1;
	is(text("p#ok_cancel"), "", "No alert confirm/cancel state after testing");
}

{
	# Default message for alert_text
	my $expect = is_phantom() ? undef : "I am an alert box!";
	visit "/";
	click "button.popup";
	test_out "$ok 1 - Retrieving alert text";
	my $txt = alert_text();
	test_test name => "Default Test Name for alert_text comes through",
		skip_err => 1;
	is $txt, $expect, "Alert text returns correct content";

	# now with custom message for alert_text
	test_out "$ok 1 - Custom alert msg";
	alert_text("Custom alert msg");
	test_test name => "Test Name for alert_text is correctly overridden",
		skip_err => 1;
	test_out "$ok 1 - Confirm popup";
	confirm_alert "Confirm popup";
	test_test name => "Closing alert",
		skip_err =>1;

	# Make sure alert_text fails on lack of alert dialog
	visit "/";
	test_out "$nok 1 - Retrieving alert text";
	test_fail +1;
	alert_text;
	test_test name => "Properly failed the alert_text call if no alert available",
		skip_err => 1;
}

{
	# Default message for type_alert
	my $expect = is_phantom() ? "" : "Hello first_name! How are you today?";
	visit "/";
	is text('p#popup_input'), "",
		"type_alert feedback text is empty on test initialization";
	click "button.popup.input";
	test_out "$ok 1 - Setting alert text", "$ok 2 - Confirming alertbox";
	type_alert "first_name";
	confirm_alert;
	test_test name => "Default Test Name for type_alert comes through",
		skip_err => 1;
	is text('p#popup_input'), $expect,
		"type_alert input was handled correctly";

	# Custom message for type_alert
	$expect = is_phantom() ? "" : "Hello second_name! How are you today?";
	visit "/";
	is text('p#popup_input'), "",
		"type_alert feedback text is empty on test initialization";
	click "button.popup.input";
	test_out "$ok 1 - Cutom type message", "$ok 2 - Confirming alertbox";
	type_alert "second_name", "Cutom type message";
	confirm_alert;
	test_test name => "Test Name for type_alert is correctly overridden",
		skip_err => 1;
	is text('p#popup_input'), $expect,
		"type_alert input was handled correctly with custom message";

	# pass undef into type_alert
	$expect = is_phantom() ? "" : "Hello ! How are you today?";
	visit "/";
	is text('p#popup_input'), "",
		"type_alert feedback text is empty on test initialization";
	click "button.popup.input";
	test_out "$ok 1 - Setting alert text", "$ok 2 - Confirming alertbox";
	type_alert;
	confirm_alert;
	test_test name => "type_alert handles undef input",
		skip_err => 1;
	is text('p#popup_input'), $expect,
		"type_alert with undef input sets properly";

	# pass empty string into type_alert
	visit "/";
	is text('p#popup_input'), "",
		"type_alert feedback text is empty on test initialization";
	click "button.popup.input";
	test_out "$ok 1 - Setting alert text", "$ok 2 - Confirming alertbox";
	type_alert "";
	confirm_alert;
	test_test name => "type_alert handles empty string input",
		skip_err => 1;
	is text('p#popup_input'), $expect,
		"type_alert with empty string sets properly";

	visit "/";
	is text('p#popup_input'), "",
		"type_alert feedback text is empty on test initialization";
	test_out "$nok 1 - Setting alert text";
	test_fail +1;
	type_alert "fail";
	test_test name => "type_alert properly failed when no alert dialog was present",
		skip_err => 1;
	is text('p#popup_input'), "",
		"type_alert feedback text is empty after testing";
}

stop_depends;
done_testing;
