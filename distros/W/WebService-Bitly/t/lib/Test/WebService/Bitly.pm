package Test::WebService::Bitly;
use strict;
use warnings;

use UNIVERSAL::require;

use base qw(Exporter);
our @EXPORT = qw(initialize_result_class);

use Path::Class;
use File::Basename;
use URI;

sub initialize_result_class {
    my ($class_name, $args) = @_;
    my $result_class = 'WebService::Bitly::Result::' . $class_name;
    $result_class->require or die $@;

    return $result_class->new($args);
}

1;


