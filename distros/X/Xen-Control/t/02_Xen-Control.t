#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 15;
use Test::Differences;
use Test::Environment 'Dump';

use Xen::Domain;

my @xm_output;
my @xm_cmds;

BEGIN {
    use_ok ( 'Xen::Control' ) or exit;
}

exit main();

sub main {
    my $xen = Xen::Control->new(
        'rm_cmd' => 'echo',
    );
    
    isa_ok($xen, 'Xen::Control');
    can_ok($xen, qw( xm ls list shutdown ));
    
    @xm_output = qw(3 2 1);
    is_deeply([ $xen->xm('list') ], [ qw(3 2 1) ], 'test our test stuff');
    is_deeply([ @xm_cmds ], [ [ 'list' ] ], 'test our test stuff');
    
    # test $xen->create
    @xm_cmds   = ();
    $xen->create('lenny');
    eq_or_diff(
        [ @xm_cmds ],
        [ [ 'create', 'lenny.cfg' ] ],
        '$xen->create'
    );

    # test $xen->ls
    @xm_output = dump_with_name('01_xm-ls.txt');
    eq_or_diff(
        [ $xen->ls ],
        [
            Xen::Domain->new(
                'name'  => 'Domain-0',
                'id'    => 0,
                'mem'   => 1417,
                'vcpus' => 2,
                'state' => 'r-----',
                'times' => '249.3',        
            ),
            Xen::Domain->new(
                'name'  => 'lenny',
                'id'    => 1,
                'mem'   => 64,
                'vcpus' => 2,
                'state' => '-b----',
                'times' => '13.7',        
            )
        ],
        '$xen->xm("list")',
    );
    
    # test $xen->shutdown
    @xm_cmds   = ();
    @xm_output = dump_with_name('01_xm-ls_2.txt');
    $xen->shutdown('lenny');
    eq_or_diff(
        [ @xm_cmds ],
        [ [ 'shutdown', 'lenny' ] ],
        '$xen->shutdown("lenny")'
    );
    
    @xm_cmds   = ();
    $xen->shutdown;
    eq_or_diff(
        [ @xm_cmds ],
        [ [ 'shutdown', '-a' ], ],
        '$xen->shutdown - shutdown all machines'
    );
    
    # test $xen->save
    @xm_cmds   = ();
    @xm_output = dump_with_name('01_xm-ls_2.txt');
    $xen->save('lenny');
    eq_or_diff(
        [ @xm_cmds ],
        [ [ 'save', 'lenny', '/var/tmp/lenny.xen' ] ],
        '$xen->save("lenny") - hibernate lenny'
    );
    
    @xm_cmds   = ();
    $xen->save;
    eq_or_diff(
        [ @xm_cmds ],
        [ ['list'], [ 'save', 'lenny', '/var/tmp/lenny.xen' ], [ 'save', 'etch', '/var/tmp/etch.xen' ] ],
        '$xen->save - hibernate all machines'
    );
        
    SKIP: {
        my $file_test_count = 4;
        my $test_filename1 = $xen->hibernation_folder.'/lenny_xen_control.xen';
        my $test_filename2 = $xen->hibernation_folder.'/etch_xen_control.xen';
        
        # if the files with our test names exists, better skip this tests
        skip 'skipping some tests test file "'.$test_filename1.'" exists', $file_test_count
            if -e $test_filename1;
        skip 'skipping some tests test file "'.$test_filename2.'" exists', $file_test_count
            if -e $test_filename2;
        
        # skip if we are not able to write to temp folder
        skip 'skipping some tests, not able to write to '.$xen->hibernation_folder, $file_test_count
            if not (
                open(my $test_file, '>', $test_filename1)
                and open(my $test_file2, '>', $test_filename2)
            );
        
        # wrap the tests in eval so that we always unlink the test files at the end
        eval {
            # test $xen->hibernated_domains
            eq_or_diff(
                [ sort $xen->hibernated_domains ],
                [ 'etch_xen_control', 'lenny_xen_control' ],
                '$xen->hibernated_domains - lookup hibernated domains',
            );

            # test $xen->restore
            @xm_cmds   = ();
            $xen->restore('lenny');
            eq_or_diff(
                [ @xm_cmds ],
                [ [ 'restore', '/var/tmp/lenny.xen' ] ],
                '$xen->restore("lenny") - restore lenny'
            );
            
            @xm_cmds   = ();
            $xen->restore;
            eq_or_diff(
                [ @xm_cmds ],
                [ [ 'restore', '/var/tmp/lenny_xen_control.xen' ], [ 'restore', '/var/tmp/etch_xen_control.xen' ] ],
                '$xen->restore - restore all machines'
            );
            
            # test $xen->create to restore
            @xm_cmds   = ();
            $xen->create('lenny_xen_control');
            eq_or_diff(
                [ @xm_cmds ],
                [ [ 'restore', '/var/tmp/lenny_xen_control.xen' ] ],
                '$xen->create("lenny_xen_control") - restore lenny_xen_control'
            );
            
        };
        warn 'test eval failed - '.$@ if $@;
        
        unlink($xen->hibernation_folder.'/lenny_xen_control.xen', $xen->hibernation_folder.'/etch_xen_control.xen');
    }
    
    return 0;
}

no warnings 'redefine';
sub Xen::Control::xm {
    my $self = shift;
    push @xm_cmds, [ @_ ];
    return @xm_output;
}
