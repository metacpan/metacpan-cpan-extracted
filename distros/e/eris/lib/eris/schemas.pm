package eris::schemas;
# ABSTRACT: Discovery and access for schemas

use Moo;
with qw(
    eris::role::pluggable
);
use Types::Standard qw(HashRef);
use namespace::autoclean;

our $VERSION = '0.008'; # VERSION




sub _build_namespace { 'eris::schema' }


sub find {
    my ($self,$log) = @_;
    my @schemas = ();
    # Otherwise, find the schema's collecting this log
    foreach my $p (@{ $self->plugins }) {
        # Jump out as quickly as possible
        if( $p->match_log($log) ) {
            push @schemas, $p;
            last if $p->final;
        }
    }
    # Return our schemas
    return @schemas;
}


sub as_bulk {
    my ($self,$log) = @_;
    # Find the matching schemas
    my @schemas = $self->find($log);
    # Return the bulk strings or the empty list
    return @schemas ? map { $_->as_bulk($log) } @schemas : ();
}


sub to_document {
    my ($self,$log) = @_;
    # Find the matching schemas
    my @schemas = $self->find($log);
    # Return the document or the empty list
    return @schemas ? $schemas[0]->to_document($log) : ();
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::schemas - Discovery and access for schemas

=head1 VERSION

version 0.008

=head1 SYNOPSIS

    use eris::schemas;
    use eris::contextualizer;

    my $schm = eris::schemas->new();
    my $ctxr = eris::contextualizer->new();

    # Transform each line from STDIN or a file into bulk commands:
    while( <<>> ) {
        my $log = $ctxr->contextualize( $_ );
        print $schm->as_bulk($log);
    }

=head1 ATTRIBUTES

=head2 namespace

Default namespace is 'eris::schema'

=head1 METHODS

=head2 find()

Takes an instance of an L<eris::log> you want to index into ElasticSearch.

Discover all possible, enabled schemas according to the C<search_path> as configured,
find all schemas matching the passed L<eris::log> object.

Returns a list

=head2 as_bulk()

Takes an instance of an L<eris::log> to index into ElasticSearch.

Using the C<find()> method, return a list of the commands necessary to
bulk index the instance of an L<eris::log> object as an array of new-line delimited
JSON.

=head2 to_document()

Takes an instance of an L<eris::log> to index into ElasticSearch.

Using the C<find()> method, return the first document to be created from the
L<eris::log> entry.

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
