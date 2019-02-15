#!/usr/bin/env perl
# XML::Axk::Sandbox - Sandbox providing a language limited access to the core.
# Reminder: all matchers define test($refdata)->bool.
# Copyright (c) 2018 cxw42.  All rights reserved.  Artistic 2.

package XML::Axk::Sandbox;
use XML::Axk::Base;
use Hash::Util::FieldHash;

#our $VERBOSE = 0;

#sub _dump {
#    local $Data::Dumper::Maxdepth = 2;
#    Dumper @_;
#} #_dump()

# Constructor and inside-out fields ===================================== {{{1

# Data storage
my %core_;  # The core associated with this sandbox
my %target_;    # The name of the script package in which this lives
Hash::Util::FieldHash::fieldhashes \%core_;

sub new {
    my $class = shift;

    my $self  = bless {}, $class;
    $core_{$self} = shift;
    $target_{$self} = shift;

    return $self;
} #new()

# }}}1
# Variable injection ============================================= {{{1

# Set up the tie between an SP in the script and its storage in the core.
sub inject_var {
    my $self = shift;
    croak("Internal use only --- see XML::Axk::Language")
        unless scalar caller eq 'XML::Axk::Language';

    my $target = $target_{$self} or die "No target known for $self";

    my ($lang, $varname) = @_;
    my $basename = substr($varname, 1);

    no strict 'refs';

    if(substr($varname, 0, 1) eq '$') {         # scalar
        tie(${"${target}::${basename}"}, 'XML::Axk::Vars::Scalar',
            $self, $lang, $varname);

    } elsif(substr($varname, 0, 1) eq '@') {    # array
        tie(@{"${target}::${basename}"}, 'XML::Axk::Vars::Array',
            $self, $lang, $varname);

    } else {
        croak "Can't inject unknown var type $varname";
    }
} #_inject_var()

# }}}1
# SPs =================================================================== {{{1

# Get the SPs for a language.  Returns a hashref.
# A sandbox is associated with one target (user script), but each target can
# support multiple languages.
#
# When called from a language, no params.
# When called from an X::A::Vars, a specific language must be provided.
# Returns undef if allocate_sps hasn't yet been called for that language.
sub sps {
    my $self = shift;
    my $lang = caller;
    $lang = shift if $lang =~ /^XML::Axk::Vars/;
    my $core = $core_{$self} or croak("No core known for $self");

    my $hrSP = $core->{sp};
    return $hrSP->{$lang} if exists $hrSP->{$lang};
    return undef;
} #sps()

# Allocate the SPs for a particular language.
# All the SPs must be given in one call.  Subsequent calls are nops.
# Takes the list of variables to allocate, with sigils.
sub allocate_sps {
    my $self = shift;
    croak("Internal use only --- see XML::Axk::Language")
        unless scalar caller eq 'XML::Axk::Language';
    my $core = $core_{$self} or croak("No core known for $self");

    my $lang = shift;

    my $hrSP = $core->{sp};
    return if exists $hrSP->{$lang};

    $hrSP = $hrSP->{$lang} = {};

    for my $name (@_) {
        my $sigil = substr($name, 0, 1);
        $hrSP->{$name} = undef, next if $sigil eq '$';
        $hrSP->{$name} = [], next if $sigil eq '@';
    }

    #say Dumper \%{$self->{sp}};
} #allocate_sps()

# }}}1
# Updaters ============================================================== {{{1

sub set_updater {
    my ($self, $lang, $updater) = @_;
    croak("Internal use only --- see XML::Axk::Language")
        unless scalar caller eq 'XML::Axk::Language';
    my $core = $core_{$self} or croak("No core known for $self");

    croak("Need a coderef") unless ref $updater eq 'CODE';
    $core->set_updater($lang, $updater);
} #set_updater()

# }}}1
# Events (pre, post, worklist) ========================================== {{{1

# We provide direct access to these arrays so that languages can push/pop/&c.
# This does mean languages can step on each other, but has the advantage that
# I don't have to manually track which order which languages added what to
# which list.  I am open to discussion of better ways.

# array($self, $core, $name)
my $_array = sub {
    my ($self, $name) = @_;
    my $core = $core_{$self} or croak("No core known for $self");
    return $core->{$name};  # an array ref
};

sub pre_all { push @_, 'pre_all'; goto &$_array; }
sub pre_file { push @_, 'pre_file'; goto &$_array; }
sub worklist { push @_, 'worklist'; goto &$_array; }
sub post_file { push @_, 'post_file'; goto &$_array; }
sub post_all { push @_, 'post_all'; goto &$_array; }

# }}}1
1;
__END__
# === Documentation ===================================================== {{{1

=pod

=encoding UTF-8

=head1 NAME

XML::Axk::Sandbox - Sandbox providing a language limited access to the axk core

=head1 SYNOPSIS

Each axk script is in its own package, which has an C<$_AxkSandbox> instance
of this class.  Languages used in that script can access the script parameters
(SPs) and set updaters through the sandbox.

=head1 SUBROUTINES

=head2 XML::Axk::Sandbox->new

Constructor.

=head1 METHODS

=head2 not yet documented

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018 Christopher White.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). Details are in the LICENSE
file accompanying this distribution.

=cut

# }}}1
# vi: set ts=4 sts=4 sw=4 et ai fo-=ro foldmethod=marker: #
