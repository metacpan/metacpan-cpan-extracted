package XML::Essex::Base;

$VERSION = 0.000_1;

=head1 NAME

XML::Essex::Base - class for Essex SAX components

=head1 SYNOPSIS

   ## Not for external use.

=head1 DESCRIPTION

All Essex generators, filters and handlers must inherit from this
class among others.  This class provides methods common to all
three and specialized export semantics so that exports may be
inherited from base classes.

=for test_scripts XML-Generator-Essex.t XML-Filter-Essex.t

=cut

use strict;

use Carp ();  # keep from acquiring Croak's exported subs as methods.

our $self;

=head1 METHODS

=over

=cut

=item new

Creates and initializes an instance.

=cut

sub new {
    my $proto = shift;
    my $self = bless { @_ }, ref $proto || $proto;
    $self->_init;  ## These must use NEXT::, it's a diamond hierarchy at
                   ## times (eq XML::Filter::Dispatcher).
    return $self;
}

sub _classes {
    no strict "refs";
    return ( $_ ) unless exists ${"${_}::"}{ISA};
    return ( $_, map _classes( $_ ), @{"${_}::ISA"} );
}

=item import

Uses C<@EXPORT> and C<@EXPORT_OK> arrays like Exporter.pm, but
implements inheritence on it.  Understands the meaning of the tags
":all" and ":default", which are hardcoded (C<%EXPORT_TAGS> is ignored
thus far), but does not emulate Exporter's other, rarely used syntaxes.

=cut

use vars qw( $self );

sub import {
    my $class = shift;
    my $caller = caller;

    my $no_params = ! @_;

    no strict "refs";

    my @classes = do {
        local $_ = $class;
        my %seen;
        grep !$seen{$_}++, _classes;
    };

    my %tags;
    @_ = grep
        substr( $_, 0, 1 ) eq ":" ? $tags{$_} = undef : 1,
        @_;

    my %default_exports = (
        map { ( $_ => undef ) }
        map
            exists ${"${_}::"}{EXPORT}
                ? @{"${_}::EXPORT"}
                : (),
        @classes
    );

    push @_, keys %default_exports if exists $tags{":default"};

    my %all_exports = (
        %default_exports,
        ( exists $tags{":all"} || @_ )
            ? (
                map { ( $_ => undef ) }
                map
                    exists ${"${_}::"}{EXPORT_OK}
                        ? @{"${_}::EXPORT_OK"}
                        : (),
                @classes 
            )
            : ()
        );
    push @_, keys %all_exports if exists $tags{":all"};

    @_= keys %default_exports if $no_params;

    my @not_exported;

    my %seen;
    for ( grep !$seen{$_}++, @_ ) {
        unless ( exists $all_exports{$_} ) {
            push @not_exported, $_;
            next;
        }

        *{"${caller}::$_"} = ( $class->can( $_ ) || \&{"${class}::$_"} );
    }

    Carp::croak
        "functions ",
        join( " ", @not_exported ),
        " not exported by $class"
        if @not_exported;
}

=item main

The main routine.  Overload this or pass in a code ref
to C<new( Main => \&foo )> or C<set_main( \&foo )> to set this.

=cut

sub main {
    goto &{$_[0]->{Main}};
}

=item set_main

Sets the main routines to a code reference.

=cut

sub set_main {
    my $self = shift;
    $self->{Main} = shift;
}

=item reset

Called before the main routine is called.

=cut

sub reset {
    my $self = shift;

    $self->{NamespaceMaps} = [];

    $self->NEXT::reset;
}

=item finish

Called after the main routine is called.

=cut

=item execute

Prepares the runtime environment, calls C<<$self->main( @_ )>>, cleans
up afterwards and runs sanity checks.

This is called automatically in filters and handlers, must be
called manually in generators.

Calls reset() before and finish() after main().

=cut

sub execute {
    local $self = shift;

    return if $self->{NoExecute};  ## Used by XML::Essex

    ## Don't save a reference to the output_monitor in case some whacko
    ## manages to alter $self->{Handler} somehow.
    $self->reset;

    local $_;  ## get() explicitly sets $_ for the convenience of
               ## main() programmers.  In unthreaded mode, we want
               ## to be sure not to perturb the caller's sense of $_.

    my $r;
    my @r;
    my $ok = eval {
        wantarray
            ? @r = $self->main( @_ )
            : defined wantarray
                ? $r = $self->main( @_ )
                : $self->main( @_ );
        1;
    };

    my ( $result_set, $result ) = $self->finish( $ok, $@ );

    return $result if $result_set;
    return wantarray ? @r : $r;
}


=item namespace_map

aka: ns_map

    $self->ns_map(
        $ns1 => $prefix1,
        $ns2 => $prefix2,
        ...
    );

Creates a new set of mappings in addition to any that are already in
effect.  If a namespace is mapped to multiple prefixes, the last one
created is used.  The mappings stay in effect until the map objected
referred to by C<$map> is destroyed.

NOTE: the namespace prefixes from the source document override the
namespace prefixes set here when events are transmitted downstream.
This is so that namespace prefixes are not altered arbitrarily; the
philosophy is to make as few changes to the source document as possible
and remapping prefixes to match what happens to be declared in the
filter would not be proper.

For names in namespaces that are introduced by the filter and are not in
the source document, the prefixes from the filter are used.  This is a
bit dangerous: some other namespace in the source document may use the
same prefix and the result could be catastrophic.  Some future version
will try to detect these collisions, and there may even be a nice way to
avoid them.

Source document prefixes are generally invisible in the Essex
environment (aside from the start_prefix_mapping and end_prefix_mapping
events) because they could be anything.  If you root around inside essex
objects enough, though, you can ferret them out.  Trying to do that is a
pretty good indication that something's wrong.

=cut

sub namespace_map {
    local $self = shift if @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ );
    require XML::Essex::NamespaceMap;
    push @{$self->{Namespaces}},
        XML::Essex::NamespaceMap->new( $self, @_ );
}

*ns_map = \&namespace_map;


=back

=head1 LIMITATIONS

Does not support other Exporter features like exporting past several calling
modules.

=head1 COPYRIGHT

    Copyright 2002, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, oir GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
