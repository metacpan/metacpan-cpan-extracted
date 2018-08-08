package UR;


# The UR module is itself a "UR::Namespace", besides being the root
# module which bootstraps the system.  The class definition itself
# is made at the bottom of the file.

use strict;
use warnings FATAL => 'all';

# Set the version at compile time, since some other modules borrow it.
our $VERSION = "0.47"; # UR $VERSION

# Ensure we get detailed errors while starting up.
# This is disabled at the bottom of the module.
use Carp;
$SIG{__DIE__} = \&Carp::confess;

# Ensure that, if the application changes directory, we do not
# change where we load modules while running.
use Cwd;
my @PERL5LIB = ($ENV{PERL5LIB} ? split(':', $ENV{PERL5LIB}) : ());
for my $dir (@INC, @PERL5LIB) {
    next unless -d $dir;
    $dir = Cwd::abs_path($dir) || $dir;
}
$ENV{PERL5LIB} = join(':', @PERL5LIB);

# Also need to fix modules that were already loaded, so that when
# a namespace is loaded the path will not change out from
# underneath it.
for my $module (keys %INC) {
    $INC{$module} = Cwd::abs_path($INC{$module});
}

# UR supports several environment variables, found under UR/ENV
# Any UR_* variable which is set but does NOT corresponde to a module found will cause an exit
# (a hedge against typos such as UR_DBI_NO_COMMMMIT=1 leading to unexpected behavior)
for my $e (keys %ENV) {
    next unless substr($e,0,3) eq 'UR_';
    eval "use UR::Env::$e";
    if ($@) {
        my $path = __FILE__;
        $path =~ s/.pm$//;
        my @files = glob("\Q${path}\E/Env/*");
        my @vars = map { /UR\/Env\/(.*).pm/; $1 } @files;
        print STDERR "Environment variable $e set to $ENV{$e} but there were errors using UR::Env::$e:\n"
        . "Available variables:\n\t"
        . join("\n\t",@vars)
        . "\n";
        exit 1;
    }
}

# These two dump info about used modules and libraries at program exit.
END {
    if ($ENV{UR_USED_LIBS}) {
        print STDERR "Used library include paths (\@INC):\n";
        for my $lib (@INC) {
            print STDERR "$lib\n";
        }
        print STDERR "\n";
    }
    if ($ENV{UR_USED_MODS}) {
        print STDERR "Used modules and paths (\%INC):\n";
        for my $mod (sort keys %INC) {
            if ($ENV{UR_USED_MODS} > 1) {
                print STDERR "$mod => $INC{$mod}\n";
            } else {
                print STDERR "$mod\n";
            }
        }
        print STDERR "\n";
    }
    if ($ENV{UR_DBI_SUMMARIZE_SQL}) {
        UR::DBI::print_sql_summary();
    }
}

#Class::AutoloadCAN must be used before Class::Autouse, or the can methods will break in confusing ways.
use Class::AutoloadCAN;
use Class::Autouse;
BEGIN {
    my $v = $Class::Autouse::VERSION;
    unless (($v =~ /^\d+\.?\d*$/ && $v >= 2.0)
            or $v eq '1.99_02'
            or $v eq '1.99_04') {
        die "UR requires Class::Autouse 2.0 or greater (or 1.99_02 or 1.99_04)!!";
    }
};

# Regular deps
use Date::Format;

#
# Because UR modules execute code when compiling to define their classes,
# and require each other for that code to execute, there are bootstrapping
# problems.
#
# Everything which is part of the core framework "requires" UR
# which, of course, executes AFTER it has compiled its SUBS,
# but BEFORE it defines its class.
#
# Everything which _uses_ the core of the framework "uses" its namespace,
# either the specific top-level namespace module, or "UR" itself for components/extensions.
#

require UR::Exit;
require UR::Util;

require UR::DBI::Report;         # this is used by UR::DBI
require UR::DBI;            # this needs a new name, and need only be used by UR::DataSource::RDBMS

