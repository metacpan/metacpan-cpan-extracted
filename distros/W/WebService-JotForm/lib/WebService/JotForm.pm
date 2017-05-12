package WebService::JotForm;

use strict;
use warnings FATAL => 'all';
use Moo;
use JSON::MaybeXS;
use LWP::UserAgent;
use URI::Escape qw(uri_escape);
use Carp qw(croak);

=head1 NAME

WebService::JotForm - Perl interface to JotForm's API -- currently only the read operations are fully supported.

Support for create, update, and delete operations are beginning to be added in this and future releases.

=head1 VERSION

Version 0.020

=head1 SYNOPSIS
	
	my $jotform = WebService::JotForm->new( apiKey => $apiKey);

	my $forms = $jotform->get_user_forms();

	# Show form details associated with our account

	foreach my $form (@{$forms->{content}}) {
		print "Form $form->{id} - $form->{title} - $form->{url} - $form->{last_submission}\n";
	}

	my $form_id = "42";

	my $submissions = $jotform->get_form_submissions($form_id);

	# Loop through all submissions to our form and print out submission created_at and ip

	foreach my $sub(@{$submissions->{content}}) {
		print "$sub->{created_at} $sub->{ip}\n";
	}

=head1 DESCRIPTION

This is a thin wrapper around the JotForm API.  All results are what's returned by the JotForm API, 
with the JSON being converted into Perl data structures.

You need a JotForm API key to use this module.  The easiest way to get an apiKey is just to
login to L<JotForm|http://jotform.com/> and then go to L<http://www.jotform.com/myaccount/api>.
From there create a token (or use an existing one).  You can set whether it's a read-only or full-access token.

More information on tokens is available in the L<JotForm API Documentation|http://api.jotform.com/docs/>

=cut

our $VERSION = '0.020';

has 'apiKey'  		=> ( is => 'ro', required => 1);
has 'apiBase' 		=> ( is => 'ro', default => 'https://api.jotform.com');
has 'apiVersion'	=> ( is => 'ro', default => 'v1');
has 'agent'   		=> ( is => 'rw'); # Must act like LWP::UserAgent

my $json = JSON::MaybeXS->new;

sub BUILD {
	my ($self) = @_;
	
	if(not $self->agent) {
		$self->agent(LWP::UserAgent->new(agent => "perl/$], WebService::JotForm/" . $self->VERSION));
	}

	my $resp = $self->agent->get($self->apiBase . "/" . $self->apiVersion . "/user?apiKey=" . $self->apiKey);

	return;
}

=head1 METHODS

=head2 new(%params)

Create a new WebService::JotForm object with hash parameter

	my $jotform = WebService::JotForm->new(
		apiKey => '1234567890abcdef'
	);

Accepts the following parameters:

=over 4

=item * apiKey

Required parameter.  JotForm apiKey

=item * apiBase

Optional parameter - defaults to: 'https://api.jotform.com'

=item * apiVersion

Optional parameter - defaults to 'v1'

=item * agent

Agent that acts like LWP::UserAgent used for making requests -- module defaults to creating its own if none is provide

=back

=cut

=head2 get_user()

	$jotform->get_user();

Get user account details for this JotForm user. Including user account type, avatar URL, name, email, website URL and account limits.

	my $user = $jotform->get_user();

=cut


sub get_user {
	my $self = shift;
	return $self->_get("user");
}

=head2 get_user_usage()

	$jotform->get_user_usage();

Get number of form submissions received this month. Also, get number of SSL form submissions, payment form submissions and upload space used by user.

=cut

sub get_user_usage {
	my $self = shift;
	return $self->_get("user/usage");
}


=head2 get_user_submissions($params)

	$jotform->get_user_submissions($params);

Get a list of all submissions for all forms on this account. The answers array has the submission data. Created_at is the date of the submission.
Optional paramaters

=over 4

=item offset

	Example: 20

=item limit

	Example: 20

=item filter

	Example: {"new":"1"} or {"created_at:gt":"2013-01-01 00:00:00"}

=item orderby

	Example: created_at

