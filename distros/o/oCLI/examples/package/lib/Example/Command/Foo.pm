package Example::Command::Foo;
use oCLI::Command;

setup foo => (
    desc => "A Foo Command Class",
);

define bar => (
    code => sub {
        my ( $self, $c ) = @_;

        $c->stash->{text} = "You're in foo:bar.\n";
    }
);

define blee => (
    code => sub {
        my ( $self, $c ) = @_;

        $c->stash->{text} = "You're in foo:blee.\n";
    }
);

define baz => (
    settings => [run => [ [qw( def=foo )], { desc => "Enable this code to run" } ] ],
    code => sub {
        my ( $self, $c ) = @_;

        my $obj1 = $self->run(( qw( /quiet foo:bar )));
        my $obj2 = $self->run(( qw( /quiet foo:blee )));

        $c->stash->{text} = $obj1->stash->{text} . $obj2->stash->{text};
    },
);

1;
