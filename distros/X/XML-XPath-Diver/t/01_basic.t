use strict;
use Test::More;
use XML::XPath::Diver;

my $xml = do { local $/; <DATA> };
my $diver = XML::XPath::Diver->new(xml => $xml);

isa_ok $diver, 'XML::XPath::Diver';
isa_ok $diver, 'XML::XPath';
can_ok $diver, qw/dive attr text to_string/;

subtest 'primitive array' => sub {
    my @foods = $diver->dive('//food/name');

    isa_ok($_, 'XML::XPath::Diver', 'Each item is a XML::XPath::Diver') for @foods;
    is(
        join(',', map {$_->text} @foods), 
        'Belgian Waffles,Strawberry Belgian Waffles,Berry-Berry Belgian Waffles,French Toast,Homestyle Breakfast',
        'create namelist'
    );
};

subtest 'first-class collection' => sub {
    my $foods = $diver->dive('//food');
    isa_ok $foods, 'Class::Builtin::Array';

    $foods->each(sub {
        my $node = shift;
        isa_ok $node, 'XML::XPath::Diver';
    });

    my $calories = $foods->map(sub{shift->dive('//calories')});
    my $calories_total = $calories->map(sub{shift->text})->reduce(sub{$a + $b});
    is $calories_total, 4000, 'total calories = 4000';

    my ($french_toast) = $diver->dive('//food[@id="202"]/name');
    my $expect = '<name>French Toast</name>';
    is $french_toast->to_string, $expect;

    my ($belgian_waffles) = $diver->dive('//food[@id="101"]');
    is $belgian_waffles->attr('id'), '101';
};

done_testing;

__DATA__
<?xml version="1.0" encoding="ISO-8859-1"?>
<!-- Edited by XMLSpy® -->
<breakfast_menu>
	<food id="101">
		<name>Belgian Waffles</name>
		<price>$5.95</price>
		<description>Two of our famous Belgian Waffles with plenty of real maple syrup</description>
		<calories>650</calories>
	</food>
	<food id="102">
		<name>Strawberry Belgian Waffles</name>
		<price>$7.95</price>
		<description>Light Belgian waffles covered with strawberries and whipped cream</description>
		<calories>900</calories>
	</food>
	<food id="201">
		<name>Berry-Berry Belgian Waffles</name>
		<price>$8.95</price>
		<description>Light Belgian waffles covered with an assortment of fresh berries and whipped cream</description>
		<calories>900</calories>
	</food>
	<food id="202">
		<name>French Toast</name>
		<price>$4.50</price>
		<description>Thick slices made from our homemade sourdough bread</description>
		<calories>600</calories>
	</food>
	<food id="203">
		<name>Homestyle Breakfast</name>
		<price>$6.95</price>
		<description>Two eggs, bacon or sausage, toast, and our ever-popular hash browns</description>
		<calories>950</calories>
	</food>
</breakfast_menu>

