use strict;
use warnings;
use utf8;

package Ukigumo::Client::Notify::Debug;
use Mouse;
use Ukigumo::Helper qw(status_str);

sub send {
    my ($self, $c, $status, $last_status, $report_url) = @_;
    $c->logger->infof("STATUS IS '@{[ status_str $status ]}' '$report_url'");
}

1;

