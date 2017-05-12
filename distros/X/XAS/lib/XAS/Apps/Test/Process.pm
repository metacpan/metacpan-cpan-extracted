package XAS::Apps::Test::Process;

our $VERSION = '0.01';

use XAS::Lib::Process;

use XAS::Class
  version    => $VERSION,
  base       => 'XAS::Lib::App::Service',
  mixin      => 'XAS::Lib::Mixins::Configs',
  accessors  => 'cfg',
  utils      => 'dotid trim',
  filesystem => 'Dir Cwd',
  vars => {
    SERVICE_NAME         => 'XAS_Process',
    SERVICE_DISPLAY_NAME => 'XAS Process Test',
    SERVICE_DESCRIPTION  => 'This is a test Perl service using XAS'
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

    my @sections = $self->cfg->Sections();

    foreach my $section (@sections) {

        next if ($section !~ /^program:/);

        my $cwd = Cwd;
        my ($alias) = $section =~ /^program:\s+(.*)/;

        my $process = XAS::Lib::Process->new(
            -alias        => trim($alias),
            -command      => $self->cfg->val($section, 'command'),
            -auto_start   => $self->cfg->val($section, 'auto-start', '1'),
            -auto_restart => $self->cfg->val($section, 'auto-restart', '1'),
            -exit_codes   => $self->cfg->val($section, 'exit-codes', '0,1'),
            -exit_retries => $self->cfg->val($section, 'exit-retries', '5'),
            -group        => $self->cfg->val($section, 'group', 'wpm'),
            -priority     => $self->cfg->val($section, 'priority', 0),
            -umask        => $self->cfg->val($section, 'umask', '0022'),
            -user         => $self->cfg->val($section, 'user', 'wpm'),
            -redirect     => $self->cfg->val($section, 'redirect' , '0'),
            -directory    => Dir($self->cfg->val($section, 'directory', $cwd)),
            -output_handler => sub {
               my $output = shift;
               my $line  = trim($output) || '';
               $self->log->info(sprintf('%s: %s', trim($alias), $line));
           }
        );

        $self->service->register($alias);

    }

}

sub main {
    my $self = shift;

    $self->log->info_msg('startup');

    $self->setup();
    $self->service->run();

    $self->log->info_msg('shutdown');

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

XAS::Apps::Test::Process - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Apps::Test::Process;

=head1 DESCRIPTION

=head1 METHODS

=head2 setup

=head2 main

=head2 options

=head1 SEE ALSO

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by WSIPC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
