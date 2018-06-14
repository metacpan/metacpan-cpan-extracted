package TestML1::Runtime;

use TestML1::Base;

has testml => ();
has bridge => ();
has library => ();
has compiler => ();
has skip => ();

has function => ();
has error => ();
has global => ();
has base => ();

use File::Basename();
use File::Spec();

sub BUILD {
    my ($self) = @_;
    $TestML1::Runtime::Singleton = $self;
    $self->{base} ||= File::Basename::dirname($0);
}

sub run {
    my ($self) = @_;
    $self->compile_testml;
    $self->initialize_runtime;
    $self->run_function($self->{function}, []);
}

# TODO Functions should have return values
sub run_function {
    my ($self, $function, $args) = @_;

    $self->apply_signature($function, $args);

    my $parent = $self->function;
    $self->{function} = $function;

    for my $statement (@{$function->statements}) {
        if (ref($statement) eq 'TestML1::Assignment') {
            $self->run_assignment($statement);
        }
        else {
            $self->run_statement($statement);
        }
    }
    $self->{function} = $parent;
    return;
}

sub apply_signature {
    my ($self, $function, $args) = @_;
    my $signature = $function->signature;

    die sprintf(
        "Function received %d args but expected %d",
        scalar(@$args),
        scalar(@$signature),
    ) if @$signature and @$args != @$signature;

    $function->setvar('Self', $function);
    for (my $i = 0; $i < @$signature; $i++) {
        my $arg = $args->[$i];
        $arg = $self->run_expression($arg)
            if ref($arg) eq 'TestML1::Expression';
        $function->setvar($signature->[$i], $arg);
    }
}

sub run_statement {
    my ($self, $statement) = @_;
    my $blocks = $self->select_blocks($statement->points || []);
    for my $block (@$blocks) {
        $self->function->setvar('Block', $block) if $block != 1;
        my $result = $self->run_expression($statement->expr);
        if (my $assert = $statement->assert) {
            $self->run_assertion($result, $assert);
        }
    }
}

sub run_assignment {
    my ($self, $assignment) = @_;
    $self->function->setvar(
        $assignment->name,
        $self->run_expression($assignment->expr),
    );
}

sub run_assertion {
    my ($self, $left, $assert) = @_;
    my $method = 'assert_' . $assert->name;

    $self->function->getvar('TestNumber')->{value}++;

    if ($assert->expr) {
        $self->$method($left, $self->run_expression($assert->expr));
    }
    else {
        $self->$method($left);
    }
}

sub run_expression {
    my ($self, $expr) = @_;

    my $context = undef;
    $self->{error} = undef;
    if ($expr->isa('TestML1::Expression')) {
        my @calls = @{$expr->calls};
        die if @calls <= 1;
        $context = $self->run_call(shift(@calls));
        for my $call (@calls) {
            if ($self->error) {
                next unless
                    $call->isa('TestML1::Call') and
                    $call->name eq 'Catch';
            }
            $context = $self->run_call($call, $context);
        }
    }
    else {
        $context = $self->run_call($expr);
    }
    if ($self->error) {
        die $self->error;
    }
    return $context;
}

sub run_call {
    my ($self, $call, $context) = @_;

    if ($call->isa('TestML1::Object')) {
        return $call;
    }
    if ($call->isa('TestML1::Function')) {
        return $call;
    }
    if ($call->isa('TestML1::Point')) {
        return $self->get_point($call->name);
    }
    if ($call->isa('TestML1::Call')) {
        my $name = $call->name;
        my $callable =
            $self->function->getvar($name) ||
            $self->lookup_callable($name) ||
                die "Can't locate '$name' callable";
        if ($callable->isa('TestML1::Object')) {
            return $callable;
        }
        return $callable unless $call->args or defined $context;
        $call->{args} ||= [];
        my $args = [map $self->run_expression($_), @{$call->args}];
        unshift @$args, $context if $context;
        if ($callable->isa('TestML1::Callable')) {
            my $value = eval { $callable->value->(@$args) };
            if ($@) {
                $self->{error} = $@;
                return TestML1::Error->new(value => $@);
            }
            die "'$name' did not return a TestML1::Object object"
                unless UNIVERSAL::isa($value, 'TestML1::Object');
            return $value;
        }
        if ($callable->isa('TestML1::Function')) {
            return $self->run_function($callable, $args);
        }
        die;
    }
    die;
}

