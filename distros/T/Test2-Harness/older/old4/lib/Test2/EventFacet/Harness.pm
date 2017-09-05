package Test2::EventFacet::Harness;
use strict;
use warnings;

BEGIN { require Test2::EventFacet; our @ISA = qw(Test2::EventFacet) }
use Test2::Util::HashBase qw{
    -job_id -job_start -job_end
    -stamp -source -line -exit -raw
    -subtest_start -subtest_end -subtest
};

1;

__END__


