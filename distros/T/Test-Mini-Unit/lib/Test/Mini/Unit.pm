# Declarative Sugar for Test::Mini.
#
# Test::Mini::Unit aims to provide a simpler, boilerplate-free environment for
# writing new {Test::Mini} test cases.  While Test::Mini itself is a fairly
# reasonable environment with very little overhead verbosity, the overhead of
# creating a new class -- or set of classes -- in Perl can still be a bit more
# distracting than you'd really like.
#
# = Enter Test::Mini::Unit
#
# At first glance, Test::Mini::Unit provides moderate improvements over the
# traditional style, transforming this:
#
#   package t::Test
#   use base 'Test::Mini::TestCase';
#   use strict;
#   use warnings;
#
#   use Test::Mini::Assertions;
#
#   sub setup {
#       # do something
#   }
#
#   sub test_some_code {
#       assert($something_true);
#   }
#
#   sub teardown {
#       # undo something
#   }
#
#   1;
#
# Into this:
#
#   use Test::Mini::Unit;
#
#   case t::Test {
#       setup {
#           # do something
#       }
#
#       test some_code {
#           assert($something_true);
#       }
#
#       teardown {
#           # undo something
#       }
#   }
#
# = Advice
#
# But Test::Mini::Unit really begins to shine as your test cases take on more
# complexity.  Multiple calls to the test advice methods (+setup+ and
# +teardown+) will stack like +BEGIN+ and +END+ blocks, allowing you to
# co-locate tests and relevant advice.
#
#   # Traditional
#   sub setup {
#       # do a bunch of setup for test_one
#       # ...
#       # do a bunch of setup for test_two
#       # ...
#   }
#
#   sub test_one { ... }
#   sub test_two { ... }
#
#   # Test::Mini::Unit
#   setup { "do setup for test_one" }
#   sub test_one { ... }
#
#   setup { "do setup for test_two" }
#   sub test_two { ... }
#
# = Test-Local Storage
#
# Per-test local storage is automatically available as +$self+ from all advice
# and test blocks.
#
#    setup { $self->{data} = Package->new() }
#    test data { assert_isa($self->{data}, 'Package') }
#
#    teardown { unlink $self->{tmpfile} }
#
# = Nesting
#
# And perhaps most usefully, test cases can be *nested*.  Nested test cases
# inherit all their outer scope's test advice, allowing you to build richer
# tests with far less code.
#
#   case t::IO::Scalar {
#       setup { $self->{buffer} = IO::Scalar->new() }
#       test can_read  { assert_can($self->{buffer}, 'read')  }
#       test can_write { assert_can($self->{buffer}, 'write') }
#       test is_empty  { assert_empty("@{[$self->{buffer}]}") }
#
#       case AfterWritingString {
#           setup { $self->{buffer}->print('String!') }
#           test contents {
#               assert_equal("@{[$self->{buffer}]}", 'String!');
#           }
#       }
#
#       case AfterWritingObject {
#           setup { $self->{buffer}->print($self) }
#           test contents {
#               assert_equal("@{[$self->{buffer}]}", "$self");
#           }
#       }
#   }
#
# = Sharing Tests...
#
# In some cases, you may find it useful to reuse the same tests in different
# cases.  For this purpose, the +shared+ and +reuse+ keywords exist:
#
#   shared BasicBookTests {
#       test has_pages { ... }
#       test pages_have_text { ... }
#   }
#
#   case Book {
#       reuse BasicBookTests;
#   }
#
#   case LargePrintBook {
#       reuse BasicBookTests;
#       test words_should_be_big { ... }
#   }
#
# = ... And Reusing Them
#
# Groups of shared tests may also be nested inside +case+ blocks, where
# they will inherit the namespace of their parent.  Since shared tests will
# most commonly see reuse inside either the +case+ they're declared in or a
# nested case, it's not usually necessary to specify the full package name.
# The +reuse+ keyword will try, therefore, to infer the fully qualified
# package name from the name it's given.  (You can always specify the full name
# yourself by prepending '::'.)
#
#   shared CommonTests {
#       # __PACKAGE__ is 'Nested::CommonTests'
#   }
#
#   case Nested {
#       shared CommonTests {
#           # __PACKAGE__ is 'Nested::CommonTests'
#       }
#
#       case Deeply {
#           shared CommonTests {
#               # __PACKAGE__ is 'Nested::Deeply::CommonTests'
#           }
#
#           # includes Nested::Deeply::CommonTests
#           reuse CommonTests;
#
#           # includes Nested::CommonTests
#           reuse Nested::CommonTests;
#
#           # includes CommonTests
#           reuse ::CommonTests;
#       }
#
#       # includes Nested::CommonTests
#       reuse CommonTests;
#   }
#
# = Automatic 'use'
#
# To automatically use packages inside all your test cases (for example, your
# own custom assertions), simply pass the 'with' option to Test::Mini::Unit;
# it can accept either a single package name or an array.
#
#   use Test::Mini::Unit (with => [ My::Assertions, My::HelperFuncs ]);
#
#   case t::TestCase {
#       # My::Assertions and My::HelperFuncs are already imported here.
#       case Nested {
#           # In here, too.
#       }
#
#       shared CommonTests {
#           # Yup, here too.
#       }
#   }
#
# @see Test::Mini
# @author Pieter van de Bruggen <pvande@cpan.org>
package Test::Mini::Unit;
use strict;
use warnings;
use 5.008;

use version 0.77; our $VERSION = qv("v1.0.3");

use Test::Mini;

require Test::Mini::Unit::Sugar::Shared;
require Test::Mini::Unit::Sugar::TestCase;

# @api private
sub import {
    my ($class, @args) = @_;
    my $caller = caller();

    strict->import;
    warnings->import;

    Test::Mini::Unit::Sugar::Shared->import(into => $caller, @args);
    Test::Mini::Unit::Sugar::TestCase->import(into => $caller, @args);
}

1;
