# Copyright (c) 2001-2015 argumentum GmbH
# See COPYRIGHT section in VCS/CMSynergy.pod for usage and distribution rights.

use strict;
use warnings;

use Config;
use Data::Dumper;
use File::Spec;

our %test_session;

BEGIN
{
    die "CCM_HOME not set in environment"
        unless $ENV{CCM_HOME};
    die "CCM_TEST_DB not set in environment" 
        unless $ENV{CCM_TEST_DB};
    die "CCM_TEST_USER not set in environment" 
        unless $ENV{CCM_TEST_USER} || !($^O eq 'MSWin32' || $^O eq 'cygwin');

    %test_session = 
    (
        CCM_HOME        => $ENV{CCM_HOME},
	PrintError	=> 0,
	RaiseError	=> 1,
	database	=> $ENV{CCM_TEST_DB},
    );

    if ($ENV{CCM_TEST_USER})
    {
	# CCM_TEST_USER=user/password@host (Oracle style :)
	@test_session{qw(user password host)} = 
	    $ENV{CCM_TEST_USER} =~ m{^(.*?)/(.*?)\@(.*)};

	$test_session{server} = delete $test_session{host}
	    if $test_session{host} =~ /^https?:/i;
    }

    my $ccm_exe = File::Spec->catfile(
        $ENV{CCM_HOME}, "bin", "ccm$Config{_exe}");
    my ($ccm_version) = qx("$ccm_exe" version) 
        =~ m{(?:CM Synergy|SYNERGY/CM|Telelogic Synergy|IBM Rational Synergy)\s+Version\s+(\d+\.\d+)}i
            or die "can't determine Synergy version";

    if ($ccm_version < 7.2 && !defined $test_session{server})
    {
        # classic mode requested
        $test_session{UseCoprocess}    = $ENV{CCM_USE_COPROCESS}||0;
	$test_session{ui_database_dir} = File::Spec->tmpdir;
    }

    # Set the date format (the default is "%c" which depends
    # on the locale, the C library etc and hence makes comparisons
    # with expected values fail)
    # NOTE: restrict yourself to strftime conversion specifiers from
    # the ISO C standard; also, don't use locale dependent conversions
    $ENV{CCM_DATETIME_FMT} = "%Y-%m-%d %H:%M:%S";
}

# all_ok BLOCK AREF [, TEST_NAME]
# check if predicate BLOCK holds for all elements in list
sub all_ok(&$;$)
{
    my ($block, $aref, $test_name) = @_;

    local $Test::Builder::Level = 2;	# report failure for caller of all_ok

    if (my @failed = grep { ! &$block($_) } @$aref)
    {
	fail("all: $test_name");
	diag "\t$test_name failed for:\n";
	diag("\t\t$_\n") foreach @failed;
    }
    else
    {
	pass("all: $test_name");
    }
}

# stringify an array of VCS::CMSynergy::Object's
sub objectnames($)
{
    my $aref = shift;
    return [ map { $_->objectname } @$aref ];
}

# NOTE: We want to prevent Data::Dumper to dump all attributes
# of a VCS::CMSynergy::Object when using the tied hash interface.
sub verbose($$)
{
    return unless defined $ENV{TEST_VERBOSE} && $ENV{TEST_VERBOSE} > 1;

    my ($tag, $result) = @_;
    my $dumper = Data::Dumper->new([ $result], [ $tag ]);
    $dumper->Useqq(1);
    $dumper->Freezer('Freezer');
    print STDERR $dumper->Dump;
}

sub VCS::CMSynergy::Object::Freezer
{
    my $objectname = shift->objectname;
    return bless \$objectname, "VCS::CMSynergy::Object::Dummy";
}

# Shut up annoying Data::Dumper warning
# WARNING(Freezer method call failed): Can't locate object method "Freezer"...
sub VCS::CMSynergy::Freezer	{ return shift; }

1;
