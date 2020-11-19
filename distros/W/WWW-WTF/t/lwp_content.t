use FindBin;
use lib "$FindBin::Bin/lib";
use Test2::V0 '!meta';
use WWW::WTF::Test;

my $test = WWW::WTF::Test->new();

$test->run_test(sub {
    my ($self) = @_;

    my $http_resource = $self->ua_lwp->get($self->uri_for('/index.html'));

    my $content = $http_resource->content();

    $content->contains_string('Cool', 'contains_string found Cool');
    $content->contains_regex(qr/Super/, 'contains_regex found /Super/');
    $content->lacks_string('Great', "lacks_string didn't find Great");
    $content->lacks_regex(qr/Excellent/, "lacks_string didn't find Excellent");
});

done_testing();
