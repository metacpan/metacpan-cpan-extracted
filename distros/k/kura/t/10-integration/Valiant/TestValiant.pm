package TestValiant;

use Exporter 'import';
use Types::Standard qw(InstanceOf);
use kura ValidLocalPerson => InstanceOf['LocalPerson'] & sub { $_->valid };

1;
