use 5.012;
use warnings;
use lib 't/lib'; use MyTest;

subtest "uv backend" => sub {
    ok UniEvent::Backend::UV(), "exists";
    is UniEvent::Backend::UV()->name, "uv", "name ok";
};

subtest "default backend" => sub {
    UniEvent::default_backend()->name;
    dies_ok { UniEvent::set_default_backend(undef) } "cannot set null as default backend";
};

subtest "set default backend" => sub {
    UniEvent::set_default_backend(UniEvent::Backend::UV());
    UniEvent::Loop->default_loop();
    dies_ok { UniEvent::set_default_backend(UniEvent::Backend::UV()) } "cannot change backend after global/default loop is accessed";
};

subtest "create loop with specified backend" => sub {
    UniEvent::Loop->new(UniEvent::Backend::UV());
    pass();
};

done_testing();
