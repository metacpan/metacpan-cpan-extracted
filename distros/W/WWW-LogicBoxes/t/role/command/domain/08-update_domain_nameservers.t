#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Domain qw( create_domain );

my $logic_boxes = create_api();

subtest 'Update Nameservers on Domain That Does Not Exist' => sub {
    throws_ok {
        $logic_boxes->update_domain_nameservers(
            id          => 999999999,
            nameservers => [ 'ns1.logicboxes.com', 'ns2.logicboxes.com' ],
        );
    } qr/No such domain/, 'Throws on domain that does not exist';
};

subtest 'Update Nameservers To Currently Values' => sub {
    my $nameservers = [ 'ns1.logicboxes.com', 'ns2.logicboxes.com' ];
    my $domain      = create_domain(
        ns => $nameservers,
    );

    lives_ok {
        $logic_boxes->update_domain_nameservers(
            id          => $domain->id,
            nameservers => $nameservers,
        );
    } 'Lives through updating nameservers';

    my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );

    is_deeply( $retrieved_domain->ns, $nameservers, 'Correct nameservers' );
};

subtest 'Update Nameservers to Invalid Nameservers' => sub {
    my $valid_nameservers   = [ 'ns1.logicboxes.com', 'ns2.logicboxes.com' ];
    my $invalid_nameservers = [ map {
        'ns1.test-' . $_ . '.com', 'ns2.test-' . $_ . '.com'
    } ( random_string('nnccnnccnnccnnccnnccnnccnncc') ) ];

    my $domain = create_domain(
        ns => $valid_nameservers,
    );

    throws_ok {
        $logic_boxes->update_domain_nameservers(
            id          => $domain->id,
            nameservers => $invalid_nameservers,
        );
    } qr/Invalid nameservers provided/, 'Throws on invalid nameservers';

    my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );
    is_deeply( $retrieved_domain->ns, $valid_nameservers, 'Correct nameservers' );
};

subtest 'Update Nameservers to New Valid Nameservers' => sub {
    my $initial_nameservers = [ 'ns1.logicboxes.com', 'ns2.logicboxes.com' ];
    my $updated_nameservers = [ 'ns1.logicboxes.org', 'ns2.logicboxes.org' ];

    my $domain = create_domain(
        ns => $initial_nameservers,
    );

    lives_ok {
        $logic_boxes->update_domain_nameservers(
            id          => $domain->id,
            nameservers => $updated_nameservers,
        );
    } 'Lives through updating nameservers';

    my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );

    is_deeply( $retrieved_domain->ns, $updated_nameservers, 'Correct nameservers' );
};

done_testing;
