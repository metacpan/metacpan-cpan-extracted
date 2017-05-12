package WWW::Pipeline::Example;
$VERSION = '0.1';

use base 'WWW::Pipeline';

=head1 WWW::Pipeline::Example

This module is a simple example application to demonstrate the very basic
pieces of building an application with WWW::Pipeline.  In order to run this
application, create an instance script that looks like the following:

 #!/usr/bin/perl

 use strict;
 use warnings;

 use WWW::Pipeline::Example;

 my $application = WWW::Pipeline::Example->new();
 $application->run();

 exit(0);

Give it the appropriate executable permissions and place it in a web-accessible
directory.  Assuming everything has been set correctly, pointing your browser
at the script should give you access to a very simple two page application.

=cut

#-- pragmas ---------------------------- 
 use strict;
 use warnings;

#===============================================================================

=head2 the C<%plan>

  For this application we've set up two handlers.  During the Initialization
Phase, we've registered the C<_setup> method.  During the ParseRequest Phase,
we've added the C<_grepMode> method.  Other phases of the pipeline are populated
by a few plugins we load in the C<_setup> method.

=cut

our %plan = (
    Initialization => [ \&_setup ],
    ParseRequest   => [ \&_grepMode ],
);

#== Handlers ===================================================================

=head2 the Handlers

=head3 _setup

During the C<_setup> method we load the plugins C<CGISimple>, C<RunModes>, and
C<Output>. C<CGISimple> gives us a query() method which returns a CGI::Simple
instance. C<RunModes> provides an easy way to manage the multiple screens that
need to be generated for the typical web application. C<Output> provides means
for setting http headers and sending the formulated response back to the client.

Once we've got RunModes loaded we also take this opportunity to tell our
application which run modes this application will have.  The two implemented
run modes are described later.

=cut

sub _setup {
    my $self = shift;
    $self->loadPlugins( qw( CGISimple RunModes Output ) );

    $self->run_modes(
        start => \&start,
        next  => 'next'
    );

    $self->mode('start');
}

#-------------------------------------------------------------------------------

=head3 _grepMode

The C<_grepMode> method is run during the ParseRequest phase of the pipeline,
and looks for the query parameter 'op' to tell the application which run mode
it should run.

=cut

sub _grepMode {
    my $self = shift;
    $self->mode( $self->query->param('op') );
}

#== Run Modes ==================================================================

=head2 Run Modes

Since we're using the C<RunModes> plugin to manage our application state for any
given request, we have defined two run modes, C<start> and C<next>. Each
generate a simple html page with a link to the other.  They link to each other
by defining the C<op> parameter in the url's query string, which is picked up
by the application's C<_grepMode> handler to determine which page should be
generated.

=cut

sub start {

    return qq(
       hello world, this is the start page<br />
       <a href="example.cgi?op=next" >next</a>
    );
}

#-------------------------------------------------------------------------------
sub next {

    return qq(
       hello world, this is the next page<br />
       <a href="example.cgi?op=start" >back to start</a>
    );
}

#========
1;

=head2 See Also

WWW::Pipeline
Application::Pipeline

WWW::Pipeline::Services::RunModes
WWW::Pipeline::Services::Output
WWW::Pipeline::Services::CGISimple

CGI::Application

=head2 Authors

Stephen Howard <stephen@thunkit.com>

=head2 License

This module may be distributed under the same terms as Perl itself.

=cut
