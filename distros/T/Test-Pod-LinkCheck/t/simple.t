#!/usr/bin/perl
#
# This file is part of Test-Pod-LinkCheck
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;

use Test::Tester;
use Test::More;
use Test::Pod::LinkCheck;
use File::Temp qw( tempfile );

my %tests = (
	'empty'		=> {
		pod		=> '',
		actual_ok	=> 1,
	},
	'error'		=> {
		pod		=> "=head999",
		actual_ok	=> 0,
	},
	'plain'		=> {
		pod		=> "=head1 NAME\n\nHello from Foobar!",
		actual_ok	=> 1,
	},
	'pass'		=> {
		pod		=> "=head1 NAME\n\nHello from Foobar! Please visit L<Test::More> for more info!",
		actual_ok	=> 1,
		todo		=> "CPAN backends are not configured everywhere, thanks CPANTesters!",
	},
	'pass_cpan'		=> {
		pod		=> "=head1 NAME\n\nHello from Foobar! Please visit L<Acme::Drunk> for more info!",
		actual_ok	=> 1,
		todo		=> "CPAN backends are not configured everywhere, thanks CPANTesters!",
	},
	'invalid'	=> {
		pod		=> "=head1 NAME\n\nHello from Foobar! Please visit L<More::Fluffy::Stuff> for more info!",
		actual_ok	=> 0,
		todo		=> "CPAN backends are not configured everywhere, thanks CPANTesters!",
	},
	'invalid_sec'	=> {
		pod		=> "=head1 NAME\n\nHello from L</Foobar>!",
		actual_ok	=> 0,
	},
	'invalid_sec_quo'=> {
		pod		=> "=head1 NAME\n\nHello from L<\"Foobar\">!",
		actual_ok	=> 0,
	},
	'invalid_sec_text'=> {
		pod		=> "=head1 NAME\n\nHello from L<foo|\"Foobar\">!",
		actual_ok	=> 0,
	},
	'invalid_sec2_text'=> {
		pod		=> "=head1 NAME\n\nHello from L<foo|/Foobar>!",
		actual_ok	=> 0,
	},
	'pass_sec'	=> {
		pod		=> "=head1 NAME\n\nHello from L</Zonkers>!\n\n=head1 Zonkers\n\nThis is the Foobar!",
		actual_ok	=> 1,
	},
	'pass_sec2'	=> {
		pod		=> "=head1 NAME\n\nHello from us!\n\n=head1 Zonkers\n\nThis is the Foobar!\n\n=head1 Welcome\n\nL</Zonkers>",
		actual_ok	=> 1,
	},
	'pass_sec_quo'	=> {
		pod		=> "=head1 NAME\n\nHello from L<\"Zonkers\">!\n\n=head1 Zonkers\n\nThis is the Foobar!",
		actual_ok	=> 1,
	},
	'pass_sec2_quo'	=> {
		pod		=> "=head1 NAME\n\nHello from us!\n\n=head1 Zonkers\n\nThis is the Foobar!\n\n=head1 Welcome\n\nL<\"Zonkers\">",
		actual_ok	=> 1,
	},
	'pass_sec_text'	=> {
		pod		=> "=head1 NAME\n\nHello from L<zonk|\"Zonkers\">!\n\n=head1 Zonkers\n\nThis is the Foobar!",
		actual_ok	=> 1,
	},
	'pass_sec2_text'	=> {
		pod		=> "=head1 NAME\n\nHello from us!\n\n=head1 Zonkers\n\nThis is the Foobar!\n\n=head1 Welcome\n\nL<zonk|\"Zonkers\">",
		actual_ok	=> 1,
	},
	'pass_sec3_text'	=> {
		pod		=> "=head1 NAME\n\nHello from us!\n\n=head1 Zonkers\n\nThis is the Foobar!\n\n=head1 Welcome\n\nL<zonk|/Zonkers>",
		actual_ok	=> 1,
	},
	'pass_man'	=> {
		pod		=> "=head1 NAME\n\nHello from L<man(1)>!",
		actual_ok	=> 1,
		todo		=> "man is not installed everywhere, thanks CPANTesters!",
	},
	'invalid_man'	=> {
		pod		=> "=head1 NAME\n\nHello from L<famboozled_not_exists(9)>!",
		actual_ok	=> 0,
		todo		=> "man is not installed everywhere, thanks CPANTesters!",
	},
	'perlfunc'	=> {
		pod		=> "=head1 NAME\n\nHello from us!\n\n=head1 Zonkers\n\nThis is the Foobar!\n\n=head1 Welcome\nLook at L<binmode> for info.",
		actual_ok	=> 1,
		todo		=> "perldoc is not installed everywhere, thanks CPANTesters!",
	},
);

plan tests => ( scalar keys %tests ) *  5;

foreach my $t ( keys %tests ) {
	# Add some generic data
	if ( $tests{ $t }{'actual_ok'} ) {
		$tests{ $t }{'ok'} = 1;
	} else {
		$tests{ $t }{'ok'} = 0;
	}
	$tests{ $t }{'depth'} = 1;

	my( $premature, @results ) = eval {
		run_tests(
			sub {
				my( $fh, $filename ) = tempfile( UNLINK => 1 );
				$fh->autoflush( 1 );
				print $fh delete $tests{ $t }{'pod'};
				my $checker = Test::Pod::LinkCheck->new;
				my $is_todo = $tests{ $t }{'todo'};
				if ( defined $is_todo ) {
					TODO: {
						local $TODO = $is_todo;
						$checker->pod_ok( $filename );
					}
				} else {
					$checker->pod_ok( $filename );
				}
				undef $checker;
			},
		);
	};

	# mangle the TODO stuff
	if ( exists $tests{ $t }{'todo'} ) {
		$results[0]->{'ok'} = $tests{ $t }{'ok'};
		$results[0]->{'actual_ok'} = $tests{ $t }{'actual_ok'};
		delete $tests{ $t }{'todo'};
	}

	ok( ! $@, "$t completed" );
	is( scalar @results, 1, "$t contained 1 test" );

	# compare the result
	foreach my $res ( keys %{ $tests{ $t } } ) {
		is( $results[0]->{ $res }, $tests{ $t }{ $res }, "$res for $t" );
	}
}

done_testing();
