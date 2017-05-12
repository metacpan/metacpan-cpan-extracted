# ABSTRACT: Models a comment in the NewsReach API
package WWW::NewsReach::Comment;

our $VERSION = '0.06';

use Moose;

use DateTime;
use DateTime::Format::ISO8601;

has id => (
    is => 'ro',
    isa => 'Int',
);

has $_ => (
    is => 'ro',
    isa => 'Str',
) for qw( text name location );

has postDate => (
    is => 'ro',
    isa => 'DateTime',
);

sub new_from_xml {
    my $class = shift;
    my ( $xml ) = @_;

    my $self = {};

    foreach (qw[id text name location]) {
        $self->{$_} = $xml->findnodes("//$_")->[0]->textContent;
    }

    my $dt_str        = $xml->findnodes("//postDate");
    my $dt            = DateTime::Format::ISO8601->new->parse_datetime( $dt_str );
    $self->{postDate} = $dt;

    return $class->new( $self );
}

1;

__END__
=pod

=head1 NAME

WWW::NewsReach::Comment - Models a comment in the NewsReach API

=head1 VERSION

version 0.06

=head1 METHODS

=head2 WWW::NewsReach::Comment->new_from_xml

Create a new WWW::NewsReach::Comment object from the
<commentListItem> ... </commentListItem> element in the XML returned from a
NewsReach API request.

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

