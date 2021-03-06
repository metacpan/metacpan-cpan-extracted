use strict;
use Test::More;
use Test::Deep;
use Test::Harness;
use Win32::ExcelSimple;
use File::Basename;
use File::Spec::Functions;

my $path = dirname(__FILE__);
   $path = Win32::GetFullPathName($path);
my $abs_file = catfile($path, 'test.xlsx');

SKIP: {
	  eval{ Win32::ExcelSimple->new($abs_file); };
	  skip "install excel first!!!", 2 if $@;
my $es = Win32::ExcelSimple->new($abs_file);
my $sheet_h = $es->open_sheet('Report');
   $sheet_h->write_cell(2,1, 'test');
is($sheet_h->read_cell(2,1),  'test', "write string test to cell B1");
$sheet_h->write_row(2,1, ['test','test1', 'test2', 'test3']);
is_deeply($sheet_h->read(2,1, 5, 1),  ['test','test1', 'test2', 'test3'], "write row to from B1");
$sheet_h->write_row(2,1,'');
is($sheet_h->read_cell(2,1), undef, "write a NULL to cell B1");
$sheet_h->write_col(2,1,['aaa','bbb','ccc']);
my $read = $sheet_h->read(2,1,2,3);
is_deeply($read,  ['aaa','bbb', 'ccc'], "write  col from  cell B1");
$sheet_h->write_col(10,1,[['aaa','115505.2'],['bbb',222],['ccc',333]]);
   $read = $sheet_h->read(10,1, 11,3);
cmp_deeply($read,  [['aaa','115505.2'],['bbb',222],['ccc',333]], "write  col from  cell B1");

   $sheet_h->write(2,1, ['test1','test2','test3']);
is_deeply($sheet_h->read(2,1,4,1),  ['test1','test2','test3'], "write data to a Range");
   $sheet_h->write(2,1, [
		                ['test1','test2','test3'],
						['chop1','chop2','chop3'],
						['deer1','deer2','deer3'],
					    ]
					);
cmp_deeply($sheet_h->read(2,1,4,3), [
		                ['test1','test2','test3'],
						['chop1','chop2','chop3'],
						['deer1','deer2','deer3'],
					    ],
					    "write data to a multi-dimension Range");
			    }	    
done_testing;

