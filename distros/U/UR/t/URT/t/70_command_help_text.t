use warnings;
use strict;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use Test::More tests => 19;

BEGIN { $ENV{'ANSI_COLORS_DISABLED'} = 1 }

UR::Object::Type->define(
    class_name => 'Acme::ParentCommand',
    is => 'Command',
    has => [
        param_a => { is => 'String', is_optional => 1, doc => 'Some documentation for param a' },
        param_b => { is => 'String', is_optional => 0, example_values => ['1','2','3'] },
        param_c => { is => 'String', doc => 'Parent documentation for param c' },
    ],
);

UR::Object::Type->define(
    class_name => 'Acme::ChildCommand',
    is => 'Acme::ParentCommand',
    has => [
        param_a => { is => 'String', is_optional => 0 },
        param_c => { is => 'String', doc => 'Child documentation for param c' },
    ],
);

sub Acme::ParentCommand::execute { 1; }

sub Acme::ChildCommand::execute { 1; }

my $usage_string = '';
my $callback = sub {
    my $self = shift;
    $usage_string = shift;
    $usage_string =~ s/\x{1b}\[\dm//g;  # Remove ANSI escape sequences for color/underline
};

Acme::ParentCommand->dump_usage_messages(0);
Acme::ParentCommand->usage_messages_callback($callback);
Acme::ChildCommand->dump_usage_messages(0);
Acme::ChildCommand->usage_messages_callback($callback);

$usage_string = '';
$DB::single = 1;
my $rv = Acme::ParentCommand->_execute_with_shell_params_and_return_exit_code('--help');
is($rv, 0, 'Parent command executed');

my %usage = split_by_section($usage_string);
like($usage{'USAGE'}, qr(USAGE\s), 'USAGE has header');
like($usage{'USAGE'}, qr(\sacme parent-command\s), 'USAGE has command');
like($usage{'USAGE'}, qr(\s--param-b=\?\s), 'USAGE has --param-b as required');
like($usage{'USAGE'}, qr(\s--param-c=\?\s), 'USAGE has --param-c as required');
like($usage{'USAGE'}, qr(\s\[--param-a=\?\](\s|$)), 'USAGE has --param-a as optional');
like($usage{'REQUIRED ARGUMENTS'}, qr(\sparam-b\s+String), 'Parent help text lists param-b as required');
like($usage{'REQUIRED ARGUMENTS'}, qr(\sparam-c\s+String\s+Parent documentation for param c), 'Parent help text for param c');
like($usage{'OPTIONAL ARGUMENTS'}, qr(\sparam-a\s+String\s+Some documentation for param a), 'Parent help text lists param-a as optional');
unlike($usage{'REQUIRED ARGUMENTS'}, qr(\sparam-a\s+String), 'Parent help text does not list param-a as required');
unlike($usage{'OPTIONAL ARGUMENTS'}, qr(\sparam-b\s+String), 'Parent help text does not list param-b as optional');

$usage_string = '';
$rv = Acme::ChildCommand->_execute_with_shell_params_and_return_exit_code('--help');
is($rv, 0, 'Child command executed');
like($usage_string, qr(USAGE\s+acme child-command --param-a=\?\s+--param-b=\?\s+--param-c=\?), 'Child help text usage is correct');
like($usage_string, qr(param-a\s+String\s+Some documentation for param a), 'Child help text mentions param-a with parent documentation');
like($usage_string, qr(param-b\s+String), 'Child help text mentions param-b');
like($usage_string, qr(param-c\s+String\s+Child documentation for param c), 'Child help text mentions param-c with child documentation');
unlike($usage_string, qr(OPTIONAL ARGUMENTS\s+param-a\s+String), 'Child help text does not list param-a as optional');

my $meta = Acme::ParentCommand->__meta__;
my $p_meta_b = $meta->property('param_b');     
my $example_values_arrayref = $p_meta_b->example_values;
is("@$example_values_arrayref", "1 2 3", "example values are stored");
is(scalar(@$example_values_arrayref), 3, "example value count is as expected");

sub split_by_section {
    my $usage_string = shift;
    my @sections = ('USAGE', 'REQUIRED ARGUMENTS', 'OPTIONAL ARGUMENTS', 'DESCRIPTION');
    my $section = shift @sections;
    my $next_section = shift @sections;
    my %usage;
    for my $line (split("\n", $usage_string)) {
        if ($line =~ /$next_section/) {
            $section = $next_section;
            $next_section = shift @sections || 'END';
        }

        if ($usage{$section}) {
            $usage{$section} .= $line;
        } else {
            $usage{$section} = $line;
        }
    }
    return %usage;
}
