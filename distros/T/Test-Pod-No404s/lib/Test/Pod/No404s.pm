#
# This file is part of Test-Pod-No404s
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Test::Pod::No404s;
# git description: release-0.01-6-g2201bfb
$Test::Pod::No404s::VERSION = '0.02';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Using this test module will check your POD for any http 404 links

# Import the modules we need
use Pod::Simple::Text;
use LWP::UserAgent;
use URI::Find;
use Test::Pod ();

# setup our tests and etc
use Test::Builder;
my $Test = Test::Builder->new;

# auto-export our 2 subs
use parent qw( Exporter );
our @EXPORT = qw( pod_file_ok all_pod_files_ok ); ## no critic ( ProhibitAutomaticExportation )

#pod =method pod_file_ok
#pod
#pod C<pod_file_ok()> will okay the test if there is no http(s) links present in the POD or if all links are not an error. Furthermore, if the POD was
#pod malformed as reported by L<Pod::Simple>, the test will fail and not attempt to check the links.
#pod
#pod When it fails, C<pod_file_ok()> will show any failing links as diagnostics.
#pod
#pod The optional second argument TESTNAME is the name of the test.  If it is omitted, C<pod_file_ok()> chooses a default
#pod test name "404 test for FILENAME".
#pod
#pod =cut

sub pod_file_ok {
	my $file = shift;
	my $name = @_ ? shift : "404 test for $file";

	if ( ! -f $file ) {
		$Test->ok( 0, $name );
		$Test->diag( "$file does not exist" );
		return;
	}

	# Parse the POD!
	my $parser = Pod::Simple::Text->new;
	my $output;
	$parser->output_string( \$output );
	$parser->complain_stderr( 0 );
	$parser->no_errata_section( 0 );
	$parser->no_whining( 0 );

	# safeguard ourself against crazy parsing failures
	eval { $parser->parse_file( $file ) };
	if ( $@ ) {
		$Test->ok( 0, $name );
		$Test->diag( "Unable to parse POD in $file => $@" );
		return;
	}

	# is POD well-formed?
	if ( $parser->any_errata_seen ) {
		$Test->ok( 0, $name );
		$Test->diag( "Unable to parse POD in $file" );

		# TODO ugly, but there is no other way to get at it?
		foreach my $l ( keys %{ $parser->{errata} } ) {
			$Test->diag( " * errors seen in line $l:" );
			$Test->diag( "   * $_" ) for @{ $parser->{errata}{$l} };
		}

		return 0;
	}

	# Did we see POD in the file?
	if ( $parser->doc_has_started ) {
		my @links;
		my $finder = URI::Find->new( sub {
			my($uri, $orig_uri) = @_;
			my $scheme = $uri->scheme;
			if ( defined $scheme and ( $scheme eq 'http' or $scheme eq 'https' ) ) {
				# we skip RFC 6761 addresses reserved for testing and etc
				if ( $uri->host !~ /(?:test|localhost|invalid|example|example\.com|example\.net|example\.org)$/ ) {
					push @links, [$uri,$orig_uri];
				}
			}
		} );
		$finder->find( \$output );

		if ( scalar @links ) {
			# Verify the links!
			my $ok = 1;
			my @errors;
			my $ua = LWP::UserAgent->new;
			foreach my $l ( @links ) {
				$Test->diag( "Checking $l->[0]" );
				my $response = $ua->head( $l->[0] );
				if ( $response->is_error ) {
					$ok = 0;
					push( @errors, [ $l->[1], $response->status_line ] );
				}
			}

			$Test->ok( $ok, $name );
			foreach my $e ( @errors ) {
				$Test->diag( "Error retrieving '$e->[0]': $e->[1]" );
			}
		} else {
			$Test->ok( 1, $name );
		}
	} else {
		$Test->ok( 1, $name );
	}

	return 1;
}

#pod =method all_pod_files_ok
#pod
#pod This function is what you will usually run. It automatically finds any POD in your distribution and runs checks on them.
#pod
#pod Accepts an optional argument: an array of files to check. By default it checks all POD files it can find in the distribution. Every file it finds
#pod is passed to the C<pod_file_ok> function.
#pod
#pod =cut

sub all_pod_files_ok {
	my @files = @_ ? @_ : Test::Pod::all_pod_files();

	$Test->plan( tests => scalar @files );

	my $ok = 1;
	foreach my $file ( @files ) {
		pod_file_ok( $file ) or undef $ok;
	}

	return $ok;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders metacpan

=head1 NAME

Test::Pod::No404s - Using this test module will check your POD for any http 404 links

=head1 VERSION

  This document describes v0.02 of Test::Pod::No404s - released November 01, 2014 as part of Test-Pod-No404s.

=head1 SYNOPSIS

	#!/usr/bin/perl
	use strict; use warnings;

	use Test::More;

	eval "use Test::Pod::No404s";
	if ( $@ ) {
		plan skip_all => 'Test::Pod::No404s required for testing POD';
	} else {
		all_pod_files_ok();
	}

=head1 DESCRIPTION

This module looks for any http(s) links in your POD and verifies that they will not return a 404. It uses L<LWP::UserAgent> for the heavy
lifting, and simply lets you know if it failed to retrieve the document. More specifically, it uses $response->is_error as the "test."

This module does B<NOT> check "pod" or "man" links like C<LE<lt>Test::PodE<gt>> in your pod. For that, please check out L<Test::Pod::LinkCheck>.

Normally, you wouldn't want this test to be run during end-user installation because they might have no internet! It is HIGHLY recommended
that this be used only for module authors' RELEASE_TESTING phase. To do that, just modify the synopsis to add an env check :)

=head1 METHODS

=head2 pod_file_ok

C<pod_file_ok()> will okay the test if there is no http(s) links present in the POD or if all links are not an error. Furthermore, if the POD was
malformed as reported by L<Pod::Simple>, the test will fail and not attempt to check the links.

When it fails, C<pod_file_ok()> will show any failing links as diagnostics.

The optional second argument TESTNAME is the name of the test.  If it is omitted, C<pod_file_ok()> chooses a default
test name "404 test for FILENAME".

=head2 all_pod_files_ok

This function is what you will usually run. It automatically finds any POD in your distribution and runs checks on them.

Accepts an optional argument: an array of files to check. By default it checks all POD files it can find in the distribution. Every file it finds
is passed to the C<pod_file_ok> function.

=head1 EXPORT

Automatically exports the two subs.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Test::Pod::LinkCheck|Test::Pod::LinkCheck>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Test::Pod::No404s

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Test-Pod-No404s>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Test-Pod-No404s>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Pod-No404s>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Test-Pod-No404s>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Test-Pod-No404s>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Test-Pod-No404s>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/overview/Test-Pod-No404s>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Test-Pod-No404s>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Test-Pod-No404s>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Test::Pod::No404s>

=back

=head2 Email

You can email the author of this module at C<APOCAL at cpan.org> asking for help with any problems you have.

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #perl-help then talk to this person for help: Apocalypse.

=item *

irc.freenode.net

You can connect to the server at 'irc.freenode.net' and join this channel: #perl then talk to this person for help: Apocal.

=item *

irc.efnet.org

You can connect to the server at 'irc.efnet.org' and join this channel: #perl then talk to this person for help: Ap0cal.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-test-pod-no404s at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Pod-No404s>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/apocalypse/perl-test-pod-no404s>

  git clone git://github.com/apocalypse/perl-test-pod-no404s.git

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
