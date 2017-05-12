package XTaTIK::Common;

our $VERSION = '0.005002'; # VERSION

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(n_to_br  set_product_pic);

use strict;
use warnings;
use HTML::Entities;
use File::Glob qw/bsd_glob/;
use File::Spec::Functions qw/catfile  splitpath/;
use experimental 'postderef';

sub n_to_br {
    my $data = shift;
    return '' unless length $data;
    return encode_entities($data) =~ s/\n\r?|\r\n/<br>/gr;
}

sub set_product_pic {
    my $c = shift;
    my ( $pic, $num ) = @_;

    # This product has a set pic; check all exist and return
    if ( length $pic ) {
        $pic = join '?',
            grep $c->app->static->file( catfile 'product-pics', $_ ),
                split /\?/, $pic;

        $pic = 'nopic.png' unless length $pic;
        $_[0] = $pic;
        return;
    }

    # No pic set; auto-find them using product number
    $num =~ s{[\\/:*?"<>|]}{_}g; # sub disallowed path chars to underscores
    my @pics;
    for ( $c->app->static->paths->@* ) {
        push @pics, map +(splitpath $_)[-1], grep -r,
            catfile($_, 'product-pics', "$num.jpg"),
            bsd_glob catfile $_, 'product-pics', $num . '___*.jpg';
    }

    $pic = join '?', @pics;
    $pic = 'nopic.png' unless length $pic;
    $_[0] = $pic;
}