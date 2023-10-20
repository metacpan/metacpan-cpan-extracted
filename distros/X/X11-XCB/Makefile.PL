use strict; use warnings;

# Automated testing of this module makes little sense: It requires libXau,
# libXdmcp, python2.6 and xsltproc which are typically not installed on CPAN
# smokers.
exit 0 if $ENV{AUTOMATED_TESTING};

my (@configure_req);
BEGIN{
  @configure_req = qw/
    Module::Install
    Module::Install::AuthorRequires
    Module::Install::XSUtil
    ExtUtils::Depends
    ExtUtils::PkgConfig
    XS::Object::Magic
  /;
  my %ok;

  die << '__' . (join "\n", grep { not $ok{$_} } keys %ok) . << '__'
You're running me in author mode.
Your fellow developer left a message to inform you
to please install the following packages manually:

__


Afterwards you can use your CPAN client to install the remaining dependencies,
build this module and install it (eg. `cpanm .`).
__
    if -e '.git'
       and @configure_req
           != grep { $ok{$_} = eval "require $_; 1" } @configure_req;
}

BEGIN { unshift @INC, '.'; }
use inc::Module::Install;

name 'X11-XCB';

abstract 'Perl bindings for libXcb';
license_from 'lib/X11/XCB.pm';
perl_version_from 'lib/X11/XCB.pm';
version_from 'lib/X11/XCB.pm';

author 'Michael Stapelberg <michael+xcb@stapelberg.de>';
author 'Sergei Zhmylev <zhmylove@cpan.org>';

repository 'https://github.com/zhmylove/X11-XCB';
bugtracker 'https://github.com/zhmylove/X11-XCB/issues';

requires 'Mouse';
requires 'MouseX::NativeTraits';
requires 'Try::Tiny';

# These are build-time requirements, but there is no way to express this (that
# I know of):
requires 'XML::Simple';
requires 'XML::Descent';
requires 'Data::Dump';

test_requires 'Test::More';
test_requires 'Test::Deep';
test_requires 'Test::Exception';

configure_requires $_ for grep !/Module::Install/, @configure_req;

use_ppport;

# -Wunused-value generates too much output to use it unconditionally
cc_warnings if $ENV{X11_XCB_CC_WARNINGS};

require ExtUtils::PkgConfig;
require ExtUtils::Depends;

ExtUtils::PkgConfig->atleast_version('xcb', '1.2')
  or die "You need at least libxcb version 1.2\n";

my @xcb_libs = qw/xcb xcb-util xcb-xinerama xcb-icccm xcb-randr xcb-xkb/;
@xcb_libs == grep { eval { ExtUtils::PkgConfig->find($_); 1 } } @xcb_libs
  or die "Perhaps you haven't installed the development versions?\n";

cc_libs @xcb_libs;

WriteMakefile(
  ExtUtils::Depends
    ->new('X11::XCB', 'XS::Object::Magic')
    ->get_makefile_vars
);

postamble <<'END_OF_MAKEFILE';
XCB_xs.inc:
	$(PERL) -I. -M_GenerateMyXS -E '_GenerateMyXS::generate()'

XCB.inc: XCB_xs.inc
	## Recover from the removal of $@
	@test -f $@ || rm -f XCB_xs.inc
	@test -f $@ || $(MAKE) $(AM_MAKEFLAGS) XCB_xs.inc

XCB.c: XCB_xs.inc XCB_util.inc XCB.inc

END_OF_MAKEFILE

# vim:sw=2:sts=2:et
