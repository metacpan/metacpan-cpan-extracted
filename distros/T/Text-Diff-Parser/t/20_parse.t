#!/usr/bin/perl -w
# $Id: 20_parse.t 530 2009-09-09 10:26:49Z fil $
use strict;

use Test::More tests => 12;

use Text::Diff::Parser;


my $parser = Text::Diff::Parser->new( Verbose => 0 );

my @tests = (
    {   file => 't/std-more.diff',
        desc => "Standard diff, many files",
        result => [
            { filename1 => 'something', line1 => 2,
              filename2 => 'something.1', line2 => 1,
              size      => 2,
              type      => 'REMOVE'
            },

            { filename1 => 'something', line1 => 3,
              filename2 => 'something.2', line2 => 2,
              size      => 1,
              type      => 'REMOVE'
            },

            { filename1 => 'something', line1 => 1,
              filename2 => 'something.3', line2 => 2,
              size      => 1,
              type      => 'ADD'
            },
            { filename1 => 'something', line1 => 3,
              filename2 => 'something.3', line2 => 4,
              size      => 1,
              type      => 'REMOVE'
            },
            { filename1 => 'something', line1 => 4,
              filename2 => 'something.3', line2 => 4,
              size      => 1,
              type      => 'ADD'
            },

            { filename1 => 'something', line1 => 3,
              filename2 => 'something.4', line2 => 3,
              size      => 1,
              type      => 'REMOVE'
            },
            { filename1 => 'something', line1 => 4,
              filename2 => 'something.4', line2 => 3,
              size      => 1,
              type      => 'ADD'
            },
            { filename1 => 'something', line1 => 4,
              filename2 => 'something.4', line2 => 5,
              size      => 2,
              type      => 'ADD'
            },
        ],
    },

    {   file => 't/std-2.diff',
        desc => "Standard diff, 2 files",
        result => [
            { filename1 => '-r1.1.1.1', line1 => 8,
              filename2 => 'demo.pl', line2 => 8,
              size      => 1,
              type      => 'REMOVE'
            },
            { filename1 => '-r1.1.1.1', line1 => 9,
              filename2 => 'demo.pl', line2 => 8,
              size      => 1,
              type      => 'ADD'
            },

            { filename1 => '-r1.1.1.1', line1 => 12,
              filename2 => 'postback.pl', line2 => 12,
              size      => 1,
              type      => 'REMOVE'
            },
            { filename1 => '-r1.1.1.1', line1 => 13,
              filename2 => 'postback.pl', line2 => 12,
              size      => 1,
              type      => 'ADD'
            },
        ],
    },

    
    {   file => 't/easy.diff',
        result => [
            { filename1 => 'Makefile.PL', line1 => 60,
              filename2 => 'Makefile.PL', line2 => 60,
              size      => 3,
              type      => ''
            },
            { filename1 => 'Makefile.PL', line1 => 63,
              filename2 => 'Makefile.PL', line2 => 63,
              size      => 2,
              type      => 'REMOVE'
            },
            { filename1 => 'Makefile.PL', line1 => 65,
              filename2 => 'Makefile.PL', line2 => 63,
              size      => 3,
              type      => 'ADD'
            },
            { filename1 => 'Makefile.PL', line1 => 65,
              filename2 => 'Makefile.PL', line2 => 66,
              size      => 1,
              type      => ''
            },
            { filename1 => 'Makefile.PL', line1 => 66,
              filename2 => 'Makefile.PL', line2 => 67,
              size      => 1,
              type      => 'ADD'
            },
            { filename1 => 'Makefile.PL', line1 => 66,
              filename2 => 'Makefile.PL', line2 => 68,
              size      => 1,
              type      => 'REMOVE'
            },
            { filename1 => 'Makefile.PL', line1 => 67,
              filename2 => 'Makefile.PL', line2 => 68,
              size      => 3,
              type      => ''
            },
        ],
        desc   => "Unified diff,  Only one in file"
    },
    {   file => 't/double.diff',
        result => [
            { filename1 => 'Changes', line1 => 1,
              filename2 => 'Changes', line2 => 1,
              size      => 2,
              type      => ''
            },
            { filename1 => 'Changes', line1 => 3,
              filename2 => 'Changes', line2 => 3,
              size      => 9,
              type      => 'ADD'
            },
            { filename1 => 'Changes', line1 => 3,
              filename2 => 'Changes', line2 => 12,
              size      => 3,
              type      => ''
            },
            { filename1 => 'README', line1 => 21,
              filename2 => 'README', line2 => 21,
              size      => 3,
              type      => ''
            },
            { filename1 => 'README', line1 => 24,
              filename2 => 'README', line2 => 24,
              size      => 6,
              type      => 'ADD'
            },
            { filename1 => 'README', line1 => 24,
              filename2 => 'README', line2 => 30,
              size      => 3,
              type      => ''
            },
        ],
        desc   => "Unified diff,  2 in file"
    },
    {   file => 't/tripple.diff',
        desc => "Unified diff,  3 chunks",
        result => [
            # 0..2
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 1,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 1,
              size      => 3,
              type      => ''
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 4,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 4,
              size      => 2,
              type      => 'ADD'
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 4,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 6,
              size      => 3,
              type      => ''
            },

            # 3..9
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 161,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 140,
              size      => 3,
              type      => ''
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 164,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 143,
              size      => 1,
              type      => 'REMOVE'
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 165,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 143,
              size      => 1,
              type      => 'ADD'
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 165,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 144,
              size      => 5,
              type      => ''
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 170,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 149,
              size      => 2,
              type      => 'REMOVE'
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 172,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 149,
              size      => 2,
              type      => 'ADD'
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 172,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 151,
              size      => 3,
              type      => ''
            },

            # 10..15
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 281,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 260,
              size      => 3,
              type      => ''
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 284,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 263,
              size      => 1,
              type      => 'ADD'
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 284,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 264,
              size      => 4,
              type      => ''
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 288,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 268,
              size      => 1,
              type      => 'REMOVE'
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 289,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 268,
              size      => 1,
              type      => 'ADD'
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 289,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 269,
              size      => 1,
              type      => ''
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 290,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 270,
              size      => 1,
              type      => 'REMOVE'
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 291,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 270,
              size      => 1,
              type      => 'ADD'
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 291,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 271,
              size      => 3,
              type      => ''
            },
        ],

    },
    {   file => 't/one-line.diff',
        desc => "Unified diff, zero vs one line",
        result => [
            { filename1 => '/dev/null', line1 => 0,
              filename2 => 'one-line', line2 => 1,
              size      => 1,
              type      => 'ADD'
            },
        ],
    },
    {   file => 't/svn-one-line.diff',
        desc => "Unified diff, zero vs one line, from subversion",
        result => [
            { filename1 => 'local/CPAN/SVN-Web/branches/svn-client/lib/SVN/Web/I18N.pm', line1 => 0,
              filename2 => 'local/CPAN/SVN-Web/branches/svn-client/lib/SVN/Web/I18N.pm', line2 => 1,
              size      => 2,
              type      => 'ADD'
            },
        ],
    },
    {   file => 't/zero-line.diff',
        desc => "Unified diff, one line vs zero",
        result => [
            { filename1 => 'one-line', line1 => 1,
              filename2 => 'zero-line', line2 => 0,
              size      => 1,
              type      => 'REMOVE'
            },
        ],
    },
    {   file => 't/svn-zero-line.diff',
        desc => "Unified diff, one line vs zero, from subversion",
        result => [
            { filename1 => 't/svn-one-line.diff', line1 => 0,
              filename2 => 't/svn-one-line.diff', line2 => 1,
              size      => 7,
              type      => 'ADD'
            },
        ],
    },
    {   file => 't/kernel-sub.diff',
        desc => "Unified diff, no timestamps, function name, from kernel.org",
        result => [
            { filename1 => 'a/kernel/sys.c', line1 => 1983,
              filename2 => 'b/kernel/sys.c', line2 => 1983,
              size      => 3,
              function  => 'asmlinkage long sys_prctl(int option, uno',
              type      => ''
            },
            { filename1 => 'a/kernel/sys.c', line1 => 1986,
              filename2 => 'b/kernel/sys.c', line2 => 1986,
              size      => 1,
              function  => 'asmlinkage long sys_prctl(int option, uno',
              type      => 'REMOVE'
            },
            { filename1 => 'a/kernel/sys.c', line1 => 1987,
              filename2 => 'b/kernel/sys.c', line2 => 1986,
              size      => 1,
              function  => 'asmlinkage long sys_prctl(int option, uno',
              type      => 'ADD'
            },
            { filename1 => 'a/kernel/sys.c', line1 => 1987,
              filename2 => 'b/kernel/sys.c', line2 => 1987,
              size      => 3,
              type      => '',
              function  => 'asmlinkage long sys_prctl(int option, uno'
            },
        ],
    },
    {
        file => 't/mercurial.diff',
        desc => 'Unified diff from Mercurial, no diff file1 file2 line',
        result => [
            { filename1 => 'a/config.ini', line1 => 32,
              filename2 => 'b/config.ini', line2 => 32,
              size      => 3,
              function  => 'static_files =',
              type      => ''
            },
            { filename1 => 'a/config.ini', line1 => 35,
              filename2 => 'b/config.ini', line2 => 35,
              size      => 1,
              function  => 'static_files =',
              type      => 'REMOVE'
            },
            { filename1 => 'a/config.ini', line1 => 36,
              filename2 => 'b/config.ini', line2 => 35,
              size      => 1,
              function  => 'static_files =',
              type      => 'ADD'
            },
            { filename1 => 'a/config.ini', line1 => 36,
              filename2 => 'b/config.ini', line2 => 36,
              size      => 3,
              function  => 'static_files =',
              type      => ''
            },


            { filename1 => 'a/extensions/timelogs/timelog.py', line1 => 274,
              filename2 => 'b/extensions/timelogs/timelog.py', line2 => 274,
              size      => 3,
              function  => 'class Issue:',
              type      => ''
            },
            { filename1 => 'a/extensions/timelogs/timelog.py', line1 => 277,
              filename2 => 'b/extensions/timelogs/timelog.py', line2 => 277,
              size      => 1,
              function  => 'class Issue:',
              type      => 'REMOVE',
            },
            { filename1 => 'a/extensions/timelogs/timelog.py', line1 => 278,
              filename2 => 'b/extensions/timelogs/timelog.py', line2 => 277,
              size      => 1,
              function  => 'class Issue:',
              type      => 'ADD',
            },
            { filename1 => 'a/extensions/timelogs/timelog.py', line1 => 278,
              filename2 => 'b/extensions/timelogs/timelog.py', line2 => 278,
              size      => 3,
              function  => 'class Issue:',
              type      => ''
            },
            
            { filename1 => 'a/extensions/timelogs/timelog.py', line1 => 301,
              filename2 => 'b/extensions/timelogs/timelog.py', line2 => 301,
              size      => 3,
              function  => 'class Workpackage(Issue):',
              type      => ''
            },
            { filename1 => 'a/extensions/timelogs/timelog.py', line1 => 304,
              filename2 => 'b/extensions/timelogs/timelog.py', line2 => 304,
              size      => 1,
              function  => 'class Workpackage(Issue):',
              type      => 'REMOVE'
            },
            { filename1 => 'a/extensions/timelogs/timelog.py', line1 => 305,
              filename2 => 'b/extensions/timelogs/timelog.py', line2 => 304,
              size      => 1,
              function  => 'class Workpackage(Issue):',
              type      => 'ADD'
            },
            { filename1 => 'a/extensions/timelogs/timelog.py', line1 => 305,
              filename2 => 'b/extensions/timelogs/timelog.py', line2 => 305,
              size      => 3,
              function  => 'class Workpackage(Issue):',
              type      => ''
            },

            { filename1 => 'a/extensions/timelogs/timeloglist.py', line1 => 178,
              filename2 => 'b/extensions/timelogs/timeloglist.py', line2 => 178,
              size      => 3,
              function  => 'class TimelogList:',
              type      => ''
            },
            { filename1 => 'a/extensions/timelogs/timeloglist.py', line1 => 181,
              filename2 => 'b/extensions/timelogs/timeloglist.py', line2 => 181,
              size      => 1,
              function  => 'class TimelogList:',
              type      => 'ADD'
            },
            { filename1 => 'a/extensions/timelogs/timeloglist.py', line1 => 181,
              filename2 => 'b/extensions/timelogs/timeloglist.py', line2 => 182,
              size      => 3,
              function  => 'class TimelogList:',
              type      => ''
            },
            { filename1 => 'a/extensions/timelogs/timeloglist.py', line1 => 184,
              filename2 => 'b/extensions/timelogs/timeloglist.py', line2 => 185,
              size      => 1,
              function  => 'class TimelogList:',
              type      => 'ADD'
            },
            { filename1 => 'a/extensions/timelogs/timeloglist.py', line1 => 184,
              filename2 => 'b/extensions/timelogs/timeloglist.py', line2 => 186,
              size      => 3,
              function  => 'class TimelogList:',
              type      => ''
            },
            { filename1 => 'a/extensions/timelogs/timeloglist.py', line1 => 187,
              filename2 => 'b/extensions/timelogs/timeloglist.py', line2 => 189,
              size      => 1,
              function  => 'class TimelogList:',
              type      => 'ADD'
            },
            { filename1 => 'a/extensions/timelogs/timeloglist.py', line1 => 187,
              filename2 => 'b/extensions/timelogs/timeloglist.py', line2 => 190,
              size      => 4,
              function  => 'class TimelogList:',
              type      => ''
            },
            { filename1 => 'a/extensions/timelogs/timeloglist.py', line1 => 191,
              filename2 => 'b/extensions/timelogs/timeloglist.py', line2 => 194,
              size      => 3,
              function  => 'class TimelogList:',
              type      => 'ADD'
            },
            { filename1 => 'a/extensions/timelogs/timeloglist.py', line1 => 191,
              filename2 => 'b/extensions/timelogs/timeloglist.py', line2 => 197,
              size      => 3,
              function  => 'class TimelogList:',
              type      => ''
            },


            { filename1 => 'a/html/issue.item.html', line1 => 157,
              filename2 => 'b/html/issue.item.html', line2 => 157,
              size      => 3,
              function  => 'python:db.remote_event.classhelp(\'id,con',
              type      => ''
            },
            { filename1 => 'a/html/issue.item.html', line1 => 160,
              filename2 => 'b/html/issue.item.html', line2 => 160,
              size      => 1,
              function  => 'python:db.remote_event.classhelp(\'id,con',
              type      => 'REMOVE'
            },
            { filename1 => 'a/html/issue.item.html', line1 => 161,
              filename2 => 'b/html/issue.item.html', line2 => 160,
              size      => 1,
              function  => 'python:db.remote_event.classhelp(\'id,con',
              type      => 'ADD'
            },
            { filename1 => 'a/html/issue.item.html', line1 => 161,
              filename2 => 'b/html/issue.item.html', line2 => 161,
              size      => 3,
              function  => 'python:db.remote_event.classhelp(\'id,con',
              type      => ''
            },

        ],
    },
    {   file => 't/mysql.diff',
        desc => "Unified diff, remove a line with --",
        result => [
            { filename1 => 'oxi_room_counts.sql', line1 => 2,
              filename2 => 'oxi_room_counts.sql', line2 => 2,
              size      => 4,
              function  => '',
              type      => 'REMOVE'
            },
            { filename1 => 'oxi_room_counts.sql', line1 => 6,
              filename2 => 'oxi_room_counts.sql', line2 => 2,
              size      => 1,
              function  => '',
              type      => 'ADD'
            },
        ],
    }
);

