package WebService::Rackspace::DNS;

use 5.010;
use Mouse;

# ABSTRACT: WebService::Rackspace::DNS - an interface to rackspace.com's RESTful Cloud DNS API using Web::API

our $VERSION = '0.1'; # VERSION

with 'Web::API';


has 'location' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { '' },
);


has 'commands' => (
    is      => 'rw',
    default => sub {
        {
            # needed for login()
            tokens => {
                method    => 'POST',
                path      => 'tokens',
                mandatory => [ 'user', 'api_key' ],
                wrapper   => [ 'auth', 'RAX-KSKEY:apiKeyCredentials' ],
            },

            # limits
            limits      => { path => 'limits' },
            limit_types => { path => 'limits/types' },
            limit       => { path => 'limits/:id' },

            # domains
            domains        => { path => 'domains' },
            domain         => { path => 'domains/:id' },
            domain_history => { path => 'domains/:id/changes', },
            zonefile       => { path => 'domains/:id/export', },
            create_domain  => {
                method    => 'POST',
                path      => 'domains',
                mandatory => ['domains'],
            },
            import_domain => {
                method    => 'POST',
                path      => 'domains/import',
                mandatory => ['domains'],

                # mandatory          => [ 'contents' ],
                # default_attributes => { contentType => 'BIND_9' },
            },
            update_domain => {
                method => 'PUT',
                path   => 'domains/:id',
            },
            update_domains => {
                method    => 'PUT',
                path      => 'domains',
                mandatory => ['domains'],
            },
            delete_domain => {
                method => 'DELETE',
                path   => 'domains/:id',
            },
            delete_domains => {
                method    => 'DELETE',
                path      => 'domains',
                mandatory => ['id'],
            },
            subdomains => { path => 'domains/:id/subdomains', },

            # records
            records       => { path => 'domains/:id/records', },
            record        => { path => 'domains/:id/records/:record_id', },
            create_record => {
                method => 'POST',
                path   => 'domains/:id/records',
            },
            update_record => {
                method => 'PUT',
                path   => 'domains/:id/records/:record_id',
            },
            update_records => {
                method => 'PUT',
                path   => 'domains/:id/records',
            },
            delete_record => {
                method => 'DELETE',
                path   => 'domains/:id/records/:record_id',
            },
            delete_records => {
                method => 'DELETE',
                path   => 'domains/:id/records',
            },

            # PTRs
            ptrs => {
                path      => 'rdns/:id',
                mandatory => ['href'],
            },
            ptr => {
                path      => 'rdns/:id/:record_id',
                mandatory => ['href'],
            },
            create_ptr => {
                method    => 'POST',
                path      => 'rdns',
                mandatory => [ 'recordsList', 'link' ],
            },
            update_ptr => {
                method    => 'PUT',
                path      => 'rdns',
                mandatory => [ 'recordsList', 'link' ],
            },
            delete_ptr => {
                method    => 'DELETE',
                path      => 'rdns/:id',
                mandatory => ['href'],
                optional  => ['ip'],
            },

            # jobs status
            status => {
                path               => 'status/:id',
                default_attributes => { showDetails => 'true' },
            },
        };
    },
);

sub commands {
    my ($self) = @_;
    return $self->commands;
}


sub login {
    my ($self) = @_;

    # rackspace uses one authentication URL for all their services
    my $base_url = $self->base_url;

    if (uc($self->location) eq 'UK') {
        $self->base_url('https://lon.identity.api.rackspacecloud.com/v2.0');
    }
    else {
        $self->base_url('https://identity.api.rackspacecloud.com/v2.0');
    }

    $self->debug(0);    #debug
    my $res = $self->tokens(user => $self->user, api_key => $self->api_key);
    $self->debug(1);    #debug

    # set special auth header token for future requests
    if (exists $res->{content}->{access}->{token}->{id}) {
        $self->header(
            { 'X-Auth-Token' => $res->{content}->{access}->{token}->{id} });

        # add tenant ID to previous base_url
        $self->base_url(
            $base_url . $res->{content}->{access}->{token}->{tenant}->{id});
    }

    return $res;
}


sub BUILD {
    my ($self) = @_;

    $self->user_agent(__PACKAGE__ . ' ' . $WebService::Rackspace::DNS::VERSION);
    $self->content_type('application/json');

    # $self->extension('json');
    $self->auth_type('none');
    $self->mapping({
            user    => 'username',
            api_key => 'apiKey',
            1       => "true",
            0       => "false",
            email   => 'emailAddress',
    });

    if (uc($self->location) eq 'UK') {
        $self->base_url('https://lon.dns.api.rackspacecloud.com/v1.0/');
    }
    else {
        $self->base_url('https://dns.api.rackspacecloud.com/v1.0/');
    }

    my $res = $self->login;
    return $res if (exists $res->{error});

    return $self;
}


1;    # End of WebService::Rackspace::DNS

__END__

=pod

=head1 NAME

WebService::Rackspace::DNS - WebService::Rackspace::DNS - an interface to rackspace.com's RESTful Cloud DNS API using Web::API

=head1 VERSION

version 0.1

=head1 SYNOPSIS

Please refer to the API documentation at L<http://docs.rackspace.com/cdns/api/v1.0/cdns-devguide/content/overview.html>

    use WebService::Rackspace::DNS;
    use Data::Dumper;
    
    my $dns = WebService::Rackspace::DNS->new(
        debug   => 1,
        user    => 'jsmith',
        api_key => 'aaaaa-bbbbb-ccccc-12345678',
    );
    
    my $response = $dns->create_domain(
        domains => [ {
            name => "blablub.com",
            emailAddress => 'bleep@bloop.com',
            recordsList => {
                records => [ {
                    name => "blablub.com",
                    type => "MX",
                    priority => 10,
                    data => "127.0.0.1"
                },
                {
                    name => "ftp.blablub.com",
                    ttl  => 3600,
                    type => "A",
                    data => "127.0.0.1"
                    comment => "A record for FTP server",
                } ],
            },
        } ]
    );
    print Dumper($response);

    $response = $dns->status(id => "some-funny-long-job-identifier");
    print Dumper($response);

=head1 ATTRIBUTES

=head2 location

=head1 SUBROUTINES/METHODS

=head2 limits

=head2 limit_types

=head2 limit

=head2 domains

=head2 domain

=head2 domain_history

=head2 zonefile

=head2 create_domain

=head2 import_domain

=head2 update_domain

=head2 update_domains

=head2 delete_domain

=head2 delete_domains

=head2 subdomains

=head2 records

=head2 record

=head2 create_record

=head2 update_record

=head2 update_records

=head2 delete_record

=head2 delete_records

=head2 ptrs

=head2 ptr

=head2 create_ptr

=head2 update_ptr

=head2 delete_ptr

=head2 status

=head1 INTERNALS

=head2 login

do rackspace's strange non-standard login token thing

=head2 BUILD

basic configuration for the client API happens usually in the BUILD method when using Web::API

=head1 BUGS

Please report any bugs or feature requests on GitHub's issue tracker L<https://github.com/nupfel/WebService-Rackspace-DNS/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Rackspace::DNS

You can also look for information at:

=over 4

=item * GitHub repository

L<https://github.com/nupfel/WebService-Rackspace-DNS>

=item * MetaCPAN

L<https://metacpan.org/module/WebService::Rackspace::DNS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService::Rackspace::DNS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService::Rackspace::DNS>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * Lenz Gschwendtner (@norbu09), for being an awesome mentor and friend.

=back

=head1 AUTHOR

Tobias Kirschstein <lev@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Tobias Kirschstein.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
