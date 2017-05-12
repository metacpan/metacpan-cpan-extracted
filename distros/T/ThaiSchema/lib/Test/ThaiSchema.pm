package Test::ThaiSchema;
use strict;
use warnings;
use utf8;
use ThaiSchema ();

use parent qw/Exporter Test::Builder::Module/;

our @EXPORT = qw/test_schema/;

sub test_schema {
    my ($value, $schema) = @_;
    my ($ok, $errors) = ThaiSchema::match_schema($value, $schema);
    __PACKAGE__->builder->ok($ok);
    __PACKAGE__->builder->diag($_) for @$errors;
    return !!$ok;
}

1;
__END__

=head1 NOTE

Test::ThaiSchema - Test with ThaiSchema

=head1 SYNOPSIS

    use Test::ThaiSchema;

    test_schema(
        +{ x => 3 },
        {x => type_int},
    );
    done_testing;

=head1 DESCRIPTION

Validate schema and report it.

=head1 AUTHOR

Tokuhiro Matsuno

