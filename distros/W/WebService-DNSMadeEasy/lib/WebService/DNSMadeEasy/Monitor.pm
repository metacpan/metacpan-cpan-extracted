package WebService::DNSMadeEasy::Monitor;

use Moo;
use String::CamelSnakeKebab qw/lower_camel_case/;

has record_id => (is => 'ro', required => 1);
has client    => (is => 'lazy');
has path      => (is => 'lazy');
has data      => (is => 'rw', builder  => 1, lazy => 1, clearer => 1);
has response  => (is => 'rw', lazy => 1, builder => 1);

sub _build_client { WebService::DNSMadeEasy::Client->instance }
sub _build_path   { '/monitor/' . shift->record_id }
sub _build_data   { shift->response->data }

sub _build_response {
    my $self = shift;
    $self->client->get($self->path);
}

sub auto_failover      { shift->data->{autoFailover}      }
sub contact_list_id    { shift->data->{contactListId}     }
sub failover           { shift->data->{failover}          }
sub http_file          { shift->data->{httpFile}          }
sub http_fqdn          { shift->data->{httpFqdn}          }
sub http_query_string  { shift->data->{httpQueryString}   }
sub ip1                { shift->data->{ip1}               }
sub ip1_failed         { shift->data->{ip1Failed}         }
sub ip2                { shift->data->{ip2}               }
sub ip2_failed         { shift->data->{ip2Failed}         }
sub ip3                { shift->data->{ip3}               }
sub ip3_failed         { shift->data->{ip3Failed}         }
sub ip4                { shift->data->{ip4}               }
sub ip4_failed         { shift->data->{ip4Failed}         }
sub ip5                { shift->data->{ip5}               }
sub ip5_failed         { shift->data->{ip5Failed}         }
sub max_emails         { shift->data->{maxEmails}         }
sub monitor            { shift->data->{monitor}           }
sub port               { shift->data->{port}              }
sub protocol_id        { shift->data->{protocolId}        }
sub sensitivity        { shift->data->{sensitivity}       }
sub source             { shift->data->{source}            }
sub source_id          { shift->data->{sourceId}          }
sub system_description { shift->data->{systemDescription} }

sub ips {
    my ($self) = @_;
    my @ips;
    push @ips, $self->ip1 if $self->ip1;
    push @ips, $self->ip2 if $self->ip2;
    push @ips, $self->ip3 if $self->ip3;
    push @ips, $self->ip4 if $self->ip4;
    push @ips, $self->ip5 if $self->ip5;
    return @ips;
}

my %PROTOCOL = (
    1 => 'TCP',
    2 => 'UDP',
    3 => 'HTTP',
    4 => 'DNS',
    5 => 'SMTP',
    6 => 'HTTPS',
);

sub protocol { $PROTOCOL{shift->protocol_id} }

sub disable {
    my ($self) = @_;
    $self->update(
        port        => $self->port,
        failover    => 'false',
        monitor     => 'false',
        sensitivity => $self->sensitivity,
    );

    my $res = $self->client->get($self->path);
    $self->response($res);
}

sub update {
    my ($self, %data) = @_;

    my %req;
    for my $old (keys %data) {
        my $new = lower_camel_case($old);
        $req{$new} = $data{$old};
    }

    my $res = $self->client->put($self->path, \%req);
    $self->clear_data;
    $self->response($res);
}

sub create {
    my ($class, %args) = @_;
    my $self = $class->new(
        client    => delete $args{client},
        record_id => delete $args{record_id},
    );
    $self->update(%args);
    return $self;
}

1;

#    use WebService::DNSMadeEasy::Monitor;
#
#    my $monitor = WebService::DNSMadeEasy::Monitor->new(
#        record_id => $record_id # required
#    );
#
#    my $monitor = WebService::DNSMadeEasy::Monitor->create(
#        record_id          => $record_id, # required
#        port               => 8080,
#        failover           => 'true',
#        ip1                => '1.1.1.1',
#        ip2                => '2.2.2.2',
#        protocol_id        => 3,
#        monitor            => 'true',
#        sensitivity        => 5,
#        system_description => 'Test',
#        max_emails         => 1,
#        auto_failover      => 'false',
#    );


=head1 NAME

WebService::DNSMadeEasy::Monitor

=head1 SYNOPSIS

    # Returns a L<WebService::DNSMadeEasy::Monitor> object
    my $monitor = $record->get_monitor;

    # actions
    $monitor->update(...); # update some attributes
    $monitor->disable;     # disable failover and system monitoring

    # attributes
    $monitor->data; # returns all attributes as a hashref
    $monitor->auto_failover;
    $monitor->contact_list_id;
    $monitor->failover;
    $monitor->http_file;
    $monitor->http_fqdn;
    $monitor->http_query_string;
    $monitor->ip1;
    $monitor->ip1_failed;
    $monitor->ip2;
    $monitor->ip2_failed;
    $monitor->ip3;
    $monitor->ip3_failed;
    $monitor->ip4;
    $monitor->ip4_failed;
    $monitor->ip5;
    $monitor->ip5_failed;
    $monitor->max_emails;
    $monitor->monitor;
    $monitor->port;
    $monitor->protocol_id;
    $monitor->record_id;
    $monitor->sensitivity;
    $monitor->source;
    $monitor->source_id;
    $monitor->system_description;

    # helpers
    $monitor->ips();       # returns a list of the failover ips
    $monitor->protocol();  # returns the protocol being monitored
                           #     protocol_id    protocol
                           #         1      =>    TCP
                           #         2      =>    UDP
                           #         3      =>    HTTP
                           #         4      =>    DNS
                           #         5      =>    SMTP
                           #         6      =>    HTTP

=head1 DESCRIPTION

This object represents DNS failover and system monitoring configuration.

=cut
