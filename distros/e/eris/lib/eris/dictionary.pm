package eris::dictionary;
# ABSTRACT: Field dictionary loader

use Moo;
with qw(
    eris::role::pluggable
);
use Types::Standard qw(HashRef);
use namespace::autoclean;

our $VERSION = '0.008'; # VERSION



sub _build_namespace { 'eris::dictionary' }


has fields => (
    is => 'ro',
    isa => HashRef,
    lazy => 1,
    builder => '_build_fields',
);

sub _build_fields {
    my ($self) = @_;

    my %complete = ();
    foreach my $p ( @{ $self->plugins } ) {
        foreach my $f ( @{ $p->fields } ) {
            if( exists $complete{$f} ) {
                warn sprintf "Duplicated field '%s' in dictionaries, %s authoratitive, %s conflicting.",
                    $f,
                    $complete{$f},
                    $p->name;
                    next;
            }
            $complete{$f} = $p->name;
        }
    }

    return \%complete;
}


my %_dict = ();
sub lookup {
    my ($self,$field) = @_;
    return $_dict{$field} if exists $_dict{$field};

    # Otherwise, lookup
    my $entry;
    foreach my $p (@{ $self->plugins }) {
        $entry = $p->lookup($field);
        last if defined $entry;
    }
    defined $entry ? $_dict{$field} = $entry : undef;  # Assignment carries Left to Right and is returned;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::dictionary - Field dictionary loader

=head1 VERSION

version 0.008

=head1 SYNOPSIS

    use eris::dictionary;
    use YAML;

    my $dict = eris::dictionary->new();

    while(<>) {
        chomp;
        foreach my $word (split /\s+/) {
            my $def = $dict->lookup($word);
            print Dump $def if $def;
        }
    }

=head1 ATTRIBUTES

=head2 namespace

Defaults to C<eris::dictionary>

=head2 fields

HashRef of fields with true/false values indicated whether they exist in the dictionary.

=head1 METHODS

=head2 lookup

Takes a field name, returns the entry for that field from
the first matching dictionary or undef if nothing is found

=head1 SEE ALSO

L<eris::role::dictionary>, L<eris::dictionary::cee>, L<eris::dictionary::eris>,
L<eris::dictionary::eris::debug>, L<eris::dictionary::syslog>

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
