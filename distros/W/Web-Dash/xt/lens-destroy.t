use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);
use Web::Dash::Lens;

my $lens_out;
{
    my $lens = new_ok('Web::Dash::Lens', [
        service_name => 'com.canonical.Unity.Lens.Files',
        object_name => '/com/canonical/unity/lens/files',
    ]);
    $lens_out = $lens;
    weaken $lens_out;
    my $hint = $lens->search_hint_sync();
    isnt($hint, "", "obtain search_hint OK");
    my @results = $lens->search_sync('hoge');
}

is($lens_out, undef, "Lens is destroyed properly.");

done_testing();

