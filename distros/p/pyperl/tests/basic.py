#!/usr/bin/env python

import unittest
import perl

class TestPyPerlBasic(unittest.TestCase):

    def setUp(self):

        perl.eval("""
sub foo2 {
    wantarray ? (1, 2, 3) : 42;
}
""")

    def test_simple_calculator(self):
        # try to use perl as a simple calculator
        self.assertEqual(perl.eval("3+3"), 6)

    def test_pass_strings_back(self):
        # can we pass strings back
        self.assertEqual(perl.eval("substr('abcd', 0, 3)"), "abc")

    def test_pass_hashes_both_ways(self):
        # can we pass hashes both ways
        if perl.MULTI_PERL:
            self.skipTest("not on MULTI_PERL...")
        else:
            perl.eval("sub foo_elem { shift->{foo} }")
            hash = perl.eval("{ foo => 42 }")
            self.assertEqual(perl.call("foo_elem", hash), 42)

    def test_trap_exceptions(self):
        # try to trap exceptions
        try:
            perl.eval("die 'Oops!'")
        except perl.PerlError as val:
            self.assertEqual(str(val)[:5],"Oops!")

        try:
            perl.call("not_there", 3, 4)
        except perl.PerlError as val:
            self.assertEqual(str(val), "Undefined subroutine &main::not_there called.\n")


    def test_function_scalar_context(self):
        # scalar context
        self.assertEqual(perl.call("foo2"), 42)

    def test_function_array_context_tuple_back(self):
        res = perl.call_tuple("foo2")
        self.assertEqual(len(res), 3)
        self.assertEqual(res[0], 1)
        self.assertEqual(res[1], 2)
        self.assertEqual(res[2], 3)

    def test_anonymous_perl_functions(self):
        # can we call anonymous perl functions
        # can we pass hashes both ways
        if perl.MULTI_PERL:
            self.skipTest("not on MULTI_PERL...")
        else:
            func = perl.eval("sub { $_[0] + $_[1] }")
            self.assertEqual(int(func(3, 4)), 7)

def test_main():
    from test import test_support
    test_support.run_unittest(TestPyPerlBasic)

if __name__ == "__main__":
    test_main()
