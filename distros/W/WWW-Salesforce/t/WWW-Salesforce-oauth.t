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
    'Set $ENV{SFDC_HOST} $ENV{SFDC_USER}, $ENV{SFDC_PASS}, $ENV{SFDC_TOKEN}'
    unless ($ENV{SFDC_HOST}
    && $ENV{SFDC_USER}
    && $ENV{SFDC_PASS}
    && $ENV{SFDC_TOKEN}
    && $ENV{SFDC_CLIENT_ID}
    && $ENV{SFDC_CLIENT_SECRET});

my $start_time = time();

diag "Running OAuth login tests with WWW::Salesforce version "
    . WWW::Salesforce->VERSION
    . " against "
    . $ENV{SFDC_HOST} . "\n";

my $user = $ENV{SFDC_USER};
my $pass = $ENV{SFDC_PASS} . $ENV{SFDC_TOKEN};

#test -- new object/connection...
my $sforce = WWW::Salesforce->login(
    username  => $user,
    password  => $pass,
    serverurl => $ENV{SFDC_HOST},
    version => '64.0', # must be a string
    type => 'oauth2-usernamepassword',
    client_id => $ENV{SFDC_CLIENT_ID},
    client_secret => $ENV{SFDC_CLIENT_SECRET},
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
        'type'      => 'Lead',
        'FirstName' => 'conversion test',
        'LastName'  => 'lead',
        'Company'   => 'Acme Inc.',
    );
    my $passed = 0;
    $passed = 1
        if ($res
        && $res->valueof('//success') eq 'true'
        && defined($res->valueof('//id')));
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
        skip("can't convert and delete new lead since the creation failed", 2)
            unless $passed;

        #test -- update
        my $id = $res->valueof('//id');
        $res = $sforce->convertLead(
            'leadId'          => $id,
            'convertedStatus' => 'Closed - Converted',
        );
        $passed = 0;
        $passed = 1 if ($res->valueof('//success') eq 'true');
        if ($passed) {
            pass("converted a lead with id '$id'");
            $id = $res->valueof('//accountId');
        }
        else {
            fail("error converting a lead: '$!'");
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
            "delete account converted"
        );
    }
}

# test -- count accounts deleted since the test-run started
{
    my $res = $sforce->getDeleted(
        'type'  => 'Account',
        'start' => strftime("%Y-%m-%dT%H:%M:%S", gmtime($start_time)),
        'end'   => strftime("%Y-%m-%dT%H:%M:%S", gmtime(time() + 60))
        ,    # ensure that (end - start) > 1 minute
    );
    ok($res, "got count of deleted accounts");
}

# tests -- base64 doc files
{
    my $passed = 0;
    my $fid    = 0;
    my $docid  = 0;
    my $doc    = 0;

    # graphic (png) in a base64 string;
    my $image
        = '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';

    #test -- do the first query
    my $res = $sforce->query(
        'type'  => 'Document',
        'query' => "select id from Folder where Type = 'Document' "
    );

    ok($res, "Query for 'Document' folder id");
    my @results = $res->valueof('//queryResponse/result/records');
    $passed = 1 if @results;

    #test -- get folder id
SKIP: {
        skip("Can't get folder ID since the query failed", 1) unless $passed;

        # get the folder id and create an image body
        my $folder = $results[0];
        $fid = $folder->{'Id'}[0];
        ok($fid, "grab folder ID from previous query")
            or diag("Invalid folder ID");
    }

    #test -- create png document using above b64 string
SKIP: {
        skip("Can't create a document since I can't get the folder ID", 1)
            unless $fid;

        # create a new document using a b64 string
        $res = $sforce->create(
            'type'        => 'Document',
            'Name'        => 'imagetest.png',
            'Body'        => $image,
            'FolderId'    => $fid,
            'ContentType' => 'image/png',
            'Type'        => 'png',
            'IsPublic'    => 'true',
        );
        $docid = $res->valueof('//id')
            if ($res && $res->valueof('//success') eq 'true');
        ok($docid, "create new png document")
            or reportFailureDetails($sforce, $res);
    }

    #test -- query for the document ID
SKIP: {
        skip(
            "Can't query for the document we just tried to create because we couldn't determine the ID",
            1
        ) unless $docid;
        $res = $sforce->query(
            'type' => 'Document',
            'query' =>
                "select id,body from Document where Id = '$docid' limit 1"
        );
        $doc = $res->valueof('//records')
            if (defined($res->valueof('//records'))
            && $res->valueof('//size') eq '1');
        ok($doc, "query for document we just created")
            or reportFailureDetails($sforce, $res);
    }

    #test -- compare returned doc with original
SKIP: {
        skip("Can't compare doc because we couldn't query it", 1) unless $doc;
        ok($doc->{'Body'} eq $image, "compare document with original");
    }

    # test -- delete that image
SKIP: {
        skip("Can't delete image because it wasn't created properly", 1)
            unless $docid;
        my @toDel = ($docid);
        $res = $sforce->delete(@toDel);
        ok($res && $res->valueof('//success') eq 'true', "delete created image")
            or reportFailureDetails($sforce, $res);
    }
}

#tests -- create and mass update some contacts
{
    my $oneid  = 0;
    my $twoid  = 0;
    my $passed = 0;

    #test -- create an account
    my $res = $sforce->create('type' => 'Contact', 'LastName' => 'thing1');
    $oneid = $res->valueof('//id') if $res;
    ok($oneid, "multi-update - create first account to test against")
        or reportFailureDetails($sforce, $res);

    #test -- create another account
SKIP: {
        skip("No point creating a second account since the first failed", 1)
            unless $oneid;
        $res   = $sforce->create('type' => 'Contact', 'LastName' => 'thing2');
        $twoid = $res->valueof('//id') if $res;
        ok($twoid, "multi-update - create second account to test against")
            or reportFailureDetails($sforce, $res);
    }

    #test -- update the two accounts above
SKIP: {
        skip(
            "No point trying a multiple update since we couldn't create multiple contacts",
            1
        ) unless $oneid && $twoid;
        $res = $sforce->update(
            type => 'Contact',
            {id => $oneid, 'LastName' => 'thing3'},
            {id => $twoid, 'LastName' => 'thing4'}
        );
        $passed = 1 if ($res && $res->valueof('//success') eq 'true');
        ok($passed, "multi-update batch contacts")
            or reportFailureDetails($sforce, $res);
    }

    #test -- check the result set of the update above
SKIP: {
        skip("No results to check value of", 1) unless $passed;
        my @results = $res->valueof('//result');
        ok(defined($results[0]) && defined($results[1]) && $#results == 1,
            "multi-update batch results check");
    }

    #test -- cleanup the temp contact records
SKIP: {
        skip("no results to delete from the mult-update batch", 1)
            unless ($oneid || $twoid);
        if ($oneid && $twoid) {
            $res = $sforce->delete($oneid, $twoid);
        }
        elsif ($oneid) {
            $res = $sforce->delete($oneid);
        }
        else {
            $res = $sforce->delete($twoid);
        }
        ok($res && $res->valueof('//success') eq 'true',
            "multi-update batch deletion")
            or reportFailureDetails($sforce, $res);
    }
}


sub reportFailureDetails {
    my ($sforce, $res) = @_;
    my $failureDetails = $sforce->getErrorDetails($res);
    diag "ERROR: $failureDetails->{message}";
    diag "CODE: $failureDetails->{statusCode}";
}
done_testing();
