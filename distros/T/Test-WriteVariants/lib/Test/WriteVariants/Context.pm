package Test::WriteVariants::Context;

use strict;
use warnings;

=head1 NAME

Test::WriteVariants::Context - representation of test context

=head1 DESCRIPTION

Contexts are used to abstract e.g. ambience or relations between
opportunities and and their application.

=head1 METHODS

=head2 new

A Context is an ordered list of various kinds of named values (such as
environment variables, our vars) possibly including other Context objects.

Values can be looked up by name. The first match will be returned.

=cut

my $ContextClass = __PACKAGE__;

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    return bless [ @_ ], $class;
}

=head2 new_composite

see Test::WriteVariants::Context::BaseItem

=cut

sub new_composite { shift->new(@_) } # see Test::WriteVariants::Context::BaseItem

=head2 push_var

add a var to an existing config

=cut

sub push_var {
    my ($self, $var) = @_;
    push @$self, $var;
    return;
}


sub _new_var    {
    my ($self, $t, $n, $v, %e) = @_;
    my $var = $t->new($n, $v, %e);
    return $self->new( $var ); # wrap var item in a context list
}

=head2 new_env_var

instantiates new context using an environment variable

=head2 new_our_var

instantiates new context using a global variable

=head2 new_module_use

instantiates new context using a module

=head2 new_meta_info

instantiates new context used to convey information between plugins

=cut

sub new_env_var    { shift->_new_var($ContextClass.'::EnvVar', @_) }
sub new_our_var    { shift->_new_var($ContextClass.'::OurVar', @_) }
sub new_module_use { shift->_new_var($ContextClass.'::ModuleUse', @_) }
sub new_meta_info  { shift->_new_var($ContextClass.'::MetaInfo', @_) }

=head2 get_code

collects code from members

=cut

# XXX should ensure that a given type+name is only output once (the latest one)
sub get_code  {
    my $self = shift;
    my @code;
    for my $setting (reverse @$self) {
        push @code, (ref $setting) ? $setting->get_code : $setting;
    }
    return join "", @code;
}


=head2 get_var

search backwards through list of settings, stop at first match

=cut

sub get_var { 
    my ($self, $name, $type) = @_;
    for my $setting (reverse @$self) {
        next unless $setting;
        my @value = $setting->get_var($name, $type);
        return $value[0] if @value;
    }
    return;
}

=head2 get_env_var

search backwards through list of settings, stop at first match (implies EnvVar)

=head2 get_our_var

search backwards through list of settings, stop at first match (implies OurVar)

=head2 get_module_use

search backwards through list of settings, stop at first match (implies ModuleUse)

=head2 get_meta_info

search backwards through list of settings, stop at first match (implies MetaInfo)

=cut

sub get_env_var    { my ($self, $name) = @_; return $self->get_var($name, $ContextClass.'::EnvVar') }
sub get_our_var    { my ($self, $name) = @_; return $self->get_var($name, $ContextClass.'::OurVar') }
sub get_module_use { my ($self, $name) = @_; return $self->get_var($name, $ContextClass.'::ModuleUse') }
sub get_meta_info  { my ($self, $name) = @_; return $self->get_var($name, $ContextClass.'::MetaInfo') }


{
    package Test::WriteVariants::Context::BaseItem;
    use strict;
    use warnings;
    require Data::Dumper;
    require Carp;

    # base class for an item (a name-value-type triple)

    sub new {
        my ($class, $name, $value) = @_;

        my $self = bless {} => $class;
        $self->name($name);
        $self->value($value);

        return $self;
    }

    sub name {
        my $self = shift;
        $self->{name} = shift if @_;
        return $self->{name};
    }

    sub value {
        my $self = shift;
        $self->{value} = shift if @_;
        return $self->{value};
    }

    sub get_code  {
        return '';
    }

    sub get_var {
        my ($self, $name, $type) = @_;
        return if $type && !$self->isa($type);  # empty list
        return if $name ne $self->name;         # empty list
        return $self->value;                    # scalar
    }

    sub quote_values_as_perl {
        my $self = shift;
        my @perl_values = map {
            my $val = Data::Dumper->new([$_])->Terse(1)->Purity(1)->Useqq(1)->Sortkeys(1)->Dump;
            chomp $val;
            $val;
        } @_;
        Carp::confess("quote_values_as_perl called with multiple items in scalar context (@perl_values)")
            if @perl_values > 1 && !wantarray;
        return $perl_values[0] unless wantarray;
        return @perl_values;
    }

    # utility method to get a new composite when you only have a value object
    sub new_composite { $ContextClass->new(@_) }

} # ::BaseItem


{
    package Test::WriteVariants::Context::EnvVar;
    use strict;
    use warnings;
    use base 'Test::WriteVariants::Context::BaseItem';

    # subclass representing a named environment variable

    sub get_code {
        my $self = shift;
        my $name = $self->{name};
        my @lines;
        if (defined $self->{value}) {
            my $perl_value = $self->quote_values_as_perl($self->{value});
            push @lines, sprintf('$ENV{%s} = %s;', $name, $perl_value);
            push @lines, sprintf('END { delete $ENV{%s} } # for VMS', $name);
        }
        else {
            # we treat undef to mean the ENV var should not exist in %ENV
            push @lines, sprintf('local  $ENV{%s};', $name); # preserve old value for VMS
            push @lines, sprintf('delete $ENV{%s};', $name); # delete from %ENV
        }
        return join "\n", @lines, '';
    }
}


{
    package Test::WriteVariants::Context::OurVar;
    use strict;
    use warnings;
    use base 'Test::WriteVariants::Context::BaseItem';

    # subclass representing a named 'our' variable

    sub get_code {
        my $self = shift;
        my $perl_value = $self->quote_values_as_perl($self->{value});
        return sprintf 'our $%s = %s;%s', $self->{name}, $perl_value, "\n";
    }
}


{
    package Test::WriteVariants::Context::ModuleUse;
    use strict;
    use warnings;
    use base 'Test::WriteVariants::Context::BaseItem';

    # subclass representing 'use $name (@$value)'

    sub get_code {
        my $self = shift;
        my @imports = $self->quote_values_as_perl(@{$self->{value}});
        return sprintf 'use %s (%s);%s', $self->{name}, join(", ", @imports), "\n";
    }
}

{
    package Test::WriteVariants::Context::MetaInfo;
    use strict;
    use warnings;
    use base 'Test::WriteVariants::Context::BaseItem';

    # subclass that doesn't generate any code
    # It's just used to convey information between plugins
}

1;

__END__

=head1 ACKNOWLEDGEMENTS

This module has been created to support DBI::Test in design and separation
of concerns.

=head1 COPYRIGHT

Copyright 2014-2015 Tim Bunce and Perl5 DBI Team.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of either:

        a) the GNU General Public License as published by the Free
        Software Foundation; either version 1, or (at your option) any
        later version, or

        b) the "Artistic License" which comes with this Kit.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

=cut
