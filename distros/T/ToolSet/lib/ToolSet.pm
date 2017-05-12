use 5.006;
use strict;
use warnings;

package ToolSet;
# ABSTRACT: Load your commonly-used modules in a single import

our $VERSION = '1.03';

use Carp;

#--------------------------------------------------------------------------#
# package variables
#--------------------------------------------------------------------------#

my %use_pragmas;
my %no_pragmas;
my %exports_of;

#--------------------------------------------------------------------------#
# functions
#--------------------------------------------------------------------------#

sub export {
    my $class = shift;
    croak "Arguments to export() must be key/value pairs"
      if @_ % 2;
    my @spec   = @_;
    my $caller = caller;
    $exports_of{$caller} = \@spec;
}

sub import {
    my ($class) = @_;
    my $caller = caller;
    if ( $use_pragmas{$class} ) {
        for my $p ( keys %{ $use_pragmas{$class} } ) {
            my $module = $p;
            $module =~ s{::}{/}g;
            $module .= ".pm";
            require $module;
            $p->import( @{ $use_pragmas{$class}{$p} } );
        }
    }
    if ( $no_pragmas{$class} ) {
        for my $p ( keys %{ $no_pragmas{$class} } ) {
            my $module = $p;
            $module =~ s{::}{/}g;
            $module .= ".pm";
            require $module;
            $p->unimport( @{ $no_pragmas{$class}{$p} } );
        }
    }
    my @exports = @{ $exports_of{$class} || [] };
    while (@exports) {
        my ( $mod, $request ) = splice( @exports, 0, 2 );

        my $evaltext;
        if ( !$request ) {
            $evaltext = "package $caller; use $mod";
        }
        elsif ( ref $request eq 'ARRAY' ) {
            my $args = join( q{ } => @$request );
            $evaltext = "package $caller; use $mod qw( $args )";
        }
        elsif ( ref $request eq 'SCALAR' ) {
            my $args = $$request;
            $evaltext = "package $caller; use $mod $args";
        }
        elsif ( ref( \$request ) eq 'SCALAR' ) {
            $evaltext = "package $caller; use $mod qw( $request )";
        }
        else {
            croak "Invalid import specification for $mod";
        }
        eval $evaltext; ## no critic
        croak "$@" if $@;
    }

    # import from a @EXPORT array in the ToolSet subclass
    {
        no strict 'refs'; ## no critic
        for my $fcn ( @{"${class}::EXPORT"} ) {
            my $source = "${class}::${fcn}";
            die "Can't import missing subroutine $source"
              if !defined *{$source}{CODE};
            *{"${caller}::${fcn}"} = \&{$source};
        }
    }
}

sub set_strict {
    my ( $class, $value ) = @_;
    return unless $value;
    my $caller = caller;
    $use_pragmas{$caller}{strict} = [];
}

sub set_warnings {
    my ( $class, $value ) = @_;
    return unless $value;
    my $caller = caller;
    $use_pragmas{$caller}{warnings} = [];
}

sub set_feature {
    my ( $class, @args ) = @_;
    return unless @args;
    my $caller = caller;
    $use_pragmas{$caller}{feature} = [@args];
}

sub use_pragma {
    my ( $class, $pragma, @args ) = @_;
    my $caller = caller;
    $use_pragmas{$caller}{$pragma} = [@args];
}

sub no_pragma {
    my ( $class, $pragma, @args ) = @_;
    my $caller = caller;
    $no_pragmas{$caller}{$pragma} = [@args];
}

1; # Magic true value required at end of module

__END__

=pod

=encoding UTF-8

=head1 NAME

ToolSet - Load your commonly-used modules in a single import

=head1 VERSION

version 1.03

=head1 SYNOPSIS

Creating a ToolSet:

    # My/Tools.pm
    package My::Tools;

    use base 'ToolSet';

    ToolSet->use_pragma( 'strict' );
    ToolSet->use_pragma( 'warnings' );
    ToolSet->use_pragma( qw/feature say switch/ ); # perl 5.10

    # define exports from other modules
    ToolSet->export(
        'Carp'          => undef,       # get the defaults
        'Scalar::Util'  => 'refaddr',   # or a specific list
    );

    # define exports from this module
    our @EXPORT = qw( shout );
    sub shout { print uc shift };

    1; # modules must return true

Using a ToolSet:

    # my_script.pl

    use My::Tools;

    # strict is on
    # warnings are on
    # Carp and refaddr are imported

    carp "We can carp!";
    print refaddr [];
    shout "We can shout, too!";

=head1 DESCRIPTION

ToolSet provides a mechanism for creating logical bundles of modules that can
be treated as a single, reusable toolset that is imported as one.  Unlike
CPAN bundles, which specify modules to be installed together, a toolset
specifies modules to be imported together into other code.

