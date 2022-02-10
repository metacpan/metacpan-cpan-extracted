package Test::WWW::WebKit2;

=head1 NAME

Test::WWW::WebKit2 - Perl extension for using an embedding WebKit2 engine for tests

=head1 SYNOPSIS

    use Test::WWW::WebKit2;

    my $webkit = Test::WWW::WebKit2->new(xvfb => 1);
    $webkit->init;

    $webkit->open_ok("http://www.google.com");
    $webkit->type_ok("q", "hello world");
    $webkit->click_ok("btnG");
    $webkit->wait_for_page_to_load_ok(5000);
    $webkit->title_is("foo");

=head1 DESCRIPTION

Test::WWW::WebKit2 is a drop-in replacement for Test::WWW::Selenium using Gtk3::WebKit2 as browser instead of relying on an external Java server and an installed browser.

=head2 EXPORT

None by default.

=cut

use 5.10.0;
use Moose;

extends 'WWW::WebKit2' => { -version => 0.126 };

use Glib qw(TRUE FALSE);
use Time::HiRes qw(time usleep);
use Test::More;

has 'debug' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

our $VERSION = '0.113';

sub shout {
    my ($self, $error) = @_;

    diag($error);

    if ($self->debug) {

        diag($self->resolve_locator('css=body')->get_inner_html);
        diag(Data::Dumper::Dumper($self->pending_requests));
    }

    return $self;
}

