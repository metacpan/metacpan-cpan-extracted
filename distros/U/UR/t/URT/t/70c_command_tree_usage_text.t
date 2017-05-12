use warnings;
use strict;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use Test::More tests => 2;

use IO::File;

UR::Object::Type->define(
    class_name => 'URT::ParentCommand',
    is => 'Command::Tree',
);
{ no warnings 'once';
$URT::ParentCommand::SUB_COMMAND_MAPPING = {
    'command-a' => 'URT::CommandA',
    'command-b' => 'URT::CommandB',
};
}

UR::Object::Type->define(
    class_name => 'URT::CommandA',
    is => 'Command::V2',
    has => [
        param_a => { is => 'String', is_optional => 0 },
        param_c => { is => 'String', doc => 'Documentation for param c' },
    ],
    doc => 'This is command a',
);

UR::Object::Type->define(
    class_name => 'URT::CommandB',
    is => 'Command::V2',
    has => [
        param_a => { is => 'String', is_optional => 0 },
        param_b => { is => 'String', doc => 'Documentation for param b' },
    ],
    doc => 'This is command b',
);


my $buffer = '';
close STDERR;
my $stdout = open(STDERR,'>',\$buffer) || die "Can't redirect stdout to a string";

my $rv = URT::ParentCommand->_execute_with_shell_params_and_return_exit_code();

close STDERR;
open(STDERR, ">-") || die "Can't dup original stdout: $!";
STDERR->autoflush(1);

ok($rv, 'Parent command executes');

$buffer =~ s/\x{1b}.*?m//mg; # Remove ANSI escape sequences for color/underline

my $expected = q(Sub-commands for u-r-t parent-command:
 command-a    This is command a 
 command-b    This is command b 
ERROR: Please specify valid params for 'u-r-t parent-command'.
);
is($buffer, $expected, 'Output with no params was as expected');
