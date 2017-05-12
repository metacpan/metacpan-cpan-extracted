package WebService::CloudProvider;

use 5.010;
use Mouse;

# ABSTRACT: WebService::CloudProvider - an interface to cloudprovider.net's RESTful Web API using Web::API

our $VERSION = '0.3'; # VERSION

with 'Web::API';


has 'commands' => (
    is      => 'rw',
    default => sub {
        {
            list_nodes => { method => 'GET' },
            node_info  => { method => 'GET', require_id => 1 },
            create_node => {
                method             => 'POST',
                default_attributes => {
                    allowed_hot_migrate            => 1,
                    required_virtual_machine_build => 1,
                    cpu_shares                     => 5,
                    required_ip_address_assignment => 1,
                    primary_network_id             => 1,
                    required_automatic_backup      => 0,
                    swap_disk_size                 => 1,
                },
                mandatory => [
                    'label',
                    'hostname',
                    'template_id',
                    'cpus',
                    'memory',
                    'primary_disk_size',
                    'required_virtual_machine_build',
                    'cpu_shares',
                    'primary_network_id',
                    'required_ip_address_assignment',
                    'required_automatic_backup',
                    'swap_disk_size',
                ]
            },
            update_node => { method => 'PUT',    require_id => 1 },
            delete_node => { method => 'DELETE', require_id => 1 },
            start_node  => {
                method       => 'POST',
                require_id   => 1,
                post_id_path => 'startup',
            },
            stop_node => {
                method       => 'POST',
                require_id   => 1,
                post_id_path => 'shutdown',
            },
            suspend_node => {
                method       => 'POST',
                require_id   => 1,
                post_id_path => 'suspend',
            },
        };
    },
);


sub commands {
    my ($self) = @_;
    return $self->commands;
}


sub BUILD {
    my ($self) = @_;

    $self->user_agent(__PACKAGE__ . ' ' . $VERSION);
    $self->base_url('https://ams01.cloudprovider.net/virtual_machines');
    $self->auth_type('basic');
    $self->content_type('application/json');
    $self->extension('json');
    $self->wrapper('virtual_machine');
    $self->mapping({
            os        => 'template_id',
            debian    => 1,
            id        => 'label',
            disk_size => 'primary_disk_size',
    });

    return $self;
}


1;    # End of WebService::CloudProvider

__END__

=pod

=head1 NAME

WebService::CloudProvider - WebService::CloudProvider - an interface to cloudprovider.net's RESTful Web API using Web::API

=head1 VERSION

version 0.3

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use WebService::CloudProvider;

    my $foo = WebService::CloudProvider->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 list_nodes

=head2 node_info

=head2 create_node

=head2 update_node

=head2 delete_node

=head2 start_node

=head2 stop_node

=head2 suspend_node

=head1 INTERNALS

=head2 BUILD

basic configuration for the client API happens usually in the BUILD method when using Web::API

=head1 BUGS

Please report any bugs or feature requests on GitHub's issue tracker L<https://github.com/nupfel/WebService-CloudProvider/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::CloudProvider

You can also look for information at:

=over 4

=item * GitHub repository

L<https://github.com/nupfel/WebService-CloudProvider>

=item * MetaCPAN

L<https://metacpan.org/module/WebService::CloudProvider>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService::CloudProvider>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService::CloudProvider>

=back

=head1 AUTHOR

Tobias Kirschstein <lev@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Tobias Kirschstein.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
