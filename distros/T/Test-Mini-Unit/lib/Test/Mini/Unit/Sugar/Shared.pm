# Defines the behavior of the +shared+ keyword.
# @api private
package Test::Mini::Unit::Sugar::Shared;
use base 'Devel::Declare::Context::Simple';
use strict;
use warnings;

use Devel::Declare ();

sub import {
    my ($class, %args) = @_;
    my $caller = $args{into} || caller;

    {
        no strict 'refs';
        *{"$caller\::shared"} = sub (&) {};
    }

    Devel::Declare->setup_for(
        $caller => { shared => { const => sub {
            $class->new(%args)->parser(@_);
        } } }
    );
}

sub parser {
    my $self = shift;
    $self->init(@_);

    $self->skip_declarator();

    my $name = $self->strip_name();
    die unless $name;

    my $pkg  = $self->get_curstash_name();
    my $base = 'Test::Mini::Unit::SharedBehavior';

    # Nested packages should be namespaced under their parent, unless the
    # package name is qualified or they're in the top level.
    $name = join('::', $pkg, $name) unless $name =~ s/^::// || $pkg eq 'main';
    (my $file = $name) =~ s/::/\//g;

    my $Sugar = 'Test::Mini::Unit::Sugar';
    my @with = ref $self->{with} ? @{$self->{with}} : $self->{with} || ();
    my $with = @with ? 'with => ["' . join('","', @with) . '"]' : '';

    $self->inject_if_block($_) for reverse (
        $self->scope_injector_call(),
        "package $name;",
        "use base '$base';",

        "\$INC{'${file}.pm'} = __FILE__;",

        "use Test::Mini::Assertions;",

        "use ${Sugar}::Test;",
        "use ${Sugar}::Advice (name => 'setup',    order => 'pre');",
        "use ${Sugar}::Advice (name => 'teardown', order => 'post');",
        (map { "use $_;" } reverse @with),
    );

    $self->shadow(sub (&) { shift->(); 1; });
}

1;
