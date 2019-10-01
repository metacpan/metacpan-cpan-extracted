=head1 NAME

XAO::DO::ImportMap::Base -- base class for all XAO import maps

=head1 DESCRIPTION

All ClearingPoint import maps must have this class in their inheritance
hierarchy. It provides basic functionality and common API methods even
if these methods cannot do anything in generic way.

Methods are:

=over

=cut

###############################################################################
package XAO::DO::ImportMap::Base;
use strict;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::ImportMap::Base);
use XAO::Objects;

use base XAO::Objects->load(objname => 'Atom');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Base.pm,v 1.9 2005/01/14 02:08:06 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item category_hash_to_array ($)

Converts older CPoint style hash into planar category path to category
path mapping to be stored into object.

Source hash has the following format:

 my %map=(
    '_keep_original'                => 'By Manufacturer::3M Products',
    '3M(TM) Clean Room Products'    => {
        '_root'                     => 'Clean Room Products',
        'General Purpose Tapes'     => '::General Purpose Tapes',
    },
    'Industrial Tapes'              => {
        '_root'                     => [ 'Industrial Tapes',
                                         'Packaging Materials'
                                       ],
        '3M(TM) Sealing and Holding Products'
                                    => '::Sealing & Holding'
    }
 );

Result will be in two array references:

 my ($src_cat,$dst_cat)=$self->category_hash_to_array(\%map);

First array will hold the list of all full source category paths and the
second one - destination paths.

=cut

sub category_hash_to_array ($$;$$) {
    my $self=shift;
    my $hash=shift;
    my $src_root=shift || '';

    my $src_root_o=$src_root;
    $src_root.='::' if $src_root;

    my @src_cat;
    my @dst_cat_complete;

    my $dst_root_ar=$hash->{_root} || '';
    $dst_root_ar=[ $dst_root_ar ] unless ref($dst_root_ar);
    foreach my $dst_root (@{$dst_root_ar}) {

        my @dst_cat;

        if($src_root && $dst_root) {
            push(@src_cat,$src_root_o);
            push(@dst_cat_complete,$dst_root);
        }

        foreach my $src (keys %{$hash}) {

            my $dst_ar=$hash->{$src};
            $dst_ar=[ $dst_ar ] unless ref($dst_ar) && ref($dst_ar) eq 'ARRAY';
            foreach my $dst (@{$dst_ar}) {

                if(ref($dst)) {

                    my $sroot=$src_root . $src;

                    my ($s,$d)=$self->category_hash_to_array($dst,$sroot);
                    push(@src_cat,@{$s});
                    push(@dst_cat,@{$d});

                }

                else {

                    push(@src_cat,$src_root . $src);
                    push(@dst_cat,$dst);

                }

            }
        }

        push(@dst_cat_complete,
             map { /^::/ ? $dst_root . $_ : $_ } @dst_cat);

    }

    ##
    # Tricky part - leaving only unique pairs. Left side can be
    # non-unique and right side can be non-unique, but there should be
    # no exactly equal pairs.
    #
    my %th;
    for(my $i=0; $i!=@src_cat; $i++) {
        my $key=$src_cat[$i] . '::::' . $dst_cat_complete[$i];
        $th{$key}=$i;
    }

    return (
        [ map { $src_cat[$_] } sort { $a <=> $b } values %th ],
        [ map { $dst_cat_complete[$_] } sort { $a <=> $b } values %th ]
    );
}

###############################################################################

=item map_category ($$)

