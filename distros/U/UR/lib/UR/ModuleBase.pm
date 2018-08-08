# A base class supplying error, warning, status, and debug facilities.

package UR::ModuleBase;

use Sub::Name;
use Sub::Install;

BEGIN {
    use Class::Autouse;
    # the file above now does this, but just in case:
    # subsequent uses of this module w/o the special override should just do nothing...
    $INC{"Class/Autouse_1_99_02.pm"} = 1;
    $INC{"Class/Autouse_1_99_04.pm"} = 1;
    no strict;
    no warnings;
    
    # ensure that modules which inherit from this never fall into the
    # replaced UNIVERSAL::can/isa
    *can = $Class::Autouse::ORIGINAL_CAN;
    *isa = $Class::Autouse::ORIGINAL_ISA;
}

=pod

=head1 NAME

UR::ModuleBase - Methods common to all UR classes and object instances.

=head1 DESCRIPTION

This is a base class for packages, classes, and objects which need to
manage basic functionality in the UR framework such as inheritance, 
AUTOLOAD/AUTOSUB methods, error/status/warning/etc messages.

UR::ModuleBase is in the @ISA list for UR::Object, but UR::ModuleBase is not
a formal UR class.

=head1 METHODS

=cut

# set up package
require 5.006_000;
use warnings;
use strict;
our $VERSION = "0.47"; # UR $VERSION;

# set up module
use Carp;
use IO::Handle;
use UR::Util;

=pod

=over

=item C<class>

  $class = $obj->class;

This returns the class name of a class or an object as a string.
It is exactly equivalent to:

    (ref($self) ? ref($self) : $self)

=cut

sub class
{
    my $class = shift;
    $class = ref($class) if ref($class);
    return $class;
}

=pod 

=item C<super_can>

  $sub_ref = $obj->super_can('func');

This method determines if any of the super classes of the C<$obj>
object can perform the method C<func>.  If any one of them can,
reference to the subroutine that would be called (determined using a
depth-first search of the C<@ISA> array) is returned.  If none of the
super classes provide a method named C<func>, C<undef> is returned.

=cut

sub super_can
{
    my $class = shift;
    
    foreach my $parent_class ( $class->parent_classes )
    {
        my $code = $parent_class->can(@_);
        return $code if $code;
    }
    return;
}

=pod

=item C<inheritance>

  @classes = $obj->inheritance;

This method returns a depth-first list of all the classes (packages)
that the class that C<$obj> was blessed into inherits from.  This
order is the same order as is searched when searching for inherited
methods to execute.  If the class has no super classes, an empty list
is returned.  The C<UNIVERSAL> class is not returned unless explicitly
put into the C<@ISA> array by the class or one of its super classes.

=cut

sub inheritance {
    my $self = $_[0];    
    my $class = ref($self) || $self;
    return unless $class;
    no strict;
    my @parent_classes = @{$class . '::ISA'};

    my @ordered_inheritance;
    foreach my $parent_class (@parent_classes) {
        push @ordered_inheritance, $parent_class, ($parent_class eq 'UR' ? () : inheritance($parent_class) );
    }

    return @ordered_inheritance;
}

=pod

=item C<parent_classes>

  MyClass->parent_classes;

This returns the immediate parent class, or parent classes in the case
of multiple inheritance.  In no case does it follow the inheritance
hierarchy as ->inheritance() does.

=cut

sub parent_classes
{
    my $self = $_[0];
    my $class = ref($self) || $self;
    no strict 'refs';
    my @parent_classes = @{$class . '::ISA'};
    return (wantarray ? @parent_classes : $parent_classes[0]);
}

=pod

=item C<base_dir>

  MyModule->base_dir;

This returns the base directory for a given module, in which the modules's 
supplemental data will be stored, such as config files and glade files,
data caches, etc.

It uses %INC.

=cut

