package App::Grok::Common;
BEGIN {
  $App::Grok::Common::AUTHORITY = 'cpan:HINRIK';
}
{
  $App::Grok::Common::VERSION = '0.26';
}

use strict;
use warnings FATAL => 'all';
use File::HomeDir qw<my_data>;
use File::Spec::Functions qw<catdir>;

use base qw(Exporter);
our @EXPORT_OK = qw(download data_dir);
our %EXPORT_TAGS = ( ALL => [@EXPORT_OK] );

sub data_dir {
    my $data_dir = catdir(my_data(), '.grok');
    if (!-d $data_dir) {
        mkdir $data_dir or die "Can't create $data_dir: $!\n";
    }

    my $res_dir = catdir($data_dir, 'resources');
    if (!-d $res_dir) {
        mkdir $res_dir or die "Can't create $res_dir: $!\n";
    }

    return $data_dir;
}

sub download {
    my ($title, $url) = @_;

    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

    eval 'require Term::ProgressBar';
    if ($@) {
        print $title, "\n";
        my $response = $ua->get($url);
        if ($response->is_success) {
            return $response->decoded_content;
        }
        else {
            die 'Download failed: '.$response->status_line."\n";
        }
    }

    my $bar = Term::ProgressBar->new({
        name  => $title,
        count => 1024,
        ETA   => 'linear',
    });

    my $content;
    my $output        = 0;
    my $target_is_set = 0;
    my $next_so_far   = 0;
    $ua->get(
        $url,
        ":content_cb" => sub {
            my ($chunk, $response, $proto) = @_;

            if (!$target_is_set) {
                if (my $cl = $response->content_length) {
                    $bar->target($cl);
                    $target_is_set = 1;
                }
                else {
                    $bar->target($output + 2 * length $chunk);
                }
            }

            $output += length $chunk;
            $content .= $chunk;

            if ($output >= $next_so_far) {
                $next_so_far = $bar->update($output);
            }

            #$bar->target($output);
            #$bar->update($output);
        },
    );

    return $content;
}

1;

=encoding utf8

=head1 NAME

App::Grok::Common - Common functions used in grok

=head1 SYNOPSIS

 use strict;
 use warnings;
 use App::Grok::Common qw<:ALL>;

 # download a file, with a progress bar
 my $url = 'http://foo.bar/baz';
 my $content = download('My file', $url);

=head1 DESCRIPTION

This module provides common utility functions used in App::Grok.

=head1 FUNCTIONS

=head2 C<download>

Downloads a file from the web and returns the contents. Prints a progress bar
(if L<Term::ProgressBar|Term::ProgressBar> is installed) as while doing so.
It takes two arguments, a title string and the url. Returns the downloaded
content.

=head2 C<data_dir>

Creates (if necessary) and then returns the name of the directory where grok
stores its data (e.g. F<~/.grok>).

=cut
