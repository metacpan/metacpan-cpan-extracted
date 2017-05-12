package Test::If;

use 5.006;
use warnings;
use strict;

=head1 NAME

Test::If - Test only if ...

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Generic usage

    use Test::More;
    use Test::If 'Test::Something', [ tests => N ];
    
    # Is equal to
    
    use Test::More;
    eval q{ use Test::Something; 1 } or plan skip_all => 'Module Test::Something required for this test';
    plan tests => N;

    
    use Test::More;
    use Test::If sub { $ENV{TEST_AUTHOR} }, [ tests => N ];
    
    # Is equal to
    
    use Test::More;
    $ENV{TEST_AUTHOR} or plan skip_all => "Test condition not met";
    plan tests => N;

You can also combine options and it is allowed to omit plan options, if it is runned by loaded module or you want to load it manually

For example common C<pod-coverage.t>:

    use Test::More;
    use Test::If
        sub { $ENV{TEST_AUTHOR} },  # Checked first $ENV{TEST_AUTHOR}, otherwise skip
        'Test::Pod::Coverage 1.08', # Use Test::Pod::Coverage of at least version 1.08
        'Pod::Coverage 0.18',       # And want Pod::Coverage at least of version 0.18
    ;
    
    all_pod_coverage_ok();

If some of conditions will not be met, test will be skipped.

=cut

use Test::Builder ();
use Test::More ();

my $Test = Test::Builder->new;

sub import {
	my $me = shift;
	my $caller = caller;
	$Test->exported_to($caller);
	my $plan;$plan = pop if ref $_[-1] eq 'ARRAY';
	for my $check (@_) {
		if (ref $check eq 'CODE') {
			$check->() or return $Test->plan(skip_all => "Test condition not met");
		}
		else {
			if (eval qq{package main; use $check; 1}) {
				# Module loaded
			}
			else {
				return $Test->plan(skip_all => "Module $check required for this test");
			}
		}
	}
	$Test->plan( @$plan ) if $plan;
	# unless $Test->has_plan;
}


=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Test::If
