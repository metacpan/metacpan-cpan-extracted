use strict;
use Test::More tests => 18;

use WebService::Backlog;
use Encode;

use Data::Dumper;

my $backlog = WebService::Backlog->new(
    space    => 'backlog',
    username => 'guest',
    password => 'guest',
);

{
    my $issue = $backlog->getIssue(181);
    ok($issue);
    is($issue->id, 181);
    is($issue->key, decode_utf8('BLG-10'));
    is($issue->summary, decode_utf8('課題詳細で、前後の課題に移動できる機能'));
    ok(defined($issue->issueType));
    is($issue->issueType->name, decode_utf8('要望'));
    is($issue->priority->name, decode_utf8('中'));
    is($issue->component, undef);
    ok(defined($issue->resolution));
    is($issue->resolution->name, decode_utf8('対応済み'));
    is($issue->version, undef);
    is($issue->status->name, decode_utf8('完了'));
    ok(defined($issue->milestone));
    is($issue->milestone->name, decode_utf8('R2005-06-30'));
    ok(defined($issue->created_user));
    is($issue->created_user->name, decode_utf8('あがた＠ヌーラボ'));
    ok(defined($issue->assigner));
    is($issue->assigner->name, decode_utf8('あがた＠ヌーラボ'));
}

