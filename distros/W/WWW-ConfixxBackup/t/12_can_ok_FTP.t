#!/usr/bin/perl

use strict;
use warnings;
use B;
use Devel::Symdump;
use Test::More tests => 1;
use WWW::ConfixxBackup::FTP;

# if you change anything here, change it in 03_WWW_ConfixxBackup_FTP.t, too.
my %methods = (
    new       => 1,
    user      => 1,
    server    => 1,
    password  => 1,
    download  => 1,
    login     => 1,
    prefix    => 1,
    ftp       => 1,
    DESTROY   => 1,
    debug     => 1,
    DEBUG     => 1,
);

my %check;
my @all_subs = _get_subroutines();
@check{@all_subs} = (1) x @all_subs;

is_deeply \%check, \%methods;

sub _get_subroutines{
    my $pkg = 'WWW::ConfixxBackup::FTP';
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