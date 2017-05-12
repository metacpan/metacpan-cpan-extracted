#!perl -T

BEGIN {
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use threads;
use threads::variables::reap;
use Test::More;

INIT
{
    # for debugging
    1;
}

plan( tests => 1 );

sub runThreads(@)
{
    my @threads = @_;
    foreach my $thr (@threads)
    {
        threads->create($thr);
    }
    do
    {
        threads->yield();
        foreach my $thr ( threads->list(threads::joinable) )
        {
            $thr->join();
        }
    } while ( scalar( threads->list(threads::all) ) > 0 );
}

my %testStruct = (
                   s1 => 1,
                   s2 => 2,
                   a1 => [qw(Perl rocks)],
                   a2 => [qw(NetBSD is great)],
                   h1 => {
                           NetBSD => {
                                       add   => 'pkg_add',
                                       del   => 'pkg_delete',
                                       check => 'pkg_info',
                                     },
                           SunOS => {
                                      add   => 'pkgadd',
                                      del   => 'pkgdel',
                                      check => 'pkginfo',
                                    },
                           RPM_Linux => {
                                          add   => 'rpm --install',
                                          del   => 'rpm --erase',
                                          check => 'rpm -qa',
                                        },
                         },
                   h2 => {
                           users => [
                                      [ 'root', 'topsecret', 'wheel', '/bin/ksh',          '/root' ],
                                      [ 'sno',  'secret',    'staff', '/usr/pkg/bin/bash', '/home/sno' ],
                                    ],
                           tmpdirs => [qw(/tmp /var/tmp .)],
                         },
                 );
my %cmpStruct = (
                  s1 => 1,
                  s2 => undef,
                  a1 => undef,
                  a2 => [],
                  h1 => {
                          NetBSD => {
                                      add   => 'pkg_add',
                                      del   => 'pkg_delete',
                                      check => undef,
                                    },
                          SunOS     => {},
                          RPM_Linux => undef,
                        },
                  h2 => {
                          users => [
                                     [ 'root', undef, 'wheel', '/bin/ksh',          '/root' ],
                                     [ 'sno',  undef, 'staff', '/usr/pkg/bin/bash', '/home/sno' ],
                                   ],
                          tmpdirs => [],
                        },
                );

sub cmpThread
{
    is_deeply( \%testStruct, \%cmpStruct, 'Struct members reaped' );
}

reap( $testStruct{s2} );
reap( $testStruct{a1} );
reap( @{ $testStruct{a2} } );
reap( $testStruct{h1}{NetBSD}{check} );
reap( %{ $testStruct{h1}{SunOS} } );
reap( $testStruct{h1}{RPM_Linux} );
reap( $testStruct{h2}{users}[0][1] );
reap( $testStruct{h2}{users}[1][1] );
reap( @{ $testStruct{h2}{tmpdirs} } );

runThreads( \&cmpThread );

