package WWW::DNSMadeEasy::ManagedDomain::Record;
our $VERSION = '0.100';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: A managed domain record in the DNSMadeEasy API

use Moo;
use String::CamelSnakeKebab qw/lower_camel_case/;
use WWW::DNSMadeEasy::Monitor;

has domain     => (is => 'ro', required => 1, handles => {path => 'records_path'});
has dme        => (is => 'lazy', handles => ['request']);
has as_hashref => (is => 'rw', builder => 1, lazy => 1, clearer => 1);
has response   => (is => 'rw');

sub _build_dme        { shift->domain->dme }
sub _build_as_hashref { shift->response->as_hashref }

sub description   { shift->as_hashref->{description}  }
sub dynamic_dns   { shift->as_hashref->{dynamicDns}   }
sub failed        { shift->as_hashref->{failed}       }
sub failover      { shift->as_hashref->{failover}     }
sub gtd_location  { shift->as_hashref->{gtdLocation}  }
sub hard_link     { shift->as_hashref->{hardLink}     }
sub id            { shift->as_hashref->{id}           }
sub keywords      { shift->as_hashref->{keywords}     }
sub monitor       { shift->as_hashref->{monitor}      }
sub mxLevel       { shift->as_hashref->{mxLevel}      }
sub name          { shift->as_hashref->{name}         }
sub password      { shift->as_hashref->{password}     }
sub port          { shift->as_hashref->{port}         }
sub priority      { shift->as_hashref->{priority}     }
sub redirect_type { shift->as_hashref->{redirectType} }
sub source        { shift->as_hashref->{source}       }
sub source_id     { shift->as_hashref->{source_id}    }
sub title         { shift->as_hashref->{title}        }
sub ttl           { shift->as_hashref->{ttl}          }
sub type          { shift->as_hashref->{type}         }
sub value         { shift->as_hashref->{value}        }
sub weight        { shift->as_hashref->{weight}       }

sub delete {
    my ($self) = @_;
    $self->request('DELETE', $self->path . $self->id);
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
    $self->clear_as_hashref;
    $self->request(PUT => $self->path . $id, \%req);

    # GRR DME doesn't return the updasted record and there is no way to get a
    # single record by id
    $name = $req{name} if $req{name};
    my @records = $self->domain->records(type => $type, name => $name);
    for my $record (@records) {
        next unless $record->id eq $id;
        $self->as_hashref($record->as_hashref);
    }
}

sub monitor_path { 'monitor/' . shift->id  }

sub get_monitor {
    my ($self) = @_;
    return WWW::DNSMadeEasy::Monitor->new(
        response => $self->request(GET => $self->monitor_path),
        dme      => $self->dme,
        record   => $self,
    );
}

sub create_monitor {
    my ($self, %data) = @_;

    my %req;
    for my $old (keys %data) {
        my $new = lower_camel_case($old);
        $req{$new} = $data{$old};
    }

    my $monitor = WWW::DNSMadeEasy::Monitor->new(
        response => $self->request(PUT => $self->monitor_path, \%req),
        dme      => $self->dme,
        record   => $self,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::DNSMadeEasy::ManagedDomain::Record - A managed domain record in the DNSMadeEasy API

=head1 VERSION

version 0.100

=head1 METHODS

=head2 delete()

=head2 update(%data)

Can't update id, name, type, or gtd_location.

=head2 response()

Returns this object as a hashreference.

=head2 get_monitor()

Returns a L<WWW::DNSMadeEasy::Monitor> object which deals with dns failover and system monitoring.

=head2 description

=head2 dynamic_dns

=head2 failed

=head2 failover

=head2 gtd_location

=head2 hard_link

=head2 id

=head2 keywords

=head2 monitor

=head2 mxLevel

=head2 name

=head2 password

=head2 port

=head2 priority

=head2 redirect_type

=head2 source

=head2 source_id

=head2 title

=head2 ttl

=head2 type

=head2 value

=head2 weight

=head1 METHODS

=head1 RECORD ATTRIBUTES

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
