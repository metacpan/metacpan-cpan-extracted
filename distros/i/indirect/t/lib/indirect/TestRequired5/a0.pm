package indirect::TestRequired5::a0;
no indirect ":fatal";
use indirect::TestRequired5::b0;
sub error {
 local $@;
 indirect::TestRequired5::b0->get;
 return $@;
}
1;
