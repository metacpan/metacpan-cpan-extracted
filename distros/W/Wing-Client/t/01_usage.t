use Test::More;
use Test::Deep;

use lib 'lib';
use 5.010;
use Ouch;
use JSON;
use HTTP::Thin;

use_ok 'Wing::Client';

# process responses
my $wing = Wing::Client->new(uri=>'https://www.thegamecrafter.com');
my $result = $wing->_process_response(HTTP::Response->new(200, 'OK', ['Content-Type' => 'application/json'], '{"result":{"foo":"bar"}}'));
is $result->{foo}, 'bar', 'process_response()';

if (HTTP::Thin->new->get('http://www.apple.com')->content =~ m,<title>Apple</title>,) { # skip online tests if we have no online access

    # get
    my $result = eval{$wing->get('_test')};
    if ($@) {
        note "CODE: ".$@->code;
        note "MESSAGE: ".$@->code;
        note "DATA: ".to_json($@->data);
    }
    else {
        is $result->{method}, 'GET', 'get';
    }

    # error
    eval { $wing->get('/api/something/that/does/not/exist') };
    is $@->code, '404', 'error handling works';

    # put
    is $wing->put('_test', {foo => 'bar'})->{method}, 'PUT', 'put';

    # delete 
    is $wing->delete('_test', {foo => 'bar'})->{method}, 'DELETE', 'delete';

    # post & upload
    cmp_deeply 
        $wing->post('_test', { file => ['t/upload.txt']}, { upload => 1}),  
        {
              "params" => {
                 "file" => "upload.txt"
              },        
              "env" => ignore(),
              "uploads" => [
                 {
                    "filename" => "upload.txt",
                    "type" => "text/plain",
                    "size" => "13"
                 }
              ],
              "method" => "POST",
              "path" => "/api/_test",
              "tracer" => ignore(),
        },
        'post / upload';

    # post with multi 
    cmp_deeply 
        $wing->post('_test', { foo => [qw(a b c)]}),  
        {
              "params" => {
                 "foo" => ["a","b","c"], 
              },        
              "env" => ignore(),
              "method" => "POST",
              "path" => "/api/_test",
              "tracer" => ignore(),
        },
        'post with multi';
} # end skip online tests if we have no online access 
else {
    note "Skipping online tests, because we don't appear to have internet access.";
}


# really bad error
eval { $wing->_process_response(HTTP::Response->new(500, 'ERROR', ['Content-Type' => 'text/plain'], 'fubared')) };
isa_ok $@, 'Ouch';
is $@->code, 500, 'parsing error code works';
is $@->message, 'Server returned unparsable content.', 'parsing error message works';
is $@->data->{content}, 'fubared', 'parsing error data works';


done_testing();
