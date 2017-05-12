#
# This file is part of Test-LWP-Recorder
#
# This software is copyright (c) 2011 by Edward J. Allen III.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Test::LWP::Recorder;
{
  $Test::LWP::Recorder::VERSION = '0.1.1';
}
BEGIN {
  $Test::LWP::Recorder::AUTHORITY = 'cpan:EALLENIII';
}

# ABSTRACT: Create an LWP UserAgent that records and plays back sessions

use strict;
use warnings;
use 5.006;
use Carp;

use base qw(LWP::UserAgent);
use Digest::MD5 qw(md5_hex);
use File::Slurp;
use File::Spec;
use List::Util qw(reduce);
use HTTP::Status qw(:constants);
use HTTP::Response;

sub new {
    my $class    = shift;
    my %defaults = (
        record        => 0,
        cache_dir     => 't/LWPCache',
        filter_params => [],
        filter_header => [qw(Client-Peer Expires Client-Date Cache-Control)],
    );
    my $params = shift || {};
    my $self = $class->SUPER::new(@_);
    $self->{_test_options} = { %defaults, %{$params} };
    return $self;
}

sub _filter_param {
    my ( $self, $key, $value ) = @_;
    my %filter = map { $_ => 1 } @{ $self->{_test_options}->{filter_params} };
    return join q{=}, $key, $filter{$key} ? q{} : $value;
}

sub _filter_all_params {
    my $self         = shift;
    my $param_string = shift;
    ## no critic (BuiltinFunctions::ProhibitStringySplit)
    my %query = map { ( split q{=} )[ 0, 1 ] } split q{\&}, $param_string;
    ## use critic;
    return %query
        ? reduce { $a . $self->_filter_param( $b, $query{$b} ) }
    sort keys %query
        : q{};
}

sub _get_cache_key {
    my ( $self, $request ) = @_;
    my $params = $request->uri->query() || q{};

    # TODO : Test if it is URL Encoded before blindly assuming.
    if ( $request->content ) {
        $params .= ($params) ? q{&} : q{};
        $params .= $request->content;
    }

    my $key =
          $request->method . q{ }
        . lc( $request->uri->host )
        . $request->uri->path . q{?}
        . $self->_filter_all_params($params);

    #warn "Key is $key";
    return File::Spec->catfile( $self->{_test_options}->{cache_dir},
        md5_hex($key) );
}

sub _filter_headers {
    my ( $self, $response ) = @_;
    foreach ( @{ $self->{_test_options}->{filter_header} } ) {
        $response->remove_header($_);
    }
    return;
}

