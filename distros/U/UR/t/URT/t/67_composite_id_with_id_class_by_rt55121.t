use strict;
use warnings;
use Test::More tests => 4;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;

UR::Object::Type->define(
    class_name => 'Acme::Composited::Polygon',
    id_by => [
        qw/size color shape/
    ]
);

UR::Object::Type->define(
    class_name => 'Acme::Box',
    has_abstract_constant => [
        'subject_class_name'
    ],
    has => [
        subject => {
            is => 'UR::Object',
            id_class_by => 'subject_class_name', id_by => 'subject_id',
            doc => 'the object being boxed'
        }
    ]
);

my ($obj,$box);

$obj = Acme::Composited::Polygon->create(
    size => 'big',
    color => 'blue',
    shape => 'square'
);

ok($obj,'make the composited id object');

$box = Acme::Box->create(
    subject_class_name => 'Acme::Composited::Polygon'
);

ok($box,'make the container');
ok($box->subject($obj),'set subject on container');
ok($box->subject,'container still has subject');


