# http://blogs.perl.org/users/sawyer_x/2010/08/distzilla-strictures-tip.html
use strictures 1;

package WebService::NotifyMyAndroid;
{
  $WebService::NotifyMyAndroid::VERSION = '0.0.6';
}
{
  $WebService::NotifyMyAndroid::DIST = 'WebService-NotifyMyAndroid';
}
use base qw( WebService::Simple );

binmode STDOUT, ":encoding(UTF-8)";

use Carp;
use Params::Validate qw( :all );
use Readonly;
use Regexp::Common qw( number );

# make sure we have the https protocol available to us;
# we need this to do anything this the API url
use LWP::Protocol::https;

# Module implementation here

# constants
Readonly my $NMA_URL        => 'https://www.notifymyandroid.com/publicapi/';

# string lengths in characters
Readonly my $KEYLENGTH      => 48;
Readonly my $APPLENGTH      => 256;
Readonly my $EVENTLENGTH    => 1000;
Readonly my $DESCLENGTH     => 10000;

# validation regexes
## we're using the 'weird' format for setting flags because strictures
## complains about 'use of multidimensional array emulation' with the
## "{-base => 16}" syntax
##  for more information read the documentation for strictures,
##  multidimensional and Regexp::Common (Flag syntax)
Readonly my $KEYREGEX       => $RE{num}{int}{"-base$;16"}{"-places$;$KEYLENGTH"};
Readonly my $APPREGEX       => ".{1,$APPLENGTH}";
Readonly my $EVENTREGEX     => ".{1,$EVENTLENGTH}";
Readonly my $DESCREGEX      => ".{1,$DESCLENGTH}";
Readonly my $PRIOREGEX      => "(?:-?[12]+|0)";

# NMA-specific configuration
__PACKAGE__->config(
    base_url        => $NMA_URL,
    response_parser => 'XML::Simple',
);

# public functions

my %verify_spec = (
    apikey => {
        type => SCALAR,
        callbacks => {
            'valid API key' => \&_valid_api_key,
        },
    },
    developerkey => {
        optional => 1,
        type => SCALAR,
        callbacks => {
            'valid API key' => \&_valid_api_key,
        },
    },
);

sub verify {
    my ($self, @args) = @_;
    my %params = validate( @args, \%verify_spec );
    return $self->get( 'verify', \%params )->parse_response;
}

my %notify_spec = (
    apikey => {
        type => SCALAR | ARRAYREF,
        callbacks => {
            'valid API key' => \&_valid_api_key,
        },
    },
    application => {
        type => SCALAR,
        regex => qr/^$APPREGEX$/xms,
    },
    event => {
        type => SCALAR,
        regex => qr/^$EVENTREGEX$/xms,
    },
    description => {
        type => SCALAR,
        regex => qr/^$DESCREGEX$/xms,
    },
    priority => {
        optional => 1,
        type => SCALAR,
        regex => qr/^$PRIOREGEX$/xms,
        default => 0,
    },
    developerkey => {
        optional => 1,
        type => SCALAR,
        callbacks => {
            'valid API key' => \&_valid_api_key,
        },
    },
);

sub notify {
    my ($self, @args) = @_;
    my %params = validate( @args, \%notify_spec );
    return $self->post( 'notify', \%params )->parse_response;
}

# private functions

sub _valid_api_key {
    my( $candidate, $params ) = @_;

    if ( ref( $candidate ) eq 'ARRAY' ) {
        foreach my $key ( @{$candidate} ) {
            _valid_api_key( $key ) or return;
        }
    }
    else {
        $candidate =~ /^$KEYREGEX$/ixms or return;
    }
    return( $candidate );
}

1; # Magic true value required at end of module
# ABSTRACT: Perl interface to Notify My Android web API

__END__

=pod

=head1 NAME

WebService::NotifyMyAndroid - Perl interface to Notify My Android web API

=head1 VERSION

version 0.0.6

=head1 SYNOPSIS

    use WebService::NotifyMyAndroid;

    my $nma = WebService::NotifyMyAndroid->new;

    # verify an existing API key
    my $result = $nma->verify( apikey => $my_api_key );
    defined( $result->{success} ) or die( $result->{error}->{content} );

    # send a message
    my $message = $nma->notify(
        apikey      => [ $my_first_api_key, $my_second_api_key, ],
        application => 'The Printer',
        event       => 'I can't print!',
        description => 'Really, I cannot print.  Please come help me.',
        priority    => 1,
    );
    defined( $message->{success} ) or die( $message->{error}->{content} );

=head1 DESCRIPTION

C<WebService::NotifyMyAndroid> is a Perl interface to the Notify My Android (http://www.notifymyandroid.com/) web API.  One or more NMA API keys are necessary in order to use this module.

=head1 INTERFACE 

=head2 verify(%params)

Documentation located at L<http://www.notifymyandroid.com/api.jsp>.

=head2 notify(%params)

Documentation located at L<http://www.notifymyandroid.com/api.jsp>.

=head1 DIAGNOSTICS

FIXME!  Error handling is pathetic at this point.

=head1 CONFIGURATION AND ENVIRONMENT

WebService::NotifyMyAndroid requires no configuration files or environment variables.  Future development will support a custom NMA API URL.

=head1 DEPENDENCIES

=over

=item L<Readonly>

=item L<Regexp::Common>

=item L<WebService::Simple>

=item L<XML::Simple>

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-webservice-nma@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

=over

=item write a real README

=item command-line tool for generating notifications

=item integration with other tools: MTAs? Nagios? IM?

=back

=head1 SEE ALSO

L<WebService::Prowl>

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 AUTHORS

=over 4

=item *

Steve Huff <shuff@cpan.org>

=item *

Chisel <chisel@chizography.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
