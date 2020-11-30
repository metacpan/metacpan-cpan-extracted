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

    Gtk3::main_iteration_do(0) while Gtk3::events_pending or not $done;

    return $clear_result;
}

sub get_cookie_domains {
    my ($self) = @_;

    my $manager = $self->view->get_website_data_manager;

    my $result = undef;
    $manager->fetch('WEBKIT_WEBSITE_DATA_COOKIES', undef, sub {
        $result = $_[1];
    }, undef);

    Gtk3::main_iteration_do(0) while Gtk3::events_pending or not defined $result;

    my %cookie_domains;
    foreach (@{ $manager->fetch_finish($result) }) {
        $cookie_domains{$_->get_name} = 1;
    }

    return keys(%cookie_domains);
}

#FIXME is there really no good way to get *all* cookies from the cookiemanager? at least for a domain?
sub get_cookies_for_uri {
    my ($self, $uri) = @_;

    my $manager = $self->view->get_website_data_manager;
    my $cookie_manager = $manager->get_cookie_manager;

    my $result = undef;
    $cookie_manager->get_cookies($uri, undef, sub {
        $result = $_[1];

    }, undef);

    Gtk3::main_iteration_do(0) while Gtk3::events_pending or not defined $result;

    my $res = $cookie_manager->get_cookies_finish($result);

    my @cookies = ();

    foreach(@$res) {
        push(@cookies, {
                name        => $_->name,
                domain      => $_->domain,
                path        => $_->path,
                value       => $_->value,
                expires     => $_->expires,
                secure      => $_->secure,
                http_only   => $_->http_only,
        });
    }

    return \@cookies;
}

1;
