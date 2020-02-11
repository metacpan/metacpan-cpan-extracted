package WWW::WebKit2::Cookies;

use Carp qw(carp croak);
use Glib qw(TRUE FALSE);
use Moose::Role;

=head3 clear_cookies

=cut

sub clear_cookies {
    my ($self) = @_;

    my $manager = $self->view->get_website_data_manager;

    my $done = 0;
    my $clear_result = '';

    $manager->clear('WEBKIT_WEBSITE_DATA_COOKIES', 0, undef, sub {
        my ($object, $result) = @_;
        $done = 1;
        $clear_result = $manager->clear_finish($result);
    }, undef);

    Gtk3::main_iteration while Gtk3::events_pending or not $done;

    return $clear_result;
}

1;
