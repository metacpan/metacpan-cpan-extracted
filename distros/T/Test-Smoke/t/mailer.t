#! /usr/bin/perl -w
use strict;

# $Id$

use File::Spec;
my $findbin;
use File::Basename;
BEGIN { $findbin = dirname $0; }
use lib $findbin;
use lib File::Spec->catdir( $findbin, File::Spec->updir, 'inc' );
use TestLib;

use Test::More tests => 32;

my $eg_config = { plevel => 19000, os => 'linux', osvers => '2.4.18-4g',
                  arch => 'i686/1 cpu', sum => 'PASS', version => '5.9.0',
                  branch => 'smokeme/nicholas/tryme'};
my $fail_cfg  = { plevel => 19000, os => 'linux', osvers => '2.4.18-4g',
                  arch => 'i686/1 cpu', sum => 'FAIL(F)', version => '5.9.0',
                  branch => 'maint-5.16'};

use_ok( 'Test::Smoke::Mailer' );
use Test::Smoke::Util 'parse_report_Config';

SKIP: {
    my $mhowto = 'Mail::Sendmail';
    local $@;
    my $load_error = do {
        eval "require $mhowto";
        $@;
    };
    $load_error and skip "Cannot load 'Mail::Sendmail'", 7;
    write_report( $eg_config ) or skip "Cannot write report", 7;

    my $mailer = Test::Smoke::Mailer->new( $mhowto => {
        ddir => 't',
        cc   => 'abeltje@test-smoke.org',
    } );

    isa_ok( $mailer, 'Test::Smoke::Mailer::Base' );
    isa_ok( $mailer, 'Test::Smoke::Mailer::Mail_Sendmail' );

    my $report = create_report( $eg_config );
    my $subject = $mailer->fetch_report();

    my @config = parse_report_Config( $mailer->{body} );
    my @conf = @{ $eg_config }{qw(version plevel os osvers arch sum branch)};
    
    is_deeply( \@config, \@conf, "Config..." );
    my $subj = sprintf "Smoke [%s] %s %s %s %s (%s)", @conf[6, 1, 5, 2, 3, 4];
    
    is( $subject, $subj, "Read the report: $subject" );
    is( $mailer->{body}, $report, "Report read back ok" );

    # Now we try to test the new ccp5p_onfail stuff
    # and the new cc behaviour: no cc unless fail
    is( $mailer->_get_cc( $subject ), '', 
        "p5p not added to cc-list [--noccp5p_onfail]" );
    $mailer->{ccp5p_onfail} = 1;
    is( $mailer->_get_cc( $subject ), '',
        "p5p not added to cc-list [PASS]" );
    1 while unlink File::Spec->catfile( 't', 'mktest.rpt' );
}

SKIP: {
    my $mhowto = 'Mail::Sendmail';
    local $@;
    my $load_error = do {
        eval "require $mhowto";
        $@;
    };
    $load_error and skip "Cannot load 'Mail::Sendmail'", 9;
    write_report( $fail_cfg ) or skip "Cannot write report", 9;

    my $mailer = Test::Smoke::Mailer->new( $mhowto => {
        ddir => 't',
        to   => 'abeltje@cpan.org',
        from => 'abeltje@cpan.org',
        cc   => 'abeltje@test-smoke.org',
    } );

    isa_ok( $mailer, 'Test::Smoke::Mailer::Base' );
    isa_ok( $mailer, 'Test::Smoke::Mailer::Mail_Sendmail' );

    my $report = create_report( $fail_cfg );
    my $subject = $mailer->fetch_report();

    my @config = parse_report_Config( $mailer->{body} );
    my @conf = @{ $fail_cfg }{qw(version plevel os osvers arch sum branch)};
    
    is_deeply( \@config, \@conf, "Config..." );
    my $subj = sprintf "Smoke [%s] %s %s %s %s (%s)", @conf[6, 1, 5, 2, 3, 4];

    is( $subject, $subj, "Read the report: $subject" );
    is( $mailer->{body}, $report, "Report read back ok" );

    # Now we try to test the new ccp5p_onfail stuff
    is( $mailer->_get_cc( $subject ), 'abeltje@test-smoke.org', 
        "p5p not added to cc-list [--noccp5p_onfail]" );
    $mailer->{ccp5p_onfail} = 1;
    is( $mailer->_get_cc( $subject ), 
        'abeltje@test-smoke.org, ' . $Test::Smoke::Mailer::P5P,
        "p5p got added to cc-list [--ccp5p_onfail]" );
    my $old_to = $mailer->{to};
    $mailer->{to} .= ", $Test::Smoke::Mailer::P5P";
    is( $mailer->_get_cc( $subject ), 'abeltje@test-smoke.org', 
        "p5p not added to cc-list [already in To:]" );
    $mailer->{to} = $old_to;
    $mailer->{cc} = $Test::Smoke::Mailer::P5P;
    is( $mailer->_get_cc( $subject ), $Test::Smoke::Mailer::P5P, 
        "p5p not added to cc-list [already in Cc:]" );
    1 while unlink File::Spec->catfile( 't', 'mktest.rpt' );
}

