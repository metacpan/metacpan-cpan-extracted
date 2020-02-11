package WWW::WebKit2;

=head1 NAME

WWW::WebKit2 - Perl extension for controlling an embedding WebKit2 engine

=head1 SYNOPSIS

    use WWW::WebKit2;

    my $webkit = WWW::WebKit2->new(xvfb => 1);
    $webkit->init;

    $webkit->open("http://www.google.com");
    $webkit->type("q", "hello world");
    $webkit->click("btnG");
    $webkit->wait_for_page_to_load(5000);
    print $webkit->get_title;

=head1 DESCRIPTION

WWW::WebKit2 is a drop-in replacement for WWW::Selenium using Gtk3::WebKit2
as browser instead of relying on an external Java server and an installed browser.

=head2 EXPORT

None by default.

=cut

use 5.10.0;
use Moose;

with 'WWW::WebKit2::Cookies';
with 'WWW::WebKit2::MouseInput';
with 'WWW::WebKit2::KeyboardInput';
with 'WWW::WebKit2::Events';
with 'WWW::WebKit2::Navigator';
with 'WWW::WebKit2::Inspector';
with 'WWW::WebKit2::Settings';

use lib 'lib';
use Gtk3;
use Gtk3::WebKit2;
use Gtk3::JavaScriptCore;
use Glib qw(TRUE FALSE);
use Time::HiRes qw(time usleep);
use X11::Xlib;
use Carp qw(carp croak);
use XSLoader;
use English '-no_match_vars';
use POSIX qw<F_SETFD F_GETFD FD_CLOEXEC>;

our $VERSION = '0.1';

use constant DOM_TYPE_ELEMENT => 1;
use constant ORDERED_NODE_SNAPSHOT_TYPE => 7;

=head2 PROPERTIES

=cut

has xvfb => (
    is  => 'ro',
    isa => 'Bool',
);

has view => (
    is        => 'ro',
    isa       => 'Gtk3::WebKit2::WebView',
    lazy      => 1,
    clearer   => 'clear_view',
    predicate => 'has_view',
    default   => sub {

        my $ctx = Gtk3::WebKit2::WebContext::get_default();
        my $view = Gtk3::WebKit2::WebView->new_with_context($ctx);

        return $view;
    },
);

has scrolled_view => (
    is        => 'ro',
    isa       => 'Gtk3::ScrolledWindow',
    lazy      => 1,
    clearer   => 'clear_scrolled_view',
    predicate => 'has_scrolled_view',
    default   => sub {
        Gtk3::ScrolledWindow->new;
    }
);

has window_width => (
    is      => 'ro',
    isa     => 'Int',
    default => 1600,
);

has window_height => (
    is      => 'ro',
    isa     => 'Int',
    default => 1200,
);

has window => (
    is        => 'ro',
    isa       => 'Gtk3::Window',
    lazy      => 1,
    clearer   => 'clear_window',
    predicate => 'has_window',
    default   => sub {
        my ($self) = @_;
        my $sw = $self->scrolled_view;
        $sw->add($self->view);

        my $win = Gtk3::Window->new;
        $win->set_title($self->window_title);
        $win->set_decorated(0);
        $win->set_default_size($self->window_width, $self->window_height);
        $win->signal_connect(delete_event => sub { Gtk3->main_quit });
        $win->add($sw);

        return $win;
    }
);

has window_title => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        return 'www_webkit_window_' . int(rand() * 100000);
    },
);

has alerts => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has confirmations => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has prompt_answers => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has confirm_answers => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has accept_confirm => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

has display => (
    is        => 'ro',
    isa       => 'X11::Xlib',
    lazy      => 1,
    clearer   => 'clear_display',
    predicate => 'has_display',
    default   => sub {
        my $display = X11::Xlib->new;
        return $display;
    },
);

has event_send_delay => (
    is  => 'rw',
    isa => 'Int',
    default => 5, # ms
);

=head3 console_messages

WWW::WebKit saves console messages in this array but still lets the default console handler
handle the message. I'm not sure if this is the best way to go but you should be able
to override this easily:

    use Glib qw(TRUE FALSE);
    $webkit->view->signal_connect('console-message' => sub {
        push @{ $webkit->console_messages }, $_[1];
        return TRUE;
    });

The TRUE return value prevents any further handlers from kicking in which in turn should
prevent any messages from getting printed.

=cut

has console_messages => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has print_requests => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has default_timeout => (
    is      => 'rw',
    isa     => 'Int',
    default => 30_000,
);

has modifiers => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {control => 0, 'shift' => 0} },
);

has pending_requests => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has load_status => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { '' },
);

has events => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        clear_events => 'clear',
        find_event   => 'first',
        add_event    => 'push',
    },
);

=head2 METHODS

=head3 init

Initializes WebKit2 and GTK3. Must be called before any of the other methods.

=cut

sub init {
    my ($self) = @_;

    $self->setup_xvfb if $self->xvfb;

    return $self->init_webkit;
}

