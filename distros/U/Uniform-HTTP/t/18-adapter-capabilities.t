use strict;
use warnings;
use Test::More;
use Uniform::HTTP::Message;

{
    # A native environment may expose trailers only after its completion event.
    package Local::LateTrailers;
    use parent 'Uniform::HTTP::Message';
    sub trailer_count {
        my ($self, @args) = @_;
        die 'trailer_count() does not accept arguments' if @args;
        return unless $self->{trailers_visible};
        return $self->SUPER::trailer_count;
    }
    sub trailer {
        my ($self, @args) = @_;
        die 'trailer() requires exactly one field name' unless @args == 1;
        return unless $self->{trailers_visible};
        return $self->SUPER::trailer(@args);
    }
    sub trailer_values {
        my ($self, @args) = @_;
        die 'trailer_values() requires exactly one field name' unless @args == 1;
        return unless $self->{trailers_visible};
        return $self->SUPER::trailer_values(@args);
    }
    sub trailer_name {
        my ($self, @args) = @_;
        die 'trailer_name() requires exactly one index' unless @args == 1;
        return unless $self->{trailers_visible};
        return $self->SUPER::trailer_name(@args);
    }
    sub trailer_value {
        my ($self, @args) = @_;
        die 'trailer_value() requires exactly one index' unless @args == 1;
        return unless $self->{trailers_visible};
        return $self->SUPER::trailer_value(@args);
    }
    sub trailers_are_lossless { return $_[0]{trailers_visible} ? 1 : 0 }
    sub trailers_are_mutable { return 0 }
}
my $late = Local::LateTrailers->new(trailers => [['X-Metric', 'v']]);
for my $method (qw(has_trailers trailer_count)) {
    is $late->$method, undef, "$method distinguishes unavailable from empty";
}
is $late->trailer('X-Metric'), undef, 'unavailable lookup';
is $late->trailer_values('X-Metric'), undef, 'unavailable list is not an empty array';
is $late->trailer_name(0), undef, 'unavailable indexed name';
is $late->trailer_value(0), undef, 'unavailable indexed value';
ok !$late->trailers_are_lossless, 'hidden fields are not lossless';
ok !$late->trailers_are_mutable, 'unavailable trailer writes not advertised';
$late->{trailers_visible} = 1;
is $late->has_trailers, 1, 'native event exposes trailer data';
is $late->trailer_count, 1, 'count becomes known';
is_deeply $late->trailer_values('X-Metric'), ['v'], 'native values now visible';
ok $late->trailers_are_lossless, 'available native data is lossless';
eval { $late->add_trailer('X-Metric', 'changed') };
like $@, qr/trailers are immutable/, 'inherited mutation honors native section capability';

{
    package Local::NativeBodyLocked;
    use parent 'Uniform::HTTP::Message';
    sub body_is_mutable { return 0 }
}
my $body_locked = Local::NativeBodyLocked->new;
ok $body_locked->is_mutable, 'native initial and trailer sections remain mutable';
eval { $body_locked->body('bytes') };
like $@, qr/buffered body is immutable/, 'body mutation honors native capability';
ok !$body_locked->has_buffered_body, 'failed body mutation changes nothing';
$body_locked->add_trailer('X-Metric', 'ok');
is $body_locked->trailer_count, 1, 'body lock does not prevent trailer edits';

{
    package Local::GlobalLock;
    use parent 'Uniform::HTTP::Message';
    sub is_mutable { return $_[0]{locked} ? 0 : 1 }
}
my $global = Local::GlobalLock->new;
$global->{locked} = 1;
for my $method (qw(initial_is_mutable body_is_mutable trailers_are_mutable)) {
    ok !$global->$method, 'legacy global immutable override still closes each section';
}
for my $call ([header => 'X', 'v'], [body => 'v'], [add_trailer => 'X', 'v']) {
    my ($method, @args) = @$call;
    eval { $global->$method(@args) };
    like $@, qr/message is immutable/, "$method honors native global lock";
}

{
    # Delegation adapter: native state is observable without canonical helpers.
    package Local::ReadOnlyAdapter;
    sub new { bless { message => $_[1] }, $_[0] }
    sub is_mutable { 0 }
    sub initial_is_mutable { 0 }
    sub body_is_mutable { 0 }
    sub trailers_are_mutable { 0 }
    sub is_complete { $_[0]{message}->is_complete }
    sub has_trailers { $_[0]{message}->has_trailers }
    sub trailer_count { $_[0]{message}->trailer_count }
    sub trailers_are_lossless { $_[0]{message}->trailers_are_lossless }
}
my $native = Uniform::HTTP::Message->new->mark_incomplete;
my $adapter = Local::ReadOnlyAdapter->new($native);
ok !$adapter->is_complete, 'read-only adapter observes live native progress';
is $adapter->has_trailers, 0, 'known current empty section';
$native->add_trailer('X-Metric', 'received')->mark_complete;
is $adapter->trailer_count, 1, 'native trailer arrival visible through read-only view';
ok $adapter->is_complete, 'native completion visible';
for my $method (qw(freeze freeze_initial freeze_trailers mark_complete mark_incomplete)) {
    ok !$adapter->can($method), "observation does not require $method";
}
done_testing;
