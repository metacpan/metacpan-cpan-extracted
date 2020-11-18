# HARNESS-NO-TIMEOUT
use common::sense;
use WWW::WTF::Testcase;

my $test = WWW::WTF::Testcase->new(
    ua_webkit2 => WWW::WTF::UserAgent::WebKit2->new(
        callbacks => {
            'resource-load-started' => sub {
                my ($view, $resource, $request) = @_;

                check_request($view->get_uri, $request->get_uri);
            }
        }
    ),
);

my %requests;

sub check_request {
    my ($browser_location, $requested_uri) = @_;

    $test->report->diag("Checking external request $requested_uri at $browser_location");

    my $base_uri = $test->base_uri->as_string;

    $base_uri =~ s/^https?/https\?/;

    return if $requested_uri =~ m!^data:!;

    if($requested_uri =~ m!$base_uri!) {
        $requests{$browser_location}{internal}{$requested_uri}++;
    } else {
        $requests{$browser_location}{external}{$requested_uri}++;
    }
}

$test->run_test(sub {
    my ($self) = @_;

    my $iterator = $self->ua_webkit2->recurse($self->uri_for('/sitemap.xml'));

    while ($iterator->next) {
        # checked by callback
    }

    while (my ($browser_location, $requests) = each(%requests)) {
        $self->run_subtest($browser_location, sub {
            $self->report->pass("Internal Request $_")
                foreach(keys(%{ $requests->{internal} }));

            $self->report->fail("External Request $_")
                foreach(keys(%{ $requests->{external} }));
        });
    }
});
