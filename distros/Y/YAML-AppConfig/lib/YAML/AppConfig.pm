package YAML::AppConfig;
use strict;
use warnings;
use Carp;
use Storable qw(dclone);  # For Deep Copy

####################
# Global Variables
####################
our $VERSION = '0.19';
our @YAML_PREFS = qw(YAML::Syck YAML);

#########################
# Class Methods: Public
#########################
sub new {
    my ($class, %args) = @_;
    my $self = bless( \%args, ref($class) || $class );

    # Load a YAML parser.
    $self->{yaml_class} = $self->_load_yaml_class();

    # Load config from file, string, or object.
    if ( exists $self->{file} ) {
        my $load_file = eval "\\&$self->{yaml_class}::LoadFile";
        $self->{config} = $load_file->( $self->{file} );
    } elsif ( exists $self->{string} ) {
        my $load = eval "\\&$self->{yaml_class}::Load";
        $self->{config} = $load->( $self->{string} );
    } elsif ( exists $self->{object} ) {
        $self->{config} = dclone( $self->{object}->{config} );
    } else {
        $self->{config} = {};
    }

    # Initialize internal state
    $self->_install_accessors();  # Install convenience accessors.
    $self->{seen} = {};  # For finding circular references.
    $self->{scope_stack} = [];  # For implementing dynamic variables.

    return $self;
}

#############################
# Instance Methods: Public
#############################
sub config {
    my $self = shift;
    return $self->{config};
}

sub config_keys {
    my $self = shift;
    return sort keys %{$self->config};
}

sub get {
    my $self = shift;
    $self->{seen} = {};    # Don't know if we exited cleanly, so clean up.
    return $self->_get(@_);
}

# Inner get so we can clear the seen hash above.  Listed here for readability.
sub _get {
    my ( $self, $key, $no_resolve ) = @_;
    return unless $self->_scope_has($key);
    return $self->config->{$key} if $self->{no_resolve} or $no_resolve;
    croak "Circular reference in $key." if exists $self->{seen}->{$key};
    $self->{seen}->{$key} = 1;
    my $value = $self->_resolve_refs($self->_get_from_scope($key));
    delete $self->{seen}->{$key};
    return $value;
}

sub set {
    my ($self, $key, $value) = @_;
    return $self->config->{$key} = $value;
}

sub merge {
    my ( $self, %args ) = @_;
    my $other_conf = $self->new( %args );
    for my $key ( $other_conf->config_keys ) {
        $self->set( $key, $other_conf->get( $key, 'no vars' ) );
    }
}

sub resolve {
    my ( $self, $thing ) = @_;
    $self->{seen} = {};  # Can't be sure this is empty, could've croaked.
    return $self->_resolve_refs($thing);
}

sub dump {
    my ( $self, $file ) = @_;
    my $func = eval "\\&$self->{yaml_class}::" . ($file ? 'DumpFile' : 'Dump');
    die "Could not find $func: $@" if $@;
    $func->($file ? ($file) : (), $self->config);
}

##############################
# Instance Methods: Private
##############################

# void _resolve_refs(Scalar $value)
#
# Recurses on $value until a non-reference scalar is found, in which case we
# defer to _resolve_scalar.  In this manner things like hashes and arrays are
# traversed depth-first.
sub _resolve_refs {
    my ( $self, $value ) = @_;
    if ( not ref $value ) {
        $value = $self->_resolve_scalar($value);
    }
    elsif (ref $value eq 'HASH' ) {
        $value = dclone($value);
        my @hidden = $self->_push_scope($value);
        for my $key ( keys %$value ) {
            $value->{$key} = $self->_resolve_refs( $value->{$key} );
        }
        $self->_pop_scope(@hidden);
        return $value;
    }
    elsif (ref $value eq 'ARRAY' ) {
        $value = dclone($value);
        for my $item (@$value) {
            $item = $self->_resolve_refs( $item );
        }
    }
    elsif (ref $value eq 'SCALAR' ) {
        $value = $self->_resolve_scalar($$value);
    } 
    else {
        my ($class, $type) = map ref, ($self, $value);
        die "${class}::_resolve_refs() can't handle $type references.";
    }

    return $value;
}

