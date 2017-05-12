#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use WebService::JotForm;
use JSON::MaybeXS;
use Data::Dumper;
use Test::Deep;

#Test some of the api methods, before allowing a release to happen

if (not $ENV{RELEASE_TESTING} ) {
    plan skip_all => 'Set $ENV{RELEASE_TESTING} to run release tests.'
}

my $token;
my $token_file;
if($ENV{'WEBSERVICEJOTFORMTOKEN'}) {
	$token = $ENV{'WEBSERVICEJOTFORMTOKEN'};
} else {
	$token_file = "$ENV{HOME}/.webservice-jotform.token";

	eval {
    		open(my $fh, '<', $token_file);
    		chomp($token = <$fh>);
	};
}

if (not $token) {
    plan skip_all => "Cannot read $token_file";
}

my $cases = {
	'response_wrap' => {
          'responseCode' => 200,
          'limit-left' => re('^\d+$'), 
          'message' => 'success'
        },
	
	resultSet => {
		'count'  => re('^\d+$'), 
		'limit'  => re('^\d+$'),
		'offset' => re('^\d+$'),
	},

	get_user_content => {
		username => re('^\w+$')
	},

	get_user_usage_content => {
		submissions => re('^\d+$'),
		payments => re('^\d+$'),
		submissions => re('^\d+$'),
		ssl_submissions => re('^\d+$'),
		uploads => re('^\d+$'),
	},

	get_user_folders_content => {
                         'owner' => re('^[A-Za-z0-9]+$'),
                         'path' =>  re('^[A-Za-z0-9]+$'),
                         'id' =>    re('^[A-Za-z0-9]+$'),
	},

        get_user_reports_content_first => {
                           'form_id' => re('^[0-9]+$'),
                           'id' => re('^[0-9]+$'),
                           'list_type' => re('^[a-zA-Z0-9]+$')
        },
	get_form_content => {
                         'count' => re('^[0-9]+$'),
                         'id' => re('^[0-9]+$'),
                         'new' => re('^[0-9]+$'),
        },
	get_form_question_content => {
                         'qid' => re('^[0-9]+$'),
                         'type' => re('^[A-Za-z0-9_]+$')
                       },
	get_form_reports_content_first => {
                           'form_id' => re('^[0-9]+$'),
                           'list_type' =>  re('^[a-zA-Z0-9]+$'),
                           'url' => re('^http:'),
                       },
	get_submission_content => {
                         'form_id' => re('^[0-9]+$'), 
                         'id' => re('^[0-9]+$'),
                         'new' => re('^[0-9]+$'),
	},
	get_report_content =>  {
                         'form_id' => re('^[0-9]+$'), 
                         'list_type' => re('^[a-zA-Z0-9]+$'),
                         'url' => re('^http:'), 
                         'id' => re('^[0-9]+$'),
	},
	get_system_plan_content => {
		name => re('^[A-Za-z0-9]+$'),
	},
	get_folder_content => {
                         'parent' => re('^[A-Za-z0-9]+$'),
                         'id' => re('^[A-Za-z0-9]+$'),
	},
	register_user_content => {
		      'avatarUrl' => re('^http:'),
                      'username' => re('webserv-jot-test'),
	},
	login_user_content => {
		      'avatarUrl' => re('^http:'),
                      'username' => re('webserv-jot-test'),
	},
	update_user_settings_content => {
        	'email' => re('webserv-jot-test.*-2'),
	},
	create_form_content => {
                         'url' => re('^http:'),
                         'id' => re('^\d+$'),
	},
	clone_form_content =>  {
                         'count' => re('^\d+$'),
                         'url' => re('http:'),
                         'id' => re('^\d+$'),
                         'title' => re('Clone'),
                         'new' => 0
                       },
	create_form_question_content => {
	       'qid' => re('\d+$'),
               'order' => re('\d+$'),
	},
	set_form_properties_content => {
	       'formWidth' => re('\d+$'),
	},
	create_form_report_content => {
		'form_id' => re('\d+$'),
		'status' => 'ENABLED',
		'list_type' => 'csv',
		'url' => re('http:'),
		'id' => re('\d+$'),
		'title' => 'Test report'
	},
	create_form_webhook_content => {
		0 => re('http:'),
	},

};

