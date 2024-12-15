package TestDataValidator;

use Exporter 'import';
use Data::Validator;

use kura Book => Data::Validator->new(
    title  => 'Str',
    author => 'Str',
);

1;
