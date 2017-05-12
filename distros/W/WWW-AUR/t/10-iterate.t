#!/usr/bin/perl

use warnings 'FATAL' => 'all';
use strict;
use Test::More;

diag 'Iterating through 100 package names';

use WWW::AUR::Iterator;
my $iter = WWW::AUR::Iterator->new;

my ( $i, @found ) = 0;
while ( $i < 100 && ( my $pkg = $iter->next )) {
    push @found, $pkg->{'name'};
    ++$i;
}

is scalar @found, 100, 'We iterated through 100 packages';

sub check_pkgobjs
{
    my ($pkgnames_ref) = @_;

    diag q{Iterating through 100 package objects (slower)};

    my $iter = WWW::AUR::Iterator->new;
    while ( @$pkgnames_ref ) {
        my $pkgname = shift @$pkgnames_ref;
        my $pkg     = $iter->next_obj;
        return 0 unless $pkg->name eq $pkgname;
    }
    return 1;
}

ok check_pkgobjs( \@found ), 'Package names and package objects match';

my $end = WWW::AUR::Iterator->new;
$end->{'curridx'} = 100_000;
ok ! defined $end->next, 'Iterator stops after reaching the end';

my $indexed = WWW::AUR::Iterator->new;
$indexed->set_pos( 10_000 );
my $pkg = $indexed->next;

# More specific test would be nice but I'm not sure what...
ok( ( lc substr $pkg->{'name'}, 0, 1 ) gt 'a' );

done_testing;
