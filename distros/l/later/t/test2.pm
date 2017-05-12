package test2;

use Carp;
use base qw(Exporter);
use Data::Dumper;

our @EXPORT = qw(foo
		 variables);

my $count_imports = 0;

my @variables;

sub import {

    # just to make sure that _autoload is not called multiple times...
    $count_imports++;
    confess "ERROR: ".__PACKAGE__." was used more than once." if ($count_imports > 1);

    @variables = @_;

    __PACKAGE__->export_to_level(1);
}

sub variables {
    return @variables;
}

sub foo { 
    return 'test2'; 
}

1;
