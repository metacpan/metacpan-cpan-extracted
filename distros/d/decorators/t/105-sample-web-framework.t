#!perl

use strict;
use warnings;

use Test::More;

# traits ...

package Entity::Traits::Provider {
    use strict;
    use warnings;

    use decorators ':for_providers';

    sub JSONParameter : Decorator : TagMethod { () }
}

package Service::Traits::Provider {
    use strict;
    use warnings;

    use decorators ':for_providers';

    sub Path     : Decorator : TagMethod { my ($meta, $method_name, $path) = @_; } # TODO

    sub GET      : Decorator : TagMethod { my ($meta, $method_name) = @_; } # TODO
    sub PUT      : Decorator : TagMethod { my ($meta, $method_name) = @_; } # TODO

    sub Consumes : Decorator : TagMethod { my ($meta, $method_name, $media_type) = @_; } # TODO
    sub Produces : Decorator : TagMethod { my ($meta, $method_name, $media_type) = @_; } # TODO
}

# this is the entity class

package Todo {
    use strict;
    use warnings;

    use decorators qw[ :accessors Entity::Traits::Provider ];

    use parent 'UNIVERSAL::Object';
    our %HAS; BEGIN { %HAS = (
        _description => sub {},
        _is_done     => sub {},
    )};

    sub description : ro(_description) JSONParameter;
    sub is_done     : ro(_is_done)     JSONParameter;
}

# this is the web-service for it

package TodoService {
    use strict;
    use warnings;

    use decorators qw[ :accessors Service::Traits::Provider ];

    use parent 'UNIVERSAL::Object';
    our %HAS; BEGIN { %HAS = (
        _todos => sub { +{} }
    )};

    sub todos : ro(_);

    sub get_todo : GET Path('/:id') Produces('application/json') {
        my ($self, $id) = @_;
        $self->todos->{ $id };
    }

    sub update_todo : PUT Path('/:id') Consumes('application/json') {
        my ($self, $id, $todo) = @_;
        return unless $self->todos->{ $id };
        $self->todos->{ $id } = $todo;
    }
}

my $todo = TodoService->new;
isa_ok($todo, 'TodoService');

done_testing;


=pod
# this is what it should ultimately generate ...

package TodoResource {
    use strict;
    use warnings;

    use parent 'Web::Machine::Resource';
    use slots (
        'JSON'    => sub { JSONinator->new  },
        'service' => sub { TodoService->new },
    );

    sub allowed_methods        { [qw[ GET PUT ]] }
    sub content_types_provided { [{ 'application/json' => 'get_as_json' }]}
    sub content_types_accepted { [{ 'application/json' => 'update_with_json' }]}

    sub get_as_json ($self) {
        my $id  = bind_path('/:id' => $self->request->path_info);
        my $res = $self->{service}->get_todo( $id );
        return \404 unless $res;
        return $self->{JSON}->collapse( $res );
    }

    sub update_with_json ($self) {
        my $id  = bind_path('/:id' => $self->request->path_info);
        my $e   = $self->{JSON}->expand( $self->{service}->entity_class, $self->request->content )
        my $res = $self->{service}->update_todo( $id, $e );
        return \404 unless $res;
        return;
    }
}
=cut

