package Venus;

use 5.018;

use strict;
use warnings;

# VERSION

our $VERSION = '5.01';

# AUTHORITY

our $AUTHORITY = 'cpan:AWNCORP';

# FILES

our $FILES = {
  'lib/Venus.pm' => {
    help => 'lib/Venus.pod',
    main => 1,
    name => 'Venus',
    skip => 0,
    test => 't/Venus.t',
    type => 'dsl',
  },
  'lib/Venus/Args.pm' => {
    help => 'lib/Venus/Args.pod',
    name => 'Venus::Args',
    skip => 0,
    test => 't/Venus_Args.t',
    type => 'class',
  },
  'lib/Venus/Array.pm' => {
    help => 'lib/Venus/Array.pod',
    name => 'Venus::Array',
    skip => 0,
    test => 't/Venus_Array.t',
    type => 'class',
  },
  'lib/Venus/Assert.pm' => {
    help => 'lib/Venus/Assert.pod',
    name => 'Venus::Assert',
    skip => 0,
    test => 't/Venus_Assert.t',
    type => 'class',
  },
  'lib/Venus/Atom.pm' => {
    help => 'lib/Venus/Atom.pod',
    name => 'Venus::Atom',
    skip => 0,
    test => 't/Venus_Atom.t',
    type => 'class',
  },
  'lib/Venus/Boolean.pm' => {
    help => 'lib/Venus/Boolean.pod',
    name => 'Venus::Boolean',
    skip => 0,
    test => 't/Venus_Boolean.t',
    type => 'class',
  },
  'lib/Venus/Box.pm' => {
    help => 'lib/Venus/Box.pod',
    name => 'Venus::Box',
    skip => 0,
    test => 't/Venus_Box.t',
    type => 'class',
  },
  'lib/Venus/Check.pm' => {
    help => 'lib/Venus/Check.pod',
    name => 'Venus::Check',
    skip => 0,
    test => 't/Venus_Check.t',
    type => 'class',
  },
  'lib/Venus/Class.pm' => {
    help => 'lib/Venus/Class.pod',
    name => 'Venus::Class',
    skip => 0,
    test => 't/Venus_Class.t',
    type => 'dsl',
  },
  'lib/Venus/Cli.pm' => {
    help => 'lib/Venus/Cli.pod',
    name => 'Venus::Cli',
    skip => 0,
    test => 't/Venus_Cli.t',
    type => 'class',
  },
  'lib/Venus/Code.pm' => {
    help => 'lib/Venus/Code.pod',
    name => 'Venus::Code',
    skip => 0,
    test => 't/Venus_Code.t',
    type => 'class',
  },
  'lib/Venus/Coercion.pm' => {
    help => 'lib/Venus/Coercion.pod',
    name => 'Venus::Coercion',
    skip => 0,
    test => 't/Venus_Coercion.t',
    type => 'class',
  },
  'lib/Venus/Config.pm' => {
    help => 'lib/Venus/Config.pod',
    name => 'Venus::Config',
    skip => 0,
    test => 't/Venus_Config.t',
    type => 'class',
  },
  'lib/Venus/Collect.pm' => {
    help => 'lib/Venus/Collect.pod',
    name => 'Venus::Collect',
    skip => 0,
    test => 't/Venus_Collect.t',
    type => 'class',
  },
  'lib/Venus/Constraint.pm' => {
    help => 'lib/Venus/Constraint.pod',
    name => 'Venus::Constraint',
    skip => 0,
    test => 't/Venus_Constraint.t',
    type => 'class',
  },
  'lib/Venus/Core.pm' => {
    help => 'lib/Venus/Core.pod',
    name => 'Venus::Core',
    skip => 0,
    test => 't/Venus_Core.t',
    type => 'core',
  },
  'lib/Venus/Core/Class.pm' => {
    help => 'lib/Venus/Core/Class.pod',
    name => 'Venus::Core::Class',
    skip => 0,
    test => 't/Venus_Core_Class.t',
    type => 'core',
  },
  'lib/Venus/Core/Mixin.pm' => {
    help => 'lib/Venus/Core/Mixin.pod',
    name => 'Venus::Core::Mixin',
    skip => 0,
    test => 't/Venus_Core_Mixin.t',
    type => 'core',
  },
  'lib/Venus/Core/Role.pm' => {
    help => 'lib/Venus/Core/Role.pod',
    name => 'Venus::Core::Role',
    skip => 0,
    test => 't/Venus_Core_Role.t',
    type => 'core',
  },
  'lib/Venus/Data.pm' => {
    help => 'lib/Venus/Data.pod',
    name => 'Venus::Data',
    skip => 0,
    test => 't/Venus_Data.t',
    type => 'class',
  },
  'lib/Venus/Date.pm' => {
    help => 'lib/Venus/Date.pod',
    name => 'Venus::Date',
    skip => 0,
    test => 't/Venus_Date.t',
    type => 'class',
  },
  'lib/Venus/Dump.pm' => {
    help => 'lib/Venus/Dump.pod',
    name => 'Venus::Dump',
    skip => 0,
    test => 't/Venus_Dump.t',
    type => 'class',
  },
  'lib/Venus/Enum.pm' => {
    help => 'lib/Venus/Enum.pod',
    name => 'Venus::Enum',
    skip => 0,
    test => 't/Venus_Enum.t',
    type => 'class',
  },
  'lib/Venus/Error.pm' => {
    help => 'lib/Venus/Error.pod',
    name => 'Venus::Error',
    skip => 0,
    test => 't/Venus_Error.t',
    type => 'class',
  },
  'lib/Venus/Factory.pm' => {
    help => 'lib/Venus/Factory.pod',
    name => 'Venus::Factory',
    skip => 0,
    test => 't/Venus_Factory.t',
    type => 'class',
  },
  'lib/Venus/False.pm' => {
    help => 'lib/Venus/False.pod',
    name => 'Venus::False',
    skip => 0,
    test => 't/Venus_False.t',
    type => 'class',
  },
  'lib/Venus/Fault.pm' => {
    help => 'lib/Venus/Fault.pod',
    name => 'Venus::Fault',
    skip => 0,
    test => 't/Venus_Fault.t',
    type => 'class',
  },
  'lib/Venus/Float.pm' => {
    help => 'lib/Venus/Float.pod',
    name => 'Venus::Float',
    skip => 0,
    test => 't/Venus_Float.t',
    type => 'class',
  },
  'lib/Venus/Future.pm' => {
    help => 'lib/Venus/Future.pod',
    name => 'Venus::Future',
    skip => 0,
    test => 't/Venus_Future.t',
    type => 'class',
  },
  'lib/Venus/Gather.pm' => {
    help => 'lib/Venus/Gather.pod',
    name => 'Venus::Gather',
    skip => 0,
    test => 't/Venus_Gather.t',
    type => 'class',
  },
  'lib/Venus/Hash.pm' => {
    help => 'lib/Venus/Hash.pod',
    name => 'Venus::Hash',
    skip => 0,
    test => 't/Venus_Hash.t',
    type => 'class',
  },
  'lib/Venus/Hook.pm' => {
    help => 'lib/Venus/Hook.pod',
    name => 'Venus::Hook',
    skip => 1,
    test => 't/Venus_Hook.t',
    type => 'dsl',
  },
  'lib/Venus/Json.pm' => {
    help => 'lib/Venus/Json.pod',
    name => 'Venus::Json',
    skip => 0,
    test => 't/Venus_Json.t',
    type => 'class',
  },
  'lib/Venus/Kind.pm' => {
    help => 'lib/Venus/Kind.pod',
    name => 'Venus::Kind',
    skip => 0,
    test => 't/Venus_Kind.t',
    type => 'kind',
  },
  'lib/Venus/Kind/Utility.pm' => {
    help => 'lib/Venus/Kind/Utility.pod',
    name => 'Venus::Kind::Utility',
    skip => 0,
    test => 't/Venus_Kind_Utility.t',
    type => 'kind',
  },
  'lib/Venus/Kind/Value.pm' => {
    help => 'lib/Venus/Kind/Value.pod',
    name => 'Venus::Kind::Value',
    skip => 0,
    test => 't/Venus_Kind_Value.t',
    type => 'kind',
  },
  'lib/Venus/Log.pm' => {
    help => 'lib/Venus/Log.pod',
    name => 'Venus::Log',
    skip => 0,
    test => 't/Venus_Log.t',
    type => 'class',
  },
  'lib/Venus/Match.pm' => {
    help => 'lib/Venus/Match.pod',
    name => 'Venus::Match',
    skip => 0,
    test => 't/Venus_Match.t',
    type => 'class',
  },
  'lib/Venus/Map.pm' => {
    help => 'lib/Venus/Map.pod',
    name => 'Venus::Map',
    skip => 0,
    test => 't/Venus_Map.t',
    type => 'class',
  },
  'lib/Venus/Meta.pm' => {
    help => 'lib/Venus/Meta.pod',
    name => 'Venus::Meta',
    skip => 0,
    test => 't/Venus_Meta.t',
    type => 'class',
  },
  'lib/Venus/Mixin.pm' => {
    help => 'lib/Venus/Mixin.pod',
    name => 'Venus::Mixin',
    skip => 0,
    test => 't/Venus_Mixin.t',
    type => 'dsl',
  },
  'lib/Venus/Module.pm' => {
    help => 'lib/Venus/Module.pod',
    name => 'Venus::Module',
    skip => 0,
    test => 't/Venus_Module.t',
    type => 'dsl',
  },
  'lib/Venus/Name.pm' => {
    help => 'lib/Venus/Name.pod',
    name => 'Venus::Name',
    skip => 0,
    test => 't/Venus_Name.t',
    type => 'class',
  },
  'lib/Venus/Number.pm' => {
    help => 'lib/Venus/Number.pod',
    name => 'Venus::Number',
    skip => 0,
    test => 't/Venus_Number.t',
    type => 'class',
  },
  'lib/Venus/Opts.pm' => {
    help => 'lib/Venus/Opts.pod',
    name => 'Venus::Opts',
    skip => 0,
    test => 't/Venus_Opts.t',
    type => 'class',
  },
  'lib/Venus/Os.pm' => {
    help => 'lib/Venus/Os.pod',
    name => 'Venus::Os',
    skip => 0,
    test => 't/Venus_Os.t',
    type => 'class',
  },
  'lib/Venus/Path.pm' => {
    help => 'lib/Venus/Path.pod',
    name => 'Venus::Path',
    skip => 0,
    test => 't/Venus_Path.t',
    type => 'class',
  },
  'lib/Venus/Process.pm' => {
    help => 'lib/Venus/Process.pod',
    name => 'Venus::Process',
    skip => 0,
    test => 't/Venus_Process.t',
    type => 'class',
  },
  'lib/Venus/Prototype.pm' => {
    help => 'lib/Venus/Prototype.pod',
    name => 'Venus::Prototype',
    skip => 0,
    test => 't/Venus_Prototype.t',
    type => 'class',
  },
  'lib/Venus/Random.pm' => {
    help => 'lib/Venus/Random.pod',
    name => 'Venus::Random',
    skip => 0,
    test => 't/Venus_Random.t',
    type => 'class',
  },
  'lib/Venus/Range.pm' => {
    help => 'lib/Venus/Range.pod',
    name => 'Venus::Range',
    skip => 0,
    test => 't/Venus_Range.t',
    type => 'class',
  },
  'lib/Venus/Regexp.pm' => {
    help => 'lib/Venus/Regexp.pod',
    name => 'Venus::Regexp',
    skip => 0,
    test => 't/Venus_Regexp.t',
    type => 'class',
  },
  'lib/Venus/Replace.pm' => {
    help => 'lib/Venus/Replace.pod',
    name => 'Venus::Replace',
    skip => 0,
    test => 't/Venus_Replace.t',
    type => 'class',
  },
  'lib/Venus/Result.pm' => {
    help => 'lib/Venus/Result.pod',
    name => 'Venus::Result',
    skip => 0,
    test => 't/Venus_Result.t',
    type => 'class',
  },
  'lib/Venus/Role.pm' => {
    help => 'lib/Venus/Role.pod',
    name => 'Venus::Role',
    skip => 0,
    test => 't/Venus_Role.t',
    type => 'dsl',
  },
  'lib/Venus/Role/Accessible.pm' => {
    help => 'lib/Venus/Role/Accessible.pod',
    name => 'Venus::Role::Accessible',
    skip => 0,
    test => 't/Venus_Role_Accessible.t',
    type => 'role',
  },
  'lib/Venus/Role/Boxable.pm' => {
    help => 'lib/Venus/Role/Boxable.pod',
    name => 'Venus::Role::Boxable',
    skip => 0,
    test => 't/Venus_Role_Boxable.t',
    type => 'role',
  },
  'lib/Venus/Role/Buildable.pm' => {
    help => 'lib/Venus/Role/Buildable.pod',
    name => 'Venus::Role::Buildable',
    skip => 0,
    test => 't/Venus_Role_Buildable.t',
    type => 'role',
  },
  'lib/Venus/Role/Catchable.pm' => {
    help => 'lib/Venus/Role/Catchable.pod',
    name => 'Venus::Role::Catchable',
    skip => 0,
    test => 't/Venus_Role_Catchable.t',
    type => 'role',
  },
  'lib/Venus/Role/Coercible.pm' => {
    help => 'lib/Venus/Role/Coercible.pod',
    name => 'Venus::Role::Coercible',
    skip => 0,
    test => 't/Venus_Role_Coercible.t',
    type => 'role',
  },
  'lib/Venus/Role/Comparable.pm' => {
    help => 'lib/Venus/Role/Comparable.pod',
    name => 'Venus::Role::Comparable',
    skip => 0,
    test => 't/Venus_Role_Comparable.t',
    type => 'role',
  },
  'lib/Venus/Role/Defaultable.pm' => {
    help => 'lib/Venus/Role/Defaultable.pod',
    name => 'Venus::Role::Defaultable',
    skip => 0,
    test => 't/Venus_Role_Defaultable.t',
    type => 'role',
  },
  'lib/Venus/Role/Deferrable.pm' => {
    help => 'lib/Venus/Role/Deferrable.pod',
    name => 'Venus::Role::Deferrable',
    skip => 0,
    test => 't/Venus_Role_Deferrable.t',
    type => 'role',
  },
  'lib/Venus/Role/Digestable.pm' => {
    help => 'lib/Venus/Role/Digestable.pod',
    name => 'Venus::Role::Digestable',
    skip => 0,
    test => 't/Venus_Role_Digestable.t',
    type => 'role',
  },
  'lib/Venus/Role/Doable.pm' => {
    help => 'lib/Venus/Role/Doable.pod',
    name => 'Venus::Role::Doable',
    skip => 0,
    test => 't/Venus_Role_Doable.t',
    type => 'role',
  },
  'lib/Venus/Role/Dumpable.pm' => {
    help => 'lib/Venus/Role/Dumpable.pod',
    name => 'Venus::Role::Dumpable',
    skip => 0,
    test => 't/Venus_Role_Dumpable.t',
    type => 'role',
  },
  'lib/Venus/Role/Encaseable.pm' => {
    help => 'lib/Venus/Role/Encaseable.pod',
    name => 'Venus::Role::Encaseable',
    skip => 0,
    test => 't/Venus_Role_Encaseable.t',
    type => 'role',
  },
  'lib/Venus/Role/Explainable.pm' => {
    help => 'lib/Venus/Role/Explainable.pod',
    name => 'Venus::Role::Explainable',
    skip => 0,
    test => 't/Venus_Role_Explainable.t',
    type => 'role',
  },
  'lib/Venus/Role/Fromable.pm' => {
    help => 'lib/Venus/Role/Fromable.pod',
    name => 'Venus::Role::Fromable',
    skip => 0,
    test => 't/Venus_Role_Fromable.t',
    type => 'role',
  },
  'lib/Venus/Role/Mappable.pm' => {
    help => 'lib/Venus/Role/Mappable.pod',
    name => 'Venus::Role::Mappable',
    skip => 0,
    test => 't/Venus_Role_Mappable.t',
    type => 'role',
  },
  'lib/Venus/Role/Matchable.pm' => {
    help => 'lib/Venus/Role/Matchable.pod',
    name => 'Venus::Role::Matchable',
    skip => 0,
    test => 't/Venus_Role_Matchable.t',
    type => 'role',
  },
  'lib/Venus/Role/Mockable.pm' => {
    help => 'lib/Venus/Role/Mockable.pod',
    name => 'Venus::Role::Mockable',
    skip => 0,
    test => 't/Venus_Role_Mockable.t',
    type => 'role',
  },
  'lib/Venus/Role/Optional.pm' => {
    help => 'lib/Venus/Role/Optional.pod',
    name => 'Venus::Role::Optional',
    skip => 0,
    test => 't/Venus_Role_Optional.t',
    type => 'role',
  },
  'lib/Venus/Role/Patchable.pm' => {
    help => 'lib/Venus/Role/Patchable.pod',
    name => 'Venus::Role::Patchable',
    skip => 0,
    test => 't/Venus_Role_Patchable.t',
    type => 'role',
  },
  'lib/Venus/Role/Pluggable.pm' => {
    help => 'lib/Venus/Role/Pluggable.pod',
    name => 'Venus::Role::Pluggable',
    skip => 0,
    test => 't/Venus_Role_Pluggable.t',
    type => 'role',
  },
  'lib/Venus/Role/Printable.pm' => {
    help => 'lib/Venus/Role/Printable.pod',
    name => 'Venus::Role::Printable',
    skip => 0,
    test => 't/Venus_Role_Printable.t',
    type => 'role',
  },
  'lib/Venus/Role/Proxyable.pm' => {
    help => 'lib/Venus/Role/Proxyable.pod',
    name => 'Venus::Role::Proxyable',
    skip => 0,
    test => 't/Venus_Role_Proxyable.t',
    type => 'role',
  },
  'lib/Venus/Role/Reflectable.pm' => {
    help => 'lib/Venus/Role/Reflectable.pod',
    name => 'Venus::Role::Reflectable',
    skip => 0,
    test => 't/Venus_Role_Reflectable.t',
    type => 'role',
  },
  'lib/Venus/Role/Rejectable.pm' => {
    help => 'lib/Venus/Role/Rejectable.pod',
    name => 'Venus::Role::Rejectable',
    skip => 0,
    test => 't/Venus_Role_Rejectable.t',
    type => 'role',
  },
  'lib/Venus/Role/Resultable.pm' => {
    help => 'lib/Venus/Role/Resultable.pod',
    name => 'Venus::Role::Resultable',
    skip => 0,
    test => 't/Venus_Role_Resultable.t',
    type => 'role',
  },
  'lib/Venus/Role/Serializable.pm' => {
    help => 'lib/Venus/Role/Serializable.pod',
    name => 'Venus::Role::Serializable',
    skip => 0,
    test => 't/Venus_Role_Serializable.t',
    type => 'role',
  },
  'lib/Venus/Role/Stashable.pm' => {
    help => 'lib/Venus/Role/Stashable.pod',
    name => 'Venus::Role::Stashable',
    skip => 0,
    test => 't/Venus_Role_Stashable.t',
    type => 'role',
  },
  'lib/Venus/Role/Subscribable.pm' => {
    help => 'lib/Venus/Role/Subscribable.pod',
    name => 'Venus::Role::Subscribable',
    skip => 0,
    test => 't/Venus_Role_Subscribable.t',
    type => 'role',
  },
  'lib/Venus/Role/Superable.pm' => {
    help => 'lib/Venus/Role/Superable.pod',
    name => 'Venus::Role::Superable',
    skip => 0,
    test => 't/Venus_Role_Superable.t',
    type => 'role',
  },
  'lib/Venus/Role/Testable.pm' => {
    help => 'lib/Venus/Role/Testable.pod',
    name => 'Venus::Role::Testable',
    skip => 0,
    test => 't/Venus_Role_Testable.t',
    type => 'role',
  },
  'lib/Venus/Role/Throwable.pm' => {
    help => 'lib/Venus/Role/Throwable.pod',
    name => 'Venus::Role::Throwable',
    skip => 0,
    test => 't/Venus_Role_Throwable.t',
    type => 'role',
  },
  'lib/Venus/Role/Tryable.pm' => {
    help => 'lib/Venus/Role/Tryable.pod',
    name => 'Venus::Role::Tryable',
    skip => 0,
    test => 't/Venus_Role_Tryable.t',
    type => 'role',
  },
  'lib/Venus/Role/Unacceptable.pm' => {
    help => 'lib/Venus/Role/Unacceptable.pod',
    name => 'Venus::Role::Unacceptable',
    skip => 0,
    test => 't/Venus_Role_Unacceptable.t',
    type => 'role',
  },
  'lib/Venus/Role/Unpackable.pm' => {
    help => 'lib/Venus/Role/Unpackable.pod',
    name => 'Venus::Role::Unpackable',
    skip => 0,
    test => 't/Venus_Role_Unpackable.t',
    type => 'role',
  },
  'lib/Venus/Role/Valuable.pm' => {
    help => 'lib/Venus/Role/Valuable.pod',
    name => 'Venus::Role::Valuable',
    skip => 0,
    test => 't/Venus_Role_Valuable.t',
    type => 'role',
  },
  'lib/Venus/Run.pm' => {
    help => 'lib/Venus/Run.pod',
    name => 'Venus::Run',
    skip => 0,
    test => 't/Venus_Run.t',
    type => 'class',
  },
  'lib/Venus/Scalar.pm' => {
    help => 'lib/Venus/Scalar.pod',
    name => 'Venus::Scalar',
    skip => 0,
    test => 't/Venus_Scalar.t',
    type => 'class',
  },
  'lib/Venus/Schema.pm' => {
    help => 'lib/Venus/Schema.pod',
    name => 'Venus::Schema',
    skip => 0,
    test => 't/Venus_Schema.t',
    type => 'class',
  },
  'lib/Venus/Sealed.pm' => {
    help => 'lib/Venus/Sealed.pod',
    name => 'Venus::Sealed',
    skip => 0,
    test => 't/Venus_Sealed.t',
    type => 'class',
  },
  'lib/Venus/Search.pm' => {
    help => 'lib/Venus/Search.pod',
    name => 'Venus::Search',
    skip => 0,
    test => 't/Venus_Search.t',
    type => 'class',
  },
  'lib/Venus/Set.pm' => {
    help => 'lib/Venus/Set.pod',
    name => 'Venus::Set',
    skip => 0,
    test => 't/Venus_Set.t',
    type => 'class',
  },
  'lib/Venus/Space.pm' => {
    help => 'lib/Venus/Space.pod',
    name => 'Venus::Space',
    skip => 0,
    test => 't/Venus_Space.t',
    type => 'class',
  },
  'lib/Venus/String.pm' => {
    help => 'lib/Venus/String.pod',
    name => 'Venus::String',
    skip => 0,
    test => 't/Venus_String.t',
    type => 'class',
  },
  'lib/Venus/Task.pm' => {
    help => 'lib/Venus/Task.pod',
    name => 'Venus::Task',
    skip => 0,
    test => 't/Venus_Task.t',
    type => 'class',
  },
  'lib/Venus/Task/Venus.pm' => {
    help => 'lib/Venus/Task/Venus.pod',
    name => 'Venus::Task::Venus',
    skip => 0,
    test => 't/Venus_Task_Venus.t',
    type => 'class',
  },
  'lib/Venus/Task/Venus/Gen.pm' => {
    help => 'lib/Venus/Task/Venus/Gen.pod',
    name => 'Venus::Task::Venus::Gen',
    skip => 0,
    test => 't/Venus_Task_Venus_Gen.t',
    type => 'class',
  },
  'lib/Venus/Task/Venus/Get.pm' => {
    help => 'lib/Venus/Task/Venus/Get.pod',
    name => 'Venus::Task::Venus::Get',
    skip => 0,
    test => 't/Venus_Task_Venus_Get.t',
    type => 'class',
  },
  'lib/Venus/Task/Venus/New.pm' => {
    help => 'lib/Venus/Task/Venus/New.pod',
    name => 'Venus::Task::Venus::New',
    skip => 0,
    test => 't/Venus_Task_Venus_New.t',
    type => 'class',
  },
  'lib/Venus/Task/Venus/Run.pm' => {
    help => 'lib/Venus/Task/Venus/Run.pod',
    name => 'Venus::Task::Venus::Run',
    skip => 0,
    test => 't/Venus_Task_Venus_Run.t',
    type => 'class',
  },
  'lib/Venus/Task/Venus/Set.pm' => {
    help => 'lib/Venus/Task/Venus/Set.pod',
    name => 'Venus::Task::Venus::Set',
    skip => 0,
    test => 't/Venus_Task_Venus_Set.t',
    type => 'class',
  },
  'lib/Venus/Template.pm' => {
    help => 'lib/Venus/Template.pod',
    name => 'Venus::Template',
    skip => 0,
    test => 't/Venus_Template.t',
    type => 'class',
  },
  'lib/Venus/Test.pm' => {
    help => 'lib/Venus/Test.pod',
    name => 'Venus::Test',
    skip => 0,
    test => 't/Venus_Test.t',
    type => 'class',
  },
  'lib/Venus/Text.pm' => {
    help => 'lib/Venus/Text.pod',
    name => 'Venus::Text',
    skip => 0,
    test => 't/Venus_Text.t',
    type => 'class',
  },
  'lib/Venus/Text/Pod.pm' => {
    help => 'lib/Venus/Text/Pod.pod',
    name => 'Venus::Text::Pod',
    skip => 0,
    test => 't/Venus_Text_Pod.t',
    type => 'class',
  },
  'lib/Venus/Text/Tag.pm' => {
    help => 'lib/Venus/Text/Tag.pod',
    name => 'Venus::Text::Tag',
    skip => 0,
    test => 't/Venus_Text_Tag.t',
    type => 'class',
  },
  'lib/Venus/Throw.pm' => {
    help => 'lib/Venus/Throw.pod',
    name => 'Venus::Throw',
    skip => 0,
    test => 't/Venus_Throw.t',
    type => 'class',
  },
  'lib/Venus/True.pm' => {
    help => 'lib/Venus/True.pod',
    name => 'Venus::True',
    skip => 0,
    test => 't/Venus_True.t',
    type => 'class',
  },
  'lib/Venus/Try.pm' => {
    help => 'lib/Venus/Try.pod',
    name => 'Venus::Try',
    skip => 0,
    test => 't/Venus_Try.t',
    type => 'class',
  },
  'lib/Venus/Type.pm' => {
    help => 'lib/Venus/Type.pod',
    name => 'Venus::Type',
    skip => 0,
    test => 't/Venus_Type.t',
    type => 'class',
  },
  'lib/Venus/Undef.pm' => {
    help => 'lib/Venus/Undef.pod',
    name => 'Venus::Undef',
    skip => 0,
    test => 't/Venus_Undef.t',
    type => 'class',
  },
  'lib/Venus/Unpack.pm' => {
    help => 'lib/Venus/Unpack.pod',
    name => 'Venus::Unpack',
    skip => 0,
    test => 't/Venus_Unpack.t',
    type => 'class',
  },
  'lib/Venus/Validate.pm' => {
    help => 'lib/Venus/Validate.pod',
    name => 'Venus::Validate',
    skip => 0,
    test => 't/Venus_Validate.t',
    type => 'class',
  },
  'lib/Venus/Vars.pm' => {
    help => 'lib/Venus/Vars.pod',
    name => 'Venus::Vars',
    skip => 0,
    test => 't/Venus_Vars.t',
    type => 'class',
  },
  'lib/Venus/What.pm' => {
    help => 'lib/Venus/What.pod',
    name => 'Venus::What',
    skip => 0,
    test => 't/Venus_What.t',
    type => 'class',
  },
  'lib/Venus/Yaml.pm' => {
    help => 'lib/Venus/Yaml.pod',
    name => 'Venus::Yaml',
    skip => 0,
    test => 't/Venus_Yaml.t',
    type => 'class',
  },
};

