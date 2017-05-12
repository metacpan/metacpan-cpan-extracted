use strict;
use Test::More tests => 15;

BEGIN {
    use_ok 'WebService::Backlog';
    use_ok 'WebService::Backlog::Comment';
    use_ok 'WebService::Backlog::Component';
    use_ok 'WebService::Backlog::Issue';
    use_ok 'WebService::Backlog::IssueType';
    use_ok 'WebService::Backlog::Priority';
    use_ok 'WebService::Backlog::Project';
    use_ok 'WebService::Backlog::Resolution';
    use_ok 'WebService::Backlog::Status';
    use_ok 'WebService::Backlog::User';
    use_ok 'WebService::Backlog::Version';
    use_ok 'WebService::Backlog::FindCondition';

    use_ok 'WebService::Backlog::CreateIssue';
    use_ok 'WebService::Backlog::UpdateIssue';
    use_ok 'WebService::Backlog::SwitchStatus';
}
