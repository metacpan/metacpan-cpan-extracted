# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

BEGIN {
    plan skip_all => "sandbox_config.json required for sandbox tests"
        unless -s 'sandbox_config.json';
}

use lib qw(lib t/lib);

use WebService::Braintree;
use WebService::Braintree::Test;
use WebService::Braintree::TestHelper qw(sandbox);

subtest 'accept()' => sub {
    subtest 'changes dispute status to accepted' => sub {
        my $txn_result = WebService::Braintree::Transaction->sale({
            amount => amount(80, 120),
            credit_card => credit_card({
                number => cc_number('dispute'),
                expiration_date => '01/2020',
            }),
        });
        validate_result($txn_result, 'Sale w/dispute created') or return;
        my $txn = $txn_result->transaction;
        my $dispute = $txn->disputes->[0];

        # Needed to test remove_evidence() from a non-open dispute
        my $add_result = WebService::Braintree::Dispute->add_text_evidence(
            $dispute->id, 'text evidence',
        );
        validate_result($add_result) or return;
        my $evidence = $add_result->evidence;

        my $acc_result = WebService::Braintree::Dispute->accept($dispute->id);
        validate_result($acc_result, 'Accept() successful') or return;

        my $refreshed = WebService::Braintree::Dispute->find($dispute->id);
        validate_result($refreshed) or return;
        is($refreshed->dispute->status, WebService::Braintree::Dispute::Status::Accepted);

        subtest 'cannot accept() an accepted dispute' => sub {
            my $fail_result = WebService::Braintree::Dispute->accept($dispute->id);
            invalidate_result($fail_result) or return;

            is($fail_result->errors->for('dispute')->on('status')->[0]->code, WebService::Braintree::ErrorCodes::Dispute::CanOnlyAcceptOpenDispute, 'Correct code');
            is($fail_result->errors->for('dispute')->on('status')->[0]->message, "Disputes can only be accepted when they are in an Open state", 'Correct message');
        };

        subtest 'cannot add_text_evidence() to an accepted dispute' => sub {
            my $fail_result = WebService::Braintree::Dispute->add_text_evidence($dispute->id, 'text evidence');
            invalidate_result($fail_result) or return;

            is($fail_result->errors->for('dispute')->on('status')->[0]->code, WebService::Braintree::ErrorCodes::Dispute::CanOnlyAddEvidenceToOpenDispute, 'Correct code');
            is($fail_result->errors->for('dispute')->on('status')->[0]->message, "Evidence can only be attached to disputes that are in an Open state", 'Correct message');
        };

        subtest 'cannot remove_evidence() from an accepted dispute' => sub {
            my $fail_result = WebService::Braintree::Dispute->remove_evidence($dispute->id, $evidence->id);
            invalidate_result($fail_result) or return;

            is($fail_result->errors->for('dispute')->on('status')->[0]->code, WebService::Braintree::ErrorCodes::Dispute::CanOnlyRemoveEvidenceFromOpenDispute, 'Correct code');
            is($fail_result->errors->for('dispute')->on('status')->[0]->message, "Evidence can only be removed from disputes that are in an Open state", 'Correct message');
        };
    };

    subtest 'raises a NotFound exception if not found' => sub {
        should_throw NotFound => sub {
            WebService::Braintree::Dispute->accept('invalid-id');
        };
    };
};

