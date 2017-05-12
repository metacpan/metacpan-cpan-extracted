package XAS::Supervisor::Monitor;

our $VERSION = '0.01';

use XAS::Lib::Process;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'Badger::Prototype XAS::Base',
  mixin      => 'XAS::Lib::Mixins::Configs',
  utils      => 'trim :env :validation',
  constants  => 'TRUE FALSE',
  accessors  => 'cfg',
  filesystem => 'Dir',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub load {
    my $self = shift;

    $self = $self->prototype() unless ref $self;

    my ($service) = validate_params(\@_, [1]);
    
    my $processes = {};
    my @sections = $self->cfg->Sections();

    foreach my $section (@sections) {

        next if ($section !~ /^program:/);

        my $env = {};
        my ($alias) = $section =~ /^program:(.*)/;

        $alias = trim($alias);

        if (my $e = $self->cfg->val($section, 'environment', undef)) {

            $env = env_parse($e);

        }

        my $process = XAS::Lib::Process->new(
            -alias          => $alias,
            -auto_start     => $self->cfg->val($section, 'auto-start', TRUE),
            -auto_restart   => $self->cfg->val($section, 'auto-restart', TRUE),
            -command        => $self->cfg->val($section, 'command'),
            -directory      => Dir($self->cfg->val($section, 'directory', "/")),
            -environment    => $env,
            -exit_codes     => $self->cfg->val($section, 'exit-codes', '0,1'),
            -exit_retries   => $self->cfg->val($section, 'exit-retires', 5),
            -group          => $self->cfg->val($section, 'group', 'xas'),
            -priority       => $self->cfg->val($section, 'priority', 0),
            -pty            => 1,
            -umask          => $self->cfg->val($section, 'umask', '0022'),
            -user           => $self->cfg->val($section, 'user', 'xas'),
            -redirect       => $self->cfg->val($section, 'redirect', FALSE),
            -output_handler => sub {
                my $output = shift;
                $output = trim($output);
                if (my ($level, $line) = $output =~/\s+(\w+)\s+-\s+(.*)/ ) {
                    $level = lc(trim($level));
                    $line  = trim($line);
                    $self->log->$level(sprintf('%s: %s', $alias, $line));
                } else {
                    $self->log->info(sprintf('%s: -> %s', $alias, $output));
                }
            }
        );

        $processes->{$alias} = $process;
        $service->register($alias);

    }

    return $processes;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->load_config();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Supervisor::Monitor - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Supervisor::Monitor;

 my $processes = XAS::Supervisor::Monitor->load($service);

=head1 DESCRIPTION

This package is used to load a configuration file and start the processes
that are defined. 

=head1 METHODS

=head2 new

Initialize the module. This will load the configuration file. Not neccessary
to be invoked as invoking load() will do the same thing. 

=head2 load

Load the processes defined within the configuration file. Returns a
hash of the loaded processes.

=head1 SEE ALSO

=over 4

=item L<XAS::Supervisor::Client|XAS::Supervisor::Client>

=item L<XAS::Supervisor::Controller|XAS::Supervisor::Controller>

=item L<XAS::Supervisor|XAS::Supervisor>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
