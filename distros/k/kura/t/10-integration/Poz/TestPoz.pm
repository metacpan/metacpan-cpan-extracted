package TestPoz;

use Exporter 'import';
use Poz qw(z);

use kura Title  => z->string->min(1)->max(255);
use kura Author => z->string->default("Anonymous");
use kura Published => z->date;

use kura Book => z->object({
    title      => Title,
    author     => Author,
    published  => Published,
})->as("My::Book");

1;
