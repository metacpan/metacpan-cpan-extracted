# -*- perl -*-

require 5.004;


BEGIN { $| = 1; print "1..4\n"; }
END {print "Did not pass all tests" unless $loaded;}
use XML::CSV;

print "Loaded OK\n";
$loaded = 1;


eval{
my $obj = XML::CSV->new();
my $num = $obj->parse_doc("Data1.csv", {'headings' => 1});
$obj->print_xml("out1.xml");
};

if($@)
{
print "not ok 1: $@\n";
$loaded = 0;
undef($@);
} else {	
print "ok 1\n";
}




##########################################

eval{
$csv_obj = XML::CSV->new();
@arr_of_headings = ('one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'eleven');
$csv_obj->{column_headings} = \@arr_of_headings;
$csv_obj->parse_doc("Data1.csv");
$csv_obj->print_xml("out2.xml", {format => " ", file_tag => "file_data", record_tag => "record_data"});
};

if($@)
{
print "not ok 2: $@\n";
$loaded = 0;
undef($@);
} else {	
print "ok 2\n";
}




##########################################

eval{
$default_obj_xs = Text::CSV_XS->new({quote_char => '"'});
$csv_obj = XML::CSV->new({csv_xs => $default_obj_xs});
$csv_obj->{column_headings} = \@arr_of_headings;

$csv_obj->{column_data} = \@arr_of_data;

$csv_obj->print_xml("out3.xml");
};

if($@)
{
print "not ok 3: $@\n";
$loaded = 0;
undef($@);
} else {	
print "ok 3\n";
}


##########################################


eval{
my $obj = XML::CSV->new();
my $num = $obj->parse_doc("Data2.csv", {'headings' => 1, 'sub_char' => "_"});
$obj->declare_xml({version => '1.0', encoding => 'UTF-8', standalone => 'yes'});
$obj->declare_doctype({source => 'PUBLIC', location1 => '-//Netscape Communications//DTD RSS 0.90//EN', location2 => 'http://my.netscape.com/publish/formats/rss-0.91.dtd'});
$obj->print_xml("out4.xml");
};

if($@)
{
print "not ok 1: $@\n";
$loaded = 0;
undef($@);
} else {	
print "ok 4\n";
}
