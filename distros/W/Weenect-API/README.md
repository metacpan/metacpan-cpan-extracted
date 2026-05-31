# Weenect - API to Weenect tracker server

![Version](https://img.shields.io/github/v/release/sciurius/perl-Weenect-API)
![GitHub issues](https://img.shields.io/github/issues/sciurius/perl-Weenect-API)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http:/makeapullrequest.com)
![Language Perl](https://img.shields.io/badge/Language-Perl-blue)

## SYNOPSIS

	use Weenect;
	my $user = Weenect::API->new;
	$user->login( "me@example.com", "mypassword" );
	my $trackers = $user->get_trackers;
	foreach my $tracker ( @$trackers ) {
		printf("Tracker %s [%d%s]\n", $tracker->name, $tracker->id,
			  $tracker->active ? "" : ",inactive" );
	}

## DESCRIPTION

This package facilitates connecting to the Weenect server and fetching
some user and tracker data.

See the programs in the scripts directory for examples.

## LICENSE

Copyright (C) 2026, Johan Vromans

This module is free software. You can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

