package MockUA;
use strict;
use warnings;
use Path::Tiny;
use HTTP::Response;

sub new {
    my ($class, %args) = @_;
    return bless {
        fixtures_dir => $args{fixtures_dir} // 't/fixtures',
    }, $class;
}

sub request {
    my ($self, $http_request) = @_;
    my $uri = $http_request->uri;

    my $fixture_file;

    # Single item/quest/enemy endpoints
    if ($uri =~ /\/items\/([^\/\?]+)/) {
        $fixture_file = "item-$1.json";
    } elsif ($uri =~ /\/quests\/([^\/\?]+)/) {
        $fixture_file = "quest-$1.json";
    } elsif ($uri =~ /\/arc-enemies\/([^\/\?]+)/) {
        $fixture_file = "arc-enemy-$1.json";
    }
    # Collection endpoints
    elsif ($uri =~ /\/items/) {
        $fixture_file = 'items.json';
    } elsif ($uri =~ /\/quests/) {
        $fixture_file = 'quests.json';
    } elsif ($uri =~ /\/arc-enemies/) {
        $fixture_file = 'arc-enemies.json';
    } else {
        return HTTP::Response->new(404, 'Not Found');
    }

    my $file = path($self->{fixtures_dir}, $fixture_file);

    unless ($file->is_file) {
        return HTTP::Response->new(404, 'Fixture not found: ' . $fixture_file);
    }

    my $content = $file->slurp_utf8;
    my $response = HTTP::Response->new(200, 'OK');
    $response->content($content);
    $response->header('Content-Type' => 'application/json');

    return $response;
}

1;
