package Win32::MMF::Shareable;

require 5.00503;
use strict;
use warnings;
use Carp;
use Win32::MMF;

require Exporter;
require DynaLoader;

our @ISA = qw/ Exporter /;
our $VERSION = '0.05';

# ------------------- Tied Interface -------------------

our $ns;

sub import {
    my $class = shift;
    if (@_ && !$ns) {
        $ns = Win32::MMF->new(@_) or croak "No shared mem!";
        $ns->{_autolock} = 0;
    }
}

my $default_settings = {
    _key => undef,      # only the key is used
    _type => undef,     # set data type
    _swapfile => undef, # use system pagefile
    _namespace => 'shareable',
    _size => 128 * 1024,    # 128k default size
    _iterating => '',
};

sub init_with_default_settings {
    if (!$ns) {
        $ns = Win32::MMF->new ( -namespace => $default_settings->{_namespace},
                                -size => $default_settings->{_size},
                                -swapfile => $default_settings->{_swapfile} )
                or croak "No shared mem!";
        $ns->{_autolock} = 0;
    }
}

sub namespace {
    return $ns;
}

sub lock {
    $ns->lock();
}

sub unlock {
    $ns->unlock();
}

sub shlock {
    $ns->lock();
}

sub shunlock {
    $ns->unlock();
}

sub debug {
    $ns && $ns->debug();
}

sub TIESCALAR {
    return _tie(S => @_);
}

sub TIEARRAY {
    return _tie(A => @_);
}

sub TIEHASH {
    return _tie(H => @_);
}

sub CLEAR {
    my $self = shift;
    $self->lock();
    $ns->setvar($self->{_key}, '');
    if ($self->{_type} eq 'A') {
        $self->{_data} = [];
    } elsif ($self->{_type} eq 'H') {
        $self->{_data} = {};
    } else {
        croak "Attempt to clear non-aggegrate";
    }
    $self->unlock();
}

sub EXTEND { }

sub STORE {
    my $self = shift;
    $self->lock();
    $self->{_data} = $ns->getvar($self->{_key});

TYPE: {
        if ($self->{_type} eq 'S') {
            $self->{_data} = shift;
            last TYPE;
        }
        if ($self->{_type} eq 'A') {
            my $i   = shift;
            my $val = shift;
            $self->{_data}->[$i] = $val;
            last TYPE;
        }
        if ($self->{_type} eq 'H') {
            my $key = shift;
            my $val = shift;
            $self->{_data}->{$key} = $val;
            last TYPE;
        }
        croak "Variables of type $self->{_type} not supported";
    }

    $ns->setvar($self->{_key}, $self->{_data}) or
        croak("Out of memory!");

    $self->unlock();

    return 1;
}

sub FETCH {
    my $self = shift;

    $self->lock();

    if ($self->{_iterating}) {
        $self->{_iterating} = ''
    } else {
        $self->{_data} = $ns->getvar($self->{_key});
    }

    my $val;
TYPE: {
        if ($self->{_type} eq 'S') {
            if (defined $self->{_data}) {
                $val = $self->{_data};
                last TYPE;
            } else {
                $self->unlock();
                return;
            }
        }
        if ($self->{_type} eq 'A') {
            if (defined $self->{_data}) {
                my $i = shift;
                $val = $self->{_data}->[$i];
                last TYPE;
            } else {
                $self->unlock();
                return;
            }
        }
        if ($self->{_type} eq 'H') {
            if (defined $self->{_data}) {
                my $key = shift;
                $val = $self->{_data}->{$key};
                last TYPE;
            } else {
                $self->unlock();
                return;
            }
        }
        croak "Variables of type $self->{_type} not supported";
    }

    $self->unlock();

    return $val;
}

# ------------------------------------------------------------------------------

sub DELETE {
    my $self = shift;
    my $key  = shift;

    $self->lock();

    $self->{_data} = $ns->getvar($self->{_key}) || {};
    my $val = delete $self->{_data}->{$key};
    $ns->setvar($self->{_key}, $self->{_data});

    $self->unlock();

    return $val;
}

sub EXISTS {
    my $self = shift;
    my $key  = shift;

    $self->lock();
    $self->{_data} = $ns->getvar($self->{_key}) || {};
    $self->unlock();

    return exists $self->{_data}->{$key};
}

sub FIRSTKEY {
    my $self = shift;
    my $key  = shift;

    $self->{_iterating} = 1;

    $self->lock();
    $self->{_data} = $ns->getvar($self->{_key}) || {};

    my $reset = keys %{$self->{_data}}; # reset
    my $first = each %{$self->{_data}};

    $self->unlock();

    return $first;
}