sub base_dir
{
    my $self = shift;
    my $class = ref($self) || $self;    
    $class =~ s/\:\:/\//g;
    my $dir = $INC{$class . '.pm'} || $INC{$class . '.pl'};
    die "Failed to find module $class in \%INC: " . Data::Dumper(%INC) unless ($dir);
    $dir =~ s/\.p[lm]\s*$//;
    return $dir;
}

=pod

=item methods

Undocumented.

=cut

sub methods
{
    my $self = shift;
    my @methods;
    my %methods;
    my ($class, $possible_method, $possible_method_full, $r, $r1, $r2);
    no strict; 
    no warnings;

    for $class (reverse($self, $self->inheritance())) 
    { 
        print "$class\n"; 
        for $possible_method (sort grep { not /^_/ } keys %{$class . "::"}) 
        {
            $possible_method_full = $class . "::" . $possible_method;
            
            $r1 = $class->can($possible_method);
            next unless $r1; # not implemented
            
            $r2 = $class->super_can($possible_method);
            next if $r2 eq $r1; # just inherited
            
            {
                push @methods, $possible_method_full; 
                push @{ $methods{$possible_method} }, $class;
            }
        } 
    }
    print Dumper(\%methods);
    return @methods;
}

=pod

=item C<context_return>

  return MyClass->context_return(@return_values);

Attempts to return either an array or scalar based on the calling context.
Will die if called in scalar context and @return_values has more than 1
element.

=cut

sub context_return {
    my $class = shift;
    return unless defined wantarray;
    return @_ if wantarray;
    if (@_ > 1) {
        my @caller = caller(1);
        Carp::croak("Method $caller[3] on $class called in scalar context, but " . scalar(@_) . " items need to be returned");
    }
    return $_[0];
}

=pod

=back

=head1 C<AUTOLOAD>

This package implements AUTOLOAD so that derived classes can use
AUTOSUB instead of AUTOLOAD.

When a class or object has a method called which is not found in the
final class or any derived classes, perl checks up the tree for
AUTOLOAD.  We implement AUTOLOAD at the top of the tree, and then
check each class in the tree in order for an AUTOSUB method.  Where a
class implements AUTOSUB, it will receive a function name as its first
parameter, and it is expected to return either a subroutine reference,
or undef.  If undef is returned then the inheritance tree search will
continue.  If a subroutine reference is returned it will be executed
immediately with the @_ passed into AUTOLOAD.  Typically, AUTOSUB will
be used to generate a subroutine reference, and will then associate
the subref with the function name to avoid repeated calls to AUTOLOAD
and AUTOSUB.

Why not use AUTOLOAD directly in place of AUTOSUB?

On an object with a complex inheritance tree, AUTOLOAD is only found
once, after which, there is no way to indicate that the given AUTOLOAD
has failed and that the inheritance tree trek should continue for
other AUTOLOADS which might implement the given method.

Example:

    package MyClass;
    our @ISA = ('UR');
    ##- use UR;    
    
    sub AUTOSUB
    {
        my $sub_name = shift;        
        if ($sub_name eq 'foo')
        {
            *MyClass::foo = sub { print "Calling MyClass::foo()\n" };
            return \&MyClass::foo;
        }
        elsif ($sub_name eq 'bar')
        {
            *MyClass::bar = sub { print "Calling MyClass::bar()\n" };
            return \&MyClass::bar;
        }
        else
        { 
            return;
        }
    }

    package MySubClass;
    our @ISA = ('MyClass');
    
    sub AUTOSUB
    {
        my $sub_name = shift;
        if ($sub_name eq 'baz')
        {
            *MyClass::baz = sub { print "Calling MyClass::baz()\n" };
            return \&MyClass::baz;
        }
        else
        { 
            return;
        }
    }

    package main;
    
    my $obj = bless({},'MySubClass');    
    $obj->foo;
    $obj->bar;
    $obj->baz;

=cut