# List _push_scope(HashRef scope)
#
# Pushes a new scope onto the stack.  Variables in this scope are hidden from
# the seen stack.  This allows us to reference variables in the current scope
# even if they have the same name as a variable higher up in chain.  The
# hidden variables are returned.
sub _push_scope {
    my ( $self, $scope ) = @_;
    unshift @{ $self->{scope_stack} }, dclone($scope);
    my @hidden;
    for my $key ( keys %$scope ) {
        if ( exists $self->{seen}->{$key} ) {
            push @hidden, $key;
            delete $self->{seen}->{$key};
        }
    }
    return @hidden;
}

# void _pop_scope(@hidden)
#
# Removes the currently active scope from the stack and unhides any variables
# passed in via @hidden, which is usually returned from _push_scope.
sub _pop_scope {
    my ( $self, @hidden ) = @_;
    shift @{$self->{scope_stack}};
    for my $key ( @hidden ) {
        $self->{seen}->{$key} = 1;  # Unhide
    }
}

# void _resolve_scalar(String $value)
#
# This function should only be called with strings (or numbers), not
# references.  $value is treated as a string and is searched for $foo type
# variables, which are then resolved.  The new string with variables resolved
# is returned.
sub _resolve_scalar {
    my ( $self, $value ) = @_;
    return unless defined $value;
    my @parts = grep length, # Empty strings are useless, discard them
                     split /((?<!\\)\$(?:{\w+}|\w+))/, $value;
    for my $part (@parts) {
        if ( $part =~ /^(?<!\\)\$(?:{(\w+)}|(\w+))$/) {
            my $name = $1 || $2;
            $part = $self->_get($name) if $self->_scope_has($name);
        } else {
            # Unescape slashes.  Example: \\\$foo -> \\$foo, ditto with ${foo}
            $part =~ s/(\\*)\\(\$(?:{(\w+)}|(\w+)))/$1$2/g;
        }
    }
    return $parts[0] if @parts == 1 and ref $parts[0]; # Preserve references
    return join "", map { defined($_) ? $_ : "" } @parts;
}

# HashRef _scope(void)
#
# Returns the current scope.  There is always a currenty defined scope, even
# if it's just the global scope.
sub _scope {
    my $self = shift;
    return $self->{scope_stack}->[0] || $self->config;
}

# List _scope_stack(void)
#
# Returns the list of currently active scopes.  The list is ordered from inner
# most scope to outer most scope.  The global scope is always the last scope
# in the list.
sub _scope_stack {
    my $self = shift;
    return ( @{ $self->{scope_stack} }, $self->config );
}

# Boolean _get_from_scope(String key)
#
# This method returns true if the key is in any scope enclosing the current
# scope or in the current scope.  False otherwise.
sub _scope_has {
    my ( $self, $name ) = @_;
    for my $scope ( $self->_scope_stack ) {
        return 1 if exists $scope->{$name};
    }
    return 0;
}

# Scalar _get_from_scope(String key)
#
# Given a key this method returns its value as it's defined in the inner most
# enclosing scope containing the key.  That is to say, this method implements
# the dyanmic scoping lookup for key.
sub _get_from_scope {
    my ( $self, $key ) = @_;
    for my $scope ( $self->_scope_stack ) {
        return $scope->{$key} if exists $scope->{$key};
    }
    return undef;
}

