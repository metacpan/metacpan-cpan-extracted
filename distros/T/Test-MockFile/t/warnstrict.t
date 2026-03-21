#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

use Test::MockFile qw< warnstrict >;

subtest(
    'is_strict_mode returns true in warnstrict mode' => sub {
        ok( Test::MockFile::is_strict_mode(), 'is_strict_mode() is true' );
    }
);

subtest(
    'is_warn_mode returns true in warnstrict mode' => sub {
        ok( Test::MockFile::is_warn_mode(), 'is_warn_mode() is true' );
    }
);

subtest(
    'accessing unmocked file warns instead of dying' => sub {
        my @w;
        local $SIG{__WARN__} = sub { push @w, $_[0] };
        my $exists = -e '/some/unmocked/file/warnstrict_test';
        is( scalar @w, 1, 'got one warning' );
        like(
            $w[0],
            qr/\Qstat\E.*unmocked.*strict mode/,
            'got warning about unmocked file access',
        );
    }
);

subtest(
    'accessing mocked file does not warn' => sub {
        my $file = Test::MockFile->file( '/warnstrict/mocked', 'content' );
        my @w;
        local $SIG{__WARN__} = sub { push @w, $_[0] };
        my $exists = -e '/warnstrict/mocked';
        is( \@w, [], 'no warnings for mocked file access' );
    }
);

subtest(
    'open on unmocked file warns instead of dying' => sub {
        my @w;
        local $SIG{__WARN__} = sub { push @w, $_[0] };
        open my $fh, '<', '/warnstrict/unmocked/open_test';
        is( scalar @w, 1, 'got one warning' );
        like(
            $w[0],
            qr/\Qopen\E.*unmocked.*strict mode/,
            'got warning about unmocked open',
        );
    }
);

subtest(
    'open on mocked file works normally' => sub {
        my $file = Test::MockFile->file( '/warnstrict/open_mocked', 'hello' );
        my @w;
        my $ok;
        local $SIG{__WARN__} = sub { push @w, $_[0] };
        $ok = open my $fh, '<', '/warnstrict/open_mocked';
        is( \@w, [], 'no warnings for mocked file open' );
        ok( $ok, 'open succeeded' );
    }
);

subtest(
    'multiple unmocked accesses all produce warnings' => sub {
        my @w;
        local $SIG{__WARN__} = sub { push @w, $_[0] };
        -e '/warnstrict/multi/a';
        -e '/warnstrict/multi/b';
        -e '/warnstrict/multi/c';
        is( scalar @w, 3, 'got 3 warnings for 3 unmocked accesses' );
    }
);

done_testing();
exit;
