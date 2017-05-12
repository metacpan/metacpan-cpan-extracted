#!/usr/bin/perl
use strict;
use warnings;
use lib qw/lib/;
use WebService::Bukget;
use Data::Dumper;

my $w = WebService::Bukget->new();
$w->geninfo({
    on_success => sub {
        my $d = shift;
        warn Dumper(shift);
    }, 
    on_failure => sub {
        warn Dumper([@_]);
    },
});
$w->plugins({
    params => { size => 2, start => 0, fields => [qw/slug plugin_name description authors logo versions.version versions.download versions.link versions.game_versions categories/] },
    on_success => sub {
        my $d = shift;
        warn Dumper(shift);
    }, 
    on_failure => sub {
        warn Dumper([@_]);
    },
});
$w->categories({
    on_success => sub {
        my $d = shift;
        warn Dumper(shift);
    }, 
    on_failure => sub {
        warn Dumper([@_]);
    },
});
$w->categories('Admin Tools' => {
    params => { fields => [qw/slug plugin_name categories server authors/] },
    on_success => sub {
        my $d = shift;
        warn Dumper(shift);
    }, 
    on_failure => sub {
        warn Dumper([@_]);
    },
});
$w->categories('bukkit' => 'Admin Tools' => {
    params => { fields => [qw/slug plugin_name categories server authors/] },
    on_success => sub {
        my $d = shift;
        warn Dumper(shift);
    }, 
    on_failure => sub {
        warn Dumper([@_]);
    },
});
$w->authors({
    on_success => sub {
        my $d = shift;
        warn Dumper(shift);
    }, 
    on_failure => sub {
        warn Dumper([@_]);
    },
});
$w->authors('md_5' => {
    params => { fields => [qw/slug plugin_name categories server authors/] },
    on_success => sub {
        my $d = shift;
        warn Dumper(shift);
    }, 
    on_failure => sub {
        warn Dumper([@_]);
    },
});
$w->authors('bukkit' => 'md_5' => {
    params => { fields => [qw/slug plugin_name categories server authors/] },
    on_success => sub {
        my $d = shift;
        warn Dumper(shift);
    }, 
    on_failure => sub {
        warn Dumper([@_]);
    },
});
