package WebService::DNSMadeEasy::ManagedDomain::Record;

use Moo;
use String::CamelSnakeKebab qw/lower_camel_case/;
use WebService::DNSMadeEasy::Monitor;

has domain_id => (is => 'rw', required => 1);
has id        => (is => 'rw', required => 1);
has client    => (is => 'lazy');
has path      => (is => 'lazy');
has data      => (is => 'rw', builder => 1, lazy => 1, clearer => 1);
has response  => (is => 'rw', clearer => 1);

sub _build_client { WebService::DNSMadeEasy::Client->instance }

# object method
sub _build_path {
    my $self = shift;
    $self->_build_build_path($self->domain_id);
}

# class method used by other class methods below
sub _build_build_path {
    my ($class, $domain_id) = @_;
    return "/dns/managed/${domain_id}/records";
}

sub _build_data {
    my $self = shift;

    # GRR DME doesn't return the updasted record and there is no way to get a
    # single record by id
    my @records = $self->find(
        client    => $self->client,
        domain_id => $self->domain_id,
        type      => $self->type, 
        name      => $self->name,
    );

    for my $record (@records) {
        next unless $record->id eq $self->id;
        return $record->data;
    }

    die "could not find record id: " . $self->id;
}

sub description   { shift->data->{description}  }
sub dynamic_dns   { shift->data->{dynamicDns}   }
sub failed        { shift->data->{failed}       }
sub failover      { shift->data->{failover}     }
sub gtd_location  { shift->data->{gtdLocation}  }
sub hard_link     { shift->data->{hardLink}     }
sub keywords      { shift->data->{keywords}     }
sub monitor       { shift->data->{monitor}      }
sub mxLevel       { shift->data->{mxLevel}      }
sub name          { shift->data->{name}         }
sub password      { shift->data->{password}     }
sub port          { shift->data->{port}         }
sub priority      { shift->data->{priority}     }
sub redirect_type { shift->data->{redirectType} }
sub source        { shift->data->{source}       }
sub source_id     { shift->data->{source_id}    }
sub title         { shift->data->{title}        }
sub ttl           { shift->data->{ttl}          }
sub type          { shift->data->{type}         }
sub value         { shift->data->{value}        }
sub weight        { shift->data->{weight}       }

sub delete {
    my ($self) = @_;
    $self->client->delete($self->path . '/' . $self->id);
}

sub update {
    my ($self, %data) = @_;

    my %req;
    for my $old (keys %data) {
        my $new = lower_camel_case($old);
        $req{$new} = $data{$old};
    }

    $req{id}   //= $self->id;
    $req{name} //= $self->name;

    my $id   = $self->id;
    my $type = $self->type;
    my $name = $self->name;
    $self->clear_data;
    $self->clear_response;
    $self->client->put($self->path . '/' . $id, \%req);

    # GRR DME doesn't return the updasted record and there is no way to get a
    # single record by id
    $name = $req{name} if $req{name};
    my @records = $self->find(
        client    => $self->client,
        domain_id => $self->domain_id,
        type      => $type,
        name      => $name,
    );

    for my $record (@records) {
        next unless $record->id eq $id;
        $self->data($record->data);
        last;
    }
}

sub create {
    my ($class, %data) = @_;
    my $client    = delete $data{client};
    my $domain_id = delete $data{domain_id} // die "domain_id required";

    my %req;
    for my $old (keys %data) {
        my $new = lower_camel_case($old);
        $req{$new} = $data{$old};
    }

    my $path = $class->_build_build_path($domain_id);
    my $res  = $client->post($path, \%req);

    return $class->new(
        client    => $client,
        domain_id => $domain_id,
        id        => $res->data->{id},
        data      => $res->data,
        response  => $res,
    );
}

sub find {
    my ($class, %args) = @_;
    my $client = delete $args{client};
    my $domain_id = delete $args{domain_id};

    # TODO yuck
    my $path = $class->_build_build_path($domain_id);
    $path .= '?type='       . $args{type} if defined $args{type} && !defined $args{name};
    $path .= '?recordName=' . $args{name} if defined $args{name} && !defined $args{type};
    $path .= '?recordName=' . $args{name} .
             '&type='       . $args{type} if defined $args{name} &&  defined $args{type};

    my $arrayref = $client->get($path)->data->{data};

    my @records;
    for my $hashref (@$arrayref) {
        push @records, $class->new(
            client    => $client,
            domain_id => $domain_id,
            id        => $hashref->{id},
            data      => $hashref,
        );
    }

    return @records;
}

#
# Monitors
#

sub get_monitor {
    my ($self) = @_;
    return WebService::DNSMadeEasy::Monitor->new(
        client    => $self->client,
        record_id => $self->id,
    );
}

sub create_monitor {
    my ($self, %data) = @_;

    my %req;
    for my $old (keys %data) {
        my $new = lower_camel_case($old);
        $req{$new} = $data{$old};
    }

    return WebService::DNSMadeEasy::Monitor->create(
        client    => $self->client,
        record_id => $self->id,
        %req,
    );
}

1;

# TODO: add this to synposis when client class is a singleton
#
#    use WebService::DNSMadeEasy::ManagedDomain::Record;
#
#    my $record  = WebService::DNSMadeEasy::ManagedDomain::Record->new(
#       id        => $id,
#       domain_id => $domain_id,
#    );
#
#    my @records = WebService::DNSMadeEasy::ManagedDomain::Record->find(
#       type => $type,
#       name => $name,
#    );
#
#    my $record  = WebService::DNSMadeEasy::ManagedDomain::Record->create(...);

=head1 NAME

WebService::DNSMadeEasy::ManagedDomain::Record

=head1 SYNOPSIS

    # These methods return L<WebService::DNSMadeEasy::ManagedDomain::Record> objects.
    my @records = $domain->records();                # Returns all records
    my @records = $domain->records(type => 'CNAME'); # Returns all CNAME records
    my @records = $domain->records(name => 'www');   # Returns all wwww records
    my $record  = $domain->create_record(
        name         => 'www',
        value        => '1.2.3.4',
        type         => 'A',
        gtd_location => 'DEFAULT',
        ttl          => 120,
    );

    # actions
    $record->update(...);
    $record->delete;

    # attributes
    $record->data; # returns all attributes as a hashref
    $record->description;
    $record->dynamic_dns;
    $record->failed;
    $record->failover;
    $record->gtd_location;
    $record->hard_link;
    $record->id;
    $record->keywords;
    $record->monitor
    $record->mxLevel;
    $record->name;
    $record->password;
    $record->port;
    $record->priority;
    $record->redirect_type;
    $record->source;
    $record->source_id;
    $record->title;
    $record->ttl;
    $record->type;
    $record->value;
    $record->weight;

    # Returns a L<WebService::DNSMadeEasy::Monitor> object
    my $monitor = $record->get_monitor;

=head1 DESCRIPTION

This object represents a DNS record for a given domain.

=cut
