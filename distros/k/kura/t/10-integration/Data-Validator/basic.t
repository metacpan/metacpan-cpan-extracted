use Test2::V0;
use Test2::Require::Module 'Data::Validator', '1.07';

use FindBin qw($Bin);
use lib "$Bin";

use TestDataValidator qw(Book);

subtest 'Test `kura` with Data::Validator' => sub {
    isa_ok Book, 'Data::Validator';

    my $data = { title => "Spidering Hacks", author => "Kevin Hemenway" };

    my $got = Book->validate($data);
    is $got, $data;

    ok dies {
        Book->validate({
            isbn => "978-0-596-00797-3",
        });
    };
};

done_testing;
