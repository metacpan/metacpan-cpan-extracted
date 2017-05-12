package T::User;

use Validation::Class;

field  'string' => { mixin => ':str' };

document 'user' => {
    'id'          => 'string',
    'type'        => 'string',
    'name'        => 'string',
    'company'     => 'string',
    'login'       => 'string',
    'email'       => 'string',
    'locations.@' => 'location'
};

1;