sub lookup_callable {
    my ($self, $name) = @_;
    for my $library (@{$self->function->getvar('Library')->value}) {
        if ($library->can($name)) {
            my $function = sub { $library->$name(@_) };
            my $callable = TestML1::Callable->new(value => $function);
            $self->function->setvar($name, $callable);
            return $callable;
        }
    }
    return;
}

sub get_point {
    my ($self, $name) = @_;
    my $value = $self->function->getvar('Block')->{points}{$name};
    defined $value or return;
    if ($value =~ s/\n+\z/\n/ and $value eq "\n") {
        $value = '';
    }
    $value =~ s/^\\//gm;
    return TestML1::Str->new(value => $value);
}

sub select_blocks {
    my ($self, $wanted) = @_;
    return [1] unless @$wanted;
    my $selected = [];

    OUTER: for my $block (@{$self->function->data}) {
        my %points = %{$block->points};
        next if exists $points{SKIP};
        if (exists $points{ONLY}) {
            for my $point (@$wanted) {
                return [] unless exists $points{$point};
            }
            $selected = [$block];
            last;
        }
        for my $point (@$wanted) {
            next OUTER unless exists $points{$point};
        }
        push @$selected, $block;
        last if exists $points{LAST};
    }
    return $selected;
}

sub compile_testml {
    my ($self) = @_;

    die "'testml' document required but not found"
        unless $self->testml;
    if ($self->testml !~ /\n/) {
        my ($file, $dir) = File::Basename::fileparse($self->testml);
        $self->{testml} = $file;
        $self->{base} = File::Spec->catdir($self->{base}, $dir);
        $self->{testml} = $self->read_testml_file($self->testml);
    }
    $self->{function} = $self->compiler->new->compile($self->testml)
        or die "TestML1 document failed to compile";
}

sub initialize_runtime {
    my ($self) = @_;

    $self->{global} = $self->function->outer;

    $self->{global}->setvar(Block => TestML1::Block->new);
    $self->{global}->setvar(Label => TestML1::Str->new(value => '$BlockLabel'));
    $self->{global}->setvar(True => $TestML1::Constant::True);
    $self->{global}->setvar(False => $TestML1::Constant::False);
    $self->{global}->setvar(None => $TestML1::Constant::None);
    $self->{global}->setvar(TestNumber => TestML1::Num->new(value => 0));
    $self->{global}->setvar(Library => TestML1::List->new);

    my $library = $self->function->getvar('Library');
    for my $lib ($self->bridge, $self->library) {
        if (ref($lib) eq 'ARRAY') {
            $library->push($_->new) for @$lib;
        }
        else {
            $library->push($lib->new);
        }
    }
}

sub get_label {
    my ($self) = @_;
    my $label = $self->function->getvar('Label') or return;
    $label = $label->value or return;
    $label =~ s/\$(\w+)/$self->replace_label($1)/ge;
    return $label;
}

sub replace_label {
    my ($self, $var) = @_;
    my $block = $self->function->getvar('Block');
    return $block->label if $var eq 'BlockLabel';
    if (my $v = $block->points->{$var}) {
        $v =~ s/\n.*//s;
        $v =~ s/^\s*(.*?)\s*$/$1/;
        return $v;
    }
    if (my $v = $self->function->getvar($var)) {
        return $v->value;
    }
}

sub read_testml_file {
    my ($self, $file) = @_;
    my $path = File::Spec->catfile($self->base, $file);
    open my $fh, $path
        or die "Can't open '$path' for input: $!";
    local $/;
    return <$fh>;
}

#-----------------------------------------------------------------------------
package TestML1::Function;

use TestML1::Base;

has type => 'Func';     # Functions are TestML1 typed objects
has signature => [];    # Input variable names
has namespace => {};    # Lexical scoped variable stash
has statements => [];   # Exexcutable code statements
has data => [];         # Data section scoped to this function

my $outer = {};
sub outer { @_ == 1 ? $outer->{$_[0]} : ($outer->{$_[0]} = $_[1]) }