require UR::ModuleBase;     # this should be switched to a role
require UR::ModuleConfig;   # used by ::Time, and also ::Lock ::Daemon

require UR::Object::Iterator;
require UR::Context::AutoUnloadPool;
require UR::DeletedRef;

require UR::Object;
require UR::Object::Type;

require UR::Object::Ghost;
require UR::Object::Property;

require UR::Observer;

require UR::BoolExpr::Util;
require UR::BoolExpr;                                  # has meta
require UR::BoolExpr::Template;                        # has meta
require UR::BoolExpr::Template::PropertyComparison;    # has meta
require UR::BoolExpr::Template::Composite;             # has meta
require UR::BoolExpr::Template::And;                   # has meta
require UR::BoolExpr::Template::Or;                    # has meta

require UR::Object::Index;

#
# Define core metadata.
#
# This is done outside of the actual modules since the define() method
# uses all of the modules themselves to do its work.
#

UR::Object::Type->define(
    class_name => 'UR::Object',
    is => [], # the default is to inherit from UR::Object, which is circular, so we explicitly say nothing
    is_abstract => 1,
    composite_id_separator => "\t",
    id_by => [
        id  => { is => 'Scalar', doc => 'unique identifier' }
    ],
    id_generator => '-urinternal',
);

UR::Object::Type->define(
    class_name => "UR::Object::Index",
    id_by => ['indexed_class_name','indexed_property_string'],
    has => ['indexed_class_name','indexed_property_string'],
    is_transactional => 0,
);

UR::Object::Type->define(
    class_name => 'UR::Object::Ghost',
    is_abstract => 1,
);

UR::Object::Type->define(
    class_name => 'UR::Entity',
    extends => ['UR::Object'],
    is_abstract => 1,
);

UR::Object::Type->define(
    class_name => 'UR::Entity::Ghost',
    extends => ['UR::Object::Ghost'],
    is_abstract => 1,
);

# MORE METADATA CLASSES

# For bootstrapping reasons, the properties with default values also need to be listed in
# %class_property_defaults defined in UR::Object::Type::Initializer.  If you make changes
# to default values, please keep these in sync.

