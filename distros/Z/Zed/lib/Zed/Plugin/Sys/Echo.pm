package Zed::Plugin::Sys::Echo;

use Zed::Plugin;

=head1 SYNOPSIS

    Echo some string just for testing plugin
    ex:
        echo foo bar

=cut
invoke "echo" => sub {
    print for @_;
    print "\n";
};

1
