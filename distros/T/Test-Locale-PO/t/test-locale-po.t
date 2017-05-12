#!/usr/bin/env perl

use Test::Builder::Tester tests => 5;
use Test::Locale::PO;

test_out('ok 1 - PO file t/po/de.po is okay');
po_file_ok('t/po/de.po');
test_test("de.po file is ok");

test_out('not ok 1 - check PO file t/po/fr.po for errors');
test_err("#   Failed test 'check PO file t/po/fr.po for errors'
#   at t/test-locale-po.t line 14.
# no translation for \"empty\" on line 13");
po_file_ok('t/po/fr.po');
test_test("fr.po must throw error");

test_out('ok 1 - PO file t/po/fr.po is okay');
po_file_ok('t/po/fr.po', empty => 0);
test_test("fr.po is okay with empty => 0");

test_out('not ok 1 - check PO file t/po/it.po for errors');
test_err("#   Failed test 'check PO file t/po/it.po for errors'
#   at t/test-locale-po.t line 25.
# fuzzy translation for \"fuzzy\" on line 16");
po_file_ok('t/po/it.po');
test_test("fr.po must fail with fuzzy translations");

test_out('ok 1 - PO file t/po/it.po is okay');
po_file_ok('t/po/it.po', fuzzy => 0);
test_test("it.po file is ok with fuzzy => 0");