sub init_webkit {
    my ($self) = @_;

    # connect to X server to keep it alive till we don't need it anymore
    $self->display;
    Gtk3::init;

    # https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget-event
    $self->view->signal_connect('event' => sub {
        my ($view, $event) = @_;

        return 0; # needs to return 0 to propagate event
    });

    # https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget-event-after
    $self->view->signal_connect('event-after' => sub {
        my ($view, $event) = @_;

        $self->add_event($event) if $self;

        return 0; # needs to return 0 to propagate event
    });

    $self->view->signal_connect('submit-form' => sub {
        return $self->handle_form_submission(@_);
    });

    $self->view->signal_connect('script-dialog' => sub {
        my ($dialog) = $_[1];
        my $message = $dialog->get_message;
        my $type = $dialog->get_dialog_type;

        if ($type eq 'confirm') {
            $self->process_confirmation_prompt($dialog, $message);
        }
        if ($type eq 'alert') {
            push @{ $self->alerts }, $message;
        }

        if ($type eq 'prompt') {
            my $answer = pop @{ $self->prompt_answers };
            $dialog->prompt_set_text($answer // '');
        }
        if ($type eq 'before-unload-confirm') {
            $self->process_confirmation_prompt($dialog, $message);
        }

        return TRUE;
    });

    $self->view->signal_connect('print' => sub {
        push @{ $self->print_requests }, $_[1];
        return TRUE;
    });

    $self->view->signal_connect('resource-load-started' => sub {
        return $self->handle_resource_request(@_);
    });

    $self->view->signal_connect('load-changed' => sub {
        my ($view, $load_event) = @_;
        $self->load_status($load_event);
    });

    $self->enable_file_access_from_file_urls;
    $self->enable_hardware_acceleration;

    $self->window->show_all;
    $self->process_events;

    $self->enable_developer_extras;

    return $self;
}

=head2 process_confirmation_prompt

=cut

sub process_confirmation_prompt {
    my ($self, $dialog, $message) = @_;

    push @{ $self->confirmations }, $message;

    $dialog->confirm_set_confirmed(
        @{ $self->confirm_answers }
            ? pop @{ $self->confirm_answers }
            : ($self->accept_confirm ? TRUE : FALSE)
    );

}


sub pending {
    my ($self) = @_;

    return scalar keys %{ $self->pending_requests };
}

sub process_events {
    my ($self) = @_;

    Gtk3::main_iteration while Gtk3::events_pending;
}

sub process_page_load {
    my ($self) = @_;

    Gtk3::main_iteration while Gtk3::events_pending or $self->is_loading;
}

sub is_loading {
    my ($self) = @_;

    return 1 if $self->view->is_loading;

    return 0;
}

sub handle_form_submission {
    my ($self, $view, $request) = @_;

    $request->submit;
}

sub handle_resource_request {
    my ($self, $view, $resource, $request) = @_;

    $self->pending_requests->{"$request"}++;

    $resource->signal_connect('finished' => sub {
        delete $self->pending_requests->{"$request"};
    });
    $resource->signal_connect('failed' => sub {
        # If someone decides not to wait_for_pending_requests, this signal is received
        # during global destruction with $self being undefined.
        delete $self->pending_requests->{"$request"} if defined $self;
    });
}

sub setup_xvfb {
    my ($self) = @_;

    # close STDERR to avoid Xvfb's noise
    open my $stderr, '>&', \*STDERR or die "Can't dup STDERR: $!";
    close STDERR;

    if (system('Xvfb -help') != 0) {
        open STDERR, '>&', $stderr;
        die 'Could not start Xvfb';
    }

    # restore STDERR
    open STDERR, '>&', $stderr or die "Can't open STDERR: $!";;

    pipe my $read, my $write;
    my $writefd = fileno $write;

    # prevent pipe FD from being closed on exec when starting Xvfb:
    $SYSTEM_FD_MAX = $writefd;
    my $flags = fcntl $write, F_GETFD, 0;
    $flags &= ~FD_CLOEXEC;
    fcntl $write, F_SETFD, $flags;

    open STDERR, '>', '/dev/null' or die "Cant' open STDERR: $!";

    my $screen_dimensions = join 'x', $self->window_width, $self->window_height, 24;
    system ("Xvfb -nolisten tcp -terminate -screen 0 $screen_dimensions -displayfd $writefd &");

    open STDERR, '>&', $stderr or die "Can't open STDERR: $!";

    # Xvfb prints the display number newline terminated to our pipe
    my $display = <$read>;
    chomp $display;

    $ENV{DISPLAY} = ":$display";

    return;
}

sub uninit {
    my ($self) = @_;

    if ($self->has_window) {
        $self->window->destroy if $self->window;
        $self->clear_window;
    }

    $self->clear_view;
    $self->clear_scrolled_view;
    $self->clear_display;
}

sub DESTROY {
    my ($self) = @_;

    $self->uninit;
}

1;

=head1 SEE ALSO

See L<WWW::Selenium> for API documentation.
See L<Test::WWW::WebKit> for a replacement for L<Test::WWW::Selenium>.
See L<Test::WWW::WebKit::Catalyst> for a replacement for L<Test::WWW::Selenium::Catalyst>.

The current development version can be found in the git repository at:
https://github.com/jscarty/WWW-WebKit2

=head1 AUTHOR

Jason Shaun Carty <jc@atikon.com>,
Philipp Voglhofer <pv@atikon.com>,$
Philipp A. Lehner <pl@atikon.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Jason Shaun Carty, Philipp Voglhofer and Philipp A. Lehner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
