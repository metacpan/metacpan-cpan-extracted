package Thorium::Log;
{
  $Thorium::Log::VERSION = '0.510';
}
BEGIN {
  $Thorium::Log::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Logging support

use Thorium::Protection;

use Moose;

# core
use Benchmark qw(timediff timestr);
use Data::Dumper;

# CPAN
use DateTime;
use Log::Log4perl qw(:levels);

# Attributes
has 'enabled' => (
    'is'            => 'rw',
    'isa'           => 'Bool',
    'default'       => 1,
    'documentation' => 'True if logging is currently enabled.'
);

has '_env_var_config_key' => (
    'is'      => 'rw',
    'isa'     => 'Str',
    'default' => 'THORIUM_LOG_CONF_FILE'
);

has 'config_file' => (
    'is'      => 'rw',
    'isa'     => 'Str',
    'documentation' => 'The location of the configuration file to read. You may set the environment variable C<THORIUM_LOG_CONF_FILE> otherwise F</etc/thorium/log.conf> will be used. An example is provided in this distribution under F<conf/log.conf>. See Log::Log4Perl for details.',
    'lazy_build' => 1
);

sub _build_config_file {
    my ($self) = @_;

    my $log_file = '/etc/thorium/log.conf';

    if ($ENV{$self->_env_var_config_key} && -r $ENV{$self->_env_var_config_key}) {
        $log_file = $ENV{$self->_env_var_config_key};
    }

    return $log_file;
}

has 'caller_depth' => (
    'is'            => 'rw',
    'isa'           => 'Int',
    'default'       => 1,
    'documentation' => 'Determines (additional) depth for caller inside Log4Perl.'
);

has 'category' => (
    'is'         => 'ro',
    'isa'        => 'Str',
    'init_arg'   => 'set_category',
    'lazy_build' => 1,
    'documentation' =>
'The category to use for Log4Perl. This is used to set category specific log levels in the configuration. Default is the name of the package in which the Thorium::Log object was created.'
);

has 'prefix' => (
    'is'      => 'rw',
    'isa'     => 'Str',
    'default' => ''
);

has 'add_benchmarks' => (
    'is'      => 'rw',
    'isa'     => 'Bool',
    'default' => 0,
    'documentation' =>
'Every time a log message is output ($log->$level($message)), additionally outputs a benchmark time line with the time elapsed since the last log message was output.'
);

has 'die_on_fatal' => (
    'is'            => 'rw',
    'isa'           => 'Bool',
    'default'       => 0,
    'documentation' => 'Allows automatic C<die()>ing for the fatal level.'
);

has '_last_benchmark' => (
    'is'      => 'rw',
    'isa'     => 'Benchmark',
    'default' => sub { Benchmark->new() },
    'lazy'    => 1,
);

has '_logger' => (
    'is'         => 'ro',
    'isa'        => 'Log::Log4perl::Logger',
    'lazy_build' => 1,
);

# Builders: subclass modifiable defaults - these aren't called if a value is provided

sub _build__logger {
    my $self = shift;

    unless (Log::Log4perl::initialized()) {
        if (-e -r $self->config_file) {
            Log::Log4perl::init($self->config_file);
        }
    }

    return Log::Log4perl->get_logger($self->category);
}

sub _build_category {
    my $self = shift;

    # package name where Thorium::Log->new() was called or '?' when there is no
    # package name available
    return (caller(1))[0] || '?';
}

sub BUILD {
    my $self = shift;

    # auto-generate logging methods
    my $meta = $self->meta;
    foreach my $level (qw(trace debug info warn error fatal)) {

        $meta->add_method(
            $level,
            sub {
                my $self = shift;
                return unless @_;
                return unless $self->enabled;

                # magic to make the call stack correct
                local $Log::Log4perl::caller_depth += $self->caller_depth;    ## no critic

                my $logger      = $self->_logger;
                my $check_level = 'is_' . $level;

                return unless $logger->$check_level();

                if ($self->add_benchmarks) {

                    # first thing logged takes 0 time
                    my $t0 = $self->_last_benchmark;
                    my $t1 = Benchmark->new();
                    my $td = timediff($t1, $t0);

                    $logger->$level('The code took: ', timestr($td));
                    $self->_last_benchmark($t1);
                }

                my $message = '';
                foreach my $string (@_) {
                    if (ref($string)) {
                        $message .= Dumper($string);
                    }
                    else {
                        $message .= $string // '';
                    }
                }

                $logger->$level($self->prefix, $message);

                if ($self->die_on_fatal && $level eq 'fatal') {
                    CORE::exit(1);
                }

                return;
            }
        );
    }

    # and now that we're done building methods
    $meta->meta->make_immutable;

    return;
}

# Methods

sub carp {
    return shift->_logger->logcarp(@_);
}

sub cluck {
    return shift->_logger->logcluck(@_);
}

sub croak {
    return shift->_logger->logcroak(@_);
}

sub confress {
    return shift->_logger->logconfess(@_);
}

no Moose;

1;


__END__
=pod

=head1 NAME

Thorium::Log - Logging support

=head1 VERSION

version 0.510

=head1 SYNOPSIS

    use Thorium::Log;

    my $log = Thorium::Log->new();

    $log->warn('Some warning message');

=head1 DESCRIPTION

Thorium::Log is a high level wrapper class around L<Log::Log4perl>'s
functionality. It exists to replace all C<print>s and C<say>s. See
L<Thorium::Roles::Logging> for adding logging support via C<$self->log->...> to
your object. You are encouraged to subclass and set C<prefix()>.

=head1 ATTRIBUTES

=head2 Optional Attributes

=over

=item * B<add_benchmarks> (C<rw>, C<Bool>)

Every time a log message is output ($log->$level($message)), additionally
outputs a benchmark time line with the time elapsed since the last log message
was output. Defaults to '0'.

=item * B<caller_depth> (C<rw>, C<Int>)

Determines (additional) depth for caller inside Log4Perl. Defaults to '1'.

=item * B<category> (C<ro>, C<Str>)

The category to use for L<Log::Log4Perl>. This is used to set category specific log
levels in the configuration. Default is the name of the package in which the
Thorium::Log object was created.

=item * B<config_file> (C<rw>, C<Str>)

The location of the configuration file to read. You may set the environment
variable C<THORIUM_LOG_CONF_FILE> otherwise F</etc/thorium/log.conf> will be
used. An example is provided in this distribution under F<conf/log.conf>. See
Log::Log4Perl for details.

=item * B<die_on_fatal> (C<rw>, C<Bool>)

Allows automatic C<die()>ing for the fatal level. Defaults to '0'.

=back

=head1 PUBLIC API METHODS

=head2 Levels

=over

=item * B<trace($str_or_ref, ...)>

=item * B<debug($str_or_ref, ...)>

=item * B<info($str_or_ref, ...)>

=item * B<warn($str_or_ref, ...)>

=item * B<error($str_or_ref, ...)>

=item * B<fatal($str_or_ref, ...)>

=back

=head2 Stack Traces

=over

=item * B<carp($str_or_ref, ...)>

Warn with one level of a stack trace.

=item * B<cluck($str_or_ref, ...)>

Warn with full stack trace.

=item * B<confress($str_or_ref, ...)>

Die with one level of a stack trace.

=item * B<croak($str_or_ref, ...)>

Die with full stack trace.

=back

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