my $jotform = WebService::JotForm->new(apiKey => $token);


my $user_info = $jotform->get_user();

cmp_deeply($user_info, superhashof($cases->{response_wrap}), "Got expected result from get_user() response_wrap");
cmp_deeply($user_info->{content}, superhashof($cases->{get_user_content}), "Got expected result from get_user() call for content returned");

my $user_usage = $jotform->get_user_usage();
cmp_deeply($user_usage, superhashof($cases->{response_wrap}), "Got expected result from get_user_usage() response_wrap");
cmp_deeply($user_usage->{content}, superhashof($cases->{get_user_usage_content}), "Got expected result from get_user_usage() content");

ok(exists $user_usage->{content}{submissions}, "Got a submissions key in return for get_user_usage");

my $user_submissions = $jotform->get_user_submissions();
cmp_deeply($user_submissions, superhashof($cases->{response_wrap}), "Got expected result from get_user_submissions() response_wrap");
cmp_deeply($user_submissions->{resultSet}, superhashof($cases->{resultSet}), "Got expected result from get_user_submissions() resultSet block");

ok(exists $user_submissions->{content}[0]{form_id}, "Got a form_id key in return for get_user_submissions");

my $form_id = $user_submissions->{content}[0]{form_id};

my $submission_id = $user_submissions->{content}[0]{id};

my $forms = $jotform->get_user_forms();
cmp_deeply($forms, superhashof($cases->{response_wrap}), "Got expected result from get_user_form() response_wrap");

my $formid = $forms->{content}[0]{id};

ok($formid, "Got at least one form as well as an id for it");

my $form_submissions_info = $jotform->get_form_submissions($formid);
cmp_deeply($form_submissions_info, superhashof($cases->{response_wrap}), "Got expected result from get_form_submissions() response_wrap");
cmp_deeply($form_submissions_info->{resultSet}, superhashof($cases->{resultSet}), "Got expected result from get_form_submissions() resultSet");

ok($form_submissions_info->{resultSet}{count} >0, "Got a resultSet back with at least one form submission");

my $sub_users = $jotform->get_user_subusers();
cmp_deeply($sub_users, superhashof($cases->{response_wrap}), "Got expected results from get_user_subusers() response_wrap");

my $folders = $jotform->get_user_folders();
cmp_deeply($folders, superhashof($cases->{response_wrap}), "Got expected results from get_user_folders() response_wrap");
cmp_deeply($folders->{content}, superhashof($cases->{get_user_folders_content}), "Got expected results from get_user_folders() content");

my $folder_id = $folders->{content}{subfolders}[0]{id};

my $reports = $jotform->get_user_reports();
cmp_deeply($reports, superhashof($cases->{response_wrap}), "Got expected results from get_user_reports() response_wrap");
cmp_deeply($reports->{content}[0], superhashof($cases->{get_user_reports_content_first}), "Got expected results from get_user_reports() content first");
my $report_id = $reports->{content}[0]{id};

my $settings = $jotform->get_user_settings();
cmp_deeply($settings, superhashof($cases->{response_wrap}), "Got expected results from get_user_settings() response_wrap");

my $history = $jotform->get_user_history();
cmp_deeply($settings, superhashof($cases->{response_wrap}), "Got expected results from get_user_history() response_wrap");

my $form = $jotform->get_form($formid);
cmp_deeply($form, superhashof($cases->{response_wrap}), "Got expected results from get_form() response_wrap");
cmp_deeply($form->{content}, superhashof($cases->{get_form_content}), "Got expected results from get_form() content");

