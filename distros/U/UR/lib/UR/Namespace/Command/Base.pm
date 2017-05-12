package UR::Namespace::Command::Base;
use strict;
use warnings;
use UR;

use Cwd;
use Carp;
use File::Find;

our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'Command::V1',
    is_abstract => 1,
    has => [ 
        namespace_name      =>  {   type => 'String',
                                    is_optional => 1,
                                    doc => 'Name of the Namespace to work in. Auto-detected if within a Namespace directory'
                                },
        lib_path            =>  {   type => "FilesystemPath",
                                    doc => "The directory in which the namespace module resides.  Auto-detected normally.",
                                    is_constant => 1,
                                    calculate_from => ['namespace_name'],
                                    calculate => q( # the namespace module should have gotten loaded in create()
                                                    my $namespace_module = $namespace_name;
                                                    $namespace_module =~ s#::#/#g;
                                                    my $namespace_path = Cwd::abs_path($INC{$namespace_module . ".pm"});
                                                    unless ($namespace_path) {
                                                        Carp::croak("Namespace module $namespace_name has not been loaded yet");
                                                    }
                                                    $namespace_path =~ s/\/[^\/]+.pm$//;
                                                    return $namespace_path;
                                                  ),
                                },
        working_subdir      =>  {   type => "FilesystemPath", 
                                    doc => 'The current working directory relative to lib_path',
                                    calculate => q( my $lib_path = $self->lib_path;
                                                    return UR::Util::path_relative_to($lib_path, Cwd::abs_path(Cwd::getcwd));
                                                  ),
                                },
        namespace_path      =>  { type => 'FilesystemPath',
                                  doc  => "The directory under which all the namespace's modules reside",
                                  is_constant => 1,
                                  calculate_from => ['namespace_name'],
                                  calculate => q(  my $lib_path = $self->lib_path;
                                                   return $lib_path . '/' . $namespace_name;
                                                ),
                                },
        verbose             =>  { type => "Boolean", is_optional => 1,
                                    doc => "Causes the command to show more detailed output."
                                },
    ],
    doc => 'a command which operates on classes/modules in a UR namespace directory'
);

sub create {
    my $class = shift;
    
    my ($rule,%extra) = $class->define_boolexpr(@_);
    my($namespace_name, $lib_path);
    if ($rule->specifies_value_for('namespace_name')) {
        $namespace_name = $rule->value_for('namespace_name');
        $lib_path = $class->resolve_lib_path_for_namespace_name($namespace_name);

    } else {
        ($namespace_name,$lib_path) = $class->resolve_namespace_name_from_cwd();
        unless ($namespace_name) {
            $class->error_message("Could not determine namespace name.");
            $class->error_message("Run this command from within a namespace subdirectory or use the --namespace-name command line option");
            return;
        }
        $rule = $rule->add_filter(namespace_name => $namespace_name);
    }

    # Use the namespace.
    $class->status_message("Loading namespace module $namespace_name") if ($rule->value_for('verbose'));

    # Ensure the right modules are visible to the command.
    # Make the module accessible.
    # We'd like to "use lib" this directory, but any other -I/use-lib
    # requests should still come ahead of it.  This requires a little munging.

    # Find the first thing in the compiled_inc list that exists
    my $compiled = '';
    for my $path ( UR::Util::compiled_inc() ) {
        next unless -d $path;
        $compiled = Cwd::abs_path($path);
        last if defined $compiled;
    }

    my $perl5lib = '';
    foreach my $path ( split(':', $ENV{'PERL5LIB'}) ) {
        next unless -d $path;
        $perl5lib = Cwd::abs_path($path);
        last if defined $perl5lib;
    }

    my $i;
    for ($i = 0; $i < @INC; $i++) {
        # Find the index in @INC that's the first thing in
        # compiled-in module paths
        #
        # since abs_path returns undef for non-existant dirs,
        # skip the comparison if either is undef
        my $inc = Cwd::abs_path($INC[$i]);
        next unless defined $inc;
        last if ($inc eq $compiled or $inc eq $perl5lib);
    }
    splice(@INC, $i, 0, $lib_path);
    eval "use $namespace_name";
    if ($@) {
        $class->error_message("Error using namespace module '$namespace_name': $@");
        return;
    }

    my $self = $class->SUPER::create($rule);
    return unless $self;

    unless (eval { UR::Namespace->get($namespace_name) }) {
        $self->error_message("Namespace '$namespace_name' was not found");
        return;
    }

    if ($namespace_name->can("_set_context_for_schema_updates")) {
        $namespace_name->_set_context_for_schema_updates();
    }

    return $self;
}

sub command_name {
    my $class = shift;
    return "ur" if $class eq __PACKAGE__;
    my $name = $class->SUPER::command_name;
    $name =~ s/^u-r namespace/ur/;
    return $name;
}

sub help_detail {
    return shift->help_brief
}

