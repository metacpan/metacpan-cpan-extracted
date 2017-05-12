package Text::Tradition::TypeMap::Entry;
use Moose;

no warnings 'recursion';

use namespace::clean -except => 'meta';

with qw(KiokuDB::TypeMap::Entry::Std);

use YAML::XS ();

sub compile_collapse_body {
    my ( $self, $class ) = @_;

    return sub {
        my ( $self, %args ) = @_;

        my $object = $args{object};
        return $self->make_entry(
            %args,
            data => YAML::XS::Dump($object)
        );
    };
}

sub compile_expand {
    my ( $self, $class ) = @_;

    return sub {
        my ( $self, $entry ) = @_;
	$self->inflate_data( YAML::XS::Load($entry->data), \(my $obj), $entry );
        bless $obj, $class;
	return $obj;
    };
}

sub compile_refresh { return sub { die "TODO" } }

__PACKAGE__->meta->make_immutable;

1;
