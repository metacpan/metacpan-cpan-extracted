=head1 NAME

XAO::DO::ImportMap::Sample -- sample Import Map

=head1 SYNOPSIS

None.

=head1 DESCRIPTION

This sample implementation of Import Map is supposed to serve as a
template for real import maps.

It works on the following XML files:

 <?xml version="1.0"?>
 <catalog id="test" generator="super ERP">
  <categories>
   <catdesc id="0" name="foos" thumbnail="xxx.jpg"/>
   <catdesc id="10" name="bars" description="bars go here"/>
   <catdesc id="100" name="non-alcoholic" parent_id="10"
            image="zzz.jpg"/>
  </categories>
  <products>
   <product id="fubar" name="heavy duty fubar" price="0.12">
    <category id="0"/>
    <category id="10"/>
    <specification name="drinks-equivalent" value="123"/>
    <specification name="tastes-like" value="chicken"/>
   </product>
   <product id="fubeer" name="non-alcoholic drink"
            description="fake long description of fubeer"
            image="fubeer.jpg"
            thumbnail="fubeer_tn.jpg"
            price="23.23">
    <category id="0"/>
    <category id="100"/>
    <specification name="weight" value="12" seq="0"/>
    <specification name="color" value="blue" seq="12"/>
    <specification name="manufacturer" value="odessa" seq="23"/>
   </product>
  </products>
 </catalog>

=cut

###############################################################################
package XAO::DO::ImportMap::Sample;
use strict;
use XAO::Utils;
use XAO::Objects;
use XML::DOM;
use Error;
use base XAO::Objects->load(objname => 'ImportMap::Base');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Sample.pm,v 1.2 2005/01/14 02:08:06 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

use constant MANUFACTURER       => 'Sample Mfr';

###############################################################################

sub check_category_map ($$) {
    my $self=shift;
    my $cmap=shift;


    if(!scalar($cmap->keys)) {
        dprint "Populating category map";

        my $c=$cmap->get_new();

        $c->put(src_cat => 'foos');
        $c->put(dst_cat => 'Tools::Foo');
        $cmap->put($c);

        $c->put(src_cat => 'bars::non-alcoholic');
        $c->put(dst_cat => 'Food::Non-Alcoholic');
        $cmap->put($c);

        $c->put(src_cat => 'bars');
        $c->put(dst_cat => 'Food::Drinks');
        $cmap->put($c);

        $c->put(src_cat => 'bars::non-alcoholic');
        $c->put(dst_cat => 'Food::Drinks');
        $cmap->put($c);
    }
}

###############################################################################

sub map_xml_categories ($$$) {
    my $self=shift;
    my $xmlcont=shift;
    my $catcont=shift;
    my $catmap=shift;

    ##
    # Preparing parser
    #
    my $parser=XML::DOM::Parser->new() ||
        throw Error::Simple "Can't create XML::DOM parser";

    ##
    # Doing two passes, first we collect categories into a hash and then
    # we translate and store them.
    #
    my %cats;
	my $doc;
    foreach my $id (@{$xmlcont->search('type','eq','category')}) {
        my $obj=$xmlcont->get($id);

        $doc=$parser->parse($obj->get('value')) ||
            throw Error::Simple ref($self)."::map_xml_categories - Can't parse category XML ($id)";

        my $catdesc=$doc->getDocumentElement();
        $catdesc->getNodeName() eq 'catdesc' ||
            throw Error::Simple "Root node is not a <catdesc> ($id)";

        my $attrmap=$catdesc->getAttributes();
        my %hash;
        foreach my $attrname (qw(id parent_id name description image thumbnail)) {
            $hash{$attrname}=$self->xattr($attrmap,$attrname);
        }

        if(exists($cats{$hash{id}})) {
            throw Error::Simple "This category ID was already used ($id)";
        }

        $cats{$hash{id}}=\%hash;
    }
	continue {
		$doc->dispose() if $doc;
	}

    return $self->store_categories_hash($catcont,\%cats,$catmap);
}

###############################################################################

