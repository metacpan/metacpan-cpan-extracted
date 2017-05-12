#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use DateTime;
use DateTime::Duration;

if (defined $ENV{WWW_ASANA_TEST_API_KEY}) {

	use_ok('WWW::Asana');

	my $asana = WWW::Asana->new($ENV{WWW_ASANA_TEST_API_KEY});

	my $me = $asana->me;
	ok(ref $me eq 'WWW::Asana::User','Testing "me", you are: '.$me->name);

	my $users_result = $asana->users;
	ok(ref $users_result eq 'ARRAY','Result of "users" is ARRAY');

	my $users_count = @{$users_result};

	for (@{$users_result}) {
		isa_ok($_,'WWW::Asana::User','"'.$_->name.'"');
		ok($_->has_email, 'has email');
	}

	sleep 1;

	my $current_me = $me->reload;
	isa_ok($current_me, 'WWW::Asana::User','Result of reload of User from "me" test');

	is($current_me->id, $me->id, "Comparing id of new me and old me");
	is($current_me->name, $me->name, "Comparing name of new me and old me");
	is($current_me->email, $me->email, "Comparing email of new me and old me");

	# needs to get fixed
	#cmp_ok($current_me->response->http_response->current_age, '<', $me->response->http_response->current_age,
	#	"Old me http_response is older then new me http_response");

	my $workspaces_ref = $me->workspaces;

	isa_ok($workspaces_ref,'ARRAY','Result of $me->workspaces');

	my $testws;

	for (@{$workspaces_ref}) {
		isa_ok($_,'WWW::Asana::Workspace','"'.$_->name.'"');
		if (defined $ENV{WWW_ASANA_TEST_WORKSPACE} && $_->name eq $ENV{WWW_ASANA_TEST_WORKSPACE}) {
			$testws = $_;
		} else {
			# my $tasks_ref = $_->tasks($current_me);
			# isa_ok($tasks_ref,'ARRAY','Result of $workspace->tasks with $me on "'.$_->name.'"');
			# for (@{$tasks_ref}) {
			# 	isa_ok($_,'WWW::Asana::Task','"'.$_->name.'"');
			# 	my $stories_ref = $_->stories;
			# 	isa_ok($stories_ref,'ARRAY','Result of $task->stories on "'.$_->name.'"');
			# 	for (@{$stories_ref}) {
			# 		isa_ok($_,'WWW::Asana::Story',$_->source.' '.$_->type);
			# 	}
			# }
		}
	}

	if ($testws) {

		my $projects_ref = $testws->projects;
		isa_ok($projects_ref,'ARRAY','Result of $testws->projects');

		my $testprj;

		for (@{$projects_ref}) {
			isa_ok($_,'WWW::Asana::Project','"'.$_->name.'"');
			if ($_->name eq 'TESTAPI') {
				$testprj = $_->update;
				isa_ok($testprj,'WWW::Asana::Project','"'.$_->name.'" updated');
			}
		}

		my $tags_ref = $testws->tags;
		isa_ok($tags_ref,'ARRAY','Result of $testws->tags');

		my $testtag;

		for (@{$tags_ref}) {
			isa_ok($_,'WWW::Asana::Tag','"'.$_->name.'"');
			if ($_->name eq 'TESTAPI') {
				$testtag = $_->update;
				isa_ok($testtag,'WWW::Asana::Tag','"'.$_->name.'" updated');
			}
		}

		if ($testprj && $testtag) {

			my $one_day = DateTime::Duration->new( days => 1 );

			my $new_task = $testws->create_task({
				name => 'DUE TOMORROW TEST',
				notes => 'TESTAPI',
				assignee => $me,
			});
			isa_ok($new_task,'WWW::Asana::Task');
			my $new_task_story = $new_task->comment("I'm a little teapot");
			isa_ok($new_task_story,'WWW::Asana::Story');
			is($new_task_story->created_by->id, $me->id, 'Checking for proper created_by on story');
			is($new_task_story->text, "I'm a little teapot", 'Checking for proper text on story');

			ok($new_task->add_project($testprj), 'Checking for successful addProject');
			ok($new_task->add_tag($testtag), 'Checking for successful addTag');
			
			$new_task->due_on($new_task->created_at + $one_day);
			$new_task->completed(1);
			my $updated_task = $new_task->update;
			isa_ok($updated_task, 'WWW::Asana::Task');
			ok($updated_task->completed, 'Checking that updated task is really completed');
			ok($updated_task->has_due_on, 'Checking that due_on is set');
			is(scalar @{$updated_task->projects}, 1, 'Checking proper project amount');
			is(scalar @{$updated_task->tags}, 1, 'Checking proper tag amount');

			$updated_task->name('DUE TOMORROW TEST DONE');
			my $done_task = $updated_task->update;
			isa_ok($done_task, 'WWW::Asana::Task');

			my $updated_task_story = $updated_task->comment("Now its done!");
			isa_ok($updated_task_story, 'WWW::Asana::Story');
			is($updated_task_story->created_by->id, $me->id, 'Checking for proper created_by on story');
			is($updated_task_story->text, "Now its done!", 'Checking for proper text on story');

			# NOT YET IMPLEMENTED
			# my $delete_task = $testws->create_task({
			# 	name => "I shouldnt exist",
			# 	notes => 'TESTAPI',
			# 	assignee => $me,
			# });
			# $delete_task->delete;

		} else {
			plan skip_all => 'Not doing write tests without "TESTAPI" project and a "TESTAPI" tag inside test workspace';
		}


	} else {
		plan skip_all => 'Not doing write tests without WWW_ASANA_TEST_WORKSPACE ENV variables (or this workspace was not found)';
	}

} else {
	plan skip_all => 'Not doing live tests without WWW_ASANA_TEST_API_KEY ENV variable';
}

done_testing;