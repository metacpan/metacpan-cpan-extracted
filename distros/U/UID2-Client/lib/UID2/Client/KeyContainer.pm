package UID2::Client::KeyContainer;
use strict;
use warnings;

use List::MoreUtils qw(upper_bound);
use UID2::Client::Timestamp;

sub new {
    my ($class, @keys) = @_;
    my $latest_expires = 0;
    my (%keys, %keys_by_site);
    for my $key (@keys) {
        $keys{$key->id} = $key;
        if ($key->site_id > 0) {
            push @{$keys_by_site{$key->site_id} //= []}, $key;
        }
        if (!$latest_expires or $key->expires > $latest_expires) {
            $latest_expires = $key->expires;
        }
    }
    while (my ($site_id, $keys) = each %keys_by_site) {
        $keys_by_site{$site_id} = [sort { $a->activates <=> $b->activates } @$keys];
    }
    bless {
        keys => \%keys,
        keys_by_site => \%keys_by_site,
        latest_expires => $latest_expires,
    }, $class;
}

sub get {
    my ($self, $id) = @_;
    $self->{keys}->{$id};
}

sub is_valid {
    my ($self, $now) = @_;
    $now //= UID2::Client::Timestamp->now;
    $self->{latest_expires} > $now->get_epoch_second;
}

sub get_active_site_key {
    my ($self, $site_id, $now) = @_;
    my $keys = $self->{keys_by_site}->{$site_id} or return;
    $now //= UID2::Client::Timestamp->now;
    my $second = $now->get_epoch_second;
    my $i = upper_bound { $_->activates <=> $second } @$keys;
    while ($i > 0) {
        $i--;
        return $keys->[$i] if $keys->[$i]->is_active($now);
    }
    return;
}

1;
__END__
