package VS::RuleEngine::Util;

use strict;
use warnings;

use Carp qw(croak);

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw();
our @EXPORT_OK = qw(
    is_existing_package
    is_valid_name 
    is_valid_package_name
);

our %EXPORT_TAGS = ();

sub is_valid_name {
    my $name = pop;
    
    return $name =~ m/^ [A-Za-z] [A-Za-z0-9_]* $/x;
}

sub is_valid_package_name {
    my $pkg = pop;
    
    return $pkg =~ m/[[:alpha:]_] \w* (?: (?: :: | ') \w+ )*/x; #
}

sub is_existing_package {
    my $package = pop;
    no strict 'refs';
    my $exists = defined *{$package . '::'} ? 1 : 0;
    return $exists;
}

1;
__END__

=head1 NAME

VS::RuleEngine::Util - Utility functions for VS::RuleEngine

=head1 INTERFACE

=head2 FUNCTIONS

=over 4

=item is_existing_package ( PACKAGE )

Checks if the package I<PACKAGE> is defined or not.

=item is_valid_name ( NAME )

Checks if the given I<NAME> is a valid name to assign inputs, outputs, hooks, rules and actions.

=item is_valid_package_name ( NAME )

Checks if the given I<NAME> is a valid package name or not.

=back

=head1 EXPORTS

Nonething by default.

=cut
