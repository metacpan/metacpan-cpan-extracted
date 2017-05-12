package XAS::Apps::Collector::Process;

our $VERSION = '0.01';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::App::Service',
  mixin     => 'XAS::Lib::Mixins::Configs',
  utils     => 'dotid load_module trim',
  accessors => 'cfg',
  vars => {
    SERVICE_NAME         => 'XAS_Collector',
    SERVICE_DISPLAY_NAME => 'XAS Collector',
    SERVICE_DESCRIPTION  => 'The XAS Collector'
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub build_args {
    my $self = shift;
    my $section = shift;
    my $parameters = shift;

    my @args;

    foreach my $parameter (@$parameters) {

        next if ($parameter eq 'module');
        push(@args, "-$parameter", $self->cfg->val($section, $parameter));

    }

    return @args;

}

sub setup {
    my $self = shift;

    my $types;
    my @sections = $self->cfg->Sections();

    foreach my $section (@sections) {

        next if ($section =~ /^collector:\s+input/);
        next if ($section =~ /^collector:\s+output/);
        next if ($section =~ /^collector:\s+format/);

        my ($type) = $section =~ /^collector:(.*)/;

        my $queue  = $self->cfg->val($section, 'queue');
        my $output = $self->cfg->val($section, 'output');
        my $format = $self->cfg->val($section, 'format');
        my $input  = $self->cfg->val($section, 'input');

        $type = trim($type);
        $types->{$type} = {
            queue  => $queue,
            format => $format,
            output => $output,
            input  => $input,
        };

    }

    foreach my $section (@sections) {

        if ($section =~ /^collector:\s+input/) {

            my $alias = $self->cfg->val($section, 'alias');
            my $module = $self->cfg->val($section, 'module');
            my @parameters = $self->cfg->Parameters($section);
            my @args = $self->build_args($section, \@parameters);

            push(@args, '-types', $types);

            load_module($module);
            $module->new(@args);

            $self->service->register($alias);

        } elsif ($section =~ /^collector:\s+format/) {

            my $alias = $self->cfg->val($section, 'alias');
            my $module = $self->cfg->val($section, 'module');
            my @parameters = $self->cfg->Parameters($section);
            my @args = $self->build_args($section, \@parameters);

            load_module($module);
            $module->new(@args);

            $self->service->register($alias);

        } elsif ($section =~ /^collector:\s+output/) {

            my $alias = $self->cfg->val($section, 'alias');
            my $module = $self->cfg->val($section, 'module');
            my @parameters = $self->cfg->Parameters($section);
            my @args = $self->build_args($section, \@parameters);

            load_module($module);
            $module->new(@args);

            $self->service->register($alias);

        }

    }

}

sub main {
    my $self = shift;

    $self->setup();

    $self->log->info_msg('startup');

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

XAS::Apps::Collector::Process - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Apps::Collector::Process;

 my $app = XAS::Apps::Collector::Process->new(
     -throws => 'xas-collector'
 );

 $app->run();

=head1 DESCRIPTION

This module will retrieve and process messages from a message queue server.
How they are processed is based on the message type and the processing modules 
that are loaded. These are configured in a configuration file.

=head1 CONFIGURATION

The configuration file is the familiar Windows .ini format. It has the 
following stanzas.

 [collector: xas-logs]
 queue  = /queue/logs
 format = format-logs
 output = output-logs
 input  = input-stomp

This defines a message type. It specifies the queue to process, the name of
the format handler, the name of the output handler and the input handler. More
then one message type can be defined. But they need to be unique.

 [collector: input]
 module = XAS::Collector::Input::Stomp
 port = 61613
 host = localhost
 alias = input-stomp

This defines an input handler. There can be more the one. The names must be 
unique. So you can have an input1, input2, etc. The standard parameters are 
the following:

 module - the module that will handle the input
 alias  - the name of the session handling this module

Other parameters may be defined, depending on the module that is being used. 
Please check their documentation.

 [collector: format]
 module = XAS::Collector::Format::Alerts
 alias = format-alerts

This defines a format handler. There can be more then one. The names
must be unique, So you can have a format1, format2, etc. A format handler
formats the incoming message into a standardized data structure. This 
structures is then used by the output handlers.

The standard parameters are the following:

 module - the module that will handle the formatting
 alias  - the name of the session handling this module

There are no additional parameters.

 [collector: output]
 module = XAS::Collector::Output::Database::Alerts
 alias = output-alerts
 database = messaging

This defines an output handler. There can be more then one. The names
must be unique, So you can have a output1, output2, etc. An output handler
does something with the created data structure. Usually storing it into a 
data store of some kind. But it could be used for other things. The standard 
parameters are the following:

 module - the module that will handle the output
 alias  - the name of the session handling this module

Other parameters may be defined, depending on the module that is being used. 
Please check their documentation.

=head2 EXAMPLE

The following is an example of a configuration that would handle the xas-alerts
message type.

 [collector: xas-alerts]
 queue  = /queue/alerts
 format = format-alerts
 output = output-alerts
 input  = input-stomp

 [collector: input]
 module = XAS::Collector::Input::Stomp
 port = 61613
 host = localhost
 alias = input-stomp

 [collector: format]
 module = XAS::Collector::Format::Alerts
 alias = format-alerts

 [collector: output]
 module = XAS::Collector::Output::Database::Alerts
 alias = output-alerts
 database = messaging

=head1 METHODS

=head2 setup

This method will configure the process.

=head2 main

This method will start the processing. 

=head2 options

No additional cli options have been defined. 

=head1 SEE ALSO

=over 4

=item L<XAS::Collector|XAS::Collector>

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
