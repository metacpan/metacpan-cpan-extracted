use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use Test::Mock::Guard qw(mock_guard);
use File::Temp qw/tempdir tempfile/;
use Win32::Unicode::File;
use Win32::Unicode::Dir;

my $dir = tempdir() or die $!;
my $write_file = File::Spec->catfile("$dir/森鷗外.txt");

ok my $fh = Win32::Unicode::File->new;
isa_ok $fh, 'Win32::Unicode::File';

sub newfh {
    Win32::Unicode::File->new(w => $write_file);
}

sub slurp {
    Win32::Unicode::File->new(r => shift)->slurp(binmode => 1);
}

{
    subtest 'OOish basic' => sub {
        my $fh = newfh();
        ok $fh->open(w => $write_file);
        ok $fh->binmode(':utf8');
        ok $fh->write('0123456789');
        ok $fh->seek(0, 2);
        is $fh->tell, 10;
        ok $fh->close;
        is slurp($write_file), '0123456789';
    };

    subtest 'OOish print' => sub {
        my $fh = newfh();
        ok $fh->open(w => $write_file);
        ok $fh->print(qw/foo bar/);
        ok $fh->seek(0, 2);
        is $fh->tell, 6;
        ok $fh->close;
        is slurp($write_file), 'foobar';
    };

    subtest 'OOish print (local $,)' => sub {
        my $fh = newfh();
        ok $fh->open(w => $write_file);
        local $, = '<>';
        ok $fh->print(qw/foo bar/);
        ok $fh->seek(0, 2);
        is $fh->tell, 8;
        ok $fh->close;
        is slurp($write_file), 'foo<>bar';
    };

    subtest 'OOish printf' => sub {
        my $fh = newfh();
        ok $fh->open(w => $write_file);
        ok $fh->printf('%02d', 1);
        ok $fh->seek(0, 2);
        is $fh->tell, 2;
        ok $fh->close;
        is slurp($write_file), '01';
    };

    subtest 'OOish say' => sub {
        my $fh = newfh();
        ok $fh->open(w => $write_file);
        ok $fh->say(qw/foo bar/);
        ok $fh->seek(0, 2);
        is $fh->tell, 8;
        ok $fh->close;
        is slurp($write_file), "foobar\r\n";
    };

    subtest 'OOish say (local $,)' => sub {
        my $fh = newfh();
        ok $fh->open(w => $write_file);
        local $, = '<>';
        ok $fh->say(qw/foo bar/);
        ok $fh->seek(0, 2);
        is $fh->tell, 10;
        ok $fh->close;
        is slurp($write_file), "foo<>bar\r\n";
    };

    subtest 'OOish say (binmode)' => sub {
        my $fh = newfh();
        ok $fh->open(w => $write_file);
        ok $fh->binmode(1);
        ok $fh->say(qw/foo bar/);
        ok $fh->seek(0, 2);
        is $fh->tell, 7;
        ok $fh->close;
        is slurp($write_file), "foobar\n";
    };

    subtest 'OOish flush' => sub {
        my $fh = newfh();
        ok $fh->open(w => $write_file);
        ok $fh->write('0123456789');
        ok $fh->flush;
        ok $fh->seek(0, 2);
        is $fh->tell, 10;
        ok $fh->close;
        is slurp($write_file), '0123456789';
    };

    subtest 'OOish autoflush' => sub {
        my $fh = newfh();
        my $guard = mock_guard($fh, {
            flush => 1,
        });
        ok $fh->open(w => $write_file);
        $fh->autoflush;
        ok $fh->write('0123456789');
        is $guard->call_count($fh, 'flush'), 1;
        ok $fh->seek(0, 2);
        is $fh->tell, 10;
        ok $fh->close;
        is slurp($write_file), '0123456789';
    };

    subtest 'OOish printflush' => sub {
        my $fh = newfh();
        ok $fh->open(w => $write_file);
        $fh->printflush('0123456789');
        ok $fh->seek(0, 2);
        is $fh->tell, 10;
        ok $fh->close;
        is slurp($write_file), '0123456789';
    };
};

