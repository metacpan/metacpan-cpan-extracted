package meon::Web::NotFound::CategoryProduct;

use warnings;
use strict;
use Path::Class 'file', 'dir';
use File::Copy::Recursive 'dircopy';
use meon::Web::env;

our $VERSION = '0.01';

sub check {
    my ($class, $base_dir, $path) = @_;

    $path =~ s/.xml$//;
    $path =~ s{/index$}{};
    my @idents = file($path)->components;
    return 0 unless shift(@idents) eq '';
    return 0 unless shift(@idents) eq 'c';

    my $xpc = meon::Web::Util->xpc;

    my $category_product_template = file(
        meon::Web::env->hostname_dir,
        'template',
        'xml',
        'category-product.xml'
    );
    return 0 unless -e $category_product_template;

    my $dom = XML::LibXML->load_xml(location => $category_product_template);
    meon::Web::env->xml($dom);

    my $breadcrumb = join('/','home',@idents);
    (
        map { $_->setAttribute('href' => $breadcrumb) }
        $xpc->findnodes('//w:category-product-breadcrumb',$dom)
    );
    my $current_ident = pop(@idents);
    (
        map { $_->setAttribute('ident' => $current_ident) }
        $xpc->findnodes('//w:current-category-product',$dom)
    );

    return $dom;
}

1;


__END__

=head1 NAME

meon::Web::NotFound::CategoryProduct

=head1 SYNOPSIS

inside config.ini:

    [main]
    not-found-handler = meon::Web::NotFound::CategoryProduct

=head1 DESCRIPTION

=head1 AUTHOR

Jozef Kutej

=cut
