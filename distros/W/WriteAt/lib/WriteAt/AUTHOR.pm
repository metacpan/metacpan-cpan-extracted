#===============================================================================
#
#  DESCRIPTION:  Author SECTION
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package WriteAt::AUTHOR;
use strict;
use warnings;
use Perl6::Pod::Block;
use base 'Perl6::Pod::Block';
our $VERSION = '0.01';

=pod

Convert:

    *AUTHOR firstname  [lineage ] surname 

    *AUTHOR Alex Bred Bom 
    *AUTHOR Alex Bom 

To 

           <author>
                <firstname>Alex</firstname>
                <lineage>Bred</lineage>
                <surname>Bom</surname>
        </author>
 
=cut

sub parse_content {
    my $self     = shift;
    my $t        = shift;
    my @words = grep {defined $_ } $t=~m/^ \s* (\S+) \s+ (?:(\S+)\s+)? (\S+)/x;
    my %items  = ();
    if (scalar(@words) > 2 ) {
    @items{qw/ firstname  lineage surname /} = @words;
    }  else {
    @items{qw/ firstname  surname /} = @words;
    }
    return \%items;
}

sub to_docbook {
    my ( $self, $to )= @_;
    my $w = $to->w;
    $w->raw('<author>');
    my $rec = $self->parse_content( $self->childs->[0]->childs->[0] );
    while( my ($k, $v) = each %$rec ) {
        $w->raw("<$k>");
        $w->print("$v");
        $w->raw("</$k>");
    }
    $w->raw('</author>');
}
1;

