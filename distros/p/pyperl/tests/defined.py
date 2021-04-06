#!/usr/bin/env python

import unittest
import perl

class TestPyPerlDefined(unittest.TestCase):

    def setUp(self):
        perl.eval(
                """sub foo;"""
                """sub bar { }"""
                """@baz = ();"""
                """$Foo::bar = 33;""")

    def test_defined(self):
        self.assertFalse(perl.defined("baz"))

        self.assertTrue(perl.defined("foo"))
        self.assertTrue(perl.defined("bar"))

        self.assertTrue(perl.defined("@baz"))

        self.assertTrue(perl.defined("$Foo::bar"))

        self.assertTrue(perl.defined("$Foo::bar"))

def test_main():
    from test import test_support
    test_support.run_unittest(TestPyPerlDefined)

if __name__ == "__main__":
    test_main()

# vim:ts=4:sw=4:et
