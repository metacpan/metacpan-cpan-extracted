use 5.012;
use warnings;
use lib 't/lib'; use MyTest;

subtest "uv backend" => sub {
    ok UniEvent::Backend::UV(), "exists";
    is UniEvent::Backend::UV()->name, "uv", "name ok";
};

UniEvent::default_backend()->name;

dies_ok { UniEvent::set_default_backend(undef) } "cannot set null as default backend";

UniEvent::set_default_backend(UniEvent::Backend::UV());

UniEvent::Loop->new(UniEvent::Backend::UV());

done_testing();
