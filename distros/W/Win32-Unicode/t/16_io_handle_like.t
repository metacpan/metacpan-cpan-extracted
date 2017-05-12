use strict;
use warnings;
use utf8;
use lib 't/lib';
use Test::More;
use Test::Exception;
use Test::Win32::Unicode::Util;

use Win32::Unicode;

sub new_tmpfile {
    my $fh = Win32::Unicode::File->new(w => 'foo') or die $!;
    print $fh join q{}, map "$_\n" => qw/foo bar baz/;
    return $fh->file_path;
}

sub new_read_fh {
    my $file = new_tmpfile;
    my $fh = Win32::Unicode::File->new(r => $file) or die $!;
}

subtest getline => sub {
    safe_dir {
        my $fh = new_read_fh;

        dies_ok { $fh->getline('foo') };

        my $lines = [];
        while (my $line = $fh->getline) {
            push @$lines, $line;
        }
        is_deeply $lines, [ map "$_\n" => qw/foo bar baz/ ];
    };
};

subtest getlines => sub {
    safe_dir {
        my $fh = new_read_fh;

        dies_ok { $fh->getlines };
        dies_ok { $fh->getlines('foo') };

        my $lines = [ $fh->getlines ];
        is_deeply $lines, [ map "$_\n" => qw/foo bar baz/ ];
    };
};

subtest 'getops / setpos' => sub {
    safe_dir {
        my $fh = new_read_fh;

        dies_ok { $fh->getpos('foo') };
        dies_ok { $fh->setpos };

        is $fh->getpos, 0;
        is $fh->setpos(4), 4;
        is $fh->getpos, 4;
    }
};

subtest opened => sub {
    safe_dir {
        ok !Win32::Unicode::File->new->opened;
        ok new_read_fh->opened;
    };
};

done_testing;
