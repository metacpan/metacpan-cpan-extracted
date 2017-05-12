use strict;
use warnings;
use Test::More;
use Web::Dash::Lens;
use utf8;

my $lens = Web::Dash::Lens->new(lens_file => '/usr/share/unity/lenses/applications/applications.lens');
my @results = $lens->search_sync('端末');
cmp_ok(int(@results), ">", 0, "some results obtained");

my $find_tammatsu = 0;
foreach my $result (@results) {
    if($result->{comment} =~ /端末/ || $result->{name} =~ /端末/) {
        $find_tammatsu = 1;
        last;
    }
}
ok($find_tammatsu, 'The japanese word "tammatsu" found');
note(explain @results);

done_testing();

