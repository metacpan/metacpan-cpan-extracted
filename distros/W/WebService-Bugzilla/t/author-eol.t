
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/WebService/Bugzilla.pm',
    'lib/WebService/Bugzilla/Attachment.pm',
    'lib/WebService/Bugzilla/Bug.pm',
    'lib/WebService/Bugzilla/Bug/History.pm',
    'lib/WebService/Bugzilla/Bug/History/Change.pm',
    'lib/WebService/Bugzilla/BugUserLastVisit.pm',
    'lib/WebService/Bugzilla/Classification.pm',
    'lib/WebService/Bugzilla/Comment.pm',
    'lib/WebService/Bugzilla/Component.pm',
    'lib/WebService/Bugzilla/Exception.pm',
    'lib/WebService/Bugzilla/Field.pm',
    'lib/WebService/Bugzilla/Field/Value.pm',
    'lib/WebService/Bugzilla/FlagActivity.pm',
    'lib/WebService/Bugzilla/FlagActivity/Type.pm',
    'lib/WebService/Bugzilla/GitHub.pm',
    'lib/WebService/Bugzilla/Group.pm',
    'lib/WebService/Bugzilla/Information.pm',
    'lib/WebService/Bugzilla/Object.pm',
    'lib/WebService/Bugzilla/Product.pm',
    'lib/WebService/Bugzilla/Reminder.pm',
    'lib/WebService/Bugzilla/Role/Updatable.pm',
    'lib/WebService/Bugzilla/User.pm',
    'lib/WebService/Bugzilla/UserDetail.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-client.t',
    't/02-reminder.t',
    't/03-classification.t',
    't/04-bug.t',
    't/05-attachment.t',
    't/06-user.t',
    't/07-group.t',
    't/08-product.t',
    't/09-comment.t',
    't/10-component.t',
    't/11-field.t',
    't/12-flag-activity.t',
    't/13-bug-user-last-visit.t',
    't/author-distmeta.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-no-breakpoints.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/exception-handling.t',
    't/http-security.t',
    't/lib/Bugzilla/Examples.pm',
    't/lib/Test/Bugzilla.pm',
    't/lib/Test/Bugzilla/PSGI.pm',
    't/lib/Test/Bugzilla/PSGIApp.pm',
    't/release-kwalitee.t',
    't/release-pause-permissions.t',
    't/release-test-legal.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
