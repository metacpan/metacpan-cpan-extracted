use strict;
use warnings;
use Test::More;

# use Data::Dumper;
use SOAP::Lite;
use POSIX qw(strftime);

use WWW::Salesforce         ();
use WWW::Salesforce::Simple ();

plan skip_all => 'Skip live tests under $ENV{AUTOMATED_TESTING}'
    if ($ENV{AUTOMATED_TESTING});
plan skip_all =>
    'Set $ENV{SFDC_HOST}, $ENV{SFDC_CLIENT_ID}, and $ENV{SFDC_CLIENT_SECRET}'
    unless ($ENV{SFDC_HOST}
    && $ENV{SFDC_CLIENT_ID}
    && $ENV{SFDC_CLIENT_SECRET});

my $start_time = time();

diag "Running OAuth login tests with WWW::Salesforce version "
    . WWW::Salesforce->VERSION
    . " against "
    . $ENV{SFDC_HOST} . "\n";

# about to test oauth2 clientcredentials
diag "Testing OAuth2 client credentials flow\n";
my $has_cc = defined($ENV{SFDC_CC_CLIENT_ID})
    && length($ENV{SFDC_CC_CLIENT_ID})
    && defined($ENV{SFDC_CC_CLIENT_SECRET})
    && length($ENV{SFDC_CC_CLIENT_SECRET});

