#!perl

use File::Temp;
use IO::Scalar;
use MIME::Base64;
use Test::Exception;
use Test::More;
use Test::Warnings ':all';
use Weasel::Driver::Mock;


my $mock;

# Test what happens with no states
lives_ok {
    $mock = Weasel::Driver::Mock->new(states => []);
    $mock->start;
} 'states() setup and start() with empty array lives';
throws_ok {
    $mock->get('http://localhost/index');
} qr/States exhausted/, 'Executing unexpected steps is a hard failure';
$mock->stop;

# Test what happens with too many states

lives_ok {
    $mock = Weasel::Driver::Mock->new(states => [ { } ]);
    $mock->start;
}, 'Setup correctly completes';
like(warning {
    $mock->stop;
     }, qr/states left/, 'stop() correctly warns');

# Test each of the keys of a state

## cmd

lives_ok {
    $mock = Weasel::Driver::Mock->new(states => [ { cmd => 'get' } ]);
    $mock->start;
    $mock->get('http://localhost/');
    $mock->stop;
}, 'Matching "cmd" runs correctly';

throws_ok {
    $mock = Weasel::Driver::Mock->new(states => [ { cmd => 'find' } ]);
    $mock->start;
    $mock->get('http://localhost/');
    $mock->stop;
} qr/Mismatch between expected \(find\) and actual \(get\) driver command/,
    'Mismatching "cmd" throws correctly';

## args

lives_ok {
    $mock = Weasel::Driver::Mock->new(
        states => [ { cmd => 'get', args => [ 'http://localhost/' ] } ]);
    $mock->start;
    $mock->get('http://localhost/');
    $mock->stop;
}, 'Matching "args" runs correctly';

throws_ok {
    $mock = Weasel::Driver::Mock->new(
        states => [ { cmd => 'get', args => [ 'http://localhost/' ] } ]);
    $mock->start;
    $mock->get('http://localhost/index');
    $mock->stop;
} qr/Mismatch between expected and actual command arguments;/,
    'Mismatching "args" throws correctly';


## content

my $out_content = '';


### failing to provide content/content_base64/content_from_file fails
### when file output (get_page_source/screenshot) is required

throws_ok {
    $mock = Weasel::Driver::Mock->new(
        states => [ { cmd => 'get_page_source' } ]);
    $mock->start;
    $mock->get_page_source(IO::Scalar->new(\$out_content));
    $mock->stop;
} qr/Output handle provided, but one of .* missing/,
    'Missing content/content_base64/content_from_file correctly fails';

### failing to provide a file handle when
### content/content_base64/content_from_file provided

throws_ok {
    $mock = Weasel::Driver::Mock->new(
        states => [ { cmd => 'get_page_source',
                      content => 'hello world' } ]);
    $mock->start;
    $mock->get_page_source();
    $mock->stop;
} qr/Content provided for command get_page_source, but output handle missing/,
    'Missing file handle correctly fails';


### content success test

lives_and {
    $mock = Weasel::Driver::Mock->new(
        states => [ { cmd => 'get_page_source',
                      content => 'hello world' } ]);
    $mock->start;
    $out_content = '';
    $mock->get_page_source(IO::Scalar->new(\$out_content));
    $mock->stop;
    is $out_content, 'hello world', '"content" written and matches expectation';
}, 'Matching "content" runs correctly';


### content_base64 success test

lives_and {
    $mock = Weasel::Driver::Mock->new(
        states => [ { cmd => 'get_page_source',
                      content_base64 => MIME::Base64::encode('hello world') } ]);
    $mock->start;
    $out_content = '';
    $mock->get_page_source(IO::Scalar->new(\$out_content));
    $mock->stop;
    is $out_content, 'hello world', '"content_base64" written and matches expectation';
}, 'Matching "content_base64" runs correctly';


### content_from_file success test

my $tmp = File::Temp->new;
print ${tmp} 'hello world';
close ${tmp};

lives_and {
    $mock = Weasel::Driver::Mock->new(
        states => [ { cmd => 'get_page_source',
                      content_from_file => $tmp->filename } ]);
    $mock->start;
    $out_content = '';
    $mock->get_page_source(IO::Scalar->new(\$out_content));
    $mock->stop;

    is $out_content, 'hello world',
        '"content_from_file" written and matches expectation';
}, 'Matching "content_from_file" runs correctly';

## ret / ret_array

### ret

lives_and {
    my $exp_rv = { id => 'abc' };
    $mock = Weasel::Driver::Mock->new(
        states => [ { cmd => 'click',
                      args => [ '//div[@id="abc"]' ],
                      ret => $exp_rv,
                    } ]);
    $mock->start;
    my $rv = $mock->click('//div[@id="abc"]');
    $mock->stop;

    is_deeply $rv, $exp_rv,
        '"ret"-provided response matches expectation';
}, '"ret"-provided response runs correctly';


### ret_array

lives_and {
    my $exp_rv = [ { id => 'abc' },
                   { id => 'def' }, ];
    $mock = Weasel::Driver::Mock->new(
        states => [ { cmd => 'find_all',
                      args => [ '//div' ],
                      ret_array => $exp_rv,
                    } ]);
    $mock->start;
    my @rv = $mock->find_all('//div');
    $mock->stop;

    is_deeply \@rv, $exp_rv,
        '"ret_array"-provided response matches expectation';
}, '"ret_array"-provided response runs correctly';


## err

throws_ok {
    $mock = Weasel::Driver::Mock->new(
        states => [ { cmd => 'get',
                      err => 'URL cannot be loaded' } ]);
    $mock->start;
    $mock->get('http://localhost/');
    $mock->stop;
} qr/URL cannot be loaded/,
    '"err" correctly throws the error(text)';




done_testing;