UR::Object::Type->define(
    class_name => 'UR::Object::Type',
    doc => 'class/type meta-objects for UR',

    id_by => 'class_name',
    sub_classification_method_name => '_resolve_meta_class_name',
    is_abstract => 1,

    has => [
        class_name                       => { is => 'Text', len => 256, is_optional => 1,
                                                doc => 'the name for the class described' },

        properties                       => {
                                                is_many => 1,

                                                # this is calculated instead of a regular relationship
                                                # so we can do appropriate inheritance filtering.
                                                # We need an isa operator and its converse
                                                # in order to be fully declarative internally here
                                                calculate => 'shift->_properties(@_);',

                                                doc => 'property meta-objects for the class'
                                            },
        id_properties                    => { is_many => 1,
                                              calculate => q( grep { defined $_->is_id } shift->_properties(@_) ),
                                              doc => 'meta-objects for the ID properties of the class' },

        doc                              => { is => 'Text', len => 1024, is_optional => 1,
                                                doc => 'a one-line description of the class/type' },

        is_abstract                      => { is => 'Boolean', default_value => 0,
                                                doc => 'abstract classes must be subclassified into a concreate class at create/load time' },

        is_final                         => { is => 'Boolean', default_value => 0,
                                                doc => 'further subclassification is prohibited on final classes' },

        is_transactional                 => { is => 'Boolean', default_value => 1, is_optional => 1,
                                                doc => 'non-transactional objects are left out of in-memory transactions' },

        is_singleton                     => { is => 'Boolean', default_value => 0,
                                                doc => 'singleton classes have only one instance, or have each instance fall into a distinct subclass' },

        namespace                        => { is => 'Text', len => 256, is_optional => 1,
                                                doc => 'the first "word" in the class name, which points to a UR::Namespace' },

        schema_name                      => { is => 'Text', len => 256, is_optional => 1,
                                                doc => 'an arbitrary grouping for classes for which instances share a common storage system' },

        data_source_id                   => { is => 'Text', len => 256, is_optional => 1,
                                                doc => 'for classes which persist beyond their current process, the identifier for their storage manager' },

        #data_source_meta                => { is => 'UR::DataSource', id_by => 'data_source_id', is_optional => 1,  },

        generated                        => { is => 'Boolean', is_transient => 1, default_value => 0,
                                                doc => 'an internal flag set when the class meta has fabricated accessors and methods in the class namespace' },

        meta_class_name                  => { is => 'Text',
                                                doc => 'even meta-classess have a meta-class' },

        composite_id_separator           => { is => 'Text', len => 2 , default_value => "\t", is_optional => 1,
                                                doc => 'for classes whose objects have a multi-value "id", this overrides using a "\t" to compose/decompose' },

        valid_signals                    => { is => 'ARRAY', is_optional => 1,
                                                doc => 'List of non-standard signal names observers can bind to ' },
        # details used by the managment of the "real" entity outside of the app (persistence)
        table_name                       => { is => 'Text', len => undef, is_optional => 1,
                                                doc => 'for classes with a data source, this specifies the table or equivalent data structure which holds instances' },

        select_hint                       => { is => 'Text', len => 1024 , is_optional => 1,
                                                doc => 'used to optimize access to underlying storage (database specific)' },

        join_hint                        => { is => 'Text', len => 1024 , is_optional => 1,
                                                doc => 'used to optimize access to underlying storage when this class is part of a join (database specific)' },

        id_generator                     => { is => 'Text', len => 256, is_optional => 1,
                                                doc => 'override the default choice for generating new object IDs' },

        # different ways of handling subclassing at object load time
        subclassify_by                      => { is => 'Text', len => 256, is_optional => 1,
                                                doc => 'when set, the method specified will return the name of a specific subclass into which the object should go' },

        subclass_description_preprocessor   => { is => 'MethodName', len => 255, is_optional => 1,
                                                doc => 'a method which should pre-process the class description of sub-classes before construction' },

        sub_classification_method_name      => { is => 'Text', len => 256, is_optional => 1,
                                                doc => 'like subclassify_by, but examines whole objects not a single property' },

        use_parallel_versions               => { is => 'Boolean', is_optional => 1, default_value => 0,
                                                doc => 'inheriting from the is class will redirect to a ::V? module implemeting a specific version' },

        # obsolete/internal
        type_name                               => { is => 'Text', len => 256, is_deprecated => 1, is_optional => 1 },
        er_role                                 => { is => 'Text', len => 256, is_optional => 1,  default_value => 'entity' },
        source                                  => { is => 'Text', len => 256 , default_value => 'data dictionary', is_optional => 1 }, # This is obsolete and should be removed later
        sub_classification_meta_class_name      => { is => 'Text', len => 1024 , is_optional => 1,
                                                    doc => 'obsolete' },
        first_sub_classification_method_name    => { is => 'Text', len => 256, is_optional => 1,
                                                    doc => 'cached value to handle a complex inheritance hierarchy with storage at some levels but not others' },


        ### Relationships with the other meta-classes (used internally) ###

        # UR::Namespaces are singletons referenced through their name
        namespace_meta                  => { is => 'UR::Namespace', id_by => 'namespace' },
        is                              => { is => 'ARRAY', is_mutable => 0, doc => 'List of the parent class names' },
        roles                           => { is => 'ARRAY', is_mutable => 0, is_optional => 1, doc => 'List of the roles consumed by this class' },

        # linking to the direct parents, and the complete ancestry
        parent_class_metas              => { is => 'UR::Object::Type', id_by => 'is',
                                             doc => 'The list of UR::Object::Type objects for the classes that are direct parents of this class' },#, is_many => 1 },
        parent_class_names              => { via => 'parent_class_metas', to => 'class_name', is_many => 1 },
        parent_meta_class_names         => { via => 'parent_class_metas', to => 'meta_class_name', is_many => 1 },
        ancestry_meta_class_names       => { via => 'ancestry_class_metas', to => 'meta_class_name', is_many => 1 },
        ancestry_class_metas            => { is => 'UR::Object::Type', id_by => 'is',  where => [-recurse => [class_name => 'is']],
                                             doc => 'Climb the ancestry tree and return the class objects for all of them' },
        ancestry_class_names            => { via => 'ancestry_class_metas', to => 'class_name', is_many => 1 },

        # This one isn't useful on its own, but is used to build the all_* accessors below
        all_class_metas                 => { is => 'UR::Object::Type', calculate => 'return ($self, $self->ancestry_class_metas)' },

        # Properties defined on this class, parent classes, etc.
        # There's also a property_meta_by_name() method defined in the class
        direct_property_metas            => { is => 'UR::Object::Property', reverse_as => 'class_meta', is_many => 1 },
        direct_property_names            => { via => 'direct_property_metas', to => 'property_name', is_many => 1 },
        direct_id_property_metas         => { is => 'UR::Object::Property', reverse_as => 'class_meta', where => [ 'is_id true' => 1, -order_by => 'is_id' ], is_many => 1 },
        direct_id_property_names         => { via => 'direct_id_property_metas', to => 'property_name', is_many => 1 },

        ancestry_property_metas          => { via => 'ancestry_class_metas', to => 'direct_property_metas', is_many => 1 },
        ancestry_property_names          => { via => 'ancestry_class_metas', to => 'direct_property_names', is_many => 1 },
        ancestry_id_property_metas       => { via => 'ancestry_class_metas', to => 'direct_id_property_metas', is_many => 1 },
        ancestry_id_property_names       => { via => 'ancestry_id_property_metas', to => 'property_name', is_many => 1 },

        all_property_metas               => { via => 'all_class_metas', to => 'direct_property_metas', is_many => 1 },
        all_property_names               => { via => 'all_property_metas', to => 'property_name', is_many => 1 },
        all_id_property_metas            => { via => 'all_class_metas', to => 'direct_id_property_metas', is_many => 1 },
        all_id_property_names            => { via => 'all_id_property_metas', to => 'property_name', is_many => 1 },

        direct_id_by_property_metas      => { via => 'direct_property_metas', to => '__self__', where => ['id_by true' => 1], is_many => 1, doc => "Properties with 'id_by' metadata, ie. direct object accessor properties" } ,
        all_id_by_property_metas         => { via => 'all_class_metas', to => 'direct_id_by_property_metas', is_many => 1},
        direct_reverse_as_property_metas => { via => 'direct_property_metas', to => '__self__', where => ['reverse_as true' => 1], is_many => 1, doc => "Properties with 'reverse_as' metadata, ie. indirect object accessor properties" },
        all_reverse_as_property_metas    => { via => 'all_class_metas', to => 'direct_reverse_as_property_metas', is_many => 1},

        # Datasource related stuff
        direct_column_names              => { via => 'direct_property_metas', to => 'column_name', is_many => 1, where => [column_name => { operator => 'true' }] },
        direct_id_column_names           => { via => 'direct_id_property_metas', to => 'column_name', is_many => 1, where => [column_name => { operator => 'true'}] },
        ancestry_column_names            => { via => 'ancestry_class_metas', to => 'direct_column_names', is_many => 1 },
        ancestry_id_column_names         => { via => 'ancestry_class_metas', to => 'direct_id_column_names', is_many => 1 },

        # Are these *columnless* properties actually necessary?  The user could just use direct_property_metas(column_name => undef)
        direct_columnless_property_metas => { is => 'UR::Object::Property', reverse_as => 'class_meta', where => [column_name => undef], is_many => 1 },
        direct_columnless_property_names => { via => 'direct_columnless_property_metas', to => 'property_name', is_many => 1 },
        ancestry_columnless_property_metas => { via => 'ancestry_class_metas', to => 'direct_columnless_property_metas', is_many => 1 },
        ancestry_columnless_property_names => { via => 'ancestry_columnless_property_metas', to => 'property_name', is_many => 1 },
        ancestry_table_names             => { via => 'ancestry_class_metas', to => 'table_name', is_many => 1 },
        all_table_names                  => { via => 'all_class_metas', to => 'table_name', is_many => 1 },
        all_column_names                 => { via => 'all_class_metas', to => 'direct_column_names', is_many => 1 },
        all_id_column_names              => { via => 'all_class_metas', to => 'direct_id_column_names', is_many => 1 },
        all_columnless_property_metas    => { via => 'all_class_metas', to => 'direct_columnless_property_metas', is_many => 1 },
        all_columnless_property_names    => { via => 'all_class_metas', to => 'direct_columnless_property_names', is_many => 1 },
    ],
);

