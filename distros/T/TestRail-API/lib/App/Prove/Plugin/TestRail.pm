# ABSTRACT: Upload your TAP results to TestRail in realtime
# PODNAME: App::Prove::Plugin::TestRail

package App::Prove::Plugin::TestRail;
$App::Prove::Plugin::TestRail::VERSION = '0.044';
use strict;
use warnings;
use utf8;

use File::HomeDir qw{my_home};
use TestRail::Utils;

sub load {
    my ( $class, $p ) = @_;

    my $app  = $p->{app_prove};
    my $args = $p->{'args'};

    my $params = {};

    #Only attempt parse if we aren't mocking and the homedir exists
    my $homedir = my_home() || '.';
    $params = TestRail::Utils::parseConfig($homedir)
      if -e $homedir && !$ENV{'TESTRAIL_MOCKED'};

    my @kvp = ();
    my ( $key, $value );
    foreach my $arg (@$args) {
        @kvp = split( /=/, $arg );
        if ( scalar(@kvp) < 2 ) {
            print
              "Unrecognized Argument '$arg' to App::Prove::Plugin::Testrail, ignoring\n";
            next;
        }
        $key            = shift @kvp;
        $value          = join( '', @kvp );
        $params->{$key} = $value;
    }

    $app->harness('Test::Rail::Harness');
    $app->merge(1);

    #XXX I can't figure out for the life of me any other way to pass this data. #YOLO
    $ENV{'TESTRAIL_APIURL'}    = $params->{apiurl};
    $ENV{'TESTRAIL_USER'}      = $params->{user};
    $ENV{'TESTRAIL_PASS'}      = $params->{password};
    $ENV{'TESTRAIL_PROJ'}      = $params->{project};
    $ENV{'TESTRAIL_RUN'}       = $params->{run};
    $ENV{'TESTRAIL_PLAN'}      = $params->{plan};
    $ENV{'TESTRAIL_CONFIGS'}   = $params->{configs};
    $ENV{'TESTRAIL_VERSION'}   = $params->{version};
    $ENV{'TESTRAIL_STEPS'}     = $params->{step_results};
    $ENV{'TESTRAIL_SPAWN'}     = $params->{testsuite_id};
    $ENV{'TESTRAIL_TESTSUITE'} = $params->{testsuite};
    $ENV{'TESTRAIL_SECTIONS'}  = $params->{sections};
    $ENV{'TESTRAIL_AUTOCLOSE'} = $params->{autoclose};
    $ENV{'TESTRAIL_ENCODING'}  = $params->{encoding};
    $ENV{'TESTRAIL_CGROUP'}    = $params->{'configuration_group'};
    $ENV{'TESTRAIL_TBAD'}      = $params->{'test_bad_status'};
    $ENV{'TESTRAIL_MAX_TRIES'} = $params->{'max_tries'};
    return $class;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Plugin::TestRail - Upload your TAP results to TestRail in realtime

=head1 VERSION

version 0.044

=head1 SYNOPSIS

`prove -PTestRail='apiurl=http://some.testrail.install/,user=someUser,password=somePassword,project=TestProject,run=TestRun,plan=TestPlan,configs=Config1:Config2:Config3,version=0.014' sometest.t`

=head1 DESCRIPTION

Prove plugin to upload test results to TestRail installations.

Accepts input in the standard Prove plugin fashion (-Ppluginname='key=value,key=value,key=value...'), but will also parse a config file.
When fed in prove plugin style, key=value input is expected.

If \$HOME/.testrailrc exists, it will be parsed for any of these values in a newline separated key=value list.  Example:

    apiurl=http://some.testrail.install
    user=someGuy
    password=superS3cret
    project=TestProject
    run=TestRun
    plan=GosPlan
    configs=config1:config2:config3: ... :configN
    version=xx.xx.xx.xx
    step_results=sr_sys_name
    lockname=internal_lock_name
    testsuite_id=123
    testsuite=blahblah #don't do this it's mutually exclusive with testuite_id
    sections=section1:section2:section3: ... :sectionN
    autoclose=0
    encoding=UTF-8
    configuration_group=Operating Systems
    test_bad_status=blocked
    max_tries=3

Note that passing configurations as filters for runs inside of plans are separated by colons.

If a configuration_group option is passed, it, and any configurations passed will be created automatically for you in the case they do not exist.

Values passed in via query string will override values in \$HOME/.testrailrc.
If your system has no concept of user homes, it will look in the current directory for .testrailrc.

See the documentation for the constructor of L<Test::Rail::Parser> as to why you might want to pass the aforementioned options.

=head1 CAVEATS

When running prove in multiple job mode (-j), or when breaking out test jobs into multiple prove processes, auto-spawn of plans & runs can race.
Be sure to extend your harness to make sure these things are already created if you do either of these things.

Also, all parameters expecting names are vulnerable to duplicate naming issues.  Try not to use the same name for:

    * projects
    * testsuites within the same project
    * sections within the same testsuite that are peers
    * test cases
    * test plans and runs outside of plans which are not completed
    * configurations & configuration groups

To do so will result in the first of said item found.
This might result in the reuse of an existing run/plan unintentionally, or spawning runs within the wrong project/testsuite or with incorrect test sections.
Similarly, duplicate named tests will result in one of the dupes never being run (as the first found is chosen).

=head1 OVERRIDDEN METHODS

=head2 load(parser)

Shoves the arguments passed to the prove plugin into $ENV so that Test::Rail::Parser can get at them.
Not the most elegant solution, but I see no other clear path to get those variables downrange to it's constructor.

=head1 SEE ALSO

L<TestRail::API>

L<Test::Rail::Parser>

L<App::Prove>

L<File::HomeDir> for the finding of .testrailrc

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.

=head1 AUTHOR

George S. Baugh <teodesian@cpan.org>

=head1 SOURCE

The development version is on github at L<http://github.com/teodesian/TestRail-Perl>
and may be cloned from L<git://github.com/teodesian/TestRail-Perl.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by George S. Baugh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
