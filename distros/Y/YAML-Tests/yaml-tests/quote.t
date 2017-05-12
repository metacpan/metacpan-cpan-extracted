use t::TestYAMLTests tests => 3;

is Dump('', [''], {foo => ''}), <<'...', 'Dumped empty string is quoted';
--- ''
---
- ''
---
foo: ''
...

is Dump({}, [{}], {foo => {}}), <<'...', 'Dumped empty map is {}';
--- {}
---
- {}
---
foo: {}
...

is Dump([], [[]], {foo => []}), <<'...', 'Dumped empty seq is []';
--- []
---
- []
---
foo: []
...
