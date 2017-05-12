package Ukigumo::Agent::View;
use strict;
use warnings;
use utf8;
use Text::Xslate;
use List::Util qw(first);
use File::Spec;

sub make_instance {
    my ($class, $c) = @_;

    my $path = File::Spec->catdir($c->share_dir, 'tmpl');
    my $xslate = Text::Xslate->new(
        syntax => 'TTerse',
        path => ["$path"],
        module => [
            'Text::Xslate::Bridge::Star',
            'Time::Piece' => ['localtime'],
            'Time::Duration' => ['duration'],
        ],
        function => {
            time => sub { time() },
            uri_for => sub { Amon2->context()->uri_for(@_) },
        },
    );
}

1;

