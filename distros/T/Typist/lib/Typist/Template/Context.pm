package Typist::Template::Context;
use strict;

use base qw( Class::ErrorHandler );

use constant FALSE => -99999;
use Exporter;
*import = \&Exporter::import;
use vars qw( @EXPORT );
@EXPORT = qw( FALSE pass_tokens pass_tokens_else );

use vars qw( %Handlers %Filters );

sub new {
    my $class = shift;
    my $ctx = bless {}, $class;
    $ctx->init(@_);
}

sub init {
    my $ctx   = shift;
    my $class = ref($ctx);
    $ctx->{__handlers} = {};
    $ctx->{__filters}  = {};
    if ($@) {    # initialize stash.
        if (ref $_[0] eq 'HASH') {
            map { $ctx->stash($_, $_[0]->{$_}) } keys %{$_[0]};
        } else {
            my @stash_pairs = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;    # ???
            return $class->error(
                              "Uneven number of arguments to initialize stash.")
              if (int(@stash_pairs) & 1);
            while (@stash_pairs) {
                my $key = shift @stash_pairs;
                my $val = shift @stash_pairs;
                $ctx->stash($key, $val);
            }
        }
    }
    $ctx;
}

sub var {
    $_[0]->{__var}->{$_[1]} = $_[2] if defined $_[2];
    $_[0]->{__var}->{$_[1]};
}

sub stash {
    my $ctx = shift;
    my $key = shift;
    $ctx->{__stash}->{$key} ||= [];
    if (@_) {
        push @{$ctx->{__stash}->{$key}}, shift;
    }
    wantarray ? @{$ctx->{__stash}->{$key}} : $ctx->{__stash}->{$key}->[-1];
}

sub unstash { pop @{$_[0]->{__stash}->{$_[1]}} }

#--- internal plugin methods

sub register_handler {    # $class/$object, $tag, $handler
    ref $_[0]
      ? $_[0]->{__handlers}->{$_[1]} =
        $_[2]
      : $Handlers{$_[1]} = $_[2];
}

sub register_filter {
    ref $_[0]
      ? $_[0]->{__filters}->{$_[1]} =
        $_[2]
      : $Filters{$_[1]} = $_[2];
}

sub handler_for {
    my $v = $_[0]->{__handlers}->{$_[1]} || $Handlers{$_[1]};
    ref($v) eq 'ARRAY' ? @$v : $v;
}

sub post_process_handler {
    sub {
        my ($ctx, $args, $str) = @_;
        foreach my $name (keys %$args) {
            my $code = $ctx->{__filters}->{$name} || $Filters{$name} || next;
            $str = $code->($str, $args->{$name}, $ctx);
        }
        $str;
      }
}

#--- plugin API

sub add_tag {
    my ($this, $name, $code) = @_;
    my $h = [$code, 0];
    $this->register_handler($name, $h);
}

sub add_container_tag {
    my ($this, $name, $code) = @_;
    my $h = [$code, 1];
    $this->register_handler($name, $h);
}

sub add_conditional_tag {
    my ($this, $name, $condition) = @_;
    my $h = [
        sub {
            if ($condition->(@_)) {
                return pass_tokens(@_);
            } else {
                return pass_tokens_else(@_);
            }
        },
        1
    ];
    $this->register_handler($name, $h);
}

sub add_global_filter {
    my ($this, $name, $code) = @_;
    $this->register_filter($name, $code);
}

#-- exportable methods

sub pass_tokens {
    $_[0]->stash('builder')->build($_[0], $_[0]->stash('tokens'), $_[2]);
}

sub pass_tokens_else {
    $_[0]->stash('builder')->build($_[0], $_[0]->stash('tokens_else'), $_[2]);
}

1;

__END__

=head1 NAME

Typist::Template::Context - contains and manages the context for a template

=head1 METHODS

=over

=item Typist::Template::Context->new(\%init_stash);

=item $ctx->stash($key, $scalar)

=item $ctx->unstash($key)

=item $ctx->var($name,[$val])

Set/get and template variable.

=item $this->add_tag(name => \&handler_code)

=item $this->add_container_tag(name => \&handler_code)

=item $this->add_conditional_tag(name => \&handler_code)

These three methods register template tags and take the same
parameters. The difference is how the build will treat them.
They require parameters of the tag name and a CODE reference
to the tag handler. 

If $this is an object the tag's scope will be tied to that
specific object rather then the Typist::Template::Context
class.

C<add_tag> registers a variable tag. These tags must use $
inside the angle brackets such as C<<$MTEntryTitle$>> These
types of tags do not have any type of contents.

C<add_container_tag> registers a tag which can contain text
or other tags. Use container tags to create loops or
specific contexts.

C<add_conditional_tag> registers a special type of container
tag that renders its contents if a some condition is true.
These tag handlers need only return a true or false value.
The rest is handled automatically. Container tags work with
the built-in C<Else> tag to render context if a conditional
does not evaulate as true.

=item $this->add_global_filter(filter_name => \&handler_code)

Registers a global filter handler. Requires the name of the
filter and a reference to the filter handler be passed. 

If $this is an object the filter's scope will be tied to that
specific object rather then the Typist::Template::Context
class.

=back
