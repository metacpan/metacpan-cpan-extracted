use strict;
use warnings;
use utf8;

use Test::More;

use XML::MyXML qw(:all);

my $obj = xml_to_object(<<'EOB');
<items>
    <item a="[]"    >a</item>
    <item a="{}"    >b</item>
    <item [a]="[]"  >c</item>
</items>
EOB

is $obj->path('item[a=\[\]]')->value,       'a', '[a=\[\]]';
is $obj->path('item[a=[\]]')->value,        'a', '[a=[\]]';
is $obj->path('item[a=\{\}]')->value,       'b', '[a=\{\}]';
is $obj->path('item[a={\}]')->value,        'b', '[a={\}]';
is $obj->path('item[a={}]')->value,         'b', '[a={}]';

is $obj->path('item[\[a\]=\[\]]')->value,   'c', '[\[a\]=\[\]]';
is $obj->path('item[[a\]=[\]]')->value,     'c', '[[a\]=[\]]';
is $obj->path('item[\[a\]]')->value,        'c', '[\[a\]]';
is $obj->path('item[[a\]]')->value,         'c', '[[a\]]';

done_testing;