# void _load_yaml_class
#
# Attempts to load a YAML class that can parse YAML for us.  We prefer the
# yaml_class attribute over everything, then fall back to a previously loaded
# YAML parser from @YAML_PREFS, and failing that try to load a parser from
# @YAML_PREFS.
sub _load_yaml_class {
    my $self = shift;

    # Always use what we were given.
    if (defined $self->{yaml_class}) {
        eval "require $self->{yaml_class}; 0;";
        croak "$@\n" if $@;
        return $self->{yaml_class};
    }

    # Use what's already been loaded.
    for my $module (@YAML_PREFS) {
        my $filename = $module . ".pm";
        $filename =~ s{::}{/};
        return $self->{yaml_class} = $module if exists $INC{$filename};
    }

    # Finally, try and load something.
    for my $module (@YAML_PREFS) {
        eval "require $module; 0;";
        return $self->{yaml_class} = $module unless $@;
    }

    die "Could not load: " . join(" or ", @YAML_PREFS);
}

# void _install_accessors(void)
#
# Installs convienence methods for getting and setting configuration values.
# These methods are just curryed versions of get() and set().
sub _install_accessors {
    my $self = shift;
    for my $key ($self->config_keys) {
        next unless $key and $key =~ /^[a-zA-Z_]\w*$/;
        for my $method (qw(get set)) {
            no strict 'refs';
            no warnings 'redefine';
            my $method_name = ref($self) . "::${method}_$key";
            *{$method_name} = sub { $_[0]->$method($key, $_[1]) };
        }
    }
}

1;
__END__

=encoding UTF-8

=head1 NAME

YAML::AppConfig - Manage configuration files with YAML and variable references.

=head1 SYNOPSIS

    use YAML::AppConfig;

    # An extended example.  YAML can also be loaded from a file.
    my $string = <<'YAML';
    ---
    root_dir: /opt
    etc_dir: $root_dir/etc
    cron_dir: $etc_dir/cron.d
    var_dir $root_dir/var
    var2_dir: ${var_dir}2
    usr: $root_dir/usr
    usr_local: $usr/local
    libs:
        system: $usr/lib
        local: $usr_local/lib
        perl:
            vendor: $system/perl
            site: $local/perl
    escape_example: $root_dir/\$var_dir/\\$var_dir
    YAML

    # Load the YAML::AppConfig from the given YAML.
    my $conf = YAML::AppConfig->new(string => $string);

    # Get settings in two different ways, both equivalent:
    $conf->get("etc_dir");    # returns /opt/etc
    $conf->get_etc_dir;       # returns /opt/etc

    # Get raw settings (with no interpolation) in three equivalent ways:
    $conf->get("etc_dir", 1); # returns '$root_dir/etc'
    $conf->get_etc_dir(1);    # returns '$root_dir/etc'
    $conf->config->{etc_dir}; # returns '$root_dir/etc'

    # Set etc_dir in three different ways, all equivalent.
    $conf->set("etc_dir", "/usr/local/etc");
    $conf->set_etc_dir("/usr/local/etc");
    $conf->config->{etc_dir} = "/usr/local/etc";

    # Changing a setting can affect other settings:
    $config->get_var2_dir;          # returns /opt/var2
    $config->set_var_dir('/var/');  # change var_dr, which var2_dir uses.
    $config->get_var2_dir;          # returns /var2

    # Variables are dynamically scoped:
    $config->get_libs->{perl}->{vendor};  # returns "/opt/usr/lib/perl"

    # As seen above, variables are live and not static:
    $config->usr_dir('cows are good: $root_dir');
    $config->get_usr_dir();               # returns "cows are good: /opt"
    $config->resolve('rm -fR $root_dir'); # returns "rm -fR /opt"

    # Variables can be escaped, to avoid accidental interpolation:
    $config->get_escape_example();  # returns "/opt/$var_dir/\$var_dir"

    # Merge in other configurations:
    my $yaml =<<'YAML';
    ---
    root_dir: cows
    foo: are good
    YAML
    $config->merge(string => $yaml);
    $config->get_root_dir();  # returns "cows"
    $config->get_foo();  # returns "are good"

    # Get the raw YAML for your current configuration:
    $config->dump();  # returns YAML as string
    $config->dump("./conf.yaml");  # Writes YAML to ./conf.yaml

