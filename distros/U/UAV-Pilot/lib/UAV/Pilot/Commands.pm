# Copyright (c) 2015  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package UAV::Pilot::Commands;
$UAV::Pilot::Commands::VERSION = '1.3';
use v5.14;
use Moose;
use namespace::autoclean;
use File::Spec;

use constant MOD_PREFIX => 'UAV::Pilot';
use constant MOD_SUFFIX => 'Commands';


has 'lib_dirs' => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    traits  => [ 'Array' ],
    default => sub {[]},
    handles => {
        add_lib_dir => 'push',
    },
);
has 'condvar' => (
    is  => 'ro',
    isa => 'AnyEvent::CondVar',
);
has 'controller_callback_ardrone' => (
    is  => 'ro',
    isa => 'CodeRef',
);
has 'controller_callback_wumpusrover' => (
    is  => 'ro',
    isa => 'CodeRef',
);
has 'quit_subs' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[CodeRef]',
    default => sub {[]},
    handles => {
        '_push_quit_sub' => 'push',
    },
);

our $s;

#
# Sole command that can run without loading other libraries
#
sub load ($;$)
{
    my ($mod_name, $args) = @_;
    $$args{condvar} = $s->condvar unless exists $$args{condvar};
    $s->load_lib( $mod_name, $args );
}


sub run_cmd
{
    my ($self, $cmd) = @_;
    if( (! defined $self) && (! ref($self)) ) {
        # Must be called with a $self, not directly via package
        return 0;
    }
    return 1 unless defined $cmd;

    $s = $self;
    eval $cmd;
    die $@ if $@;

    return 1;
}

sub quit
{
    my ($self) = @_;
    $_->() for @{ $self->{quit_subs} };
    return 1;
}


sub load_lib
{
    my ($self, $mod_name, $args) = @_;
    my $dest_namespace = delete $args->{namespace} // 'UAV::Pilot::Commands';
    
    # This works via the hooks placed into @INC array, which is documented 
    # in perlfunc under the require() entry.  In short, we can stick a 
    # subref in @INC and mess around with how Perl loads up the module.  
    # By choosing the starting text, we can control the exact namespace 
    # where the module will end up.

    my @orig_inc = @INC;
    local @INC = (
        $self->_get_load_module_sub( $dest_namespace, \@orig_inc ),
        @INC,
    );

    my $full_mod_name = $self->MOD_PREFIX
            . '::' . $mod_name
            . '::' . $self->MOD_SUFFIX;

    eval "require $full_mod_name";
    die "Could not load $mod_name: $@" if $@;

    if( my $call = $dest_namespace->can( 'uav_module_init' ) ) {
        $call->( $dest_namespace, $self, $args );

        # Clear uav_module_init.  Would prefer a solution without
        # eval( STRING ), though a symbol table manipulation method may be 
        # considered just as evil.
        my $del_str = 'delete $' . $dest_namespace . '::{uav_module_init}';
        eval $del_str;
    }

    if( my $quit_call = $dest_namespace->can( 'uav_module_quit' ) ) {
        $self->_push_quit_sub( $quit_call );
    }

    # If we want to reload the module, we need to delete its entry from the 
    # %INC cache
    my @mod_name_components = split /::/, $full_mod_name;
    my $mod_name_path = File::Spec->catfile( @mod_name_components ) . '.pm';
    delete $INC{$mod_name_path};

    return 1;
}

