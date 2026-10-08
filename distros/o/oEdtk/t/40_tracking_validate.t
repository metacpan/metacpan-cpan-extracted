#!/usr/bin/perl
#
# Non-regression tests for the pure validators of oEdtk::Tracking.
#
# oEdtk::Tracking installs global $SIG{__WARN__}/$SIG{__DIE__} handlers at BEGIN
# time; they are neutralized right after loading so they cannot interfere with
# the rest of the test run.
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use TestOEdtk qw(quiet_require reset_sig_handlers mute);

quiet_require('oEdtk::Tracking');
reset_sig_handlers();

# --- _validate_event : first letter of a valid job event --------------------
is(oEdtk::Tracking::_validate_event('Job'),      'J', '_validate_event Job');
is(oEdtk::Tracking::_validate_event('Spool'),    'S', '_validate_event Spool');
is(oEdtk::Tracking::_validate_event('Document'), 'D', '_validate_event Document');
is(oEdtk::Tracking::_validate_event('Line'),     'L', '_validate_event Line');
is(oEdtk::Tracking::_validate_event('Warning'),  'W', '_validate_event Warning');
is(oEdtk::Tracking::_validate_event('Error'),    'E', '_validate_event Error');
is(mute(sub { oEdtk::Tracking::_validate_event('Halt') }), 'H', '_validate_event Halt');
is(oEdtk::Tracking::_validate_event('Reject'),   'R', '_validate_event Reject');
is(oEdtk::Tracking::_validate_event('Track'),    'T', '_validate_event Track');
is(oEdtk::Tracking::_validate_event('JobXYZ'),   'J', '_validate_event only checks the first letter');

eval { mute(sub { oEdtk::Tracking::_validate_event(undef) }) };
like($@, qr/Invalid job event/, '_validate_event dies on undef');
eval { oEdtk::Tracking::_validate_event('X') };
like($@, qr/Invalid job event/, '_validate_event dies on an unknown event');

# --- _validate_edmode : printing mode letter, 'U' as default -----------------
is(oEdtk::Tracking::_validate_edmode('Batch'),   'B', '_validate_edmode Batch');
is(oEdtk::Tracking::_validate_edmode('Tp'),      'T', '_validate_edmode Tp');
is(oEdtk::Tracking::_validate_edmode('Web'),     'W', '_validate_edmode Web');
is(oEdtk::Tracking::_validate_edmode('Mail'),    'M', '_validate_edmode Mail');
is(oEdtk::Tracking::_validate_edmode('Groupe'),  'G', '_validate_edmode Groupe');
# The source comment lists "probinG", but the regex anchors on the first
# character, so a value such as "probinG" actually falls back to 'U'.
is(oEdtk::Tracking::_validate_edmode('probinG'), 'U', '_validate_edmode probinG falls back to U');
is(oEdtk::Tracking::_validate_edmode(undef),     'U', '_validate_edmode undef defaults to U');
is(oEdtk::Tracking::_validate_edmode(''),        'U', '_validate_edmode empty defaults to U');
is(oEdtk::Tracking::_validate_edmode('Z'),       'U', '_validate_edmode unknown defaults to U');
is(oEdtk::Tracking::_validate_edmode('Xyz'),     'U', '_validate_edmode garbage defaults to U');

done_testing();
