package DTS_UT::Controller::MainController;

=pod

=head1 NAME

DTS_UT::Controller::MainController - controller implementation for MVC architeture

=head1 DESCRIPTION

C<DTS_UT::Controller::MainController> is the controller for the web application. It is based on L<DTS_UT::Controller> 
class.

This class defines the actions for each run mode available for the web application:

=over

=item *
list_packages

=item *
show_error

=item *
exec_test

=back

=cut

use base qw(DTS_UT::Controller);
use DTS_UT::Model::UnitTestExec;
use DTS_UT::Model::DTS;

=head2 EXPORT

Nothing.

=head2 METHODS

=head3 setup

Does initial configuration. It defines the actions (method invocation) for each run mode available.

=cut

sub setup {

    my $self = shift;

    $self->tmpl_path( $self->config_param('templates_path') );
    $self->start_mode('start');
    $self->error_mode('show_error');
    $self->run_modes(
        {
            'start'     => 'list_packages',
            'error'     => 'show_error',
            'exec_test' => 'exec_test'
        }
    );

}

=head3 list_packages

Invokes C<DTS_UT::Model::DTS> to list the packages available in the server configured in the web application file (YAML
file) and the proper C<HTML::Template> template to display the information.

=cut

sub list_packages {

    my $self = shift;

    my $template = $self->load_tmpl( $self->config_param('index_template') );

    $model = DTS_UT::Model::DTS->new( $self->config_param('ut_config') );

    my @values;
    my $counter = 1;

    foreach my $package ( @{ $model->read_dts_list() } ) {

        push( @values, { ITEM => 'dts' . $counter, PACKAGE => $package } );
        $counter++;

    }

   # :WORKAROUND:10/11/2008:ARFREITAS: to be able to use IIS as webserver, using
   # path_info() method. Additional configuration is necessary in IIS side.
    $template->param(
        MYSELF => $self->query()->url( -absolute => 1 ) |
          $self->query()->path_info(),
        PACKAGES_LIST => \@values
    );

    return $template->output();

}

=head3 show_error

Loads the default C<HTML::Template> template for error messages that occurs in any exception.

=cut

sub show_error {

    my $self      = shift;
    my $error_msg = shift;

    my $template = $self->load_tmpl( $self->config_param('error_template') );

    $template->param( ERROR_MSG => $error_msg );

    return $template->output();

}

=head3 exec_test

Invokes C<DTS_UT::Model::UnitTestExec> to execute the test for the DTS packages selected.

To select parameters, this method expects to receive as parameters with names that start with the regex C</^dts\d+/>
and it will throw an exception with none is find.

=cut

sub exec_test {

    my $self = shift;

    my $template = $self->load_tmpl( $self->config_param('result_template') );

    $model = DTS_UT::Model::UnitTestExec->new(
        $self->config_param('temp_files_path'),
        $self->config_param('ut_config')
    );

    my $query = $self->query();
    my @packages;

    foreach my $param ( $query->param() ) {

        next unless $param =~ /^dts\d+/;
        push( @packages, $query->param($param) );

    }

    unless (@packages) {

        $self->show_error('No package was selected for testing!')

    }
    else {

        my $results;

        eval {
            $results =
              $model->run_tests( \@packages );
        };

        if ($@) {

            $self->show_error($@);

        }
        else {

   # :WORKAROUND:10/11/2008:ARFREITAS: to be able to use IIS as webserver, using
   # path_info() method. Additional configuration is necessary in IIS side.
            $template->param(
                RESULTS => $results,
                MYSELF  => $query->url( -absolute => 1 ) |
                  $self->query()->path_info()
            );

            return $template->output();

        }

    }

}

=head1 SEE ALSO

=over

=item *
L<DTS_UT::Controller>

=item *
L<DTS_UT::Model::UnitTestExec>

=item *
L<DTS_UT::Model::DTS>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
