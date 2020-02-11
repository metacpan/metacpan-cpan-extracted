package WWW::WebKit2::Settings;

use Carp qw(carp croak);
use Glib qw(TRUE FALSE);
use Moose::Role;

=head3 enable_file_access_from_file_urls

=cut

sub enable_file_access_from_file_urls {
    my ($self) = @_;

    my $settings = $self->settings;
    $settings->set_allow_file_access_from_file_urls(TRUE);
    $settings->set_allow_universal_access_from_file_urls(TRUE);
    return $self->save_settings($settings);
}

=head3 enable_console_log

=cut

sub enable_console_log {
    my ($self) = @_;

    my $settings = $self->settings;
    $settings->set_enable_write_console_messages_to_stdout(TRUE);
    return $self->save_settings($settings);
}

=head3 enable_developer_extras

=cut

sub enable_developer_extras {
    my ($self) = @_;

    my $settings = $self->settings;
    $settings->set_enable_developer_extras(TRUE);
    return $self->save_settings($settings);
}

=head3 enable_hardware_acceleration

=cut

sub enable_hardware_acceleration {
    my ($self) = @_;

    my $settings = $self->settings;
    $settings->set_hardware_acceleration_policy("WEBKIT_HARDWARE_ACCELERATION_POLICY_ALWAYS");
    return $self->save_settings($settings);
}

=head3 disable_plugins()

Disables WebKit plugins. Use this if you don't need plugins like Java and Flash
and want to for example silence plugin loading messages.

=cut

sub disable_plugins {
    my ($self) = @_;

    my $settings = $self->settings;
    $settings->set_enable_plugins(FALSE);
    return $self->save_settings($settings);
}

=head3 enable_plugins()

=cut

sub enable_plugins {
    my ($self) = @_;

    my $settings = $self->settings;
    $settings->set_enable_plugins(TRUE);
    return $self->save_settings($settings);
}

=head3 settings

=cut

sub settings {
    my ($self) = @_;

    return $self->view->get_settings;
}

=head3 save_settings

=cut

sub save_settings {
    my ($self, $settings) = @_;

    $self->view->set_settings($settings);
    return 1;
}

1;
