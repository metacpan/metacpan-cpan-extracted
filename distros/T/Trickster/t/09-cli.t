use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(getcwd);

use_ok('Trickster::CLI');

# Test CLI object creation
{
    my $cli = Trickster::CLI->new;
    ok($cli, 'CLI object created');
    isa_ok($cli, 'Trickster::CLI');
}

# Test version command
{
    my $cli = Trickster::CLI->new;
    ok($cli->can('cmd_version'), 'version command exists');
}

# Test help command
{
    my $cli = Trickster::CLI->new;
    ok($cli->can('cmd_help'), 'help command exists');
    ok($cli->can('show_help'), 'show_help method exists');
}

# Test generate command
{
    my $cli = Trickster::CLI->new;
    ok($cli->can('cmd_generate'), 'generate command exists');
    ok($cli->can('generate_controller'), 'generate_controller exists');
    ok($cli->can('generate_model'), 'generate_model exists');
    ok($cli->can('generate_template'), 'generate_template exists');
}

# Test new command
{
    my $cli = Trickster::CLI->new;
    ok($cli->can('cmd_new'), 'new command exists');
}

# Test server command
{
    my $cli = Trickster::CLI->new;
    ok($cli->can('cmd_server'), 'server command exists');
}

# Test routes command
{
    my $cli = Trickster::CLI->new;
    ok($cli->can('cmd_routes'), 'routes command exists');
}

# Test app name detection
{
    my $cli = Trickster::CLI->new;
    my $app_name = $cli->detect_app_name;
    ok($app_name, 'App name detected');
    like($app_name, qr/^[A-Z]/, 'App name is capitalized');
}

done_testing;