sub _get_load_module_sub
{
    my ($self, $dest_namespace, $inc) = @_;
    my $init_source = "package $dest_namespace;";

    my $sub = sub {
        my ($this_sub, $file) = @_;

        my @return;
        foreach (@$inc) {
            my $full_path = File::Spec->catfile( $_, $file );
            if( -e $full_path ) {
                open( my $in, '<', $full_path )
                    or die "Can't open '$full_path': $!\n";

                @return = (
                    \$init_source,
                    $in,
                );
                last;
            }
        }

        return @return;
    };

    return $sub;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::Commands

=head1 SYNOPSIS

    my $device; # Some UAV::Pilot::Control instance, defined elsewhere
    my $cmds = UAV::Pilot::Commands->new({
        device => $device,
        controller_callback_ardrone     => \&make_ardrone_controller,
        controller_callback_wumpusrover => \&make_wumpusrover_controller,
    });
    
    $cmds->load_lib( 'ARDrone' );
    $cmds->run_cmd( 'takeoff;' );
    $cmds->run_cmd( 'land;' );

=head1 DESCRIPTION

Provides an interface for loading UAV extensions and running them, particularly for 
REPL shells.

=head1 METHODS

=head2 new

    new({
        condvar                         => $cv,
        controller_callback_ardrone     => sub { ... },
        controller_callback_wumpusrover => sub { .. },
    })

Constructor.  The C<condvar> parameter is an C<AnyEvent::Condvar>.

The C<controller_callback_*> parameters take a sub ref.  The subroutines take 
a the parameters C<($cmd, $cv, $easy_event)>, where C<$cmd> is this 
C<UAV::Pilot::Commands> instance, C<$cv> is the condvar passed above, and 
C<$easy_event> is an C<UAV::Pilot::EasyEvent> instance.  It should return a 
C<UAV::Pilot::Control> object of the associated type (generally one of the 
C<*::Event> types with C<init_event_loop()> called).

Note that this API is likely to change to a factory pattern in the near future.

=head2 load_lib

    load_lib( 'ARDrone', {
        pack => 'AR',
    })

Loads an extension by name.  The C<pack> paramter will load the library into a specific 
namespace.  If you don't specify it, you won't need to qualify commands with a namespace 
prefix.  Example:

    load_lib( 'ARDrone', { pack => 'AR' } );
    run_cmd( 'takeoff;' );     # Error: no subroutine named 'takeoff'
    run_cmd( 'AR::takeoff;' ); # This works
    
    load_lib( 'ARDrone' );
    run_cmd( 'takeoff;' );     # Now this works, too

Any other parmaeters you pass will be passed to the module's C<uav_module_init()> 
subroutine.

=head2 run_cmd

    run_cmd( 'takeoff;' )

Executes a command.  Note that this will execute arbitrary Perl statements.

=head1 COMMANDS

Commands provide an easy interface for writing simple UAV programms in a REPL shell.  
They are usually thin interfaces over a L<UAV::Pilot::Control>.  If you're writing a 
complicated script, it's suggested that you skip this interface and write to the 
L<UAV::Pilot::Control> directly.

=head2 load

    load 'ARDrone', {
        namespace => 'AR',
    };

Direct call to C<load_lib>.  The C<namespace> paramter will load the library 
into a specific namespace.  If you don't specify it, you won't need to qualify 
commands with a namespace prefix.  Example:

    load 'ARDrone', { namespace => 'AR' };
    takeoff;     # Error: no subroutine named 'takeoff'
    AR::takeoff; # This works
    
    load ARDrone;
    takeoff;     # Now this works, too

Any other parmaeters you pass will be passed to the module's 
C<uav_module_init()> subroutine.

=head1 WRITING YOUR OWN EXTENSIONS

When calling C<load_lib( 'Foo' )>, we look for C<UAV::Pilot::Foo::Commands> 
in the current C<@INC>.

You write them much like any Perl module, but don't use a C<package> 
statement--the package will be controlled by C<UAV::Pilot::Command> when 
loaded.  Like a Perl module, it should return true as its final statement 
(put a C<1;> at the end).

Likewise, be careful not to make any assumptions about what package you're in. 
Modules may or may not get loaded into different, arbitrary packages.

For ease of use, it's recommended to use function prototypes to reduce the need
for parens.

The method C<uav_module_init()> is called with the package name as the first 
argument.  Subsquent arguments will be the hashref passed to 
C<load()/load_lib()>.  After being called, this sub will be deleted from the 
package.

The method C<uav_module_quit()> is called when the REPL is closing.
