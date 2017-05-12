package Zed::Plugin::Host::Dump;

use Zed::Plugin;
use Zed::Output;
use Zed::Config::Env;
use Zed::Config::Space;

=head1 SYNOPSIS

    Dump space server list
    ex:
        dump
        dump list

=cut

invoke "dump" => sub {
    my( $space, @host ) = shift;
    $space ||= usespace() or error("use no space!") and return;
    @host = space($space) or error("space:[$space] don't have any hosts!") and return;
    info("$space\[", scalar @host, "]:");
    text(join "\n", @host);

}, sub{ keys space() };

1