=back

=cut

sub get_user_submissions {
	my ($self, $params) = @_;
	$params ||= {};
	return $self->_get("user/submissions", $params);
}

=head2 get_user_subusers()

	$jotform->get_user_subusers();

Get a list of sub users for this accounts and list of forms and form folders with access privileges.
=cut

sub get_user_subusers {
	my $self = shift;
	return $self->_get("user/subusers");
}

=head2 get_user_folders()

	$jotform->get_user_folders();

Get a list of form folders for this account. Returns name of the folder and owner of the folder for shared folders.

=cut

sub get_user_folders {
	my $self = shift;
	return $self->_get("user/folders");
}

=head2 get_user_reports()
	
	$jotform->get_user_reports();

List of URLS for reports in this account. Includes reports for all of the forms. ie. Excel, CSV, printable charts, embeddable HTML tables.

=cut
sub get_user_reports {
	my $self = shift;
	return $self->_get("user/reports");
}

=head2 register_user()

	$jotform->register_user($params);

	$jotform->register_user({ username => $username, password => $pw, email => $email });

Register a new JotForm account with username, password and email

=cut

sub register_user {
	my $self = shift;
	my $params = shift;
	$params ||= {};
	return $self->_post("user/register", $params);
}

=head2 login_user()

	$jotform->register_user($params);

	$jotform->register_user({ username => $username, password => $pw });

Login user with given credentials - accepts username, password, and optionally appName, and access

=cut



sub login_user {
	my $self = shift;
	my $params = shift;
	$params ||= {};
	return $self->_post("user/login", $params);
}

=head2 get_user_logout()

	$jotform->get_user_logout();

Logout user

=cut
sub get_user_logout {
	my $self = shift;
	return $self->_get("user/logout");
}

=head2 get_user_settings()

	$jotform->get_user_settings();

Get user's time zone and language.

=cut
sub get_user_settings {
	my $self = shift;
	return $self->_get("user/settings");
}

=head2 update_user_settings()

	$jotform->update_user_settings($params);
	
	$jotform->update_user_settings({ email => $updated_email });

Update user's settings like time zone and language.  Optional fields: name, email, website, time_zone, company, securityQuestion, securityAnswer, industry

=cut
sub update_user_settings {
	my $self = shift;
	my $params = shift;
	$params ||= {};
	
	return $self->_post("user/settings", $params);
}








=head2 get_user_history()

	$jotform->get_user_history();

User activity log about things like forms created/modified/deleted, account logins and other operations.


=cut

sub get_user_history {
	my ($self, $params) = @_;
	return $self->_get("user/history", $params);
}

=head2 get_user_forms($params)

	$jotform->get_user_forms($params);


Get a list of forms for this account. Includes basic details such as title of the form, when it was created, number of new and total submissions.

TODO -- document additionsal optional params

=cut

sub get_user_forms {
	my ($self, $params) = @_;
	return $self->_get("user/forms", $params);
}

=head2 create_forms($params);

	$jotform->create_forms($params);

Add new forms with questions, properties and email settings.


=cut

sub create_forms {
	my $self = shift;
	my $params = shift;
	$params ||= {};

	return $self->_post("user/forms", $params);
}

=head2 create_form($params);

	$jotform->create_form($params);

Add new form with questions, properties and email settings.


=cut

sub create_form {
	my $self = shift;
	my $params = shift;
	$params ||= {};

	return $self->_post("/form", $params);
}


=head2 get_form($id)

	$jotform->get_form($id);

Get basic information about a form. Use get_form_questions($id) to get the list of questions.

=cut

sub get_form {
	my ($self, $form_id) = @_;
	croak "No form id provided to get_form" if !$form_id;
	return $self->_get("form/$form_id");
}

=head2 clone_form($id)
	
	$jotform->clone_form($id);

Clone a given form
=cut

sub clone_form {
	my ($self, $form_id) = @_;
	croak "No form id provided to clone_form" if !$form_id;
	return $self->_post("/form/$form_id/clone");
}

