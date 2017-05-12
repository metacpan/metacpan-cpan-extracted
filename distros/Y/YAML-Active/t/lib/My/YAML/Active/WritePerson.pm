package My::YAML::Active::WritePerson;
use 5.006;
use strict;
use warnings;
use YAML::Active ':all';
our $VERSION = '1.08';

sub yaml_activate {
    my ($self, $phase) = @_;
    UNIVERSAL::isa($self, 'HASH') && exists $self->{person}
      or die
'My::YAML::Active::WritePerson expects a hash ref like { person => {...} }';
    $main::result .= "Writing person:\n";
    my $person = node_activate($self->{person}, $phase);
    $main::result .= " $_ => $person->{$_}\n" for sort keys %$person;
    return $person->{personname};    # rc: OK
}
1;