{
    subtest 'tie basic' => sub {
        my $fh = newfh();
        ok open $fh, '>', $write_file;
        ok binmode $fh, ':utf8';
        ok print $fh '0123456789', 'ABCDEF';
        ok seek($fh, 0, 2);
        is tell $fh, 16;
        ok close $fh;
        is slurp($write_file), '0123456789ABCDEF';
    };

    subtest 'tie print (local $,)' => sub {
        my $fh = newfh();
        ok open $fh, '>', $write_file;
        local $, = '<>';
        ok print $fh '0123456789', 'ABCDEF';
        ok seek($fh, 0, 2);
        is tell $fh, 18;
        ok close $fh;
        is slurp($write_file), '0123456789<>ABCDEF';
    };

    subtest 'tie printf' => sub {
        my $fh = newfh();
        ok open $fh, '>', $write_file;
        ok printf $fh '%02d', '1';
        ok seek($fh, 0, 2);
        is tell $fh, 2;
        ok close $fh;
        is slurp($write_file), '01';
    };

    subtest 'tie say' => sub {
        my $fh = newfh();
        ok open $fh, '>', $write_file;
        ok say $fh qw/foo bar/;
        ok seek($fh, 0, 2);
        is tell $fh, 8;
        ok close $fh;
        is slurp($write_file), "foobar\r\n";
    };

    subtest 'tie say (local $,)' => sub {
        my $fh = newfh();
        ok open $fh, '>', $write_file;
        local $, = '<>';
        ok say $fh qw/foo bar/;
        ok seek($fh, 0, 2);
        is tell $fh, 10;
        ok close $fh;
        is slurp($write_file), "foo<>bar\r\n";
    };

    subtest 'tie say (binmode)' => sub {
        my $fh = newfh();
        ok open $fh, '>', $write_file;
        ok binmode $fh;
        ok say $fh qw/foo bar/;
        ok seek($fh, 0, 2);
        is tell $fh, 7;
        ok close $fh;
        is slurp($write_file), "foobar\n";
    };

    subtest 'tie flush' => sub {
        my $fh = newfh();
        ok open $fh, '>', $write_file;
        ok print $fh '0123456789';
        ok flush $fh;
        ok seek $fh, 0, 2;
        is tell $fh, 10;
        ok close $fh;
        is slurp($write_file), '0123456789';
    };

    subtest 'OOish autoflush' => sub {
        my $fh = newfh();
        my $guard = mock_guard($fh, {
            flush => 1,
        });
        ok $fh->open(w => $write_file);
        $fh->autoflush;
        ok $fh->write('0123456789');
        is $guard->call_count($fh, 'flush'), 1;
        ok $fh->seek(0, 2);
        is $fh->tell, 10;
        ok $fh->close;
        is slurp($write_file), '0123456789';
    };

    subtest 'OOish printflush' => sub {
        my $fh = newfh();
        ok $fh->open(w => $write_file);
        $fh->printflush('0123456789');
        ok $fh->seek(0, 2);
        is $fh->tell, 10;
        ok $fh->close;
        is slurp($write_file), '0123456789';
    };

    {
        plan skip_all => '$^V < 5.1000' if $^V < 5.0100;
        use if $^V < 5.1000, feature => 'say';

        subtest 'tie say (use feature)' => sub {
            my $fh = newfh();
            ok open $fh, '>', $write_file;
            ok say $fh qw/foo bar/;
            ok seek($fh, 0, 2);
            is tell $fh, 8;
            ok close $fh;
            is slurp($write_file), "foobar\r\n";
        };

       subtest 'tie say (use feature / local $,)' => sub {
            my $fh = newfh();
            ok open $fh, '>', $write_file;
            local $, = '<>';
            ok say $fh qw/foo bar/;
            ok seek($fh, 0, 2);
            is tell $fh, 10;
            ok close $fh;
            is slurp($write_file), "foo<>bar\r\n";
        };

        subtest 'tie say (use feature / binmode)' => sub {
            my $fh = newfh();
            ok open $fh, '>', $write_file;
            ok binmode $fh;
            ok say $fh qw/foo bar/;
            ok seek($fh, 0, 2);
            is tell $fh, 7;
            ok close $fh;
            is slurp($write_file), "foobar\n";
        };
    }
};

Win32::Unicode::Dir::rmtreeW($dir);

done_testing;
