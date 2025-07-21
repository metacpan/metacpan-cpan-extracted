use Test2::V0;
use Test2::Require::Module 'PDL::IO::CSV';
use Test2::Require::Module 'Text::CSV';

use WebService::OurWorldInData::Chart;

pass('PDL installed');

todo 'not implemented yet' => sub {
    # write csv file to disk
    ok(0, "read file");
    # test pdl object contains csv data
};

=pod from the docs

use PDL::IO::CSV ':all'

pdl> $cars = rcsv2D('mtcars_001.csv')

seems to read from file or filehandle
do we just let the users do this
create a temp file and hand them a "Table"?

=cut

done_testing;
