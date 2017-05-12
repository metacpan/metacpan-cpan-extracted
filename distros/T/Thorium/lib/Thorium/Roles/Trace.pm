package Thorium::Roles::Trace;
{
  $Thorium::Roles::Trace::VERSION = '0.510';
}
BEGIN {
  $Thorium::Roles::Trace::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Add code tracing and argument dumping to your class

use Thorium::Protection;

use MooseX::Role::Strict;

# core
use Data::Dumper;
use Scalar::Util qw();

# Attributes

has 'tracing' => (
    'is'              => 'rw',
    'isa'             => 'Bool',
    'default'         => 0,
    'trigger'         => \&_set_tracing,
    'documentation' => 'Turn tracing on or off by setting this attribute to true.'
);

has 'trace_meta' => (
    'is'              => 'rw',
    'isa'             => 'Bool',
    'default'         => 0,
    'documentation' => 'Include calls to the objects meta method (Class::MOP) in trace output.'
);

has 'dump_args' => (
    'is'      => 'rw',
    'isa'     => 'Bool',
    'default' => 0,
    'trigger' => \&_set_args_dump,
    'documentation' =>
      'Dump arguments being passed in and out of every method. Note, argument dumping will turn on tracing as well.'
);

has 'dump_args_in' => (
    'is'              => 'rw',
    'isa'             => 'Bool',
    'default'         => 0,
    'trigger'         => \&_set_args_dump_in,
    'documentation' => 'Dump arguments being passed in to a method.'
);

has 'dump_args_out' => (
    'is'              => 'rw',
    'isa'             => 'Bool',
    'default'         => 0,
    'trigger'         => \&_set_args_dump_out,
    'documentation' => 'Dump arguments being passed out of a method.'
);

has 'dump_maxdepth' => (
    'is'              => 'rw',
    'isa'             => 'Maybe[Int]',
    'default'         => undef,
    'documentation' => 'Maximum depth of argument dump - sets C<$Data::Dumper::Maxdepth> locally.'
);

has 'dump_skip_self' => (
    'is'      => 'rw',
    'isa'     => 'Bool',
    'default' => 1,
    'documentation' =>
'Do not include C<$self> in dump. This is true by default. Note, this just blindly skips the first argument in @_!'
);

has 'trace_dbi_calls' => (
    'is'              => 'rw',
    'isa'             => 'Bool',
    'default'         => 0,
    'trigger'         => \&_set_dbi_handlers,
    'documentation' => 'Add simple tracing callbacks to some DBI methods.'
);

has '_dbh_to_trace' => (
    'is'      => 'rw',
    'isa'     => 'Maybe[Object]',
    'default' => undef,
);

# Builders

# Triggers

# these need to be skipped to avoid deep recursion
my @_skip_methods = qw(
  tracing
  trace_meta
  dump_args
  dump_args_in
  dump_args_out
  dump_maxdepth
  dump_skip_self
  log
);

sub _set_tracing {
    my $self = shift;
    my ($new) = @_;

    # if tracing is being set to false, short-circuit and return
    # also, we only need to do this once the first time set to true
    # XXX: is there a way to drop method modifiers?
    return unless $new;

    # Get methods
    my $class   = ref $self;
    my $meta    = $self->meta;
    my @methods = $meta->get_all_method_names();

    # do we have a log object as an attribute?
    my $is_logging = 0;
    $is_logging = 1 if 'log' ~~ @methods && Scalar::Util::blessed $self->log eq 'Thorium::Log';

    if ($meta->is_immutable) {
        $self->meta->make_mutable;
    }

    # go over methods and declare before and after method modifiers that handle
    # tracing and method dumping.
    for my $method (@methods) {

        # avoid deep recursion
        next if $method ~~ @_skip_methods;
        next if $method eq 'meta' && !$self->trace_meta;
        push(@_skip_methods, $method);    # don't add next time

        $meta->add_around_method_modifier(
            $method,
            sub {
                my $next = shift;
                my $self = shift;

                my $msg = "##### Entering $class" . "::$method #####\n";

                if ($self->dump_args_in) {
                    local $Data::Dumper::Maxdepth = $self->dump_maxdepth;
                    $msg .= "*** $method args ***\n";
                    $msg .= $self->dump_skip_self ? Dumper(\@_) : Dumper([ $self, @_ ]);
                }

                $is_logging && $self->log->enabled ? $self->log->trace($msg) : warn $msg;

                my (@rl, $rs);

                if (wantarray) {
                    @rl = $self->$next(@_);
                }
                else {
                    $rs = $self->$next(@_);
                }

                $msg = "##### Leaving $class" . "::$method #####\n";

                if ($self->dump_args_out) {
                    local $Data::Dumper::Maxdepth = $self->dump_maxdepth;
                    $msg .= "*** $method returned ***\n";
                    (wantarray) ? $msg .= Dumper(\@rl) : $msg .= Dumper($rs);
                }

                $is_logging && $self->log->enabled ? $self->log->trace($msg) : warn $msg;

                (wantarray) ? return @rl : return $rs;
            }
        );
    }

}    # _set_tracing

sub _set_args_dump {
    my $self = shift;
    my ($new) = @_;

    # if we're turning on arg dumping turn on tracing too
    $self->tracing($new) if $new;

    $self->dump_args_in($new);
    $self->dump_args_out($new);
}

sub _set_args_dump_in {
    my $self = shift;
    $self->tracing($_[0]) if $_[0];
}

sub _set_args_dump_out {
    my $self = shift;
    $self->tracing($_[0]) if $_[0];
}

sub _set_dbi_handlers {
    my $self = shift;

    return unless ($INC{'DBI.pm'} && $DBI::VERSION > 1.5);

    my ($dbh) = $self->_dbh_to_trace;

    my $meta    = $self->meta;
    my @methods = $meta->get_all_method_names();

    # do we have a log object as an attribute?
    my $is_logging = 0;
    $is_logging = 1 if 'log' ~~ @methods && Scalar::Util::blessed $self->log eq 'Thorium::Log';

    $dbh->{'Callbacks'} = {
        'prepare' => sub {
            my (undef, $query) = @_;

            my $msg = "DBI Preparing SQL: $query";

            $is_logging ? $self->log->trace($msg) : warn $msg;
            return;
        },
        'do' => sub {
            my (undef, $query) = @_;
            my $msg = "DBI do: $query";

            $is_logging ? $self->log->trace($msg) : warn $msg;
            return;
        },
        'connect' => sub {
            my $msg = 'DBI Connected';

            $is_logging ? $self->log->trace($msg) : warn $msg;
            return;
        },
        'disconnect' => sub {
            my $msg = 'DBI Disconnected';

            $is_logging ? $self->log->trace($msg) : warn $msg;
            return;
        },
    };

    return;
}

# Method modifiers
around 'trace_dbi_calls' => sub {
    my $orig = shift;
    my $self = shift;
    my $dbh  = shift;

    if (!$dbh) {
        return $self->$orig(0);
    }
    else {
        $self->_dbh_to_trace($dbh);
        return $self->$orig(1);
    }
};

no Moose::Role;

1;



=pod

=head1 NAME

Thorium::Roles::Trace - Add code tracing and argument dumping to your class

=head1 VERSION

version 0.510

=head1 SYNOPSIS

    package MyModule;
    
    use Moose;
    with qw(Thorium::Roles::Trace);
    
    # ... methods, attributes and such

Then when using an object of your class

    use MyModule;
    
    # new object, with tracing turned on
    
    my $obj = MyModule->new(tacing => 1);
    
    $obj->method(); # method and all calls from $self interally are traced
    # ##### Entering MyModule::method #####
    # ##### Leaving MyModule::method #####
    
    $obj->dump_args_in(1);
    
    $obj->method2({one => 1}); # dump arguments being passed into methods
    # ##### Entering MyModule::method2 #####
    # *** method2 args ***
    # $VAR1 = [                    
    #           {
    #             'one' => 1
    #           }
    #         ];
    # ##### Leaving MyModule::method2 #####

Note that methods added after tracing is set will not be logged until tracing is
set again. Methods set with C<*MyModule::method = sub {}> will never be seen; use
C<$meta->add_method> instead!

=head1 DESCRIPTION

This role adds tracing to arguments, sub-routines entering/leaving and returned
data to L<Thorium::Log> logging or C<STDERR> if no logging sub-system found.

=head1 WARNING!

Do B<not> keep tracing enabled in production. It has measurable performance
penalties! Tracing should be a temporary debugging action. Proper logging is a
permanent debugging action.

=head1 MORE WARNING!

Once you turn on tracing it is not possible to turn off as the original
references to the sub-routines are embedded into new sub-routines and as a
result, lost. It is technically possible add the ability to turn off tracing,
but for the sake of simplicity and for the note listed in L</"WARNING!"> the
feature is absent.

=head1 ATTRIBUTES

=head2 Optional Attributes

=over

=item * tracing (rw, Bool)

Turn tracing on or off by setting this attribute to true. Defaults to false.

=item * trace_meta (rw, Bool)

Include calls to the objects meta method (Class::MOP) in trace output. Defaults
to false.

=item * dump_args (rw, Bool)

Dump arguments being passed in and out of every method. Note, argument dumping
will turn on tracing as well. Defaults to false.

=item * dump_args_in (rw, Bool)

Dump arguments being passed in to a method. Defaults to false.

=item * dump_args_out (rw, Bool)

Dump arguments being passed out of a method. Defaults to false.

=item * dump_maxdepth (rw, Maybe[Int])

Maximum depth of argument dump - sets C<$Data::Dumper::Maxdepth> locally. Defaults to false.

=item * dump_skip_self (rw, Bool)

Do not include C<$self> in dump. This is true by default. Note, this just blindly
skips the first argument in @_!

=item * trace_dbi_calls (rw, DBH|Bool)

Add simple tracing callbacks to some L<DBI> methods:

=over

=item * connect

=item * prepare

=item * do

=item * disconnect

=back

=back

=head1 PUBLIC API METHODS

None. This is a L<Moose::Role>.

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

