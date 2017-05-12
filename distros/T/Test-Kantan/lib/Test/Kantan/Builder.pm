package Test::Kantan::Builder;
use strict;
use warnings;
use utf8;
use 5.010_001;
use Module::Load;
use Try::Tiny;
use File::Spec;
use File::Path;

use Test::Kantan::State;

# Do not call this interface directly from your code.
# After release TB2 and TB2 is good enough to me, I will replace this part with TB2.

use Moo;

has color    => ( is => 'lazy' );
has state    => ( is => 'lazy' );
has reporter => ( is => 'ro', 'builder' => '_build_reporter' );
has finished => ( is => 'rw', default => sub { 0 } );
has pid => (is => 'ro', default => sub { $$ });
has message_dir => (is => 'ro', 'builder' => '_build_message_dir' );

no Moo;

sub _build_color {
    $ENV{KANTAN_COLOR} || -t *STDOUT;
}

sub _build_state {
    Test::Kantan::State->new();
}

sub _build_message_dir {
    my $self = shift;
    my $time = time;
    File::Spec->catfile(File::Spec->tmpdir, "kantan.$$.${time}");
}

sub _build_reporter {
    my $self = shift;

    my $reporter_class = do {
        my $s = $ENV{KANTAN_REPORTER} || 'Spec';
        my $klass = ($s =~ s/\A\+// ? $s : "Test::Kantan::Reporter::${s}");
        Module::Load::load $klass;
        $klass;
    };
    my $reporter = $reporter_class->new(
        color => $self->color,
        state => $self->state,
    );
    $reporter->start;
    return $reporter;
}

sub ok {
    my ($self, %args) = @_;
    return if $self->care_child(\%args);

    my $caller      = param(\%args, 'caller');
    my $value       = param(\%args, 'value');
    my $description = param(\%args, 'description', {optional => 1});

    if ($value) {
        $self->state->passed();
        $self->reporter->pass(
            caller      => $caller,
            description => $description,
        );
        return 1;
    } else {
        $self->state->failed();
        $self->reporter->fail(
            caller      => $caller,
            description => $description,
        );
        return 0;
    }
}

sub care_child {
    my ($self, $args) = @_;
    return if $$ eq $self->pid;
    (my $meth = [caller(1)]->[3]) =~ s/.*:://;

    $self->push_child_message($meth, $args);
}

sub exception {
    my ($self, %args) = @_;
    return if $self->care_child(\%args);
    my $message = param(\%args, 'message');

    $self->state->failed();
    $self->reporter->exception(
        message => $message,
    );
}

sub param {
    my ($args, $key, $opts) = @_;

    if (exists $opts->{default} && not exists $args->{$key}) {
        $args->{$key} = $opts->{default};
    }

    if (exists $args->{$key}) {
        delete $args->{$key};
    } else {
        if ($opts->{optional}) {
            return undef;
        } else {
            Carp::confess "Missing mandatory parameter: ${key}";
        }
    }
}

sub diag {
    my ($self, %args) = @_;
    return if $self->care_child(\%args);
    my $message = param(\%args, 'message');
    my $cutoff  = param(\%args, 'cutoff', { default => $self->reporter->cutoff });
    my $caller  = param(\%args, 'caller');

    $self->reporter->diag(
        message => $message,
        cutoff  => $cutoff,
        caller  => $caller,
    );
}

sub subtest {
    my ($self, %args) = @_;
    my $title = param(\%args, 'title');
    my $code  = param(\%args, 'code');
    my $suite = param(\%args, 'suite');

    my $guard = $self->reporter->suite($title);

    $suite->parent->call_trigger('setup');
    try {
        $code->();
    } catch {
        $self->exception(message => $_);
    };

    if (-d $self->message_dir) {
        require Storable;
        for my $fname (glob($self->message_dir . "/*")) {
            open my $fh, '<', $fname
                or die;
            my $dat = Storable::thaw(do { local $/; <$fh> });
            close $fh;
            unlink $fname;

            my ($method, $args) = @$dat;
            $self->$method(%$args);
        }
        rmdir $self->message_dir;
    }

    $suite->parent->call_trigger('teardown');
}

sub done_testing {
    my ($self) = @_;
    return if $self->{finished}++;

    $self->reporter->finalize();

    # Test::Pretty was loaded
    if (Test::Pretty->can('_subtest')) {
        # Do not run Test::Pretty's finalization
        $Test::Pretty::NO_ENDING=1;
    }
}

sub push_child_message {
    my ($self, $type, $args) = @_;

    require Time::HiRes;
    require Storable;

    mkdir $self->message_dir;

    my $fname = File::Spec->catfile($self->message_dir, "$$." . Time::HiRes::time());
    open my $fh, '>>', $fname
        or die "$fname: $!";
    print {$fh} Storable::nfreeze([$type, $args]) . "\n";
    close $fh;
}

sub DESTROY {
    my $self = shift;
    if ($$ == $self->pid) {
        File::Path::rmtree($self->message_dir); # 為念
    }
}

1;