subtest 'finalize()' => sub {
    subtest 'changes dispute status to disputed' => sub {
        my $txn_result = WebService::Braintree::Transaction->sale({
            amount => amount(80, 120),
            credit_card => credit_card({
                number => cc_number('dispute'),
                expiration_date => '01/2020',
            }),
        });
        validate_result($txn_result, 'Sale w/dispute created') or return;
        my $txn = $txn_result->transaction;
        my $dispute = $txn->disputes->[0];

        my $fin_result = WebService::Braintree::Dispute->finalize($dispute->id);
        validate_result($fin_result, 'Finalize() successful') or return;

        my $refreshed = WebService::Braintree::Dispute->find($dispute->id);
        validate_result($refreshed) or return;
        is($refreshed->dispute->status, WebService::Braintree::Dispute::Status::Disputed);

        subtest 'cannot finalize() a non-open dispute' => sub {
            my $fail_result = WebService::Braintree::Dispute->finalize($dispute->id);
            invalidate_result($fail_result) or return;

            is($fail_result->errors->for('dispute')->on('status')->[0]->code, WebService::Braintree::ErrorCodes::Dispute::CanOnlyFinalizeOpenDispute, 'Correct code');
            is($fail_result->errors->for('dispute')->on('status')->[0]->message, "Disputes can only be finalized when they are in an Open state", 'Correct message');
        };
    };

    subtest 'raises a NotFound exception if not found' => sub {
        should_throw NotFound => sub {
            WebService::Braintree::Dispute->accept('invalid-id');
        };
    };
};

subtest 'add_file_evidence()' => sub {
    plan skip_all => 'tests for add_file_evidence() requires DocumentUpload';
};

subtest 'text evidence (add and remove)' => sub {
    my $txn_result = WebService::Braintree::Transaction->sale({
        amount => amount(80, 120),
        credit_card => credit_card({
            number => cc_number('dispute'),
            expiration_date => '01/2020',
        }),
    });
    validate_result($txn_result, 'Sale w/dispute created') or return;
    my $txn = $txn_result->transaction;
    my $dispute = $txn->disputes->[0];

    my $add_result = WebService::Braintree::Dispute->add_text_evidence(
        $dispute->id, 'text evidence',
    );
    validate_result($add_result) or return;

    my $evidence = $add_result->evidence;
    is($evidence->comment, 'text evidence');
    like($evidence->id, qr/^\w{16,}$/);
    is($evidence->sent_to_processor_at, undef);
    is($evidence->url, undef);

    my $refreshed = WebService::Braintree::Dispute->find($dispute->id);
    validate_result($refreshed) or return;
    my $expected_evidence = $refreshed->dispute->evidence->[0];
    ok($expected_evidence);
    is($expected_evidence->comment, 'text evidence');

    my $rem_result = WebService::Braintree::Dispute->remove_evidence(
        $dispute->id, $evidence->id,
    );
    validate_result($rem_result) or return;

    my $refreshed2 = WebService::Braintree::Dispute->find($dispute->id);
    validate_result($refreshed2) or return;
    my $removed_evidence = $refreshed2->dispute->evidence->[0];
    ok(!$removed_evidence);

    subtest 'adding raises a NotFound exception if not found' => sub {
        should_throw NotFound => sub {
            WebService::Braintree::Dispute->add_text_evidence('invalid', 'x');
        };
    };

    subtest 'removing raises a NotFound exception if not found' => sub {
        should_throw NotFound => sub {
            WebService::Braintree::Dispute->remove_evidence('invalid', 'x');
        };
    };
};

subtest search => sub {
    subtest 'Not found' => sub {
        my $collection = perform_search(Dispute => {
            id => 'non_existent_dispute',
        });

        cmp_ok(count($collection), '==', 0, 'Nothing found for fake id');
    };

    subtest 'Find a transaction' => sub {
        my $txn_result = WebService::Braintree::Transaction->sale({
            amount => amount(80, 120),
            credit_card => credit_card({
                number => cc_number('dispute'),
                expiration_date => '01/2020',
            }),
        });
        validate_result($txn_result, 'Sale w/dispute created') or return;
        my $txn = $txn_result->transaction;
        my $dispute = $txn->disputes->[0];

        my $by_status = perform_search(Dispute => {
            status => WebService::Braintree::Dispute::Status::Open,
        });

        cmp_ok(count($by_status), '>=', 1, 'Found at least 1 open txn');
    };
};

sub count {
    my $collection = shift;
    my $c = 0;
    $collection->each(sub { $c++; });
    return $c;
}

done_testing;
