# See Also

* https://metacpan.org/module/Text::ASCIITable (Nov 29, 2011)

```perl
use Text::ASCIITable;
$t = Text::ASCIITable->new({ headingText => 'Basket' });
 
$t->setCols('Id','Name','Price');
$t->addRow(1,'Dummy product 1',24.4);
$t->addRow(2,'Dummy product 2',21.2);
$t->addRow(3,'Dummy product 3',12.3);
$t->addRowLine();
$t->addRow('','Total',57.9);
print $t;
```
```
.------------------------------.
|            Basket            |
+----+-----------------+-------+
| Id | Name            | Price |
+----+-----------------+-------+
|  1 | Dummy product 1 |  24.4 |
|  2 | Dummy product 2 |  21.2 |
|  3 | Dummy product 3 |  12.3 |
+----+-----------------+-------+
|    | Total           |  57.9 |
'----+-----------------+-------'
```

* https://metacpan.org/module/Text::Table (Sep 02, 2011)

```perl
my @col_titles = ( "Radius\nkm", "Density\ng/cm^3" );
my $tb = Text::Table->new(
   {  is_sep => 1,
      title  => '| ',
      body   => '| ', },
   {  title       => 'Planet',
      align_title => 'center', },
   (  map {
         (  {  is_sep => 1,
               title  => ' | ',
               body   => ' | ', },
            {  title       => $_,
               align_title => 'center', }, )
         } @col_titles ),
   {  is_sep => 1,
      title  => ' |',
      body   => ' |', }, );

$tb->load(
   [ "Mercury", 2360,  3.7 ],
   [ "Venus",   6110,  5.1 ],
   [ "Earth",   6378,  5.52 ],
   [ "Jupiter", 71030, 1.3 ], );

my $o = '';
$o .= $tb->rule( q{-}, q{+} );
$o .= $tb->title();
$o .= $tb->rule( q{-}, q{+} );
$o .= $tb->body();
$o .= $tb->rule( q{-}, q{+} );
```
```
+---------+--------+---------+
| Planet  | Radius | Density |
|         |   km   | g/cm^3  |
+---------+--------+---------+
| Mercury |   2360 |  3.7    |
| Venus   |   6110 |  5.1    |
| Earth   |   6378 |  5.52   |
| Jupiter |  71030 |  1.3    |
+---------+--------+---------+
```

* https://metacpan.org/module/Text::TabularDisplay (Mar 30, 2012)

```perl
my $t = Text::TabularDisplay->new(qw(id name phone));
$t->add(1, "Tom Jones", "(666) 555-1212");
$t->add(2, "Barnaby Jones", "(666) 555-1213");
$t->add(3, "Bridget Jones", "(666) 555-1214");
print $t->render;
````
````
+----+---------------+----------------+
| id | name          | phone          |
+----+---------------+----------------+
| 1  | Tom Jones     | (666) 555-1212 |
| 2  | Barnaby Jones | (666) 555-1213 |
| 3  | Bridget Jones | (666) 555-1214 |
+----+---------------+----------------+
```

* https://metacpan.org/module/Text::Table::Tiny (Jan 24, 2012)

```perl
my $rows = [
	# header row
	['Name', 'Rank', 'Serial'],
	# rows
	['alice', 'pvt', '123456'],
	['bob',   'cpl', '98765321'],
	['carol', 'brig gen', '8745'],
];
# separate rows puts lines between rows, header_row says that the first row is headers
print Text::Table::Tiny::table(rows => $rows, separate_rows => 1, header_row => 1);
```
```
Example in the synopsis: Text::Table::Tiny::table(rows => $rows);
 
  +-------+----------+----------+
  | Name  | Rank     | Serial   |
  | alice | pvt      | 123456   |
  | bob   | cpl      | 98765321 |
  | carol | brig gen | 8745     |
  +-------+----------+----------+
 
with header_row: Text::Table::Tiny::table(rows => $rows, header_row => 1);
 
  +-------+----------+----------+
  | Name  | Rank     | Serial   |
  +-------+----------+----------+
  | alice | pvt      | 123456   |
  | bob   | cpl      | 98765321 |
  | carol | brig gen | 8745     |
  +-------+----------+----------+
 
with header_row and separate_rows: Text::Table::Tiny::table(rows => $rows, header_row => 1, separate_rows => 1);
 
  +-------+----------+----------+
  | Name  | Rank     | Serial   |
  O=======O==========O==========O
  | alice | pvt      | 123456   |
  +-------+----------+----------+
  | bob   | cpl      | 98765321 |
  +-------+----------+----------+
  | carol | brig gen | 8745     |
  +-------+----------+----------+
```

