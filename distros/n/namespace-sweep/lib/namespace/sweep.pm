package namespace::sweep;
{
  $namespace::sweep::VERSION = '0.006';
}

# ABSTRACT: Sweep up imported subs in your classes

use strict;
use warnings;

use Scalar::Util 'blessed', 'reftype';
use List::Util 'first';
use Carp 'croak';
use Data::Dumper;

use Sub::Identify          0.04 'get_code_info';
use B::Hooks::EndOfScope   0.09 'on_scope_end';
use Package::Stash         0.33;

$namespace::sweep::AUTHORITY = 'cpan:FRIEDO';

sub import { 
    my ( $class, %args ) = @_;

    my $cleanee = exists $args{-cleanee} ? $args{-cleanee} : scalar caller;
    my @alsos;

    if ( exists $args{-also} ) { 
        if ( ref $args{-also} && ( reftype $args{-also} eq reftype [ ] ) ) { 
            @alsos = @{ $args{-also} };
        } else { 
            @alsos = ( $args{-also} );
        }
    }
    
    my @also_tests;
    foreach my $also( @alsos ) { 
        my $test = !$also                           ? sub { 0 }
                 : !ref( $also )                    ? sub { $_[0] eq $also }
                 : reftype $also eq reftype sub { } ? sub { local $_ = $_[0]; $also->() }
                 : reftype $also eq reftype qr//    ? sub { $_[0] =~ $also }
                 : croak sprintf q{Don't know what to do with [%s] for -also}, $also;

        push @also_tests, $test;
    }

    my $run_test = sub { 
        return 1 if first { $_->( $_[0] ) } @also_tests;
        return;
    };

    on_scope_end { 
        no strict 'refs';
        my $st = $cleanee . '::';
        my $ps = Package::Stash->new( $cleanee );

        my $sweep = sub { 
            # stolen from namespace::clean
            my @symbols = map {
                my $name = $_ . $_[0];
                my $def = $ps->get_symbol( $name );
                defined($def) ? [$name, $def] : ()
            } '$', '@', '%', '';

            $ps->remove_glob( $_[0] );
            $ps->add_symbol( @$_ ) for @symbols;
        };

        my %keep;
        my $class_of_cm = UNIVERSAL::can('Class::MOP', 'can')  && 'Class::MOP'->can('class_of');
        my $class_of_mu = UNIVERSAL::can('Mouse::Util', 'can') && 'Mouse::Util'->can('class_of');
        if ( $class_of_cm or $class_of_mu ) { 
            # look for moose-ish composed methods
            my ($meta) =
                grep { !!$_ }
                map  { $cleanee->$_ }
                grep { defined $_ }
                ($class_of_cm, $class_of_mu);
            if ( blessed $meta && $meta->can( 'get_all_method_names' ) ) { 
                %keep = map { $_ => 1 } $meta->get_all_method_names;
            }
        }

        foreach my $sym( keys %{ $st } ) { 
            $sweep->( $sym ) and next if $run_test->( $sym );

            next unless exists &{ $st . $sym };
            next if $keep{$sym};

            my ( $pkg, $name ) = get_code_info \&{ $st . $sym };
            next if $pkg eq $cleanee;                       # defined in the cleanee pkg
            next if $pkg eq 'overload' and $name eq 'nil';  # magic overload method

            $sweep->( $sym );
        } 
    };

}

1;

__END__

=pod

=head1 NAME

namespace::sweep - Sweep up imported subs in your classes

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    package Foo;

    use namespace::sweep;
    use Some::Module qw(some_function);

    sub my_method { 
         my $foo = some_function();
         ...
    }

    package main;

    Foo->my_method;      # ok
    Foo->some_function;  # ERROR!

=head1 DESCRIPTION

Because Perl methods are just regular subroutines, it's difficult to tell what's a method
and what's just an imported function. As a result, imported functions can be called as
methods on your objects. This pragma will delete imported functions from your class's
symbol table, thereby ensuring that your interface is as you specified it. However,
code inside your module will still be able to use the imported functions without any 
problems.

=encoding utf-8

=head1 ARGUMENTS

The following arguments may be passed on the C<use> line:

=over

=item -cleanee

If you want to clean a different class than the one importing this pragma, you can 
specify it with this flag. Otherwise, the importing class is assumed.

    package Foo;
    use namespace::sweep -cleanee => 'Bar'   # sweep up Bar.pm

=item -also

This lets you provide a mechanism to specify other subs to sweep up that would not
normally be caught. (For example, private helper subs in your module's class that
should not be called as methods.)

    package Foo;
    use namespace::sweep -also => '_helper';          # sweep up single sub
    use namespace::sweep -also => [qw/foo bar baz/];  # list of subs
    use namespace::sweep -also => qr/^secret_/;       # subs matching regex

You can also specify a subroutine reference which will receive the symbol name as
C<$_>. If the sub returns true, the symbol will be swept.

    # sweep up those rude four-letter subs
    use namespace::sweep -also => sub { return 1 if length $_ == 4 }

You can also combine these methods into an array reference:

    use namespace::sweep -also => [ 'string', sub { 1 if /$pat/ and $_ !~ /$other/ }, qr/^foo_.+/ ];

=back

=head1 RATIONALE 

This pragma was written to address some problems with the excellent L<namespace::autoclean>.
In particular, namespace::autoclean will remove special symbols that are installed by 
L<overload>, so you can't use namespace::autoclean on objects that overload Perl operators.

Additionally, namespace::autoclean relies on L<Class::MOP> to figure out the list of methods
provided by your class. This pragma does not depend on Class::MOP or L<Moose>, so you can
use it for non-Moose classes without worrying about heavy dependencies. 

However, if your class has a Moose (or Moose-compatible) C<meta> object, then that will be
used to find e.g. methods from composed roles that should not be deleted.

In most cases, namespace::sweep should work as a drop-in replacement for namespace::autoclean.
Upon release, this pragma passes all of namespace::autoclean's tests, in addition to its own.

=head1 CAVEATS

This is an early release and there are bound to be a few hiccups along the way.

=head1 ACKNOWLEDGEMENTS 

Thanks Florian Ragwitz and Tomas Doran for writing and maintaining namespace::autoclean. 

Thanks to Toby Inkster for submitting some better code for finding C<meta> objects.

=head1 SEE ALSO

L<namespace::autoclean>, L<namespace::clean>, L<overload>

=head1 AUTHOR

Mike Friedman <friedo@friedo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Mike Friedman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
