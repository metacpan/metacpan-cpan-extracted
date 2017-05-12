use Test::More tests => 3;
use Test::Exception;

require_ok( 'WebService::SendInBlue' );

dies_ok { WebService::SendInBlue->new() } 'mandatory arguments';

isa_ok(WebService::SendInBlue->new('api_key'=>'x'), 'WebService::SendInBlue', 'Constructor with api key');
