package Zed::Plugin::Sys::Debug;

use Zed::Plugin;
use Zed::Output;

=head1 SYNOPSIS

    Open/Close debug message
    ex:
        debug Zed::Plugin::Exe::Cmd
        debug Zed::Plugin::Exe::Cmd off

=cut

invoke "debug" => sub {
    my( $module, $on ) = splice @_;
    $on ||= 'on';
    $on = undef if $on eq 'off';
    $on ? Zed::Output::_debug($module) : Zed::Output::_debug_off($module);
    info("module:$module debug:", $on ? "on" : "off");

}, sub{
    my %plugin = Zed::Plugin::plugins;
    values %{ $plugin{invoke} };
};

1
