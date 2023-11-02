#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use Test::More;
use WWW::Suffit::RefUtil qw/:all/;

# Checks

ok is_ref([]), 'is_ref([])';
ok is_undef(undef), 'is_undef(undef)';
ok is_scalar_ref(\"foo"), 'is_scalar_ref(\"foo")';
ok is_array_ref([]), 'is_array_ref([])';
ok is_hash_ref({}), 'is_hash_ref({})';
ok is_code_ref(sub { 1 }), 'is_code_ref(sub { 1 })';
ok is_glob_ref( \*STDOUT ), 'is_glob_ref( \*STDOUT )';
ok is_regexp_ref(qr/\d/), 'is_regexp_ref(qr/\d/)';
ok is_regex_ref(qr/\d/), 'is_regex_ref(qr/\d/)';
ok is_rx(qr/\d/), 'is_rx(qr/\d/)';
ok is_value("foo"), 'is_value("foo")';
ok is_string("foo"), 'is_string("foo")';
ok is_number(-123), 'is_number(-123)';
ok is_integer(17), 'is_integer(17)';
ok is_int8(28), 'is_int8(28)';
ok is_int16(512), 'is_int16(512)';
ok is_int32(65537), 'is_int32(65537)';
ok is_int64(1234567890), 'is_int64(1234567890)';
ok(is_int8(0), 'Function is_int8(0)');

# True flags
ok(!is_false_flag("yes"), 'yes is true');
ok(is_true_flag("Y"), 'Y too');
ok(is_true_flag("YEP"), 'And YEP too');
ok(is_true_flag(1), 'And 1 too');

# False flags
ok(is_false_flag("Nope"), 'Nope is false');
ok(is_false_flag(0), 'And 0 too');
ok(is_false_flag("disabled"), 'And disabled too');

# Void
ok(is_void(undef),'undef - void value');
ok(is_void(\undef),'\\undef - void value');
ok(isnt_void(""),'null - void value');
ok(isnt_void("0"),'"0" - NOT void value');
ok(isnt_void(\"0"),'\\"0" - NOT void value');
ok(isnt_void(0),'0 - NOT void value');
ok(is_void([]),'[] - void value');
ok(isnt_void([0]),'[0] - NOT void value');
ok(is_void([undef]),'[undef] - void value');
ok(isnt_void([undef,0]),'[undef,0] - NOT void value');
ok(is_void([{}]),'[{}] - void value');
ok(isnt_void([{foo=>undef}]),'[{foo=>undef}] - NOT void value');
ok(isnt_void([[{foo=>undef}]]),'\\[{foo=>undef}] - NOT void value');
ok(is_void([[[[[]]]]]),'[[[[[]]]]] - void value');
ok(isnt_void([[[[[]],0]]]),'[[[[[]],0]]] - NOT void value');
ok(is_void([[[[[{}]]]]]),'[[[[[{}]]]]] - void value');
ok(isnt_void([[[[[{bar=>undef}]]]]]),'[[[[[{bar=>undef}]]]]] - NOT void value');
ok(isnt_void(qr/./),'qr/./ - NOT void value');
ok(isnt_void(sub {1}),'sub{1} - NOT void value');

done_testing;

1;

__END__
