use strict;
use warnings;

use Path::Tiny ();
my $response_base = Path::Tiny::path(qw(t cpanidx_responses))->absolute;

# patch modules that hit the network, to be sure we don't do this during
# testing.
{
    use HTTP::Tiny;
    package HTTP::Tiny;
    no warnings 'redefine';
    sub get {
        my ($self, $url) = @_;
        Test::More::note 'in monkeypatched HTTP::Tiny::get for ' . $url;
        my ($module) = reverse split('/', $url);
        $module =~ s/::/_/g;
        my $body = $response_base->child($module);
        return +{
            success => 1,
            status => '200',
            reason => 'OK',
            protocol => 'HTTP/1.1',
            url => $url,
            headers => {
                'content-type' => 'text/x-yaml',
            },
            content => $body->exists ? $body->slurp_utf8 : '[]',
        };
    }
    sub mirror { die "HTTP::Tiny::mirror called for $_[1]" }
}
1;
