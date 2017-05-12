#!/usr/bin/perl

use strict;
use warnings;
use B;
use Devel::Symdump;
use Test::More tests => 1;
use WWW::ConfixxBackup;

# if you change anything here, change it in 01_WWW_ConfixxBackup.t, too.
my %methods = (
    available_confixx_versions => 1,
    default_confixx_version    => 1,
    user              => 1,
    password          => 1,
    server            => 1,
    ftp_user          => 1,
    ftp_password      => 1,
    ftp_server        => 1,
    ftp_login         => 1,
    confixx_user      => 1,
    confixx_password  => 1,
    confixx_server    => 1,
    confixx_version   => 1,
    confixx_login     => 1,
    http_proxy        => 1,
    file_prefix       => 1,
    backup            => 1,
    download          => 1,
    backup_download   => 1,
    new               => 1,
    login             => 1,
    waiter            => 1,
    errstr            => 1,
    detect_version    => 1,
    debug             => 1,
    DEBUG             => 1,
);

my %check;
my @all_subs = _get_subroutines();
@check{@all_subs} = (1) x @all_subs;

is_deeply \%check, \%methods;

sub _get_subroutines{
    my $pkg = 'WWW::ConfixxBackup';
    my $test;
    
    $test ||= $pkg;    

    my $symdump = Devel::Symdump->new($pkg);

    my @symbols;
    for my $func ($symdump->functions ) {
        my $owner = _get_sub(\&{$func});
        $owner =~ s/^\*(.*)::.*?$/$1/;
        next if $owner ne $test;

        # check if it's on the whitelist
        $func =~ s/${pkg}:://;

        push @symbols, $func unless $func =~ /^_/;
    }
    
    return @symbols;
}

sub _get_sub {
    my ($svref) = @_;
    my $b_cv = B::svref_2object($svref);
    no strict 'refs';
    return *{ $b_cv->GV->STASH->NAME . "::" . $b_cv->GV->NAME };
}