UR::Object::Type->define(
    class_name => 'UR::Object::Property',
    id_properties => [
        class_name                      => { is => 'Text', len => 256 },
        property_name                   => { is => 'Text', len => 256 },
    ],
    has_optional => [
        property_type                   => { is => 'Text', len => 256 , is_optional => 1},
        column_name                     => { is => 'Text', len => 256, is_optional => 1 },
        data_length                     => { is => 'Text', len => 32, is_optional => 1 },
        data_type                       => { is => 'Text', len => 256, is_optional => 1 },
        calculated_default              => { is_optional => 1 },
        default_value                   => { is_optional => 1 },
        valid_values                    => { is => 'ARRAY', is_optional => 1, },
        example_values                  => { is => 'ARRAY', is_optional => 1, doc => 'example valid values; used to generate help text for Commands' },
        doc                             => { is => 'Text', len => 1000, is_optional => 1 },
        is_id                           => { is => 'Integer', default_value => undef, doc => 'denotes this is an ID property of the class, and ranks them' },
        is_optional                     => { is => 'Boolean' , default_value => 0},
        is_transient                    => { is => 'Boolean' , default_value => 0},
        is_constant                     => { is => 'Boolean' , default_value => 0},  # never changes
        is_mutable                      => { is => 'Boolean' , default_value => 1},  # can be changed explicitly via accessor (cannot be constant)
        is_volatile                     => { is => 'Boolean' , default_value => 0},  # changes w/o a signal: (cannot be constant or transactional)
        is_classwide                    => { is => 'Boolean' , default_value => 0},
        is_delegated                    => { is => 'Boolean' , default_value => 0},
        is_calculated                   => { is => 'Boolean' , default_value => 0},
        is_transactional                => { is => 'Boolean' , default_value => 1},  # STM works on these, and the object can possibly save outside the app
        is_abstract                     => { is => 'Boolean' , default_value => 0},
        is_concrete                     => { is => 'Boolean' , default_value => 1},
        is_final                        => { is => 'Boolean' , default_value => 0},
        is_many                         => { is => 'Boolean' , default_value => 0},
        is_aggregate                    => { is => 'Boolean' , default_value => 0},
        is_deprecated                   => { is => 'Boolean', default_value => 0},
        is_numeric                      => { calculate_from => ['data_type'], },
        id_by                           => { is => 'ARRAY', is_optional => 1},
        id_class_by                     => { is => 'Text', is_optional => 1},
        is_undocumented                 => { is => 'Boolean', is_optional => 1, doc => 'do not show in documentation to users' },
        doc_position                    => { is => 'Number', is_optional => 1, doc => 'override the sort position within documentation' },
        access_as                       => { is => 'Text', is_optional => 1, doc => 'when id_class_by is set, and this is set to "auto", primitives will return as their ID instead of boxed' },
        order_by                        => { is => 'ARRAY', is_optional => 1},
        specify_by                      => { is => 'Text', is_optional => 1},
        reverse_as                      => { is => 'ARRAY', is_optional => 1 },
        implied_by                      => { is => 'Text' , is_optional => 1},
        via                             => { is => 'Text' , is_optional => 1 },
        to                              => { is => 'Text' , is_optional => 1},
        where                           => { is => 'ARRAY', is_optional => 1},
        calculate                       => { is => 'Text' , is_optional => 1},
        calculate_from                  => { is => 'ARRAY' , is_optional => 1},
        calculate_perl                  => { is => 'Perl' , is_optional => 1},
        calculate_sql                   => { is => 'SQL'  , is_optional => 1},
        calculate_js                    => { is => 'JavaScript' , is_optional => 1},
        constraint_name                 => { is => 'Text' , is_optional => 1},
        is_legacy_eav                   => { is => 'Boolean' , is_optional => 1},
        is_dimension                    => { is => 'Boolean', is_optional => 1},
        is_specified_in_module_header   => { is => 'Boolean', default_value => 0 },
        position_in_module_header       => { is => 'Integer', is_optional => 1, doc => "Line in the class definition source's section this property appears" },
        singular_name                   => { is => 'Text' },
        plural_name                     => { is => 'Text' },

        class_meta                      => { is => 'UR::Object::Type', id_by => 'class_name' },
        r_class_meta                    => { is => 'UR::Object::Type', id_by => 'data_type' },
    ],
    unique_constraints => [
        { properties => [qw/property_name class_name/], sql => 'SUPER_FAKE_O4' },
    ],
);


