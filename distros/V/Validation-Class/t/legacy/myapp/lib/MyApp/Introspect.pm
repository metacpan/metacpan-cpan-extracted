package MyApp::Introspect;

use Validation::Class;

sub per_class {

    my ($self, $code) = @_;

    $self->proto->relatives->each(sub{

        my ($alias, $namespace) = @_;

        # do something with each class
        $code->($namespace);

    });

}

sub per_field_per_class {

    my ($self, $code) = @_;

    $self->per_class(sub{

        my $namespace = shift;

        my $class = $namespace->new;

        foreach my $field (sort $class->fields->keys) {

            # do something with each field
            $code->($class, $class->fields->{$field});

        }

    });

}

1;