Translates one category path into another according to translation table
stored on the object (CategoryMap). Elements of path are separated by
double colon -- `::'.

If there is no exact match for the category translate_category() will
strip elements from the end of path and try again. If that gave a
translated path then translate_category() will check if that path has
sub-paths in which case it will return 'Other' sub-path in that found
path. Otherwise it will return the path itself.

First argument is a reference to the hash used unternally by
map_category, just provide a reference to an empty hash to the first
call and keep that reference the same throughout all the calls.

Second argument is a category path to be translated.

Always returns a list reference even if that was one to one match.

May return empty list if that category is not mapped anywhere and should
be ignored.

=cut

sub map_category ($$$$) {
    my $self=shift;
    my $category_cache=shift;
    my $path=$self->normalize_category_path(shift);
    my $category_map=shift;

    ref($category_cache) eq 'HASH' ||
        throw $self "map_category - first argument must be a hash reference";

    if(!keys %{$category_cache}) {
        foreach my $obj ($category_map->values) {
            my $src_cat=$self->normalize_category_path($obj->get('src_cat'));
            next unless $src_cat;
            my $dst_cat=$self->normalize_category_path($obj->get('dst_cat'));
            push(@{$category_cache->{$src_cat}},$dst_cat);
        }
        keys %{$category_cache} || dprint "Empty CategoryMap table";
    }

    dprint "path=$path";

    return $category_cache->{$path} if $category_cache->{$path};

    dprint "not in the cache path=$path";

    my @list;
    if($category_cache->{_keep_original}) {
        foreach my $cat (@{$category_cache->{_keep_original}}) {
            push(@list,$cat ? $cat.'::'.$path : $path);
        }
    }

    my @p=split(/::/,$path);
    for(my $i=$#p; $i>=0; $i--) {
        my $np=join('::',@p[0..$i]);

        if($category_cache->{$np . '::Other'}) {
            push(@list,@{$category_cache->{$np . '::Other'}});
            last;
        }
    }

    if($category_cache->{Other}) {
        push(@list,@{$category_cache->{Other}});
    }

    dprint "TRANSLATION: ",join(",",@list);

    \@list;
}

###############################################################################

=item map_xml_categories ($$)

Pure virtual method that is supposed to translate all categories from
RawXML container (first argument) to Categories container (second
argument).

Returns a reference to the hash that contains a map between external and
internal category IDs. Pass this hash reference to the
map_xml_products() method.

Should be overriden unless your catalog has no categories information
whatsoever.

=cut

sub map_xml_categories ($$$) {
    my $self=shift;
    dprint ref($self)."::map_xml_categories - default empty method called";
    return { };
}

###############################################################################

=item map_xml_products ($$$)

Pure virtual method that is supposed to translate all products from
RawXML container (second argument) to Products container (third
argument) using category ID translation map (fourth argument).

The first argument is currently just a text prefix that would be added
to all product IDs before storing them. Later that should be changed to
a SKU translating object reference or code reference.

You must override that method in derived classes.

=cut

sub map_xml_products ($$$$) {
    my $self=shift;

    throw $self "map_xml_products - pure virtual method called";
}

###############################################################################

sub new ($) {
    my $class=shift;
    my $self={};
    bless $self, ref($class) || $class;
}

###############################################################################

=item normalize_category_path ($)

Removes double spaces, spaces in the beginning and at the end of path
element.

=cut

sub normalize_category_path ($$) {
    my $self=shift;
    my $path=shift || '';

    $path=~s/\s\s+/ /g;
    $path=~s/ ::/::/g;
    $path=~s/:: /::/g;

    $path;
}

###############################################################################

=item product_id ($$)

Analyzes product and generates product SKU and suggested product ID
(list ID). Supposed to be overriden in project specific implementations.

=cut

sub product_id ($$$) {
    my $self=shift;
    my $product=shift;

    if(@_) {
        throw $self "product_id - you're using old syntax, please change" .
                    " your ImportMap accordingly";
    }

    undef;
}

###############################################################################

sub store_categories_hash ($$$) {
    my $self=shift;
    my $storage=shift;
    my $cats=shift;
    my $map=shift;

    ##
    # Building a hash to speed up reverse lookup of category id by
    # name. We cannot keep categories under some one-to-one name to
    # id matching as categories from different catalogs can (and will)
    # translate to the same common categories.
    #
    my %reverse_map;
    dprint "Building reverse lookup cache";
    foreach my $cid ($storage->keys) {
        my $cobj=$storage->get($cid);
        my ($path,$parent_id)=$cobj->get('name','parent_id');

        while(defined($parent_id) && length($parent_id)) {
            my $c=$storage->get($parent_id);
            if(!$c) {
                eprint "Non-existing parent category (name=$parent_id)";
                $path=undef;
                last;
            }
            $path=$c->get('name') . '::' . $path;
            $parent_id=$c->get('parent_id');
        }
        next unless $path;

        $path=$self->normalize_category_path($path);
        $reverse_map{$path}=$cid;
        dprint "$path => $cid";
    }

    ##
    # Now mapping categories and storing them into $storage
    #
    my $inc;
    my %catmap;
    my %catcache;
    dprint "Mapping and storing";
    foreach my $cat (values %{$cats}) {
        my $path=$cat->{name};
        my $tc=$cat;
        while(defined($tc->{parent_id}) && length($tc->{parent_id})) {
            my $c=$cats->{$tc->{parent_id}};
            if(!$c) {
                eprint "No parent category known for parent_id='$tc->{parent_id}'";
                $path=undef;
                last;
            }
            $tc=$c;
            $path=$tc->{name} . '::' . $path;
        }
        next unless $path;

        my @cpids;

        my $cset=$self->map_category(\%catcache,$path,$map);
        dprint $path;

        foreach my $path (@$cset) {
            my @path=split(/::/,$path);
            my $parent_id='';
            for(my $i=0; $i!=@path; $i++) {
                my $cdesc=$path[$i];
                my $cpath=join('::',@path[0..$i]);

                if($reverse_map{$cpath}) {
                    $parent_id=$reverse_map{$cpath};
                    push(@cpids,$parent_id) if $i==$#path;
                    next;
                }

                my $cobj=$storage->get_new();
                my $id;

                if($i==$#path) {
                    my $n=substr($cdesc,0,$cobj->describe('name')->{maxlength});
                    my $d=substr($cat->{description},0,$cobj->describe('description')->{maxlength});
                    dprint "ln=",length($n)," ld=",length($d);

                    $cobj->put(name          => $n);
                    $cobj->put(description   => $d);
                    $cobj->put(parent_id     => $parent_id);
                    $cobj->put(image_url     => $cat->{image});
                    $cobj->put(thumbnail_url => $cat->{thumbnail});

                    $id=$storage->put($cobj);

                    push(@cpids,$id);
                }
                else {
                    my $n=substr($cdesc,0,$cobj->describe('name')->{maxlength});
                    dprint "ln=",length($n);

                    $cobj->put(name      => $n);
                    $cobj->put(parent_id => $parent_id);

                    $id=$storage->put($cobj);
                }

                $parent_id=$id;
                $reverse_map{$cpath}=$id;
            }

        }

        $catmap{$cat->{id}}=\@cpids;
    }

    foreach my $id (sort keys %catmap) {
        dprint "Category $id translates to [",join(',',@{$catmap{$id}}),"]";
    }

    \%catmap;
}

###############################################################################

=item xattr

Convenience method to get attribute value out of XML::DOM item.

=cut

sub xattr ($$$;$) {
    my $self=shift;
    my $xmlattr=shift;
    my $name=shift;
    my $default=shift || '';

    my $value=$xmlattr->getNamedItem($name);
    $value=$value ? $value->getValue() : undef;

    defined($value) ? $value : $default;
}

###############################################################################

1;

__END__

=back

=head1 AUTHORS

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/
