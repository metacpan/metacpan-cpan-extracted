use strict;
use warnings;
use Test::More;
use Web::Dash::Lens;

system('killall', 'unity-lens-github');

{
    my $lens_file = '/usr/share/unity/lenses/extras-unity-lens-github/extras-unity-lens-github.lens';
    my $lens = Web::Dash::Lens->new(lens_file => $lens_file);
    my $desc = $lens->search_hint_sync();
    ok($desc, "search_hint obtained");

    note(<<EOD);
If lens process is not running, DBus seems to spawn it when someone tries to
communicate with it. Unfortunately, the newly spawned remote object is somehow
unprepared and call to Search() method fails in a strange way. By recreating the lens,
we can obtain the fully functional remote objects.
EOD
    
    $lens = Web::Dash::Lens->new(lens_file => $lens_file);
    
    my @results = $lens->search_sync('web dash');
    cmp_ok(int(@results), ">", 0, "results obtained");
}
done_testing();




