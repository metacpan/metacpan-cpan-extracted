use strict;
use warnings;


use Web::Dash::Lens;
use utf8;
use Encode qw(encode);

sub show_results {
    my (@results) = @_;
    foreach my $result (@results) {
        print "-----------\n";
        print encode('utf8', "$result->{name}\n");
        print encode('utf8', "$result->{description}\n");
        print encode('utf8', "$result->{uri}\n");
    }
    print "=============\n";
}

my $lens = Web::Dash::Lens->new(lens_file => '/usr/share/unity/lenses/applications/applications.lens');


## Synchronous query
my @search_results = $lens->search_sync("terminal");
show_results(@search_results);

    
## Asynchronous query
use Future::Q;
use Net::DBus::Reactor;
    
$lens->search("terminal")->then(sub {
    my @search_results = @_;
    show_results(@search_results);
    Net::DBus::Reactor->main->shutdown;
})->catch(sub {
    my $e = shift;
    warn "Error: $e";
    Net::DBus::Reactor->main->shutdown;
});
Net::DBus::Reactor->main->run();
