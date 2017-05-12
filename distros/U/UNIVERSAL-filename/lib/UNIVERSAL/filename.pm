package UNIVERSAL::filename;
use strict;
use warnings;
our $VERSION = '0.03';

BEGIN {
    require UNIVERSAL;
}

*UNIVERSAL::filename = sub {
    my $class = shift;
    $class =~ s{::}{/}g;
    $INC{$class.".pm"};
} unless defined &UNIVERSAL::filename;

1;
__END__

=head1 NAME

UNIVERSAL::filename - file location inspector of modules

=head1 SYNOPSIS

    use UNIVERSAL::filename;    # declare once

    # lib/Foo.pm
    package Foo;

    package Bar;

    1;

    # any.pl
    Foo->filename;              #=> 'lib/Foo.pm'
    Bar->filename;              #=> undef

=head1 DESCRIPTION

Similiar to the 'require' operator, UNIVERSAL::filename inspects %INC to for the file location of a particular module.
No magic here, that means you can't find the file location of a module embeded in the file that belongs to another module.

=head1 AUTHOR

shelling E<lt>navyblueshellingford@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

The MIT License

=cut