UR::Object::Type->define(
    class_name => 'UR::Object::Property::Calculated::From',
    id_properties => [qw/class_name calculated_property_name source_property_name/],
);

require UR::Singleton;
require UR::Namespace;

UR::Object::Type->define(
    class_name => 'UR',
    extends => ['UR::Namespace'],
);

require UR::Context;
UR::Object::Type->initialize_bootstrap_classes;

require UR::Role;
require Command;

$UR::initialized = 1;

require UR::Change;
require UR::Context::Root;
require UR::Context::Process;
require UR::Object::Tag;

do {
    UR::Context->_initialize_for_current_process();
};

require UR::ModuleLoader;   # signs us up with Class::Autouse
require UR::Value::Iterator;
require UR::Object::View;
require UR::Object::Join;

sub main::ur_core {
    print STDERR "Dumping rules and templates to ./ur_core.stor...\n";
    my $dump;
    unless(open($dump, ">ur_core.stor")) {
        print STDERR "Can't open ur_core.stor for writing: $!";
        exit;
    }
    store_fd([
               $UR::Object::rule_templates,
               $UR::Object::rules,
              ],
             $dump);
    close $dump;
    exit();
}

1;
__END__

=pod

=head1 NAME

UR - rich declarative transactional objects

=head1 VERSION

