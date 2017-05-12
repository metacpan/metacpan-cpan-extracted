use Test;
BEGIN { plan tests => 26 };

### Load the module

use Text::TabFile;
ok(1); 

my $t = new Text::TabFile;
ok(defined $t);

### Open the file

ok($t->open('t/test.tab'));

### Check the header row

my @head = $t->fields;
ok(join(',',@head) eq 'col1,col2,col3');

### Read the first line

my $row = $t->read;
ok(ref $row);

### Check the first line contents

ok(join(',', map {$row->{$_}} @head) eq 'foo,bar,baz');

### Read from various columns and check

for my $word ( qw/foo bar baz/ ) {
  my @letters = split '', $word;

  for my $num ( 1 .. 3 ) {
    $row = $t->read;
    ok(ref $row);
    ok($row->{'col'.$num} eq shift @letters);
  }
}

### Check empty read

$row = $t->read;
ok(not ref $row);

### close the file

ok($t->close);