my $questions = $jotform->get_form_questions($formid);
cmp_deeply($questions, superhashof($cases->{response_wrap}), "Got expected results from get_form_questions() response_wrap");
ok(exists $questions->{content}{1}{name}, "Got a name for a first question for get_form_questions");
ok(exists $questions->{content}{1}{type}, "Got a type for a first question for get_form_questions");

my $question = $jotform->get_form_question($formid, 1);
cmp_deeply($question, superhashof($cases->{response_wrap}), "Got expected results from get_form_question() response_wrap");
cmp_deeply($question->{content}, superhashof($cases->{get_form_question_content}), "Got expected results from get_form_question() content");

my $form_properties = $jotform->get_form_properties($formid);
cmp_deeply($form_properties, superhashof($cases->{response_wrap}), "Got expected results from get_form_properties() response_wrap");

my $form_reports = $jotform->get_form_reports($formid);
cmp_deeply($form_reports, superhashof($cases->{response_wrap}), "Got expected results from get_form_reports() response_wrap");

#print Dumper($form_reports->{content});
#print Dumper($form_reports->{content}[0]);

#cmp_deeply($form_reports->{content}[0], superhashof($cases->{get_form_reports_content_first}), "Got expected results from get_form_reports() content first");

my $form_files = $jotform->get_form_files($formid);
cmp_deeply($form_files, superhashof($cases->{response_wrap}), "Got expected results from get_form_files() response_wrap");

my $form_webhooks = $jotform->get_form_webhooks($formid);
#cmp_deeply($form_webhooks, superhashof($cases->{response_wrap}), "Got expected results from get_form_webhooks() response_wrap");
#like($form_webhooks->{content}{0}, qr/http:/, "Got an initial webhook that starts with http:");

my $submission = $jotform->get_submission($submission_id);
cmp_deeply($submission, superhashof($cases->{response_wrap}), "Got expected results from get_submission() response_wrap");
cmp_deeply($submission->{content}, superhashof($cases->{get_submission_content}), "Got expected results from get_submission() content");

my $report = $jotform->get_report($report_id);
cmp_deeply($report, superhashof($cases->{response_wrap}), "Got expected results from get_report() response_wrap");
cmp_deeply($report->{content}, superhashof($cases->{get_report_content}), "Got expected results from get_report() content");

my $system_plan = $jotform->get_system_plan('FREE');
cmp_deeply($system_plan, superhashof($cases->{response_wrap}), "Got expected results from get_system_plan() response_wrap");
cmp_deeply($system_plan->{content}, superhashof($cases->{get_system_plan_content}), "Got expected results from get_system_plan() response_content");


my $folder = $jotform->get_folder($folder_id);
cmp_deeply($folder, superhashof($cases->{response_wrap}), "Got expected results from get_folder() response_wrap");
cmp_deeply($folder->{content}, superhashof($cases->{get_folder_content}), "Got expected results from get_folder() content");


my $reg_user_random = "webserv-jot-test-";
my @chars = (0..9,'a'..'z');
for(1..5) {
	$reg_user_random .= $chars[rand @chars];
}


my $registered_user = $jotform->register_user({ username => $reg_user_random, password => $reg_user_random, email => "$reg_user_random\@timvroom.com"});

cmp_deeply($registered_user, superhashof($cases->{response_wrap}), "Got expected results from register_user() response_wrap");
cmp_deeply($registered_user->{content}, superhashof($cases->{register_user_content}), "Got expected results from register_user() content");


my $login_user = $jotform->login_user({ username => $reg_user_random, password => $reg_user_random });
cmp_deeply($login_user, superhashof($cases->{response_wrap}), "Got expected results from login_user() response_wrap");
cmp_deeply($login_user->{content}, superhashof($cases->{login_user_content}), "Got expected results from login_user() content");

