#!perl

use IO::Scalar;
use Test::More;

use Weasel::Driver::Mock;


my $mock;


# standard pattern
for my $fn (qw| get clear click dblclick execute_script get_attribute
            get_text is_displayed set_attribute get_selected set_selected
            send_keys tag_name set_window_size |) {
    $mock = Weasel::Driver::Mock->new(
        states => [ { cmd => $fn,
                      args => [ 'an arg' ],
                      ret => 'valid' } ]);

    $mock->start;
    is $mock->$fn('an arg'), 'valid',
        "mocked function $fn returns valid response";
    $mock->stop;
}


# with file handle
for my $fn (qw| screenshot get_page_source |) {
    $mock = Weasel::Driver::Mock->new(
        states => [ { cmd => $fn,
                      args => [],
                      content => 'valid' } ]);

    $mock->start;
    my $out_content = '';
    $mock->$fn(IO::Scalar->new(\$out_content));
    is $out_content, 'valid', "mocked function $fn returns valid response";
    $mock->stop;
}


# remaining

##TODO: set_wait_timeout wait_for find_all



# no need to test start() and stop(): they don't have 'mock effects'

done_testing;