sub getvar {
    my ($self, $name) = @_;
    while ($self) {
        if (my $object = $self->namespace->{$name}) {
            return $object;
        }
        $self = $self->outer;
    }
    undef;
}

sub setvar {
    my ($self, $name, $value) = @_;
    $self->namespace->{$name} = $value;
}

sub forgetvar {
    my ($self, $name) = @_;
    delete $self->namespace->{$name};
}

#-----------------------------------------------------------------------------
package TestML1::Assignment;

use TestML1::Base;

has name => ();
has expr => ();

#-----------------------------------------------------------------------------
package TestML1::Statement;

use TestML1::Base;

has expr => ();
has assert => ();
has points => ();

#-----------------------------------------------------------------------------
package TestML1::Expression;

use TestML1::Base;

has calls => [];

#-----------------------------------------------------------------------------
package TestML1::Assertion;

use TestML1::Base;

has name => ();
has expr => ();

#-----------------------------------------------------------------------------
package TestML1::Call;

use TestML1::Base;

has name => ();
has args => ();

#-----------------------------------------------------------------------------
package TestML1::Callable;

use TestML1::Base;
has value => ();

#-----------------------------------------------------------------------------
package TestML1::Block;

use TestML1::Base;

has label => '';
has points => {};

#-----------------------------------------------------------------------------
package TestML1::Point;

use TestML1::Base;

has name => ();

#-----------------------------------------------------------------------------
package TestML1::Object;

use TestML1::Base;

has value => ();

sub type {
    my $type = ref($_[0]);
    $type =~ s/^TestML1::// or die "Can't find type of '$type'";
    return $type;
}

sub str { die "Cast from ${\ $_[0]->type} to Str is not supported" }
sub num { die "Cast from ${\ $_[0]->type} to Num is not supported" }
sub bool { die "Cast from ${\ $_[0]->type} to Bool is not supported" }
sub list { die "Cast from ${\ $_[0]->type} to List is not supported" }
sub none { $TestML1::Constant::None }

#-----------------------------------------------------------------------------
package TestML1::Str;

use TestML1::Base;
extends 'TestML1::Object';

sub str { $_[0] }
sub num { TestML1::Num->new(
    value => ($_[0]->value =~ /^-?\d+(?:\.\d+)$/ ? ($_[0]->value + 0) : 0),
)}
sub bool {
    length($_[0]->value) ? $TestML1::Constant::True : $TestML1::Constant::False
}
sub list { TestML1::List->new(value => [split //, $_[0]->value]) }

#-----------------------------------------------------------------------------
package TestML1::Num;

use TestML1::Base;
extends 'TestML1::Object';

sub str { TestML1::Str->new(value => $_[0]->value . "") }
sub num { $_[0] }
sub bool { ($_[0]->value != 0) ? $TestML1::Constant::True : $TestML1::Constant::False }
sub list {
    my $list = [];
    $#{$list} = int($_[0]) -1;
    TestML1::List->new(value =>$list);
}

#-----------------------------------------------------------------------------
package TestML1::Bool;

use TestML1::Base;
extends 'TestML1::Object';

sub str { TestML1::Str->new(value => $_[0]->value ? "1" : "") }
sub num { TestML1::Num->new(value => $_[0]->value ? 1 : 0) }
sub bool { $_[0] }

#-----------------------------------------------------------------------------
package TestML1::List;

use TestML1::Base;
extends 'TestML1::Object';
has value => [];
sub list { $_[0] }
sub push {
    my ($self, $elem) = @_;
    push @{$self->value}, $elem;
}

#-----------------------------------------------------------------------------
package TestML1::None;

use TestML1::Base;
extends 'TestML1::Object';

sub str { TestML1::Str->new(value => '') }
sub num { TestML1::Num->new(value => 0) }
sub bool { $TestML1::Constant::False }
sub list { TestML1::List->new(value => []) }

#-----------------------------------------------------------------------------
package TestML1::Native;

use TestML1::Base;
extends 'TestML1::Object';

#-----------------------------------------------------------------------------
package TestML1::Error;

use TestML1::Base;
extends 'TestML1::Object';

#-----------------------------------------------------------------------------
package TestML1::Constant;

our $True = TestML1::Bool->new(value => 1);
our $False = TestML1::Bool->new(value => 0);
our $None = TestML1::None->new;

1;