my $update_user_settings = $jotform->update_user_settings({ email => "$reg_user_random-2\@timvroom.com"});
cmp_deeply($update_user_settings, superhashof($cases->{response_wrap}), "Got expected results from update_user_settings() response_wrap");
cmp_deeply($update_user_settings->{content}, superhashof($cases->{update_user_settings_content}), "Got expected results from update_user_settings() content");
my $create_form_data = {
	"questions[0][type]" => "control_head", 
	"questions[0][text]" => "Form Title",
	"questions[0][order]" => "1",
	"questions[0][name]" => "Header",
	"questions[1][type]" => "control_textbox",
	"questions[1][text]" => "Text Box Title",
	"questions[1][order]" => "2",
	"questions[1][name]" => "TextBox",
	"questions[1][validation]" => "None",
	"questions[1][required]" => "No",
	"questions[1][readonly]" => "No",
	"questions[1][size]" => "20",
	"questions[1][labelAlign]" => "Auto",
	"questions[1][hint]" => " ",
	"properties[title]" => "New Form",
	"properties[height]" => "600",
	"emails[0][type]" => "notification",
	"emails[0][name]" => "notification",
	"emails[0][from]" => "default",
	"emails[0][to]" => "noreply\@jotform.com",
	"emails[0][subject]" => "New Submission",
	"emails[0][html]" => "false"
};

my $created_form = $jotform->create_forms($create_form_data);

#print Dumper($created_form);

cmp_deeply($created_form, superhashof($cases->{response_wrap}), "Got expected results from create_forms() response_wrap");
cmp_deeply($created_form->{content}, superhashof($cases->{create_forms_content}), "Got expected results from create_forms() content");

my $created_form2 = $jotform->create_form($create_form_data);
cmp_deeply($created_form2, superhashof($cases->{response_wrap}), "Got expected results from create_form() response_wrap");
cmp_deeply($created_form2->{content}, superhashof($cases->{create_forms_content}), "Got expected results from create_form() content");

my $clone_result = $jotform->clone_form($form_id);
cmp_deeply($clone_result, superhashof($cases->{response_wrap}), "Got expected results from clone_form() response_wrap");
cmp_deeply($clone_result->{content}, superhashof($cases->{clone_form_content}), "Got expected results from clone_form() content");
#print Dumper($clone_result);

my $create_form_question = $jotform->create_form_question($form_id, { 
	"type" => "control_head", 
	"text" => "Header", 
	"order" => "1",
	"name" => "clickTo" 
});

cmp_deeply($create_form_question, superhashof($cases->{response_wrap}), "Got expected results from create_form_question response_wrap");
cmp_deeply($create_form_question->{content}, superhashof($cases->{create_form_question_content}), "Got expected results from create_form_question() content");

my $set_form_properties = $jotform->set_form_properties($form_id, { formWidth => 455 });
cmp_deeply($set_form_properties, superhashof($cases->{response_wrap}), "Got expected results from set_form_properties respons_wrap");
cmp_deeply($set_form_properties->{content}, superhashof($cases->{set_form_properties_content}), "Got expected results from set_form_properties() content");

my $create_form_report = $jotform->create_form_report($form_id, { title => "Test report", list_type => "csv"});
cmp_deeply($create_form_report, superhashof($cases->{response_wrap}), "Got expected results from create_form_report response_wrap");
cmp_deeply($create_form_report->{content}, superhashof($cases->{create_form_report_content}), "Got expected results from create_form_report content");

my $webhooknum = int(rand(10000));

my $create_form_webhook = $jotform->create_form_webhook($form_id, "http://example.com/$webhooknum");
cmp_deeply($create_form_webhook, superhashof($cases->{response_wrap}), "Got expected results from create_form_webhook response_wrap");
cmp_deeply($create_form_webhook->{content}, superhashof($cases->{create_form_webhook}), "Got expected results from create_form_webhook content");

print Dumper($jotform->get_form_questions($form_id));


done_testing;
