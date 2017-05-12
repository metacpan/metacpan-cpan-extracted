package Text::ClearSilver::Compat;
use strict;
use Text::ClearSilver;
use Symbol ();

no warnings qw(once);

$INC{'ClearSilver.pm'}          = __FILE__;
$INC{'Data/ClearSilver/HDF.pm'} = __FILE__;

package Text::ClearSilver::HDF;
# ClearSilver::HDF is a subclass of Text::ClearSilver::HDF
@ClearSilver::HDF::ISA = (__PACKAGE__);

*setValue  = \&set_value;
*getValue  = \&get_value;
*readFile  = \&read_file;
*readString= \&read_string;
*writeFile = \&write_file;
*getObj    = \&get_obj;
*objChild  = \&obj_child;
*getChild  = \&get_child;
*objValue  = \&obj_value;
*objName   = \&obj_name;
*objNext   = \&obj_next;

sub sortObj {
    my($self, $func_name) = @_;
    my $func_sym = Symbol::qualify_to_ref($func_name, scalar caller);
    $self->sort_obj(*{$func_sym}{CODE});
}

*setSymlink = \&set_symlink;
*removeTree = \&remove_tree;

# Data::ClearSilver::HDF is a subclass of Text::ClearSilver::HDF
@Data::ClearSilver::HDF::ISA = ('ClearSilver::HDF');

*hdf = \&new;

package Text::ClearSilver::CS;
# ClearSilver::CS is a subclass of Text::ClearSilver::CS
@ClearSilver::CS::ISA = (__PACKAGE__);

sub displayError{
    return 'Text::ClearSilver::Compat: displayError() is not supported';
}

*parseFile   = \&parse_file;
*parseString = \&parse_string;

1;
__END__

=head1 NAME

Text::ClearSilver::Compat - Adopt Text::ClearSilver, instead of ClearSilver and Data::ClearSilver::HDF

=head1 SYNOPSIS

    use Text::ClearSilver::Compat;

    # main script
    use ClearSilver;            # noop
    use Data::ClearSilver::HDF; # noop

    my %vars;
    my $hdf = Data::ClearSilver::HDF->HDF(\%vars);

    my $cs = ClearSilver::CS->new($hdf);
    $cs->parseFile('template.cs');
    $cs->render();

=head1 SEE ALSO

L<Text::ClearSilver>

=cut