our $AUTOLOAD;
sub AUTOLOAD {
    
    my $self = $_[0];
    
    # The debugger can't see $AUTOLOAD.  This is just here for debugging.
    my $autoload = $AUTOLOAD; 
    
    $autoload =~ /(.*)::([^\:]+)$/;            
    my $package = $1;
    my $function = $2;

    return if $function eq 'DESTROY';

    unless ($package) {
        Carp::confess("Failed to determine package name from autoload string $autoload");
    }

    # switch these to use Class::AutoCAN / CAN?
    no strict;
    no warnings;
    my @classes = grep {$_} ($self, inheritance($self) );
    for my $class (@classes) {
        if (my $AUTOSUB = $class->can("AUTOSUB"))
            # FIXME The above causes hard-to-read error messages if $class isn't really a class or object ref
            # The 2 lines below should fix the problem, but instead make other more impoartant things not work
            #my $AUTOSUB = eval { $class->can('AUTOSUB') };
        #if ($AUTOSUB) {
        {                    
            if (my $subref = $AUTOSUB->($function,@_)) {
                goto $subref;
            }
        }
    }

    if ($autoload and $autoload !~ /::DESTROY$/) {
        my $subref = \&Carp::confess;
        @_ = ("Can't locate object method \"$function\" via package \"$package\" (perhaps you forgot to load \"$package\"?)");
        goto $subref;
    }
}


=pod

=head1 MESSAGING

UR::ModuleBase implements several methods for sending and storing error, warning and
status messages to the user.  

  # common usage

  sub foo {
      my $self = shift;
      ...
      if ($problem) {
          $self->error_message("Something went wrong...");
          return;
      }
      return 1;
  }

  unless ($obj->foo) {
      print LOG $obj->error_message();
  }

=head2 Messaging Methods

=over 4

=item message_types

  @types = UR::ModuleBase->message_types;
  UR::ModuleBase->message_types(@more_types);

With no arguments, this method returns all the types of messages that
this class handles.  With arguments, it adds a new type to the
list.

Standard message types are fatal, error, status, warning, debug and usage.

Note that the addition of new types is not fully supported/implemented
yet.

=back

=cut

my $create_subs_for_message_type;  # filled in lower down
my @message_types = qw(error status warning debug usage fatal);
sub message_types
{
    my $self = shift;
    if (@_)
    {
        foreach my $msg_type ( @_ ) {
            if (! $self->can("${msg_type}_message")) {
                # This is a new one
                $create_subs_for_message_type->($self, $msg_type);
                push @message_types, $msg_type;
            }
        }
    } else {
        return grep { $self->can($_ . '_message') } @message_types;
    }
}


# Most defaults are false
my %default_messaging_settings;
$default_messaging_settings{dump_error_messages} = 1;
$default_messaging_settings{dump_warning_messages} = 1;
$default_messaging_settings{dump_status_messages} = 1;
$default_messaging_settings{dump_fatal_messages} = 1;

#
# Implement error_mesage/warning_message/status_message in a way
# which handles object-specific callbacks.
#
# Build a set of methods for getting/setting/printing error/warning/status messages
# $class->dump_error_messages(<bool>) Turn on/off printing the messages to STDERR
#     error and warnings default to on, status messages default to off
# $class->queue_error_messages(<bool>) Turn on/off queueing of messages
#     defaults to off
# $class->error_message("blah"): set an error message
# $class->error_message() return the last message
# $class->error_messages()  return all the messages that have been queued up
# $class->error_messages_arrayref()  return the reference to the underlying
#     list messages get queued to.  This is the method for truncating the list
#     or altering already queued messages
# $class->error_messages_callback(<subref>)  Specify a callback for when error
#     messages are set.  The callback runs before printing or queueing, so
#     you can alter @_ and change the message that gets printed or queued
# And then the same thing for status and warning messages

=pod

For each message type, several methods are created for sending and retrieving messages,
registering a callback to run when messages are sent, controlling whether the messages
are printed on the terminal, and whether the messages are queued up.