sub request {
    my ( $self, @original_args ) = @_;
    my $request = $original_args[0];

    my $key = $self->_get_cache_key($request);

    if ( $self->{_test_options}->{record} ) {
        my $response = $self->SUPER::request(@original_args);

        my $cache_response = $response->clone;
        $self->_filter_headers($cache_response);
        $self->_set_cache( $key, $cache_response );

        return $response;
    }

    if ( $self->_has_cache($key) ) {
        return $self->_get_cache($key);
    }
    else {
        carp q{Page requested that wasn't recorded: }
            . $request->uri->as_string;
        return HTTP::Response->new(HTTP_NOT_FOUND);
    }
}

sub _set_cache {
    my ( $self, $key, $response ) = @_;
    write_file( $key, $response->as_string );
    return;
}

sub _has_cache {
    my ( $self, $key ) = @_;
    return ( -f $key );
}

sub _get_cache {
    my ( $self, $key ) = @_;
    my $file = read_file($key);
    return HTTP::Response->parse($file);
}

1;



=pod

=for :stopwords Edward Allen J. III cpan testmatrix url annocpan anno bugtracker rt cpants
kwalitee diff irc mailto metadata placeholders metacpan motemen UserAgent
LWP GPL UA

=encoding utf-8

=head1 NAME

Test::LWP::Recorder - Create an LWP UserAgent that records and plays back sessions

=head1 VERSION

  This document describes v0.1.1 of Test::LWP::Recorder - released September 16, 2013 as part of Test-LWP-Recorder.

=head1 SYNOPSIS

    use Test::LWP::Recorder; 

    my $ua = Test::LWP::Recorder->new({
        record => $ENV{LWP_RECORD},
        cache_dir => 't/LWPCache', 
        filter_params => [qw(api_key api_secret password ssn)],
        filter_header => [qw(Client-Peer Expires Client-Date Cache-Control)],
    });

=head1 DESCRIPTION

This module creates a LWP UserAgent that records interactions to a test
drive.  Setting the "record" parameter to true will cause it to record,
otherwise it plays back.  It is designed for use in test suites.

In the case that a page is requested while in playback mode that was not
recorded while in record mode, a 404 will be returned.

There is another module that does basically the same thing called
L<LWPx::Record::DataSection|LWPx::Record::DataSection>.  Please check this out
before using this module.  It doesn't require a special UA, and stores the
data in the DATA section of your file.  I use this module (a copy in inc/) for
my test suite! 

=head1 METHODS

=head2 new ($options_ref, @lwp_options)

This creates a new object.  Please see L<PARAMETERS|PARAMETERS> for more
details on available options.

The returned object can be used just like any other LWP UserAgent object.

=head2 request

This is overridden from L<LWP::UserAgent|LWP::UserAgent> so we can do our magic.

=head1 PARAMETERS

=head2 record

Setting this to true puts the agent in record mode.  False, in playback.  You
usually want to set this to an environment variable.

=head2 cache_dir

This is the location to store the recordings.  Filenames are all MD5 digests.

=head2 filter_params

This is an ArrayRef of POST or GET parameters to remove when recording.  

The default for this is no filtering.

For example (using the $ua created in the synopsis):

    # This is the request
    my $resp = $ua->get('http://www.mybank.com?password=IAMSOCOOL&ssn=111-11-1111&method=transfer&destination=CH');

    # Because password and ssn are filtered, these parameters will be removed
    # from the object stored.  If a tester in the future makes the following
    # call:
    #

    my $resp = $ua->get('http://www.mybank.com?password=GUESSME&ssn=999-11-9999&method=transfer&destination=CH');

    The cache result from the first will be used.

=head2 filter_header

A list of response headers not stored. 

Default is [qw(Client-Peer Expires Client-Date Cache-Control)];

=head1 DIAGNOSTICS

=head2 Page requested that wasn't recorded 

A page was requested while in playback mode that was not recorded in record
mode. A 404 object will be returned.

=head1 IMPORTANT NOTE

Please note that you should <b>always</b> put this in an inc directory in your
module when using it as part of a test suite.  This is critical because the
filenames in the cache may change as new features are added to the module.

Feel free to just copy the module file over and include it in your inc
(provided that your module uses Perl5, GPL, or Artistic license).  If
you make any changes to it, please change the version number (the last
number).

=head1 ACKNOWLEDGMENTS

Thanks to motemen for L<LWPx::Record::DataSection|LWPx::Record::DataSection> which I use to test this
module (and bundle in the inc/ directory).  It's a great module and a simple
approach.

=head1 BUGS AND LIMITATIONS

This works using a new UserAgent, which may not work for you.

Currently Cookies are ignored.

The filename scheme is pretty lame.

The test suite needs to be extended to include a POST example

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<LWP::UserAgent|LWP::UserAgent>

=item *

L<LWPx::Record::DataSection|LWPx::Record::DataSection>

=back

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Test-LWP-Recorder>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Test::LWP::Recorder>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Test-LWP-Recorder>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Test-LWP-Recorder>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Test-LWP-Recorder>

=back

=head2 Email

You can email the author of this module at C<EALLENIII at cpan.org> asking for help with any problems you have.

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-test-lwp-recorder at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-LWP-Recorder>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/riemann42/Test-LWP-Recorder>

  git clone git://github.com/riemann42/Test-LWP-Recorder.git

=head1 AUTHOR

Edward Allen <ealleniii@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Edward J. Allen III.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__