=head2 create_form_question($id, $question)

	$jotform->create_form_question($id, $question)

	Add a new question to a form, takes an id for the form as a parameter, and then a hasref of key/values for the question fields

=cut

sub create_form_question {
	my ($self, $form_id, $question) = @_;
	
	croak "No form id provided to create_form_question" if !$form_id;
	
	$question ||= {};
	my $params = {};

	foreach (keys %$question) {
		$params->{"question[$_]"} = $question->{$_};
	}

	return $self->_post("/form/$form_id/questions", $params);
}


=head2 edit_form_question($form_id, $qid, $question);

	$jotform->edit_form_question($form_id, $qid, $question);

Edit a question property or add a new one. Form questions might have various properties. Examples: Is it required? Are there any validations such as 'numeric only'?

=cut

sub edit_form_question { 
	my ($self, $form_id, $qid, $question) = @_;
	croak "edit_form_question requires both a form_id and question id" if !$form_id && $qid;

	$question ||= {};
	my $params = {};
	
	foreach (keys %$question) {
		$params->{"question[$_]"} = $question->{$_};
	}
	
	return $self->_post("form/$form_id/question/$qid", $params);
}

=head2 set_form_properties($form_id, $params)

	$jotform->set_form_properties($form_id, $params);
	
	$jotform->set_form_properties($form_id, { formWidth => 555 });

Add or edit properties of a specific form

=cut 
sub set_form_properties {
	my($self, $form_id, $params) = @_;
	croak "set_form_properties requires a form_id" if !$form_id;
	$params ||= {};

	my $props = {};

	foreach(keys %$params) {
		$props->{"properties[$_]"} = $params->{$_};
	}
	return $self->_post("/form/$form_id/properties", $props);
}

=head2 get_form_questions($id)
	
	$jotform->get_form_questions($id);

	Get a list of all questions on a form. Type describes question field type. Order is the question order in the form. Text field is the question label.

=cut

sub get_form_questions {
	my ($self, $form_id) = @_;
	croak "No form id provided to get_form_questions" if !$form_id;
	return $self->_get("form/$form_id/questions");
}

=head2 get_form_question($form_id, $qid)
	
	$jotform->get_form_question($form_id, $qid);

	Get Details About a Question

=cut

sub get_form_question {
	my ($self, $form_id, $qid) = @_;
	croak "Get_form_question requires both a form_id and question id" if !$form_id && $qid;
	return $self->_get("form/$form_id/question/$qid");
}

=head2 get_form_properties($id,$key)

	$jotform->get_form_properties($id);
	
	$jotform->get_form_properties($id,$key);

	Get a list of all properties on a form.

=cut

sub get_form_properties {
	my ($self, $form_id, $key) = @_;
	croak "Get_form_properties requires a form_id" if !$form_id;
	
	if($key) {
		return $self->_get("form/$form_id/properties/$key"); 
	} else {
		return $self->_get("form/$form_id/properties"); 
	}
}

=head2 get_form_reports($id)

	$jotform->getFormReports($id);

	Get all the reports of a specific form.

=cut

sub get_form_reports {
	my ($self, $form_id) = @_;
	croak "No form id provided to get_form_reports" if !$form_id;
	return $self->_get("form/$form_id/reports"); 
}

=head2 create_form_report($form_id, { title => $title, list_type => $list_type });

	$jotform->create_form_report($form_id, { title => $title, list_type => "csv" });
	$jotform->create_form_report($form_id, { title => $title, list_type => "csv", "fields=ip,dt,1" });

	Create new report of a form with intended fields, type and title.

=cut 

sub create_form_report{
	my($self, $form_id, $params) = @_;
	$params ||= {};
	croak "No form id provided to create_form_report" if !$form_id;
	croak "title and list_type required parameters to create_form_report" if !$params->{title} || !$params->{list_type};

	return $self->_post("form/$form_id/reports", $params);
}

=head2 get_form_files($id)

	$jotform->get_form_files($id);

	List of files uploaded on a form. Here is how you can access a particular file: http://www.jotform.com/uploads/{username}/{form-id}/{submission-id}/{file-name}. Size and file type is also included.