Toolset is designed to be a superclass -- subclasses will specify specific
modules to bundle.  ToolSet supports custom import lists for each included
module and even supports compile-time pragmas like C<strict>, C<warnings>
and C<feature>.

A ToolSet module does not physically bundle the component modules, but
rather specifies lists of modules to be used together and import
specifications for each.  By adding the component modules to a
prerequisites list in a C<Makefile.PL> or C<Build.PL> for a ToolSet
subclass, an entire dependency chain can be managed as a single unit across
scripts or distributions that use the subclass.

=head1 INTERFACE

=head2 Setting up

    use base 'ToolSet';

ToolSet must be used as a base class.

=head2 C<@EXPORT>

    our @EXPORT = qw( shout };
    sub shout { print uc shift }

Functions defined in the ToolSet subclass can be automatically exported during
C<use()> by listing them in an C<@EXPORT> array.

=head2 C<export>

    ToolSet->export(
        'Carp' => undef,
        'Scalar::Util' => 'refaddr',
    );

Specifies packages and arguments to import via C<use()>.  An argument of C<undef>
or the empty string calls C<use()> with default imports.  Arguments should be
provided either as a whitespace delimited string or in an anonymous array.  An
empty anonymous array will be treated like passing the empty list as an
argument to C<use()>.  Here are examples of how how specifications will be
provided to C<use()>:

    'Carp' => undef                 # use Carp;
    'Carp' => q{}                   # use Carp;
    'Carp' => 'carp croak'          # use Carp qw( carp croak );
    'Carp' => [ '!carp', 'croak' ]  # use Carp qw( !carp croak );
    'Carp' => []                    # use Carp ();

Elements in an array are passed to C<use()> as a white-space separated
list, so elements may not themselves contain spaces or unexpected results
will occur.  (But read further below about exact whitespace handling.)

As of version 1.00, modules may be repeated multiple times.  This is useful
with modules like L<autouse>.

    ToolSet->export(
      autouse => [ 'Carp' => qw(carp croak) ],
      autouse => [ 'Scalar::Util' => qw(refaddr blessed) ],
    );

As of version 1.02, if you need exact handling of whitespace, pass a
reference to a string and it will be used verbatim:

    'Foo' => \'-foo => { bar => "Some thing with spaces" }'

    #  use Foo -foo => { bar => "Some thing with spaces" }'

=head2 C<use_pragma>

  ToolSet->use_pragma( 'strict' );         # use strict;
  ToolSet->use_pragma( 'feature', ':5.10' ); # use feature ':5.10';

Specifies a compile-time pragma to enable and optional arguments to that
pragma.  This must only be used with pragmas that act via the magic C<$^H> or
C<%^H> variables.  It must not be used with modules that have other side-effects
during import() such as exporting functions.

=head2 C<no_pragma>

  ToolSet->no_pragma( 'indirect' ); # no indirect;

Like C<use_pragma>, but disables a pragma instead.

If a pragma is specified in both a C<use_pragma> and C<no_pragma> statement, the
C<use_pragma> will be executed first.  This allow turning on a pragma with
default settings and then disabling some of them.

  ToolSet->use_pragma( 'strict' );
  ToolSet->no_pragma ( 'strict', 'refs' );

=head2 C<set_feature> (DEPRECATED)

See C<use_pragma> instead.

=head2 C<set_strict> (DEPRECATED)

See C<use_pragma> instead.

=head2 C<set_warnings> (DEPRECATED)

See C<use_pragma> instead.

=head1 DIAGNOSTICS

ToolSet will report an error for a module that cannot be found just like an
ordinary call to C<use()> or C<require()>.

Additional error messages include:

=over 4

=item *

C<"Invalid import specification for MODULE"> -- an incorrect type was provided for the list to be imported (e.g. a hash reference)

=item *

C<"Can't import missing subroutine NAME"> -- the named subroutine is listed in C<@EXPORT>, but is not defined in the ToolSet subclass

=back

=head1 CONFIGURATION AND ENVIRONMENT

ToolSet requires no configuration files or environment variables.

=head1 DEPENDENCIES

ToolSet requires at least Perl 5.6.  ToolSet subclasses will, of course, be
dependent on any modules they load.

=head1 SEE ALSO

Similar functionality is provided by the L<Toolkit> module, though that
module requires defining the bundle via text files found within directories
in C<PERL5LIB> and uses source filtering to insert their contents as files
are compiled.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/ToolSet/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/ToolSet>

  git clone https://github.com/dagolden/ToolSet.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Haakon Haegland

Haakon Haegland <Hakon.Hagland@uni.no>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
