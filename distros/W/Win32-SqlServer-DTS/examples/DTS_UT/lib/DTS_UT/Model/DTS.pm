package DTS_UT::Model::DTS;

=pod

=head1 NAME

DTS_UT::Model::DTS - model implementation for MVC architeture

=head1 DESCRIPTION

C<DTS_UT::Model::DTS> is a model of MVC implementation of L<CGI::Application>. It implements all rules related
to the DTS packages available in the MS SQL Server referenced in the web application configuration file.

=cut

use Win32::SqlServer::DTS::Application;
use Config::YAML;
use Params::Validate qw(validate_pos :types);
use base qw(Class::Accessor);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(file));

=head2 EXPORTS

Nothing.

=head2 METHODS

=head3 new

Creates and returns a new C<DTS_UT::Model::DTS> object.

Expects as a parameter the complete pathname to a YAML file with the following keys:

=over

=item 1.
server

=item 2.
use_trusted_connection

=item 3.
user

=item 4.
password

=back

This is exactly the parameters needed by C<Win32::SqlServer::DTS::Application> class to connect to a MS SQL Server.

=cut

sub new {

    validate_pos( @_, { type => SCALAR }, { type => SCALAR } );

    my $class = shift;
    my $self = { file => shift };

    bless $self, $class;

    return $self;

}

=head3 read_dts_list

Connect to a MS SQL Server and retrieve the names of all DTS packages available, returning this list as an array 
reference.

=cut

sub read_dts_list {

    my $self = shift;

    my $list;
    my $app;

    my $yml_conf = Config::YAML->new( config => $self->get_file() );

    eval {

        $app = Win32::SqlServer::DTS::Application->new(
            {
                server => $yml_conf->get_server(),
                use_trusted_connection =>
                  $yml_conf->get_use_trusted_connection()

          # uncomment this if the MS SQL Server does not use trusted connections
          #           ,user                   => $yml_conf->get_user(),
          #           password               => $yml_conf->get_password()

            }
        );

    };

    if ($@) {

        die "Could not connect to SQL Server. $@";

    }
    else {

        return $app->list_pkgs_names();

    }

}

=head1 SEE ALSO

=over

=item *
L<Config::YAML>

=item *
L<Win32::SqlServer::DTS::Application>

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
