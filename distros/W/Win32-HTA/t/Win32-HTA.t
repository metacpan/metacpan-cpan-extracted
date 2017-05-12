use strict;
use warnings;

use Test::More tests => 5;

BEGIN { use_ok('Win32::HTA') };

my $hta = new_ok('Win32::HTA');

my %set1 = %{ $hta };

my $ret = $hta->show(
    ON_LOAD => q[
        pipe_string('whoosh!');
    ],
);

is($ret, 'whoosh!', 'pipe string from hta');

$hta->clear();
my %set2 = %{ $hta };

is_deeply(\%set1, \%set2, 'clear settings');

SKIP: {
    skip('JSON not installed', 1)
        unless eval { require JSON };

    my @tdata;
    $hta->show(
        AJAX => sub {
            my($request) = @_;
            push @tdata, $request->{request};
            push @tdata, $request->{data};
            return { succeeded => 1, data => 'huuiii!' };
        },
        ON_LOAD => q[
            var reply = ajax_request({request : "test1", data : 'testdata'});
            if ( reply['succeeded'] ) {
                reply = ajax_request({request : "test2", data : reply['data']});
            }
            close();
        ],
    );

    is_deeply(\@tdata, ['test1', 'testdata', 'test2', 'huuiii!'], 'ajax simple')
        or do {
            # diagnostic info for failures from CPAN Testers
            my $iev_str = qx/reg query "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Internet Explorer" \/v version"/;
            my($iev) = $iev_str =~ /version\s+REG_SZ\s+(\S+)/;
            warn "IE Version $iev\n";
        };
};
