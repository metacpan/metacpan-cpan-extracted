package WWW::DNSMadeEasy::Domain::Record;
our $VERSION = '0.100';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: A domain record in the DNSMadeEasy API

use Moo;
use Carp;

has id => (
    is => 'ro',
    required => 1,
);

has domain => (
    is => 'ro',
    required => 1,
);

has response_index => (
    is => 'rw',
    predicate => 'has_response_index',
);

has as_hashref => (is => 'rw', builder => 1, lazy => 1);
has response   => (is => 'rw', builder => 1, lazy => 1);

sub _build_as_hashref { shift->response->as_hashref }
sub _build_response   { $_[0]->domain->dme->request(GET => $_[0]->path) }

sub ttl           { shift->as_hashref->{ttl}          }
sub gtd_location  { shift->as_hashref->{gtdLocation}  }
sub name          { shift->as_hashref->{name}         }
sub data          { shift->as_hashref->{data}         }
sub type          { shift->as_hashref->{type}         }
sub password      { shift->as_hashref->{password}     }
sub description   { shift->as_hashref->{description}  }
sub keywords      { shift->as_hashref->{keywords}     }
sub title         { shift->as_hashref->{title}        }
sub redirect_type { shift->as_hashref->{redirectType} }
sub hard_link     { shift->as_hashref->{hardLink}     }

sub path {
    my ( $self ) = @_;
    $self->domain->path_records.'/'.$self->id;
}

sub delete {
    my ( $self ) = @_;
    $self->domain->dme->request('DELETE',$self->path);
}

sub put { shift->update(@_) }

sub update {
    my $self = shift;
    my %data = ( @_ % 2 == 1 ) ? %{ $_[0] } : @_;
    my $put_response = $self->domain->dme->request('PUT', $self->path, \%data);
    return WWW::DNSMadeEasy::Domain::Record->new({
        domain => $self->domain,
        id => $put_response->data->{id},
        response => $put_response,
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::DNSMadeEasy::Domain::Record - A domain record in the DNSMadeEasy API

=head1 VERSION

version 0.100

=head1 ATTRIBUTES

=head2 id

=head2 domain

=head2 obj

=head1 METHODS

=head2 $obj->delete

=head2 $obj->ttl

=head2 $obj->gtd_location

=head2 $obj->name

=head2 $obj->data

=head2 $obj->type

=head2 $obj->password

=head2 $obj->description

=head2 $obj->keywords

=head2 $obj->title

=head2 $obj->redirect_type

=head2 $obj->hard_link

=head2 $obj->update

    $record->put( {
        name => $name,
        type => $type,
        data => $data,
        gtdLocation => $gtdLocation,
        ttl => $ttl
    } );

to update the record

=head1 ATTRIBUTES

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
