package WebService::DNSMadeEasy::ManagedDomain;

use Moo;
use String::CamelSnakeKebab qw/lower_camel_case/;
use WebService::DNSMadeEasy::ManagedDomain::Record;

has name     => (is => 'ro', required => 1);
has client   => (is => 'lazy');
has path     => (is => 'lazy');
has data     => (is => 'rw', builder  => 1, lazy => 1, clearer => 1);
has response => (is => 'rw', builder  => 1, lazy => 1, clearer => 1);

sub _build_client { WebService::DNSMadeEasy::Client->instance }
sub _build_path   { '/dns/managed' }
sub _build_data   { shift->response->data }

sub _build_response {
   my $self = shift;
   $self->client->get($self->path . '/id/' . $self->name);
}

sub active_third_parties  { shift->data->{activeThirdParties}  }
sub created               { shift->data->{created}             }
sub delegate_name_servers { shift->data->{delegateNameServers} }
sub folder_id             { shift->data->{folderId}            }
sub gtd_enabled           { shift->data->{gtdEnabled}          }
sub id                    { shift->data->{id}                  }
sub name_servers          { shift->data->{nameServers}         }
sub pending_action_id     { shift->data->{pendingActionId}     }
sub process_multi         { shift->data->{processMulti}        }
sub updated               { shift->data->{updated}             }

sub delete {
    my ($self) = @_;
    $self->client->delete($self->path . '/' . $self->id);
}

sub update {
    my ($self, %data) = @_;
    $self->clear_data;
    my $res = $self->client->put($self->path . '/' . $self->id, \%data);
    $self->response($res);
}

sub wait_for_delete {
    my ($self) = @_;
    while (1) {
        $self->clear_response;
        $self->clear_data;
        eval { $self->response() };
        last if $@ && $@ =~ /(404|400)/;
        sleep 10;
    }
}

sub wait_for_pending_action {
    my ($self) = @_;
    while (1) {
        $self->clear_response;
        $self->clear_data;
        last if $self->pending_action_id == 0;
        sleep 10;
    }
}

sub create {
    my ($class, %data) = @_;
    my $self = $class->new(
        client => $data{client},
        name   => $data{name},
    );
    my $res = $self->client->post($self->path, {name => $data{name}});
    $self->response($res);
    return $self;
}

sub find {
    my ($class, %args) = @_;

    my $path = $class->_build_path;
    my $data = $args{client}->get($path)->data->{data};

    my @domains;
    push @domains, $class->new(
        client => $args{client},
        name   => $_->{name},
    ) for @$data;

    return @domains;
}

#
# RECORDS
#

sub create_record {
    my ($self, %data) = @_;

	WebService::DNSMadeEasy::ManagedDomain::Record->create(
        client    => $self->client,
        domain_id => $self->id,
        %data,
    );
}

# TODO 
# - do multiple gets when max number of records is reached
# - save the request as part of the Record obj
sub records {
    my ($self, %args) = @_;
    WebService::DNSMadeEasy::ManagedDomain::Record->find(
        client    => $self->client,
        domain_id => $self->id,
        %args,
    );
}

1;

#    use WebService::DNSMadeEasy::ManagedDomain;
#
#    my $domain  = WebService::DNSMadeEasy::ManagedDomain->new(name => $name);
#    my $domain  = WebService::DNSMadeEasy::ManagedDomain->create(name => $name);
#    my @domains = WebService::DNSMadeEasy::ManagedDomain->find;

=head1 NAME

WebService::DNSMadeEasy::ManagedDomain

=head1 SYNOPSIS

    # These methods return L<WebService::DNSMadeEasy::ManagedDomain> objects.
    my @domains = $dns->managed_domains;
    my $domain  = $dns->get_managed_domain('example.com');
    my $domain  = $dns->create_managed_domain('stegasaurus.com');

    # actions
    $domain->delete;
    $domain->update(...); # update some domain attributes
    $domain->wait_for_delete;
    $domain->wait_for_pending_action;

    # attributes
    $domain->data; # returns all attributes as a hashref
    $domain->active_third_parties;
    $domain->created;
    $domain->delegate_name_servers;
    $domain->folder_id;
    $domain->gtd_enabled;
    $domain->id;
    $domain->name_servers;
    $domain->pending_action_id;
    $domain->process_multi;
    $domain->updated;

    # These methods return L<WebService::DNSMadeEasy::ManagedDomain::Record> objects.
    $domain->create_record(
        name         => 'www',
        type         => 'A',
        value        => '1.2.3.4',
        gtd_location => 'DEFAULT',
        ttl          => 120,
    );
    my @records = $domain->records();                # Returns all records
    my @records = $domain->records(type => 'CNAME'); # Returns all CNAME records
    my @records = $domain->records(name => 'www');   # Returns all wwww records

=head1 DESCRIPTION

This object represents a domain.

=cut


