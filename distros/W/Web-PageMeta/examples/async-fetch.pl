#!/usr/env perl

use strict;
use warnings;
use 5.010;
binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

use Web::PageMeta;
use Future::Utils qw( fmap_void );
use DDP;

# init color logging
use Log::Any qw($log);
use Log::Any::Adapter;
use Log::Log4perl;
Log::Log4perl->init(log4perl_config());
Log::Any::Adapter->set('Log4perl');

# array of urls to fetch
my @urls = qw(
    https://www.apa.at/
    http://www.diepresse.at/
    https://metacpan.org/
    https://nonexistingtest.meon.eu/
    https://github.com/
);

# main async loop with concurrency of 2
fmap_void(
    sub {
        my ($url) = @_;

        # prepare fetch Future for given url
        $log->info('Initiating fetch of ' . $url);
        my $wpm = Web::PageMeta->new(url => $url);
        return $wpm->fetch_image_data_ft->then(
            sub {
                # fetch successfully done
                $log->info('Fetched ' . $wpm->url . ':');
                p($wpm->page_meta);
            },
            sub {
                # fetch of page or image failed
                my ($err) = @_;
                $log->error('failed to fetch ' . $wpm->url . ': ' . np($err));
            }
        );
    },
    foreach    => [@urls],
    concurrent => 2
)->get;

sub log4perl_config {
    my $l4pc = <<'__CFG__';
log4perl.logger = DEBUG, ColorApp
log4perl.appender.ColorApp=Log::Log4perl::Appender::ScreenColoredLevels
log4perl.appender.ColorApp.layout = PatternLayout
log4perl.appender.ColorApp.layout.ConversionPattern=%d %m %n
__CFG__
    return \$l4pc;
}

__END__

=head1 NAME

async-fetch.pl - async example fetching pages open-graph information with concurrency of 2

=head1 SEE ALSO

Visit L<https://blog.kutej.net/2021/09/Web-PageMeta> for more info.

=cut
