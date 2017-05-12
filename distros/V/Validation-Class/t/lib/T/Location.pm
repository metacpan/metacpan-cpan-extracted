package T::Location;

use Validation::Class;

field  'state'  => { state => 1 };
field  'string' => { mixin => ':str' };

document 'location' => {
    'id'       => 'string',
    'type'     => 'string',
    'name'     => 'string',
    'company'  => 'string',
    'address1' => 'string',
    'address2' => 'string',
    'city'     => 'string',
    'state'    => 'state',
    'zip'      => 'string'
};

1;