# IMPORTS

sub import {
  my ($self, @args) = @_;

  my $target = caller;

  no strict 'refs';

  my %exports = (
    after => 1,
    all => 1,
    any => 1,
    args => 1,
    around => 1,
    array => 1,
    arrayref => 1,
    assert => 1,
    async => 1,
    atom => 1,
    await => 1,
    before => 1,
    bool => 1,
    box => 1,
    call => 1,
    cast => 1,
    catch => 1,
    caught => 1,
    chain => 1,
    check => 1,
    clargs => 1,
    cli => 1,
    clone => 1,
    code => 1,
    collect => 1,
    concat => 1,
    config => 1,
    cop => 1,
    data => 1,
    date => 1,
    docs => 1,
    enum => 1,
    error => 1,
    factory => 1,
    false => 1,
    fault => 1,
    flat => 1,
    float => 1,
    future => 1,
    gather => 1,
    gets => 1,
    handle => 1,
    hash => 1,
    hashref => 1,
    hook => 1,
    in => 1,
    is => 1,
    is_arrayref => 1,
    is_blessed => 1,
    is_bool => 1,
    is_boolean => 1,
    is_coderef => 1,
    is_dirhandle => 1,
    is_enum => 1,
    is_error => 1,
    is_false => 1,
    is_fault => 1,
    is_filehandle => 1,
    is_float => 1,
    is_glob => 1,
    is_hashref => 1,
    is_number => 1,
    is_object => 1,
    is_package => 1,
    is_reference => 1,
    is_regexp => 1,
    is_scalarref => 1,
    is_string => 1,
    is_true => 1,
    is_undef => 1,
    is_value => 1,
    is_yesno => 1,
    json => 1,
    kvargs => 1,
    list => 1,
    load => 1,
    log => 1,
    make => 1,
    map => 1,
    match => 1,
    merge => 1,
    merge_flat => 1,
    merge_flat_mutate => 1,
    merge_join => 1,
    merge_join_mutate => 1,
    merge_keep => 1,
    merge_keep_mutate => 1,
    merge_swap => 1,
    merge_swap_mutate => 1,
    merge_take => 1,
    merge_take_mutate => 1,
    meta => 1,
    name => 1,
    number => 1,
    opts => 1,
    pairs => 1,
    path => 1,
    perl => 1,
    process => 1,
    proto => 1,
    puts => 1,
    raise => 1,
    random => 1,
    range => 1,
    read_env => 1,
    read_env_file => 1,
    read_json => 1,
    read_json_file => 1,
    read_perl => 1,
    read_perl_file => 1,
    read_yaml => 1,
    read_yaml_file => 1,
    regexp => 1,
    render => 1,
    replace => 1,
    roll => 1,
    schema => 1,
    search => 1,
    set => 1,
    sets => 1,
    sorts => 1,
    space => 1,
    string => 1,
    syscall => 1,
    template => 1,
    test => 1,
    text_pod => 1,
    text_pod_string => 1,
    text_tag => 1,
    text_tag_string => 1,
    then => 1,
    throw => 1,
    true => 1,
    try => 1,
    tv => 1,
    type => 1,
    unpack => 1,
    vars => 1,
    vns => 1,
    what => 1,
    work => 1,
    wrap => 1,
    write_env => 1,
    write_env_file => 1,
    write_json => 1,
    write_json_file => 1,
    write_perl => 1,
    write_perl_file => 1,
    write_yaml => 1,
    write_yaml_file => 1,
    yaml => 1,
  );

  @args = grep defined && !ref && /^[A-Za-z]/ && $exports{$_}, @args;

  my %seen;
  for my $name (grep !$seen{$_}++, @args, 'true', 'false') {
    *{"${target}::${name}"} = $self->can($name) if !$target->can($name);
  }

  return $self;
}

# HOOKS

sub _qx {
  my (@args) = @_;
  local $| = 1;
  local $SIG{__WARN__} = sub {};
  (do{local $_ = qx(@{[@args]}); chomp if $_; $_}, $?, ($? >> 8))
}

# FUNCTIONS

sub after ($$) {
  my ($name, $code) = @_;

  my $package = caller;

  return space($package, 'after', $name, $code);
}

sub all ($;$) {
  my ($data, $expr) = @_;

  my $cast = cast($data);

  my $code = (defined $expr && ref $expr ne 'CODE') ? sub{tv($_[1], $expr)} : $expr;

  if ($cast->isa('Venus::Kind') && $cast->does('Venus::Role::Mappable')) {
    return ref $code eq 'CODE' ? $cast->all($code) : $cast->count ? true() : false();
  }
  else {
    return false();
  }
}

sub any ($;$) {
  my ($data, $expr) = @_;

  my $cast = cast($data);

  my $code = (defined $expr && ref $expr ne 'CODE') ? sub{tv($_[1], $expr)} : $expr;

  if ($cast->isa('Venus::Kind') && $cast->does('Venus::Role::Mappable')) {
    return ref $code eq 'CODE' ? $cast->any($code) : $cast->count ? true() : false();
  }
  else {
    return false();
  }
}

sub args ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Args;

  if (!$code) {
    return Venus::Args->new($data);
  }

  return Venus::Args->new($data)->$code(@args);
}

sub array ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Array;

  if (!$code) {
    return Venus::Array->new($data);
  }

  return Venus::Array->new($data)->$code(@args);
}

sub arrayref (@) {
  my (@args) = @_;

  return @args > 1
    ? ([@args])
    : ((ref $args[0] eq 'ARRAY') ? ($args[0]) : ([@args]));
}

sub around ($$) {
  my ($name, $code) = @_;

  my $package = caller;

  return space($package, 'around', $name, $code);
}

sub assert ($$) {
  my ($data, $expr) = @_;

  require Venus::Assert;

  my $assert = Venus::Assert->new->expression($expr);

  return $assert->validate($data);
}

sub async ($) {
  my ($code) = @_;

  require Venus::Process;

  return Venus::Process->new->future($code);
}

sub atom (;$) {
  my ($data) = @_;

  require Venus::Atom;

  return Venus::Atom->new($data);
}

sub await ($;$) {
  my ($future, $timeout) = @_;

  require Venus::Future;

  return $future->wait($timeout);
}

sub before ($$) {
  my ($name, $code) = @_;

  my $package = caller;

  return space($package, 'before', $name, $code);
}

sub bool (;$) {
  my ($data) = @_;

  require Venus::Boolean;

  return Venus::Boolean->new($data);
}

sub box ($) {
  my ($data) = @_;

  require Venus::Box;

  my $box = Venus::Box->new($data);

  return $box;
}

sub call (@) {
  my ($data, @args) = @_;
  my $next = @args;
  if ($next && UNIVERSAL::isa($data, 'CODE')) {
    return $data->(@args);
  }
  my $code = shift(@args);
  if ($next && Scalar::Util::blessed($data)) {
    return $data->$code(@args) if UNIVERSAL::can($data, $code)
      || UNIVERSAL::can($data, 'AUTOLOAD');
    $next = 0;
  }
  if ($next && ref($data) eq 'SCALAR') {
    return $$data->$code(@args) if UNIVERSAL::can(load($$data)->package, $code);
    $next = 0;
  }
  if ($next && UNIVERSAL::can(load($data)->package, $code)) {
    no strict 'refs';
    return *{"${data}::${code}"}{"CODE"} ?
      &{"${data}::${code}"}(@args) : $data->$code(@args[1..$#args]);
  }
  if ($next && UNIVERSAL::can($data, 'AUTOLOAD')) {
    no strict 'refs';
    return &{"${data}::${code}"}(@args);
  }
  fault("Exception! call(@{[join(', ', map qq('$_'), @_)]}) failed.");
}

sub cast (;$$) {
  my ($data, $into) = (@_ ? (@_) : ($_));

  require Venus::What;

  my $what = Venus::What->new($data);

  return $into ? $what->cast($into) : $what->deduce;
}

sub catch (&) {
  my ($data) = @_;

  my $error;

  require Venus::Try;

  my @result = Venus::Try->new($data)->error(\$error)->result;

  return wantarray ? ($error ? ($error, undef) : ($error, @result)) : $error;
}

sub caught ($$;&) {
  my ($data, $type, $code) = @_;

  require Scalar::Util;

  ($type, my($name)) = @$type if ref $type eq 'ARRAY';

  my $is_true = $data
    && Scalar::Util::blessed($data)
    && $data->isa('Venus::Error')
    && $data->isa($type || 'Venus::Error')
    && ($data->name ? $data->of($name || '') : !$name);

  return undef unless $is_true;

  local $_ = $data;
  return $code ? $code->($data) : $data;
}

sub chain {
  my ($data, @args) = @_;

  return if !$data;

  for my $next (map +(ref($_) eq 'ARRAY' ? $_ : [$_]), @args) {
    $data = call($data, @$next);
  }

  return $data;
}

sub check ($$) {
  my ($data, $expr) = @_;

  require Venus::Assert;

  return Venus::Assert->new->expression($expr)->valid($data);
}

sub clargs (@) {
  my (@args) = @_;

  my ($argv, $specs) = (@args > 1) ? (map arrayref($_), @args) : ([@ARGV], arrayref(@args));

  my $opts = opts($argv, 'reparse', $specs);

  return wantarray ? (args($opts->unused), $opts, vars({})) : $opts;
}

sub cli (;$) {
  my ($data) = @_;

  require Venus::Cli;

  my $cli = Venus::Cli->new($data);

  return $cli;
}

sub clone ($) {
  my ($data) = @_;

  require Storable;
  require Scalar::Util;

  local $Storable::Deparse = 1;

  local $Storable::Eval = 1;

  return $data if !ref $data;

  return Scalar::Util::blessed($data)
    && $data->isa('Venus::Core')
    && ($data->DOES('Venus::Role::Encaseable') || $data->DOES('Venus::Role::Reflectable'))
    ? $data->clone
    : Storable::dclone($data);
}

sub code ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Code;

  if (!$code) {
    return Venus::Code->new($data);
  }

  return Venus::Code->new($data)->$code(@args);
}

sub config ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Config;

  if (!$code) {
    return Venus::Config->new($data);
  }

  return Venus::Config->new($data)->$code(@args);
}

sub concat (@) {
  my (@args) = @_;

  require Venus::Log;

  return Venus::Log->new->output(@args);
}

sub collect ($;$) {
  my ($data, $code) = @_;

  require Venus::Collect;

  return Venus::Collect->new(value => $data)->execute($code);
}

sub cop (@) {
  my ($data, @args) = @_;

  require Scalar::Util;

  ($data, $args[0]) = map {
    ref eq 'SCALAR' ? $$_ : Scalar::Util::blessed($_) ? ref($_) : $_
  } ($data, $args[0]);

  return space("$data")->cop(@args);
}

sub data ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Data;

  if (!$code) {
    return Venus::Data->new($data);
  }

  return Venus::Data->new($data)->$code(@args);
}

sub date ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Date;

  if (!$code) {
    return Venus::Date->new($data);
  }

  return Venus::Date->new($data)->$code(@args);
}

sub enum {
  my (@data) = @_;

  require Venus::Enum;

  return Venus::Enum->new(@data);
}

sub error (;$) {
  my ($data) = @_;

  $data ||= {};
  $data->{context} ||= (caller(1))[3];

  require Venus::Throw;

  return Venus::Throw->new->die($data);
}

sub factory ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Factory;

  if (!$code) {
    return Venus::Factory->new($data);
  }

  return Venus::Factory->new($data)->$code(@args);
}

sub false () {

  require Venus::False;

  return Venus::False->value;
}

sub fault (;$) {
  my ($data) = @_;

  require Venus::Fault;

  return Venus::Fault->new($data)->throw;
}

sub flat {
  my @args = @_;

  return (
    map +(ref $_ eq 'HASH' ? flat(%$_) : (ref $_ eq 'ARRAY' ? flat(@$_) : $_)), @args,
  );
}

sub float ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Float;

  if (!$code) {
    return Venus::Float->new($data);
  }

  return Venus::Float->new($data)->$code(@args);
}

sub future {
  my (@data) = @_;

  require Venus::Future;

  return Venus::Future->new(@data);
}

sub gather ($;&) {
  my ($data, $code) = @_;

  require Venus::Gather;

  my $match = Venus::Gather->new($data);

  return $match if !$code;

  local $_ = $match;

  my $returned = $code->($match, $data);

  $match->data($returned) if ref $returned eq 'HASH';

  return $match->result;
}

sub gets ($;@) {
  my ($data, @args) = @_;

  $data = cast($data);

  my $result = [];

  if ($data->isa('Venus::Hash')) {
    $result = $data->gets(@args);
  }
  elsif ($data->isa('Venus::Array')) {
    $result = $data->gets(@args);
  }

  return wantarray ? (@{$result}) : $result;
}

sub handle ($$) {
  my ($name, $code) = @_;

  my $package = caller;

  return space($package, 'handle', $name, $code);
}

sub hash ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Hash;

  if (!$code) {
    return Venus::Hash->new($data);
  }

  return Venus::Hash->new($data)->$code(@args);
}

sub hashref (@) {
  my (@args) = @_;

  return @args > 1
    ? ({(scalar(@args) % 2) ? (@args, undef) : @args})
    : ((ref $args[0] eq 'HASH')
    ? ($args[0])
    : ({(scalar(@args) % 2) ? (@args, undef) : @args}));
}

sub hook ($$$) {
  my ($type, $name, $code) = @_;

  my $package = caller;

  return space($package, 'hook', $type, $name, $code);
}

sub in ($$) {
  my ($lvalue, $rvalue) = @_;

  return any($lvalue, sub{tv($rvalue, $_)});
}

sub is_arrayref ($) {
  my ($data) = @_;

  return check($data, 'arrayref');
}

sub is_blessed ($) {
  my ($data) = @_;

  return check($data, 'object');
}

sub is_boolean ($) {
  my ($data) = @_;

  return check($data, 'boolean');
}

sub is_coderef ($) {
  my ($data) = @_;

  return check($data, 'coderef');
}

sub is_dirhandle ($) {
  my ($data) = @_;

  return check($data, 'dirhandle');
}

sub is_enum ($@) {
  my ($data, @args) = @_;

  my $enum = sprintf 'enum[%s]', join ', ', map "$_", @args;

  return check($data, $enum);
}

sub is_error ($;$@) {
  my ($data, $code, @args) = @_;

  require Scalar::Util;
  require Venus::Boolean;

  if (Scalar::Util::blessed($data) && $data->isa('Venus::Error')) {
    return $code
      ? ($data->can($code)
        ? Venus::Boolean->new($data->$code(@args))->is_true
        : Venus::Boolean->false)
      : Venus::Boolean->new($data)->is_true;
  }
  else {
    return Venus::Boolean->false;
  }
}

sub is_false ($;$@) {
  my ($data, $code, @args) = @_;

  require Scalar::Util;
  require Venus::Boolean;

  if (Scalar::Util::blessed($data) && $code) {
    return Venus::Boolean->new($data->$code(@args))->is_false;
  }
  else {
    return Venus::Boolean->new($data)->is_false;
  }
}

sub is_fault ($;$@) {
  my ($data, $code, @args) = @_;

  require Scalar::Util;
  require Venus::Boolean;

  if (Scalar::Util::blessed($data) && $data->isa('Venus::Fault')) {
    return Venus::Boolean->true;
  }
  else {
    return Venus::Boolean->false;
  }
}

sub is_filehandle ($) {
  my ($data) = @_;

  return check($data, 'filehandle');
}

sub is_float ($) {
  my ($data) = @_;

  return check($data, 'float');
}

sub is_glob ($) {
  my ($data) = @_;

  return check($data, 'glob');
}

sub is_hashref ($) {
  my ($data) = @_;

  return check($data, 'hashref');
}

sub is_number ($) {
  my ($data) = @_;

  return check($data, 'number');
}

sub is_object ($) {
  my ($data) = @_;

  return check($data, 'object');
}

sub is_package ($) {
  my ($data) = @_;

  return check($data, 'package');
}

sub is_reference ($) {
  my ($data) = @_;

  return check($data, 'reference');
}

sub is_regexp ($) {
  my ($data) = @_;

  return check($data, 'regexp');
}

sub is_scalarref ($) {
  my ($data) = @_;

  return check($data, 'scalarref');
}

sub is_string ($) {
  my ($data) = @_;

  return check($data, 'string');
}

sub is_true ($;$@) {
  my ($data, $code, @args) = @_;

  require Scalar::Util;
  require Venus::Boolean;

  if (Scalar::Util::blessed($data) && $code) {
    return Venus::Boolean->new($data->$code(@args))->is_true;
  }
  else {
    return Venus::Boolean->new($data)->is_true;
  }
}

sub is_undef ($) {
  my ($data) = @_;

  return check($data, 'undef');
}

sub is_value ($) {
  my ($data) = @_;

  return check($data, 'value');
}

sub is_yesno ($) {
  my ($data) = @_;

  return check($data, 'yesno');
}

sub is ($$) {
  my ($lvalue, $rvalue) = @_;

  require Scalar::Util;

  if (ref($lvalue) && ref($rvalue)) {
    return Scalar::Util::refaddr($lvalue) == Scalar::Util::refaddr($rvalue) ? true() : false();
  }
  else {
    return false();
  }
}

sub json (;$$) {
  my ($code, $data) = @_;

  require Venus::Json;

  if (!$code) {
    return Venus::Json->new;
  }

  if (lc($code) eq 'decode') {
    return Venus::Json->new->decode($data);
  }

  if (lc($code) eq 'encode') {
    return Venus::Json->new(value => $data)->encode;
  }

  return fault(qq(Invalid "json" action "$code"));
}

sub kvargs {
  my (@args) = @_;

  return $args[0] if @args == 1 && ref($args[0]) eq 'HASH';

  return (@args % 2) ? {@args, undef} : {@args};
}

sub list (@) {
  my (@args) = @_;

  return map {defined $_ ? (ref eq 'ARRAY' ? (@{$_}) : ($_)) : ($_)} @args;
}

sub load ($) {
  my ($data) = @_;

  return space($data)->do('load');
}

sub log (@) {
  my (@args) = @_;

  state $codes = {
    debug => 'debug',
    error => 'error',
    fatal => 'fatal',
    info => 'info',
    trace => 'trace',
    warn => 'warn',
  };

  unshift @args, 'debug' if @args && !$codes->{$args[0]};

  require Venus::Log;

  my $log = Venus::Log->new($ENV{VENUS_LOG_LEVEL});

  return $log if !@args;

  my $code = shift @args;

  return $log->$code(@args);
}

sub make (@) {

  return if !@_;

  return call($_[0], 'new', @_);
}

sub map ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Map;

  if (!$code) {
    return Venus::Map->new($data);
  }

  return Venus::Map->new($data)->$code(@args);
}

sub match ($;&) {
  my ($data, $code) = @_;

  require Venus::Match;

  my $match = Venus::Match->new($data);

  return $match if !$code;

  local $_ = $match;

  my $returned = $code->($match, $data);

  $match->data($returned) if ref $returned eq 'HASH';

  return $match->result;
}

sub merge {
  my ($lvalue, @rvalues) = @_;

  return merge_join($lvalue, @rvalues);
}

sub merge_flat {
  my ($lvalue, @rvalues) = @_;

  return $lvalue if !@rvalues;

  if (@rvalues > 1) {
    my $result = $lvalue;

    $result = merge_flat($result, $_) for @rvalues;

    return $result;
  }

  my $rvalue = $rvalues[0];

  return $rvalue if !ref($lvalue) && !ref($rvalue);

  return $rvalue if !ref($lvalue) && ref($rvalue);

  if (ref($lvalue) eq 'ARRAY' && !ref($rvalue)) {
    return [@$lvalue, $rvalue];
  }

  if (ref($lvalue) eq 'ARRAY' && ref($rvalue) eq 'ARRAY') {
    return [@$lvalue, @$rvalue];
  }

  if (ref($lvalue) eq 'ARRAY' && ref($rvalue) eq 'HASH') {
    return [@$lvalue, values %$rvalue];
  }

  return $rvalue if ref($lvalue) eq 'HASH' && (!ref($rvalue) || ref($rvalue) eq 'ARRAY');

  if (ref($lvalue) eq 'HASH' && ref($rvalue) eq 'HASH') {
    my $result = {%$lvalue};
    for my $key (keys %$rvalue) {
      $result->{$key} = exists $lvalue->{$key} ? merge_flat($lvalue->{$key}, $rvalue->{$key}) : $rvalue->{$key};
    }
    return $result;
  }

  return $lvalue;
}

sub merge_flat_mutate {
  my ($lvalue, @rvalues) = @_;

  return $lvalue if !@rvalues;

  if (@rvalues > 1) {
    $lvalue = merge_flat_mutate($lvalue, $_) for @rvalues;
    return $lvalue;
  }

  my $rvalue = $rvalues[0];

  return $_[0] = $rvalue if !ref($lvalue) && !ref($rvalue);

  return $_[0] = $rvalue if !ref($lvalue) && ref($rvalue);

  if (ref($lvalue) eq 'ARRAY' && !ref($rvalue)) {
    push @$lvalue, $rvalue;
    return $lvalue;
  }

  if (ref($lvalue) eq 'ARRAY' && ref($rvalue) eq 'ARRAY') {
    push @$lvalue, @$rvalue;
    return $lvalue;
  }

  if (ref($lvalue) eq 'ARRAY' && ref($rvalue) eq 'HASH') {
    push @$lvalue, values %$rvalue;
    return $lvalue;
  }

  return $_[0] = $rvalue if ref($lvalue) eq 'HASH' && (!ref($rvalue) || ref($rvalue) eq 'ARRAY');

  if (ref($lvalue) eq 'HASH' && ref($rvalue) eq 'HASH') {
    for my $key (keys %$rvalue) {
      if (exists $lvalue->{$key}) {
        merge_flat_mutate($lvalue->{$key}, $rvalue->{$key});
      } else {
        $lvalue->{$key} = $rvalue->{$key};
      }
    }
    return $lvalue;
  }

  return $lvalue;
}

sub merge_join {
  my ($lvalue, @rvalues) = @_;

  return $lvalue if !@rvalues;

  if (@rvalues > 1) {
    my $result = $lvalue;

    $result = merge_join($result, $_) for @rvalues;

    return $result;
  }

  my $rvalue = $rvalues[0];

  return $rvalue if !ref($lvalue) && !ref($rvalue);

  return $rvalue if !ref($lvalue) && ref($rvalue);

  if (ref($lvalue) eq 'ARRAY' && !ref($rvalue)) {
    return [@$lvalue, $rvalue];
  }

  if (ref($lvalue) eq 'ARRAY' && ref($rvalue) eq 'ARRAY') {
    return [@$lvalue, @$rvalue];
  }

  if (ref($lvalue) eq 'ARRAY' && ref($rvalue) eq 'HASH') {
    return [@$lvalue, $rvalue];
  }

  return $rvalue if ref($lvalue) eq 'HASH' && (!ref($rvalue) || ref($rvalue) eq 'ARRAY');

  if (ref($lvalue) eq 'HASH' && ref($rvalue) eq 'HASH') {
    my $result = {%$lvalue};
    for my $key (keys %$rvalue) {
      $result->{$key} = exists $lvalue->{$key} ? merge_join($lvalue->{$key}, $rvalue->{$key}) : $rvalue->{$key};
    }
    return $result;
  }

  return $lvalue;
}

sub merge_join_mutate {
  my ($lvalue, @rvalues) = @_;

  return $lvalue if !@rvalues;

  if (@rvalues > 1) {
    $lvalue = merge_join_mutate($lvalue, $_) for @rvalues;
    return $lvalue;
  }

  my $rvalue = $rvalues[0];

  return $_[0] = $rvalue if !ref($lvalue) && !ref($rvalue);

  return $_[0] = $rvalue if !ref($lvalue) && ref($rvalue);

  if (ref($lvalue) eq 'ARRAY' && !ref($rvalue)) {
    push @$lvalue, $rvalue;
    return $lvalue;
  }

  if (ref($lvalue) eq 'ARRAY' && ref($rvalue) eq 'ARRAY') {
    push @$lvalue, @$rvalue;
    return $lvalue;
  }

  if (ref($lvalue) eq 'ARRAY' && ref($rvalue) eq 'HASH') {
    push @$lvalue, $rvalue;
    return $lvalue;
  }

  return $_[0] = $rvalue if ref($lvalue) eq 'HASH' && (!ref($rvalue) || ref($rvalue) eq 'ARRAY');

  if (ref($lvalue) eq 'HASH' && ref($rvalue) eq 'HASH') {
    for my $key (keys %$rvalue) {
      if (exists $lvalue->{$key}) {
        merge_join_mutate($lvalue->{$key}, $rvalue->{$key});
      } else {
        $lvalue->{$key} = $rvalue->{$key};
      }
    }
    return $lvalue;
  }

  return $lvalue;
}

