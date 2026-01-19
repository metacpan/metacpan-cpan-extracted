package WWW::Crawl::Chromium;

use strict;
use warnings;

use parent 'WWW::Crawl';

use Carp qw(croak);
use IPC::Run qw(start timeout);

our $VERSION = '0.5';
# $VERSION = eval $VERSION;

sub _fetch_page {
    my ($self, $url) = @_;

    my $chromium_path = $self->{'chromium_path'}
        || $self->{'chrome_path'}
        || $self->{'chromium'}
        || 'chromium';
    my $timeout = $self->{'chromium_timeout'} // 120;
    my $virtual_time_budget = $self->{'chromium_time_budget'} // 20000;
    my $proxy = $self->{'proxy'} // 'direct://';

    my $chrome_ua = $self->{'agent'} // "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36";
    my $retry_count = $self->{'retry_count'} // 0;
    
    my @base_command = (
        $chromium_path,
        '--headless=new',
        qq{--proxy-server=$proxy},
        qq{--user-agent=$chrome_ua},
        '--window-size=1920,1080',
        '--no-sandbox',
        '--disable-gpu',
        '--disable-dev-shm-usage',
        '--disable-software-rasterizer',
        '--disable-features=VaapiVideoDecoder',
        '--disable-site-isolation-trials',
        '--password-store=basic',
        '--use-mock-keychain',
        '--log-level=3',
        '--no-first-run',
        '--no-default-browser-check',
        '--run-all-compositor-stages-before-draw',
        "--virtual-time-budget=$virtual_time_budget",
        '--dump-dom',
        $url,
    );

    my $result;
    for my $attempt (0 .. $retry_count) {
        if ($attempt > 0) {
            print STDERR "DEBUG: Retry attempt $attempt for $url\n" if $self->{'debug'};
            sleep 1; 
        }
        
        $result = $self->_execute_chromium(\@base_command, $timeout);
        last if $result->{'success'};
    }
    
    return $result;
}

sub _execute_chromium {
    my ($self, $command, $timeout) = @_;
    my @command = @$command;

    my $content = '';
    my $error_output = '';
    my $timed_out = 0;
    my $launch_error = '';

    my $exit_code = 0;
    my $harness = eval {
        start \@command, '<', \undef, '>', \$content, '2>', \$error_output, timeout($timeout);
    };
    if ($@) {
        $launch_error = $@;
    } elsif (!$harness) {
        $launch_error = 'Unknown failure starting Chromium';
    } else {
        eval { $harness->finish; 1 };
        if ($@) {
            if ($@ =~ /timeout/i) {
                $timed_out = 1;
                $harness->kill_kill;
            } else {
                $launch_error = $@;
                $harness->kill_kill;
            }
        } else {
            $exit_code = $? >> 8;
            if ($exit_code != 0) {
                $launch_error = "Chromium exited with status $exit_code";
            }
        }
    }

    if ($timed_out) {
        return {
            'success' => 0,
            'status'  => 599,
            'reason'  => "Chromium timeout after ${timeout}s",
            'content' => '',
        };
    }

    if ($launch_error ne '') {
        $launch_error =~ s/\s+$//;
        my $reason = $error_output || $launch_error;
        return {
            'success' => 0,
            'status'  => 599,
            'reason'  => $reason,
            'content' => $content,
        };
    }

    if ($content eq '') {
        return {
            'success' => 0,
            'status'  => 599,
            'reason'  => 'Chromium returned empty content',
            'content' => '',
        };
    }

    return {
        'success' => 1,
        'status'  => 200,
        'reason'  => 'OK',
        'content' => $content,
    };
}

1;

__END__

=head1 NAME

WWW::Crawl::Chromium - Crawl JavaScript-rendered pages with Chromium

=head1 VERSION

This documentation refers to WWW::Crawl::Chromium version 0.5.

=head1 SYNOPSIS

    use WWW::Crawl::Chromium;

    my $crawler = WWW::Crawl::Chromium->new(
        chromium_path    => '/usr/bin/chromium',
        chromium_timeout => 30,
    );

    my @visited = $crawler->crawl('https://example.com', \&process_page);

    sub process_page {
        my $url = shift;
        print "Visited: $url\n";
    }

=head1 DESCRIPTION

C<WWW::Crawl::Chromium> reuses the crawling and link-parsing logic from
C<WWW::Crawl> but overrides page fetching to use a headless Chromium or
Chrome executable. The rendered DOM is collected via C<--dump-dom> after
the document is fully loaded.

=head1 OPTIONS

=over 4

=item *

C<chromium_path>: Full path to the Chromium or Chrome executable. Defaults to
C<chromium>.

=item *

C<chrome_path>: Alias for C<chromium_path>.

=item *

C<chromium_timeout>: Timeout in seconds for a single page fetch. Defaults to
30 seconds.

=item *

C<chromium_time_budget>: Virtual time budget in milliseconds for Chromium to
allow JavaScript to settle. Defaults to 10000.

=item *

C<proxy>: Proxy server to use (e.g. C<direct://> or C<http://proxy.example.com:8080>). Defaults to C<direct://>.

=item *

C<retry_count>: Number of times to retry Chromium fetches before giving up. Defaults to 0.

=item *

C<debug>: Enable debug logging to STDERR when set to a true value.

=back

=head1 METHODS

This module overrides the protected C<_fetch_page($url)> method from
C<WWW::Crawl> to return rendered HTML from Chromium. All crawling and parsing
is handled by the parent module.

=head1 AUTHOR

Ian Boddison, C<< <bod at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-crawl at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Crawl-Chromium>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Crawl::Chromium


You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/IanBod/WWW-Crawl>

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Crawl-Chromium>

=item * Search CPAN

L<https://metacpan.org/release/WWW-Crawl-Chromium>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023-2026 by Ian Boddison.

This program is released under the following license:

  Perl


=cut

1; # End of WWW::Crawl::Chromium