if ($has_cc) {
    #test -- new object/connection...
    my $sforce = WWW::Salesforce->login(
        serverurl => $ENV{SFDC_HOST},
        version => '64.0', # must be a string
        type => 'oauth2-clientcredentials',
        client_id => $ENV{SFDC_CC_CLIENT_ID},
        client_secret => $ENV{SFDC_CC_CLIENT_SECRET},
    );
    ok($sforce, "Login test") or BAIL_OUT($!);

    #test -- describeGlobal
    {
        my $res = $sforce->describeGlobal();
        ok($res, "describeGlobal") or reportFailureDetails($sforce, $res);
    }

    #test -- describeLayout
    {
        my $res = $sforce->describeLayout('type' => 'Account');
        ok($res, "describeLayout") or reportFailureDetails($sforce, $res);
    }

    #test -- describeSObject
    {
        my $res = $sforce->describeSObject('type' => 'Account');
        ok($res, "describeSObject") or reportFailureDetails($sforce, $res);
    }

    #test -- describeSObjects
    {
        my @types = qw(Account Lead Opportunity);
        my $res   = $sforce->describeSObjects('type' => \@types);
        ok($res, "describeSObjects: " . join(', ', @types))
            or reportFailureDetails($sforce, $res);
    }

    # tests -- describeTabs
    {
        my $passed = 0;

        #test -- describeTabs
        my $res = $sforce->describeTabs();
        $passed = 1 if ($res && $res->valueof('//result'));
        ok($passed, "describeTabs return") or reportFailureDetails($sforce, $res);

    SKIP: {
            skip("Can't check tabs results since describeTabs failed", 2)
                unless $passed;
            my @apps = $res->valueof('//result');
            ok($#apps > 1,                  "list of tab sets");
            ok(defined $apps[0]->{'label'}, "app has a label");
        }
    }

    #test -- getServerTimestamp
    {
        my $res = $sforce->getServerTimestamp();
        ok($res, "getServerTimestamp") or reportFailureDetails($sforce, $res);
    }

    #test -- getUserinfo
    {
        my $res = $sforce->getUserInfo();
        ok($res, "getUserInfo") or reportFailureDetails($sforce, $res);
    }

    #test -- query
    {
        my $res = $sforce->query('query' => 'select id from account', 'limit' => 5);
        ok($res, "query accounts") or reportFailureDetails($sforce, $res);

        #test -- queryMore
    SKIP: {
            my $locator = $res->valueof('//queryResponse/result/queryLocator')
                if $res;
            skip("No more results to queryMore for", 1) unless $locator;
            $res = $sforce->queryMore('queryLocator' => $locator, 'limit' => 5);
            ok($res, "queryMore accounts") or reportFailureDetails($sforce, $res);
        }
    }

    #test -- queryAll
    {
        my $res
            = $sforce->queryAll('query' => 'select id from account', 'limit' => 5);
        ok($res, "queryAll accounts") or reportFailureDetails($sforce, $res);

        #test -- queryMore against queryAll
    SKIP: {
            my $locator = $res->valueof('//queryAllResponse/result/queryLocator')
                if $res;
            skip("No more results to queryMore for", 1) unless $locator;
            $res = $sforce->queryMore('queryLocator' => $locator, 'limit' => 5);
            ok($res, "queryMore all accounts")
                or reportFailureDetails($sforce, $res);
        }
    }

    # test -- relation query
    {
        my $res = $sforce->query('query' =>
                'Select a.CreatedBy.Username, a.Name From Account a limit 2');
        my $passed = 0;
        $passed = 1
            if ($res
            && $res->valueof('//done') eq 'true'
            && $res->valueof('//size') eq '2'
            && $res->valueof('//records'));
        ok($passed, "relational query") or reportFailureDetails($sforce, $res);

        my @recs;
        @recs = $res->valueof('//records') if $passed;

        # test -- check expected structure of the relation query
        ok(
            defined($recs[0]->{'Name'})
                && defined($recs[0]->{'CreatedBy'}->{'Username'}),
            "relational query - first record check"
        );

        # test -- second check for expected structure
        ok(
            defined($recs[1]->{'Name'})
                && defined($recs[1]->{'CreatedBy'}->{'Username'}),
            "relational query - second record check"
        );
    }

    # test -- create a record
    {
        my $res
            = $sforce->create('type' => 'Account', 'Name' => 'foobar test account');
        my $passed = 0;
        $passed = 1
            if ($res
            && $res->valueof('//success') eq 'true'
            && defined($res->valueof('//id')));
        if ($passed) {
            pass("created an account");
        }
        else {
            fail("error creating account: '$!'");
            my $failureDetails = $sforce->getErrorDetails($res);
            diag "ERROR: $failureDetails->{message}";
            diag "CODE: $failureDetails->{statusCode}";
        }

    SKIP: {
            skip("can't update and delete new account since the creation failed", 2)
                unless $passed;

            #test -- update
            my $id = 0;
            $id  = $res->valueof('//id') if $passed;
            $res = $sforce->update(
                'type' => 'Account',
                'id'   => $id,
                'Name' => 'foobar test account updated'
            );
            $passed = 0;
            $passed = 1
                if ($res->valueof('//success') eq 'true'
                && defined($res->valueof('//id')));
            if ($passed) {
                pass("updated an account");
            }
            else {
                fail("error updating an account: '$!'");
                my $failureDetails = $sforce->getErrorDetails($res);
                diag "ERROR: $failureDetails->{message}";
                diag "CODE: $failureDetails->{statusCode}";
            }

            # test -- delete the account we just created and updated
            my @toDel = ($id);
            $res = $sforce->delete(@toDel);
            ok(
                $res->valueof('//success') eq 'true'
                    && defined($res->valueof('//id')),
                "delete account created"
            );
        }
    }

    # test -- create a lead and convert it to a contact
    {
        my $res = $sforce->create(
            'type' => 'Lead',
            'FirstName' => 'Foo',
            'LastName' => 'Bar',
            'Company' => 'Acme'
        );
        my $passed = 0;
        $passed = 1 if ($res && $res->valueof('//success') eq 'true' && defined($res->valueof('//id')));
        if ($passed) {
            pass("created a lead");
        }
        else {
            fail("error creating lead: '$!'");
            my $failureDetails = $sforce->getErrorDetails($res);
            diag "ERROR: $failureDetails->{message}";
            diag "CODE: $failureDetails->{statusCode}";
        }

    SKIP: {
            skip("can't convert lead since creation failed", 1) unless $passed;
            my $id = $res->valueof('//id');
            my $lead = $sforce->convertLead(
                'leadId' => $id,
                'doNotCreateOpportunity' => 'true',
                'overwriteLeadSource' => 'false',
                'sendNotificationEmail' => 'false'
            );
            ok($lead, "convertLead success") or reportFailureDetails($sforce, $lead);
        }
    }
}

sub reportFailureDetails {
    my ($sforce, $res) = @_;
    my $failureDetails = $sforce->getErrorDetails($res);
    diag "ERROR: $failureDetails->{message}";
    diag "CODE: $failureDetails->{statusCode}";
}
done_testing();