For example, for the "error" message type, these methods are created:

=over 4

=item error_message

    $obj->error_message("Something went wrong...");
    $obj->error_message($format, @list);
    $msg = $obj->error_message();

When called with one or more arguments, it sends an error message to the
object.  The error_message_callback will be run, if one is registered, and the
message will be printed to the terminal.  When given a single argument, it will
be passed through unmodified.  When given multiple arguments, error_message will
assume the first is a format string and the remainder are parameters to
sprintf.  When called with no arguments, the last message sent will be
returned.  If the message is C<undef> then no message is printed or queued, and
the next time error_message is run as an accessor, it will return
undef.

Note that C<fatal_message()> will throw an exception at the point it appears
in the program.  This exception, like others, is trappable bi C<eval>.

=item dump_error_messages

    $obj->dump_error_messages(0);
    $flag = $obj->dump_error_messages();

Get or set the flag which controls whether messages sent via C<error_message()>
is printed to the terminal.  This flag defaults to true for warning and error
messages, and false for others.

Note that C<fatal_message()> messages and exceptions do not honor the value of
C<dump_fatal_messages()>, and always print their message and throw their
exception unless trapped with an C<eval>.

=item queue_error_messages

    $obj->queue_error_messages(0);
    $flag = $obj->queue_error_messages();

Get or set the flag which control whether messages send via C<error_message()>
are saved into a list.  If true, every message sent is saved and can be retrieved
with L<error_messages()> or L<error_messages_arrayref()>.  This flag defaults to
false for all message types.

=item error_messages_callback

    $obj->error_messages_callback($subref);
    $subref = $obj->error_messages_callback();

Get or set the callback run whenever an error_message is sent.  This callback
is run with two arguments: The object or class error_message() was called on,
and a string containing the message.  This callback is run before the message
is printed to the terminal or queued into its list.  The callback can modify
the message (by writing to $_[1]) and affect the message that is printed or
queued.  If $_[1] is set to C<undef>, then no message is printed or queued,
and the last recorded message is set to undef as when calling error_message
with undef as the argument.

=item error_messages

    @list = $obj->error_messages();

If the queue_error_messages flag is on, then this method returns the entire list
of queued messages.

When called as an instance method, it returns the errors queued only on that
object.  When called as a class method, it returns the errors queued on that
class, all it's subclasses, and all instances of that class or subclasses.

=item error_messages_arrayref

    $listref = $obj->error_messages_arrayref();

If the queue_error_messages flag is on, then this method returns a reference to
the actual list where messages get queued.  This list can be manipulated to add
or remove items.

=item error_message_source

    %source_info = $obj->error_message_source

Returns a hash of information about the most recent call to error_message.
The key "error_message" contains the message.  The keys error_package,
error_file, error_line and error_subroutine contain info about the location
in the code where error_message() was called.

=item error_package

=item error_file

=item error_line

=item error_subroutine

These methods return the same data as $obj->error_message_source().

=back

=cut

our $stderr = \*STDERR;
our $stdout = \*STDOUT;
my %message_settings;

