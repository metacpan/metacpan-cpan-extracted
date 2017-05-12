package Text::Livedoor::Wiki::CatalogKeeper;

use strict;
use warnings;
use Data::Dumper;

my $NO_SETTING = "&nbsp;";

sub new {
    my $class =shift;
    my $self = bless {} ,$class;
    $self->{data} = [];
    return $self;
}
sub append {
    my $self   = shift;
    my $args   = shift;
    push @{$self->{data}} , $args; 
}

sub contents {
    my $self = shift;

# divでこのうえを囲わない
    my $prev = 0;
    my $contents = qq|<div class="wiki-catalog">\n<div class="wiki-catalog-inner">\n<ul>\n|;
    for ( my $i = 0 ; $i < scalar @{ $self->{data} } ; $i++ ) {
        my $flg = 1;
        my $item = $self->{data}[$i];
        my $next = scalar @{$self->{data}} != $i+1 ? $self->{data}[$i+1]{level} : 0;
        while( $flg ) {
            if( $item->{level} > $prev + 1 ) {
                $prev++;
                #my $n = $prev == $item->{level} ? $next : $prev+1;
                my $n = $next ;
                $contents .= sprintf( qq|<li class="list-%s">$NO_SETTING| , $prev );

                if( $prev == $n ) {
                    $contents .= "</li>\n";
                }
                elsif( $prev > $n ) {
                    my $diff= $item->{level} - $n;
                    $contents .= "</li>\n";
                    for(1..$diff) {
                        $contents .= "</ul>\n</li>\n"; 
                    }
                }
                elsif( $prev < $n ) {
                    $contents .= "\n<ul>\n"; 
                }

                next;
            }
            $prev= 1 if $prev== 0;
            $flg = 0;
        }
        $contents .= sprintf( qq|<li class="list-%s"><a href="#%s">%s</a>| , $item->{level} , $item->{id} , $item->{label} );

        if( $item->{level} == $next ) {
            $contents .= "</li>\n";
        }
        elsif( $next != 0 && $item->{level} > $next ) {
            my $diff= $item->{level} - $next;
            $contents .= "</li>\n";
            for(1..$diff) {
                $contents .= "</ul>\n</li>\n"; 
            }
        }
        elsif( $item->{level} < $next ) {
            $contents .= "\n<ul>\n"; 
        }

        if( $next == 0 ) {
            $contents .= "</li>\n";
            for(1..($item->{level}-1)) {
                $contents .= "</ul>\n</li>"; 
            }
        }

        $prev = $item->{level};
    }

    $contents .= "\n</ul>\n</div>\n</div>";

    return $contents;
}

1;

=head1 NAME

Text::Livedoor::Wiki::CatalogKeeper - Catalog Keeper

=head1 DESCRIPTION

keep h3,h4,h5 catalog

=head1 METHOD

=head2 append

=head2 contents

=head2 new

=head1 AUTHOR

polocky

=cut
