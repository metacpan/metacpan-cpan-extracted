package autovivification::TestRequired4::a0;
no autovivification qw<strict fetch>;
use autovivification::TestRequired4::b0;
sub error {
 local $@;
 autovivification::TestRequired4::b0->get;
 return $@;
}
1;