foreach my $test ( @tests ) {
    if( $test->{file} ) {
        $parser->parse_file( $test->{file} );
    }
    else {
        die "HONK";
    }
    my $res = [$parser->changes];
#    use Data::Dumper;
    compare_changes($res, $test->{result}, $test->{desc} )
#            or die Dumper $res;
}


sub compare_changes
{
    my( $got, $expected, $text ) = @_;

    my $q1 = 0;
    foreach my $ch ( @$got ) {
        foreach my $f ( qw(filename1 line1 size filename2 line2 function) ) {
            my $v = $ch->can($f)->($ch);
            $v = '' unless defined $v;
            my $ex = $expected->[$q1]{$f};
            $ex = '' unless defined $ex;
            unless( $ex eq $v ) {
                my_fail( $text, $ch, $expected, $q1, $f, $v );
                use Data::Dumper;
                die Dumper $ch;
                return;
            }
        }
        my $v = $ch->type;
        unless( $expected->[$q1]{type} eq $v ) {
            my_fail( $text, $ch, $expected, $q1, 'type', $v );
            return;
        }
        $q1++;
    }
    pass( $text );
}

sub my_fail
{
    my( $text, $ch, $expected, $q1, $f, $v ) = @_;

    fail( $text );
    $expected->[$q1]{$f} ||= '';
    $v ||= '';
    diag ( "     \$got->[$q1]->$f = $v" );
    diag ( "\$expected->[$q1]{$f} = $expected->[$q1]{$f}" );
    # diag ( join "\n", $ch->text );
}
