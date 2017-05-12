use strict;
use warnings;
use Test::More;
use Web::Dash::Lens;

{
    my $service = "com.canonical.Unity.Lens.Applications";
    my $object = '/com/canonical/unity/lens/applications';
    my $lens = Web::Dash::Lens->new(
        service_name => $service,
        object_name => $object,
    );
    my $clone = $lens->clone();
    is($clone->service_name, $service, "service_name of the clone OK");
    is($clone->object_name, $object, "object_name of the clone OK");
}

done_testing();

