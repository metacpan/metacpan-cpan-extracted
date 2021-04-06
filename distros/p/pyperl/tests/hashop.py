#!/usr/bin/env python

import unittest
import perl

class TestPyPerlHashOp(unittest.TestCase):

    def setUp(self):
        self.h = perl.get_ref("%")

    def test_type_is_hash(self):
        self.assertEqual(self.h.__type__, 'HASH')
        self.assertEqual(self.h.__class__, None)

    def test_hash_elements(self):
        self.assertEqual(len(self.h), 0)
        self.assertEqual(len(list(self.h.items())), 0)
        self.assertEqual(len(list(self.h.keys())), 0)
        self.assertEqual(len(list(self.h.values())), 0)


    def test_hash_type_error(self):
        try:
            print((self.h[42]))
        except TypeError as v:
            self.assertEqual(str(v), 'perl hash key must be string')

    def test_hash_key_error(self):
        try:
            print((self.h["foo"]))
        except KeyError as v:
            self.assertEqual(str(v), "'foo'")

    def test_hash_get(self):
        self.h["foo"] = 42
        self.assertIsNotNone(self.h.get("foo"))
        self.assertEqual(self.h.get("foo"), 42)

    def test_hash_get_type_error(self):
        try:
            print((self.h.get(42)))
        except TypeError as v:
            self.assertEqual(str(v), "a bytes-like object is required, not 'int'")

    def test_hash_key_index(self):
        self.h["foo"] = 42
        self.assertEqual(len(self.h), 1)
        self.assertEqual(self.h["foo"], 42)

    def test_hash_algoritm_order(self):
        self.skipTest("Order doesn't to predictable...")
        self.h["foo"] = 42
        self.h["bar"] = 21

        # self.here we assume a certain order, which might get broken by another self.hash
        # algoritim or other internal changes.  In that case fix the tests below.
        self.assertEqual(list(self.h.keys()), ["bar", "foo"])
        self.assertEqual(list(self.h.values()), [21, 42])
        self.assertEqual(list(self.h.items()), [("bar", 21), ("foo", 42)])

    def test_hash_has_key(self):
        self.h["bar"] = 21

        self.assertFalse("baz" in self.h)
        self.assertTrue("bar" in self.h)

    def test_hash_copy(self):
        self.h2 = self.h.copy()
        self.assertNotEqual(id(self.h), id(self.h2))
        self.assertEqual(list(self.h.items()), list(self.h2.items()))

    def test_hash_clear(self):
        self.h2 = self.h.copy()
        self.h2.clear()
        self.assertEqual(len(self.h2), 0)

    def test_hash_delete(self):
        self.h["foo"] = 42
        self.h["bar"] = 21
        del self.h["bar"]
        self.assertEqual(list(self.h.keys()), ["foo"])

def test_main():
    from test import test_support
    test_support.run_unittest(TestPyPerlHashOp)

if __name__ == "__main__":
    test_main()
