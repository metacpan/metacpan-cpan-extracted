#!/usr/bin/env perl

use Test::More tests => 1
	+do { eval { require Test::NoWarnings;Test::NoWarnings->import; 1 } || 0 };

use uni::perl ':dumper';
is(dumper({ тест => 'Проверка' }), qq|{\n  "тест" => "Проверка"\n}\n|, 'dumper converts utf-8');
