#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 8;

BEGIN { use_ok('XML::Entities::Data') }

sub are_funcnames;
sub each_in_all;
sub char2entity_sane;
sub str2ords;

my @names;
ok(@names = XML::Entities::Data::names, "Are any entity sets defined?");

ok(are_funcnames(@names), "Do names() contain real function names?");

is(ref XML::Entities::Data::all(), 'HASH', "Does all() return a hashref?");

no strict 'refs';
my $val1 = "XML::Entities::Data::$names[0]"->();
my $val2 = "XML::Entities::Data::$names[0]"->();
use strict;
cmp_ok($val1, '==', $val2, "Does caching work?");

ok(each_in_all(), "Is every set a subset of all?");

is(ref XML::Entities::Data::char2entity('all'), 'HASH', "Does char2entity return a hashref?");
ok(char2entity_sane(), "Does char2entity return a reverse mapping of all?");

sub are_funcnames {
    for (@_) {
        if (not XML::Entities::Data->can($_)) {
            diag("Function '$_' returned by names() but not defined.");
            return 0
        }
        no strict 'refs';
        my $rv = "XML::Entities::Data::$_"->();
        use strict;
        if (ref $rv ne 'HASH') {
            diag("Function $_ did not return a hashref but '$rv'");
            return 0
        }
    }
    return 1
}

sub each_in_all {
    my @names = XML::Entities::Data::names();
    my %all = %{ XML::Entities::Data::all() };
    for my $name (@names) {
        no strict 'refs';
        my $set = "XML::Entities::Data::$name"->();
        use strict 'refs';
        for my $ent (keys %$set) {
            if (not exists $all{ $ent }) {
                diag("entity '$ent' is defined in set '$name' but not in 'all'");
                return 0
            }
            elsif ($all{ $ent } ne $set->{ $ent }) {
                diag("Entity '$ent' has different definitions in '$name' ($$set{$ent}) and in all ($all{$ent}). OK but weird.");
            }
        }
    }
    return 1
}

sub char2entity_sane {
    my %all = %{ XML::Entities::Data::all() };
    my %c2e = %{ XML::Entities::Data::char2entity('all') };
    my @entnames = keys   %all;
    my @entchars = values %all;
    for my $i (0 .. $#entchars) {
        my $entchar = $entchars[$i];
        if (not exists $c2e{ $entchar }) {
            my $ords = str2ords($entchar);
            my $message = "char2entity doesn't map '$ords'"
            . " despite that all() maps '$entnames[$i]' onto it";
            diag($message);
            return 0
        }
        my $backmap = $c2e{ $entchar };
        $backmap =~ s/^&//;
        $backmap =~ s/;$//;
        if ($all{ $backmap } ne $entchar and $all{ "$backmap;" } ne $entchar) {
            my $ords = str2ords($entchar);
            diag("char2entity maps '$ords' onto '$backmap' but all() maps '$backmap' to '$all{$backmap.';'}'");
            return 0
        }
    }
    return 1
}

sub str2ords {
    my ($string) = @_;
    my @ords = map {'chr('.ord($_).')'} split //, $string;
    my $ords = join('-', @ords);
    return $ords
}