=head1 DESCRIPTION

L<YAML::AppConfig> extends the work done in L<Config::YAML> and
L<YAML::ConfigFile> to allow more flexible configuration files.

Your configuration is stored in YAML and then parsed and presented to you via
L<YAML::AppConfig>.  Settings can be referenced using C<get> and C<set>
methods and settings can refer to one another by using variables of the form
C<$foo>, much in the style of C<AppConfig>.  See L</"USING VARIABLES"> below
for more details.

The underlying YAML parser is either L<YAML>, L<YAML::Syck> or one of your
choice.  See L</"THE YAML LIBRARY"> below for more information on how a YAML
parser is picked.

=head1 THE YAML LIBRARY

At this time there are two API compatible YAML libraries for Perl.  L<YAML>
and L<YAML::Syck>.  L<YAML::AppConfig> chooses which YAML parser to use as
follows:

=over

=item yaml_class

If C<yaml_class> is given to C<new> then it used above all other
considerations.  You can use this to force use of L<YAML> or L<YAML::Syck>
when L<YAML::AppConfig> isn't using the one you'd like.  You can also use it
specify your own YAML parser, as long as it's API compatible with L<YAML> and
L<YAML::Syck>.

=item The currently loaded YAML Parser

If you don't specify C<yaml_class> then L<YAML::AppConfig> will default to
using an already loaded YAML parser, e.g. one of L<YAML> or L<YAML::Syck>.  If
both are loaded then L<YAML::Syck> is preferred.

=item An installed YAML Parser.

If no YAML parser has already been loaded then L<YAML::AppConfig> will attempt
to load L<YAML::Syck> and failing that it will attempt to load L<YAML>.  If
both fail then L<YAML::AppConfig> will C<croak> when you create a new object
instance.

=back

=head1 USING VARIABLES

=head2 Variable Syntax

Variables refer to other settings inside the configuration file.
L<YAML::AppConfig> variables have the same form as scalar variables in Perl.
That is they begin with a dollar sign and then start with a letter or an
underscore and then have zero or more letters, numbers, or underscores which
follow.  For example, C<$foo>, C<$_bar>, and C<$cat_3> are all valid variable
names.

Variable names can also be contained in curly brackets so you can have a
variable side-by-side with text that might otherwise be read as the name of
the variable itself.  For example, C<${foo}bar> is the the variable C<$foo>
immediately followed by the literal text C<bar>.  Without the curly brackets
L<YAML::AppConfig> would assume the variable name was C<$foobar>, which is
incorrect.

Variables can also be escaped by using backslashes.  The text C<\$foo> will
resolve to the literal string C<$foo>.  Likewise C<\\$foo> will resolve to the
literal string C<\$foo>, and so on.

=head2 Variable Scoping

YAML is essentially a serialization language and so it follows that your
configuration file is just an easy to read serialization of some data
structure.  L<YAML::AppConfig> assumes the top most data structure is a hash
and that variables are keys in that hash, or in some hash contained within.

If every hash in the configuration file is thought of as a namespace then the
variables can be said to be dynamically scoped.  For example, consider the
following configuration file:

    ---
    foo: world
    bar: hello
    baz:
        - $foo
        - {foo: dogs, cats: $foo}
        - $foo $bar
    qux:
        quack: $baz
        
In this sample configuration the array contained by C<$baz> has two elements.
The first element resolves to the value C<hello>, the second element resolves
to the value "dogs", and the third element resolves to C<hello world>.

=head2 Variable Resolving

Variables can also refer to entire data structures.  For example, C<$quack>
will resolve to the same three element array as C<$baz>.  However, YAML
natively gives you this ability and then some.  So consider using YAML's
ability to take references to structures if L<YAML::AppConfig> is not
providing enough power for your use case.

