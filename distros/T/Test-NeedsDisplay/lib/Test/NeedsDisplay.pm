package Test::NeedsDisplay;

=pod

=head1 NAME

Test::NeedsDisplay - Ensure that tests needing a display have one

=head1 SYNOPSIS

In your Makefile.PL...

  use inc::Module::Install; 
  # ... or whatever else you use
  
  # Check for a display
  use Test::NeedsDisplay;
  
  # ... your Makefile.PL content as normal
  
And again in each test script that loads L<Wx>

  #!/usr/bin/perl
  
  use strict;
  
  use Test::NeedsDisplay;
  
  # Test content as normal...

=head1 DESCRIPTION

When testing GUI applications, sometimes applications or modules
absolutely insist on a display, even just to load a module without
actually showing any objects.

Regardless, this makes GUI applications pretty much impossible to
build and test on headless or automated systems. And it fails to
the point of not even running the Makefile.PL script because
a dependency needs a display so it can be loaded to find a version.

In these situations, what is needed is a fake display.

The C<Test::NeedsDisplay> module will search around and try to find
a way to load some sort of display that can be used for the testing.

=head2 Strategies for Finding a Display

At this time, only a single method is used (and a very simple one).

Debian Linux has a script called C<xvfb-run> which is a wrapper for
the C<xvfb>, a virtual X server which uses the linux frame buffer.

When loaded without a viable display, the module will re-exec the
same script using something like (for example) C<xvfb-run test.t>.

As such, it should be loaded as early as possible, before anything
has a chance to change script parameters. These params will be
resent through to the script again.

=head1 METHODS

There are no methods. You simply use the module as early as possible,
probably right after C<use strict;> and make sure to load it with
only default params.

Specifically, need must B<always> load it before you set the test plan,
otherwise the test script will report two plans, and the harness will
complain about it and die.

  # Use it like this ...
  use Test::NeedsDisplay;
  
  # ... not like this ...
  use Test::NeedsDisplay 'anything';
  
  # ... and not like this.
  use Test::NeedsDisplay ();

And that's all there is to do. The module will take care of the rest.

=cut

use 5.006;
use strict;
use Config     ();
use File::Spec ();
use Test::More ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.07';
}

sub import {
	# Get rid of Win32 and existing DISPLAY cases
	return 1 if $^O eq 'MSWin32';
	return 1 if $ENV{DISPLAY};

	# The quick way is to use the xvfb-run script
	print "# No DISPLAY. Looking for xvfb-run...\n";
	my @PATHS = split $Config::Config{path_sep}, $ENV{PATH};
	foreach my $path ( @PATHS ) {
		my $xvfb_run = File::Spec->catfile( $path, 'xvfb-run' );
		next unless -e $xvfb_run;
		next unless -x $xvfb_run;
		print "# Restarting with xvfb-run...\n";
		exec(
			$xvfb_run,
			$^X,
			($INC{'blib.pm'} ? '-Mblib' : ()),
			($INC{'perl5db.pl'} ? '-d' : ()),
			$0,
		);
	}

	# If provided with the :skip_all, abort the run
	if ( $_[1] and $_[1] eq ':skip_all' ) {
		Test::More::plan( skip_all => 'Test needs a DISPLAY' );
		exit(0);
	}

	print "# Failed to find xvfb-run.\n";
	print "# Running anyway, but will probably fail...\n";
}

1;

=pod

=head1 TO DO

- Find alternative ways to launch a display on different platforms

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-NeedsDisplay>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2005 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
