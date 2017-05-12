#!/usr/bin/perl

use warnings 'FATAL' => 'all';
use strict;
use Test::More;
use WWW::AUR;

my $aur   = WWW::AUR->new;
my @found = $aur->search( 'perl' );

ok @found > 1, 'more than one perl package was found on the AUR';

my @VALID_FIELDS = qw{ id name version category desc url urlpath
                       license votes outdated };

my $pkg = $found[0];
ok ref $pkg eq 'WWW::AUR::Package';
for my $field ( @VALID_FIELDS ) {
    my $method = $WWW::AUR::Package::{ $field };
    ok $method, qq{package metod "$field" exists};
    eval { $method->( $pkg ) };
    ok !$@, qq{package accessor "$field" works};
}

sub wrong_match
{
    for my $pkg ( @_ ) {
        return 1 if $pkg->name !~ /\Aperl-/;
    }
    return 0;
}

@found = $aur->search( '^perl-' );
ok @found > 1, 'more than one perl-... package was found';
ok !wrong_match( @found ), 'anchored search returned all matching results';

done_testing();
