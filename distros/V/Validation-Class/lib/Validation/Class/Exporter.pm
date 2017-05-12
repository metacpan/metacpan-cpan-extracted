# ABSTRACT: Simple Exporter for Validation::Class Classes

package Validation::Class::Exporter;

use 5.008001;

use strict;
use warnings;

our $VERSION = '7.900057'; # VERSION


sub apply_spec {

    my ($this, %args) = @_;

    no strict 'refs';
    no warnings 'once';
    no warnings 'redefine';

    my $parent = caller(0);

    my @keywords = @{$args{keywords}}   if $args{keywords};
    my @routines = @{$args{routines}}   if $args{routines};
    my $settings = {@{$args{settings}}} if $args{settings};

    *{"$parent\::import"} = sub {

        my $child = caller(0);

        *{"$child\::$_"} = *{"$parent\::$_"} for @{$args{keywords}};

        *{"$child\::$_"} = *{"$parent\::$_"} for @{$args{routines}};

        my $ISA = "$child\::ISA";

        push @$ISA, 'Validation::Class'
          unless grep { $_ eq 'Validation::Class' } @$ISA;

        *{"$child\::$_"} = *{"Validation\::Class\::$_"}
          for @Validation::Class::EXPORT;

        strict->import;
        warnings->import;

        $child->load({@{$args{settings}}}) if $args{settings};

        return $child;

    };

    return $this;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Exporter - Simple Exporter for Validation::Class Classes

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    package MyApp::Validator;

    use Validation::Class;
    use Validation::Class::Exporter;

    my @settings = (
        classes => [
            MyApp::Validator::DomainAlpha
            MyApp::Validator::DomainBeta
        ]
    );

    Validation::Class::Exporter->apply_spec(
        routines => ['thing'], # export additional routines as is
        settings => [@settings] # passed to the `load` keyword in V::C
    );

    sub thing {

        my $args = pop;

        my $class = shift || caller;

        # routine as a keyword

        # ... do some thing

    };

... in your application class:

    package MyApp;

    use MyApp::Validator;

    thing ['a', 'b'];

... in your application:

    package main;

    my $app = MyApp->new;

=head1 DESCRIPTION

This module (while experimental) encapsulates the exporting of keywords and
routines. It applies the L<Validation::Class> framework along with any keyword
routines and/or sub-routines specified with the apply_spec() method. It does
this by simply by copying the spec into the calling class.

To simplify writing exporter modules, C<Validation::Class::Exporter> also
imports C<strict> and C<warnings> into your exporter module, as well as into
modules that use it.

=head1 METHODS

=head2 apply_spec

When you call this method, C<Validation::Class::Exporter> builds a custom
C<import> method on the calling class. The C<import> method will export the
functions you specify, and can also automatically export C<Validation::Class>
making the calling class a Validation::Class derived class.

This method accepts the following parameters:

=over 8

=item * routines => [ ... ]

This list of function I<names only> will be exported into the calling class
exactly as is, the functions can be used traditionally or as keywords so their
parameter handling should be configured accordingly.

=item * settings => [ ... ]

This list of key/value pair will be passed to the load method imported from
C<Validation::Class::load> and will be applied on the calling class.

This approach affords you some trickery in that you can utilize the load method
to apply the current class' configuration to the calling class' configuration,
etc.

=back

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
