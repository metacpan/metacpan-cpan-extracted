package Zed::Plugin::Host::Use;
use strict;

use Zed::Config::Space;
use Zed::Output;
use Zed::Plugin;

=head1 SYNOPSIS

    Specify a Space used by Exe plugin
    ex:
        use
        use list

=cut

invoke "use" => sub {
    my $use = usespace( shift );
    my @host = space($use);
    info("use space: ", $use ? $use."[".scalar @host."]" : "undef");

}, sub{ keys space() };

1
