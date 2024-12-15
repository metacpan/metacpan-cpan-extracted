use Test2::V0;
use Test2::Require::Module 'Poz', '0.02';

use FindBin qw($Bin);
use lib "$Bin";

use TestPoz qw(Book);

subtest 'Test `kura` with Poz' => sub {
    isa_ok Book, 'Poz::Types::object';

    my $book = Book->parse({
        title     => "Spidering Hacks",
        author    => "Kevin Hemenway",
        published => "2003-10-01",
    });

    ok $book->isa('My::Book');
};

done_testing;
