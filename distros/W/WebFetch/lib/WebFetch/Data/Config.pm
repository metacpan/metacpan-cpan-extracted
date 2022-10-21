# WebFetch::Data::Config
# ABSTRACT: WebFetch configuration data management
#
# Copyright (c) 2022 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  https://www.gnu.org/licenses/gpl-3.0-standalone.html
#
# WebFetch::Data::Config contains configuration data for the WebFetch class hierarchy.
# It was made to replace older-generation code which depended on subclasses defining
# package variables. That is no longer considered good practice. This uses the singleton
# design pattern to maintain a simple key/value store for configuration data.

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
use utf8;
## use critic (Modules::RequireExplicitPackage)

package WebFetch::Data::Config;
$WebFetch::Data::Config::VERSION = '0.15.4';
use Carp qw(croak confess);
use base 'Class::Singleton';

# helper function to allow methods to get the singleton instance whether called as a class or instance method
sub _class_or_obj
{
    my $coo = shift;    # coo = class or object

    # safety net: all-stop if we received an undef
    if ( not defined $coo ) {
        confess "coo got undef from:" . ( join "|", caller 1 );
    }

    # safety net: the class or object must be WebFetch::Data::Config or a derivative
    if ( not $coo->isa("WebFetch::Data::Config") ) {
        confess "incompatible class $coo from:" . ( join "|", caller 1 );
    }

    # instance method if it got an object reference
    return $coo if ref $coo;

    # class method: return the instance via the instance() class method
    # if the singleton object wasn't already instantiated, this will take care of it
    # assumption: it must be string name of class WebFetch::Data::Config or subclass of it - so it has instance()
    return $coo->instance();
}

# check for existence of a config entry
sub contains
{
    my ( $class_or_obj, $key ) = @_;
    my $instance = _class_or_obj($class_or_obj);
    return exists $instance->{$key} ? 1 : 0;
}

# configuration read accessor
sub read_accessor
{
    my ( $class_or_obj, $key ) = @_;
    my $instance = _class_or_obj($class_or_obj);
    if ( $instance->contains($key) ) {
        return $instance->{$key};
    }
    return;
}

# configuration write accessor
sub write_accessor
{
    my ( $class_or_obj, $key, $value ) = @_;
    my $instance = _class_or_obj($class_or_obj);
    $instance->{$key} = $value;
    return;
}

# configuration read/write accessor
# WebFetch's config() method calls here
sub accessor
{
    my ( $class_or_obj, $key, $value ) = @_;
    my $instance = _class_or_obj($class_or_obj);

    # if no value is provided, use read accessor
    if ( not defined $value ) {
        return $instance->read_accessor($key);
    }

    # otherwise use write accessor
    $instance->write_accessor( $key, $value );
    return;
}

# delete configuration item
sub del
{
    my ( $class_or_obj, $key ) = @_;
    my $instance = _class_or_obj($class_or_obj);
    if ( $instance->contains($key) ) {
        return delete $instance->{$key};
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebFetch::Data::Config - WebFetch configuration data management

=head1 VERSION

version 0.15.4

=head1 SYNOPSIS

In all classes other than WebFetch, use WebFetch's config() and has_config() class methods.

    use WebFetch;
    # ...
    WebFetch->config($key, $write_value);
    my $read_value = WebFetch->config($key);
    my $bool_value = WebFetch->has_config($key);
    my $del_value = WebFetch->del_config($key);

From within WebFetch, class or instance methods may be used interchangeably.

    use WebFetch::Data::Config;
    WebFetch::Data::Config->instance(@params); # instantiate singleton with optional initalization data
    #...
    my $config_instance = WebFetch::Data::Config->instance();
    #...
    $config_instance->write_accessor($key, $write_value);
    my $read_value = $config_instance->read_accessor($key);
    my $bool_value = $config_instance->contains($key);
    my $del_value = $config_instance->del($key);
    # or
    WebFetch::Data::Config->accessor($key, $write_value);
    my $read_value = WebFetch::Data::Config->accessor($key);
    my $bool_value = WebFetch::Data::Config->contains($key);
    my $del_value = WebFetch::Data::Config->del($key);

=head1 DESCRIPTION

WebFetch::Data::Config is a key/value store for global WebFetch configuration data.
The methods of this class should only be called from WebFetch.
Otherwise use the config() and has_config() class methods provided by WebFetch to access it.

=head1 SEE ALSO

L<WebFetch>
L<https://github.com/ikluft/WebFetch>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/WebFetch/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/WebFetch/pulls>

=head1 AUTHOR

Ian Kluft <https://github.com/ikluft>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998-2022 by Ian Kluft.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