This document describes UR version 0.47

=head1 SYNOPSIS

    use UR;

    ## no database

    class Foo { is => 'Bar', has => [qw/prop1 prop2 prop3/] };

    $o1 = Foo->create(prop1 => 111, prop2 => 222, prop3 => 333);

    @o = Foo->get(prop2 => 222, prop1 => [101,111,121], 'prop3 between' => [200, 400]);
    # returns one object

    $o1->delete;

    @o = Foo->get(prop2 => 222, prop1 => [101,111,121], 'prop3 between' => [200, 400]);
    # returns zero objects

    @o = Foo->get(prop2 => 222, prop1 => [101,111,121], 'prop3 between' => [200, 400]);
    # returns one object again

    ## database

    class Animal {
        has => [
            favorite_food => { is => 'Text', doc => "what's yummy?" },
        ],
        data_source => 'MyDB1',
        table_name => 'Animal'
    };

    class Cat {
        is => 'Animal',
        has => [
            feet    => { is => 'Number', default_value => 4 },
            fur     => { is => 'Text', valid_values => [qw/fluffy scruffy/] },
        ],
        data_source => 'MyDB1',
        table_name => 'Cat'
    };

    Cat->create(feet => 4, fur => 'fluffy', favorite_food => 'taters');

    @cats = Cat->get(favorite_food => ['taters','sea bass']);

    $c = $cats[0];

    print $c->feet,"\n";

    $c->fur('scruffy');

    UR::Context->commit();


