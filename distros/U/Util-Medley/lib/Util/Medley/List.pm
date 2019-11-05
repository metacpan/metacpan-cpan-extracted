package Util::Medley::List;
$Util::Medley::List::VERSION = '0.007';
#########################################################################################

use Modern::Perl;
use Method::Signatures;
use Moose;
use namespace::autoclean;

use Data::Printer alias => 'pdump';
use List::Util;

=head1 NAME

Util::Medley::List - utility methods for working with lists

=head1 VERSION

version 0.007

=cut

#########################################################################################

=pod

use base 'Exporter';
our @EXPORT      = qw();                      # Symbols to autoexport (:DEFAULT tag)
our @EXPORT_OK   = qw(list2map min undefs2strs uniq);    # Symbols to export on request
our %EXPORT_TAGS = (                          # Define names for sets of symbols
    all => \@EXPORT_OK,
);

=cut

#########################################################################################

method listToMap (@list) {

    my %map = map { $_ => 1 } @list;
    return %map;
}

=head1 min

Just a passthrough to List::Util::min()

=cut
method min (@list) {

    return List::Util::min(@list);    
}

method undefsToStrings (ArrayRef $list,
                        Str 	 $string = '') {

    my @return;
    foreach my $val (@$list) {
        $val = $string if !defined $val;
        push @return, $val;
    }

    return \@return;
}

=head1 uniq

Just a passthrough to List::Util::uniq()

=cut
method uniq (@list) {

    return List::Util::uniq(@list);    
}

1;