# This sub creates the settings mutator subs for each message type
# For example, when passed in 'error', it creates the subs error_messages_callback,
# queue_error_messages, dump_error_messages, etc
$create_subs_for_message_type = sub {
    my($self, $type) = @_;

    my $class = ref($self) ? $self->class : $self;

    my $save_setting = sub {
        my($self, $name, $val) = @_;
        if (ref $self) {
            $message_settings{ $self->class . '::' . $name . '_by_id' }->{$self->id} = $val;
        } else {
            $message_settings{ $self->class . '::' . $name } = $val;
        }
    };
    my $get_setting = sub {
        my($self, $name) = @_;
        if (ref $self) {
            return exists($message_settings{ $self->class . '::' . $name . '_by_id' })
                    ? $message_settings{ $self->class . '::' . $name . '_by_id' }->{$self->id}
                    : undef;
        } else {
            return $message_settings{ $self->class . '::' . $name };
        }
    };

    my $make_mutator = sub {
        my $name = shift;
        return sub {
            my $self = shift;

            if (@_) {
                # setting the value
                $save_setting->($self, $name, @_);

            } else {
                # getting the value
                my $val = $get_setting->($self, $name);
                if (defined $val) {
                    return $val;

                } elsif (ref $self) {
                    # called on an object and no value set, try the class
                    return $self->class->$name();

                } else {
                    # called on a class name
                    my @super = $self->inheritance();
                    foreach my $super ( @super ) {
                        if (my $super_sub = $super->can($name)) {
                            return $super_sub->($super);
                        }
                    }
                    # None of the parent classes implement it, or there aren't
                    # any parent classes
                    return $default_messaging_settings{$name};
                }
            }
        };
    };

    foreach my $base ( qw( %s_messages_callback queue_%s_messages %s_package
                            %s_file %s_line %s_subroutine )
    ) {
        my $method = sprintf($base, $type);
        my $full_name = $class . '::' . $method;

        my $method_subref = Sub::Name::subname $full_name => $make_mutator->($method);
        Sub::Install::install_sub({
            code => $method_subref,
            into => $class,
            as => $method,
        });
    }

    my $should_dump_messages = "dump_${type}_messages";
    my $dump_mutator = $make_mutator->($should_dump_messages);
    my @dump_env_vars = map { $_ . uc($should_dump_messages) } ('UR_', 'UR_COMMAND_');
    my $should_dump_messages_subref = Sub::Name::subname $class . '::' . $should_dump_messages => sub {
        my $self = shift;
        if (@_) {
            return $dump_mutator->($self, @_);
        }
        foreach my $varname ( @dump_env_vars ) {
            return $ENV{$varname} if (defined $ENV{$varname});
        }
        return $dump_mutator->($self);
    };
    Sub::Install::install_sub({
        code => $should_dump_messages_subref,
        into => $class,
        as => $should_dump_messages,
    });


    my $messages_arrayref = "${type}_messages_arrayref";
    my $message_arrayref_sub = Sub::Name::subname "${class}::${messages_arrayref}" => sub {
        my $self = shift;
        my $a = $get_setting->($self, $messages_arrayref);
        if (! defined $a) {
            $save_setting->($self, $messages_arrayref, $a = []);
        }
        return $a;
    };
    Sub::Install::install_sub({
        code => $message_arrayref_sub,
        into => $class,
        as => $messages_arrayref,
    });

    my $array_subname = "${type}_messages";
    my $array_subref = Sub::Name::subname "${class}::${array_subname}" => sub {
        my $self = shift;
        my @search = ref($self)
                        ? $self
                        : ( $self, $self->__meta__->subclasses_loaded, $self->is_loaded() );
        my %seen;
        my @all_messages;
        foreach my $thing ( @search ) {
            next if $seen{$thing}++;
            my $a = $get_setting->($thing, $messages_arrayref);
            push @all_messages, $a ? @$a : ();
        }
        return @all_messages;
    };
    Sub::Install::install_sub({
        code => $array_subref,
        into => $class,
        as => $array_subname,
    });


    my $messageinfo_subname = "${type}_message_source";
    my @messageinfo_keys = map { $type . $_ } qw( _message _package _file _line _subroutine );
    my $messageinfo_subref = Sub::Name::subname "${class}::${messageinfo_subname}" => sub {
        my $self = shift;
        return map { $_ => $self->$_ } @messageinfo_keys;
    };
    Sub::Install::install_sub({
        code => $messageinfo_subref,
        into => $class,
        as => $messageinfo_subname,
    });

    # usage messages go to STDOUT, others to STDERR
    my $default_fh = $type eq 'usage' ? \$stdout : \$stderr;

    my $should_queue_messages = "queue_${type}_messages";
    my $check_callback = "${type}_messages_callback";
    my $message_text_prefix = ($type eq 'status' or $type eq 'usage') ? '' : uc($type) . ': ';
    my $message_package     = "${type}_package";
    my $message_file        = "${type}_file";
    my $message_line        = "${type}_line";
    my $message_subroutine  = "${type}_subroutine";

    my $messaging_action = $type eq 'fatal'
                            ? sub { Carp::croak($message_text_prefix . $_[1]) }
                            : sub {
                                my($self, $msg) = @_;
                                if (my $fh = $self->$should_dump_messages()) {
                                    $fh = $$default_fh unless (ref $fh);

                                    $fh->print($message_text_prefix . $msg . "\n");
                                }
                            };

    my $logger_subname = "${type}_message";
    my $logger_subref = Sub::Name::subname "${class}::${logger_subname}" => sub {
        my $self = shift;

        if (@_) {
            my $msg = shift;

            # if given multiple arguments, assume it's a format string
            if(@_) {
                $msg = _carp_sprintf($msg, @_);
            }

            defined($msg) && chomp($msg);

            # old-style callback registered with error_messages_callback
            if (my $code = $self->$check_callback()) {
                if (ref $code) {
                    $code->($self, $msg);
                } else {
                    $self->$code($msg);
                }
            }

            # New-style callback registered as an observer
            # Some non-UR classes inherit from UR::ModuleBase, and can't __signal
            if ($UR::initialized && $self->can('__signal_observers__')) {
                $self->__signal_observers__($logger_subname, $msg);
            }

            $save_setting->($self, $logger_subname, $msg);
            # If the callback set $msg to undef with "$_[1] = undef", then they didn't want the message
            # processed further
            if (defined $msg) {
                if ($self->$should_queue_messages()) {
                    my $a = $self->$messages_arrayref();
                    push @$a, $msg;
                }

                my ($package, $file, $line, $subroutine) = caller;
                $self->$message_package($package);
                $self->$message_file($file);
                $self->$message_line($line);
                $self->$message_subroutine($subroutine);

                $self->$messaging_action($msg);

            }
        }

        return $get_setting->($self, $logger_subname);
    };
    Sub::Install::install_sub({
        code => $logger_subref,
        into => $class,
        as => $logger_subname,
    });

    # "Register" the message type as a valid signal.
    $UR::Object::Type::STANDARD_VALID_SIGNALS{$logger_subname} = 1;
};

