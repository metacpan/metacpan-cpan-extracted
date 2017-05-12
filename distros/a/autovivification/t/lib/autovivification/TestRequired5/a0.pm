package autovivification::TestRequired5::a0;
no autovivification qw<strict fetch>;
use autovivification::TestRequired5::b0;
sub error {
 local $@;
 autovivification::TestRequired5::b0->get;
 return $@;
}
1;
