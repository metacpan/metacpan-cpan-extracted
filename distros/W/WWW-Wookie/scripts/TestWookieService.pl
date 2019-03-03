#!/usr/bin/env perl    # -*- cperl; cperl-indent-level: 4 -*-
use strict;
use warnings;

use utf8;
use 5.020000;

our $VERSION = 'v1.1.1';

use lib qw(./lib ../lib);

use CGI qw/:all/;
## no critic qw(ProhibitDebuggingModules)
use Data::Dumper qw/Dumper/;
## use critic
use HTTP::Server::Brick;

use lib q{../lib};
use Getopt::Long;
use Pod::Usage;
use WWW::Wookie::Connector::Service;
use WWW::Wookie::User;
use WWW::Wookie::Widget::Property;

use Readonly;
## no critic qw(ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $CONNECTOR_PORT  => 8081;
Readonly::Scalar my $WOOKIE_SERVER   => q{http://localhost:8080/wookie/};
Readonly::Scalar my $API_KEY         => q{TEST};
Readonly::Scalar my $SHARED_DATA_KEY => q{localhost_dev};
Readonly::Scalar my $USER            => q{demo_1};
Readonly::Scalar my $DEMO_PROP       => q{demo_property};
Readonly::Scalar my $DEMO_VAL        => q{demo_value};
Readonly::Scalar my $LOCALE          => q{en};

Readonly::Scalar my $STRIP_QUERY => qr{^/[?]}sxm;

Readonly::Scalar my $EMPTY           => q{};
Readonly::Scalar my $ROOT            => q{/};
Readonly::Scalar my $GET             => q{GET};
Readonly::Scalar my $ERROR           => q{error};
Readonly::Scalar my $SELECT          => q{Select};
Readonly::Scalar my $WOOKIE_TITLE    => q{Wookie Connector Framework Test};
Readonly::Scalar my $NO_WIDGET       => q{No widget selected};
Readonly::Scalar my $USERS_AFTER_DEL => q{Users after delete};
Readonly::Scalar my $PROPS_AFTER_DEL => q{Properties after delete};

Readonly::Array my @GETOPT_CONFIG =>
  qw(no_ignore_case bundling auto_version auto_help);
Readonly::Array my @GETOPTIONS =>
  ( q{server|s=s}, q{port|p=s}, q{help|h}, q{verbose|v+}, );
Readonly::Hash my %OPTS_DEFAULT => (
    'server' => $WOOKIE_SERVER,
    'port'   => $CONNECTOR_PORT,
);

Readonly::Array my @IDS => (
    { 'id' => q{widget_id},  'login' => q{demo_2} },
    { 'id' => q{widget_id2}, 'login' => q{demo_425} },
);
## use critic

Getopt::Long::Configure(@GETOPT_CONFIG);
my %opts = %OPTS_DEFAULT;
Getopt::Long::GetOptions( \%opts, @GETOPTIONS ) or Pod::Usage::pod2usage(2);

my $server = HTTP::Server::Brick->new( 'port' => $opts{'port'} );

$server->mount(
    $ROOT => {
        'handler'  => \&main,
        'wildcard' => 1,
    },
);

sub main {
    my ( $req, $res ) = @_;
    my $uri = $req->uri;
    $uri =~ s{$STRIP_QUERY}{}smx;
    my $q = CGI->new($uri);
    my $test =
      WWW::Wookie::Connector::Service->new( $opts{'server'}, $API_KEY,
        $SHARED_DATA_KEY, $USER );
    $test->setLocale($LOCALE);
    $test->getUser->setLoginName($USER);
    my @available_widgets = $test->getAvailableWidgets;

    $res->add_content( $q->start_html($WOOKIE_TITLE) );

    if ( !$test->getConnection->test ) {
        $res->add_content( $ERROR . $q->br );
    }

    $res->add_content( $q->start_pre
          . $q->start_form( { 'method' => $GET, 'action' => $EMPTY } ) );

    for my $id (@IDS) {
        my %labels = ( $EMPTY => $NO_WIDGET );
        foreach my $widget (@available_widgets) {
            $labels{ $widget->getIdentifier } = $widget->getTitle;
        }
        $res->add_content(
            $q->popup_menu(
                {
                    'name'    => $id->{'id'},
                    'values'  => [ sort keys %labels ],
                    'labels'  => \%labels,
                    'default' => [ $q->param( $id->{'id'} ) ],
                },
            ),
        );
    }

    $res->add_content( $q->submit( { 'value' => $SELECT } ) . $q->end_form );

    for my $id (@IDS) {
        if ( defined $q->param( $id->{'id'} )
            && $q->param( $id->{'id'} ) ne $EMPTY )
        {
            $test->getUser->setLoginName( $id->{'login'} );
            my $widget = $test->getOrCreateInstance( $q->param( $id->{'id'} ) );
            if ($widget) {
                $res->add_content(
                    $q->start_iframe(
                        {
                            'src'    => $widget->getUrl,
                            'width'  => $widget->getWidth,
                            'height' => $widget->getHeight,
                        },
                      )
                      . $q->end_iframe
                      . $q->br,
                );
                $test->addParticipant( $widget,
                    WWW::Wookie::User->new( $id->{'login'}, $id->{'login'} ) );
                $res->add_content(
                    $q->escapeHTML(
                        Data::Dumper::Dumper $test->getUsers($widget),
                    ),
                );

                ( $id != $IDS[0] ) && next;
                $test->deleteParticipant( $widget,
                    WWW::Wookie::User->new( $id->{'login'}, $id->{'login'} ) );
                $res->add_content(
                        $USERS_AFTER_DEL
                      . $q->br
                      . $q->escapeHTML(
                        Data::Dumper::Dumper $test->getUsers($widget),
                      )
                      . $q->escapeHTML(
                        Data::Dumper::Dumper $test->setProperty(
                            $widget,
                            WWW::Wookie::Widget::Property->new(
                                $DEMO_PROP, $DEMO_VAL,
                            ),
                        ),
                      )
                      . $PROPS_AFTER_DEL
                      . $q->br
                      . (
                        $q->escapeHTML(
                            Data::Dumper::Dumper $test->deleteProperty(
                                $widget,
                                WWW::Wookie::Widget::Property->new($DEMO_PROP),
                            ),
                          )
                          || $EMPTY
                      )
                      . $q->br,
                );
            }
        }
    }

    $res->add_content(
        $q->escapeHTML( Data::Dumper::Dumper( $test->WidgetInstances->get ) )
          . $q->end_pre
          . $q->end_html );

    $res->header( 'Content-Type', 'application/xhtml+xml' );
    return 1;
}

$server->start;

__END__

=encoding utf8

=for stopwords CGI Readonly TestWookieService.pl Ipenburg Wookie MERCHANTABILITY

=head1 NAME

TestWookieService.pl - HTTP server for testing the Apache Wookie Connector
Framework Perl implementation

=head1 VERSION

This document describes C<TestWookieService.pl> version v1.1.1

=head1 USAGE

    ./TestWookieService.pl --server=http://localhost:8080/wookie/ --port=8081

=head1 REQUIRED ARGUMENTS

None.

=head1 OPTIONS

=over 4

=item B<--server> URL of the Wookie server, default
L<http://localhost:8080/wookie/|http://localhost:8080/wookie/>

=item B<--port> Port number on which this HTTP server will be listening on
C<localhost>, default port 8081 

=back

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 DEPENDENCIES

=over 4

=item * L<CGI|CGI>

=item * L<Data::Dumper|Data::Dumper>

=item * L<Getopt::Long|Getopt::Long>

=item * L<HTTP::Server::Brick|HTTP::Server::Brick>

=item * L<Pod::Usage|Pod::Usage>

=item * L<Readonly|Readonly>

=item * L<WWW::Wookie::Connector::Service|WWW::Wookie::Connector::Service>

=item * L<WWW::Wookie::User|WWW::Wookie::User>

=item * L<WWW::Wookie::Widget::Property|WWW::Wookie::Widget::Property>

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 DESCRIPTION

This starts an HTTP service which presents an HTML page that interacts with an
Apache Wookie Server using a Perl implementation of the Apache Wookie
Connector Framework.  For more information see:
L<http://wookie.apache.org|http://wookie.apache.org>

=head1 CONFIGURATION AND ENVIRONMENT

Using the defaults it starts the HTTP service on port 8081 and tries to
connect to an Apache Wookie service on C<localhost> port 8080.

=head1 AUTHOR

Roland van Ipenburg, E<lt>ipenburg@xs4all.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 by Roland van Ipenburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
