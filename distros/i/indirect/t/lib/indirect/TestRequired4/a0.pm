package indirect::TestRequired4::a0;
no indirect ":fatal";
use indirect::TestRequired4::b0;
sub error {
 local $@;
 indirect::TestRequired4::b0->get;
 return $@;
}
1;
