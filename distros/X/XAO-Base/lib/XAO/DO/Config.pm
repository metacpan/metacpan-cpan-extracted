=head1 NAME

XAO::DO::Config - Base object for all configurations

=head1 SYNOPSIS

Useful in tandem with XAO::Projects to describe contexts.

 use XAO::Projects qw(:all);

 my $config=XAO::Objects->new(objname => 'Config',
                              sitename => 'test');

 create_project(name => 'test',
                object => $config,
                set_current => 1);

 my $webconfig=XAO::Objects->new(objname => 'Web::Config');
 my $fsconfig=XAO::Objects->new(objname => 'FS::Config');

 $config->embed(web => $webconfig,
                fs => $fsconfig);

 # Now we have web and fs methods on the config itself:
 #
 my $cgi=$config->cgi;
 my $odb=$config->odb;

=head1 DESCRIPTION

This object provides storage for project specific configuration
variables and clipboard mechanism.

It can ``embed'' other configuration objects that describe specific
parts of the system -- such as database, web or something else. This is
done by using method embed() -- see below.

=head1 METHODS

XAO::DO::Config provides the following methods:

=over

=cut

###############################################################################
package XAO::DO::Config;
use strict;
use XAO::Utils;
use XAO::Objects;
use XAO::Cache;

use base XAO::Objects->load(objname => 'Atom');

###############################################################################
# Prototypes
#
sub cache ($%);
sub cleanup ($;@);
sub embed ($%);
sub embedded ($$);
sub new ($);

###############################################################################

=item cache (%)

Creates or retrieves a cache for use in various other XAO objects.
Arguments are directly passed to XAO::Cache's new() method (see
L<XAO::Cache>).

The 'name' argument is required and is used to identify the requested
cache. If a cache with the same name was requested before its previously
created object is returned and all new arguments are silently ignored
without making sure they match the previous request.

B<Note:> Retrieve method SHOULD NOT rely on any locally available
lexical variables, they will be taken from whatever scope existed first
time cache() was called!

Example:

 my $cache=$self->cache(
     name        => 'fubar',
     retrieve    => \&real_retrieve,
     coords      => ['foo','bar'],
     expire      => 60
 );

Caches are kept between executions in mod_perl environment.

=cut

sub cache ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $name=$args->{'name'} ||
        throw $self "cache - no 'name' argument";

    my $cache_list=$self->{'cache_list'};
    if(! $cache_list) {
        $cache_list=$self->{'cache_list'}={};
    }

    my $cache=$cache_list->{$name};

    if(! $cache) {
        $cache=$cache_list->{$name}=XAO::Cache->new($args,{
            sitename    => $self->{'sitename'},
        });
    }

    return $cache;
}

###############################################################################

=item cleanup ()

Calls cleanup method on all embedded configurations if it is
available. Order of calls is random.

=cut

sub cleanup ($;@) {
    my $self=shift;
    foreach my $name (keys %{$self->{names}}) {
        my $obj=$self->{names}->{$name}->{obj};
        $obj->cleanup(@_) if $obj->can('cleanup');
    }
}

###############################################################################

=item embed (%)

This method allows to embed other configuration objects into
Config. After embedding certain methods of embedded object become
available as Config methods. For example, if you embed Web::Config into
Config and Web::Config provides a method called cgi(), then you will be
able to call that method on Config:

 my $config=XAO::Objects->new(objname => 'Config');
 my $webconfig=XAO::Objects->new(objname => 'Web::Config');

 $config->embed('Web::Config' => $webconfig);

 my $cgi=$config->cgi();

In order to support that hte object being embedded must have a method
embeddable_methods() that returns an array of method names to be
embedded.

 sub embeddable_methods ($) {
     my $self=shift;
     return qw(cgi add_cookie del_cookie);
 }

The idea behind embedding is to allow easy access to arbitrary context
description objects (Configs). For example XAO::FS would provide its own
config that creates and caches its database handler. Some other database
module might provide its own config if for some reason XAO::FS can't be
used.

=cut

use vars qw(%global_methods);

sub embed ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    foreach my $name (keys %$args) {

        throw $self "embed - object with that name ($name) was already embedded before"
            if $self->{$name};

        my $obj=$args->{$name};
        $obj->can('embeddable_methods') ||
            throw $self "embed - object (".ref($obj).") does not have embeddable_methods() method";

        ##
        # Setting base for the object we embed, it might need it
        #
        $obj->set_base_config($self) if $obj->can('set_base_config');

        ##
        # Building perl code for proxy methods definitions
        #
        my @list=$obj->embeddable_methods();
        my $code='';
        foreach my $mn (@list) {
            $obj->can($mn) ||
                throw $self "embed - object (".ref($obj).") doesn't have embeddable method $mn()";

            $self->{methods}->{$mn} &&
                throw $self "embed - method with such name ($mn) already exists, can't be embedded from ".ref($obj);

            $self->{methods}->{$mn}=$obj;

            ##
            # We only add code if it is required, if that subroutine was
            # not defined before in another instance of Config object.
            #
            if(! $global_methods{$mn}) {
                $code.="sub $mn { shift->{methods}->{$mn}->$mn(\@_); }\n";
                $global_methods{$mn}=1;
            }
        }

        ##
        # Now a bit of black magic, evaluating the code in the current
        # package context to add appropriate proxy methods.
        #
        if($code) {
            eval $code;
            $@ && throw $self "embed - internal error; name=$name, obj=".ref($obj);
        }

        ##
        # To operate with sub-configs by name later on.
        #
        $self->{names}->{$name}->{obj}=$obj;
        $self->{names}->{$name}->{methods}=\@list;
    }
}

###############################################################################

=item embedded ($)

Returns a reference to a previously embedded object by name. Can be used
to call non-embedded method on that object.

=cut

sub embedded ($$) {
    my $self=shift;
    my $name=shift;

    my $desc=$self->{names}->{$name} ||
        throw $self "embedded - no configuration with such name ($name)";
    $desc->{obj};
}

###############################################################################

=item init (%)

Default method for project specific Config implementation
initialization. This method would normally be called by various handlers
after creating configuration and before making it current. It calls
init() method on all embedded configs in unpredictable order.

=cut

sub init ($) {
    my $self=shift;
    foreach my $name (keys %{$self->{names}}) {
        my $obj=$self->{names}->{$name}->{obj};
        $obj->init() if $obj->can('init');
    }
}

###############################################################################

=item new ()

Creates new instance of abstract Config.

=cut

sub new ($) {
    my $proto=shift;
    my $args=get_args(\@_);
    $proto->SUPER::new(merge_refs($args,{
        methods => {
            embed => 1,
            embedded => 1,
            new => 1,
            BEGIN => 1,
            END => 1,
            DESTROY => 1,
            AUTOLOAD => 1,
        },
    }));
}

###############################################################################
1;
__END__

=back

=head1 AUTHOR

Copyright (c) 2001 XAO Inc.

Author is Andrew Maltsev <am@xao.com>.
