# Revision history for Test-Timer

## 2.12 2021-07-08 Maintenance release, update not required

* Updated CODE OF CONDUCT to latest version (thanks to Yak)

* Migrated change log (`Changes`) from text file to Markdown file, renamed to: `CHANGELOG.md`

* Removed [Dist::Zilla::Plugin::Test::CPAN::Changes](https://metacpan.org/pod/Dist::Zilla::Plugin::Test::CPAN::Changes) from [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) configuration

* All code has been run through [Perl::Tidy](https://metacpan.org/pod/Perl::Tidy)

## 2.11 2019-09-06T17:43:07Z Maintenance release, update not required

* Applied PR [#23](https://github.com/jonasbn/perl-test-timer/pulls/16) with POD improvements from Mohammad S Anwar

## 2.10 2019-02-19T16:13:40Z Maintenance release, update not required

* Cleaned the code a bit and eliminated use of regular expression for parsing output from Benchmark, issue [#21](https://github.com/jonasbn/perl-test-timer/issues/21)

## 2.09 2017-11-24 Maintenance release, update not required

* Attempting to address issues with [tests on Windows](http://www.cpantesters.org/distro/T/Test-Timer.html?grade=3&perlmat=2&patches=2&oncpan=2&distmat=2&perlver=ALL&osname=ALL&version=2.08)

* Reinstated `sleep` over `select` in the test suite

* Changed some test parameters was made a bit less relaxed attempting to decrease the execution time
  for the test suite

* Removed loose match in regular, it should be possible to anticipate the timeout

* Removed redundant tests, trying to cut down execution time for the test suite

## 2.08 2017-11-20 Maintenance release, update not required

* Addressing reports on failing tests from CPAN testers

## 2.07 2017-11-18 Maintenance release, update not required

* Addressing issue [#17](https://github.com/jonasbn/perl-test-timer/issues/17), the tests are now more liberal, so when executed on smokers, CI environments and similar, load will not influence the test results. The requirement for [Test::Tester](https://metacpan.org/pod/Test::Tester) has been updated and a patch required by this distribution has been included

## 2.06 2017-11-14 Maintenance release, update not required

* Added cancellation of alarm, based on advice from Erik Johansen

* Implemented own `sleep`, based on `select`, this might address possible issues with
  `sleep` implementations

## 2.05 2017-11-12 Maintenance release, update not required

* Addressed issue [#11](https://github.com/jonasbn/perl-test-timer/issues/11) adding experimental graphical support elements to the documentation

## 2.04 2017-10-15 Maintenance release, update not required

* Minor improvements to Test::Timer::TimeoutException, some obsoleted code could
  be removed

* Generalising test asserting, since CPAN testers are sometime constrained on resources,
  making it impossible to predict the actual timeout value, see [example](http://www.cpantesters.org/cpan/report/2561e32c-9efa-11e7-bc90-bbe42ddde1fb)

* Correction of spelling mistake via PR [#16](https://github.com/jonasbn/perl-test-timer/pulls/16) from Gregor Herrmann of the Debian Perl Group

## 2.03 2017-07-01 Maintenance release, update not required

* Minor clean up in code and tests

## 2.02 2017-06-30 Maintenance release, update recommended

* Correction to documentation

* Improvements to alarm signal handling and other internal parts

* Addressed issue [#15](https://github.com/jonasbn/perl-test-timer/issues/15) meaning thresholds are now included in the assertions

## 2.01 2017-06-12 Bug fix release, update recommended

* Fixed bug where execution/time would be reported as `0`, ref: issue [#13](https://github.com/jonasbn/perl-test-timer/issues/13)

## 2.00 2017-06-06 Feature release, update recommended

* Improved diagnostics based on feedback for change introduced in 1.00
  from Nigel Horne. The actual measured time used is now presented, ref: issue [#12](https://github.com/jonasbn/perl-test-timer/issues/12)

* private subroutine `_runtest_atleast` factored out, ref: [#9](https://github.com/jonasbn/perl-test-timer/issues/9)

## 1.00 2017-06-03 Feature release, update recommended

* Implemented suggestion for improvement from Nigel Horne [#10](https://github.com/jonasbn/perl-test-timer/issues/10)

  This change impacts all the diagnostics, so these now communicate the relevant specified thresholds

* Added [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) plugins requirements causing issues to `dist.ini`, so these are explicitly specified

* Exchanged CJM´s: [Dist::Zilla::Plugin::VersionFromModule](https://metacpan.org/pod/Dist::Zilla::Plugin::VersionFromModule) for Dave Rolskys: [Dist::Zilla::Plugin::VersionFromMainModule](https://metacpan.org/pod/Dist::Zilla::Plugin::VersionFromMainModule)

  There are some deprecation notices from Dist::Zilla making tests fail
  see XDG's [PR](https://github.com/madsen/dist-zilla-plugins-cjm/pull/5)

## 0.18 2016-12-30 Maintenance release, update not required

* Reenabled Github issues over RT, the [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) plugins not completely compatible

## 0.17 2016-12-30 Maintenance release, update not required

* Exchanged use of Test::Exception for Test::Fatal

* Exchanged use of: [Dist::Zilla::Plugin::GitHub::Meta](https://metacpan.org/pod/Dist::Zilla::Plugin::GitHub::Meta) for [Dist::Zilla::Plugin::GithubMeta](https://metacpan.org/pod/Dist::Zilla::Plugin::GithubMeta) to specify a proper homepage attribute

## 0.16 2016-12-29 Maintenance release, update not required

* Elimination of warnings in test suite, PR [#4](https://github.com/jonasbn/perl-test-timer/pulls/4) from p-alik

## 0.15 2016-12-11 Maintenance release, update not required

* Addressed Kwalitee test: `has_meta_json`

* Addressing minor cosmetics issues in release 0.14

## 0.14 2016-12-10 Maintenance release, update not required

* Corrections to file permissions, PR [#7](https://github.com/jonasbn/perl-test-timer/pulls/7) from Kent Fredric

## 0.13 2016-08-05 Maintenance release, update not required

* Corrections to the POD, PR [#5](https://github.com/jonasbn/perl-test-timer/pulls/5) from Nick Morrott

## 0.12 2015-08-02 Maintenance release, update not required

* Added `MetaProvides` to [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) build, this should assist in addressing the issue listed on CPANTS, see also below

* Addressing [issue](http://cpants.cpanauthors.org/dist/Test-Timer-0.11) with inconsistent version

## 0.11 2015-07-15 Maintenance release, update not required

* Requirement for Perl 5.12 sneaked in issue [#3](https://github.com/jonasbn/perl-test-timer/issues/3), analysed code with [Perl::MinimumVersion](https://metacpan.org/pod/Perl::MinimumVersion) and decided for Perl version 5.6.0 as minimum requirement

## 0.10 2015-06-01 Maintenance release, update not required

* [Test::Tester](https://metacpan.org/pod/Test::Tester) is marked as a normal runtime dependency issue [#2](https://github.com/jonasbn/perl-test-timer/issues/2) (RT:1047699)

* Upgraded license from Artistic license 1.0 to Artistic license 2.0

* Migrated build system from [Module::Build](https://metacpan.org/pod/Module::Build) to [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla)

## 0.09 2014-08-29 Maintenance release, update not required

* Addressing issue [#1](https://github.com/jonasbn/perl-test-timer/issues/1), the occassional report on failing the rigid test of: `test_between`

## 0.08 2014-02-22 Maintenance release, update not required

* Repository migrated to Github from hosted Subversion

* Plenty of POD updates

* Added `changes.t` automatic assertion of the integrity of the `Changes` file

## 0.07 2013-07-31 Maintenance release, update not required

* Corrected minor issue in this file, had forgotten to run in through [the validator](http://changes.cpanhq.org/validate)

## 0.06 2013-07-26 Maintenance release, update not required

* Fixed up `Changes` file as part of my Questhub quest adhering to the standard
  described in: [CPAN::Changes::Spec](https://metacpan.org/module/CPAN::Changes::Spec)

## 0.05 2008-11-16 Bug fix release, update not required

* Added use of [Test::Builder::Module](https://metacpan.org/pod/Test::Builder::Module)

* Added patch from brian d foy, bug in `_run_test`

## 0.04 2007-03-18 Maintenance release, update not required

* Added creation of traditional `Makefile.PL` to `Build.PL`

* Added `Makefile.PL` to `MANIFEST`

## 0.03 2007-03-11 Maintenance release, update not required

* Removed version number from `README`

* Read up on the [Test::Perl::Critic](https://metacpan.org/pod/Test::Perl::Critic) documentation and updated my [Perl::Critic](https://metacpan.org/pod/Perl::Critic) test (t/critic.t), introducing `t/perlcriticrc` and added a few of the requirements needed by this test to build requirements

* Moved [Test::Tester](https://metacpan.org/pod/Test::Tester) to general requirements from build requirements

* Minor changes to POD

## 0.02 2007-03-10 Feature release, update recommended

* Removed support for reference to arrays as second parameter to `time_nok`,
  `time_ok`, `time_almost` and `time_atleast` - `time_between` is recommended

* Read up on the [Test::Builder](https://metacpan.org/pod/Test::Builder) does and eliminated the builder subroutine, this has also been removed from the test-suite (`t/test-tester.t`)

* Added some more tests, to get better coverage, thanks to PJCJ for [Devel::Cover](https://metacpan.org/pod/Devel::Cover) this module really helps, since aiming at better coverage, makes you think about your tests and code and you can eliminate stuff you do not need

* Updated POD added DIAGNOSTICS among other things

* Fixed bug in Test::Timer, with alarm being scoped using my, should
  be our, pointed out by Paul Evans

* Ran all code through [Perl::Tidy](https://metacpan.org/pod/Perl::Tidy)

## 0.01 2007-03-01 Feature release

* First version, released on an unsuspecting world.
