# ABSTRACT: Provides an interface to TestLink's XMLRPC api via HTTP
# PODNAME: TestLink::API

package TestLink::API;
$TestLink::API::VERSION = '0.011';

use 5.010;
use strict;
use warnings;
use Carp;
use Scalar::Util qw{reftype looks_like_number}; #boo, some functions return hashes and arrays depending on # of results (1 or many)
use Data::Validate::URI 'is_uri';

use Clone 'clone';

use XMLRPC::Lite;


sub new {
    my ($class,$apiurl,$apikey) = @_;
    confess("Constructor must be called statically, not by an instance") if ref($class);
    $apiurl ||= $ENV{'TESTLINK_SERVER_ADDR'};
    $apikey ||= $ENV{'TESTLINK_API_KEY'};

    confess("No API key provided.") if !$apiurl;
    confess("No API URL provided.") if !$apikey;
    confess("API URL provided not valid.") unless is_uri($apiurl);

    my $self = {
        apiurl           => $apiurl,
        apikey           => $apikey,
        testtree         => [],
        flattree         => [],
        invalidate_cache => 1 #since we don't have a cache right now... #TODO this should be granular down to project rather than global
    };

    bless $self, $class;
    return $self;
}


#EZ get/set of obj vars
sub AUTOLOAD {
    my %public_elements = map {$_,1} qw{apiurl apikey}; #Public element access
    our $AUTOLOAD;

    if ($AUTOLOAD =~ /::(\w+)$/ and exists $public_elements{$1} ) {
        my $field = $1;
        {
            no strict 'refs';
            *{$AUTOLOAD} = sub {
                confess("Object parameters must be called by an instance") unless ref($_[0]);
                return $_[0]->{$field} unless defined $_[1];
                $_[0]->{$field} = $_[1];
                return $_[0];
            };
        }
        goto &{$AUTOLOAD};
    }
    confess("$AUTOLOAD not accessible property") unless $AUTOLOAD =~ /DESTROY$/;
}


