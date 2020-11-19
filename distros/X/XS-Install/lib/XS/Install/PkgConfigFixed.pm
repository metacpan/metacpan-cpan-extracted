package
    XS::Install::PkgConfigFixed;
use PkgConfig;

no warnings 'redefine';

my $orig_parse_line = \&PkgConfig::parse_line;
*PkgConfig::parse_line = sub {
    my $self = shift;
    my $line = shift;
    $line =~ s/[@]/^/g if $line =~ /=/;
    return $orig_parse_line->($self, $line, @_);
};

my $orig_assign_var = \&PkgConfig::assign_var;
*PkgConfig::assign_var = sub {
    my ($self, $field, $value) = (shift, shift, shift);
    $value =~ s/\^/\\\@/g;
    return $orig_assign_var->($self, $field, $value);
};

1;