In a L<YAML::AppConfig> object the variables are not resolved until you
retrieve the variable (e.g. using C<get()>.  This allows you to change
settings which are used by other settings and update many settings at once.
For example, if I call C<set("baz", "cows")> then C<get("quack")> will resolve
to C<cows>.

If a variable can not be resolved because it doesn't correspond to a key
currently in scope then the variable will be left verbatim in the text.
Consider this example:

    ---
    foo:
        bar: food
    qux:
        baz: $bar
        qix: $no_exist

In this example C<$baz> resolves to the literal string C<$bar> since C<$bar> is
not visible within the current scope where C<$baz> is used.  Likewise, C<$qix>
resolves to the literal string C<$no_exist> since there is no key in the
current scope named C<no_exist>.

=head1 METHODS

=head2 new(%args)

Creates a new YAML::AppConfig object and returns it.  new() accepts the
following key values pairs:

=over 8

=item file

The name of the file which contains your YAML configuration.

=item string

A string containing your YAML configuration.

=item object

A L<YAML::AppConfig> object which will be deep copied into your object.

=item no_resolve

If true no attempt at variable resolution is done on calls to C<get()>.

=item yaml_class

The name of the class we should use to find our C<LoadFile> and C<Load>
functions for parsing YAML files and strings, respectively.  The named class
should provide both C<LoadFile> and C<Load> as functions and should be loadable
via C<require>.

=back

=head2 get(key, [no_resolve])

Given C<$key> the value of that setting is returned, same as C<get_$key>.  If
C<$no_resolve> is true then the raw value associated with C<$key> is returned,
no variable interpolation is done.

It is assumed that C<$key> refers to a setting at the top level of the
configuration file.

=head2 set(key, value)

The setting C<$key> will have its value changed to C<$value>.  It is assumed
that C<$key> refers to a setting at the top level of the configuration file.

=head2 get_*([no_resolve])

Convenience methods to retrieve values using a method, see C<get>.  For
example if C<foo_bar> is a configuration key in top level of your YAML file
then C<get_foo_bar> retrieves its value.  These methods are curried versions
of C<get>.  These functions all take a single optional argument,
C<$no_resolve>, which is the same as C<get()'s> C<$no_resolve>.

=head2 set_*(value)

Convenience methods to set values using a method, see C<set> and C<get_*>.
These methods are curried versions of C<set>.

=head2 config

Returns the hash reference to the raw config hash.  None of the values are
interpolated, this is just the raw data.

=head2 config_keys

Returns the keys in C<config()> sorted from first to last.

=head2 merge(%args)

Merge takes another YAML configuration and merges it into this one.  C<%args>
are the same as those passed to C<new()>, so the configuration can come from a
file, string, or existing L<YAML::AppConfig> object.

=head2 resolve($scalar)

C<resolve()> runs the internal parser on non-reference scalars and returns the
result.  If the scalar is a reference then it is deep copied and a copy is
returned where the non-reference leaves of the data structure are parsed and
replaced as described in L</"USING VARIABLES">.

=head2 dump([$file])

Serializes the current configuration using the YAML parser's Dump or, if
C<$file> is given, DumpFile functions.  No interpolation is done, so the
configuration is saved raw.  Things like comments will be lost, just as they
would if you did C<Dump(Load($yaml))>, because that is what what calling
C<dump()> on an instantiated object amounts to.

=head1 AUTHORS

Matthew O'Connor E<lt>matthew@canonical.orgE<gt>

Original implementations by Kirrily "Skud" Robert (as L<YAML::ConfigFile>) and
Shawn Boyette (as L<Config::YAML>).

Currently maintained by Grzegorz Rożniecki E<lt>xaerxess@gmail.comE<gt>.

=head1 SEE ALSO

L<YAML>, L<YAML::Syck>, L<Config::YAML>, L<YAML::ConfigFile>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 Matthew O'Connor, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
