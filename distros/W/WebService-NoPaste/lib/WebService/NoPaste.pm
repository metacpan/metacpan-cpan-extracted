package WebService::NoPaste;
use Spiffy 0.24 -Base;
use LWP::UserAgent;
use HTTP::Request::Common 'POST';
use IO::All;
use Clipboard;
our $VERSION = '0.03';

sub new {
    my %args = @_;
    bless {
        host => delete $args{host},
        post_path => delete $args{post_path},
        args => \%args,
    }, $self
}

sub send {
    my $text = shift;
    my $r = LWP::UserAgent->new->request(
        POST $self->{host} . $self->{post_path}, [
            %{$self->{args}},
            text => $text,
        ]);
    $self->response_die($r, "Didn't get a '302 Found'.") unless 302 == $r->code;
    my $p = $r->headers->header('Location');
    $p =~ s/\.html$// or $self->response_die($r, "Location looks strange: $p");
    $self->{payload_path} = $p;
}

sub payload_urls {
    map { $self->{host} . $self->{payload_path} . '.' . $_ } qw(txt html)
}

sub read_from_stdin {
    print "Paste at will...\n" if -t STDIN;
    io('-')->all
}

sub read_from_clipboard { Clipboard->paste }

sub save_to_clipboard { Clipboard->copy($_[0]); }

my $PLEASE_EMAIL = "WebService::NoPaste has only been tested with 'pastebot' brand paste servers, and even then only to a limited extent.  If you got this error unexpectedly, please let me know - rking\@panopic.com.";
sub response_die {
    my ($r, $reason) = @_;
    die join "\n", $reason, $PLEASE_EMAIL, "The response was: " .  $r->as_string
}

1;

=head1 NAME 

    WebService::NoPaste - Post to Paste Web Pages

=head1 SYNOPSIS

    # Manually paste input, manually copy the result url:
    $ nopaste

    # Turbo mode: use clipboard as input, send, and then put the result
    # URL back into the clipboard:
    $ nopaste cp

    # Just take the input from the clipboard, but otherwise leave the
    # clipboard alone:
    $ nopaste c

    # Instantly upload your passwd file for the whole world to see, but
    # at least you'll have the result URL conveniently in your
    # clipboard.
    $ nopaste p < /etc/passwd 

=head1 DESCRIPTION

    When online chatting it is problematic to paste an entire 300 line
    file.  Yes paste?  No.  NoPaste!

    Posting to a paste host is preferred.  These servers are just web
    forms that accept input from a big text field, and temporarily house
    them as web pages.

    This script/module is for those who find it tedious to switch to a
    web browser, load the page, and then paste.  Why use the mouse when
    you can use the keyboard? ;)

=head1 CONFIGURATION
    
    Currently, you just edit "nopaste" itself to point it at a different
    server, to change languages (which only affects the way the HTML
    formatting syntax highlights), etc.

    This is lame, I know.  But it's early.  If you'd like neater
    configuration, email me, and I'll get right to it.

=head1 AUTHOR

    Ryan King <rking@panoptic.com>

=head1 COPYRIGHT

    Copyright (c) 2005. Ryan King. All rights reserved.

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

    See http://www.perl.com/perl/misc/Artistic.html

=cut
# vi:tw=72
