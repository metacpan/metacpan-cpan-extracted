#!/usr/bin/perl

use strict;
use warnings;
use WWW::eiNetwork;
use Test::More tests => 2;

my $holds_html = qq(
    <table border width="100%" class="patFunc"><tr class="patFuncTitle">
    <td align="center" colspan="5" class="patFuncTitle">
    <strong>HOLDS</strong>
    </td>
    </tr>
	<tr class="patFuncHeaders">
	<th class="patFuncHeaders"> CANCEL </th>
	<th class="patFuncHeaders"> TITLE </th>
	<th class="patFuncHeaders"> STATUS </th>
	<th class="patFuncHeaders">PICKUP LOCATION</th>
	<th class="patFuncHeaders"> CANCEL IF NOT FILLED BY </th>
	</tr>
	<tr class="patFuncEntry">
	<td  class="patFuncMark" align="center">
	<input type="checkbox" name="cancel55555" /></td>
	<td  class="patFuncTitle">
	<a href="/patroninfo/9999999/item&55555">
	a book titled selected</a>
	<br />
	</td>
	<td  class="patFuncStatus"> 7 of 40 holds </td>
	<td class="patFuncPickup"><select name=loc44444>
	<option value="aa+++" >Library A</option>
	<option value="aa+++" selected="selected">Library B
	</option>
	<option value="aa+++" >Library C</option>
	</select>
	</td>
	<td class="patFuncCancel">12-10-08</td>
	</tr>
	<tr class="patFuncEntry">
	<td  class="patFuncMark" align="center">
	<input type="checkbox" name="canceli44444" /></td>
	<td  class="patFuncTitle">
	<a href="/patroninfo/9999999/item&44444"> Test Item B; ABC </a>
	<br />
	</td>
	<td  class="patFuncStatus"> IN TRANSIT </td>
	<td class="patFuncPickup"><select name=loci44444>
	<option value="aa+++" selected="selected">Test Library Y</option>
	<option value="aa+++" >Test Library Z</option>
	</select>
	</td>
	<td class="patFuncCancel">12-10-08</td>
	</tr>
	</table>
	</form>
);

my $expected_holds =
[
	{
		pickup => 'Library B',
		status => '7 of 40 holds',
		cancel => '12-10-08',
		title  => 'a book titled selected',
	},
	{
		pickup => 'Test Library Y',
		status => 'IN TRANSIT',
		cancel => '12-10-08',
		title  => 'Test Item B; ABC',
	},
];

my $items_html = qq(
	</nobr>
	<table border width="100%" class="patFunc">
	<tr class="patFuncTitle">
	<td colspan="5" align="center" class="patFuncTitle">
	<strong>2 ITEMS CHECKED OUT</strong></td>
	</tr>
	<tr class="patFuncHeaders">
	<th class="patFuncHeaders"> RENEW </th><th class="patFuncHeaders"> TITLE </th>
	<th  class="patFuncHeaders"> BARCODE </th><th class="patFuncHeaders"> STATUS </th>
	<th  class="patFuncHeaders"> CALL NUMBER </th>
	<tr class="patFuncEntry"><td align="left" class="patFuncMark">
	<input type="checkbox" name="renew0" value="i53535353" /></td>
	<td align="left" class="patFuncTitle"><a href="/patroninfo/444444/item&43434343">Test Book A</a>
	<br />
	</td>
	<td align="left" class="patFuncBarcode"> 12345678901 </td>
	<td align="left" class="patFuncStatus"> DUE 01-01-08 
	</td>
	<td align="left" class="patFuncCallNo"> 100.0 ABC  </td>
	</tr>
	<tr class="patFuncEntry"><td align="left" class="patFuncMark"><input type="checkbox" name="renew1" value="i43434343" /></td>
	<td align="left" class="patFuncTitle"><a href="/patroninfo/444444/item&4343434"> Another Test Item  </a>
	<br />
	</td>
	<td align="left" class="patFuncBarcode"> 0987654321 </td>
	<td align="left" class="patFuncStatus"> DUE 02-01-09
	</td>
	<td align="left" class="patFuncCallNo"> ABC E </td>
	</tr>
	</table>
	</form></dl><br />
	<link href="/screens/main.css" rel="stylesheet" type="text/css">
);

my $expected_items = 
[
	{
		status  => 'DUE 01-01-08',
		barcode => '12345678901',
		title   => 'Test Book A',
		callno  => '100.0 ABC',
	},
	{
		status  => 'DUE 02-01-09',
		barcode => '0987654321',
		title   => 'Another Test Item',
		callno  => 'ABC E',
	}
];

my $ein = WWW::eiNetwork->new(
    card_number => '1234567890',
    pin_number  => '1234',
);

my @holds = $ein->holds(html => $holds_html);
my @items = $ein->items(html => $items_html);

is_deeply(\@holds, $expected_holds, 'parsed holds data successfully');
is_deeply(\@items, $expected_items, 'parsed items data successfully');