sub NEXTKEY {
    my $self = shift;

    # caveat emptor if hash was changed by another process
    my $next = each %{$self->{_data}};

    if (not defined $next) {
        $self->{_iterating} = '';
        return undef;
    } else {
        $self->{_iterating} = 1;
        return $next;
    }
}

sub FETCHSIZE {
    my $self = shift;

    $self->lock();
    $self->{_data} = $ns->getvar($self->{_key}) || [];
    $self->unlock();

    return scalar(@{$self->{_data}});
}

sub STORESIZE {
    my $self = shift;
    my $n    = shift;

    $self->lock();
    $self->{_data} = $ns->getvar($self->{_key}) || [];
    $#{@{$self->{_data}}} = $n - 1;
    $ns->setvar($self->{_key}, $self->{_data});
    $self->unlock();

    return $n;
}

sub SHIFT {
    my $self = shift;

    $self->lock();
    $self->{_data} = $ns->getvar($self->{_key}) || [];
    my $val = shift @{$self->{_data}};
    $ns->setvar($self->{_key}, $self->{_data});
    $self->unlock();

    return $val;
}

sub UNSHIFT {
    my $self = shift;

    $self->lock();
    $self->{_data} = $ns->getvar($self->{_key}) || [];
    my $val = unshift @{$self->{_data}} => @_;
    $ns->setvar($self->{_key}, $self->{_data});
    $self->unlock();

    return $val;
}

sub SPLICE {
    my($self, $off, $n, @av) = @_;

    $self->lock();
    $self->{_data} = $ns->getvar($self->{_key}) || [];
    my @val = splice @{$self->{_data}}, $off, $n => @av;
    $ns->setvar($self->{_key}, $self->{_data});
    $self->unlock();

    return @val;
}

sub PUSH {
    my $self = shift;

    $self->lock();

    $self->{_data} = $ns->getvar($self->{_key});

    if (!defined $self->{_data}) {
        $self->{_data} = [];
    }
    push @{$self->{_data}}, @_;

    $ns->setvar($self->{_key}, $self->{_data}) or
        croak "Not enough shared memory";

    $self->unlock();
}

sub POP {
    my $self = shift;

    $self->lock();
    $self->{_data} = $ns->getvar($self->{_key}) || [];
    my $val = pop @{$self->{_data}};
    $ns->setvar($self->{_key}, $self->{_data});
    $self->unlock();

    return $val;
}

sub UNTIE {
    my $self = shift;
}


# ------------------------------------------------------------------------------

sub _tie {
    my $type  = shift;
    my $class = shift;

    my $self = { %$default_settings };
    $self->{_type} = $type;

    # allowed parameters are aliases to IPC::Shareable
    my $allowed_parameters = "key";

    if (ref $_[0] eq 'HASH') {
        # Parameters passed in as HASHREF
        for my $p (keys %{$_[0]}) {
            $self->{'_' . lc $p} = $_[0]->{$p};
        }
    } elsif ($_[0] =~ /^-(?=$allowed_parameters)/i) {
        # Parameters passed in as named parameters
        my %p = @_;
        for my $p (keys %p) {
            $self->{'_' . lc substr($p,1)} = $p{$p};
        }
    } else {
        # Parameters passed in as: tie $variable, 'Win32::MMF::Shareable', 'data', \%options
        $self->{_key} = shift;
        # Parameters passed in as HASHREF
        for my $p (keys %{$_[1]}) {
            $self->{'_' . lc $p} = $_[0]->{$p};
        }
    }

    croak "The label/key for the tied variable must be defined!" if !$self->{_key};

    # retrieve the namespace parameters
    $default_settings->{_namespace} = $self->{_namespace};
    $default_settings->{_size} = $self->{_size};
    $default_settings->{_swapfile} = $self->{_swapfile};

    init_with_default_settings() if ! $ns;

    bless $self, $class;
}

1;

=pod

=head1 NAME

 Win32::MMF::Shareable - tied variable interface to MMF

=head1 SYNOPSIS

  use Win32::MMF::Shareable;

  my $ns = tie my $s1, "Win32::MMF::Shareable", "varid";
  tie my @a1, "Win32::MMF::Shareable", "array";
  $s1 = 'Hello world';
  @a1 = ( A => 1, B => 2, C => 3 );

  tie my $s2, "Win32::MMF::Shareable", "varid";
  tie my @a1, "Win32::MMF::Shareable", "array";
  print "$s2\n";
  print "@a1\n";


