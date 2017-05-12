#
# Test case for WebService::Recruit::Shingaku
#

use strict;
use Test::More tests => 12;


{
    use_ok('WebService::Recruit::Shingaku::School');
    my $obj = new WebService::Recruit::Shingaku::School();
    ok( ref $obj, 'new WebService::Recruit::Shingaku::School()');
}

{
    use_ok('WebService::Recruit::Shingaku::Subject');
    my $obj = new WebService::Recruit::Shingaku::Subject();
    ok( ref $obj, 'new WebService::Recruit::Shingaku::Subject()');
}

{
    use_ok('WebService::Recruit::Shingaku::Work');
    my $obj = new WebService::Recruit::Shingaku::Work();
    ok( ref $obj, 'new WebService::Recruit::Shingaku::Work()');
}

{
    use_ok('WebService::Recruit::Shingaku::License');
    my $obj = new WebService::Recruit::Shingaku::License();
    ok( ref $obj, 'new WebService::Recruit::Shingaku::License()');
}

{
    use_ok('WebService::Recruit::Shingaku::Pref');
    my $obj = new WebService::Recruit::Shingaku::Pref();
    ok( ref $obj, 'new WebService::Recruit::Shingaku::Pref()');
}

{
    use_ok('WebService::Recruit::Shingaku::Category');
    my $obj = new WebService::Recruit::Shingaku::Category();
    ok( ref $obj, 'new WebService::Recruit::Shingaku::Category()');
}


1;
