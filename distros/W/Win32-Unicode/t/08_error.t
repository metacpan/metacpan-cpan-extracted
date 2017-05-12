use strict;
use warnings;
use Test::More;
use Test::Exception;

use Win32::Unicode;

ok Win32::Unicode::Error::error;
ok Win32::Unicode::Dir::error;
ok Win32::Unicode::File::error;
ok errorW;

subtest '_set_errno called' => sub {
    lives_ok { Win32::Unicode::Error::_set_errno() };
};

subtest 'set ERROR_FILE_EXISTS' => sub {
    Win32::Unicode::Error::_set_errno(Win32::Unicode::Constant::ERROR_FILE_EXISTS);
    is 0+$!, Errno::EEXIST();
};

done_testing;