sub open_ok {
    my ($self, $url, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->open($url);

    ok(1, "open_ok($url, $description)");
}

sub refresh_ok {
    my ($self, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->refresh;
    ok(1, "refresh_ok($description)");
}

sub go_back_ok {
    my ($self, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->go_back;
    ok(1, "go_back_ok($description)");
}

sub select_ok {
    my ($self, $select, $option, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ok(eval { $self->select($select, $option) }, "select_ok($select, $option, $description)")
        or $self->shout($@);
}

sub click_ok {
    my ($self, $locator, $timeout, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $timeout ||= 0;

    my $result = eval { $self->click($locator, $timeout) };

    my $retval = ok($result, "click_ok($locator, $timeout, $description)")
        or $self->shout($@);

    return $retval;
}

sub click_and_wait_ok {
    my ($self, $locator, $timeout, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $timeout ||= $self->default_timeout;

    my $result = eval { $self->click_and_wait($locator, $timeout) };

    my $retval = ok($result, "click_and_wait_ok($locator, $timeout, $description)")
        or $self->shout($@);

    return $retval;
}

sub wait_for_page_to_load_ok {
    my ($self, $timeout, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->wait_for_page_to_load($timeout);
}

sub wait_for_element_present_ok {
    my ($self, $locator, $timeout, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $timeout ||= $self->default_timeout;

    my $result = eval { $self->wait_for_element_present($locator, $timeout) };

    my $retval = ok($result, "wait_for_element_present_ok($locator, $timeout, $description)")
        or $self->shout($@);

    return $retval;
}

sub wait_for_element_to_disappear_ok {
    my ($self, $locator, $timeout, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $timeout ||= $self->default_timeout;

    my $result = eval { $self->wait_for_element_to_disappear($locator, $timeout) };

    my $retval = ok($result, "wait_for_element_to_disappear_ok($locator, $timeout, $description)")
        or $self->shout($@);

    return $retval;
}

sub wait_for_condition_ok {
    my ($self, $condition, $timeout, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $result = eval { $self->wait_for_condition($condition, $timeout) };

    my $retval = ok($result, "wait_for_condition($description)")
        or $self->shout($@);

    return $retval;
}

sub wait_for_pending_requests_ok {
    my ($self, $timeout, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $result = eval { $self->wait_for_pending_requests($timeout) };

    my $retval = ok($result, "wait_for_pending_requests($description)")
        or $self->shout($@);

    return $retval;
}

sub prepare_async_page_load_ok {
    my ($self, $variable_name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->prepare_async_page_load($variable_name);
}

sub wait_for_async_page_load_ok {
    my ($self, $timeout, $variable_name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->wait_for_async_page_load($timeout, $variable_name);
}

sub is_element_present_ok {
    my ($self, $locator, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $result = eval { $self->is_element_present($locator) };

    my $retval = ok($result, "is_element_present_ok($locator, $description)")
        or $self->shout($@);

    return $retval;
}

sub type_ok {
    my ($self, $locator, $text, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ok(eval { $self->type($locator, $text) }, "type_ok($locator, $text, $description)")
        or $self->shout($@);
}

sub type_keys_ok {
    my ($self, $locator, $text, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ok(eval { $self->type_keys($locator, $text) }, "type_keys_ok($locator, $text, $description)")
        or $self->shout($@);
}

sub control_key_down_ok {
    my ($self, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->control_key_down;
    ok(1, "control_key_down_ok($description)");
}

sub control_key_up_ok {
    my ($self, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->control_key_up;
    ok(1, "control_key_up_ok($description)");
}

sub is_ordered_ok {
    my ($self, $first, $second, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $result = eval { $self->is_ordered($first, $second) };

    my $retval = ok($result, "is_ordered_ok($first, $second, $description)")
        or $self->shout($@);

    return $retval;
}

sub mouse_over_ok {
    my ($self, $locator, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ok(eval { $self->mouse_over($locator) }, "mouse_over_ok($locator, $description)")
        or $self->shout($@);
}

sub mouse_down_ok {
    my ($self, $locator, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ok(eval { $self->mouse_down($locator) }, "mouse_down_ok($locator, $description)")
        or $self->shout($@);
}

sub fire_event_ok {
    my ($self, $locator, $event_type, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ok(eval { $self->fire_event($locator, $event_type) }, "fire_event_ok($locator, $event_type, $description)")
        or $self->shout($@);
}

sub text_is {
    my ($self, $locator, $text, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $result = eval { $self->get_text($locator) };

    my $retval = is($result, $text, "text_is($locator, $text, $description, $description)")
        or $self->shout($@);

    return $retval;
}

sub text_like {
    my ($self, $locator, $text, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    like(eval { $self->get_text($locator) }, $text, "test_like($text, $description)")
        or $self->shout($@);
}

sub body_text_like {
    my ($self, $text, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    like(eval { $self->get_body_text() }, $text, "body_text_like($text, $description)")
        or $self->shout($@);
}

sub value_is {
    my ($self, $locator, $value, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    is(eval { $self->get_value($locator) }, $value, "value_is($locator, $value, $description)")
        or $self->shout($@);
}

sub title_like {
    my ($self, $text, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    like(eval { $self->get_title }, $text, "title_like($text, $description)")
        or $self->shout($@);
}

sub is_visible_ok {
    my ($self, $locator, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ok(eval { $self->is_visible($locator) }, "is_visible($locator, $description)")
        or $self->shout($@);
}

sub attribute_like {
    my ($self, $locator, $expr, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    like(eval { $self->get_attribute($locator) }, $expr, "attribute_like($locator, $expr, $description)")
        or $self->shout($@);
}

sub attribute_unlike {
    my ($self, $locator, $expr, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    unlike(eval { $self->get_attribute($locator) }, $expr, "attribute_unlike($locator, $expr, $description)")
        or $self->shout($@);
}

sub submit_ok {
    my ($self, $locator, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ok(eval { $self->submit($locator) }, "submit_ok($locator, $description)")
        or $self->shout($@);
}

sub eval_is {
    my ($self, $js, $expr, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    is(eval { $self->eval_js($js) }, $expr, "eval_is($expr, $description)")
        or $self->shout($@);
}

sub check_ok {
    my ($self, $locator, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ok(eval { $self->check($locator) }, "check_ok($locator, $description)")
        or $self->shout($@);
}

sub uncheck_ok {
    my ($self, $locator, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ok(eval { $self->uncheck($locator) }, "uncheck_ok($locator, $description)")
        or $self->shout($@);
}

sub print_requested_ok {
    my ($self, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ok(eval { $self->print_requested }, "print_requested_ok($description)")
        or $self->shout($@);
}

=head2 Additions to the Selenium API

=head3 wait_for_alert_ok($text, $timeout)

Wait for an alert with the given text to happen.
If $text is undef, it waits for any alert. Since alerts do not get automatically cleared, this has to be done manually before causing the action that is supposed to throw a new alert:

    $webkit->alerts([]);
    $webkit->click('...');
    $webkit->wait_for_alert;

=cut

sub wait_for_alert_ok {
    my ($self, $text, $timeout, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $timeout ||= $self->default_timeout;

    ok($self->wait_for_alert($text, $timeout), "wait_for_alert_ok($text, $timeout, $description)")
        or diag(
            @{ $self->alerts }
            ? 'Last alert was: "' . $self->alerts->[-1] . '"'
            : 'No alert occured'
        );
}

=head3 native_drag_and_drop_to_position_ok($source, $target_x, $target_y, $options)

Drag and drop $source to position ($target_x and $target_y)

=cut

sub native_drag_and_drop_to_position_ok {
    my ($self, $source, $target_x, $target_y, $options, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    eval { $self->native_drag_and_drop_to_position($source, $target_x, $target_y, $options) };

    ok($@ eq '', "native_drag_and_drop_to_position_ok($source, $target_x, $target_y, $description)")
        or $self->shout($@);
}

=head3 native_drag_and_drop_to_object_ok($source, $target, $options)

Drag and drop $source to $target.

=cut

sub native_drag_and_drop_to_object_ok {
    my ($self, $source, $target, $options, $description) = @_;
    $description //= '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    eval { $self->native_drag_and_drop_to_object($source, $target, $options) };

    ok($@ eq '', "native_drag_and_drop_to_object_ok($source, $target, $description)")
        or $self->shout($@);
}

1;

=head1 SEE ALSO

L<WWW::Selenium> for the base package.
See L<Test::WWW::Selenium> for API documentation.
L<Test::WWW::WebKit::Catalyst> for a replacement for L<Test::WWW::Selenium::Catalyst>

=head1 AUTHOR

Jason Shaun Carty <jc@atikon.com>,
Philipp Voglhofer <pv@atikon.com>,
Philipp A. Lehner <pl@atikon.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Jason Shaun Carty, Philipp Voglhofer and Philipp A. Lehner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