=head1 ABSTRACT

This module provides a tied variable interface to the
Win32::MMF module. It is part of the Win32::MMF package.

The current version 0.09 of Win32::MMF is available on CPAN at:

  http://search.cpan.org/search?query=Win32::MMF


=head1 DESCRIPTION

The Win32::MMF::Shareable module is modelled after C<IPC::Shareable>.
All options from C<IPC::Shareable> can be used in Win32::MMF::Shareable,
although they are mostly ignored except for the 'label' argument.
Because memory and variable management are managed internally by the
Win32::MMF module, you do not need to specify how much memory is
required by the variable.

All access to tied variables are automatically and exclusively locked
to preserve data integrity across multiple processes.

Win32::MMF::Shareable mimics the operation of C<IPC::Shareable>,
it allows you to tie a variable to a namespace (shared memory)
making it easy to share its content with other Perl processes.

Note that if you try to tie a variable without specifying the
namespace, the default namespace 'shareable' will be used. If you
want to change how the default namespace is created, provide the
namespace, swapfile and size options when you tie the first variable.

 use Win32::MMF::Shareable;
 tie $scalar, "Win32::MMF::Shareable", "var_1",
              { namespace = 'MyNamespace', size = 1024 * 1024,
                swapfile = 'C:\private.swp' };

The options are exactly the same as the Win32::MMF constructor options.
For compatibility with IPC::Shareable, you can pass in IPC::Shareable
options, although they mostly get ignored, except for the 'key' option.

An alternative is to provide these options when the Win32::MMF::Shareable
module is imported:

 use Win32::MMF::Shareable { namespace = 'MyNamespace',
                             size = 1024 * 1024,
                             swapfile = 'C:\private.swp' };
 tie $scalar,"Win32::MMF::Shareable", "var_1";

Currently only scalars, arrays, and hashes can be tied, I am investigating
on the possibilities with tied file handles at the moment.

To tie a variable to the default namespace:

 tie $scalar, "Win32::MMF::Shareable", "var_1";
 tie @array,  "Win32::MMF::Shareable", "var_2";
 tie %hash,   "Win32::MMF::Shareable", "var_3";

And to use a tied variable:

 $scalar = 'Hello Perl';

 @array = qw/ A B C D E F G /;

 %hash = @array;


=head1 REFERENCE

=head2 Initialization

There are two ways to initialize an MMF namespace to be
used in tied mode.

 # Method 1 - when importing the module
 use Win32::MMF::Shareable { namespace = 'MyNamespace',
                             size = 1024 * 1024,
                             swapfile = 'C:\private.swp' };

 # Method 2 - initialization upon first use
 use Win32::MMF::Shareable;
 tie $scalar, "Win32::MMF::Shareable", "var_1",
              { namespace = 'MyNamespace', size = 1024 * 1024,
                swapfile = 'C:\private.swp' };

The options are exactly the same as those for the Win32::MMF
constructor, although you can pass in IPC::Shareable options
as well, making it easy to port IPC::Shareable

=head2 Locking

All read and write accesses to a tied variable are locked
by default. Additional level of locking can be performed to
protect critical part of the code.

 my $ns = tie $scalar, "Win32::MMF::Shareable", "var_1";
 ...

 $ns->lock();
 $scalar = 'some string';
 $ns->unlock();

=head2 Debugging

There is a built-in method B<debug> that will display as
much information as possible for a given tied object.

 my $ns = tie $scalar, "Win32::MMF::Shareable", "var_1";
 ...

 $ns->debug();

=head2 Limitations

Currently only scalar, list and hash can be tied and modified
correctly. You can tie a scalar reference too, but the
elements that the scalar reference is pointing to can not
be modified by a direct assignment. The way to get around
it is to make a local copy of the tied reference, modify the
local copy, and then assign the modified local copy back to
the reference.

 tie $ref, "Win32::MMF::Shareable", "var_1";
 $ref = [ 'A', 'B', 'C' ];

 push @$ref, 'D';       # this does not work

 @list = @$ref;
 push @list, 'D';
 $ref = \@list;         # this works


=head1 SEE ALSO

C<Win32::MMF>

=head1 CREDITS

Credits go to my wife Jenny and son Albert, and I love them forever.

=back


=head1 AUTHOR

Roger Lee <roger@cpan.org>

=back


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 Roger Lee

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