* https://metacpan.org/module/Text::SimpleTable (Mar 11, 2010)

```perl
my $t1 = Text::SimpleTable->new(5, 10);
$t1->row('foobarbaz', 'yadayadayada');
print $t1->draw;
 
my $t2 = Text::SimpleTable->new([5, 'Foo'], [10, 'Bar']);
$t2->row('foobarbaz', 'yadayadayada');
$t2->row('barbarbarbarbar', 'yada');
print $t2->draw;

my $t3 = Text::SimpleTable->new([5, 'Foo'], [10, 'Bar']);
$t3->row('foobarbaz', 'yadayadayada');
$t3->hr;
$t3->row('barbarbarbarbar', 'yada');
print $t3->draw;
```
```
.-------+------------.
| foob- | yadayaday- |
| arbaz | ada        |
'-------+------------'
 
.-------+------------.
| Foo   | Bar        |
+-------+------------+
| foob- | yadayaday- |
| arbaz | ada        |
| barb- | yada       |
| arba- |            |
| rbar- |            |
| bar   |            |
'-------+------------'
 
.-------+------------.
| Foo   | Bar        |
+-------+------------+
| foob- | yadayaday- |
| arbaz | ada        |
+-------+------------+
| barb- | yada       |
| arba- |            |
| rbar- |            |
| bar   |            |
'-------+------------'
```

* https://metacpan.org/module/Text::FormatTable (Jul 24, 2009)

```perl
my $table = Text::FormatTable->new('r|l');
$table->head('a', 'b');
$table->rule('=');
$table->row('c', 'd');
print $table->render(20);
```
```
a|b
===
c|d
```

* https://metacpan.org/module/Text::SpanningTable (Oct 17, 2010)

```perl
# create a table object with four columns of varying widths
my $t = Text::SpanningTable->new(10, 20, 15, 25);
 
# enable auto-newline adding
$t->newlines(1);
 
# print a top border
print $t->hr('top');
 
# print a row (with header information)
print $t->row('Column 1', 'Column 2', 'Column 3', 'Column 4');
 
# print a double horizontal rule
print $t->dhr; # also $t->hr('dhr');
 
# print a row of data
print $t->row('one', 'two', 'three', 'four');
 
print $t->hr;
 
# print another row, with one column that spans all four columns
print $t->row([4, 'Creedance Clearwater Revival']);
 
print $t->hr;
 
# print a row with the first column normally and another column
# spanning the remaining three columns
print $t->row(
        'normal column',
        [3, 'this column spans three columns and also wraps to the next line.']
);
 
# finally, print the bottom border
print $t->hr('bottom');
```
``` 
.----------+------------------+-------------+-----------------------.
| Column 1 | Column 2         | Column 3    | Column 4              |
+==========+==================+=============+=======================+
| one      | two              | three       | four                  |
+----------+------------------+-------------+-----------------------+
| Creedance Clearwater Revival                                      |
+----------+------------------+-------------+-----------------------+
| normal   | this column spans three columns and also wraps to the  |
|          | next line.                                             |
'----------+------------------+-------------+-----------------------'
```

* https://metacpan.org/module/Text::UnicodeTable::Simple (Dec 30, 2011)

```perl
$t = Text::UnicodeTable::Simple->new();
 
$t->set_header(qw/Subject Score/);
$t->add_row('English',     '78');
$t->add_row('Mathematics', '91');
$t->add_row('Chemistry',   '64');
$t->add_row('Physics',     '95');
$t->add_row_line();
$t->add_row('Total', '328');
 
print "$t";
```
```
.-------------+-------.
| Subject     | Score |
+-------------+-------+
| English     |    78 |
| Mathematics |    91 |
| Chemistry   |    64 |
| Physics     |    95 |
+-------------+-------+
| Total       |   328 |
'-------------+-------'
```
