#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok('WebService::HIBP') || print "Bail out!\n";
}

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
        ok( $breach->logo_type(),
            "Logo Type of breach is '" . $breach->logo_type() . "'" );
        ok( defined $breach->is_active(),
            "Breach is " . ( $breach->is_active() ? 'active' : 'NOT active' ) );
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
        elsif ( defined $breach->logo_type() ) {
        }
        elsif ( defined $breach->is_active() ) {
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
    my $bad_password = 'password1';
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
done_testing();