sub createTestPlan {
    my ($self,$name,$project,$notes,$active,$public) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    confess("Desired Test Plan Name is a required argument (0th).") if !$name;
    confess("Parent Project Name is a required argument (1st).") if !$project;

    $notes  ||= 'res ipsa loquiter';
    $active ||= 1;
    $public ||= 1;

    my $input = {
        devKey          => $self->apikey,
        testplanname    => $name,
        testprojectname => $project,
        notes           => $notes,
        active          => $active,
        public         => $public
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.createTestPlan',$input);
    warn $result->result->[0]->{'message'} if $result->result->[0]->{'code'};
    return $result->result->[0]->{'id'} if $result->result->[0]->{'id'};
    return 0;
}


sub createBuild {
    my ($self,$plan_id,$name,$notes) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    confess("Plan ID must be integer") unless looks_like_number($plan_id);
    confess("Build name is a required argument (1st)") if !$name;
    $notes  ||= 'res ipsa loquiter';

    my $input = {
        devKey     => $self->apikey,
        testplanid => $plan_id,
        buildname  => $name,
        buildnotes => $notes
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.createBuild',$input);
    warn $result->result->[0]->{'message'} if $result->result->[0]->{'code'};
    return $result->result->[0]->{'id'} if $result->result->[0]->{'id'};
    return 0;
}


sub createTestSuite {
    my ($self,$project_id,$name,$details,$parent_id,$order) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    confess("Parent Project ID (arg 0) must be an integer") unless looks_like_number($project_id);
    confess("Name (arg 1) cannot be undefined") unless $name;

    $details ||= 'res ipsa loquiter';
    $order ||= -1;

    my $input = {
        devKey        => $self->apikey,
        testprojectid => $project_id,
        testsuitename => $name,
        details       => $details,
        parentid      => $parent_id,
        order         => $order
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.createTestSuite',$input);
    warn $result->result->[0]->{'message'} if $result->result->[0]->{'code'};
    $self->{'invalidate_cache'} = 1 if $result->result->[0]->{'id'};
    return $result->result->[0]->{'id'} if $result->result->[0]->{'id'};
    return 0;
}


#XXX probably should not use
sub createTestProject {
    my ($self,$name,$case_prefix,$notes,$options,$active,$public) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    $notes   //= 'res ipsa loquiter';
    $options //= {};
    $public  //= 1;
    $active  //= 1;

    my $input = {
        devKey          => $self->apikey,
        testprojectname => $name,
        testcaseprefix  => $case_prefix,
        notes           => $notes,
        options         => $options,
        active          => $active,
        public          => $public
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.createTestProject',$input);
    #XXX i'm being very safe (haha), there's probably a better check
    warn $result->result->[0]->{'message'} if $result->result->[0]->{'code'};
    $self->{'invalidate_cache'} = 1 if $result->result->[0]->{'id'};
    return $result->result->[0]->{'id'} if $result->result->[0]->{'id'};
    return 0;

}


sub createTestCase {
    my ($self,$test_name,$test_suite_id,$test_project_id,$author_name,$summary,$steps,$preconditions,$execution,$order) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    my $input = {
        devKey        => $self->apikey,
        testcasename  => $test_name,
        testsuiteid   => $test_suite_id,
        testprojectid => $test_project_id,
        authorlogin   => $author_name,
        summary       => $summary,
        steps         => $steps,
        preconditions => $preconditions,
        execution     => $execution,
        order         => $order
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.createTestCase',$input);
    #XXX i'm being very safe (haha), there's probably a better check
    warn $result->result->[0]->{'message'} if $result->result->[0]->{'code'};
    return $result->result->[0] if $result->result->[0]->{'id'};
    return 0;

}


sub reportTCResult {
    my ($self,$case_id,$plan_id,$build_id,$status,$platform,$notes,$bugid) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    my $input = {
        devKey     => $self->apikey,
        testcaseid => $case_id,
        testplanid => $plan_id,
        buildid    => $build_id,
        status     => $status,
        notes      => $notes,
        bugid      => $bugid
    };

    if (defined($platform) && !ref $platform) {
        if (looks_like_number($platform)) {
            $input->{'platformid'} = $platform;
        } else {
            $input->{'platformname'} = $platform;
        }
    }

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.reportTCResult',$input);
    warn $result->result->[0]->{'message'} if $result->result->[0]->{'code'};
    return $result->result->[0] unless $result->result->[0]->{'code'};
    return 0;
}


#XXX this should be able to be done in batch
sub addTestCaseToTestPlan {
    my ($self,$plan_id,$case_id,$project_id,$version,$platform,$order,$urgency) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    my $input = {
        devKey             => $self->apikey,
        testplanid         => $plan_id,
        testcaseexternalid => $case_id,
        testprojectid      => $project_id,
        version            => $version,
        platformid         => $platform,
        executionorder     => $order,
        urgency            => $urgency
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.addTestCaseToTestPlan',$input);
    warn $result->result->{'message'} if $result->result->{'code'};
    return 1 unless $result->result->{'code'};
    return 0;
}


sub uploadExecutionAttachment {
   my ($self,$execution_id,$filename,$filetype,$content,$title,$description) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    my $input = {
        devKey      => $self->apikey,
        executionid => $execution_id,
        title       => $title,
        description => $description,
        filename    => $filename,
        filetype    => $filetype,
        content     => $content
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.uploadExecutionAttachment',$input);
    warn $result->result->{'message'} if $result->result->{'code'};
    return 1 unless $result->result->{'code'};
    return 0;
}


sub uploadTestCaseAttachment {
   my ($self,$case_id,$filename,$filetype,$content,$title,$description) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    my $input = {
        devKey      => $self->apikey,
        testcaseid  => $case_id,
        title       => $title,
        description => $description,
        filename    => $filename,
        filetype    => $filetype,
        content     => $content
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.uploadTestCaseAttachment',$input);
    warn $result->result->[0]->{'message'} if $result->result->[0]->{'code'};
    return 1 unless $result->result->[0]->{'code'};
    return 0;
}



sub getProjects {
    my $self = shift;
    confess("Object parameters must be called by an instance") unless ref($self);

    my $input = {
        devKey     => $self->apikey
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.getProjects',$input);
    warn $result->result->[0]->{'message'} if $result->result->[0]->{'code'};

    #Save state for future use, if needed
    if (!scalar(@{$self->{'testtree'}})) {
        $self->{'testtree'} = $result->result unless $result->result->[0]->{'code'};
    }

   if (!exists($result->result->[0]->{'code'})) {
        #Note that it's a project for future reference by recursive tree search
        for my $pj (@{$result->result}) {
            $pj->{'type'} = 'project';
        }
        return $result->result;
    }

    return 0;
}


sub getProjectByName {
    my ($self,$project) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    confess "No project provided." unless $project;

    #See if we already have the project list...
    my $projects = $self->{'testtree'};
    $projects = $self->getProjects() unless scalar(@$projects);

    #Search project list for project
    for my $candidate (@$projects) {
        return $candidate if ($candidate->{'name'} eq $project);
    }

    return 0;
}


sub getProjectByID {
    my ($self,$project) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    confess "No project provided." unless $project;

    #See if we already have the project list...
    my $projects = $self->{'testtree'};
    $projects = $self->getProjects() unless scalar(@$projects);

    #Search project list for project
    for my $candidate (@$projects) {
        return $candidate if ($candidate->{'id'} eq $project);
    }

    return 0;
}



sub getTLDTestSuitesForProject {
    my ($self,$project,$get_tests) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    confess "No project ID provided." unless $project;

    my $input = {
        devKey        => $self->apikey,
        testprojectid => $project
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.getFirstLevelTestSuitesForTestProject',$input);

    #Error condition, return right away
    warn $result->result->[0]->{'message'} if $result->result->[0]->{'code'};
    return [] if $result->result->[0]->{'code'};

    #Handle bizarre output
    if ($result->result && !(reftype($result->result) eq 'HASH' || reftype($result->result) eq 'ARRAY')) {
        return [];
    }
    return [] if !$result->result;

    #Handle mixed return type for this function -- this POS will return arrayrefs, and 2 types of hashrefs.
    my $res = [];
    $res = $result->result if reftype($result->result) eq 'ARRAY';
    @$res = values(%{$result->result}) if reftype($result->result) eq 'HASH' && !defined($result->result->{'id'});
    $res = [$result->result] if reftype($result->result) eq 'HASH' && defined($result->result->{'id'});
    return [] if (!scalar(keys(%{$res->[0]}))); #Catch bizarre edge case of blank hash being only thing there

    if ($get_tests) {
        for (my $i=0; $i < scalar(@{$result->result}); $i++) {
            $result->result->[$i]->{'tests'} = $self->getTestCasesForTestSuite($result->result->[$i]->{'id'},0,1);
        }
    }

    return $result->result;
}


sub getTestSuitesForTestSuite {
    my ($self,$tsid,$get_tests) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    confess "No TestSuite ID provided." unless $tsid;

    my $input = {
        devKey        => $self->apikey,
        testsuiteid => $tsid
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.getTestSuitesForTestSuite',$input);

    #Handle bizarre output
    if ($result->result && !(reftype($result->result) eq 'HASH' || reftype($result->result) eq 'ARRAY')) {
        return [];
    }
    return [] if !$result->result;

    #Handle mixed return type for this function -- this POS will return arrayrefs, and 2 types of hashrefs.
    my $res = [];
    $res = $result->result if reftype($result->result) eq 'ARRAY';
    @$res = values(%{$result->result}) if reftype($result->result) eq 'HASH' && !defined($result->result->{'id'});
    $res = [$result->result] if reftype($result->result) eq 'HASH' && defined($result->result->{'id'});

    if ($get_tests) {
        foreach my $row (@$res) {
            $row->{'tests'} = $self->getTestCasesForTestSuite($row->{'id'},0,1);
        }
    }

    #Error condition, return false and don't bother searching arrays
    warn $res->{'message'} if $res->[0]->{'code'};
    return [] if $res->[0]->{'code'};
    return $res;
}



sub getTestSuitesByName {
    my ($self,$project_id,$testsuite_name,$do_regex) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    return 0 if (!$project_id || !$testsuite_name); #GIGO

    #use caching methods here to speed up subsequent calls
    $self->_cacheProjectTree($project_id,1,1,0) if $self->{'invalidate_cache'};

    #my $tld = $self->getTLDTestSuitesForProject($project_id);
    my $candidates = [];

    #Walk the whole tree.  No other way to be sure.
    foreach my $ts (@{$self->{'flattree'}}) {
        if ($do_regex) {
            push(@$candidates,$ts) if $ts->{'name'} =~ $testsuite_name;
        } else {
            push(@$candidates,$ts) if $ts->{'name'} eq $testsuite_name;
        }
    }
    return $candidates;

}


sub getTestSuiteByID {
    my ($self,$testsuite_id) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    my $input = {
        devKey      => $self->apikey,
        testsuiteid => $testsuite_id
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.getTestSuiteByID',$input);
    warn $result->result->{'message'} if $result->result->{'code'};
    return $result->result unless $result->result->{'code'};
    return 0;
}


sub getTestCasesForTestSuite {
    my ($self,$testsuite_id,$deep,$details) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    $details = 'full' if $details;

    my $input = {
        devKey      => $self->apikey,
        testsuiteid => $testsuite_id,
        deep        => $deep,
        details     => $details
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.getTestCasesForTestSuite',$input);
    return [] if !$result->result;

    return [] if !scalar(keys(%{$result->result->[0]})); # No tests

    warn $result->result->[0]->{'message'} if $result->result->[0]->{'code'};
    return $result->result unless $result->result->[0]->{'code'};
    return [];
}


sub getTestCaseByExternalId {
    my ($self,$case_id,$version) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    my $input = {
        devKey             => $self->apikey,
        testcaseexternalid => $case_id,
        version            => $version
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.getTestCase',$input);
    warn $result->result->[0]->{'message'} if $result->result->[0]->{'code'};
    return $result->result->[0] unless $result->result->[0]->{'code'};
    return 0;
}


sub getTestCaseById {
    my ($self,$case_id,$version) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    my $input = {
        devKey     => $self->apikey,
        testcaseid => $case_id,
        version    => $version
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.getTestCase',$input);
    warn $result->result->[0]->{'message'} if $result->result->[0]->{'code'};
    return $result->result->[0] unless $result->result->[0]->{'code'};
    return 0;
}


sub getTestCaseByName {
    my ($self, $casename, $suitename, $projectname, $testcasepathname) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    my $input = {
        devKey           => $self->apikey,
        testcasename     => $casename,
        testsuitename    => $suitename,
        testprojectname  => $projectname,
        testcasepathname => $testcasepathname
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.getTestCaseIDByName',$input);
    warn $result->result->[0]->{'message'} if $result->result->[0]->{'code'};
    return $result->result->[0] unless $result->result->[0]->{'code'};
    return 0;
}


sub getTestCaseAttachments {
    my ($self, $case_ext_id) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    my $input = {
        devKey     => $self->apikey,
        testcaseexternalid => $case_ext_id,
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.getTestCaseAttachments',$input);
    return 0 if (!$result->result);
    warn $result->result->[0]->{'message'} if $result->result->[0]->{'code'};
    return $result->result->[0] unless $result->result->[0]->{'code'};
    return 0;
}


sub getTestPlansForProject {
    my ($self,$project_id) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    my $input = {
        devKey        => $self->apikey,
        testprojectid => $project_id
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.getProjectTestPlans',$input);
    warn $result->result->[0]->{'message'} if $result->result->[0]->{'code'};
    return $result->result unless $result->result->[0]->{'code'};
    return 0;
}


# I find it highly bizarre that the only 'by name' method exists for test plans, and it's the only test plan getter.
sub getTestPlanByName {
    my ($self,$plan_name,$project_name) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    my $input = {
        devKey          => $self->apikey,
        testplanname    => $plan_name,
        testprojectname => $project_name
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.getTestPlanByName',$input);
    warn $result->result->[0]->{'message'} if $result->result->[0]->{'code'};
    return $result->result->[0] unless $result->result->[0]->{'code'};
    return 0;
}


sub getBuildsForTestPlan {
    my ($self,$plan_id) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    my $input = {
        devKey          => $self->apikey,
        testplanid      => $plan_id
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.getBuildsForTestPlan',$input);
    warn $result->result->[0]->{'message'} if $result->result->[0]->{'code'};
    return $result->result unless $result->result->[0]->{'code'};
    return 0;
}


sub getTestCasesForTestPlan {
   my ($self,$plan_id) = @_;
   confess("Object parameters must be called by an instance") unless ref($self);

    my $input = {
        devKey          => $self->apikey,
        testplanid      => $plan_id
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.getTestCasesForTestPlan',$input);
    warn $result->result->{'message'} if $result->result->{'code'};
    return $result->result unless $result->result->{'code'};
    return 0;
}


sub getLatestBuildForTestPlan {
    my ($self,$plan_id) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    my $input = {
        devKey     => $self->apikey,
        tplanid    => $plan_id, #documented arg, but that's LIES, apparently it wants the next one
        testplanid => $plan_id
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.getLatestBuildForTestPlan',$input);

    #Handle mixed return type
    my $res = $result->result;
    $res = [$res] if reftype($res) eq 'HASH';

    warn $res->[0]->{'message'} if $res->[0]->{'code'};
    return $res->[0] unless $res->[0]->{'code'};
    return 0;
}


#TODO cache stuff, don't require proj id?
sub getBuildByName {
    my ($self,$build_name,$project_id) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    my $plans = $self->getTestPlansForProject($project_id);
    for my $plan (@$plans) {
        my $builds = $self->getBuildsForTestPlan($plan->{'id'});
        for my $build (@$builds) {
            return $build if $build->{'name'} eq $build_name;
        }
    }
    return 0;
}


sub getTotalsForTestPlan {
    my ($self,$plan_id) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    my $input = {
        devKey     => $self->apikey,
        tplanid    => $plan_id, #documented arg, but that's LIES, apparently it wants the next one
        testplanid => $plan_id
    };

    my $rpc = XMLRPC::Lite->proxy($self->apiurl);
    my $result = $rpc->call('tl.getTotalsForTestPlan',$input);

    warn $result->result->{'message'} if $result->result->{'code'};
    return $result->result unless $result->result->{'code'};
    return 0;
}


sub dump {
    my ($self,$project,$attachment,$flat) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    confess("Getting attachments not yet implemented") if $attachment;

    my $res = $self->_cacheProjectTree($project,$flat);
    return [] if !$res;

    return $res if !$project || $flat;
    foreach my $pj (@{$res}) {
        return $pj if $pj->{'name'} eq $project;
    }
    croak "COULD NOT DUMP, SOMETHING HORRIBLY WRONG";
}

sub _cacheProjectTree {
    my ($self,$project,$flat,$use_project_id,$get_tests) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    $flat //= 0;
    $use_project_id //= 0;
    $get_tests //= 1;

    #Cache Projects
    if (!scalar(@{$self->{'testtree'}})) {
        $self->getProjects();
    }

    my @flattener = @{$self->{'testtree'}};

    for my $projhash (@flattener) {
        if ($use_project_id) {
            next if $project && $project ne $projhash->{'id'} && (defined($projhash->{'type'}) && $projhash->{'type'} eq 'project');
        } else {
            next if $project && $project ne $projhash->{'name'} && (defined($projhash->{'type'}) && $projhash->{'type'} eq 'project');
        }

        #If TestSuites are not defined, this must be a TS which we have not traversed yet, so go and get it
        if (exists($projhash->{'type'}) && $projhash->{'type'} eq 'project') {
            $projhash->{'testsuites'} = $self->getTLDTestSuitesForProject($projhash->{'id'},$get_tests);
        } else {
            $projhash->{'testsuites'} = $self->getTestSuitesForTestSuite($projhash->{'id'},$get_tests);
        }

        $projhash->{'testsuites'} = [] if !$projhash->{'testsuites'};
        for my $tshash (@{$projhash->{'testsuites'}}) {
            #Otherwise, push it's children to the end of our array so we can recurse as needed.
            #I hope the designers of TL's schema were smart enough to not allow self-referential or circular suites..
            push(@flattener,clone $tshash);
        }

    }

    #Keep this for simple searches in the future.
    $self->{'flattree'} = clone \@flattener;
    return $self->{'flattree'} if $flat;
    return $self->_expandTree($project,@flattener);
}

sub _expandTree {
    my $self = shift;
    confess("Object parameters must be called by an instance") unless ref($self);
    my $project = shift;
    my @flattener = @_;
    #The following algorithm relies implicitly on pass-by-reference.
    #So we have a flat array of testsuites we want to map into parent-child relationships.
    my ($i,$j);
    foreach my $suite (@flattener) {
        if (defined($suite->{'type'}) && $suite->{'type'} eq 'project') {
            #Then skip it, since it's not a suite.
            shift @flattener;
            next;
        }

        #This means we need to walk the hierarchy of every project, or just the one we passed
        for ($j=0; $j < scalar(@{$self->{'testtree'}}); $j++) {
            #If we have a project, skip the other ones
            next unless $project && $self->{'testtree'}->[$j]->{'name'} eq $project;

            #Get the ball rolling if we have to
            $self->{'testtree'}->[$j]->{'testsuites'} = $self->getTLDTestSuitesForProject($self->{'testtree'}->[$j]->{'id'},1) if !defined($self->{'testtree'}->[$j]->{'testsuites'});

            #So, let's tail recurse over the testsuites.
            for ($i=0; $i < scalar(@{$self->{'testtree'}->[$j]->{'testsuites'}}); $i++) {
                my $tailRecurseTSWalker = sub  {
                    my ($ts,$desired_ts) = @_;

                    #Mark it down if we found it
                    if ($ts->{'id'} eq $desired_ts->{'parent_id'}) {

                        #Set the REF's 'testsuites' param, and quit searching
                        $ts->{'testsuites'} = [] if !defined($ts->{'testsuites'});
                        push(@{$ts->{'testsuites'}},$desired_ts);
                        $desired_ts->{'found'} = 1;
                        return;
                    }

                    #If there's already (nonblank) hierarchy in the passed TS, then WE HAVE TO GO DEEPER
                    if (defined($ts->{'testsuites'}) && scalar(@{$desired_ts->{'testsuites'}})) {
                        for (my $i=0; $i < scalar(@{$ts->{'testsuites'}}); $i++) {
                            _tailRecurseTSWalker($ts->{'testsuites'}->[$i],$desired_ts);
                        }
                    }

                    return;
                };

                &$tailRecurseTSWalker($self->{'testtree'}->[$j]->{'testsuites'}->[$i],$suite);
                #OPTIMIZE: break out if we found it already
                last if $suite->{'found'};
            }
            last if $suite->{'found'};
        }

        #If we didn't find this one yet, as the hierarchy build is progressive, add it to the end until it gets picked up.
        if (!$suite->{'found'}) {
            push(@flattener,shift @flattener); # If it wasn't found, push it on to the end of the array so the walk might find it next time.
        } else {
            shift @flattener;
        }
    }
    return $self->{'testtree'};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TestLink::API - Provides an interface to TestLink's XMLRPC api via HTTP

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use TestLink::API;

    my $tl = TestLink::API->new('http://tl.test/testlink/lib/api/xmlrpc/v1/xmlrpc.php', 'gobbledygook123');

    #Look up test definitions
    my $projects = $tl->getProjects();
    my $suites = $tl->getTLDTestSuitesForProject($projects->[0]->{'id'});
    my $childsuites = $tl->getTestSuitesForTestSuite($suites->[0]->{'id'});
    my $tests = $tl->getTestCasesForTestSuite($childsuites->[0]->{'id'});

    #Look up test plans/builds
    my $plans = $tl->getTestPlansForProject($projects->[0]->{'id'});
    my $tests2 = $tl->getTestCasesForTestPlan($plans->[0]->{'id'});
    my $builds = $tl->getBuildsForTestPlan($plans->[0]->{'id'});

    #Set results
    my $testResults = doSomethingReturningBoolean();
    my $results = $tl->reportTCResult($tests2->[0]->{'id'},$plans->[0]->{'id'},$builds->[0]->{'id'}, $testResults ? 'p' : 'f');
    $tl->uploadExecutionAttachment($results->{'id'},'test.txt','text/plain',encode_base64('MOO MOO MOOOOOO'),'bovine emissions','whee')

=head1 DESCRIPTION

C<TestLink::API> provides methods to access an existing TestLink account.  You can then do things like look up tests, set statuses and create builds from lists of tests.
The getter methods cache the test tree up to whatever depth is required by your getter calls.  This is to speed up automated creation/reading/setting of the test db based on existing automated tests.
Cache expires at the end of script execution. (TODO use memcached controlled by constructor, with create methods invalidating cache?)
Getter/setter methods that take args assume that the relevant project/testsuite/test/plan/build provided exists (TODO: use cache to check exists, provide more verbose error reason...), and returns false if not.
Create methods assume desired entry provided is not already in the DB (TODO (again): use cache to check exists, provide more verbose error reason...), and returns false if not.
It is by no means exhaustively implementing every TestLink API function.  Designed with TestLink 1.9.9, but will likely work on (some) other versions.

=head1 CONSTRUCTOR

=head2 B<new (api_url, key)>

Creates new C<TestLink::API> object.

=over 4

=item C<API URL> - URL to your testlink API endpoint.

=item C<KEY> - TestLink API key.

=back

Returns C<TestLink::API> object if login is successful.

    my $tl = TestLink::API->new('http://tl.test/testlink/lib/api/xmlrpc/v1/xmlrpc.php', 'gobbledygook123');

=head1 PROPERTIES

=over 4

apiurl and apikey can be accessed/set:

$url = $tl->apiurl;
$tl = $tl->apiurl('http//some.new.url/foo.php');

=back

=head1 CREATE METHODS

=head2 B<createTestPlan (name, project, [notes, active, public])>

Creates new Test plan with given name in the given project.

=over 4

=item STRING C<NAME> - Desired test plan name.

=item STRING C<PROJECT> - The name of some project existing in TestLink.

=item STRING C<NOTES> (optional) - Additional description of test plan.  Default value is 'res ipsa loquiter'

=item BOOLEAN C<ACTIVE> (optional) - Whether or not the test plan is active.  Default value is true.

=item BOOLEAN C<PUBLIC> (optional) - Whether or not the test plan is public.  Default is true.

=back

Returns (integer) test plan ID if creation is successful.

    my $tpid = $tl->createTestPlan('shock&awe', 'enduringfreedom');

=head2 B<createBuild (test_plan_id, name, [notes])>

Creates new 'Build' (test run in common parlance) from given test plan having given name and notes.

=over 4

=item INTEGER C<TEST PLAN ID> - ID of test plan to base test run on.

=item STRING C<NAME> - Desired name for test run.

=item STRING C<NOTES> (optional) - Additional description of run.  Default value is 'res ipsa loquiter'.

=back

Returns true if case addition is successful, false otherwise.

    $tl->createBuild(1234, "Bossin' up", 'Crushing our enemies, seeing them driven before us and hearing the lamentations of their support engineers.');

=head2 B<createTestSuite (project_id, name, [details, parent_testsuite_id, order])>

Creates new TestSuite (folder of tests) in the database of test specifications under given project id having given name and details.
Optionally, can have a parent test suite (this is an analog to a hierarchical file tree after all) and what order to have this suite be amongst it's peers.

=over 4

=item INTEGER C<PROJECT ID> - ID of project this test suite should be under.

=item STRING C<NAME> - Desired name of test suite.

=item STRING C<DETAILS> (optional) - Description of test suite.  Default value is 'res ipsa loquiter'.

=item INTEGER C<PARENT TESTSUITE ID> (optional) - Parent test suite ID.  Defaults to top level of project.

=item INTEGER C<ORDER> (optional) - Desired order amongst peer testsuites.  Defaults to last in list.

=back

Returns (integer) build ID on success, false otherwise.

    $tl->createTestSuite(1, 'broken tests', 'Tests that should be reviewed', 2345, -1);

=head2 B<createTestProject (name, case_prefix, [notes, options, active, public])>

Creates new Project (Database of testsuites/tests) with given name and case prefix.
Optionally, can have notes, options, set the project as active/inactive and public/private.

=over 4

=item STRING C<NAME> - Desired name of project.

=item STRING C<CASE PREFIX> - Desired prefix of project's external test case IDs.

=item STRING C<NOTES> (optional) - Description of project.  Default value is 'res ipsa loquiter'.

=item HASHREF{BOOLEAN} C<OPTIONS> (optional) - Hash with keys: requirementsEnabled,testPriorityEnabled,automationEnabled,inventoryEnabled.

=item BOOLEAN C<ACTIVE> (optional) - Whether to mark the project active or not.  Default True.

=item BOOLEAN C<PUBLIC> (optional) - Whether the project is public or not.  Default true.

=back

Returns (integer) project ID on success, false otherwise.

    $tl->createTestProject('Widgetronic 4000', 'Tests for the whiz-bang new product', {'inventoryEnabled=>true}, true, true);

=head2 B<createTestCase (name, test_suite_id, test_project_id, author, summary, steps, preconditions, execution, order)>

Creates new test case with given test suite id and project id.
Author, Summary and Steps are mandatory for reasons that should be obvious to any experienced QA professional.
Execution type and Test order is optional.

=over 4

=item STRING C<NAME> - Desired name of test case.

=item INTEGER C<TEST SUITE ID> - ID of parent test suite.

=item INTEGER C<TEST PROJECT ID> - ID of parent project

=item STRING C<AUTHOR> - Author of test case.

=item STRING C<SUMMARY> - Summary of test case.

=item STRING C<STEPS> - Test steps.

=item STRING C<PRECONDITIONS> - Prereqs for running the test, if any.

=item STRING C<EXECUTION> (optional) - Execution type.  Defaults to 'manual'.

=item INTEGER C<ORDER> (optional) - Order of test amongst peers.

=back

Returns (HASHREF) with Test Case ID and Test Case External ID on success, false otherwise.

    $tl->createTestCase('Verify Whatsit Throbs at correct frequency', 123, 456, 'Gnaeus Pompieus Maximus', 'Make sure throbber on Whatsit doesn't work out of harmony with other throbbers', '1. Connect measurement harness. 2. ??? 3. PROFIT!', 'automated', 2);

=head1 SETTER METHODS

=head2 B<reportTCResult (case_id, test_plan_id, build_id, status, [platform, notes, bug id])>

Report results of a test case with a given ID, plan and build ID.  Set case results to status given.
Platform is mandatory if available, otherwise optional.
Notes and Bug Ids for whatever tracker you use are optional.

=over 4

=item INTEGER C<CASE ID> - Desired test case.

=item INTEGER C<TEST PLAN ID> - ID of relevant test plan.

=item INTEGER C<BUILD ID> - ID of relevant build.

=item STRING C<STATUS> - Desired Test Status Code.  Codes not documented anywhere but in your cfg/const.inc.php of the TestLink Install.

=item STRING C<PLATFORM> (semi-optional) - Relevant platform tested on.  Accepts both platform name and ID, if it looks_like_number, uses platform_id

=item STRING C<NOTES> (optional) - Relevant information gleaned during testing process.

=item STRING C<BUG ID> (optional) - Relevant bug ID for regression tests, or if you auto-open bugs based on failures.

=back

Returns project ID on success, false otherwise.

    $tl->reportTCResult('T-1000', 7779311, 8675309, 'Tool Failure', 'Skynet Infiltration Model 1000', 'Catastrophic systems failure due to falling into vat of molten metal' 'TERMINATOR-2');

=head2 B<addTestCaseToTestPlan (test_plan_id, test_case_id, project_id, test_version, [sut_platform])>

Creates new Test plan with given name in the given project.

=over 4

=item INTEGER C<TEST PLAN ID> - Desired test plan.

=item STRING C<TEST CASE ID> - The 'external' name of some existing test in TestLink, e.g. TP-12.

=item INTEGER C<PROJECT ID> - The ID of some project in testlink

=item INTEGER C<TEST VERSION> - The desired version of the test to add.

=item STRING C<SUT PLATFORM> (semi-optional) - The name of the desired platform to run on for this test (if any).

=item INTEGER C<EXECUTION ORDER> (optional) - The order in which to execute this test amongst it's peers.

=item INTEGER C<URGENCY> (optional) - The priority of the case in the plan.

=back

Returns true if case addition is successful.

    $tl->addTestCaseToTestPlan(666, 'cp-90210', 121, '3.11', 'OS2/WARP', 3, 1);

=head2 B<uploadExecutionAttachment (execution_id,filename,mimetype,content,[title,description])>

Uploads the provided file and associates it with the given execution.

=over 4

=item INTEGER C<EXECUTION ID> - ID of a successful execution, such as the id key from the hash that is returned by reportTCResult.

=item STRING C<FILENAME> - The name you want this file to appear as.

=item INTEGER C<MIMETYPE> - The mimetype of the file uploaded, so we can tell the browser what to do with it when downloaded

=item INTEGER C<CONTENT> - The base64 encoded content of the file you want to upload.

=item STRING C<TITLE> (optional) - A title for this attachment.

=item INTEGER C<DESCRIPTION> (optional) - A short description of who/what/why this was attached.

=back

Returns true if attachment addition is successful.

    $tl->uploadExecutionAttachment(1234, 'moo.txt', 'text/cow', APR::Base64::encode('MOO MOO MOOOOOO'), 'MOO', 'Test observed deranged bleatings of domestic ungulates, please investigate.');

=head2 B<uploadTestCaseAttachment (case_id,filename,mimetype,content,[title,description])>

Uploads the provided file and associates it with the given execution.

=over 4

=item INTEGER C<CASE ID> - ID of desired test case

=item STRING C<FILENAME> - The name you want this file to appear as.

=item INTEGER C<MIMETYPE> - The mimetype of the file uploaded, so we can tell the browser what to do with it when downloaded

=item INTEGER C<CONTENT> - The base64 encoded content of the file you want to upload.

=item STRING C<TITLE> (optional) - A title for this attachment.

=item INTEGER C<DESCRIPTION> (optional) - A short description of who/what/why this was attached.

=back

Returns true if attachment addition is successful.

    $tl->uploadTestCaseAttachment(1234, 'doStuff.t', 'text/perl', APR::Base64::encode($slurped_file_content), 'doStuff.t', 'Test File.');

=head1 GETTER METHODS

=head2 B<getProjects ()>

Get all available projects

Returns array of project definition hashes, false otherwise.

    $projects = $tl->getProjects;

=head2 B<getProjectByName ($project)>

Gets some project definition hash by it's name

=over 4

=item STRING C<PROJECT> - desired project

=back

Returns desired project def hash, false otherwise.

    $projects = $tl->getProjectByName('FunProject');

=head2 B<getProjectByID ($project)>

Gets some project definition hash by it's ID

=over 4

=item INTEGER C<PROJECT> - desired project

=back

Returns desired project def hash, false otherwise.

    $projects = $tl->getProjectByID(222);

=head2 B<getTLDTestSuitesForProject (project_id,get_tests)>

Gets the testsuites in the top level of a project

=over 4

=item STRING C<PROJECT ID> - desired project's ID
=item BOOLEAN C<GET TESTS> - Get tests for suites returned, set them as 'tests' key in hash

=back

Returns desired testsuites' definition hashes, 0 on error and -1  when there is no such project.

    $projects = $tl->getTLDTestSuitesForProject(123);

=head2 B<getTestSuitesForTestSuite (testsuite_id,get_tests)>

Gets the testsuites that are children of the provided testsuite.

=over 4

=item STRING C<TESTSUITE ID> - desired parent testsuite ID
=item STRING C<GET TESTS> - whether to get child tests as well

=back

Returns desired testsuites' definition hashes, false otherwise.

    $suites = $tl->getTestSuitesForTestSuite(123);
    $suitesWithCases = $tl->getTestSuitesForTestSuite(123,1);

=head2 B<getTestSuitesByName (project_id,testsuite_name,do_regex)>

Gets the testsuite(s) that match given name inside of given project name.
WARNING: this will slurp the entire testsuite tree.  This can take a while on large projects, but the results are cached so that subsequent calls are not as onerous.

=over 4

=item STRING C<PROJECT ID> - ID of project holding this testsuite

=item STRING C<TESTSUITE NAME> - desired parent testsuite name

=item BOOLEAN C<DO REGEX> (optional) - whether or not PROJECT NAME is a regex (default false, uses 'eq' to compare).

=back

Returns desired testsuites' definition hashes, false otherwise.

    $suites = $tl->getTestSuitesByName(321, 'hugSuite');
    $suitesr = $tl->getTestSuitesByName(123, qr/^hug/, 1);

=head2 B<getTestSuiteByID (testsuite_id)>

Gets the testsuite with the given ID.

=over 4

=item STRING C<TESTSUITE_ID> - TestSuite ID.

=back

Returns desired testsuite definition hash, false otherwise.

    $tests = $tl->getTestSuiteByID(123);

=head2 B<getTestCasesForTestSuite (testsuite_id,recurse,details)>

Gets the testsuites that match given name inside of given project name.

=over 4

=item STRING C<TESTSUITE_ID> - TestSuite ID.

=item BOOLEAN C<RECURSE> - Search testsuite tree recursively for tests below the provided testsuite

=item BOOLEAN C<RETURNMODE> (optional) - whether or not to return more detailed test info (steps,summary,expected results).  Defaults to false.

=back

Returns desired case definition hashes, false otherwise.

    $tests = $tl->getTestCasesForTestSuite(123,1,1);

=head2 B<getTestCaseByExternalId (case_id,version)>

Gets the test case with the given external ID (e.g. projprefix-123) at provided version.

=over 4

=item STRING C<CASE ID> - desired external case ID

=item STRING C<VERSION> - desired test case version.  Defaults to most recent version.

=back

Returns desired case definition hash, false otherwise.

    $case = $tl->getTestCaseByExternalId('eee-123');

=head2 B<getTestCaseById (case_id,version)>

Gets the test case with the given internal ID at provided version.

=over 4

=item STRING C<CASE ID> - desired internal case ID

=item STRING C<VERSION> - desired test case version.  Defaults to most recent version.

=back

Returns desired case definition hash, false otherwise.

    $case = $tl->getTestCaseById(28474,5);

=head2 B<getTestCaseByName (case_name,suite_name,project_name,tc_path_nameversion)>

Gets the test case with the given internal ID at provided version.

=over 4

=item STRING C<CASE NAME> - desired internal case ID

=item STRING C<SUITE NAME> - parent suite's name

=item STRING C<PROJECT NAME> - parent project's name

=item STRING C<TC_PATH_NAME> (optional)- Full path to TC. Please see documentation for more info: http://jetmore.org/john/misc/phpdoc-testlink193-api/TestlinkAPI/TestlinkXMLRPCServer.html#getTestCaseIDByName

=item STRING C<VERSION> (optional)- desired test case version.  Defaults to most recent version.

=back

Returns desired case definition hash, false otherwise.

    $case = $tl->getTestCaseByName('nugCase','gravySuite','chickenProject');

=head2 B<getTestCaseAttachments (case_ext_id)>

Gets the attachments for some case.

=over 4

=item STRING C<CASE ID> - desired external case ID

=back

Returns desired attachment definition hash, false otherwise.  Content key is the file base64 encoded.

    $att = $tl->getTestCaseAttachments('CP-222');

=head2 B<getTestPlansForProject (project_id)>

Gets the test plans within given project id

=over 4

=item STRING C<PROJECT ID> - project ID

=back

Returns desired test plan definition hashes, false otherwise.

    $plans = $tl->getTestPlansForProject(23);

=head2 B<getTestPlanByName (plan_name,project_name)>

Gets the test plan within given project name

=over 4

=item STRING C<PLAN NAME> - desired test plan name

=item STRING C<PROJECT NAME> - project name

=back

Returns desired test plan definition hash, false otherwise.

    $suites = $tl->getTestPlanByName('nugs','gravy');

=head2 B<getBuildsForTestPlan (plan_id)>

Gets the builds for given test plan

=over 4

=item STRING C<PLAN ID> - desired test plan ID

=back

Returns desired builds' definition hashes, false otherwise.

    $builds = $tl->getBuildsForTestPlan(1234);

=head2 B<getTestCasesForTestPlan (plan_id)>

Gets the cases in provided test plan

=over 4

=item STRING C<PLAN ID> - desired test plan ID

=back

Returns desired tests' definition hashes sorted by parent test plan ID, false otherwise.

    Example output:
    { 1234 => [{case1},{case2},...], 33212 => [cases...]}

    Example usage:
    $builds = $tl->getTestCasesForTestPlan(1234);

=head2 B<getLatestBuildForTestPlan (plan_id)>

Gets the latest build for the provided test plan

=over 4

=item STRING C<PLAN ID> - desired test plan ID

=back

Returns desired build definition hash, false otherwise.

    $build = $tl->getLatestBuildForTestPlan(1234);

=head2 B<getBuildByName (build_name,project_id)>

Gets the desired build in project id by name

=over 4

=item STRING C<BUILD NAME> - desired build's name

=item INTEGER C<PROJECT ID> - desired test project ID

=back

Returns desired build definition hash, false otherwise.

    $build = $tl->getBuildByName('foo',1234);

=head1 REPORTING METHODS

=head2 B<getTotalsForTestPlan (plan_id)>

Gets the results summary for a test plan, even though what you really want is results by build/platform

=over 4

=item INTEGER C<PLAN ID> - desired test plan

=back

Returns Hash describing test results.

    $res = $tl->getTotalsForTestPlan(2322);

=head1 EXPORT/IMPORT METHODS

=head2 B<dump([project,get_attachments,flatten])>

Return all info for all (or only the specified) projects.
It will have the entire testsuite hierarchy and it's tests/attachments in an array of HASHREFs.
The idea would be that you then could encode as JSON/XML as a backup, or to facilitate migration to other systems.

The project hashes will be what you would expect from getProjectByName calls.
Those will have a key 'testsuites' with a list of it's child testsuites.
These testsuites will themselves have 'testsuites' and 'test' keys describing their children.
Both the test and testsuite hashes will have an 'attachment' parameter with the base64 encoded attachment as a string if the get_attachments option is passed.

WARNING: I have observed some locking related issues with cases/suites etc.
Sometimes calls to get tests/suites during dumps fails, sometimes subsequent calls to getTestSuites/getTestCasesForTestSuite fail.
If you are experiencing issues, try to put some wait() in there until it starts behaving right.
Alternatively, just XML dump the whole project and use XML::Simple or your tool of choice to get the project tree.

ALSO: Attachment getting is not enabled due to the underlying XMLRPC calls appearing not to work.  This option will be ignored until a workaround can be found.

=over 4

=item INTEGER C<PROJECT NAME> (optional) - desired project
=item BOOLEAN C<GET ATTACHMENTS> (optional) - whether or not to get attachments.  Default false. UNIMPLEMENTED.
=item BOOLEAN C<FLATTEN> (optional) - Whether to return a flattened structure (you will need to correlate parent to child yourself, but this is faster due to not walking the tree).  Preferred output for those not comfortable with doing tail recursion.

=back

Returns ARRAYREF describing everything.

    $ultradump = $tl->dump();
    $dumpWithAtts = $tl->dump('TestProject',1);
    $flatDump = $tl->dump('testProj',0,1);

=head1 SEE ALSO

L<XMLRPC::Lite>

=head1 SPECIAL THANKS

cPanel, Inc. graciously funded the initial work on this project.

=head1 AUTHOR

George S. Baugh <teodesian@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Neil Bowers

Neil Bowers <neil@bowers.com>

=head1 SOURCE

The development version is on github at L<http://github.com/teodesian/TestLink-Perl>
and may be cloned from L<git://github.com/teodesian/TestLink-Perl.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by George S. Baugh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