sub merge_keep {
  my ($lvalue, @rvalues) = @_;

  return $lvalue if !@rvalues;

  if (@rvalues > 1) {
    my $result = $lvalue;

    $result = merge_keep($result, $_) for @rvalues;

    return $result;
  }

  my $rvalue = $rvalues[0];

  return $lvalue if !ref($lvalue) && !ref($rvalue);

  return $lvalue if !ref($lvalue) && ref($rvalue);

  if (ref($lvalue) eq 'ARRAY' && !ref($rvalue)) {
    return [@$lvalue, $rvalue];
  }

  if (ref($lvalue) eq 'ARRAY' && ref($rvalue) eq 'ARRAY') {
    return [@$lvalue, @$rvalue];
  }

  if (ref($lvalue) eq 'ARRAY' && ref($rvalue) eq 'HASH') {
    return [@$lvalue, $rvalue];
  }

  return $lvalue if ref($lvalue) eq 'HASH' && (!ref($rvalue) || ref($rvalue) eq 'ARRAY');

  if (ref($lvalue) eq 'HASH' && ref($rvalue) eq 'HASH') {
    my $result = {%$lvalue};
    for my $key (keys %$rvalue) {
      $result->{$key} = exists $lvalue->{$key} ? merge_keep($lvalue->{$key}, $rvalue->{$key}) : $rvalue->{$key};
    }
    return $result;
  }

  return $lvalue;
}

sub merge_keep_mutate {
  my ($lvalue, @rvalues) = @_;

  return $lvalue if !@rvalues;

  if (@rvalues > 1) {
    $lvalue = merge_keep_mutate($lvalue, $_) for @rvalues;
    return $lvalue;
  }

  my $rvalue = $rvalues[0];

  return $lvalue if !ref($lvalue) && !ref($rvalue);

  return $lvalue if !ref($lvalue) && ref($rvalue);

  if (ref($lvalue) eq 'ARRAY' && !ref($rvalue)) {
    push @$lvalue, $rvalue;
    return $lvalue;
  }

  if (ref($lvalue) eq 'ARRAY' && ref($rvalue) eq 'ARRAY') {
    push @$lvalue, @$rvalue;
    return $lvalue;
  }

  if (ref($lvalue) eq 'ARRAY' && ref($rvalue) eq 'HASH') {
    push @$lvalue, $rvalue;
    return $lvalue;
  }

  return $lvalue if ref($lvalue) eq 'HASH' && (!ref($rvalue) || ref($rvalue) eq 'ARRAY');

  if (ref($lvalue) eq 'HASH' && ref($rvalue) eq 'HASH') {
    for my $key (keys %$rvalue) {
      if (!exists $lvalue->{$key}) {
        $lvalue->{$key} = $rvalue->{$key};
      } else {
        merge_keep_mutate($lvalue->{$key}, $rvalue->{$key});
      }
    }
    return $lvalue;
  }

  return $lvalue;
}

sub merge_swap {
  my ($lvalue, @rvalues) = @_;

  return $lvalue if !@rvalues;

  if (@rvalues > 1) {
    my $result = $lvalue;

    $result = merge_swap($result, $_) for @rvalues;

    return $result;
  }

  my $rvalue = $rvalues[0];

  return $rvalue if !ref($lvalue) && !ref($rvalue);

  return $rvalue if !ref($lvalue) && ref($rvalue);

  if (ref($lvalue) eq 'ARRAY' && !ref($rvalue)) {
    return [@$lvalue, $rvalue];
  }

  if (ref($lvalue) eq 'ARRAY' && ref($rvalue) eq 'ARRAY') {
    my $result = [@$lvalue];
    for my $i (0..$#$rvalue) {
      $result->[$i] = $rvalue->[$i] if exists $rvalue->[$i];
    }
    return $result;
  }

  if (ref($lvalue) eq 'ARRAY' && ref($rvalue) eq 'HASH') {
    return [@$lvalue, $rvalue];
  }

  return $rvalue if ref($lvalue) eq 'HASH' && (!ref($rvalue) || ref($rvalue) eq 'ARRAY');

  if (ref($lvalue) eq 'HASH' && ref($rvalue) eq 'HASH') {
    my $result = {%$lvalue};
    for my $key (keys %$rvalue) {
      $result->{$key} = exists $lvalue->{$key} ? merge_swap($lvalue->{$key}, $rvalue->{$key}) : $rvalue->{$key};
    }
    return $result;
  }

  return $lvalue;
}

sub merge_swap_mutate {
  my ($lvalue, @rvalues) = @_;

  return $lvalue if !@rvalues;

  if (@rvalues > 1) {
    $lvalue = merge_swap_mutate($lvalue, $_) for @rvalues;
    return $lvalue;
  }

  my $rvalue = $rvalues[0];

  return $_[0] = $rvalue if !ref($lvalue) && !ref($rvalue);

  return $_[0] = $rvalue if !ref($lvalue) && ref($rvalue);

  if (ref($lvalue) eq 'ARRAY' && !ref($rvalue)) {
    push @$lvalue, $rvalue;
    return $lvalue;
  }

  if (ref($lvalue) eq 'ARRAY' && ref($rvalue) eq 'ARRAY') {
    for my $i (0..$#$rvalue) {
      $lvalue->[$i] = $rvalue->[$i] if exists $rvalue->[$i];
    }
    return $lvalue;
  }

  if (ref($lvalue) eq 'ARRAY' && ref($rvalue) eq 'HASH') {
    push @$lvalue, $rvalue;
    return $lvalue;
  }

  return $_[0] = $rvalue if ref($lvalue) eq 'HASH' && (!ref($rvalue) || ref($rvalue) eq 'ARRAY');

  if (ref($lvalue) eq 'HASH' && ref($rvalue) eq 'HASH') {
    for my $key (keys %$rvalue) {
      if (exists $lvalue->{$key}) {
        merge_swap_mutate($lvalue->{$key}, $rvalue->{$key});
      } else {
        $lvalue->{$key} = $rvalue->{$key};
      }
    }
    return $lvalue;
  }

  return $lvalue;
}

sub merge_take {
  my ($lvalue, @rvalues) = @_;

  return $lvalue if !@rvalues;

  if (@rvalues > 1) {
    my $result = $lvalue;

    $result = merge_take($result, $_) for @rvalues;

    return $result;
  }

  my $rvalue = $rvalues[0];

  if (ref($rvalue) eq 'ARRAY') {
    return [map {merge_take(undef, $_)} @$rvalue];
  }

  if (ref($lvalue) eq 'HASH' && ref($rvalue) eq 'HASH') {
    my $result = {%$lvalue};
    foreach my $key (keys %$rvalue) {
      $result->{$key} = merge_take($lvalue->{$key}, $rvalue->{$key});
    }
    return $result;
  }

  if (ref($rvalue) eq 'HASH') {
    return {%$rvalue};
  }

  return $rvalue;
}

sub merge_take_mutate {
  my ($lvalue, @rvalues) = @_;

  return $lvalue if !@rvalues;

  if (@rvalues > 1) {
    $lvalue = merge_take_mutate($lvalue, $_) for @rvalues;
    return $lvalue;
  }

  my $rvalue = $rvalues[0];

  if (ref($lvalue) eq 'ARRAY' && ref($rvalue) eq 'ARRAY') {
    @$lvalue = @$rvalue;
    return $lvalue;
  }

  if (ref($lvalue) eq 'HASH' && ref($rvalue) eq 'HASH') {
    foreach my $key (keys %$rvalue) {
      $lvalue->{$key} = merge_take_mutate($lvalue->{$key}, $rvalue->{$key});
    }
    return $lvalue;
  }

  return $_[0] = $rvalue;
}

sub meta ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Meta;

  if (!$code) {
    return Venus::Meta->new(name => $data);
  }

  return Venus::Meta->new(name => $data)->$code(@args);
}

sub name ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Name;

  if (!$code) {
    return Venus::Name->new($data);
  }

  return Venus::Name->new($data)->$code(@args);
}

sub number ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Number;

  if (!$code) {
    return Venus::Number->new($data);
  }

  return Venus::Number->new($data)->$code(@args);
}

sub opts ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Opts;

  if (!$code) {
    return Venus::Opts->new($data);
  }

  return Venus::Opts->new($data)->$code(@args);
}

sub pairs (@) {
  my ($args) = @_;

  my $result = defined $args
    ? (
    ref $args eq 'ARRAY'
    ? ([map {[$_, $args->[$_]]} 0..$#{$args}])
    : (ref $args eq 'HASH' ? ([map {[$_, $args->{$_}]} sort keys %{$args}]) : ([])))
    : [];

  return wantarray ? @{$result} : $result;
}

sub path ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Path;

  if (!$code) {
    return Venus::Path->new($data);
  }

  return Venus::Path->new($data)->$code(@args);
}

sub perl (;$$) {
  my ($code, $data) = @_;

  require Venus::Dump;

  if (!$code) {
    return Venus::Dump->new;
  }

  if (lc($code) eq 'decode') {
    return Venus::Dump->new->decode($data);
  }

  if (lc($code) eq 'encode') {
    return Venus::Dump->new(value => $data)->encode;
  }

  return fault(qq(Invalid "perl" action "$code"));
}

sub process (;$@) {
  my ($code, @args) = @_;

  require Venus::Process;

  if (!$code) {
    return Venus::Process->new;
  }

  return Venus::Process->new->$code(@args);
}

sub proto ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Prototype;

  if (!$code) {
    return Venus::Prototype->new($data);
  }

  return Venus::Prototype->new($data)->$code(@args);
}

sub puts ($;@) {
  my ($data, @args) = @_;

  $data = cast($data);

  my $result = [];

  if ($data->isa('Venus::Hash')) {
    $result = $data->puts(@args);
  }
  elsif ($data->isa('Venus::Array')) {
    $result = $data->puts(@args);
  }

  return wantarray ? (@{$result}) : $result;
}

sub raise ($;@) {
  my ($self, @args) = @_;

  ($self, my $parent) = (@$self) if (ref($self) eq 'ARRAY');

  my $data = kvargs(@args);

  $data->{context} ||= (caller(1))[3];

  $parent = 'Venus::Error' if !$parent;

  require Venus::Throw;

  return Venus::Throw->new(package => $self, parent => $parent)->die($data);
}

sub random (;$@) {
  my ($code, @args) = @_;

  require Venus::Random;

  state $random = Venus::Random->new;

  if (!$code) {
    return $random;
  }

  return $random->$code(@args);
}

sub range ($;@) {
  my ($data, @args) = @_;

  return array($data, 'range', @args);
}

sub read_env ($) {
  my ($data) = @_;

  require Venus::Config;

  return Venus::Config->new->read_env($data);
}

sub read_env_file ($) {
  my ($data) = @_;

  require Venus::Config;

  return Venus::Config->new->read_env_file($data);
}

sub read_json ($) {
  my ($data) = @_;

  require Venus::Config;

  return Venus::Config->new->read_json($data);
}

sub read_json_file ($) {
  my ($data) = @_;

  require Venus::Config;

  return Venus::Config->new->read_json_file($data);
}

sub read_perl ($) {
  my ($data) = @_;

  require Venus::Config;

  return Venus::Config->new->read_perl($data);
}

sub read_perl_file ($) {
  my ($data) = @_;

  require Venus::Config;

  return Venus::Config->new->read_perl_file($data);
}

sub read_yaml ($) {
  my ($data) = @_;

  require Venus::Config;

  return Venus::Config->new->read_yaml($data);
}

sub read_yaml_file ($) {
  my ($data) = @_;

  require Venus::Config;

  return Venus::Config->new->read_yaml_file($data);
}

sub regexp ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Regexp;

  if (!$code) {
    return Venus::Regexp->new($data);
  }

  return Venus::Regexp->new($data)->$code(@args);
}

sub render ($;$) {
  my ($data, $args) = @_;

  return template($data, 'render', undef, $args || {});
}

sub replace ($;$@) {
  my ($data, $code, @args) = @_;

  my @keys = qw(
    string
    regexp
    substr
  );

  my @data = (ref $data eq 'ARRAY' ? (map +(shift(@keys), $_), @{$data}) : $data);

  require Venus::Replace;

  if (!$code) {
    return Venus::Replace->new(@data);
  }

  return Venus::Replace->new(@data)->$code(@args);
}

sub roll (@) {

  return (@_[1,0,2..$#_]);
}

sub schema (;$@) {
  my ($code, @args) = @_;

  require Venus::Schema;

  if (!$code) {
    return Venus::Schema->new;
  }

  return Venus::Schema->new->$code(@args);
}

sub search ($;$@) {
  my ($data, $code, @args) = @_;

  my @keys = qw(
    string
    regexp
  );

  my @data = (ref $data eq 'ARRAY' ? (map +(shift(@keys), $_), @{$data}) : $data);

  require Venus::Search;

  if (!$code) {
    return Venus::Search->new(@data);
  }

  return Venus::Search->new(@data)->$code(@args);
}

sub set ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Set;

  if (!$code) {
    return Venus::Set->new($data);
  }

  return Venus::Set->new($data)->$code(@args);
}

sub sets ($;@) {
  my ($data, @args) = @_;

  $data = cast($data);

  my $result = [];

  if ($data->isa('Venus::Hash')) {
    $result = $data->sets(@args);

    $_[0] = $data->get;
  }
  elsif ($data->isa('Venus::Array')) {
    $result = $data->sets(@args);

    $_[0] = $data->get;
  }

  return wantarray ? (@{$result}) : $result;
}

sub space ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Space;

  if (!$code) {
    return Venus::Space->new($data);
  }

  return Venus::Space->new($data)->$code(@args);
}

sub sorts (@) {

  return CORE::sort(map list($_), @_);
}

sub string ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::String;

  if (!$code) {
    return Venus::String->new($data);
  }

  return Venus::String->new($data)->$code(@args);
}

sub syscall ($;@) {
  my (@args) = @_;

  require Venus::Os;

  for (my $i = 0; $i < @args; $i++) {
    if ($args[$i] =~ /^\|+$/) {
      next;
    }
    if ($args[$i] =~ /^\&+$/) {
      next;
    }
    if ($args[$i] =~ /^\w+$/) {
      next;
    }
    if ($args[$i] =~ /^[<>]+$/) {
      next;
    }
    if ($args[$i] =~ /^\d[<>&]+\d?$/) {
      next;
    }
    if ($args[$i] =~ /\$[A-Z]\w+/) {
      next;
    }
    if ($args[$i] =~ /^\$\((.*)\)$/) {
      next;
    }
    $args[$i] = Venus::Os->quote($args[$i]);
  }

  my ($data, $exit, $code) = (_qx(@args));

  return wantarray ? ($data, $code) : (($exit == 0) ? true() : false());
}

sub template ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Template;

  if (!$code) {
    return Venus::Template->new($data);
  }

  return Venus::Template->new($data)->$code(@args);
}

sub test ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Test;

  if (!$code) {
    return Venus::Test->new($data);
  }

  return Venus::Test->new($data)->$code(@args);
}

sub text_pod ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Text::Pod;

  if (!$code) {
    return Venus::Text::Pod->new($data);
  }

  return Venus::Text::Pod->new($data)->$code(@args);
}

sub text_pod_string {
  my (@args) = @_;

  my $file = (grep -f, (caller(0))[1], $0)[0];

  return text_pod($file, 'string', @args > 1 ? @args : (undef, @args));
}

sub text_tag ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Text::Tag;

  if (!$code) {
    return Venus::Text::Tag->new($data);
  }

  return Venus::Text::Tag->new($data)->$code(@args);
}

sub text_tag_string {
  my (@args) = @_;

  my $file = (grep -f, (caller(0))[1], $0)[0];

  return text_tag($file, 'string', @args > 1 ? @args : (undef, @args));
}

sub then (@) {

  return ($_[0], call(@_));
}

sub throw ($;$@) {
  my ($data, $code, @args) = @_;

  $data ||= {};

  require Venus::Throw;

  my $throw = Venus::Throw->new(context => (caller(1))[3]);

  $data = {package => $data} if ref $data ne 'HASH';

  for my $key (keys %{$data}) {
    $throw->$key($data->{$key}) if $throw->can($key);
  }

  return $throw if !$code;

  return $throw->$code(@args);
}

sub true () {

  require Venus::True;

  return Venus::True->value;
}

sub try ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Try;

  if (!$code) {
    return Venus::Try->new($data);
  }

  return Venus::Try->new($data)->$code(@args);
}

sub tv {
  my ($lvalue, $rvalue) = @_;

  require Scalar::Util;

  if (is($lvalue, $rvalue)) {
    return true();
  }
  if (!defined($lvalue) && !defined($rvalue)) {
    return true();
  }
  if (!defined($lvalue) || !defined($rvalue)) {
    return false();
  }
  if (ref($lvalue) && ref($rvalue)) {
    if (Scalar::Util::blessed($lvalue) && Scalar::Util::blessed($rvalue)) {
      if (ref($lvalue) ne ref($rvalue)) {
        return false();
      }
      if (UNIVERSAL::isa($lvalue, 'HASH')) {
        return tv({%$lvalue}, {%$rvalue});
      }
      elsif (UNIVERSAL::isa($lvalue, 'ARRAY')) {
        return tv([@$lvalue], [@$rvalue]);
      }
      elsif (UNIVERSAL::isa($lvalue, 'REF')) {
        return tv($$lvalue, $$rvalue);
      }
      elsif (UNIVERSAL::isa($lvalue, 'SCALAR')) {
        return tv($$lvalue, $$rvalue);
      }
      elsif (UNIVERSAL::isa($lvalue, 'GLOB')) {
        return *$lvalue eq *$rvalue;
      }
      elsif (UNIVERSAL::isa($lvalue, 'REGEXP')) {
        return $lvalue eq $rvalue;
      }
      else {
        return false();
      }
    }
    else {
      if (ref($lvalue) eq 'ARRAY') {
        if (@$lvalue != @$rvalue) {
          return false();
        }
        for my $i (0 .. $#$lvalue) {
          if (!tv($lvalue->[$i], $rvalue->[$i])) {
            return false();
          }
        }
        return true();
      }
      elsif (ref($lvalue) eq 'HASH') {
        if (keys %$lvalue != keys %$rvalue) {
          return false();
        }
        for my $key (keys %$lvalue) {
          if (!exists $rvalue->{$key} || !tv($lvalue->{$key}, $rvalue->{$key})) {
            return false();
          }
        }
        return true();
      }
      elsif (ref($lvalue) eq 'SCALAR') {
        return tv($$lvalue, $$rvalue);
      }
      elsif (ref($lvalue) eq 'GLOB') {
        return *$lvalue eq *$rvalue;
      }
      elsif (ref($lvalue) eq 'REF') {
        return tv($$lvalue, $$rvalue);
      }
      elsif (ref($lvalue) eq 'REGEXP') {
        return $lvalue eq $rvalue;
      }
      else {
        return false();
      }
    }
  }
  if (!ref($lvalue) && !ref($rvalue)) {
    require Venus::What;

    if (Venus::What::scalar_is_boolean($lvalue) && Venus::What::scalar_is_boolean($rvalue)) {
      return $lvalue == $rvalue;
    }
    elsif (Venus::What::scalar_is_numeric($lvalue) && Venus::What::scalar_is_numeric($rvalue)) {
      return $lvalue == $rvalue;
    }
    elsif (!Venus::What::scalar_is_numeric($lvalue) && !Venus::What::scalar_is_numeric($rvalue)) {
      return $lvalue eq $rvalue;
    }
    else {
      return false();
    }
  }
  else {
    return false();
  }
}

sub type {
  my ($code, @args) = @_;

  require Venus::Type;

  if (!$code) {
    return Venus::Type->new;
  }

  return Venus::Type->new->$code(@args);
}

sub unpack (@) {
  my (@args) = @_;

  require Venus::Unpack;

  return Venus::Unpack->new->do('args', @args)->all;
}

sub vars ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::Vars;

  if (!$code) {
    return Venus::Vars->new($data);
  }

  return Venus::Vars->new($data)->$code(@args);
}