sub map_xml_products ($$$$) {
    my $self=shift;
    my $catalog=shift || throw Error::Simple ref($self)."::map_xml_products - no catalog given";;
    my $prefix=shift || throw Error::Simple ref($self)."::map_xml_products - no prefix given";;
    my $xmlcont=shift || throw Error::Simple ref($self)."::map_xml_products - no RawXML container given";
    my $prodcont=shift || throw Error::Simple ref($self)."::map_xml_products - no Products container given";;
    my $catmap=shift || throw Error::Simple ref($self)."::map_xml_products - no category map given";;

    ##
    # Preparing parser
    #
    my $parser=XML::DOM::Parser->new() ||
        throw Error::Simple "Can't create XML::DOM parser";

    my $source_ref=$catalog->container_key || 'unknown';
    my $source_seq=$catalog->get('source_seq') || 0;
    $catalog->put(source_seq => ++$source_seq);

	my $doc;
    foreach my $objid (@{$xmlcont->search('type','eq','product')}) {
        my $obj=$xmlcont->get($objid);

        $doc=$parser->parse($obj->get('value')) ||
            throw Error::Simple "Can't parse product XML ($objid)";

        my $pdesc=$doc->getDocumentElement();
        $pdesc->getNodeName() eq 'product' ||
            throw Error::Simple "Root node is not a <product> ($objid)";

        ##
        # Scanning categories
        #
        my %cats;
        foreach my $node ($pdesc->getElementsByTagName('category')) {
            my $attrmap=$node->getAttributes();
            my $id=$self->xattr($attrmap,'id');
            if(!$id) {
                eprint "No category ID is in one of the categories at $objid";
            }
            else {
                my $list=$catmap->{$id};
                if(!$list) {
                    eprint "Unknown category used in $objid";
                }
                else {
                    @cats{@{$list}}=@{$list};
                }
            }
        }
        my @cats=keys %cats;        # making category IDs unique
        undef %cats;
        if(!@cats) {
            eprint "Product $objid does not belong to any known category, skipping it";
            next;
        }

        ##
        # Loading product description
        #
        my $attrmap=$pdesc->getAttributes();
        my $id=$self->xattr($attrmap,'id');
        if(!$id) {
            eprint "No product ID at $objid";
            next;
        }

        ##
        # Creating hash with product description to be passed into ID
        # calculator
        #
        my %product=(
            categories      => \@cats,
            description     => $self->xattr($attrmap,'description'),
            image_url       => $self->xattr($attrmap,'image'),
            manufacturer_id => $id,
            manufacturer    => MANUFACTURER,
            name            => $self->xattr($attrmap,'name'),
            source_ref      => $source_ref,
            source_seq      => $source_seq,
            source_sku      => $id,
            thumbnail_url   => $self->xattr($attrmap,'thumbnail'),
        );

        ##
        # Looking for matching SKU and taking suggestion for product
        # ID. If there is no SKU then we ignore this product.
        #
        my $product_id=$self->product_id(\%product);
        my $sku=$product{sku};
        if(!$sku) {
            dprint "Skipping product without known SKU - (id=$id)";
            next;
        }

        ##
        # Looking for existing product with the same SKU. Ignoring
        # suggested ID if found.
        #
        my $product_ids=$prodcont->search('sku','eq',$sku);
        if(@{$product_ids}) {
            $product_id=$product_ids->[0];
        }

        ##
        # Filling data into this detached object
        #
        my $pobj=$prodcont->get_new();
        foreach my $fn (keys %product) {
            next if $fn eq 'categories';
            my $maxl=$pobj->describe($fn)->{maxlength};
            my $value=$maxl ? substr($product{$fn},0,$maxl) : $product{$fn};
            $pobj->put($fn => $value);
        }

        ##
        # Storing and reloading to get attached product reference.
        #
        if($product_id && $prodcont->exists($product_id)) {
            my $curr_id=$prodcont->get($product_id)->get('source_sku');
            if($id ne $curr_id) {
                eprint "Cannot override products, current source_sku=$curr_id, new=$id, id=$product_id";
                $product_id=undef;
            }
        }
        if($product_id) {
            $prodcont->put($product_id => $pobj);
        }
        else {
            $product_id=$prodcont->put($pobj);
        }
        $pobj=$prodcont->get($product_id);

        ##
        # Storing specs
        #
        my $specseq=1000;
        my $specs=$pobj->get('Specification');
        $specs->destroy();
        my $spec_obj=$specs->get_new();
        foreach my $node ($pdesc->getElementsByTagName('specification')) {
            $attrmap=$node->getAttributes();
            my $name=$self->xattr($attrmap,'name');
            my $value=$self->xattr($attrmap,'value');
            my $seq=sprintf('S%05u',$self->xattr($attrmap,'seq',$specseq++));

            $spec_obj->put(param => $name);
            $spec_obj->put(value => $value);
            $specs->put($seq => $spec_obj);
        }

        ##
        # Now storing/updating categories
        #
        my $prod_cats=$pobj->get('Categories');
        $prod_cats->destroy();
        my $cat_obj=$prod_cats->get_new();
        foreach my $cat (@cats) {
            $prod_cats->put($cat => $cat_obj);
        }
    }
	continue {
		$doc->dispose() if $doc;
    }
}

1;

__END__

=head1 AUTHORS

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/
