package WWW::DNSMadeEasy::Monitor;
our $VERSION = '0.100';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: DNS Failover and System Monitoring configuration

use Moo;
use String::CamelSnakeKebab qw/lower_camel_case/;

use feature qw/say/;

has dme        => (is => 'ro', required => 1, handles => ['request']);
has record     => (is => 'ro', required => 1, handles => {path => 'monitor_path'});
has as_hashref => (is => 'rw', builder  => 1, lazy => 1, clearer => 1);
has response   => (is => 'rw');

sub _build_as_hashref { shift->response->as_hashref }

sub auto_failover      { shift->as_hashref->{autoFailover}      }
sub contact_list_id    { shift->as_hashref->{contactListId}     }
sub failover           { shift->as_hashref->{failover}          }
sub http_file          { shift->as_hashref->{httpFile}          }
sub http_fqdn          { shift->as_hashref->{httpFqdn}          }
sub http_query_string  { shift->as_hashref->{httpQueryString}   }
sub ip1                { shift->as_hashref->{ip1}               }
sub ip1_failed         { shift->as_hashref->{ip1Failed}         }
sub ip2                { shift->as_hashref->{ip2}               }
sub ip2_failed         { shift->as_hashref->{ip2Failed}         }
sub ip3                { shift->as_hashref->{ip3}               }
sub ip3_failed         { shift->as_hashref->{ip3Failed}         }
sub ip4                { shift->as_hashref->{ip4}               }
sub ip4_failed         { shift->as_hashref->{ip4Failed}         }
sub ip5                { shift->as_hashref->{ip5}               }
sub ip5_failed         { shift->as_hashref->{ip5Failed}         }
sub max_emails         { shift->as_hashref->{maxEmails}         }
sub monitor            { shift->as_hashref->{monitor}           }
sub port               { shift->as_hashref->{port}              }
sub protocol_id        { shift->as_hashref->{protocolId}        }
sub record_id          { shift->as_hashref->{recordId}          }
sub sensitivity        { shift->as_hashref->{sensitivity}       }
sub source             { shift->as_hashref->{source}            }
sub source_id          { shift->as_hashref->{sourceId}          }
sub system_description { shift->as_hashref->{systemDescription} }

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

sub create { shift->update(@_) }

sub disable {
    my ($self) = @_;
    $self->update(
        port        => $self->port,
        failover    => 'false',
        monitor     => 'false',
        sensitivity => $self->sensitivity,
    );

    my $res = $self->request(GET => $self->path);
    $self->response($res);
}

sub update {
    my ($self, %data) = @_;

    my %req;
    for my $old (keys %data) {
        my $new = lower_camel_case($old);
        $req{$new} = $data{$old};
    }

    $self->clear_as_hashref;
    my $res = $self->request(PUT => $self->path, \%req);
    $self->response($res);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::DNSMadeEasy::Monitor - DNS Failover and System Monitoring configuration

=head1 VERSION

version 0.100

=head1 METHODS

=head2 disable()

Disables dns failover and system monitoring.

=head2 update(%data)

=head2 response()

Returns the response for this object

=head2 as_hashref()

Returns json response data as a hashref

=head2 record()

Returns a L<WWW::DNSMadeEasy::ManagedDomain::Record> object.

=head2 ips()

Returns a list of failover ips (ip1, ip2, ...).

=head2 protocol()

Returns the protocol being monitored.  

    protocol_id    protocol
         1      =>    TCP
         2      =>    UDP
         3      =>    HTTP
         4      =>    DNS
         5      =>    SMTP
         6      =>    HTTP

=head2 auto_failover()

=head2 contact_list_id()

=head2 failover()

=head2 http_file()

=head2 http_fqdn()

=head2 http_query_string()

=head2 ip1()

=head2 ip1_failed()

=head2 ip2()

=head2 ip2_failed()

=head2 ip3()

=head2 ip3_failed()

=head2 ip4()

=head2 ip4_failed()

=head2 ip5()

=head2 ip5_failed()

=head2 max_emails()

=head2 monitor()

=head2 port()

=head2 protocol_id()

=head2 record_id()

=head2 sensitivity()

=head2 source()

=head2 source_id()

=head2 system_description()

=head1 METHODS

=head1 MONITOR ATTRIBUTES

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net and highlight Getty or /msg me.

Repository

  http://github.com/Getty/p5-www-dnsmadeeasy
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-www-dnsmadeeasy/issues

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/p5-www-dnsmadeeasy>

  git clone https://github.com/Getty/p5-www-dnsmadeeasy.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by L<Torsten Raudssus|https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
