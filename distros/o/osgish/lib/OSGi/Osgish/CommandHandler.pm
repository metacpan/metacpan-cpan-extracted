#!/usr/bin/perl

package OSGi::Osgish::CommandHandler;

use strict;
use Data::Dumper;
use Term::ANSIColor qw(:constants);

=head1 NAME 

OSGi::Osgish::CommandHandler - Handler for osgish commands

=head1 DESCRIPTION

This object is responsible for managing L<OSGi::Osgish::Command> object which
are at the heart of osgish and provide all features. During startup it
registeres commands dynamicallt and pushes the L<OSGi::Osgish> context to them
for allowing to access the agent and other handlers.

Registration is occurs in two phases:

...

It also keeps a stack of so called navigational I<context> which can be used to
provide a menu like structure (think of it like directories which can be
entered). If the stack contains elements, the navigational commands C<..> and
C</> are added to traverse the stack. C</> will always jump to the top of the
stack (the I<root directory>) whereas C<..> will pop up one level in the stack
(the I<parent directory>). Commands which want to manipulate the stack like
pushing themselves on the stack should use the methods L</push_on_stack> or
L</reset_stack> (for jumping to the top of the menu).

=cut

=head1 METHODS

=over

=item $command_handler = new OSGi::Osgish::CommandHandler($osgish,$shell)

Create a new command handler object. The arguments to be passed are the osgish
object (C<$osgish>) and the shell object (C<$shell>) in order to update the
shell's current command set.

=cut 

sub new { 
    my $class = shift;
    my $osgish = shift || "No osgish object given";    
    my $shell = shift || "No shell given";
    my $extra = shift;
    $extra = { $extra, @_ } unless ref($extra) eq "HASH";
    my $self = {
                osgish => $osgish,
                shell => $shell,
                %{$extra}
               };
    $self->{stack} = [];
    bless $self,(ref($class) || $class);
    $shell->term->prompt($self->_prompt);
    $self->_register_commands;
    return $self;
}

=item $comand_handler->push_on_stack($context,$cmds)

Update the stack with an entry of name C<$context> which provides the commands
C<$cmds>. C<$cmds> must be a hashref as known to L<Term::ShellUI>, whose
C<commands> method is used to update the shell. Additionally it updates the
shell's prompt to reflect the state of the stack.

=cut 

sub push_on_stack {
    my $self = shift;
    # The new context
    my $context = shift;
    # Sub-commands within the context
    my $sub_cmds = shift;
    my $contexts = $self->{stack};
    push @$contexts,{ name => $context, cmds => $sub_cmds };
    #print Dumper(\@contexts);

    my $shell = $self->{shell};
    # Set sub-commands
    $shell->commands
      ({
        %$sub_cmds,
        %{$self->_global_commands},
        %{$self->_navigation_commands},
       }
      );    
}

=item $command_handler->reset_stack

Reset the stack and install the top and global commands as collected from the
registered L<OSGi::Osgish::Command>.

=cut

sub reset_stack {
    my $self = shift;
    my $shell = $self->{shell};
    $shell->commands({ %{$self->_top_commands}, %{$self->_global_commands}});
    $self->{stack} = [];
}

=item $command = $command_handler->command($command_name) 

Get a registered command by name

=cut 

sub command {
    my $self = shift;
    my $name = shift || die "No command name given";
    return $self->{commands}->{$name};
}

=back

=cut

# ============================================================================

sub _top_commands {
    my $self = shift;
    my $top = $self->{top_commands};
    my @ret = ();
    for my $command (values %$top) {
        push @ret, %{$command->top_commands};        
    }
    return { @ret };
}

sub _global_commands {
    my $self = shift;
    my $globals = $self->{global_commands};
    my @ret = ();
    for my $command (values %$globals) {
        push @ret, %{$command->global_commands};        
    }
    return { @ret };
}


sub _navigation_commands {
    my $self = shift;
    my $shell = $self->{shell};
    my $contexts = $self->{stack};
    if (@$contexts > 0) {
        return 
            {".." => {
                      desc => "Go up one level",
                      proc => 
                      sub { 
                          my $stack = $self->{stack};
                          my $parent = pop @$stack;
                          if (@$stack > 0) {
                              $shell->commands
                                ({
                                  %{$stack->[$#{$stack}]->{cmds}},
                                  %{$self->_global_commands},
                                  %{$self->_navigation_commands},
                                 }
                                );    
                          } else { 
                              $shell->commands({ 
                                                %{$self->_top_commands},
                                                %{$self->_global_commands},
                                               });
                          }
                      }
                     },
             "/" => { 
                     desc => "Go to the top level",
                     proc => 
                     sub { 
                         $self->reset_stack();
                     }
                    }
            };
    } else {
        return {};
    }
}

sub _register_commands { 
    my $self = shift;
    my $osgish = $self->{osgish};

    # TODO: For now a fix list of commands, let them be looked up dynamically
    my @modules = ( "OSGi::Osgish::Command::Bundle",
                    "OSGi::Osgish::Command::Global",
                    "OSGi::Osgish::Command::Server",
                    "OSGi::Osgish::Command::Service",
                    "OSGi::Osgish::Command::Upload",                    
                  );
    my $commands = {};
    my $top = {};
    my $globals = {};
    for my $module (@modules) {
        my $file = $module;
        $file =~ s/::/\//g;
        require $file . ".pm";
        $module->import;
        my $command = eval "$module->new(\$osgish)";
        die "Cannot register $module: ",$@ if $@;
        $commands->{$command->name} = $command;
        my $top_cmd = $command->top_commands;
        if ($top_cmd) {
            $top->{$command->name} = $command;
        }
        my $global_cmd = $command->global_commands;
        if ($global_cmd) {
            $globals->{$command->name} = $command;
        }
    }
    $self->{commands} = $commands;
    $self->{top_commands} = $top;
    $self->{global_commands} = $globals;
    $self->reset_stack;
}


sub _prompt {
    my $self = shift;
    my $osgish = $self->{osgish};
    return sub {
        my $term = shift;
        my $stack = $self->{stack};
        my $osgi = $osgish->agent;
        my ($yellow,$cyan,$red,$reset) = 
          $self->{no_color_prompt} ? ("","","","") : $osgish->color("host","prompt_context","prompt_empty",RESET,{escape => 1});
        my $p = "[";
        $p .= $osgi ? $yellow . $osgish->server : $red . "osgish";
        $p .= $reset;
        $p .= ":" . $cyan if @$stack;
        for my $i (0 .. $#{$stack}) {
            $p .= $stack->[$i]->{name};
            $p .= $i < $#{$stack} ? "/" : $reset;
        }
        $p .= "] : ";
        return $p;
    };
}


=head1 LICENSE

This file is part of osgish.

Osgish is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

osgish is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with osgish.  If not, see <http://www.gnu.org/licenses/>.

A commercial license is available as well. Please contact roland@cpan.org for
further details.

=head1 PROFESSIONAL SERVICES

Just in case you need professional support for this module (or JMX or OSGi in
general), you might want to have a look at www.consol.com Contact
roland.huss@consol.de for further information (or use the contact form at
http://www.consol.com/contact/)

=head1 AUTHOR

roland@cpan.org

=cut

1;