=head1 DESCRIPTION

UR is a class framework and object/relational mapper for Perl.  It starts
with the familiar Perl meme of the blessed hash reference as the basis for
object instances, and extends its capabilities with ORM (object-relational
mapping) capabilities, object cache, in-memory transactions, more formal
class definitions, metadata, documentation system, iterators, command line
tools, etc.

UR can handle multiple column primary and foreign keys, SQL joins involving
class inheritance and relationships, and does its best to avoid querying
the database unless the requested data has not been loaded before.  It has
support for SQLite, Oracle, Mysql and Postgres databases, and the ability
to use a text file as a table.

UR uses the same syntax to define non-persistent objects, and supports
in-memory transactions for both.

=head1 DOCUMENTATION

=head2 Manuals

L<ur> - command line interface

L<UR::Manual::Overview> - UR from Ten Thousand Feet

L<UR::Manual::Tutorial> - Getting started with UR

L<UR::Manual::Presentation> - Slides for a presentation on UR

L<UR::Manual::Cookbook> - Recepies for getting stuff working

L<UR::Manual::Metadata> - UR's metadata system

L<UR::Object::Type::Initializer> - Defining classes

=head2 Basic Entities

L<UR::Object> - Pretty much everything is-a UR::Object

L<UR::Object::Type> - Metadata class for Classes

L<UR::Object::Property> - Metadata class for Properties

L<UR::Namespace> - Manage packages and classes

L<UR::Context> - Software transactions and More!

L<UR::DataSource> - How and where to get data

=head1 QUICK TUTORIAL

First create a Namespace class for your application, Music.pm:

    package Music;
    use UR;

    class Music {
        is => 'UR::Namespace'
    };

    1;

Next, define a data source representing your database, Music/DataSource/DB1.pm

    package Music::DataSource::DB1;
    use Music;

    class Music::DataSource::DB1 {
        is => ['UR::DataSource::MySQL', 'UR::Singleton'],
        has_constant => [
            server  => { value => 'database=music' },
            owner   => { value => 'music' },
            login   => { value => 'mysqluser' },
            auth    => { value => 'mysqlpasswd' },
        ]
    };

    or to get something going quickly, SQLite has smart defaults...

    class Music::DataSource::DB1 {
        is => ['UR::DataSource::SQLite', 'UR::Singleton'],
    };


Create a class to represent artists, who have many CDs, in Music/Artist.pm

    package Music::Artist;
    use Music;

    class Music::Artist {
        id_by => 'artist_id',
        has => [
            name => { is => 'Text' },
            cds  => { is => 'Music::Cd', is_many => 1, reverse_as => 'artist' }
        ],
        data_source => 'Music::DataSource::DB1',
        table_name => 'ARTIST',
    };

Create a class to represent CDs, in Music/Cd.pm

    package Music::Cd;
    use Music;

    class Music::Cd {
        id_by => 'cd_id',
        has => [
            artist => { is => 'Music::Artist', id_by => 'artist_id' },
            title  => { is => 'Text' },
            year   => { is => 'Integer' },
            artist_name => { via => 'artist', to => 'name' },
        ],
        data_source => 'Music::DataSource::DB1',
        table_name => 'CD',
    };


If the database does not exist, you can run this to generate the tables and columns from the classes you've written
(very experimental):

  $ cd Music
  $ ur update schema

