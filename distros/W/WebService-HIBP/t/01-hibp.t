#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok('WebService::HIBP') || print "Bail out!\n";
}

package Acme::LWP::Teapot;

sub new { 
	my ($class) = @_;
	return bless {}, $class;
}

sub get {
	my ($self, $url);
	my $response = HTTP::Response->new(418, "I'm a teapot");
	$response->request(HTTP::Request->new('GET', $url));
	return $response;
}

package main;

my $bad_password = 'password1';
my $hibp = WebService::HIBP->new();
SKIP: {
    my @classes;
	ACCOUNT: {
			eval {
				@classes = $hibp->data_classes();
			} or do {
				if ($@ =~ /429/) {
					chomp $@;
					diag("Retrying data_classes:$@");
					sleep 4 + int rand 4;
					redo ACCOUNT;
				} else {
					chomp $@;
					diag("Failed data_classes call:$@");
					diag("Request:\n" . $hibp->last_request()->as_string());
					diag("Response:\n" . $hibp->last_response()->as_string());
					skip("Skipping remaining tests", 1);
				}
			};
	}
    ok(
        scalar @classes > 0,
        'Found data classes ' . join q[, ],
        map { "'$_'" } @classes
    );
	my @breaches;
	ACCOUNT: {
			eval {
				sleep 2;
				@breaches = $hibp->account( 'test@example.com' );
			} or do {
				if ($@ =~ /429/) {
					chomp $@;
					diag("Retrying account:$@");
					sleep 4 + int rand 4;
					redo ACCOUNT;
				} else {
					chomp $@;
					diag("Failed account call:$@");
					diag("Request:\n" . $hibp->last_request()->as_string());
					diag("Response:\n" . $hibp->last_response()->as_string());
					skip("Skipping remaining tests", 1);
				}
			};
	}
    my $count = 0;
    foreach my $breach ( @breaches ) {
        ok( $breach->name(),  "Name of breach is '" . $breach->name() . "'" );
        ok( $breach->title(), "Title of breach is '" . $breach->title() . "'" );
        ok( 1,
                "Domain of breach is '"
              . ( $breach->domain() || 'not defined' )
              . "'" );
        my $description = Encode::encode( 'UTF-8', $breach->description(), 1 );
        ok( $description, "Description of breach is '" . $description . "'" );
        foreach my $data_class ( $breach->data_classes() ) {
            ok( $data_class, "Found data_class '$data_class'" );
        }
        ok(
            $breach->breach_date() =~ /^\d{4}\-\d{2}\-\d{2}$/smx,
            "Date of breach is '"
              . $breach->breach_date()
              . "' and is correctly formatted"
        );
        ok(
            $breach->added_date() =~
              /^\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}Z$/smx,
            "Added Date is '"
              . $breach->modified_date()
              . "' and is correctly formatted"
        );
        ok(
            $breach->modified_date() =~
              /^\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}Z$/smx,
            "Modified Date is '"
              . $breach->modified_date()
              . "' and is correctly formatted"
        );
        ok( $breach->logo_path(),
            "Logo Path of breach is '" . $breach->logo_path() . "'" );
        ok(
            defined $breach->is_retired(),
            "Breach is " . ( $breach->is_retired() ? 'retired' : 'NOT retired' )
        );
        ok(
            defined $breach->is_sensitive(),
            "Breach is "
              . ( $breach->is_sensitive() ? 'sensitive' : 'NOT sensitive' )
        );
        ok(
            defined $breach->is_spam_list(),
            "Breach is "
              . ( $breach->is_spam_list() ? 'a spam list' : 'NOT a spam list' )
        );
        ok(
            defined $breach->is_verified(),
            "Breach is "
              . ( $breach->is_verified() ? 'verified' : 'NOT verified' )
        );
        ok(
            defined $breach->is_fabricated(),
            "Breach is "
              . ( $breach->is_fabricated() ? 'fabricated' : 'NOT fabricated' )
        );
        ok(
            $breach->pwn_count() =~ /^\d+$/smx,
            "Pwn Count is '"
              . $breach->pwn_count()
              . "' and is correctly formatted"
        );
        $count += 1;
    }
    my $previous_count = $count;
    $count = 0;
	@breaches = ();
	ACCOUNT: {
			eval {
				sleep 2;
				@breaches = $hibp->account( 'test@example.com', truncate => 1 );
			} or do {
				if ($@ =~ /429/) {
					chomp $@;
					diag("Retrying account with truncate:$@");
					sleep 4 + int rand 4;
					redo ACCOUNT;
				} else {
					chomp $@;
					diag("Failed account with truncate call:$@");
					diag("Request:\n" . $hibp->last_request()->as_string());
					diag("Response:\n" . $hibp->last_response()->as_string());
					skip("Skipping remaining tests", 1);
				}
			};
	}
    foreach my $breach ( @breaches ) {
        if ( defined $breach->title() ) {
        }
        elsif ( defined $breach->domain() ) {
        }
        elsif ( defined $breach->description() ) {
        }
        elsif ( scalar $breach->data_classes() ) {
        }
        elsif ( defined $breach->breach_date() ) {
        }
        elsif ( defined $breach->added_date() ) {
        }
        elsif ( defined $breach->modified_date() ) {
        }
        elsif ( defined $breach->logo_path() ) {
        }
        elsif ( defined $breach->is_retired() ) {
        }
        elsif ( defined $breach->is_sensitive() ) {
        }
        elsif ( defined $breach->is_spam_list() ) {
        }
        elsif ( defined $breach->is_verified() ) {
        }
        elsif ( defined $breach->is_fabricated() ) {
        }
        elsif ( $breach->name() ) {
            $count += 1;
        }

    }
    ok(
        $count == $previous_count,
"When truncate is applied, all the breaches were returned with only the name defined:$count:$previous_count"
    );
    $count = 0;
	@breaches = ();
	ACCOUNT: {
			eval {
				sleep 2;
				@breaches = $hibp->account( 'test@example.com', unverified => 1 );
			} or do {
				if ($@ =~ /429/) {
					chomp $@;
					diag("Retrying account with unverified:$@");
					sleep 4 + int rand 4;
					redo ACCOUNT;
				} else {
					chomp $@;
					diag("Failed account with unverified call:$@");
					diag("Request:\n" . $hibp->last_request()->as_string());
					diag("Response:\n" . $hibp->last_response()->as_string());
					skip("Skipping remaining tests", 1);
				}
			};
	}
    foreach my $breach ( @breaches )
    {
        if ( $breach->name() ) {
            $count += 1;
        }
    }
    $count = 0;
	@breaches = ();
	ACCOUNT: {
			eval {
				sleep 2;
				@breaches = $hibp->account( 'test@example.com', domain => 'adobe.com' );
			} or do {
				if ($@ =~ /429/) {
					chomp $@;
					diag("Retrying account with domain:$@");
					sleep 4 + int rand 4;
					redo ACCOUNT;
				} else {
					chomp $@;
					diag("Failed account with domain call:$@");
					diag("Request:\n" . $hibp->last_request()->as_string());
					diag("Response:\n" . $hibp->last_response()->as_string());
					skip("Skipping remaining tests", 1);
				}
			};
	}
    foreach my $breach ( @breaches ) {
        if ( $breach->name() ) {
            $count += 1;
        }
    }
    ok( $count < $previous_count && $count > 0,
        "When domain adobe.com is applied, less breaches were reported" );
    my $breach;
	ACCOUNT: {
			eval {
				sleep 2;
				$breach = $hibp->breach( 'Adobe' );
			} or do {
				if ($@ =~ /429/) {
					chomp $@;
					diag("Retrying breach:$@");
					sleep 4 + int rand 4;
					redo ACCOUNT;
				} else {
					chomp $@;
					diag("Failed breach call:$@");
				}
			};
	}
    ok( $breach->name() eq 'Adobe',
        "Request for a specific breach is returned" );
	@breaches = ();
	ACCOUNT: {
			eval {
				sleep 2;
				@breaches = $hibp->breaches();
			} or do {
				if ($@ =~ /429/) {
					chomp $@;
					diag("Retrying breaches:$@");
					sleep 4 + int rand 4;
					redo ACCOUNT;
				} else {
					chomp $@;
					diag("Failed breaches call:$@");
					diag("Request:\n" . $hibp->last_request()->as_string());
					diag("Response:\n" . $hibp->last_response()->as_string());
					skip("Skipping remaining tests", 1);
				}
			};
	}
    $count = 0;
    foreach my $breach ( sort { $a->added_date() cmp $b->added_date() }
        @breaches )
    {
        if ( $breach->description() ) {
            $count += 1;
        }
    }
    ok( $count, "Found $count breaches with descriptions" );
    $previous_count = $count;
    $count          = 0;
	@breaches = ();
	ACCOUNT: {
			eval {
				sleep 2;
				@breaches = $hibp->breaches( domain => 'adobe.com' );
			} or do {
				if ($@ =~ /429/) {
					chomp $@;
					diag("Retrying breaches with domain:$@");
					sleep 4 + int rand 4;
					redo ACCOUNT;
				} else {
					chomp $@;
					diag("Failed breaches with domain call:$@");
					diag("Request:\n" . $hibp->last_request()->as_string());
					diag("Response:\n" . $hibp->last_response()->as_string());
					skip("Skipping remaining tests", 1);
				}
			};
	}
    foreach my $breach ( sort { $a->added_date() cmp $b->added_date() }
        @breaches )
    {
        $count += 1;
    }
    ok( $count > 0 && $count < $previous_count,
        "Found $count breaches for adobe.com (filtering appears to work)" );
	my @pastes;
	PASTE: {
			eval {
				sleep 2;
				@pastes = $hibp->pastes( 'test@example.com' );
			} or do {
				if ($@ =~ /429/) {
					chomp $@;
					diag("Retrying pastes:$@");
					sleep 4 + int rand 4;
					redo PASTE;
				} else {
					chomp $@;
					diag("Failed pastes call:$@");
					diag("Request:\n" . $hibp->last_request()->as_string());
					diag("Response:\n" . $hibp->last_response()->as_string());
					if ($@ =~ /401/) {
						skip("Skipping remaining tests on forbidden", 1);
					}
				}
			};
	}
    foreach my $paste ( @pastes ) {
        ok( $paste->source(), "Source of paste is '" . $paste->source() . "'" );
        ok( $paste->id(),     "Id of paste is '" . $paste->id() . "'" );
        ok( $paste->title() || 1,
            "Title of paste is '" . ( $paste->title() || '' ) . "'" );
        ok( $paste->date() || 1,
            "Date of paste is '" . ( $paste->date() || '' ) . "'" );
        ok( $paste->email_count(),
            "Email Count of paste is '" . $paste->email_count() . "'" );
    }
    $count = $hibp->password($bad_password);
    ok( $count, "Bad password '$bad_password' returns a count of $count" );
    my $good_password = 'swYBygTEymkmYiwrgYj4yWwemeiQkTRQBuhWVh3JfxzRpxSTKj';
    $count = $hibp->password($good_password);
    ok( $count == 0,
        "Good password '$good_password' returns a count of $count" );
	$ENV{HTTPS_PROXY} = 'http://incorrect.example.com';
	$hibp = WebService::HIBP->new();
	eval {
        $hibp->password($good_password);
	};
	chomp $@;
	ok($@, "password threw an error when supplied a bad proxy:$@");
	eval {
		$hibp->pastes( 'test@example.com' );
	};
	chomp $@;
	ok($@, "pastes threw an error when supplied a bad proxy:$@");
	eval {
		$hibp->breach( 'Adobe' );
	};
	chomp $@;
	ok($@, "breach threw an error when supplied a bad proxy:$@");
	eval {
		$hibp->breaches();
	};
	chomp $@;
	ok($@, "breaches threw an error when supplied a bad proxy:$@");
	eval {
		$hibp->data_classes();
	};
	chomp $@;
	ok($@, "data_classes threw an error when supplied a bad proxy:$@");
	eval {
		$hibp->account( 'test@example.com' );
	};
	chomp $@;
	ok($@, "account threw an error when supplied a bad proxy:$@");

}
ok(WebService::HIBP->new(user_agent => LWP::UserAgent->new()), "Successfully created a HIBP object with a custom LWP::UserAgent object");
my $teapot = WebService::HIBP->new(user_agent => Acme::LWP::Teapot->new());
ok($teapot, "Successfully created a HIBP object with a custom Acme::LWP::Teapot object");
ok(!defined $teapot->last_request(), "last_request is undefined as no request has been made yet");
ok(!defined $teapot->last_response(), "last_request is undefined as no request has been made yet");
eval {
	$teapot->password($bad_password);
};
ok($@ =~ /^Failed[ ]to[ ]retrieve.*:418.*teapot/, "Threw an exception when the user_agent returns a non-success code for password");
ok(defined $teapot->last_request(), "last_request is defined as a request has been made yet");
ok(defined $teapot->last_response(), "last_request is defined as a request has been made yet");
eval {
	$teapot->account( 'test@example.com' );
};
ok($@ =~ /^Failed[ ]to[ ]retrieve.*:418.*teapot/, "Threw an exception when the user_agent returns a non-success code for account");
eval {
	$teapot->data_classes();
};
ok($@ =~ /^Failed[ ]to[ ]retrieve.*:418.*teapot/, "Threw an exception when the user_agent returns a non-success code for data_classes");
eval {
	$teapot->breach( 'Adobe' );
};
ok($@ =~ /^Failed[ ]to[ ]retrieve.*:418.*teapot/, "Threw an exception when the user_agent returns a non-success code for breach");
eval {
	$teapot->pastes( 'test@example.com' );
};
ok($@ =~ /^Failed[ ]to[ ]retrieve.*:418.*teapot/, "Threw an exception when the user_agent returns a non-success code for pastes");
eval {
	$teapot->breaches();
};
ok($@ =~ /^Failed[ ]to[ ]retrieve.*:418.*teapot/, "Threw an exception when the user_agent returns a non-success code for breaches");

done_testing();

