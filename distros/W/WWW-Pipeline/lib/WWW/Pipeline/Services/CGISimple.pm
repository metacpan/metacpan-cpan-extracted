package WWW::Pipeline::Services::CGISimple;
$VERSION = '0.1';

#-- pragmas ---------------------------- 
 use strict;
 use warnings;

#-- modules ---------------------------- 
 use CGI::Simple;

=head1 WWW::Pipeline::Services::CGISimple

This plugin for Application::Pipeline makes available a query object, which is
simply a CGI::Simple instance. To access it from the Application::Pipeline
subclass:

$pipeline->loadPlugin( 'CGISimple' );

$query = $pipeline->query();

Optionally, you may indicate to CGI::Simple that you want to enable uploads,
like so:

$pipeline->loadPlugin( 'CGISimple',
        DISABLE_UPLOADS => 0
);

As CGI::Simple disables them by default.

=cut

#===============================================================================
sub load {
    my( $class, $pipeline, %args ) = @_;

    $CGI::Simple::DISABLE_UPLOADS = ( $args{DISABLE_UPLOADS} ) ? 1 : 0;
    my $cgi = CGI::Simple->new();
    $pipeline->addServices( query => $cgi );

    return $cgi;
}

#========
1;

=head2 Authors

Stephen Howard <stephen@thunkit.com>

=head2 License

This module may be distributed under the same terms as Perl itself.

=cut