=cut


sub get_form_files {
	my ($self, $form_id) = @_;
	croak "No form id provided to get_form_files" if !$form_id;
	return $self->_get("form/$form_id/files"); 
}

=head2 get_form_webhooks($id)

	$jotform->get_form_webhooks($id)

	Webhooks can be used to send form submission data as an instant notification. Returns list of webhooks for this form.

=cut


sub get_form_webhooks {
	my ($self, $form_id) = @_;
	croak "No form id provided to get_form_webhooks" if !$form_id;
	return $self->_get("form/$form_id/webhooks"); 
}

=head2 create_form_webhook($form_id, $url)

	$jotform->create_form_webhook($form_id, $url);

	Webhooks can be used to send form submission data as an instant notification.  Add a new webhook that receives submission data for a given form

=cut

sub create_form_webhook {
	my($self, $form_id, $url) = @_;
	croak "No form id provided to create_form_webhook" if !$form_id;
	croak "No url provided to create_form_webhook" if !$url;

	return $self->_post("/form/$form_id/webhooks", { webhookURL => $url });
}

=head2 get_form_submissions($id)

	$jotform->get_form_submissions($id, $params);

	List of form reponses. Fields array has the submitted data. Created_at is the date of the submission.

=cut


sub get_form_submissions {
	my ($self, $form_id, $params) = @_;
	croak "No form id provided to get_form_submissions" if !$form_id;
	return $self->_get("form/$form_id/submissions"); 
}

=head2 get_submission($id)

	$jotform->get_submission($id);

	Similar to get_form_submissions($id) But only get a single submission, based on submission id

=cut


sub get_submission {
	my ($self, $sub_id) = @_;
	croak "No submission id provided to get_submission" if !$sub_id;
	return $self->_get("submission/$sub_id");
}

=head2 get_report($id)

	$jotform->get_report($id);

	Get more information about a data report.
=cut


sub get_report {
	my ($self, $rep_id) = @_;
	croak "No report id provided to get_report" if !$rep_id;
	return $self->_get("report/$rep_id"); 
}

=head2 get_folder($id)

	$jotform->get_folder($id)

	Get a list of forms in a folder, and other details about the form such as folder color.
=cut


sub get_folder {
	my ($self, $fol_id) = @_;
	croak "No folder id provided to get_folder" if !$fol_id;
	return $self->_get("folder/$fol_id"); 
}

=head2 get_system_plan($plan_name)

	$jotform->get_system_plan($plan_name)

	Get limit and prices of a plan.
=cut


sub get_system_plan {
	my ($self, $plan_name) = @_;
	croak "No plan name provided to get_system_plan" if !$plan_name;
	return $self->_get("system/plan/$plan_name"); 

}


sub _get {
	my ($self, $path, $params) = @_;
	my $url = $self->_gen_request_url($path, $params);
	my $resp = $self->agent->get($url);

	unless ($resp->is_success) {
		croak "Failed to fetch $url - ".$resp->status_line;
	}
	return $json->decode($resp->content);
}

sub _post {
	my ($self, $path, $params) = @_;
	$params ||= {};
	my $url = join("/", $self->apiBase, $self->apiVersion, $path) . "?apiKey=" .$self->apiKey;
	my $resp = $self->agent->post($url, $params);
	unless ($resp->is_success) {
		croak "Failed to fetch $url - ".$resp->status_line;
	}
	return $json->decode($resp->content);
}

sub _gen_request_url {
	my ($self, $path, $params) = @_;
	my $url = join("/", $self->apiBase, $self->apiVersion, $path) . "?apiKey=" .$self->apiKey;
	foreach my $param (keys %$params) {
		$url .= "&".uri_escape($param) ."=". uri_escape($params->{$param});
	}
	return $url;
} 


=head1 AUTHOR

Tim Vroom, C<< <vroom at blockstackers.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-jotform at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-JotForm>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::JotForm


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-JotForm>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-JotForm>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-JotForm>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-JotForm/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Tim Vroom.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WebService::JotForm