If the database existed already, you could have done this to get it to write the last 2 classes for you:

  $ cd Music;
  $ ur update classes

Regardless, if the classes and database tables are present, you can then use these classes in your application code:

    # Using the namespace enables auto-loading of modules upon first attempt to call a method
    use Music;

    # This would get back all Artist objects:
    my @all_artists = Music::Artist->get();

    # After the above, further requests would be cached
    # if that set were large though, you might want to iterate gradually:
    my $artist_iter = Music::Artist->create_iterator();

    # Get the first object off of the iterator
    my $first_artist = $artist_iter->next();

    # Get all the CDs published in 2007 for the first artist
    my @cds_2007 = Music::Cd->get(year => 2007, artist => $first_artist);

    # Use non-equality operators:
    my @some_cds = Music::Cd->get(
        'year between' => ['2004','2009']
    );

    # This will use a JOIN with the ARTISTS table internally to filter
    # the data in the database.  @some_cds will contain Music::Cd objects.
    # As a side effect, related Artist objects will be loaded into the cache
    @some_cds = Music::Cd->get(
        year => '2007',
        'artist_name like' => 'Bob%'
    );

    # These values would be cached...
    my @artists_for_some_cds = map { $_->artist } @some_cds;

    # This will use a join to prefetch Artist objects related to the
    # objects that match the filter
    my @other_cds = Music::Cd->get(
        'title like' => '%White%',
        -hints => ['artist']
    );
    my $other_artist_0 = $other_cds[0]->artist;  # already loaded so no query

    # create() instantiates a new object in the current "context", but does not save
    # it in the database.  It will autogenerate its own cd_id:
    my $new_cd = Music::Cd->create(
        title => 'Cool Album',
        year  => 2009
    );

    # Assign it to an artist; fills in the artist_id field of $new_cd
    $first_artist->add_cd($new_cd);

    # Save all changes in the current transaction back to the database(s)
    # which are behind the changed objects.
    UR::Context->current->commit;

=head1 Environment Variables

UR uses several environment variables to do things like run with
database commits disabled, watching SQL queries run, examine query plans,
and control cache size, etc.

These make development and debugging fast and easy.

See L<UR::Env> for details.

=head1 DEPENDENCIES

Class::Autouse
Cwd
Data::Dumper
Date::Format
DBI
File::Basename
FindBin
FreezeThaw
Path::Class
Scalar::Util
Sub::Installer
Sub::Name
Sys::Hostname
Text::Diff
Time::HiRes
XML::Simple

=head1 AUTHORS

UR was built by the software development team at the McDonnell Genome Institute
at the Washington University School of Medicine (Richard K. Wilson, PI).

Incarnations of it run laboratory automation and analysis systems
for high-throughput genomics.

 Anthony Brummett   brummett@cpan.org
 Nathan Nutter
 Josh McMichael
 Eric Clark
 Ben Oberkfell
 Eddie Belter
 Feiyu Du
 Adam Dukes
 Brian Derickson
 Craig Pohl
 Gabe Sanderson
 Todd Hepler
 Jason Walker
 James Weible
 Indraniel Das
 Shin Leong
 Ken Swanson
 Scott Abbott
 Alice Diec
 William Schroeder
 Shawn Leonard
 Lynn Carmichael
 Amy Hawkins
 Michael Kiwala
 Kevin Crouse
 Mark Johnson
 Kyung Kim
 Jon Schindler
 Justin Lolofie
 Jerome Peirick
 Ryan Richt
 John Osborne
 Chris Harris
 Philip Kimmey
 Robert Long
 Travis Abbott
 Matthew Callaway
 James Eldred
 Scott Smith	    sakoht@cpan.org
 David Dooling

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2002-2016 Washington University in St. Louis, MO.

This software is licensed under the same terms as Perl itself.
See the LICENSE file in this distribution.

=pod

