package decorators::providers::constructor;
# ABSTRACT: A set of decorators to generate BUILDARG methods

use strict;
use warnings;

use decorators ':for_providers';

use Carp      ();
use MOP::Util ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub strict : Decorator : CreateMethod {
    my ( $meta, $method, %signature ) = @_;

    # XXX:
    # Consider perhaps supporting something
    # like the Perl 6 signature format here,
    # which would give us a more sophisticated
    # way to specify the constructor API
    #
    # The way MAIN is handled is good inspiration maybe ...
    # http://perl6maven.com/parsing-command-line-arguments-perl6
    #
    # - SL

    my $class_name  = $meta->name;
    my $method_name = $method->name;

    Carp::confess('The `strict` trait can only be applied to BUILDARGS')
        if $method_name ne 'BUILDARGS';

    if ( %signature ) {

        my @all       = sort keys %signature;
        my @required  = grep !/\?$/, @all;

        my $max_arity = 2 * scalar @all;
        my $min_arity = 2 * scalar @required;

        # use Data::Dumper;
        # warn Dumper {
        #     class     => $meta->name,
        #     all       => \@all,
        #     required  => \@required,
        #     min_arity => $min_arity,
        #     max_arity => $max_arity,
        # };

        $meta->add_method('BUILDARGS' => sub {
            my ($self, @args) = @_;

            my $arity = scalar @args;

            Carp::confess('Constructor for ('.$class_name.') expected '
                . (($max_arity == $min_arity)
                    ? ($min_arity)
                    : ('between '.$min_arity.' and '.$max_arity))
                . ' arguments, got ('.$arity.')')
                if $arity < $min_arity || $arity > $max_arity;

            my $proto = $self->UNIVERSAL::Object::BUILDARGS( @args );

            my @missing;
            # make sure all the expected parameters exist ...
            foreach my $param ( @required ) {
                push @missing => $param unless exists $proto->{ $param };
            }

            Carp::confess('Constructor for ('.$class_name.') missing (`'.(join '`, `' => @missing).'`) parameters, got (`'.(join '`, `' => sort keys %$proto).'`), expected (`'.(join '`, `' => @all).'`)')
                if @missing;

            my (%final, %super);

            #warn "---------------------------------------";
            #warn join ', ' => @all;

            # do any kind of slot assignment shuffling needed ....
            foreach my $param ( @all ) {

                #warn "CHECKING param: $param";

                my $from = $param;
                $from =~ s/\?$//;
                my $to   = $signature{ $param };

                #warn "PARAM: $param FROM: ($from) TO: ($to)";

                if ( $to =~ /^super\((.*)\)$/ ) {
                    $super{ $1 } = delete $proto->{ $from }
                         if $proto->{ $from };
                }
                else {
                    if ( exists $proto->{ $from } ) {

                        #use Data::Dumper;
                        #warn "BEFORE:", Dumper $proto;

                        # now grab the slot by the correct name ...
                        $final{ $to } = delete $proto->{ $from };

                        #warn "AFTER:", Dumper $proto;
                    }
                    #else {
                        #use Data::Dumper;
                        #warn "NOT FOUND ($from) :", Dumper $proto;
                    #}
                }
            }

            # inherit keys ...
            if ( keys %super ) {
                my $super_proto = $self->next::method( %super );
                %final = ( %$super_proto, %final );
            }

            if ( keys %$proto ) {

                #use Data::Dumper;
                #warn Dumper +{
                #    proto => $proto,
                #    final => \%final,
                #    super => \%super,
                #    meta  => {
                #        class     => $meta->name,
                #        all       => \@all,
                #        required  => \@required,
                #        min_arity => $min_arity,
                #        max_arity => $max_arity,
                #    }
                #};

                Carp::confess('Constructor for ('.$class_name.') got unrecognized parameters (`'.(join '`, `' => keys %$proto).'`)');
            }

            return \%final;
        });
    }
    else {
        $meta->add_method('BUILDARGS' => sub {
            my ($self, @args) = @_;
            Carp::confess('Constructor for ('.$class_name.') expected 0 arguments, got ('.(scalar @args).')')
                if @args;
            return $self->UNIVERSAL::Object::BUILDARGS();
        });
    }
}

1;

__END__

=pod

=head1 NAME

decorators::providers::constructor - A set of decorators to generate BUILDARG methods

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use decorators ':constructor';

  # accepts /no/ arguments
  sub BUILDARGS : strict;

  # accept *only* the following arguments
  sub BUILDARGS : strict(
      foo  => _foo,      # required key
      bar? => _bar       # optional
      baz? => super(baz) # delegate to the superclass
  );

=head1 DESCRIPTION

=over 4

=item C<< strict( arg_key => slot_name, ... ) >>

This is a trait that is exclusively applied to the C<BUILDARGS>
method. This is a means for generating a strict interface for the
C<BUILDARGS> method that will map a set of constructor parameters
to a set of given slots. This is useful for maintaining encapsulation
for things like a private slot with a different public name.

    # declare a slot with a private name
    use slots (_bar => sub {});

    # map the `foo` key to the `_bar` slot
    sub BUILDARGS : strict( foo => _bar );

All other parameters will be rejected and an exception thrown. If
you wish to have an optional parameter, simply follow the parameter
name with a question mark, like so:

    # declare a slot with a private name
    use slots (_bar => sub {});

    # the `foo` key is optional, but if
    # given, will store in the `_bar` slot
    sub BUILDARGS : strict( foo? => _bar );

If you wish to accept parameters for your superclass's constructor
but do not want to specify storage location because of encapsulation
concerns, simply use the C<super> designator, like so:

    # map the `foo` key to the local `_bar` slot
    # with the `bar` key, let the superclass decide ...
    sub BUILDARGS : strict(
        foo => _bar,
        bar => super(bar)
    );

If you wish to have a constructor that accepts no parameters at
all, then simply do this.

    sub BUILDARGS : strict;

And the constructor will throw an exception if any arguments at
all are passed in.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
