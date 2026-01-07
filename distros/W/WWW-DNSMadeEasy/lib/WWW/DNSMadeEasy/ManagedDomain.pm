package WWW::DNSMadeEasy::ManagedDomain;
our $VERSION = '0.100';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: A managed domain in the DNSMadeEasy API

use Moo;
use String::CamelSnakeKebab qw/lower_camel_case/;
use WWW::DNSMadeEasy::ManagedDomain::Record;

has dme => (
    is       => 'ro',
    required => 1,
    handles  => {
        request => 'request',
        path    => 'domain_path',
    }
);

has name       => (is => 'ro', required => 1);
has as_hashref => (is => 'rw', builder  => 1, lazy => 1, clearer => 1);
has response   => (is => 'rw', builder  => 1, lazy => 1, clearer => 1);

sub _build_as_hashref { shift->response->as_hashref }
sub _build_response { $_[0]->request(GET => $_[0]->path . 'id/' . $_[0]->name) }

sub active_third_parties  { shift->as_hashref->{activeThirdParties}  }
sub created               { shift->as_hashref->{created}             }
sub delegate_name_servers { shift->as_hashref->{delegateNameServers} }
sub folder_id             { shift->as_hashref->{folderId}            }
sub gtd_enabled           { shift->as_hashref->{gtdEnabled}          }
sub id                    { shift->as_hashref->{id}                  }
sub name_servers          { shift->as_hashref->{nameServers}         }
sub pending_action_id     { shift->as_hashref->{pendingActionId}     }
sub process_multi         { shift->as_hashref->{processMulti}        }
sub updated               { shift->as_hashref->{updated}             }

sub delete {
    my ($self) = @_;
    $self->request(DELETE => $self->path . $self->id);
}

sub update {
    my ($self, $data) = @_;
    $self->clear_as_hashref;
    my $res = $self->request(PUT => $self->path . $self->id, $data);
    $self->response($res);
}

sub wait_for_delete {
    my ($self) = @_;
    while (1) {
        $self->clear_response;
        $self->clear_as_hashref;
        eval { $self->response() };
        last if $@ && $@ =~ /(404|400)/;
        sleep 10;
    }
}

sub wait_for_pending_action {
    my ($self) = @_;
    while (1) {
        $self->clear_response;
        $self->clear_as_hashref;
        last if $self->pending_action_id == 0;
        sleep 10;
    }
}

#
# RECORDS
#

sub records_path { $_[0]->path . $_[0]->id . '/records/' }

sub create_record {
    my ( $self, %data ) = @_;

    my %req;
    for my $old (keys %data) {
        my $new = lower_camel_case($old);
        $req{$new} = $data{$old};
    }

	return WWW::DNSMadeEasy::ManagedDomain::Record->new(
        response => $self->request(POST => $self->records_path, \%req),
        domain   => $self,
    );
}

# TODO 
# - do multiple gets when max number of records is reached
# - save the request as part of the Record obj
sub records {
    my ($self, %args) = @_;

    # TODO should switch to URI->query_form() but that requires changing DME->request()
    my $path = $self->records_path;
    $path .= '?type='       . $args{type} if defined $args{type} && !defined $args{name};
    $path .= '?recordName=' . $args{name} if defined $args{name} && !defined $args{type};
    $path .= '?recordName=' . $args{name} .
             '&type='       . $args{type} if defined $args{name} &&  defined $args{type};

    my $arrayref = $self->request(GET => $path)->data->{data};

    my @records;
    for my $hashref (@$arrayref) {
        push @records, WWW::DNSMadeEasy::ManagedDomain::Record
            ->new(as_hashref => $hashref, domain => $self);
    }

    return @records;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::DNSMadeEasy::ManagedDomain - A managed domain in the DNSMadeEasy API

=head1 VERSION

version 0.100

=head1 METHODS

=head2 delete()

=head2 update(%data)

=head2 records(%data)

    my @records = $domain->records();                # Returns all records
    my @records = $domain->records(type => 'CNAME'); # Returns all CNAME records
    my @records = $domain->records(name => 'www');   # Returns all wwww records

Returns a list of L<WWW::DNSMadeEasy::ManagedDomain::Record> objects.

=head2 response

Returns the response for this object

=head2 as_hashref

Returns json response data as a hashref

=head2 name

=head2 active_third_parties

=head2 created

=head2 delegate_name_servers

=head2 folder_id

=head2 gtd_enabled

=head2 id

=head2 name_servers

=head2 pending_action_id

=head2 process_multi

=head2 updated

=head1 METHODS

=head1 MANAGED DOMAIN ATTRIBUTES

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