# Return a list of module pathnames relative to lib_path
sub _modules_in_tree {
    my $self = shift;
    my @modules;

    my $lib_path = $self->lib_path;
    my $namespace_path = $self->namespace_path;

    my $wanted_closure = sub {
                             if (-f $_ and m/\.pm$/) {
                                 push @modules, UR::Util::path_relative_to($lib_path, $_);
                             }
                        };
    unless (@_) {
        File::Find::find({ no_chdir => 1,
                           wanted => $wanted_closure,
                         },
                         $namespace_path);
    }
    else {
        # this method takes either module paths or class names as params
        # normalize to module paths


        NAME:
        for (my $i = 0; $i < @_; $i++) {
            my $name = $_[$i];

            if ($name =~ m/::/) {
                # It's a class name
                my @name_parts = split(/::/, $name);
                unless ($self->namespace_name eq $name_parts[0]) {
                    $self->warning_message("Skipping class name $name: Not in namespace ".$self->namespace_name);
                    next NAME;
                }
                $name = join('/', @name_parts) . ".pm";
            }

            # First, check the pathname relative to the cwd
            CHECK_LIB_PATH:
            foreach my $check_name ( $name, $lib_path.'/'.$name, $namespace_path.'/'.$name) {
                if (-e $check_name) {
                    if (-f $check_name and $check_name =~ m/\.pm$/) {
                        push @modules, UR::Util::path_relative_to($lib_path, $check_name);
                        next NAME;  # found it, don't check the other $check_name

                    } elsif (-d $check_name) {
                        File::Find::find({ no_chdir => 1,
                                           wanted => $wanted_closure,
                                         },
                                         $check_name);
                    } elsif (-e $check_name) {
                        $self->warning_message("Ignoring non-module $check_name");
                        next CHECK_LIB_PATH;
                    }
                }

            }
        }
    }
    return @modules;
}

sub _class_names_in_tree {
    my $self = shift;
    my @modules = $self->_modules_in_tree(@_);
    my $lib_path = $self->lib_path;
    my @class_names;
    for my $module (@modules) {
        my $class = $module;
        $class =~ s/^$lib_path\///;
        $class =~ s/\//::/g;
        $class =~ s/\.pm$//;

        # Paths can have invalid package names so are therefore packages in
        # another "namespace" and should not be included.
        next unless UR::Util::is_valid_class_name($class);

        push @class_names, $class;
    }
    return @class_names;
}

sub _class_objects_in_tree {
    my $self = shift;
    my @class_names = $self->_class_names_in_tree(@_);
    my @class_objects;
    for my $class_name (sort { uc($a) cmp uc($b) } @class_names) {
        unless(UR::Object::Type->use_module_with_namespace_constraints($class_name)) {
        #if ($@) {
            print STDERR "Failed to use class $class_name!\n";
            print STDERR $@,"\n";
            next;
        }
        my $c = UR::Object::Type->is_loaded(class_name => $class_name);
        unless ($c) {
            #print STDERR "Failed to find class object for class $class_name\n";
            next;
        }
        push @class_objects, $c;
        #print $class_name,"\n";
    }
    return @class_objects;
}

# Tries to guess what namespace you are in from your current working
# directory.  When called in list context, it also returns the directroy
# name the namespace module was found in
sub resolve_namespace_name_from_cwd {
    my $class = shift;
    my $cwd = shift;
    $cwd ||= Cwd::cwd();

    my @lib = grep { length($_) } split(/\//,$cwd);

    SUBDIR:
    while (@lib) {
        my $namespace_name = pop @lib;

        my $lib_path = "/" . join("/",@lib);
        my $namespace_module_path = $lib_path . '/' . $namespace_name . '.pm';
        if (-e $namespace_module_path) {
            if ($class->_is_file_the_namespace_module($namespace_name, $namespace_module_path)) {
                if (wantarray) {
                    return ($namespace_name, $lib_path);
                } else {
                    return $namespace_name;
                }
            }
        }
    }
    return;
}

# Returns true if the given file is the namespace module we're looking for.
# The only certain way is to go ahead and load it, but this should be good
# enough for ligitimate use cases.
sub _is_file_the_namespace_module {
    my($class,$namespace_name,$namespace_module_path) = @_;

    my $fh = IO::File->new($namespace_module_path);
    return unless $fh;
    while (my $line = $fh->getline) {
        if ($line =~ m/package\s+$namespace_name\s*;/) {
            # At this point $namespace_name should be a plain word with no ':'s
            # and if the file sets the package to a single word with no colons,
            # it's pretty likely that it's a namespace module.
            return 1;
        }
    }
    return;
}


# Return the pathname that the specified namespace module can be found
sub resolve_lib_path_for_namespace_name {
    my($class,$namespace_name,$cwd) = @_;

    unless ($namespace_name) {
        Carp::croak('namespace name is a required argument for UR::Util::resolve_lib_path_for_namespace_name()');
    }

    # first, see if we're in a namespace dir
    my($resolved_ns_name, $lib_path ) = $class->resolve_namespace_name_from_cwd($cwd);
    return $lib_path if (defined($resolved_ns_name) and $resolved_ns_name eq $namespace_name);

    foreach $lib_path ( @main::INC ) {
        my $expected_namespace_module = $lib_path . '/' . $namespace_name . '.pm';
        $expected_namespace_module =~ s/::/\//g;  # swap :: for /
        if ( $class->_is_file_the_namespace_module($namespace_name, $expected_namespace_module)) {
            return $lib_path;
        }
    }
    return;
}

1;


=pod

=head1 NAME

UR::Namespace::Command - Top-level Command module for the UR namespace commands

=head1 DESCRIPTION

This class is the parent class for all the namespace-manipluation command
modules, and the root for command handling behind the 'ur' command-line
script.  

There are several sub-commands for manipluating a namespace's metadata.

=over 4

=item browser 

Start a lightweight web server for viewing class and schema information

=item commit

Update data source schemas based on the current class structure

=item define

Define metadata instances such as classes, data sources or namespaces

=item describe

Get detailed information about a class

=item diff

Show a diff for various kinds of other ur commands.

=item info

Show brief information about class or schema metadata

=item list

List various types of things

=item redescribe

Outputs class description(s) formatted to the latest standard

=item rename

Rename logical schema elements.

=item rewrite

Rewrites class descriptions headers to normalize manual changes.

=item test

Sub-commands related to testing

=item update

Update metadata based on external data sources

=back

Some of these commands have sub-commands of their own.  You can get more
detailed information by typing 'ur <command> --help' at the command line.

=head1 SEE ALSO

Command, UR, UR::Namespace

=cut