SKIP: {
    my $mhowto = 'mail';
    my $bin = whereis( $mhowto ) or skip "No '$mhowto' found", 5;
    write_report( $eg_config ) or skip "Cannot write report", 5;

    my $mailer = Test::Smoke::Mailer->new( $mhowto => {
        ddir => 't',
        mailbin => $bin,
    } );

    isa_ok( $mailer, 'Test::Smoke::Mailer::Base' );
    isa_ok( $mailer, 'Test::Smoke::Mailer::Mail_X' );

    my $report = create_report( $eg_config );
    my $subject = $mailer->fetch_report();

    my @config = parse_report_Config( $mailer->{body} );
    my @conf = @{ $eg_config }{qw(version plevel os osvers arch sum branch)};
    
    is_deeply( \@config, \@conf, "Config..." );
    my $subj = sprintf "Smoke [%s] %s %s %s %s (%s)", @conf[6, 1, 5, 2, 3, 4];

    is( $subject, $subj, "Read the report: $subject" );
    is( $mailer->{body}, $report, "Report read back ok" );
    1 while unlink File::Spec->catfile( 't', 'mktest.rpt' );
}

SKIP: {
    my $mhowto = 'mailx';
    my $bin = whereis( $mhowto ) or skip "No '$mhowto' found", 5;
    write_report( $eg_config ) or skip "Cannot write report", 5;

    my $mailer = Test::Smoke::Mailer->new( $mhowto => {
        ddir => 't',
        mailbin => $bin,
    } );

    isa_ok( $mailer, 'Test::Smoke::Mailer::Base' );
    isa_ok( $mailer, 'Test::Smoke::Mailer::Mail_X' );

    my $report = create_report( $eg_config );
    my $subject = $mailer->fetch_report();

    my @config = parse_report_Config( $mailer->{body} );
    my @conf = @{ $eg_config }{qw(version plevel os osvers arch sum branch)};
    
    is_deeply( \@config, \@conf, "Config..." );
    my $subj = sprintf "Smoke [%s] %s %s %s %s (%s)", @conf[6, 1, 5, 2, 3, 4];

    is( $subject, $subj, "Read the report: $subject" );
    is( $mailer->{body}, $report, "Report read back ok" );
    1 while unlink File::Spec->catfile( 't', 'mktest.rpt' );
}

SKIP: {
    my $mhowto = 'sendmail';
    $^O eq 'VMS' and skip "Do not try '$mhowto' on $^O", 5;
    local $ENV{PATH} = "$ENV{PATH}:/usr/sbin";
    my $bin = whereis( $mhowto ) or skip "No '$mhowto' found", 5;
    write_report( $eg_config ) or skip "Cannot write report", 5;

    my $mailer = Test::Smoke::Mailer->new( $mhowto => {
        ddir => 't',
        mailbin => $bin,
    } );

    isa_ok( $mailer, 'Test::Smoke::Mailer::Base' );
    isa_ok( $mailer, 'Test::Smoke::Mailer::Sendmail' );

    my $report = create_report( $eg_config );
    my $subject = $mailer->fetch_report();

    my @config = parse_report_Config( $mailer->{body} );
    my @conf = @{ $eg_config }{qw(version plevel os osvers arch sum branch)};
    
    is_deeply( \@config, \@conf, "Config..." );
    my $subj = sprintf "Smoke [%s] %s %s %s %s (%s)", @conf[6, 1, 5, 2, 3, 4];

    is( $subject, $subj, "Read the report: $subject" );
    is( $mailer->{body}, $report, "Report read back ok" );
    1 while unlink File::Spec->catfile( 't', 'mktest.rpt' );
}

sub write_report {
    my $eg = shift;

    local *REPORT;
    my $report_file = File::Spec->catfile( 't', 'mktest.rpt' );

    my $report = create_report( $eg );

    open REPORT, "> $report_file" or return undef;
    print REPORT $report;
    close REPORT or return undef;

    return 1;
}

sub create_report {
    my $eg = shift;
    my $branch = '';
    if (exists $eg->{branch}) {
        $branch = " branch $eg->{branch}";
    }
    return <<__EOR__;
Automated smoke report for$branch $eg->{version} patch $eg->{plevel}
host: TI UltraSparc I (SpitFire) ($eg->{arch})
    on $eg->{os} - $eg->{osvers}
    using cc version 4.2
    smoketime 4 hours 2 minutes

Summary: $eg->{sum}
__EOR__
}
