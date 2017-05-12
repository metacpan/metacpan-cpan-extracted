use strict;
use warnings;
use utf8;

package Ukigumo::Client::Notify::Growl;
use Growl::Any;
use Ukigumo::Helper qw(status_str);
use Ukigumo::Constants;

use Mouse;

has ignore_success => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 1,
);

has ignore_skip => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has _growl => (
    is   => 'ro',
    lazy => 1,
    default => sub {
        Growl::Any->new(
            appname => 'Ukigumo chan',
            events => ['test result']
        );
    },
);

no Mouse;

sub send {
    my ($self, $c, $status, $last_status, $report_url) = @_;

    if ( $self->ignore_success     &&
         $status eq STATUS_SUCCESS &&
         defined($last_status)     &&
         ($last_status eq STATUS_SUCCESS || $last_status eq STATUS_SKIP)
    ) {
        $c->logger->infof(
            "The test was succeeded. There is no reason to notify($status, $last_status).");
        return;
    }
    if ( $self->ignore_skip && $status eq STATUS_SKIP ) {
        $c->logger->infof( "The test was skiped. There is no reason to notify.");
        return;
    }

    my $icon_path = 'https://raw.github.com/ukigumo/Ukigumo-Server/master/static/img/';
       $icon_path .= $status == STATUS_SUCCESS ? 'ukigumo-chan.png' : 'ukigumo-chan-angry.png';

    $self->_growl->notify(
        'test result',
        'Test ' . status_str($status) .'!',
        $report_url,
        $icon_path,
    );
}

1;