sub _carp_sprintf {
    my $format = shift;
    my @list = @_;

    # warnings weren't very helpful because they wouldn't tell you who passed
    # in the "bad" format string
    my $formatted_string;
    my $warn_msg;
    {
        local $SIG{__WARN__} = sub {
            my $msg = $_[0];
            my ($filename, $line) = (caller)[1, 2];
            my $short_msg = ($msg =~ /(.*) at \Q$filename\E line $line./)[0];
            $warn_msg = ($short_msg || $msg);
        };
        $formatted_string = sprintf($format, @list);
    }
    if ($warn_msg) {
        Carp::carp($warn_msg);
    }

    return $formatted_string;
}


# at init time, make messaging subs for the initial message types
$create_subs_for_message_type->(__PACKAGE__, $_) foreach @message_types;


sub _current_call_stack
{
    my @stack = reverse split /\n/, Carp::longmess("\t");

    # Get rid of the final line from carp, showing the line number
    # above from which we called it.
    pop @stack;

    # Get rid any other function calls which are inside of this
    # package besides the first one.  This allows wrappers to
    # get_message to look at just the external call stack.
    # (i.e. AUTOSUB above, set_message/get_message which called this,
    # and AUTOLOAD in UniversalParent)
    pop(@stack) while ($stack[-1] =~ /^\s*(UR::ModuleBase|UR)::/ && $stack[-2] && $stack[-2] =~ /^\s*(UR::ModuleBase|UR)::/);

    return \@stack;
}


1;
__END__

=pod

=head1 SEE ALSO

UR(3)

=cut

# $Header$