sub vns ($;@) {
  my ($name, $data, $code, @args) = @_;

  my $space = space('Venus')->child($name)->do('tryload');

  if (!$code) {
    return $space->package->new($#_ > 0 ? $data : ());
  }

  return $space->package->new($#_ > 0 ? $data : ())->$code(@args);
}

sub what ($;$@) {
  my ($data, $code, @args) = @_;

  require Venus::What;

  if (!$code) {
    return Venus::What->new($data);
  }

  return Venus::What->new($data)->$code(@args);
}

sub work ($) {
  my ($data) = @_;

  require Venus::Process;

  return Venus::Process->new->do('work', $data);
}

sub wrap ($;$) {
  my ($data, $name) = @_;

  return if !@_;

  my $moniker = $name // $data =~ s/\W//gr;
  my $caller = caller(0);

  no strict 'refs';
  no warnings 'redefine';

  return *{"${caller}::${moniker}"} = sub {@_ ? make($data, @_) : $data};
}

sub write_env ($) {
  my ($data) = @_;

  require Venus::Config;

  return Venus::Config->new($data)->write_env;
}

sub write_env_file ($$) {
  my ($path, $data) = @_;

  require Venus::Config;

  return Venus::Config->new($data)->write_env_file($path);
}

sub write_json ($) {
  my ($data) = @_;

  require Venus::Config;

  return Venus::Config->new($data)->write_json;
}

sub write_json_file ($$) {
  my ($path, $data) = @_;

  require Venus::Config;

  return Venus::Config->new($data)->write_json_file($path);
}

sub write_perl ($) {
  my ($data) = @_;

  require Venus::Config;

  return Venus::Config->new($data)->write_perl;
}

sub write_perl_file ($$) {
  my ($path, $data) = @_;

  require Venus::Config;

  return Venus::Config->new($data)->write_perl_file($path);
}

sub write_yaml ($) {
  my ($data) = @_;

  require Venus::Config;

  return Venus::Config->new($data)->write_yaml;
}

sub write_yaml_file ($$) {
  my ($path, $data) = @_;

  require Venus::Config;

  return Venus::Config->new($data)->write_yaml_file($path);
}

sub yaml (;$$) {
  my ($code, $data) = @_;

  require Venus::Yaml;

  if (!$code) {
    return Venus::Yaml->new;
  }

  if (lc($code) eq 'decode') {
    return Venus::Yaml->new->decode($data);
  }

  if (lc($code) eq 'encode') {
    return Venus::Yaml->new(value => $data)->encode;
  }

  return fault(qq(Invalid "yaml" action "$code"));
}

1;


=head1 NAME

Venus - Standard Library

=cut

=head1 ABSTRACT

Standard Library for Perl 5

=cut

=head1 VERSION

5.01

=cut

=head1 SYNOPSIS

  package main;

  use Venus 'catch', 'error', 'raise';

  # error handling
  my ($error, $result) = catch {
    error;
  };

  # boolean keywords
  if ($result) {
    error;
  }

  # raise exceptions
  if ($result) {
    raise 'MyApp::Error';
  }

  # boolean keywords, and more!
  my $bool = true ne false;

=cut

=head1 DESCRIPTION

This library provides an object-orientation framework and extendible standard
library for Perl 5 with classes which wrap most native Perl data types. Venus
has a simple modular architecture, robust library of classes, methods, and
roles, supports pure-Perl autoboxing, advanced exception handling, "true" and
"false" functions, package introspection, command-line options parsing, and
more. This package will always automatically exports C<true> and C<false>
keyword functions (unless existing routines of the same name already exist in
the calling package or its parents), otherwise exports keyword functions as
requested at import. This library requires Perl C<5.18+>.

=head1 CAPABILITIES

The following is a short list of capabilities:

=over 4

=item *

Perl 5.18.0+

=item *

Zero Dependencies

=item *

Fast Object-Orientation

=item *

Robust Standard Library

=item *

Intuitive Value Classes

=item *

Pure Perl Autoboxing

=item *

Convenient Utility Classes

=item *

Simple Package Reflection

=item *

Flexible Exception Handling

=item *

Composable Standards

=item *

Pluggable (no monkeypatching)

=item *

Proxyable Methods

=item *

Type Assertions

=item *

Type Coercions

=item *

Value Casting

=item *

Boolean Values

=item *

Complete Documentation

=item *

Complete Test Coverage

=back

=cut

=head1 FUNCTIONS

This package provides the following functions:

=cut

=head2 after

  after(string $name, coderef $code) (coderef)

The after function installs a method modifier that executes after the original
method, allowing you to perform actions after a method call. B<Note:> The
return value of the modifier routine is ignored; the wrapped method always
returns the value from the original method. Modifiers are executed in the order
they are stacked. This function is always exported unless a routine of the same
name already exists.

I<Since C<4.15>>

=over 4

=item after example 1

  package Example;

  use Venus::Class 'after', 'attr';

  attr 'calls';

  sub BUILD {
    my ($self) = @_;
    $self->calls([]);
  }

  sub test {
    my ($self) = @_;
    push @{$self->calls}, 'original';
    return 'original';
  }

  after 'test', sub {
    my ($self) = @_;
    push @{$self->calls}, 'after';
    return 'ignored';
  };

  package main;

  my $example = Example->new;
  my $value = $example->test;

  # "original"

=back

=over 4

=item after example 2

  package Example2;

  use Venus::Class 'after', 'attr';

  attr 'calls';

  sub BUILD {
    my ($self) = @_;
    $self->calls([]);
  }

  sub test {
    my ($self) = @_;
    push @{$self->calls}, 'original';
    return $self;
  }

  after 'test', sub {
    my ($self) = @_;
    push @{$self->calls}, 'after';
    return $self;
  };

  package main;

  my $example = Example2->new;
  $example->test;
  my $calls = $example->calls;

  # ['original', 'after']

=back

=cut

=head2 all

  all(arrayref | hashref | consumes[Venus::Role::Mappable] $lvalue, any $rvalue) (boolean)

The all function accepts an arrayref, hashref, or
L<"mappable"|Venus::Role::Mappable> and returns true if the rvalue is a
callback and returns true for all items in the collection. If the rvalue
provided is not a coderef that value's type and value will be used as the
criteria.

I<Since C<4.15>>

=over 4

=item all example 1

  # given: synopsis

  package main;

  use Venus 'all';

  my $all = all [1, '1'], 1;

  # false

=back

=over 4

=item all example 2

  # given: synopsis

  package main;

  use Venus 'all';

  my $all = all [1, 1], 1;

  # true

=back

=over 4

=item all example 3

  # given: synopsis

  package main;

  use Venus 'all';

  my $all = all {1, 2}, 1;

  # false

=back

=over 4

=item all example 4

  # given: synopsis

  package main;

  use Venus 'all';

  my $all = all {1, 1}, 1;

  # true

=back

=over 4

=item all example 5

  # given: synopsis

  package main;

  use Venus 'all';

  my $all = all [[1], [1]], [1];

  # true

=back

=over 4

=item all example 6

  # given: synopsis

  package main;

  use Venus 'all';

  my $all = all [1, '1', 2..4], sub{$_ > 0};

  # true

=back

=over 4

=item all example 7

  # given: synopsis

  package main;

  use Venus 'all';

  my $all = all [1, '1', 2..4], sub{$_ > 1};

  # false

=back

=cut

=head2 any

  any(arrayref | hashref | consumes[Venus::Role::Mappable] $lvalue, any $rvalue) (boolean)

The any function accepts an arrayref, hashref, or
L<"mappable"|Venus::Role::Mappable> and returns true if the rvalue is a
callback and returns true for any items in the collection. If the rvalue
provided is not a coderef that value's type and value will be used as the
criteria.

I<Since C<4.15>>

=over 4

=item any example 1

  # given: synopsis

  package main;

  use Venus 'any';

  my $any = any [1, '1'], 1;

  # true

=back

=over 4

=item any example 2

  # given: synopsis

  package main;

  use Venus 'any';

  my $any = any [1, 1], 0;

  # false

=back

=over 4

=item any example 3

  # given: synopsis

  package main;

  use Venus 'any';

  my $any = any {1, 2}, 1;

  # false

=back

=over 4

=item any example 4

  # given: synopsis

  package main;

  use Venus 'any';

  my $any = any {1, 1}, 1;

  # true

=back

=over 4

=item any example 5

  # given: synopsis

  package main;

  use Venus 'any';

  my $any = any [[0], [1]], [1];

  # true

=back

=over 4

=item any example 6

  # given: synopsis

  package main;

  use Venus 'any';

  my $any = any [1, '1', 2..4], sub{!defined};

  # false

=back

=over 4

=item any example 7

  # given: synopsis

  package main;

  use Venus 'any';

  my $any = any [1, '1', 2..4, undef], sub{!defined};

  # true

=back

=cut

=head2 args

  args(arrayref $value, string | coderef $code, any @args) (any)

The args function builds and returns a L<Venus::Args> object, or dispatches to
the coderef or method provided.

I<Since C<3.10>>

=over 4

=item args example 1

  package main;

  use Venus 'args';

  my $args = args ['--resource', 'users'];

  # bless({...}, 'Venus::Args')

=back

=over 4

=item args example 2

  package main;

  use Venus 'args';

  my $args = args ['--resource', 'users'], 'indexed';

  # {0 => '--resource', 1 => 'users'}

=back

=cut

=head2 around

  around(string $name, coderef $code) (coderef)

The around function installs a method modifier that wraps around the original
method, giving you complete control over its execution. The modifier receives
the original method as its first argument, followed by the method's arguments,
and must explicitly call the original method if desired.

I<Since C<4.15>>

=over 4

=item around example 1

  package Example3;

  use Venus::Class 'around', 'attr';

  sub test {
    my ($self, $value) = @_;
    return $value;
  }

  around 'test', sub {
    my ($orig, $self, $value) = @_;
    my $result = $self->$orig($value);
    return $result * 2;
  };

  package main;

  my $result = Example3->new->test(5);

  # 10

=back

=over 4

=item around example 2

  package Example4;

  use Venus::Class 'around', 'attr';

  attr 'calls';

  sub BUILD {
    my ($self) = @_;
    $self->calls([]);
  }

  sub test {
    my ($self) = @_;
    push @{$self->calls}, 'original';
    return $self;
  }

  around 'test', sub {
    my ($orig, $self) = @_;
    push @{$self->calls}, 'before';
    $self->$orig;
    push @{$self->calls}, 'after';
    return $self;
  };

  package main;

  my $example = Example4->new;
  $example->test;
  my $calls = $example->calls;

  # ['before', 'original', 'after']

=back

=cut

=head2 array

  array(arrayref | hashref $value, string | coderef $code, any @args) (any)

The array function builds and returns a L<Venus::Array> object, or dispatches
to the coderef or method provided.

I<Since C<2.55>>

=over 4

=item array example 1

  package main;

  use Venus 'array';

  my $array = array [];

  # bless({...}, 'Venus::Array')

=back

=over 4

=item array example 2

  package main;

  use Venus 'array';

  my $array = array [1..4], 'push', 5..9;

  # [1..9]

=back

=cut

=head2 arrayref

  arrayref(any @args) (arrayref)

The arrayref function takes a list of arguments and returns a arrayref.

I<Since C<3.10>>

=over 4

=item arrayref example 1

  package main;

  use Venus 'arrayref';

  my $arrayref = arrayref(content => 'example');

  # [content => "example"]

=back

=over 4

=item arrayref example 2

  package main;

  use Venus 'arrayref';

  my $arrayref = arrayref([content => 'example']);

  # [content => "example"]

=back

=over 4

=item arrayref example 3

  package main;

  use Venus 'arrayref';

  my $arrayref = arrayref('content');

  # ['content']

=back

=cut

=head2 assert

  assert(any $data, string $expr) (any)

The assert function builds a L<Venus::Assert> object and returns the result of
a L<Venus::Assert/validate> operation.

I<Since C<2.40>>

=over 4

=item assert example 1

  package main;

  use Venus 'assert';

  my $assert = assert(1234567890, 'number');

  # 1234567890

=back

=over 4

=item assert example 2

  package main;

  use Venus 'assert';

  my $assert = assert(1234567890, 'float');

  # Exception! (isa Venus::Check::Error)

=back

=over 4

=item assert example 3

  package main;

  use Venus 'assert';

  my $assert = assert(1234567890, 'number | float');

  # 1234567890

=back

=cut

=head2 async

  async(coderef $code, any @args) (Venus::Future)

The async function accepts a callback and executes it asynchronously via
L<Venus::Process/future>. This function returns a L<Venus::Future> object which
can be fulfilled via L<Venus::Future/wait>.

I<Since C<3.40>>

=over 4

=item async example 1

  package main;

  use Venus 'async';

  my $async = async sub{
    'done'
  };

  # bless({...}, 'Venus::Future')

=back

=cut

=head2 atom

  atom(any $value) (Venus::Atom)

The atom function builds and returns a L<Venus::Atom> object.

I<Since C<3.55>>

=over 4

=item atom example 1

  package main;

  use Venus 'atom';

  my $atom = atom 'super-admin';

  # bless({scope => sub{...}}, "Venus::Atom")

  # "$atom"

  # "super-admin"

=back

=cut

=head2 await

  await(Venus::Future $future, number $timeout) (any)

The await function accepts a L<Venus::Future> object and eventually returns a
value (or values) for it. The value(s) returned are the return values or
emissions from the asychronous callback executed with L</async> which produced
the process object.

I<Since C<3.40>>

=over 4

=item await example 1

  package main;

  use Venus 'async', 'await';

  my $process;

  my $async = async sub{
    return 'done';
  };

  my $await = await $async;

  # bless(..., "Venus::Future")

=back

=cut

=head2 before

  before(string $name, coderef $code) (coderef)

The before function installs a method modifier that executes before the
original method, allowing you to perform actions before a method call. B<Note:>
The return value of the modifier routine is ignored; the wrapped method always
returns the value from the original method. Modifiers are executed in the order
they are stacked. This function is always exported unless a routine of the same
name already exists.

I<Since C<4.15>>

=over 4

=item before example 1

  package Example5;

  use Venus::Class 'attr', 'before';

  attr 'calls';

  sub BUILD {
    my ($self) = @_;
    $self->calls([]);
  }

  sub test {
    my ($self) = @_;
    push @{$self->calls}, 'original';
    return $self;
  }

  before 'test', sub {
    my ($self) = @_;
    push @{$self->calls}, 'before';
    return $self;
  };

  package main;

  my $example = Example5->new;
  $example->test;
  my $calls = $example->calls;

  # ['before', 'original']

=back

=over 4

=item before example 2

  package Example6;

  use Venus::Class 'attr', 'before';

  attr 'validated';

  sub test {
    my ($self, $value) = @_;
    return $value;
  }

  before 'test', sub {
    my ($self, $value) = @_;
    $self->validated(1) if $value > 0;
    return 'ignored';
  };

  package main;

  my $example = Example6->new;
  my $value = $example->test(5);

  # 5

=back

=cut

=head2 bool

  bool(any $value) (Venus::Boolean)

The bool function builds and returns a L<Venus::Boolean> object.

I<Since C<2.55>>

=over 4

=item bool example 1

  package main;

  use Venus 'bool';

  my $bool = bool;

  # bless({value => 0}, 'Venus::Boolean')

=back

=over 4

=item bool example 2

  package main;

  use Venus 'bool';

  my $bool = bool 1_000;

  # bless({value => 1}, 'Venus::Boolean')

=back

=cut

=head2 box

  box(any $data) (Venus::Box)

The box function returns a L<Venus::Box> object for the argument provided.

I<Since C<2.32>>

=over 4

=item box example 1

  package main;

  use Venus 'box';

  my $box = box({});

  # bless({value => bless({value => {}}, 'Venus::Hash')}, 'Venus::Box')

=back

=over 4

=item box example 2

  package main;

  use Venus 'box';

  my $box = box([]);

  # bless({value => bless({value => []}, 'Venus::Array')}, 'Venus::Box')

=back

=cut

=head2 call

  call(string | object | coderef $data, any @args) (any)

The call function dispatches function and method calls to a package and returns
the result.

I<Since C<2.32>>

=over 4

=item call example 1

  package main;

  use Venus 'call';

  require Digest::SHA;

  my $result = call(\'Digest::SHA', 'new');

  # bless(do{\(my $o = '...')}, 'digest::sha')

=back

=over 4

=item call example 2

  package main;

  use Venus 'call';

  require Digest::SHA;

  my $result = call('Digest::SHA', 'sha1_hex');

  # "da39a3ee5e6b4b0d3255bfef95601890afd80709"

=back

=over 4

=item call example 3

  package main;

  use Venus 'call';

  require Venus::Hash;

  my $result = call(sub{'Venus::Hash'->new(@_)}, {1..4});

  # bless({value => {1..4}}, 'Venus::Hash')

=back

=over 4

=item call example 4

  package main;

  use Venus 'call';

  require Venus::Box;

  my $result = call(Venus::Box->new(value => {}), 'merge', {1..4});

  # bless({value => bless({value => {1..4}}, 'Venus::Hash')}, 'Venus::Box')

=back

=cut

=head2 cast

  cast(any $data, string $type) (object)

The cast function returns the argument provided as an object, promoting native
Perl data types to data type objects. The optional second argument can be the
name of the type for the object to cast to explicitly.

I<Since C<1.40>>

=over 4

=item cast example 1

  package main;

  use Venus 'cast';

  my $undef = cast;

  # bless({value => undef}, "Venus::Undef")

=back

=over 4

=item cast example 2

  package main;

  use Venus 'cast';

  my @booleans = map cast, true, false;

  # (bless({value => 1}, "Venus::Boolean"), bless({value => 0}, "Venus::Boolean"))

=back

=over 4

=item cast example 3

  package main;

  use Venus 'cast';

  my $example = cast bless({}, "Example");

  # bless({value => 1}, "Example")

=back

=over 4

=item cast example 4

  package main;

  use Venus 'cast';

  my $float = cast 1.23;

  # bless({value => "1.23"}, "Venus::Float")

=back

=cut

=head2 catch

  catch(coderef $block) (Venus::Error, any)

The catch function executes the code block trapping errors and returning the
caught exception in scalar context, and also returning the result as a second
argument in list context.

I<Since C<0.01>>

=over 4

=item catch example 1

  package main;

  use Venus 'catch';

  my $error = catch {die};

  $error;

  # "Died at ..."

=back

=over 4

=item catch example 2

  package main;

  use Venus 'catch';

  my ($error, $result) = catch {error};

  $error;

  # bless({...}, 'Venus::Error')

=back

=over 4

=item catch example 3

  package main;

  use Venus 'catch';

  my ($error, $result) = catch {true};

  $result;

  # 1

=back

=cut

=head2 caught

  caught(object $error, string | tuple[string, string] $identity, coderef $block) (any)

The caught function evaluates the exception object provided and validates its
identity and name (if provided) then executes the code block provided returning
the result of the callback. If no callback is provided this function returns
the exception object on success and C<undef> on failure.

I<Since C<1.95>>

=over 4

=item caught example 1

  package main;

  use Venus 'catch', 'caught', 'error';

  my $error = catch { error };

  my $result = caught $error, 'Venus::Error';

  # bless(..., 'Venus::Error')

=back

=over 4

=item caught example 2

  package main;

  use Venus 'catch', 'caught', 'raise';

  my $error = catch { raise 'Example::Error' };

  my $result = caught $error, 'Venus::Error';

  # bless(..., 'Venus::Error')

=back

=over 4

=item caught example 3

  package main;

  use Venus 'catch', 'caught', 'raise';

  my $error = catch { raise 'Example::Error' };

  my $result = caught $error, 'Example::Error';

  # bless(..., 'Venus::Error')

=back

=over 4

=item caught example 4

  package main;

  use Venus 'catch', 'caught', 'raise';

  my $error = catch { raise 'Example::Error', { name => 'on.test' } };

  my $result = caught $error, ['Example::Error', 'on.test'];

  # bless(..., 'Venus::Error')

=back

=over 4

=item caught example 5

  package main;

  use Venus 'catch', 'caught', 'raise';

  my $error = catch { raise 'Example::Error', { name => 'on.recv' } };

  my $result = caught $error, ['Example::Error', 'on.send'];

  # undef

=back

=over 4

=item caught example 6

  package main;

  use Venus 'catch', 'caught', 'error';

  my $error = catch { error };

  my $result = caught $error, ['Example::Error', 'on.send'];

  # undef

=back

=over 4

=item caught example 7

  package main;

  use Venus 'catch', 'caught', 'error';

  my $error = catch { error };

  my $result = caught $error, ['Example::Error'];

  # undef

=back

=over 4

=item caught example 8

  package main;

  use Venus 'catch', 'caught', 'error';

  my $error = catch { error };

  my $result = caught $error, 'Example::Error';

  # undef

=back

=over 4

=item caught example 9

  package main;

  use Venus 'catch', 'caught', 'error';

  my $error = catch { error { name => 'on.send' } };

  my $result = caught $error, ['Venus::Error', 'on.send'];

  # bless(..., 'Venus::Error')

=back

=over 4

=item caught example 10

  package main;

  use Venus 'catch', 'caught', 'error';

  my $error = catch { error { name => 'on.send.open' } };

  my $result = caught $error, ['Venus::Error', 'on.send'], sub {
    $error->stash('caught', true) if $error->is('on.send.open');
    return $error;
  };

  # bless(..., 'Venus::Error')

=back

=cut

=head2 chain

  chain(string | object | coderef $self, string | within[arrayref, string] @args) (any)

The chain function chains function and method calls to a package (and return
values) and returns the result.

I<Since C<2.32>>

=over 4

=item chain example 1

  package main;

  use Venus 'chain';

  my $result = chain('Venus::Path', ['new', 't'], 'exists');

  # 1

=back

=over 4

=item chain example 2

  package main;

  use Venus 'chain';

  my $result = chain('Venus::Path', ['new', 't'], ['test', 'd']);

  # 1

=back

=cut

=head2 check

  check(any $data, string $expr) (boolean)

The check function builds a L<Venus::Assert> object and returns the result of
a L<Venus::Assert/check> operation.

I<Since C<2.40>>

=over 4

=item check example 1

  package main;

  use Venus 'check';

  my $check = check(rand, 'float');

  # true

=back

=over 4

=item check example 2

  package main;

  use Venus 'check';

  my $check = check(rand, 'string');

  # false

=back

=cut

=head2 clargs

  clargs(arrayref $args, arrayref $spec) (Venus::Args, Venus::Opts, Venus::Vars)

The clargs function accepts a single arrayref of L<Getopt::Long> specs, or an
arrayref of arguments followed by an arrayref of L<Getopt::Long> specs, and
returns a three element list of L<Venus::Args>, L<Venus::Opts>, and
L<Venus::Vars> objects. If only a single arrayref is provided, the arguments
will be taken from C<@ARGV>. If this function is called in scalar context only
the L<Venus::Opts> object will be returned.

I<Since C<3.10>>

=over 4

=item clargs example 1

  package main;

  use Venus 'clargs';

  my ($args, $opts, $vars) = clargs;

  # (
  #   bless(..., 'Venus::Args'),
  #   bless(..., 'Venus::Opts'),
  #   bless(..., 'Venus::Vars')
  # )

=back

=over 4

=item clargs example 2

  package main;

  use Venus 'clargs';

  my ($args, $opts, $vars) = clargs ['resource|r=s', 'help|h'];

  # (
  #   bless(..., 'Venus::Args'),
  #   bless(..., 'Venus::Opts'),
  #   bless(..., 'Venus::Vars')
  # )

=back

=over 4

=item clargs example 3

  package main;

  use Venus 'clargs';

  my ($args, $opts, $vars) = clargs ['--resource', 'help'],
    ['resource|r=s', 'help|h'];

  # (
  #   bless(..., 'Venus::Args'),
  #   bless(..., 'Venus::Opts'),
  #   bless(..., 'Venus::Vars')
  # )

=back

=over 4

=item clargs example 4

  package main;

  use Venus 'clargs';

  my ($args, $opts, $vars) = clargs ['--help', 'how-to'],
    ['resource|r=s', 'help|h'];

  # (
  #   bless(..., 'Venus::Args'),
  #   bless(..., 'Venus::Opts'),
  #   bless(..., 'Venus::Vars')
  # )

=back

=over 4

=item clargs example 5

  package main;

  use Venus 'clargs';

  my $opts = clargs ['--help', 'how-to'], ['resource|r=s', 'help|h'];

  # bless(..., 'Venus::Opts'),

=back

=cut

=head2 cli

  cli(arrayref $args) (Venus::Cli)

The cli function builds and returns a L<Venus::Cli> object.

I<Since C<2.55>>

=over 4

=item cli example 1

  package main;

  use Venus 'cli';

  my $cli = cli;

  # bless({...}, 'Venus::Cli')

=back

=over 4

=item cli example 2

  package main;

  use Venus 'cli';

  my $cli = cli 'mycli';

  # bless({...}, 'Venus::Cli')

  # $cli->boolean('option', 'help');

  # $cli->parse('--help');

  # $cli->option_value('help');

  # 1

=back

=cut

=head2 clone

  clone(ref $value) (ref)

The clone function uses L<Storable/dclone> to perform a deep clone of the
reference provided and returns a copy.

I<Since C<3.55>>

=over 4

=item clone example 1

  package main;

  use Venus 'clone';

  my $orig = {1..4};

  my $clone = clone $orig;

  $orig->{3} = 5;

  my $result = $clone;

  # {1..4}

=back

=over 4

=item clone example 2

  package main;

  use Venus 'clone';

  my $orig = {1,2,3,{1..4}};

  my $clone = clone $orig;

  $orig->{3}->{3} = 5;

  my $result = $clone;

  # {1,2,3,{1..4}}

=back

=cut

=head2 code

  code(coderef $value, string | coderef $code, any @args) (any)

The code function builds and returns a L<Venus::Code> object, or dispatches
to the coderef or method provided.

I<Since C<2.55>>

=over 4

=item code example 1

  package main;

  use Venus 'code';

  my $code = code sub {};

  # bless({...}, 'Venus::Code')

=back

=over 4

=item code example 2

  package main;

  use Venus 'code';

  my $code = code sub {[1, @_]}, 'curry', 2,3,4;

  # sub {...}

=back

=cut

=head2 collect

  collect(any $value, coderef $code) (any)

The collect function uses L<Venus::Collect> to iterate over the value and
selectively transform or filter the data. The function supports both list-like
and hash-like data structures, handling key/value iteration when applicable.

I<Since C<4.15>>

=over 4

=item collect example 1

  package main;

  use Venus 'collect';

  my $collect = collect [];

  # []

=back

=over 4

=item collect example 2

  package main;

  use Venus 'collect';

  my $collect = collect [1..4], sub{$_%2==0?(@_):()};

  # [2,4]

=back

=over 4

=item collect example 3

  package main;

  use Venus 'collect';

  my $collect = collect {};

  # {}

=back

=over 4

=item collect example 4

  package main;

  use Venus 'collect';

  my $collect = collect {1..8}, sub{$_%6==0?(@_):()};

  # {5,6}

=back

=cut

=head2 concat

  concat(any @args) (string)

The concat function stringifies and L<"joins"|perlfunc/join> multiple values delimited
by a single space and returns the resulting string.

I<Since C<4.15>>

=over 4

=item concat example 1

  # given: synopsis

  package main;

  use Venus 'concat';

  my $concat = concat;

  # ""

=back

=over 4

=item concat example 2

  # given: synopsis

  package main;

  use Venus 'concat';

  my $concat = concat 'hello';

  # "hello"

=back

=over 4

=item concat example 3

  # given: synopsis

  package main;

  use Venus 'concat';

  my $concat = concat 'hello', 'world';

  # "hello world"

=back

=over 4

=item concat example 4

  # given: synopsis

  package main;

  use Venus 'concat';

  my $concat = concat 'value is', [1,2];

  # "value is [1,2]"

=back

=over 4

=item concat example 5

  # given: synopsis

  package main;

  use Venus 'concat';

  my $concat = concat 'value is', [1,2], 'and', [3,4];

  # "value is [1,2] and [3,4]"

=back

=cut

=head2 config

  config(hashref $value, string | coderef $code, any @args) (any)

The config function builds and returns a L<Venus::Config> object, or dispatches
to the coderef or method provided.

I<Since C<2.55>>

=over 4

=item config example 1

  package main;

  use Venus 'config';

  my $config = config {};

  # bless({...}, 'Venus::Config')

=back

=over 4

=item config example 2

  package main;

  use Venus 'config';

  my $config = config {}, 'read_perl', '{"data"=>1}';

  # bless({...}, 'Venus::Config')

=back

=cut

=head2 cop

  cop(string | object | coderef $self, string $name) (coderef)

The cop function attempts to curry the given subroutine on the object or class
and if successful returns a closure.

I<Since C<2.32>>

=over 4

=item cop example 1

  package main;

  use Venus 'cop';

  my $coderef = cop('Digest::SHA', 'sha1_hex');

  # sub { ... }

=back

=over 4

=item cop example 2

  package main;

  use Venus 'cop';

  require Digest::SHA;

  my $coderef = cop(Digest::SHA->new, 'digest');

  # sub { ... }

=back

=cut

=head2 data

  data(any $value, string | coderef $code, any @args) (any)

The data function builds and returns a L<Venus::Data> object, or dispatches to
the coderef or method provided.

I<Since C<4.15>>

=over 4

=item data example 1

  package main;

  use Venus 'data';

  my $data = data {value => {name => 'Elliot'}};

  # bless({...}, 'Venus::Data')

=back

=over 4

=item data example 2

  package main;

  use Venus 'data';

  my $data = data {value => {name => 'Elliot'}}, 'valid';

  # 1

=back

=over 4

=item data example 3

  package main;

  use Venus 'data';

  my $data = data {value => {name => 'Elliot'}}, 'shorthand', ['name!' => 'string'];

  # bless({...}, 'Venus::Data')

  # $data->valid;

  # 1

=back

=over 4

=item data example 4

  package main;

  use Venus 'data';

  my $data = data {value => {name => undef}}, 'shorthand', ['name!' => 'string'];

  # bless({...}, 'Venus::Data')

  # $data->valid;

  # 0

=back

=cut

=head2 date

  date(number $value, string | coderef $code, any @args) (any)

The date function builds and returns a L<Venus::Date> object, or dispatches to
the coderef or method provided.

I<Since C<2.40>>

=over 4

=item date example 1

  package main;

  use Venus 'date';

  my $date = date time, 'string';

  # '0000-00-00T00:00:00Z'

=back

=over 4

=item date example 2

  package main;

  use Venus 'date';

  my $date = date time, 'reset', 570672000;

  # bless({...}, 'Venus::Date')

  # $date->string;

  # '1988-02-01T00:00:00Z'

=back

=over 4

=item date example 3

  package main;

  use Venus 'date';

  my $date = date time;

  # bless({...}, 'Venus::Date')

=back

=cut

=head2 enum

  enum(arrayref | hashref $value) (Venus::Enum)

The enum function builds and returns a L<Venus::Enum> object.

I<Since C<3.55>>

=over 4

=item enum example 1

  package main;

  use Venus 'enum';

  my $themes = enum ['light', 'dark'];

  # bless({scope => sub{...}}, "Venus::Enum")

  # my $result = $themes->get('dark');

  # bless({scope => sub{...}}, "Venus::Enum")

  # "$result"

  # "dark"

=back

=over 4

=item enum example 2

  package main;

  use Venus 'enum';

  my $themes = enum {
    light => 'light_theme',
    dark => 'dark_theme',
  };

  # bless({scope => sub{...}}, "Venus::Enum")

  # my $result = $themes->get('dark');

  # bless({scope => sub{...}}, "Venus::Enum")

  # "$result"

  # "dark_theme"

=back

=cut

=head2 error

  error(maybe[hashref] $args) (Venus::Error)

The error function throws a L<Venus::Error> exception object using the
exception object arguments provided.

I<Since C<0.01>>

=over 4

=item error example 1

  package main;

  use Venus 'error';

  my $error = error;

  # bless({...}, 'Venus::Error')

=back

=over 4

=item error example 2

  package main;

  use Venus 'error';

  my $error = error {
    message => 'Something failed!',
  };

  # bless({message => 'Something failed!', ...}, 'Venus::Error')

=back

=cut

=head2 factory

  factory(hashref $value, string | coderef $code, any @args) (any)

The factory function builds and returns a L<Venus::Factory> object, or
dispatches to the coderef or method provided.

I<Since C<4.15>>

=over 4

=item factory example 1

  package main;

  use Venus 'factory';

  my $factory = factory {};

  # bless(..., 'Venus::Factory')

=back

=over 4

=item factory example 2

  package main;

  use Venus 'factory';

  my $path = factory {name => 'path', value => ['/tmp/log']}, 'class', 'Venus::Path';

  # bless(..., 'Venus::Factory')

  # $path->build;

  # bless({value => '/tmp/log'}, 'Venus::Path')

=back

=cut

=head2 false

  false() (boolean)

The false function returns a falsy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<0> value.

I<Since C<0.01>>

=over 4

=item false example 1

  package main;

  use Venus;

  my $false = false;

  # 0

=back

=over 4

=item false example 2

  package main;

  use Venus;

  my $true = !false;

  # 1

=back

=cut

=head2 fault

  fault(string $args) (Venus::Fault)

The fault function throws a L<Venus::Fault> exception object and represents a
system failure, and isn't meant to be caught.

I<Since C<1.80>>

=over 4

=item fault example 1

  package main;

  use Venus 'fault';

  my $fault = fault;

  # bless({message => 'Exception!'}, 'Venus::Fault')

=back

=over 4

=item fault example 2

  package main;

  use Venus 'fault';

  my $fault = fault 'Something failed!';

  # bless({message => 'Something failed!'}, 'Venus::Fault')

=back

=cut

=head2 flat

  flat(any @args) (any)

The flat function take a list of arguments and flattens them where possible and
returns the list of flattened values. When a hashref is encountered, it will be
flattened into key/value pairs. When an arrayref is encountered, it will be
flattened into a list of items.

I<Since C<4.15>>

=over 4

=item flat example 1

  package main;

  use Venus 'flat';

  my @flat = flat 1, 2, 3;

  # (1, 2, 3)

=back

=over 4

=item flat example 2

  package main;

  use Venus 'flat';

  my @flat = flat 1, 2, 3, [1, 2, 3];

  # (1, 2, 3, 1, 2, 3)

=back

=over 4

=item flat example 3

  package main;

  use Venus 'flat';

  my @flat = flat 1, 2, 3, [1, 2, 3], {1, 2};

  # (1, 2, 3, 1, 2, 3, 1, 2)

=back

=cut

=head2 float

  float(string $value, string | coderef $code, any @args) (any)

The float function builds and returns a L<Venus::Float> object, or dispatches
to the coderef or method provided.

I<Since C<2.55>>

=over 4

=item float example 1

  package main;

  use Venus 'float';

  my $float = float 1.23;

  # bless({...}, 'Venus::Float')

=back

=over 4

=item float example 2

  package main;

  use Venus 'float';

  my $float = float 1.23, 'int';

  # 1

=back

=cut

=head2 future

  future(coderef $code) (Venus::Future)

The future function builds and returns a L<Venus::Future> object.

I<Since C<3.55>>

=over 4

=item future example 1

  package main;

  use Venus 'future';

  my $future = future(sub{
    my ($resolve, $reject) = @_;

    return int(rand(2)) ? $resolve->result('pass') : $reject->result('fail');
  });

  # bless(..., "Venus::Future")

  # $future->is_pending;

  # false

=back

=cut

=head2 gather

  gather(any $value, coderef $callback) (any)

The gather function builds a L<Venus::Gather> object, passing it and the value
provided to the callback provided, and returns the return value from
L<Venus::Gather/result>.

I<Since C<2.50>>

=over 4

=item gather example 1

  package main;

  use Venus 'gather';

  my $gather = gather ['a'..'d'];

  # bless({...}, 'Venus::Gather')

  # $gather->result;

  # undef

=back

=over 4

=item gather example 2

  package main;

  use Venus 'gather';

  my $gather = gather ['a'..'d'], sub {{
    a => 1,
    b => 2,
    c => 3,
  }};

  # [1..3]

=back

=over 4

=item gather example 3

  package main;

  use Venus 'gather';

  my $gather = gather ['e'..'h'], sub {{
    a => 1,
    b => 2,
    c => 3,
  }};

  # []

=back

=over 4

=item gather example 4

  package main;

  use Venus 'gather';

  my $gather = gather ['a'..'d'], sub {
    my ($case) = @_;

    $case->when(sub{lc($_) eq 'a'})->then('a -> A');
    $case->when(sub{lc($_) eq 'b'})->then('b -> B');
  };

  # ['a -> A', 'b -> B']

=back

=over 4

=item gather example 5

  package main;

  use Venus 'gather';

  my $gather = gather ['a'..'d'], sub {

    $_->when(sub{lc($_) eq 'a'})->then('a -> A');
    $_->when(sub{lc($_) eq 'b'})->then('b -> B');
  };

  # ['a -> A', 'b -> B']

=back

=cut

=head2 gets

  gets(string @args) (arrayref)

The gets function select values from within the underlying data structure using
L<Venus::Array/path> or L<Venus::Hash/path>, where each argument is a selector,
returns all the values selected. Returns a list in list context.

I<Since C<4.15>>

=over 4

=item gets example 1

  package main;

  use Venus 'gets';

  my $data = {'foo' => {'bar' => 'baz'}, 'bar' => ['baz']};

  my $gets = gets $data, 'bar', 'foo.bar';

  # [['baz'], 'baz']

=back

=over 4

=item gets example 2

  package main;

  use Venus 'gets';

  my $data = {'foo' => {'bar' => 'baz'}, 'bar' => ['baz']};

  my ($bar, $foo_bar) = gets $data, 'bar', 'foo.bar';

  # (['baz'], 'baz')

=back

=over 4

=item gets example 3

  package main;

  use Venus 'gets';

  my $data = ['foo', {'bar' => 'baz'}, 'bar', ['baz']];

  my $gets = gets $data, '3', '1.bar';

  # [['baz'], 'baz']

=back

=over 4

=item gets example 4

  package main;

  use Venus 'gets';

  my $data = ['foo', {'bar' => 'baz'}, 'bar', ['baz']];

  my ($baz, $one_bar) = gets $data, '3', '1.bar';

  # (['baz'], 'baz')

=back

=cut

=head2 handle

  handle(string $name, coderef $code) (coderef)

The handle function installs a method modifier that wraps a method similar to
L</around>, but is the low-level implementation. The modifier receives the
original method as its first argument (which may be undef if the method doesn't
  exist), followed by the method's arguments. This is the foundation for the
other method modifiers.

I<Since C<4.15>>

=over 4

=item handle example 1

  package Example7;

  use Venus::Class 'handle';

  sub test {
    my ($self, $value) = @_;
    return $value;
  }

  handle 'test', sub {
    my ($orig, $self, $value) = @_;
    return $orig ? $self->$orig($value * 2) : 0;
  };

  package main;

  my $result = Example7->new->test(5);

  # 10

=back

=over 4

=item handle example 2

  package Example8;

  use Venus::Class 'handle';

  handle 'missing', sub {
    my ($orig, $self) = @_;
    return 'method does not exist';
  };

  package main;

  my $result = Example8->new->missing;

  # "method does not exist"

=back

=cut

=head2 hash

  hash(hashref $value, string | coderef $code, any @args) (any)

The hash function builds and returns a L<Venus::Hash> object, or dispatches
to the coderef or method provided.

I<Since C<2.55>>

=over 4

=item hash example 1

  package main;

  use Venus 'hash';

  my $hash = hash {1..4};

  # bless({...}, 'Venus::Hash')

=back

=over 4

=item hash example 2

  package main;

  use Venus 'hash';

  my $hash = hash {1..8}, 'pairs';

  # [[1, 2], [3, 4], [5, 6], [7, 8]]

=back

=cut

=head2 hashref

  hashref(any @args) (hashref)

The hashref function takes a list of arguments and returns a hashref.

I<Since C<3.10>>

=over 4

=item hashref example 1

  package main;

  use Venus 'hashref';

  my $hashref = hashref(content => 'example');

  # {content => "example"}

=back

=over 4

=item hashref example 2

  package main;

  use Venus 'hashref';

  my $hashref = hashref({content => 'example'});

  # {content => "example"}

=back

=over 4

=item hashref example 3

  package main;

  use Venus 'hashref';

  my $hashref = hashref('content');

  # {content => undef}

=back

=over 4

=item hashref example 4

  package main;

  use Venus 'hashref';

  my $hashref = hashref('content', 'example', 'algorithm');

  # {content => "example", algorithm => undef}

=back

=cut

=head2 hook

  hook(string $type, string $name, coderef $code) (coderef)

The hook function is a specialized method modifier helper that applies a
modifier (after, around, before, or handle) to a lifecycle hook method. It
automatically uppercases the hook name, making it convenient for modifying
Venus lifecycle hooks like BUILD, BLESS, BUILDARGS, and AUDIT.

I<Since C<4.15>>

=over 4

=item hook example 1

  package Example9;

  use Venus::Class 'attr', 'hook';

  attr 'startup';

  sub BUILD {
    my ($self, $args) = @_;
    $self->startup('original');
  }

  hook 'after', 'build', sub {
    my ($self) = @_;
    $self->startup('modified');
  };

  package main;

  my $result = Example9->new->startup;

  # "modified"

=back

=over 4

=item hook example 2

  package Example10;

  use Venus::Class 'attr', 'hook';

  attr 'calls';

  sub BUILD {
    my ($self, $args) = @_;
    $self->calls([]) if !$self->calls;
    push @{$self->calls}, 'BUILD';
  }

  hook 'before', 'build', sub {
    my ($self) = @_;
    $self->calls([]) if !$self->calls;
    push @{$self->calls}, 'before';
  };

  package main;

  my $example = Example10->new;
  my $calls = $example->calls;

  # ['before', 'BUILD']

=back

=cut

=head2 in

  in(arrayref | hashref | consumes[Venus::Role::Mappable] $lvalue, any $rvalue) (boolean)

The in function accepts an arrayref, hashref, or
L<"mappable"|Venus::Role::Mappable> and returns true if the type and value of
the rvalue is the same for any items in the collection.

I<Since C<4.15>>

=over 4

=item in example 1

  # given: synopsis

  package main;

  use Venus 'in';

  my $in = in [1, '1'], 1;

  # true

=back

=over 4

=item in example 2

  # given: synopsis

  package main;

  use Venus 'in';

  my $in = in [1, 1], 0;

  # false

=back

=over 4

=item in example 3

  # given: synopsis

  package main;

  use Venus 'in';

  my $in = in {1, 2}, 1;

  # false

=back

=over 4

=item in example 4

  # given: synopsis

  package main;

  use Venus 'in';

  my $in = in {1, 1}, 1;

  # true

=back

=over 4

=item in example 5

  # given: synopsis

  package main;

  use Venus 'in';

  my $in = in [[0], [1]], [1];

  # true

=back

=cut

=head2 is

  is(any $lvalue, any $rvalue) (boolean)

The is function returns true if the lvalue and rvalue are identical, i.e.
refers to the same memory address, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is example 1

  # given: synopsis

  package main;

  use Venus 'is';

  my $is = is 1, 1;

  # false

=back

=over 4

=item is example 2

  # given: synopsis

  package main;

  use Venus 'is', 'number';

  my $a = number 1;

  my $is = is $a, 1;

  # false

=back

=over 4

=item is example 3

  # given: synopsis

  package main;

  use Venus 'is', 'number';

  my $a = number 1;

  my $is = is $a, $a;

  # true

=back

=over 4

=item is example 4

  # given: synopsis

  package main;

  use Venus 'is', 'number';

  my $a = number 1;
  my $b = number 1;

  my $is = is $a, $b;

  # false

=back

=cut

=head2 is_blessed

  is_blessed(any $data) (boolean)

The is_blessed function uses L</check> to validate that the data provided is an
object returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_blessed example 1

  # given: synopsis

  package main;

  use Venus 'is_blessed';

  my $is_blessed = is_blessed bless {};

  # true

=back

=over 4

=item is_blessed example 2

  # given: synopsis

  package main;

  use Venus 'is_blessed';

  my $is_blessed = is_blessed {};

  # false

=back

=cut

=head2 is_boolean

  is_boolean(any $data) (boolean)

The is_boolean function uses L</check> to validate that the data provided is a
boolean returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_boolean example 1

  # given: synopsis

  package main;

  use Venus 'is_boolean';

  my $is_boolean = is_boolean true;

  # true

=back

=over 4

=item is_boolean example 2

  # given: synopsis

  package main;

  use Venus 'is_boolean';

  my $is_boolean = is_boolean 1;

  # false

=back

=cut

=head2 is_coderef

  is_coderef(any $data) (boolean)

The is_coderef function uses L</check> to validate that the data provided is a
coderef returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_coderef example 1

  # given: synopsis

  package main;

  use Venus 'is_coderef';

  my $is_coderef = is_coderef sub{};

  # true

=back

=over 4

=item is_coderef example 2

  # given: synopsis

  package main;

  use Venus 'is_coderef';

  my $is_coderef = is_coderef {};

  # false

=back

=cut

=head2 is_dirhandle

  is_dirhandle(any $data) (boolean)

The is_dirhandle function uses L</check> to validate that the data provided is
a dirhandle returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_dirhandle example 1

  # given: synopsis

  package main;

  use Venus 'is_dirhandle';

  opendir my $dh, 't';

  my $is_dirhandle = is_dirhandle $dh;

  # true

=back

=over 4

=item is_dirhandle example 2

  # given: synopsis

  package main;

  use Venus 'is_dirhandle';

  open my $fh, '<', 't/data/moon';

  my $is_dirhandle = is_dirhandle $fh;

  # false

=back

=cut

=head2 is_enum

  is_enum(any $data, value @args) (boolean)

The is_enum function uses L</check> to validate that the data provided is an
enum returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_enum example 1

  # given: synopsis

  package main;

  use Venus 'is_enum';

  my $is_enum = is_enum 'yes', 'yes', 'no'

  # true

=back

=over 4

=item is_enum example 2

  # given: synopsis

  package main;

  use Venus 'is_enum';

  my $is_enum = is_enum 'yes', 'Yes', 'No';

  # false

=back

=cut

=head2 is_error

  is_error(any $data, string | coderef $code, any @args) (boolean)

The is_error function accepts a scalar value and returns true if the value is
(or is derived from) L<Venus::Error>. This function can dispatch method calls
and execute callbacks, and returns true of the return value from the callback
is truthy, and false otherwise.

I<Since C<4.15>>

=over 4

=item is_error example 1

  package main;

  use Venus 'is_error';

  my $is_error = is_error 0;

  # false

=back

=over 4

=item is_error example 2

  package main;

  use Venus 'is_error';

  my $is_error = is_error 1;

  # false

=back

=over 4

=item is_error example 3

  package main;

  use Venus 'catch', 'fault', 'is_error';

  my $fault = catch {fault};

  my $is_error = is_error $fault;

  # false

=back

=over 4

=item is_error example 4

  package main;

  use Venus 'catch', 'error', 'is_error';

  my $error = catch {error};

  my $is_error = is_error $error;

  # true

=back

=over 4

=item is_error example 5

  package main;

  use Venus 'catch', 'error', 'is_error';

  my $error = catch {error {verbose => true}};

  my $is_error = is_error $error, 'verbose';

  # true

=back

=over 4

=item is_error example 6

  package main;

  use Venus 'catch', 'error', 'is_error';

  my $error = catch {error {verbose => false}};

  my $is_error = is_error $error, 'verbose';

  # false

=back

=cut

=head2 is_false

  is_false(any $data, string | coderef $code, any @args) (boolean)

The is_false function accepts a scalar value and returns true if the value is
falsy. This function can dispatch method calls and execute callbacks.

I<Since C<3.04>>

=over 4

=item is_false example 1

  package main;

  use Venus 'is_false';

  my $is_false = is_false 0;

  # true

=back

=over 4

=item is_false example 2

  package main;

  use Venus 'is_false';

  my $is_false = is_false 1;

  # false

=back

=over 4

=item is_false example 3

  package main;

  use Venus 'array', 'is_false';

  my $array = array [];

  my $is_false = is_false $array;

  # false

=back

=over 4

=item is_false example 4

  package main;

  use Venus 'array', 'is_false';

  my $array = array [];

  my $is_false = is_false $array, 'count';

  # true

=back

=over 4

=item is_false example 5

  package main;

  use Venus 'array', 'is_false';

  my $array = array [1];

  my $is_false = is_false $array, 'count';

  # false

=back

=over 4

=item is_false example 6

  package main;

  use Venus 'is_false';

  my $array = undef;

  my $is_false = is_false $array, 'count';

  # true

=back

=cut

=head2 is_fault

  is_fault(any $data) (boolean)

The is_fault function accepts a scalar value and returns true if the value is
(or is derived from) L<Venus::Fault>.

I<Since C<4.15>>

=over 4

=item is_fault example 1

  package main;

  use Venus 'is_fault';

  my $is_fault = is_fault 0;

  # false

=back

=over 4

=item is_fault example 2

  package main;

  use Venus 'is_fault';

  my $is_fault = is_fault 1;

  # false

=back

=over 4

=item is_fault example 3

  package main;

  use Venus 'catch', 'fault', 'is_fault';

  my $fault = catch {fault};

  my $is_fault = is_fault $fault;

  # true

=back

=over 4

=item is_fault example 4

  package main;

  use Venus 'catch', 'error', 'is_fault';

  my $error = catch {error};

  my $is_fault = is_fault $error;

  # false

=back

=cut

=head2 is_filehandle

  is_filehandle(any $data) (boolean)

The is_filehandle function uses L</check> to validate that the data provided is
a filehandle returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_filehandle example 1

  # given: synopsis

  package main;

  use Venus 'is_filehandle';

  open my $fh, '<', 't/data/moon';

  my $is_filehandle = is_filehandle $fh;

  # true

=back

=over 4

=item is_filehandle example 2

  # given: synopsis

  package main;

  use Venus 'is_filehandle';

  opendir my $dh, 't';

  my $is_filehandle = is_filehandle $dh;

  # false

=back

=cut

=head2 is_float

  is_float(any $data) (boolean)

The is_float function uses L</check> to validate that the data provided is a
float returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_float example 1

  # given: synopsis

  package main;

  use Venus 'is_float';

  my $is_float = is_float .123;

  # true

=back

=over 4

=item is_float example 2

  # given: synopsis

  package main;

  use Venus 'is_float';

  my $is_float = is_float 123;

  # false

=back

=cut

=head2 is_glob

  is_glob(any $data) (boolean)

The is_glob function uses L</check> to validate that the data provided is a
glob returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_glob example 1

  # given: synopsis

  package main;

  use Venus 'is_glob';

  my $is_glob = is_glob \*main;

  # true

=back

=over 4

=item is_glob example 2

  # given: synopsis

  package main;

  use Venus 'is_glob';

  my $is_glob = is_glob *::main;

  # false

=back

=cut

=head2 is_hashref

  is_hashref(any $data) (boolean)

The is_hashref function uses L</check> to validate that the data provided is a
hashref returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_hashref example 1

  # given: synopsis

  package main;

  use Venus 'is_hashref';

  my $is_hashref = is_hashref {};

  # true

=back

=over 4

=item is_hashref example 2

  # given: synopsis

  package main;

  use Venus 'is_hashref';

  my $is_hashref = is_hashref [];

  # false

=back

=cut

=head2 is_number

  is_number(any $data) (boolean)

The is_number function uses L</check> to validate that the data provided is a
number returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_number example 1

  # given: synopsis

  package main;

  use Venus 'is_number';

  my $is_number = is_number 0;

  # true

=back

=over 4

=item is_number example 2

  # given: synopsis

  package main;

  use Venus 'is_number';

  my $is_number = is_number '0';

  # false

=back

=cut

=head2 is_object

  is_object(any $data) (boolean)

The is_object function uses L</check> to validate that the data provided is an
object returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_object example 1

  # given: synopsis

  package main;

  use Venus 'is_object';

  my $is_object = is_object bless {};

  # true

=back

=over 4

=item is_object example 2

  # given: synopsis

  package main;

  use Venus 'is_object';

  my $is_object = is_object {};

  # false

=back

=cut

=head2 is_package

  is_package(any $data) (boolean)

The is_package function uses L</check> to validate that the data provided is a
package returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_package example 1

  # given: synopsis

  package main;

  use Venus 'is_package';

  my $is_package = is_package 'Venus';

  # true

=back

=over 4

=item is_package example 2

  # given: synopsis

  package main;

  use Venus 'is_package';

  my $is_package = is_package 'MyApp';

  # false

=back

=cut

=head2 is_reference

  is_reference(any $data) (boolean)

The is_reference function uses L</check> to validate that the data provided is
a reference returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_reference example 1

  # given: synopsis

  package main;

  use Venus 'is_reference';

  my $is_reference = is_reference \0;

  # true

=back

=over 4

=item is_reference example 2

  # given: synopsis

  package main;

  use Venus 'is_reference';

  my $is_reference = is_reference 0;

  # false

=back

=cut

=head2 is_regexp

  is_regexp(any $data) (boolean)

The is_regexp function uses L</check> to validate that the data provided is a
regexp returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_regexp example 1

  # given: synopsis

  package main;

  use Venus 'is_regexp';

  my $is_regexp = is_regexp qr/hello/;

  # true

=back

=over 4

=item is_regexp example 2

  # given: synopsis

  package main;

  use Venus 'is_regexp';

  my $is_regexp = is_regexp 'hello';

  # false

=back

=cut

=head2 is_scalarref

  is_scalarref(any $data) (boolean)

The is_scalarref function uses L</check> to validate that the data provided is
a scalarref returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_scalarref example 1

  # given: synopsis

  package main;

  use Venus 'is_scalarref';

  my $is_scalarref = is_scalarref \1;

  # true

=back

=over 4

=item is_scalarref example 2

  # given: synopsis

  package main;

  use Venus 'is_scalarref';

  my $is_scalarref = is_scalarref 1;

  # false

=back

=cut

=head2 is_string

  is_string(any $data) (boolean)

The is_string function uses L</check> to validate that the data provided is a
string returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_string example 1

  # given: synopsis

  package main;

  use Venus 'is_string';

  my $is_string = is_string '0';

  # true

=back

=over 4

=item is_string example 2

  # given: synopsis

  package main;

  use Venus 'is_string';

  my $is_string = is_string 0;

  # false

=back

=cut

=head2 is_true

  is_true(any $data, string | coderef $code, any @args) (boolean)

The is_true function accepts a scalar value and returns true if the value is
truthy. This function can dispatch method calls and execute callbacks.

I<Since C<3.04>>

=over 4

=item is_true example 1

  package main;

  use Venus 'is_true';

  my $is_true = is_true 1;

  # true

=back

=over 4

=item is_true example 2

  package main;

  use Venus 'is_true';

  my $is_true = is_true 0;

  # false

=back

=over 4

=item is_true example 3

  package main;

  use Venus 'array', 'is_true';

  my $array = array [];

  my $is_true = is_true $array;

  # true

=back

=over 4

=item is_true example 4

  package main;

  use Venus 'array', 'is_true';

  my $array = array [];

  my $is_true = is_true $array, 'count';

  # false

=back

=over 4

=item is_true example 5

  package main;

  use Venus 'array', 'is_true';

  my $array = array [1];

  my $is_true = is_true $array, 'count';

  # true

=back

=over 4

=item is_true example 6

  package main;

  use Venus 'is_true';

  my $array = undef;

  my $is_true = is_true $array, 'count';

  # false

=back

=cut

=head2 is_undef

  is_undef(any $data) (boolean)

The is_undef function uses L</check> to validate that the data provided is an
undef returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_undef example 1

  # given: synopsis

  package main;

  use Venus 'is_undef';

  my $is_undef = is_undef undef;

  # true

=back

=over 4

=item is_undef example 2

  # given: synopsis

  package main;

  use Venus 'is_undef';

  my $is_undef = is_undef '';

  # false

=back

=cut

=head2 is_value

  is_value(any $data) (boolean)

The is_value function uses L</check> to validate that the data provided is an
value returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_value example 1

  # given: synopsis

  package main;

  use Venus 'is_value';

  my $is_value = is_value 0;

  # true

=back

=over 4

=item is_value example 2

  # given: synopsis

  package main;

  use Venus 'is_value';

  my $is_value = is_value sub{};

  # false

=back

=cut

=head2 is_yesno

  is_yesno(any $data) (boolean)

The is_yesno function uses L</check> to validate that the data provided is a
yesno returns true, otherwise returns false.

I<Since C<4.15>>

=over 4

=item is_yesno example 1

  # given: synopsis

  package main;

  use Venus 'is_yesno';

  my $is_yesno = is_yesno 0;

  # true

=back

=over 4

=item is_yesno example 2

  # given: synopsis

  package main;

  use Venus 'is_yesno';

  my $is_yesno = is_yesno undef;

  # false

=back

=cut

=head2 json

  json(string $call, any $data) (any)

The json function builds a L<Venus::Json> object and will either
L<Venus::Json/decode> or L<Venus::Json/encode> based on the argument provided
and returns the result.

I<Since C<2.40>>

=over 4

=item json example 1

  package main;

  use Venus 'json';

  my $decode = json 'decode', '{"codename":["Ready","Robot"],"stable":true}';

  # { codename => ["Ready", "Robot"], stable => 1 }

=back

=over 4

=item json example 2

  package main;

  use Venus 'json';

  my $encode = json 'encode', { codename => ["Ready", "Robot"], stable => true };

  # '{"codename":["Ready","Robot"],"stable":true}'

=back

=over 4

=item json example 3

  package main;

  use Venus 'json';

  my $json = json;

  # bless({...}, 'Venus::Json')

=back

=over 4

=item json example 4

  package main;

  use Venus 'json';

  my $json = json 'class', {data => "..."};

  # Exception! (isa Venus::Fault)

=back

=cut

=head2 kvargs

  kvargs(any @args) (hashref)

The kvargs function takes a list of arguments and returns a hashref. If a
single hashref is provided, it is returned as-is. Otherwise, the arguments are
treated as key-value pairs. If an odd number of arguments is provided, the last
key will have C<undef> as its value.

I<Since C<5.00>>

=over 4

=item kvargs example 1

  package main;

  use Venus 'kvargs';

  my $kvargs = kvargs {name => 'Elliot'};

  # {name => 'Elliot'}

=back

=over 4

=item kvargs example 2

  package main;

  use Venus 'kvargs';

  my $kvargs = kvargs name => 'Elliot', role => 'hacker';

  # {name => 'Elliot', role => 'hacker'}

=back

=over 4

=item kvargs example 3

  package main;

  use Venus 'kvargs';

  my $kvargs = kvargs name => 'Elliot', 'role';

  # {name => 'Elliot', role => undef}

=back

=over 4

=item kvargs example 4

  package main;

  use Venus 'kvargs';

  my $kvargs = kvargs;

  # {}

=back

=cut

=head2 list

  list(any @args) (any)

The list function accepts a list of values and flattens any arrayrefs,
returning a list of scalars.

I<Since C<3.04>>

=over 4

=item list example 1

  package main;

  use Venus 'list';

  my @list = list 1..4;

  # (1..4)

=back

=over 4

=item list example 2

  package main;

  use Venus 'list';

  my @list = list [1..4];

  # (1..4)

=back

=over 4

=item list example 3

  package main;

  use Venus 'list';

  my @list = list [1..4], 5, [6..10];

  # (1..10)

=back

=cut

=head2 load

  load(any $name) (Venus::Space)

The load function loads the package provided and returns a L<Venus::Space> object.

I<Since C<2.32>>

=over 4

=item load example 1

  package main;

  use Venus 'load';

  my $space = load 'Venus::Scalar';

  # bless({value => 'Venus::Scalar'}, 'Venus::Space')

=back

=cut

=head2 log

  log(any @args) (Venus::Log)

The log function prints the arguments provided to STDOUT, stringifying complex
values, and returns a L<Venus::Log> object. If the first argument is a log
level name, e.g. C<debug>, C<error>, C<fatal>, C<info>, C<trace>, or C<warn>,
it will be used when emitting the event. The desired log level is specified by
the C<VENUS_LOG_LEVEL> environment variable and defaults to C<trace>.

I<Since C<2.40>>

=over 4

=item log example 1

  package main;

  use Venus 'log';

  my $log = log;

  # bless({...}, 'Venus::Log')

  # log time, rand, 1..9;

  # 00000000 0.000000, 1..9

=back

=cut

=head2 make

  make(string $package, any @args) (any)

The make function L<"calls"|Venus/call> the C<new> routine on the invocant and
returns the result which should be a package string or an object.

I<Since C<2.32>>

=over 4

=item make example 1

  package main;

  use Venus 'make';

  my $made = make('Digest::SHA');

  # bless(do{\(my $o = '...')}, 'Digest::SHA')

=back

=over 4

=item make example 2

  package main;

  use Venus 'make';

  my $made = make('Digest', 'SHA');

  # bless(do{\(my $o = '...')}, 'Digest::SHA')

=back

=cut

=head2 map

  map(hashref $value) (Venus::Map)

The map function returns a L<Venus::Map> object for the hashref provided.

I<Since C<4.15>>

=over 4

=item map example 1

  package main;

  use Venus;

  my $map = Venus::map {1..4};

  # bless(..., 'Venus::Map')

=back

=over 4

=item map example 2

  package main;

  use Venus;

  my $map = Venus::map {1..4}, 'count';

  # 2

=back

=cut

=head2 match

  match(any $value, coderef $callback) (any)

The match function builds a L<Venus::Match> object, passing it and the value
provided to the callback provided, and returns the return value from
L<Venus::Match/result>.

I<Since C<2.50>>

=over 4

=item match example 1

  package main;

  use Venus 'match';

  my $match = match 5;

  # bless({...}, 'Venus::Match')

  # $match->result;

  # undef

=back

=over 4

=item match example 2

  package main;

  use Venus 'match';

  my $match = match 5, sub {{
    1 => 'one',
    2 => 'two',
    5 => 'five',
  }};

  # 'five'

=back

=over 4

=item match example 3

  package main;

  use Venus 'match';

  my $match = match 5, sub {{
    1 => 'one',
    2 => 'two',
    3 => 'three',
  }};

  # undef

=back

=over 4

=item match example 4

  package main;

  use Venus 'match';

  my $match = match 5, sub {
    my ($case) = @_;

    $case->when(sub{$_ < 5})->then('< 5');
    $case->when(sub{$_ > 5})->then('> 5');
  };

  # undef

=back

=over 4

=item match example 5

  package main;

  use Venus 'match';

  my $match = match 6, sub {
    my ($case, $data) = @_;

    $case->when(sub{$_ < 5})->then("$data < 5");
    $case->when(sub{$_ > 5})->then("$data > 5");
  };

  # '6 > 5'

=back

=over 4

=item match example 6

  package main;

  use Venus 'match';

  my $match = match 4, sub {

    $_->when(sub{$_ < 5})->then("$_[1] < 5");
    $_->when(sub{$_ > 5})->then("$_[1] > 5");
  };

  # '4 < 5'

=back

=cut

=head2 merge

  merge(any @args) (any)

The merge function returns a value which is a merger of all of the arguments
provided. This function is an alias for L</merge_join> given the principle of
least surprise.

I<Since C<2.32>>

=over 4

=item merge example 1

  package main;

  use Venus 'merge';

  my $merged = merge({1..4}, {5, 6});

  # {1..6}

=back

=over 4

=item merge example 2

  package main;

  use Venus 'merge';

  my $merged = merge({1..4}, {5, 6}, {7, 8, 9, 0});

  # {1..9, 0}

=back

=cut

=head2 merge_flat

  merge_flat(any @args) (any)

The merge_flat function merges two (or more) values and returns a new values
based on the types of the inputs:

B<Note:> This function appends hashref values to an arrayref when encountered.

=over 4

=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "arrayref" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "hashref" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "scalar" we
append the C<rvalue> to the C<lvalue>.

=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "arrayref"
we append the items in C<rvalue> to the C<lvalue>.

=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "hashref" we
append the values in C<rvalue> to the C<lvalue>.

=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "arrayref" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "hashref" we
append the keys and values in C<rvalue> to the C<lvalue>, overwriting existing
keys where there's overlap.

=back

I<Since C<4.15>>

=over 4

=item merge_flat example 1

  # given: synopsis

  package main;

  use Venus 'merge_flat';

  my $merge_flat = merge_flat;

  # undef

=back

=over 4

=item merge_flat example 2

  # given: synopsis

  package main;

  use Venus 'merge_flat';

  my $merge_flat = merge_flat 1;

  # 1

=back

=over 4

=item merge_flat example 3

  # given: synopsis

  package main;

  use Venus 'merge_flat';

  my $merge_flat = merge_flat 1, 2;

  # 2

=back

=over 4

=item merge_flat example 4

  # given: synopsis

  package main;

  use Venus 'merge_flat';

  my $merge_flat = merge_flat 1, [2, 3];

  # [2, 3]

=back

=over 4

=item merge_flat example 5

  # given: synopsis

  package main;

  use Venus 'merge_flat';

  my $merge_flat = merge_flat 1, {a => 1};

  # {a => 1}

=back

=over 4

=item merge_flat example 6

  # given: synopsis

  package main;

  use Venus 'merge_flat';

  my $merge_flat = merge_flat [1, 2], 3;

  # [1, 2, 3]

=back

=over 4

=item merge_flat example 7

  # given: synopsis

  package main;

  use Venus 'merge_flat';

  my $merge_flat = merge_flat [1, 2], {a => 3, b => 4};

  # [1, 2, 3, 4]

=back

=over 4

=item merge_flat example 8

  # given: synopsis

  package main;

  use Venus 'merge_flat';

  my $merge_flat = merge_flat(
    {
      a => 1,
      b => {x => 10},
      d => 0,
      g => [4],
    },
    {
      b => {y => 20},
      c => 3,
      e => [5],
      f => [6]
    },
    {
      b => {z => 456},
      c => {z => 123},
      d => 2,
      e => [6, 7],
      f => {7, 8},
      g => 5,
    },
  );

  # {
  #   a => 1,
  #   b => {
  #     x => 10,
  #     y => 20,
  #     z => 456
  #   },
  #   c => {z => 123},
  #   d => 2,
  #   e => [5, 6, 7],
  #   f => [6, 8],
  #   g => [4, 5],
  # }

=back

=cut

=head2 merge_flat_mutate

  merge_flat_mutate(any @args) (any)

The merge_flat_mutate performs a merge operaiton in accordance with
L</merge_flat> except that it mutates the values being merged and returns the
mutated value.

I<Since C<4.15>>

=over 4

=item merge_flat_mutate example 1

  # given: synopsis

  package main;

  use Venus 'merge_flat_mutate';

  my $merge_flat_mutate = merge_flat_mutate;

  # undef

=back

=over 4

=item merge_flat_mutate example 2

  # given: synopsis

  package main;

  use Venus 'merge_flat_mutate';

  my $merge_flat_mutate = merge_flat_mutate 1;

  # 1

=back

=over 4

=item merge_flat_mutate example 3

  # given: synopsis

  package main;

  use Venus 'merge_flat_mutate';

  $result = 1;

  my $merge_flat_mutate = merge_flat_mutate $result, 2;

  # 2

  $result;

  # 2

=back

=over 4

=item merge_flat_mutate example 4

  # given: synopsis

  package main;

  use Venus 'merge_flat_mutate';

  $result = 1;

  my $merge_flat_mutate = merge_flat_mutate $result, [2, 3];

  # [2, 3]

  $result;

  # [2, 3]

=back

=over 4

=item merge_flat_mutate example 5

  # given: synopsis

  package main;

  use Venus 'merge_flat_mutate';

  $result = 1;

  my $merge_flat_mutate = merge_flat_mutate $result, {a => 1};

  # {a => 1}

  $result;

  # {a => 1}

=back

=over 4

=item merge_flat_mutate example 6

  # given: synopsis

  package main;

  use Venus 'merge_flat_mutate';

  $result = [1, 2];

  my $merge_flat_mutate = merge_flat_mutate $result, 3;

  # [1, 2, 3]

  $result;

  # [1, 2, 3]

=back

=over 4

=item merge_flat_mutate example 7

  # given: synopsis

  package main;

  use Venus 'merge_flat_mutate';

  $result = [1, 2];

  my $merge_flat_mutate = merge_flat_mutate $result, {a => 3, b => 4};

  # [1, 2, 3, 4]

  $result;

  # [1, 2, 3, 4]

=back

=cut

=head2 merge_join

  merge_join(any @args) (any)

The merge_join merges two (or more) values and returns a new values based on
the types of the inputs:

B<Note:> This function merges hashrefs with hashrefs, and appends arrayrefs
with arrayrefs.

=over 4

=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "arrayref" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "hashref" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "scalar" we
append the C<rvalue> to the C<lvalue>.

=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "arrayref"
we append the items in C<rvalue> to the C<lvalue>.

=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "hashref" we
append the C<rvalue> to the C<lvalue>.

=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "arrayref" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "hashref" we
append the keys and values in C<rvalue> to the C<lvalue>, overwriting existing
keys where there's overlap.

=back

I<Since C<4.15>>

=over 4

=item merge_join example 1

  # given: synopsis

  package main;

  use Venus 'merge_join';

  my $merge_join = merge_join;

  # undef

=back

=over 4

=item merge_join example 2

  # given: synopsis

  package main;

  use Venus 'merge_join';

  my $merge_join = merge_join 1;

  # 1

=back

=over 4

=item merge_join example 3

  # given: synopsis

  package main;

  use Venus 'merge_join';

  my $merge_join = merge_join 1, 2;

  # 2

=back

=over 4

=item merge_join example 4

  # given: synopsis

  package main;

  use Venus 'merge_join';

  my $merge_join = merge_join 1, [2, 3];

  # [2, 3]

=back

=over 4

=item merge_join example 5

  # given: synopsis

  package main;

  use Venus 'merge_join';

  my $merge_join = merge_join [1, 2], 3;

  # [1, 2, 3]

=back

=over 4

=item merge_join example 6

  # given: synopsis

  package main;

  use Venus 'merge_join';

  my $merge_join = merge_join [1, 2], [3, 4];

  # [1, 2, 3, 4]

=back

=over 4

=item merge_join example 7

  # given: synopsis

  package main;

  use Venus 'merge_join';

  my $merge_join = merge_join {a => 1}, {a => 2, b => 3};

  # {a => 2, b => 3}

=back

=over 4

=item merge_join example 8

  # given: synopsis

  package main;

  use Venus 'merge_join';

  my $merge_join = merge_join(
    {
      a => 1,
      b => {x => 10},
      d => 0,
      g => [4],
    },
    {
      b => {y => 20},
      c => 3,
      e => [5],
      f => [6]
    },
    {
      b => {z => 456},
      c => {z => 123},
      d => 2,
      e => [6, 7],
      f => {7, 8},
      g => 5,
    },
  );

  # {
  #   a => 1,
  #   b => {
  #     x => 10,
  #     y => 20,
  #     z => 456
  #   },
  #   c => {z => 123},
  #   d => 2,
  #   e => [5, 6, 7],
  #   f => [6, {7, 8}],
  #   g => [4, 5],
  # }

=back

=cut

=head2 merge_join_mutate

  merge_join_mutate(any @args) (any)

The merge_join_mutate performs a merge operaiton in accordance with
L</merge_join> except that it mutates the values being merged and returns the
mutated value.

I<Since C<4.15>>

=over 4

=item merge_join_mutate example 1

  # given: synopsis

  package main;

  use Venus 'merge_join_mutate';

  my $merge_join_mutate = merge_join_mutate;

  # undef

=back

=over 4

=item merge_join_mutate example 2

  # given: synopsis

  package main;

  use Venus 'merge_join_mutate';

  my $merge_join_mutate = merge_join_mutate 1;

  # 1

=back

=over 4

=item merge_join_mutate example 3

  # given: synopsis

  package main;

  use Venus 'merge_join_mutate';

  $result = 1;

  my $merge_join_mutate = merge_join_mutate $result, 2;

  # 2

  $result;

  # 2

=back

=over 4

=item merge_join_mutate example 4

  # given: synopsis

  package main;

  use Venus 'merge_join_mutate';

  $result = 1;

  my $merge_join_mutate = merge_join_mutate $result, [2, 3];

  # [2, 3]

  $result;

  # [2, 3]

=back

=over 4

=item merge_join_mutate example 5

  # given: synopsis

  package main;

  use Venus 'merge_join_mutate';

  $result = [1, 2];

  my $merge_join_mutate = merge_join_mutate $result, 3;

  # [1, 2, 3]

  $result;

  # [1, 2, 3]

=back

=over 4

=item merge_join_mutate example 6

  # given: synopsis

  package main;

  use Venus 'merge_join_mutate';

  $result = [1, 2];

  my $merge_join_mutate = merge_join_mutate $result, [3, 4];

  # [1, 2, 3, 4]

  $result;

  # [1, 2, 3, 4]

=back

=over 4

=item merge_join_mutate example 7

  # given: synopsis

  package main;

  use Venus 'merge_join_mutate';

  $result = {a => 1};

  my $merge_join_mutate = merge_join_mutate $result, {a => 2, b => 3};

  # {a => 2, b => 3}

  $result;

  # {a => 2, b => 3}

=back

=cut

=head2 merge_keep

  merge_keep(any @args) (any)

The merge_keep function merges two (or more) values and returns a new values
based on the types of the inputs:

B<Note:> This function retains the existing data, appends arrayrefs with
arrayrefs, and only merges new keys and values when merging hashrefs with
hashrefs.

=over 4

=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "scalar" we
keep the C<lvalue>.

=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "arrayref" we
keep the C<lvalue>.

=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "hashref" we
keep the C<lvalue>.

=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "scalar" we
append the C<rvalue> to the C<lvalue>.

=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "arrayref"
we append the items in C<rvalue> to the C<lvalue>.

=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "hashref" we
append the C<rvalue> to the C<lvalue>.

=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "scalar" we
keep the C<lvalue>.

=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "arrayref" we
keep the C<lvalue>.

=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "hashref" we
append the keys and values in C<rvalue> to the C<lvalue>, but without
overwriting existing keys if there's overlap.

=back

I<Since C<4.15>>

=over 4

=item merge_keep example 1

  # given: synopsis

  package main;

  use Venus 'merge_keep';

  my $merge_keep = merge_keep;

  # undef

=back

=over 4

=item merge_keep example 2

  # given: synopsis

  package main;

  use Venus 'merge_keep';

  my $merge_keep = merge_keep 1;

  # 1

=back

=over 4

=item merge_keep example 3

  # given: synopsis

  package main;

  use Venus 'merge_keep';

  my $merge_keep = merge_keep 1, 2;

  # 1

=back

=over 4

=item merge_keep example 4

  # given: synopsis

  package main;

  use Venus 'merge_keep';

  my $merge_keep = merge_keep 1, [2, 3];

  # 1

=back

=over 4

=item merge_keep example 5

  # given: synopsis

  package main;

  use Venus 'merge_keep';

  my $merge_keep = merge_keep [1, 2], 3;

  # [1, 2, 3]

=back

=over 4

=item merge_keep example 6

  # given: synopsis

  package main;

  use Venus 'merge_keep';

  my $merge_keep = merge_keep [1, 2], [3, 4];

  # [1, 2, 3, 4]

=back

=over 4

=item merge_keep example 7

  # given: synopsis

  package main;

  use Venus 'merge_keep';

  my $merge_keep = merge_keep {a => 1}, {a => 2, b => 3};

  # {a => 1, b => 3}

=back

=over 4

=item merge_keep example 8

  # given: synopsis

  package main;

  use Venus 'merge_keep';

  my $merge_keep = merge_keep(
    {
      a => 1,
      b => {x => 10},
      d => 0,
      g => [4],
    },
    {
      b => {y => 20},
      c => 3,
      e => [5],
      f => [6]
    },
    {
      b => {y => 30, z => 456},
      c => {z => 123},
      d => 2,
      e => [6, 7],
      f => {7, 8},
      g => 5,
    },
  );

  # {
  #   a => 1,
  #   b => {
  #     x => 10,
  #     y => 20,
  #     z => 456
  #   },
  #   c => 3,
  #   d => 0,
  #   e => [5, 6, 7],
  #   f => [6, {7, 8}],
  #   g => [4, 5],
  # }

=back

=cut

=head2 merge_keep_mutate

  merge_keep_mutate(any @args) (any)

The merge_keep_mutate performs a merge operaiton in accordance with
L</merge_keep> except that it mutates the values being merged and returns the
mutated value.

I<Since C<4.15>>

=over 4

=item merge_keep_mutate example 1

  # given: synopsis

  package main;

  use Venus 'merge_keep_mutate';

  my $merge_keep_mutate = merge_keep_mutate;

  # undef

=back

=over 4

=item merge_keep_mutate example 2

  # given: synopsis

  package main;

  use Venus 'merge_keep_mutate';

  my $merge_keep_mutate = merge_keep_mutate 1;

  # 1

=back

=over 4

=item merge_keep_mutate example 3

  # given: synopsis

  package main;

  use Venus 'merge_keep_mutate';

  $result = 1;

  my $merge_keep_mutate = merge_keep_mutate $result, 2;

  # 1

  $result;

  # 1

=back

=over 4

=item merge_keep_mutate example 4

  # given: synopsis

  package main;

  use Venus 'merge_keep_mutate';

  $result = 1;

  my $merge_keep_mutate = merge_keep_mutate $result, [2, 3];

  # 1

  $result;

  # 1

=back

=over 4

=item merge_keep_mutate example 5

  # given: synopsis

  package main;

  use Venus 'merge_keep_mutate';

  $result = [1, 2];

  my $merge_keep_mutate = merge_keep_mutate $result, 3;

  # [1, 2, 3]

  $result;

  # [1, 2, 3]

=back

=over 4

=item merge_keep_mutate example 6

  # given: synopsis

  package main;

  use Venus 'merge_keep_mutate';

  $result = [1, 2];

  my $merge_keep_mutate = merge_keep_mutate $result, [3, 4];

  # [1, 2, 3, 4]

  $result;

  # [1, 2, 3, 4]

=back

=over 4

=item merge_keep_mutate example 7

  # given: synopsis

  package main;

  use Venus 'merge_keep_mutate';

  $result = {a => 1};

  my $merge_keep_mutate = merge_keep_mutate $result, {a => 2, b => 3};

  # {a => 1, b => 3}

  $result;

  # {a => 1, b => 3}

=back

=cut

=head2 merge_swap

  merge_swap(any @args) (any)

The merge_swap function merges two (or more) values and returns a new values
based on the types of the inputs:

B<Note:> This function replaces the existing data, including when merging
hashrefs with hashrefs, and overwrites values (instead of appending) when
merging arrayrefs with arrayrefs.

=over 4

=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "arrayref" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "hashref" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "scalar" we
append the C<rvalue> to the C<lvalue>.

=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "arrayref"
we replace each items in C<lvalue> with the value at the corresponding position
in the C<rvalue>.

=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "hashref" we
append the C<rvalue> to the C<lvalue>.

=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "arrayref" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "hashref" we
append the keys and values in C<rvalue> to the C<lvalue>, overwriting existing
keys if there's overlap.

=back

I<Since C<4.15>>

=over 4

=item merge_swap example 1

  # given: synopsis

  package main;

  use Venus 'merge_swap';

  my $merge_swap = merge_swap;

  # undef

=back

=over 4

=item merge_swap example 2

  # given: synopsis

  package main;

  use Venus 'merge_swap';

  my $merge_swap = merge_swap 1;

  # 1

=back

=over 4

=item merge_swap example 3

  # given: synopsis

  package main;

  use Venus 'merge_swap';

  my $merge_swap = merge_swap 1, 2;

  # 2

=back

=over 4

=item merge_swap example 4

  # given: synopsis

  package main;

  use Venus 'merge_swap';

  my $merge_swap = merge_swap 1, [2, 3];

  # [2, 3]

=back

=over 4

=item merge_swap example 5

  # given: synopsis

  package main;

  use Venus 'merge_swap';

  my $merge_swap = merge_swap [1, 2], 3;

  # [1, 2, 3]

=back

=over 4

=item merge_swap example 6

  # given: synopsis

  package main;

  use Venus 'merge_swap';

  my $merge_swap = merge_swap [1, 2, 3], [4, 5];

  # [4, 5, 3]

=back

=over 4

=item merge_swap example 7

  # given: synopsis

  package main;

  use Venus 'merge_swap';

  my $merge_swap = merge_swap {a => 1}, {a => 2, b => 3};

  # {a => 2, b => 3}

=back

=over 4

=item merge_swap example 8

  # given: synopsis

  package main;

  use Venus 'merge_swap';

  my $merge_swap = merge_swap(
    {
      a => 1,
      b => {x => 10},
      d => 0,
      g => [4],
    },
    {
      b => {y => 20},
      c => 3,
      e => [5],
      f => [6]
    },
    {
      b => {y => 30, z => 456},
      c => {z => 123},
      d => 2,
      e => [6, 7],
      f => {7, 8},
      g => 5,
    },
  );

  # {
  #   a => 1,
  #   b => {
  #     x => 10,
  #     y => 30,
  #     z => 456
  #   },
  #   c => {z => 123},
  #   d => 2,
  #   e => [6, 7],
  #   f => [6, {7, 8}],
  #   g => [4, 5],
  # }

=back

=cut

=head2 merge_swap_mutate

  merge_swap_mutate(any @args) (any)

The merge_swap_mutate performs a merge operaiton in accordance with
L</merge_swap> except that it mutates the values being merged and returns the
mutated value.

I<Since C<4.15>>

=over 4

=item merge_swap_mutate example 1

  # given: synopsis

  package main;

  use Venus 'merge_swap_mutate';

  $result = undef;

  my $merge_swap_mutate = merge_swap_mutate $result;

  # undef

  $result;

  # undef

=back

=over 4

=item merge_swap_mutate example 2

  # given: synopsis

  package main;

  use Venus 'merge_swap_mutate';

  $result = 1;

  my $merge_swap_mutate = merge_swap_mutate $result;

  # 1

  $result;

  # 1

=back

=over 4

=item merge_swap_mutate example 3

  # given: synopsis

  package main;

  use Venus 'merge_swap_mutate';

  $result = 1;

  my $merge_swap_mutate = merge_swap_mutate $result, 2;

  # 2

  $result;

  # 2

=back

=over 4

=item merge_swap_mutate example 4

  # given: synopsis

  package main;

  use Venus 'merge_swap_mutate';

  $result = 1;

  my $merge_swap_mutate = merge_swap_mutate $result, [2, 3];

  # [2, 3]

  $result;

  # [2, 3]

=back

=over 4

=item merge_swap_mutate example 5

  # given: synopsis

  package main;

  use Venus 'merge_swap_mutate';

  $result = [1, 2];

  my $merge_swap_mutate = merge_swap_mutate $result, 3;

  # [1, 2, 3]

  $result;

  # [1, 2, 3]

=back

=over 4

=item merge_swap_mutate example 6

  # given: synopsis

  package main;

  use Venus 'merge_swap_mutate';

  $result = [1, 2, 3];

  my $merge_swap_mutate = merge_swap_mutate $result, [4, 5];

  # [4, 5, 3]

  $result;

  # [4, 5, 3]

=back

=over 4

=item merge_swap_mutate example 7

  # given: synopsis

  package main;

  use Venus 'merge_swap_mutate';

  $result = {a => 1};

  my $merge_swap_mutate = merge_swap_mutate $result, {a => 2, b => 3};

  # {a => 2, b => 3}

  $result;

  # {a => 2, b => 3}

=back

=cut

=head2 merge_take

  merge_take(any @args) (any)

The merge_take function merges two (or more) values and returns a new values
based on the types of the inputs:

B<Note:> This function always "takes" the new value, does not append arrayrefs,
and overwrites keys and values when merging hashrefs with hashrefs.

=over 4

=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "arrayref" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "hashref" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "arrayref"
we keep the C<rvalue>.

=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "hashref" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "arrayref" we
keep the C<rvalue>.

=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "hashref" we
append the keys and values in C<rvalue> to the C<lvalue>, overwriting existing
keys if there's overlap.

=back

I<Since C<4.15>>

=over 4

=item merge_take example 1

  # given: synopsis

  package main;

  use Venus 'merge_take';

  my $merge_take = merge_take;

  # undef

=back

=over 4

=item merge_take example 2

  # given: synopsis

  package main;

  use Venus 'merge_take';

  my $merge_take = merge_take 1;

  # 1

=back

=over 4

=item merge_take example 3

  # given: synopsis

  package main;

  use Venus 'merge_take';

  my $merge_take = merge_take 1, 2;

  # 2

=back

=over 4

=item merge_take example 4

  # given: synopsis

  package main;

  use Venus 'merge_take';

  my $merge_take = merge_take [1], [2, 3];

  # [2, 3]

=back

=over 4

=item merge_take example 5

  # given: synopsis

  package main;

  use Venus 'merge_take';

  my $merge_take = merge_take {a => 1, b => {x => 10}}, {b => {y => 20}, c => 3};

  # {a => 1, b => {x => 10, y => 20}, c => 3}

=back

=over 4

=item merge_take example 6

  # given: synopsis

  package main;

  use Venus 'merge_take';

  my $merge_take = merge_take [1, 2], 3;

  # 3

=back

=over 4

=item merge_take example 7

  # given: synopsis

  package main;

  use Venus 'merge_take';

  my $merge_take = merge_take {a => 1}, 2;

  # 2

=back

=over 4

=item merge_take example 8

  # given: synopsis

  package main;

  use Venus 'merge_take';

  my $merge_take = merge_take(
    {
      a => 1,
      b => {x => 10},
      d => 0,
      g => [4],
    },
    {
      b => {y => 20},
      c => 3,
      e => [5],
      f => [6]
    },
    {
      b => {y => 30, z => 456},
      c => {z => 123},
      d => 2,
      e => [6, 7],
      f => {7, 8},
      g => 5,
    },
  );

  # {
  #   a => 1,
  #   b => {
  #     x => 10,
  #     y => 30,
  #     z => 456
  #   },
  #   c => {z => 123},
  #   d => 2,
  #   e => [6, 7],
  #   f => {7, 8},
  #   g => 5,
  # }

=back

=cut

=head2 merge_take_mutate

  merge_take_mutate(any @args) (any)

The merge_take_mutate performs a merge operaiton in accordance with
L</merge_take> except that it mutates the values being merged and returns the
mutated value.

I<Since C<4.15>>

=over 4

=item merge_take_mutate example 1

  # given: synopsis

  package main;

  use Venus 'merge_take_mutate';

  $result = undef;

  my $merge_take_mutate = merge_take_mutate $result;

  # undef

  $result;

  # undef

=back

=over 4

=item merge_take_mutate example 2

  # given: synopsis

  package main;

  use Venus 'merge_take_mutate';

  $result = 1;

  my $merge_take_mutate = merge_take_mutate $result;

  # 1

  $result;

  # 1

=back

=over 4

=item merge_take_mutate example 3

  # given: synopsis

  package main;

  use Venus 'merge_take_mutate';

  $result = 1;

  my $merge_take_mutate = merge_take_mutate $result, 2;

  # 2

  $result;

  # 2

=back

=over 4

=item merge_take_mutate example 4

  # given: synopsis

  package main;

  use Venus 'merge_take_mutate';

  $result = [1];

  my $merge_take_mutate = merge_take_mutate $result, [2, 3];

  # [2, 3]

  $result;

  # [2, 3]

=back

=over 4

=item merge_take_mutate example 5

  # given: synopsis

  package main;

  use Venus 'merge_take_mutate';

  $result = {a => 1, b => {x => 10}};

  my $merge_take_mutate = merge_take_mutate $result, {b => {y => 20}, c => 3};

  # {a => 1, b => {x => 10, y => 20}, c => 3}

  $result;

  # {a => 1, b => {x => 10, y => 20}, c => 3}

=back

=over 4

=item merge_take_mutate example 6

  # given: synopsis

  package main;

  use Venus 'merge_take_mutate';

  $result = [1, 2];

  my $merge_take_mutate = merge_take_mutate $result, 3;

  # 3

  $result;

  # 3

=back

=over 4

=item merge_take_mutate example 7

  # given: synopsis

  package main;

  use Venus 'merge_take_mutate';

  $result = {a => 1};

  my $merge_take_mutate = merge_take_mutate $result, 2;

  # 2

  $result;

  # 2

=back

=cut

=head2 meta

  meta(string $value, string | coderef $code, any @args) (any)

The meta function builds and returns a L<Venus::Meta> object, or dispatches to
the coderef or method provided.

I<Since C<2.55>>

=over 4

=item meta example 1

  package main;

  use Venus 'meta';

  my $meta = meta 'Venus';

  # bless({...}, 'Venus::Meta')

=back

=over 4

=item meta example 2

  package main;

  use Venus 'meta';

  my $result = meta 'Venus', 'sub', 'meta';

  # 1

=back

=cut

=head2 name

  name(string $value, string | coderef $code, any @args) (any)

The name function builds and returns a L<Venus::Name> object, or dispatches to
the coderef or method provided.

I<Since C<2.55>>

=over 4

=item name example 1

  package main;

  use Venus 'name';

  my $name = name 'Foo/Bar';

  # bless({...}, 'Venus::Name')

=back

=over 4

=item name example 2

  package main;

  use Venus 'name';

  my $name = name 'Foo/Bar', 'package';

  # "Foo::Bar"

=back

=cut

=head2 number

  number(Num $value, string | coderef $code, any @args) (any)

The number function builds and returns a L<Venus::Number> object, or dispatches
to the coderef or method provided.

I<Since C<2.55>>

=over 4

=item number example 1

  package main;

  use Venus 'number';

  my $number = number 1_000;

  # bless({...}, 'Venus::Number')

=back

=over 4

=item number example 2

  package main;

  use Venus 'number';

  my $number = number 1_000, 'prepend', 1;

  # 11_000

=back

=cut

=head2 opts

  opts(arrayref $value, string | coderef $code, any @args) (any)

The opts function builds and returns a L<Venus::Opts> object, or dispatches to
the coderef or method provided.

I<Since C<2.55>>

=over 4

=item opts example 1

  package main;

  use Venus 'opts';

  my $opts = opts ['--resource', 'users'];

  # bless({...}, 'Venus::Opts')

=back

=over 4

=item opts example 2

  package main;

  use Venus 'opts';

  my $opts = opts ['--resource', 'users'], 'reparse', ['resource|r=s', 'help|h'];

  # bless({...}, 'Venus::Opts')

  # my $resource = $opts->get('resource');

  # "users"

=back

=cut

=head2 pairs

  pairs(any $data) (arrayref)

The pairs function accepts an arrayref or hashref and returns an arrayref of
arrayrefs holding keys (or indices) and values. The function returns an empty
arrayref for all other values provided. Returns a list in list context.

I<Since C<3.04>>

=over 4

=item pairs example 1

  package main;

  use Venus 'pairs';

  my $pairs = pairs [1..4];

  # [[0,1], [1,2], [2,3], [3,4]]

=back

=over 4

=item pairs example 2

  package main;

  use Venus 'pairs';

  my $pairs = pairs {'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4};

  # [['a',1], ['b',2], ['c',3], ['d',4]]

=back

=over 4

=item pairs example 3

  package main;

  use Venus 'pairs';

  my @pairs = pairs [1..4];

  # ([0,1], [1,2], [2,3], [3,4])

=back

=over 4

=item pairs example 4

  package main;

  use Venus 'pairs';

  my @pairs = pairs {'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4};

  # (['a',1], ['b',2], ['c',3], ['d',4])

=back

=cut

=head2 path

  path(string $value, string | coderef $code, any @args) (any)

The path function builds and returns a L<Venus::Path> object, or dispatches
to the coderef or method provided.

I<Since C<2.55>>

=over 4

=item path example 1

  package main;

  use Venus 'path';

  my $path = path 't/data/planets';

  # bless({...}, 'Venus::Path')

=back

=over 4

=item path example 2

  package main;

  use Venus 'path';

  my $path = path 't/data/planets', 'absolute';

  # bless({...}, 'Venus::Path')

=back

=cut

=head2 perl

  perl(string $call, any $data) (any)

The perl function builds a L<Venus::Dump> object and will either
L<Venus::Dump/decode> or L<Venus::Dump/encode> based on the argument provided
and returns the result.

I<Since C<2.40>>

=over 4

=item perl example 1

  package main;

  use Venus 'perl';

  my $decode = perl 'decode', '{stable=>bless({},\'Venus::True\')}';

  # { stable => 1 }

=back

=over 4

=item perl example 2

  package main;

  use Venus 'perl';

  my $encode = perl 'encode', { stable => true };

  # '{stable=>bless({},\'Venus::True\')}'

=back

=over 4

=item perl example 3

  package main;

  use Venus 'perl';

  my $perl = perl;

  # bless({...}, 'Venus::Dump')

=back

=over 4

=item perl example 4

  package main;

  use Venus 'perl';

  my $perl = perl 'class', {data => "..."};

  # Exception! (isa Venus::Fault)

=back

=cut

=head2 process

  process(string | coderef $code, any @args) (any)

The process function builds and returns a L<Venus::Process> object, or
dispatches to the coderef or method provided.

I<Since C<2.55>>

=over 4

=item process example 1

  package main;

  use Venus 'process';

  my $process = process;

  # bless({...}, 'Venus::Process')

=back

=over 4

=item process example 2

  package main;

  use Venus 'process';

  my $process = process 'do', 'alarm', 10;

  # bless({...}, 'Venus::Process')

=back

=cut

=head2 proto

  proto(hashref $value, string | coderef $code, any @args) (any)

The proto function builds and returns a L<Venus::Prototype> object, or
dispatches to the coderef or method provided.

I<Since C<2.55>>

=over 4

=item proto example 1

  package main;

  use Venus 'proto';

  my $proto = proto {
    '$counter' => 0,
  };

  # bless({...}, 'Venus::Prototype')

=back

=over 4

=item proto example 2

  package main;

  use Venus 'proto';

  my $proto = proto { '$counter' => 0 }, 'apply', {
    '&decrement' => sub { $_[0]->counter($_[0]->counter - 1) },
    '&increment' => sub { $_[0]->counter($_[0]->counter + 1) },
  };

  # bless({...}, 'Venus::Prototype')

=back

=cut

=head2 puts

  puts(any @args) (arrayref)

The puts function select values from within the underlying data structure using
L<Venus::Array/path> or L<Venus::Hash/path>, optionally assigning the value to
the preceeding scalar reference and returns all the values selected.

I<Since C<3.20>>

=over 4

=item puts example 1

  package main;

  use Venus 'puts';

  my $data = {
    size => "small",
    fruit => "apple",
    meta => {
      expiry => '5d',
    },
    color => "red",
  };

  puts $data, (
    \my $fruit, 'fruit',
    \my $expiry, 'meta.expiry'
  );

  my $puts = [$fruit, $expiry];

  # ["apple", "5d"]

=back

=cut

=head2 raise

  raise(string $class | tuple[string, string] $class, any @args) (Venus::Error)

The raise function generates and throws a named exception object derived from
L<Venus::Error>, or provided base class, using the exception object arguments
provided.

I<Since C<0.01>>

=over 4

=item raise example 1

  package main;

  use Venus 'raise';

  my $error = raise 'MyApp::Error';

  # bless({...}, 'MyApp::Error')

=back

=over 4

=item raise example 2

  package main;

  use Venus 'raise';

  my $error = raise ['MyApp::Error', 'Venus::Error'];

  # bless({...}, 'MyApp::Error')

=back

=over 4

=item raise example 3

  package main;

  use Venus 'raise';

  my $error = raise ['MyApp::Error', 'Venus::Error'], {
    message => 'Something failed!',
  };

  # bless({message => 'Something failed!', ...}, 'MyApp::Error')

=back

=over 4

=item raise example 4

  package main;

  use Venus 'raise';

  my $error = raise 'MyApp::Error', message => 'Something failed!';

  # bless({message => 'Something failed!', ...}, 'MyApp::Error')

=back

=over 4

=item raise example 5

  package main;

  use Venus 'raise';

  my $error = raise 'MyApp::Error', name => 'on.issue',  message => 'Something failed!';

  # bless({message => 'Something failed!', ...}, 'MyApp::Error')

=back

=cut

=head2 random

  random(string | coderef $code, any @args) (any)

The random function builds and returns a L<Venus::Random> object, or dispatches
to the coderef or method provided.

I<Since C<2.55>>

=over 4

=item random example 1

  package main;

  use Venus 'random';

  my $random = random;

  # bless({...}, 'Venus::Random')

=back

=over 4

=item random example 2

  package main;

  use Venus 'random';

  my $random = random 'collect', 10, 'letter';

  # "ryKUPbJHYT"

=back

=cut

=head2 range

  range(number | string @args) (arrayref)

The range function returns the result of a L<Venus::Array/range> operation.

I<Since C<3.20>>

=over 4

=item range example 1

  package main;

  use Venus 'range';

  my $range = range [1..9], ':4';

  # [1..5]

=back

=over 4

=item range example 2

  package main;

  use Venus 'range';

  my $range = range [1..9], '-4:-1';

  # [6..9]

=back

=cut

=head2 read_env

  read_env(string $data) (Venus::Config)

The read_env function returns a new L<Venus::Config> object based on the string
of key/value pairs provided.

I<Since C<4.15>>

=over 4

=item read_env example 1

  package main;

  use Venus 'read_env';

  my $read_env = read_env "APPNAME=Example\nAPPVER=0.01\n# Comment\n\n\nAPPTAG=\"Godzilla\"";

  # bless(..., 'Venus::Config')

=back

=cut

=head2 read_env_file

  read_env_file(string $file) (Venus::Config)

The read_env_file function uses L<Venus::Path> to return a new L<Venus::Config>
object based on the file provided.

I<Since C<4.15>>

=over 4

=item read_env_file example 1

  package main;

  use Venus 'read_env_file';

  my $config = read_env_file 't/conf/read.env';

  # bless(..., 'Venus::Config')

=back

=cut

=head2 read_json

  read_json(string $data) (Venus::Config)

The read_json function returns a new L<Venus::Config> object based on the JSON
string provided.

I<Since C<4.15>>

=over 4

=item read_json example 1

  package main;

  use Venus 'read_json';

  my $config = read_json q(
  {
    "$metadata": {
      "tmplog": "/tmp/log"
    },
    "$services": {
      "log": { "package": "Venus/Path", "argument": { "$metadata": "tmplog" } }
    }
  }
  );

  # bless(..., 'Venus::Config')

=back

=cut

=head2 read_json_file

  read_json_file(string $file) (Venus::Config)

The read_json_file function uses L<Venus::Path> to return a new
L<Venus::Config> object based on the file provided.

I<Since C<4.15>>

=over 4

=item read_json_file example 1

  package main;

  use Venus 'read_json_file';

  my $config = read_json_file 't/conf/read.json';

  # bless(..., 'Venus::Config')

=back

=cut

=head2 read_perl

  read_perl(string $data) (Venus::Config)

The read_perl function returns a new L<Venus::Config> object based on the Perl
string provided.

I<Since C<4.15>>

=over 4

=item read_perl example 1

  package main;

  use Venus 'read_perl';

  my $config = read_perl q(
  {
    '$metadata' => {
      tmplog => "/tmp/log"
    },
    '$services' => {
      log => { package => "Venus/Path", argument => { '$metadata' => "tmplog" } }
    }
  }
  );

  # bless(..., 'Venus::Config')

=back

=cut

=head2 read_perl_file

  read_perl_file(string $file) (Venus::Config)

The read_perl_file function uses L<Venus::Path> to return a new
L<Venus::Config> object based on the file provided.

I<Since C<4.15>>

=over 4

=item read_perl_file example 1

  package main;

  use Venus 'read_perl_file';

  my $config = read_perl_file 't/conf/read.perl';

  # bless(..., 'Venus::Config')

=back

=cut

=head2 read_yaml

  read_yaml(string $data) (Venus::Config)

The read_yaml function returns a new L<Venus::Config> object based on the YAML
string provided.

I<Since C<4.15>>

=over 4

=item read_yaml example 1

  package main;

  use Venus 'read_yaml';

  my $config = read_yaml q(
  '$metadata':
    tmplog: /tmp/log
  '$services':
    log:
      package: "Venus/Path"
      argument:
        '$metadata': tmplog
  );

  # bless(..., 'Venus::Config')

=back

=cut

=head2 read_yaml_file

  read_yaml_file(string $file) (Venus::Config)

The read_yaml_file function uses L<Venus::Path> to return a new
L<Venus::Config> object based on the YAML string provided.

I<Since C<4.15>>

=over 4

=item read_yaml_file example 1

  package main;

  use Venus 'read_yaml_file';

  my $config = read_yaml_file 't/conf/read.yaml';

  # bless(..., 'Venus::Config')

=back

=cut

=head2 regexp

  regexp(string $value, string | coderef $code, any @args) (any)

The regexp function builds and returns a L<Venus::Regexp> object, or dispatches
to the coderef or method provided.

I<Since C<2.55>>

=over 4

=item regexp example 1

  package main;

  use Venus 'regexp';

  my $regexp = regexp '[0-9]';

  # bless({...}, 'Venus::Regexp')

=back

=over 4

=item regexp example 2

  package main;

  use Venus 'regexp';

  my $replace = regexp '[0-9]', 'replace', 'ID 12345', '0', 'g';

  # bless({...}, 'Venus::Replace')

  # $replace->get;

  # "ID 00000"

=back

=cut

=head2 render

  render(string $data, hashref $args) (string)

The render function accepts a string as a template and renders it using
L<Venus::Template>, and returns the result.

I<Since C<3.04>>

=over 4

=item render example 1

  package main;

  use Venus 'render';

  my $render = render 'hello {{name}}', {
    name => 'user',
  };

  # "hello user"

=back

=cut

=head2 replace

  replace(arrayref $value, string | coderef $code, any @args) (any)

The replace function builds and returns a L<Venus::Replace> object, or
dispatches to the coderef or method provided.

I<Since C<2.55>>

=over 4

=item replace example 1

  package main;

  use Venus 'replace';

  my $replace = replace ['hello world', 'world', 'universe'];

  # bless({...}, 'Venus::Replace')

=back

=over 4

=item replace example 2

  package main;

  use Venus 'replace';

  my $replace = replace ['hello world', 'world', 'universe'], 'get';

  # "hello universe"

=back

=cut

=head2 roll

  roll(string $name, any @args) (any)

The roll function takes a list of arguments, assuming the first argument is
invokable, and reorders the list such that the routine name provided comes
after the invocant (i.e. the 1st argument), creating a list acceptable to the
L</call> function.

I<Since C<2.32>>

=over 4

=item roll example 1

  package main;

  use Venus 'roll';

  my @list = roll('sha1_hex', 'Digest::SHA');

  # ('Digest::SHA', 'sha1_hex');

=back

=over 4

=item roll example 2

  package main;

  use Venus 'roll';

  my @list = roll('sha1_hex', call(\'Digest::SHA', 'new'));

  # (bless(do{\(my $o = '...')}, 'Digest::SHA'), 'sha1_hex');

=back

=cut

=head2 schema

  schema(string | coderef $code, any @args) (Venus::Schema)

The schema function builds and returns a L<Venus::Schema> object, or dispatches
to the coderef or method provided.

I<Since C<4.15>>

=over 4

=item schema example 1

  package main;

  use Venus 'schema';

  my $schema = schema;

  # bless({...}, "Venus::Schema")

=back

=over 4

=item schema example 2

  package main;

  use Venus 'schema';

  my $schema = schema 'rule', {
    selector => 'handles',
    presence => 'required',
    executes => [['type', 'arrayref']],
  };

  # bless({...}, "Venus::Schema")

=back

=over 4

=item schema example 3

  package main;

  use Venus 'schema';

  my $schema = schema 'rules', {
    selector => 'fname',
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  },{
    selector => 'lname',
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  };

  # bless({...}, "Venus::Schema")

=back

=cut

=head2 search

  search(arrayref $value, string | coderef $code, any @args) (any)

The search function builds and returns a L<Venus::Search> object, or dispatches
to the coderef or method provided.

I<Since C<2.55>>

=over 4

=item search example 1

  package main;

  use Venus 'search';

  my $search = search ['hello world', 'world'];

  # bless({...}, 'Venus::Search')

=back

=over 4

=item search example 2

  package main;

  use Venus 'search';

  my $search = search ['hello world', 'world'], 'count';

  # 1

=back

=cut

=head2 set

  set(arrayref $value) (Venus::Set)

The set function returns a L<Venus::Set> object for the arrayref provided.

I<Since C<4.11>>

=over 4

=item set example 1

  package main;

  use Venus;

  my $set = Venus::set [1..9];

  # bless(..., 'Venus::Set')

=back

=over 4

=item set example 2

  package main;

  use Venus;

  my $set = Venus::set [1..9], 'count';

  # 9

=back

=cut

=head2 sets

  sets(string @args) (arrayref)

The sets function find values from within the underlying data structure using
L<Venus::Array/path> or L<Venus::Hash/path>, where each argument pair is a
selector and value, and returns all the values provided. Returns a list in list
context. Note, nested data structures can be updated but not created.

I<Since C<4.15>>

=over 4

=item sets example 1

  package main;

  use Venus 'sets';

  my $data = ['foo', {'bar' => 'baz'}, 'bar', ['baz']];

  my $sets = sets $data, '3' => 'bar', '1.bar' => 'bar';

  # ['bar', 'bar']

=back

=over 4

=item sets example 2

  package main;

  use Venus 'sets';

  my $data = ['foo', {'bar' => 'baz'}, 'bar', ['baz']];

  my ($baz, $one_bar) = sets $data, '3' => 'bar', '1.bar' => 'bar';

  # ('bar', 'bar')

=back

=over 4

=item sets example 3

  package main;

  use Venus 'sets';

  my $data = {'foo' => {'bar' => 'baz'}, 'bar' => ['baz']};

  my $sets = sets $data, 'bar' => 'bar', 'foo.bar' => 'bar';

  # ['bar', 'bar']

=back

=over 4

=item sets example 4

  package main;

  use Venus 'sets';

  my $data = {'foo' => {'bar' => 'baz'}, 'bar' => ['baz']};

  my ($bar, $foo_bar) = sets $data, 'bar' => 'bar', 'foo.bar' => 'bar';

  # ('bar', 'bar')

=back

=cut

=head2 sorts

  sorts(any @args) (any)

The sorts function accepts a list of values, flattens any arrayrefs, and sorts
it using the default C<sort(LIST)> call style exclusively.

I<Since C<4.15>>

=over 4

=item sorts example 1

  package main;

  use Venus 'sorts';

  my @sorts = sorts 1..4;

  # (1..4)

=back

=over 4

=item sorts example 2

  package main;

  use Venus 'sorts';

  my @sorts = sorts 4,3,2,1;

  # (1..4)

=back

=over 4

=item sorts example 3

  package main;

  use Venus 'sorts';

  my @sorts = sorts [1..4], 5, [6..9];

  # (1..9)

=back

=cut

=head2 space

  space(any $name) (Venus::Space)

The space function returns a L<Venus::Space> object for the package provided.

I<Since C<2.32>>

=over 4

=item space example 1

  package main;

  use Venus 'space';

  my $space = space 'Venus::Scalar';

  # bless({value => 'Venus::Scalar'}, 'Venus::Space')

=back

=cut

=head2 string

  string(string $value, string | coderef $code, any @args) (any)

The string function builds and returns a L<Venus::String> object, or dispatches
to the coderef or method provided.

I<Since C<2.55>>

=over 4

=item string example 1

  package main;

  use Venus 'string';

  my $string = string 'hello world';

  # bless({...}, 'Venus::String')

=back

=over 4

=item string example 2

  package main;

  use Venus 'string';

  my $string = string 'hello world', 'camelcase';

  # "helloWorld"

=back

=cut

=head2 syscall

  syscall(number | string @args) (any)

The syscall function perlforms system call, i.e. a L<perlfunc/qx> operation,
and returns C<true> if the command succeeds, otherwise returns C<false>. In
list context, returns the output of the operation and the exit code.

I<Since C<3.04>>

=over 4

=item syscall example 1

  package main;

  use Venus 'syscall';

  my $syscall = syscall 'perl', '-v';

  # true

=back

=over 4

=item syscall example 2

  package main;

  use Venus 'syscall';

  my $syscall = syscall 'perl', '-z';

  # false

=back

=over 4

=item syscall example 3

  package main;

  use Venus 'syscall';

  my ($data, $code) = syscall 'sun', '--heat-death';

  # ('done', 0)

=back

=over 4

=item syscall example 4

  package main;

  use Venus 'syscall';

  my ($data, $code) = syscall 'earth', '--melt-icecaps';

  # ('', 127)

=back

=cut

=head2 template

  template(string $value, string | coderef $code, any @args) (any)

The template function builds and returns a L<Venus::Template> object, or
dispatches to the coderef or method provided.

I<Since C<2.55>>

=over 4

=item template example 1

  package main;

  use Venus 'template';

  my $template = template 'Hi {{name}}';

  # bless({...}, 'Venus::Template')

=back

=over 4

=item template example 2

  package main;

  use Venus 'template';

  my $template = template 'Hi {{name}}', 'render', undef, {
    name => 'stranger',
  };

  # "Hi stranger"

=back

=cut

=head2 test

  test(string $value, string | coderef $code, any @args) (any)

The test function builds and returns a L<Venus::Test> object, or dispatches to
the coderef or method provided.

I<Since C<2.55>>

=over 4

=item test example 1

  package main;

  use Venus 'test';

  my $test = test 't/Venus.t';

  # bless({...}, 'Venus::Test')

=back

=over 4

=item test example 2

  package main;

  use Venus 'test';

  my $test = test 't/Venus.t', 'for', 'synopsis';

  # bless({...}, 'Venus::Test')

=back

=cut

=head2 text_pod

  text_pod(string $value, string | coderef $code, any @args) (any)

The text_pod function builds and returns a L<Venus::Text::Pod> object, or
dispatches to the coderef or method provided.

I<Since C<4.15>>

=over 4

=item text_pod example 1

  package main;

  use Venus 'text_pod';

  my $text_pod = text_pod 't/data/sections';

  # bless({...}, 'Venus::Text::Pod')

=back

=over 4

=item text_pod example 2

  package main;

  use Venus 'text_pod';

  my $text_pod = text_pod 't/data/sections', 'string', undef, 'name';

  # "Example #1\nExample #2"

=back

=cut

=head2 text_pod_string

  text_pod_string(any @args) (any)

The text_pod_string function builds a L<Venus::Text::Pod> object for the
current file, i.e. L<perlfunc/__FILE__> or script, i.e. C<$0>, and returns the
result of a L<Venus::Text::Pod/string> operation using the arguments provided.

I<Since C<4.15>>

=over 4

=item text_pod_string example 1

  package main;

  use Venus 'text_pod_string';

  # =name
  #
  # Example #1
  #
  # =cut
  #
  # =name
  #
  # Example #2
  #
  # =cut
  #
  # =head1 NAME
  #
  # Example #1
  #
  # =cut
  #
  # =head1 NAME
  #
  # Example #2
  #
  # =cut
  #
  # =head1 ABSTRACT
  #
  # Example Abstract
  #
  # =cut

  my $text_pod_string = text_pod_string 'name';

  # "Example #1\nExample #2"

=back

=over 4

=item text_pod_string example 2

  package main;

  use Venus 'text_pod_string';

  # =name
  #
  # Example #1
  #
  # =cut
  #
  # =name
  #
  # Example #2
  #
  # =cut
  #
  # =head1 NAME
  #
  # Example #1
  #
  # =cut
  #
  # =head1 NAME
  #
  # Example #2
  #
  # =cut
  #
  # =head1 ABSTRACT
  #
  # Example Abstract
  #
  # =cut

  my $text_pod_string = text_pod_string 'head1', 'ABSTRACT';

  # "Example Abstract"

=back

=cut

=head2 text_tag

  text_tag(string $value, string | coderef $code, any @args) (any)

The text_tag function builds and returns a L<Venus::Text::Tag> object, or
dispatches to the coderef or method provided.

I<Since C<4.15>>

=over 4

=item text_tag example 1

  package main;

  use Venus 'text_tag';

  my $text_tag = text_tag 't/data/sections';

  # bless({...}, 'Venus::Text::Tag')

=back

=over 4

=item text_tag example 2

  package main;

  use Venus 'text_tag';

  my $text_tag = text_tag 't/data/sections', 'string', undef, 'name';

  # "Example Name"

=back

=cut

=head2 text_tag_string

  text_tag_string(any @args) (any)

The text_tag_string function builds a L<Venus::Text::Tag> object for the
current file, i.e. L<perlfunc/__FILE__> or script, i.e. C<$0>, and returns the
result of a L<Venus::Text::Tag/string> operation using the arguments provided.

I<Since C<4.15>>

=over 4

=item text_tag_string example 1

  package main;

  use Venus 'text_tag_string';

  # @@ name
  #
  # Example Name
  #
  # @@ end
  #
  # @@ titles #1
  #
  # Example Title #1
  #
  # @@ end
  #
  # @@ titles #2
  #
  # Example Title #2
  #
  # @@ end

  my $text_tag_string = text_tag_string 'name';

  # "Example Name"

=back

=over 4

=item text_tag_string example 2

  package main;

  use Venus 'text_tag_string';

  # @@ name
  #
  # Example Name
  #
  # @@ end
  #
  # @@ titles #1
  #
  # Example Title #1
  #
  # @@ end
  #
  # @@ titles #2
  #
  # Example Title #2
  #
  # @@ end

  my $text_tag_string = text_tag_string 'titles', '#1';

  # "Example Title #1"

=back

=over 4

=item text_tag_string example 3

  package main;

  use Venus 'text_tag_string';

  # @@ name
  #
  # Example Name
  #
  # @@ end
  #
  # @@ titles #1
  #
  # Example Title #1
  #
  # @@ end
  #
  # @@ titles #2
  #
  # Example Title #2
  #
  # @@ end

  my $text_tag_string = text_tag_string undef, 'name';

  # "Example Name"

=back

=cut

=head2 then

  then(string | object | coderef $self, any @args) (any)

The then function proxies the call request to the L</call> function and returns
the result as a list, prepended with the invocant.

I<Since C<2.32>>

=over 4

=item then example 1

  package main;

  use Venus 'then';

  my @list = then('Digest::SHA', 'sha1_hex');

  # ("Digest::SHA", "da39a3ee5e6b4b0d3255bfef95601890afd80709")

=back

=cut

=head2 throw

  throw(string | hashref $value, string | coderef $code, any @args) (any)

The throw function builds and returns a L<Venus::Throw> object, or dispatches
to the coderef or method provided.

I<Since C<2.55>>

=over 4

=item throw example 1

  package main;

  use Venus 'throw';

  my $throw = throw 'Example::Error';

  # bless({...}, 'Venus::Throw')

=back

=over 4

=item throw example 2

  package main;

  use Venus 'throw';

  my $throw = throw 'Example::Error', 'error';

  # bless({...}, 'Example::Error')

=back

=over 4

=item throw example 3

  package main;

  use Venus 'throw';

  my $throw = throw {
    name => 'on.execute',
    package => 'Example::Error',
    capture => ['...'],
    stash => {
      time => time,
    },
  };

  # bless({...}, 'Venus::Throw')

=back

=cut

=head2 true

  true() (boolean)

The true function returns a truthy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<1> value.

I<Since C<0.01>>

=over 4

=item true example 1

  package main;

  use Venus;

  my $true = true;

  # 1

=back

=over 4

=item true example 2

  package main;

  use Venus;

  my $false = !true;

  # 0

=back

=cut

=head2 try

  try(any $data, string | coderef $code, any @args) (any)

The try function builds and returns a L<Venus::Try> object, or dispatches to
the coderef or method provided.

I<Since C<2.55>>

=over 4

=item try example 1

  package main;

  use Venus 'try';

  my $try = try sub {};

  # bless({...}, 'Venus::Try')

  # my $result = $try->result;

  # ()

=back

=over 4

=item try example 2

  package main;

  use Venus 'try';

  my $try = try sub { die };

  # bless({...}, 'Venus::Try')

  # my $result = $try->result;

  # Exception! (isa Venus::Error)

=back

=over 4

=item try example 3

  package main;

  use Venus 'try';

  my $try = try sub { die }, 'maybe';

  # bless({...}, 'Venus::Try')

  # my $result = $try->result;

  # undef

=back

=cut

=head2 tv

  tv(any $lvalue, any $rvalue) (boolean)

The tv function compares the lvalue and rvalue and returns true if they have
the same type and value, otherwise returns false. b<Note:> Comparison of
coderefs, filehandles, and blessed objects with private state are impossible.
This function will only return true if these data types are L<"identical"|/is>.
It's also impossible to know which blessed objects have private state and
therefore could produce false-positives when comparing object in those cases.

I<Since C<4.15>>

=over 4

=item tv example 1

  # given: synopsis

  package main;

  use Venus 'tv';

  my $tv = tv 1, 1;

  # true

=back

=over 4

=item tv example 2

  # given: synopsis

  package main;

  use Venus 'tv';

  my $tv = tv '1', 1;

  # false

=back

=over 4

=item tv example 3

  # given: synopsis

  package main;

  use Venus 'tv';

  my $tv = tv ['0', 1..4], ['0', 1..4];

  # true

=back

=over 4

=item tv example 4

  # given: synopsis

  package main;

  use Venus 'tv';

  my $tv = tv ['0', 1..4], [0, 1..4];

  # false

=back

=over 4

=item tv example 5

  # given: synopsis

  package main;

  use Venus 'tv';

  my $tv = tv undef, undef;

  # true

=back

=over 4

=item tv example 6

  # given: synopsis

  package main;

  use Venus 'number', 'tv';

  my $a = number 1;

  my $tv = tv $a, undef;

  # false

=back

=over 4

=item tv example 7

  # given: synopsis

  package main;

  use Venus 'number', 'tv';

  my $a = number 1;

  my $tv = tv $a, $a;

  # true

=back

=over 4

=item tv example 8

  # given: synopsis

  package main;

  use Venus 'number', 'tv';

  my $a = number 1;
  my $b = number 1;

  my $tv = tv $a, $b;

  # true

=back

=over 4

=item tv example 9

  # given: synopsis

  package main;

  use Venus 'number', 'tv';

  my $a = number 0;
  my $b = number 1;

  my $tv = tv $a, $b;

  # false

=back

=cut

=head2 type

  type(string | coderef $code, any @args) (any)

The type function builds and returns a L<Venus::Type> object, or dispatches to
the coderef or method provided.

I<Since C<4.15>>

=over 4

=item type example 1

  package main;

  use Venus 'type';

  my $type = type;

  # bless({...}, 'Venus::Type')

=back

=over 4

=item type example 2

  package main;

  use Venus 'type';

  my $expression = type 'expression', 'string | number';

  # ["either", "string", "number"]

=back

=over 4

=item type example 3

  package main;

  use Venus 'type';

  my $expression = type 'expression', ["either", "string", "number"];

  # "string | number"

=back

=cut

=head2 unpack

  unpack(any @args) (Venus::Unpack)

The unpack function builds and returns a L<Venus::Unpack> object.

I<Since C<2.40>>

=over 4

=item unpack example 1

  package main;

  use Venus 'unpack';

  my $unpack = unpack;

  # bless({...}, 'Venus::Unpack')

  # $unpack->checks('string');

  # false

  # $unpack->checks('undef');

  # false

=back

=over 4

=item unpack example 2

  package main;

  use Venus 'unpack';

  my $unpack = unpack rand;

  # bless({...}, 'Venus::Unpack')

  # $unpack->check('number');

  # false

  # $unpack->check('float');

  # true

=back

=cut

=head2 vars

  vars(hashref $value, string | coderef $code, any @args) (any)

The vars function builds and returns a L<Venus::Vars> object, or dispatches to
the coderef or method provided.

I<Since C<2.55>>

=over 4

=item vars example 1

  package main;

  use Venus 'vars';

  my $vars = vars {};

  # bless({...}, 'Venus::Vars')

=back

=over 4

=item vars example 2

  package main;

  use Venus 'vars';

  my $path = vars {}, 'exists', 'path';

  # "..."

=back

=cut

=head2 vns

  vns(string $name, args $args, string | coderef $callback, any @args) (any)

The vns function build a L<Venus> package based on the name provided, loads and
instantiates the package, and returns an instance of that package or dispatches
to the method provided and returns the result.

I<Since C<4.15>>

=over 4

=item vns example 1

  package main;

  use Venus 'vns';

  my $space = vns 'space';

  # bless({value => 'Venus'}, 'Venus::Space')

=back

=over 4

=item vns example 2

  package main;

  use Venus 'vns';

  my $space = vns 'space', 'Venus::String';

  # bless({value => 'Venus::String'}, 'Venus::Space')

=back

=over 4

=item vns example 3

  package main;

  use Venus 'vns';

  my $code = vns 'code', sub{};

  # bless({value => sub{...}}, 'Venus::Code')

=back

=cut

=head2 what

  what(any $data, string | coderef $code, any @args) (any)

The what function builds and returns a L<Venus::What> object, or dispatches to
the coderef or method provided.

I<Since C<4.11>>

=over 4

=item what example 1

  package main;

  use Venus 'what';

  my $what = what [1..4];

  # bless({...}, 'Venus::What')

  # $what->deduce;

  # bless({...}, 'Venus::Array')

=back

=over 4

=item what example 2

  package main;

  use Venus 'what';

  my $what = what [1..4], 'deduce';

  # bless({...}, 'Venus::Array')

=back

=cut

=head2 work

  work(coderef $callback) (Venus::Process)

The work function builds a L<Venus::Process> object, forks the current process
using the callback provided via the L<Venus::Process/work> operation, and
returns an instance of L<Venus::Process> representing the current process.

I<Since C<2.40>>

=over 4

=item work example 1

  package main;

  use Venus 'work';

  my $parent = work sub {
    my ($process) = @_;
    # in forked process ...
    $process->exit;
  };

  # bless({...}, 'Venus::Process')

=back

=cut

=head2 wrap

  wrap(string $data, string $name) (coderef)

The wrap function installs a wrapper function in the calling package which when
called either returns the package string if no arguments are provided, or calls
L</make> on the package with whatever arguments are provided and returns the
result. Unless an alias is provided as a second argument, special characters
are stripped from the package to create the function name.

I<Since C<2.32>>

=over 4

=item wrap example 1

  package main;

  use Venus 'wrap';

  my $coderef = wrap('Digest::SHA');

  # sub { ... }

  # my $digest = DigestSHA();

  # "Digest::SHA"

  # my $digest = DigestSHA(1);

  # bless(do{\(my $o = '...')}, 'Digest::SHA')

=back

=over 4

=item wrap example 2

  package main;

  use Venus 'wrap';

  my $coderef = wrap('Digest::SHA', 'SHA');

  # sub { ... }

  # my $digest = SHA();

  # "Digest::SHA"

  # my $digest = SHA(1);

  # bless(do{\(my $o = '...')}, 'Digest::SHA')

=back

=cut

=head2 write_env

  write_env(hashref $data) (string)

The write_env function returns a string representing environment variable
key/value pairs based on the L</value> held by the underlying L<Venus::Config>
object.

I<Since C<4.15>>

=over 4

=item write_env example 1

  package main;

  use Venus 'write_env';

  my $write_env = write_env {
    APPNAME => "Example",
    APPTAG => "Godzilla",
    APPVER => 0.01,
  };

  # "APPNAME=Example\nAPPTAG=Godzilla\nAPPVER=0.01"

=back

=cut

=head2 write_env_file

  write_env_file(string $path, hashref $data) (Venus::Config)

The write_env_file function saves a environment configuration file and returns
a new L<Venus::Config> object.

I<Since C<4.15>>

=over 4

=item write_env_file example 1

  package main;

  use Venus 'write_env_file';

  my $write_env_file = write_env_file 't/conf/write.env', {
    APPNAME => "Example",
    APPTAG => "Godzilla",
    APPVER => 0.01,
  };

  # bless(..., 'Venus::Config')

=back

=cut

=head2 write_json

  write_json(hashref $data) (string)

The write_json function returns a JSON encoded string based on the L</value>
held by the underlying L<Venus::Config> object.

I<Since C<4.15>>

=over 4

=item write_json example 1

  package main;

  use Venus 'write_json';

  my $write_json = write_json {
    '$services' => {
      log => { package => "Venus::Path" },
    },
  };

  # '{ "$services":{ "log":{ "package":"Venus::Path" } } }'

=back

=cut

=head2 write_json_file

  write_json_file(string $path, hashref $data) (Venus::Config)

The write_json_file function saves a JSON configuration file and returns a new
L<Venus::Config> object.

I<Since C<4.15>>

=over 4

=item write_json_file example 1

  package main;

  use Venus 'write_json_file';

  my $write_json_file = write_json_file 't/conf/write.json', {
    '$services' => {
      log => { package => "Venus/Path", argument => { value => "." } }
    }
  };

  # bless(..., 'Venus::Config')

=back

=cut

=head2 write_perl

  write_perl(hashref $data) (string)

The write_perl function returns a FILE encoded string based on the L</value>
held by the underlying L<Venus::Config> object.

I<Since C<4.15>>

=over 4

=item write_perl example 1

  package main;

  use Venus 'write_perl';

  my $write_perl = write_perl {
    '$services' => {
      log => { package => "Venus::Path" },
    },
  };

  # '{ "\$services" => { log => { package => "Venus::Path" } } }'

=back

=cut

=head2 write_perl_file

  write_perl_file(string $path, hashref $data) (Venus::Config)

The write_perl_file function saves a Perl configuration file and returns a new
L<Venus::Config> object.

I<Since C<4.15>>

=over 4

=item write_perl_file example 1

  package main;

  use Venus 'write_perl_file';

  my $write_perl_file = write_perl_file 't/conf/write.perl', {
    '$services' => {
      log => { package => "Venus/Path", argument => { value => "." } }
    }
  };

  # bless(..., 'Venus::Config')

=back

=cut

=head2 write_yaml

  write_yaml(hashref $data) (string)

The write_yaml function returns a FILE encoded string based on the L</value>
held by the underlying L<Venus::Config> object.

I<Since C<4.15>>

=over 4

=item write_yaml example 1

  package main;

  use Venus 'write_yaml';

  my $write_yaml = write_yaml {
    '$services' => {
      log => { package => "Venus::Path" },
    },
  };

  # '---\n$services:\n\s\slog:\n\s\s\s\spackage:\sVenus::Path'

=back

=cut

=head2 write_yaml_file

  write_yaml_file(string $path, hashref $data) (Venus::Config)

The write_yaml_file function saves a YAML configuration file and returns a new
L<Venus::Config> object.

I<Since C<4.15>>

=over 4

=item write_yaml_file example 1

  package main;

  use Venus 'write_yaml_file';

  my $write_yaml_file = write_yaml_file 't/conf/write.yaml', {
    '$services' => {
      log => { package => "Venus/Path", argument => { value => "." } }
    }
  };

  # bless(..., 'Venus::Config')

=back

=cut

=head2 yaml

  yaml(string $call, any $data) (any)

The yaml function builds a L<Venus::Yaml> object and will either
L<Venus::Yaml/decode> or L<Venus::Yaml/encode> based on the argument provided
and returns the result.

I<Since C<2.40>>

=over 4

=item yaml example 1

  package main;

  use Venus 'yaml';

  my $decode = yaml 'decode', "---\nname:\n- Ready\n- Robot\nstable: true\n";

  # { name => ["Ready", "Robot"], stable => 1 }

=back

=over 4

=item yaml example 2

  package main;

  use Venus 'yaml';

  my $encode = yaml 'encode', { name => ["Ready", "Robot"], stable => true };

  # '---\nname:\n- Ready\n- Robot\nstable: true\n'

=back

=over 4

=item yaml example 3

  package main;

  use Venus 'yaml';

  my $yaml = yaml;

  # bless({...}, 'Venus::Yaml')

=back

=over 4

=item yaml example 4

  package main;

  use Venus 'yaml';

  my $yaml = yaml 'class', {data => "..."};

  # Exception! (isa Venus::Fault)

=back

=cut

=head1 FEATURES

This package provides the following features:

=cut

=over 4

=item venus-args

This library contains a L<Venus::Args> class which provides methods for
accessing C<@ARGS> items.

=back

=over 4

=item venus-array

This library contains a L<Venus::Array> class which provides methods for
manipulating array data.

=back

=over 4

=item venus-assert

This library contains a L<Venus::Assert> class which provides a mechanism for
asserting type constraints and coercion.

=back

=over 4

=item venus-atom

This library contains a L<Venus::Atom> class which provides a write-once object
representing a constant value.

=back

=over 4

=item venus-boolean

This library contains a L<Venus::Boolean> class which provides a representation
for boolean values.

=back

=over 4

=item venus-box

This library contains a L<Venus::Box> class which provides a pure Perl boxing
mechanism.

=back

=over 4

=item venus-call

This library contains a L<Venus::Call> class which provides a protocol for
dynamically invoking methods with optional opt-in type safety.

=back

=over 4

=item venus-check

This library contains a L<Venus::Check> class which provides runtime dynamic type checking.

=back

=over 4

=item venus-class

This library contains a L<Venus::Class> class which provides a class builder.

=back

=over 4

=item venus-cli

This library contains a L<Venus::Cli> class which provides a superclass for
creating CLIs.

=back

=over 4

=item venus-code

This library contains a L<Venus::Code> class which provides methods for
manipulating subroutines.

=back

=over 4

=item venus-coercion

This library contains a L<Venus::Coercion> class which provides data type coercions via L<Venus::Check>.

=back

=over 4

=item venus-collect

This library contains a L<Venus::Collect> class which provides a mechanism for
iterating over mappable values.

=back

=over 4

=item venus-config

This library contains a L<Venus::Config> class which provides methods for
loading Perl, YAML, and JSON configuration data.

=back

=over 4

=item venus-constraint

This library contains a L<Venus::Constraint> class which provides data type
constraints via L<Venus::Check>.

=back

=over 4

=item venus-data

This library contains a L<Venus::Data> class which provides value object for
encapsulating data validation.

=back

=over 4

=item venus-date

This library contains a L<Venus::Date> class which provides methods for
formatting, parsing, and manipulating dates.

=back

=over 4

=item venus-dump

This library contains a L<Venus::Dump> class which provides methods for reading
and writing dumped Perl data.

=back

=over 4

=item venus-enum

This library contains a L<Venus::Enum> class which provides an interface for working with enumerations.

=back

=over 4

=item venus-error

This library contains a L<Venus::Error> class which represents a context-aware
error (exception object).

=back

=over 4

=item venus-factory

This library contains a L<Venus::Factory> class which provides an object-oriented factory pattern for building objects.

=back

=over 4

=item venus-false

This library contains a L<Venus::False> class which provides the global
C<false> value.

=back

=over 4

=item venus-fault

This library contains a L<Venus::Fault> class which represents a generic system
error (exception object).

=back

=over 4

=item venus-float

This library contains a L<Venus::Float> class which provides methods for
manipulating float data.

=back

=over 4

=item venus-future

This library contains a L<Venus::Future> class which provides a
framework-agnostic implementation of the Future pattern.

=back

=over 4

=item venus-gather

This library contains a L<Venus::Gather> class which provides an
object-oriented interface for complex pattern matching operations on
collections of data, e.g. array references.

=back

=over 4

=item venus-hash

This library contains a L<Venus::Hash> class which provides methods for
manipulating hash data.

=back

=over 4

=item venus-json

This library contains a L<Venus::Json> class which provides methods for reading
and writing JSON data.

=back

=over 4

=item venus-log

This library contains a L<Venus::Log> class which provides methods for logging
information using various log levels.

=back

=over 4

=item venus-map

This library contains a L<Venus::Map> class which provides a representation of
a collection of ordered key/value pairs.

=back

=over 4

=item venus-match

This library contains a L<Venus::Match> class which provides an object-oriented
interface for complex pattern matching operations on scalar values.

=back

=over 4

=item venus-meta

This library contains a L<Venus::Meta> class which provides configuration
information for L<Venus> derived classes.

=back

=over 4

=item venus-mixin

This library contains a L<Venus::Mixin> class which provides a mixin builder.

=back

=over 4

=item venus-name

This library contains a L<Venus::Name> class which provides methods for parsing
and formatting package namespaces.

=back

=over 4

=item venus-number

This library contains a L<Venus::Number> class which provides methods for
manipulating number data.

=back

=over 4

=item venus-opts

This library contains a L<Venus::Opts> class which provides methods for
handling command-line arguments.

=back

=over 4

=item venus-os

This library contains a L<Venus::Os> class which provides methods for
determining the current operating system, as well as finding and executing
files.

=back

=over 4

=item venus-path

This library contains a L<Venus::Path> class which provides methods for working
with file system paths.

=back

=over 4

=item venus-process

This library contains a L<Venus::Process> class which provides methods for
handling and forking processes.

=back

=over 4

=item venus-prototype

This library contains a L<Venus::Prototype> class which provides a simple
construct for enabling prototype-base programming.

=back

=over 4

=item venus-random

This library contains a L<Venus::Random> class which provides an
object-oriented interface for Perl's pseudo-random number generator.

=back

=over 4

=item venus-range

This library contains a L<Venus::Range> class which provides an object-oriented
interface for selecting elements from an arrayref using range expressions.

=back

=over 4

=item venus-regexp

This library contains a L<Venus::Regexp> class which provides methods for
manipulating regexp data.

=back

=over 4

=item venus-replace

This library contains a L<Venus::Replace> class which provides methods for
manipulating regexp replacement data.

=back

=over 4

=item venus-result

This library contains a L<Venus::Result> class which provides a container for
representing success and error states.

=back

=over 4

=item venus-run

This library contains a L<Venus::Run> class which provides a base class for
providing a command execution system for creating CLIs (command-line
interfaces).

=back

=over 4

=item venus-scalar

This library contains a L<Venus::Scalar> class which provides methods for
manipulating scalar data.

=back

=over 4

=item venus-schema

This library contains a L<Venus::Schema> class which provides a mechanism for
validating complex data structures.

=back

=over 4

=item venus-sealed

This library contains a L<Venus::Sealed> class which provides a mechanism for
restricting access to the underlying data structure.

=back

=over 4

=item venus-search

This library contains a L<Venus::Search> class which provides methods for
manipulating regexp search data.

=back

=over 4

=item venus-set

This library contains a L<Venus::Set> class which provides a representation of
a collection of ordered key/value pairs.

=back

=over 4

=item venus-space

This library contains a L<Venus::Space> class which provides methods for
parsing and manipulating package namespaces.

=back

=over 4

=item venus-string

This library contains a L<Venus::String> class which provides methods for
manipulating string data.

=back

=over 4

=item venus-task

This library contains a L<Venus::Task> class which provides a base class for
creating CLIs (command-line interfaces).

=back

=over 4

=item venus-template

This library contains a L<Venus::Template> class which provides a templating
system, and methods for rendering template.

=back

=over 4

=item venus-test

This library contains a L<Venus::Test> class which aims to provide a standard
for documenting L<Venus> derived software projects.

=back

=over 4

=item venus-text

This library contains a L<Venus::Text> class which provides methods for
extracting C<DATA> sections and POD block.

=back

=over 4

=item venus-text-pod

This library contains a L<Venus::Text::Pod> class which provides methods for
extracting POD blocks.

=back

=over 4

=item venus-text-tag

This library contains a L<Venus::Text::Tag> class which provides methods for
extracting C<DATA> sections.

=back

=over 4

=item venus-throw

This library contains a L<Venus::Throw> class which provides a mechanism for
generating and raising error objects.

=back

=over 4

=item venus-true

This library contains a L<Venus::True> class which provides the global C<true>
value.

=back

=over 4

=item venus-try

This library contains a L<Venus::Try> class which provides an object-oriented
interface for performing complex try/catch operations.

=back

=over 4

=item venus-type

This library contains a L<Venus::Type> class which provides a mechanism for
parsing, generating, and validating data type expressions.

=back

=over 4

=item venus-undef

This library contains a L<Venus::Undef> class which provides methods for
manipulating undef data.

=back

=over 4

=item venus-unpack

This library contains a L<Venus::Unpack> class which provides methods for
validating, coercing, and otherwise operating on lists of arguments.

=back

=over 4

=item venus-validate

This library contains a L<Venus::Validate> class which provides a mechanism for
performing data validation of simple and hierarchal data.

=back

=over 4

=item venus-vars

This library contains a L<Venus::Vars> class which provides methods for
accessing C<%ENV> items.

=back

=over 4

=item venus-what

This library contains a L<Venus::What> class which provides methods for casting
native data types to objects.

=back

=over 4

=item venus-yaml

This library contains a L<Venus::Yaml> class which provides methods for reading
and writing YAML data.

=back

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut