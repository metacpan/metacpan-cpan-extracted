## Tk::Cloth
##
## Copyright (c) 1997-1998 Graham Barr. All rights reserved.
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.

##
## Base class for the creation of all cloth objects
##

## $Id: Cloth.pm,v 2.3 2003/10/22 21:33:17 eserte Exp $

package Tk::Cloth;

use strict;
use vars qw($VERSION);

$VERSION = sprintf("%d.%02d", q$Revision: 2.3 $ =~ /(\d+)\.(\d+)/);

package Tk::Cloth::Object;

use vars qw(*Construct *DelegateFor *privateData *TkHash *_OnDestroy);

# I cannot inherit from Tk::Widget as I am not a widget, but I do
# want to use some of the methods widgets have.

*Construct = Tk::Widget->can('Construct');
*DelegateFor = Tk::Widget->can('DelegateFor');
*privateData = Tk::Widget->can('privateData');
*TkHash = Tk::Widget->can('TkHash');
*_OnDestroy = Tk::Widget->can('_OnDestroy');

##
## base class for all cloth items
##

package Tk::Cloth::Item;

use Tk::Submethods
	'addtag' => [qw(withtag above all below closest overlapping enclosed)],
	'select' => [qw(adjust from to)];

# Tk::Derived::configure and ::cget call these, as they cannot call SUPER::
use vars qw(*configure_self *cget_self *destroy);

*configure_self = \&configure;
*cget_self = \&cget;
# Tk objects usually has a destroy method
*destroy = \&delete;


sub new {
    my $class  = shift;
    my $parent = shift;
    my %args = @_;

    my $cloth = $parent->isa('Tk::Cloth::Item')
			? $parent->cloth : $parent;

    delete $args{Name};

    my @args = $class->CreateArgs($cloth, \%args);
    my $item = bless {}, $class;
    my $tag  = $class->create($cloth, @args);

    $item->{'parent'} = $parent;
    $item->{'cloth'} = $cloth;
    $item->{'tag'}    = $tag;

    $cloth->{'item_tags'} ||= {};
    $cloth->{'item_tags'}{$tag} = $item;

    while($parent->isa('Tk::Cloth::Item')) {
	$parent->addtagWithtag($item);
	$parent = $parent->parent;
    }

    $item->InitObject(\%args);
    $item->configure(%args) if (%args);

    $item;
}

sub DoWhenIdle {
    shift->cloth->DoWhenIdle(@_);
}

sub InitObject {
}

sub CreateArgs {
    my($class,$cloth,$args) = @_;
    my @args = ();
    my $coords = delete $args->{'-coords'};

    push @args , @{$coords}
	if defined $coords;

    @args
}

sub create {
    my $class = shift;
    my $cloth = shift;
    $cloth->create($class->Tk_type, @_);
}

sub tag { shift->{'tag'} }
sub parent { shift->{'parent'} }
sub cloth { shift->{'cloth'} }
sub children { () }

sub delete {
    my $item = shift;

    foreach ($item->gettags) {
	$_->forget($item) if defined $_;
    }

    $item->cloth->delete($item);
}

# Tk objects usually has a destroy method
*destroy = \&delete;

sub pack {}
sub grid {}
sub place {}
sub form {}

sub addtag	{ $_[0]->cloth->addtag(@_)		}
sub bbox	{ $_[0]->cloth->bbox(@_)   		}
sub coords	{ $_[0]->cloth->coords(@_)		}
sub dchars	{ $_[0]->cloth->dchars(@_)		}
sub dtag	{ $_[0]->cloth->dtag(@_)		}
sub focus	{ $_[0]->cloth->itemfocus(@_)		}
sub gettags	{ $_[0]->cloth->gettags(@_)		}
sub icursor	{ $_[0]->cloth->icursor(@_)		}
sub index	{ $_[0]->cloth->index(@_)		}
sub insert	{ $_[0]->cloth->insert(@_)		}
sub configure	{ $_[0]->cloth->itemconfigure(@_)	}
sub cget	{ $_[0]->cloth->itemcget(@_)		}
sub lower	{ $_[0]->cloth->itemlower(@_)		}
sub move	{ $_[0]->cloth->move(@_)		}
sub raise	{ $_[0]->cloth->itemraise(@_)		}
sub scale	{ $_[0]->cloth->scale(@_)		}
sub type	{ $_[0]->cloth->type(@_)		}
sub select	{ $_[0]->cloth->select(@_)		}

sub bind {
    my $item = shift;
    my @args = ();

    push @args, shift
	if @_;

    if(@_) {
	my $cb = shift;
	my @a = ( $item );
	if(ref($cb) && UNIVERSAL::isa($cb,'ARRAY')) {
	    my $meth = shift @$cb;
	    push @a, @$cb;
	    $cb = $meth;
	}

	push(@args, [ 
	    sub { shift; shift->Call(@_)}, Tk::Callback->new($cb), @a
	]);
    }

    $item->cloth->itembind($item,@args);
}

package Tk::Cloth::Text;
use base qw(Tk::Cloth::Item);
Construct Tk::Cloth::Object 'Text';
sub Tk_type { 'text' }

package Tk::Cloth::Image;
use base qw(Tk::Cloth::Item);
Construct Tk::Cloth::Object 'Image';
sub Tk_type { 'image' }

package Tk::Cloth::Arc;
use base qw(Tk::Cloth::Item);
Construct Tk::Cloth::Object 'Arc';
sub Tk_type { 'arc' }

package Tk::Cloth::Bitmap;
use base qw(Tk::Cloth::Item);
Construct Tk::Cloth::Object 'Bitmap';
sub Tk_type { 'bitmap' }

package Tk::Cloth::Line;
use base qw(Tk::Cloth::Item);
Construct Tk::Cloth::Object 'Line';
sub Tk_type { 'line' }

package Tk::Cloth::Oval;
use base qw(Tk::Cloth::Item);
Construct Tk::Cloth::Object 'Oval';
sub Tk_type { 'oval' }

package Tk::Cloth::Polygon;
use base qw(Tk::Cloth::Item);
Construct Tk::Cloth::Object 'Polygon';
sub Tk_type { 'polygon' }

package Tk::Cloth::Rectangle;
use base qw(Tk::Cloth::Item);
Construct Tk::Cloth::Object 'Rectangle';
sub Tk_type { 'rectangle' }

package Tk::Cloth::Window;
use base qw(Tk::Cloth::Item);
Construct Tk::Cloth::Object 'Window';
sub Tk_type { 'window' }

package Tk::Cloth::Grid;
use base qw(Tk::Cloth::Item);
Construct Tk::Cloth::Object 'Grid';
sub Tk_type { 'grid' }

package Tk::Cloth::Tag;
# with Tk::Derived in @ISA, Tag did not work anymore
use base qw(Tk::Cloth::Item Tk::Cloth::Object);
Construct Tk::Cloth::Object 'Tag';

sub Tk_type { 'tag' }
sub BackTrace { shift->cloth->BackTrace(@_); }

sub optionGet {
    shift->cloth->optionGet(@_);
}

sub delete {
    my $del;

    foreach $del (@_) {
	my @ch = $del->children;
	shift(@ch)->delete(@ch)
	    if @ch;
    }

    shift->cloth->delete(@_)
	if @_;
}

sub forget {
    my($item,$subitem) = @_;
    my($k,$v);

    return unless exists $item->{SubWidget};
    my $sw = $item->{SubWidget};

    while(($k,$v) = each %$sw) {
	next unless $v == $subitem;
	delete $sw->{$k};
	last;
    }
}


sub create {
    my $class  = shift;
    my $cloth = shift;

    $cloth->addtag(@_);
    $_[0];
}

my $DEFname = 'tag00000000';

sub CreateArgs {
    my $clsss = shift;
    my $cloth = shift;
    my $arg = shift;
    my $name =  $DEFname++;
    my @args = ($name, 'withtag', '...none...');

    @args;
}

sub children {
    my $item = shift;
    $item->cloth->findWithtag($item)
}

sub Populate {
}

sub SubItem {
    shift->Subwidget(@_);
}

##
## The cloth package
##

package Tk::Cloth;

use Tk::Canvas;

use Tk::Submethods
	'addtag' => [qw(withtag above all below closest overlapping enclosed)],
	'find'   => [qw(withtag above all below closest overlapping enclosed)],
	'select' => [qw(adjust clear from item to)];

Construct Tk::Widget 'Cloth';

# Make sure we can create items on the cloth

use vars qw(*bind *raise *lower *focus);
use base qw(Tk::Cloth::Object Tk::Derived Tk::Canvas);

*bind  = Tk::Widget->can('bind');
*raise = Tk::Widget->can('raise');
*lower = Tk::Widget->can('lower');
*focus = Tk::Widget->can('focus');

sub addtag {
    my $cloth = shift;
    my @args = map { ref($_) ? $_->tag : $_ } @_;

    $cloth->SUPER::addtag(@args);
}

sub bbox {
    my $cloth = shift;
    $cloth->SUPER::bbox(map { $_->tag } @_);
}

sub itembind {
    my $cloth = shift;
    my $item = shift;

    $cloth->SUPER::bind($item->tag,@_);
}

sub coords {
    my $cloth = shift;
    my $item = shift;
    $cloth->SUPER::coords($item->tag, @_);
}

sub dchars {
    my $cloth = shift;
    my $item = shift;
    $cloth->SUPER::dchars($item->tag, @_);
}

sub delete {
    my $cloth = shift;

    my($item,$parent);
    my @tags = ();
    foreach $item (@_) {
	push @tags, $item->tag;
	foreach $parent ($item->gettags) {
	    $parent->forget($item) if defined $parent;
	}
    }

    delete @{$cloth->{'item_tags'}}{@tags};
    $cloth->SUPER::delete(@tags);
}

sub dtag {
    my $cloth = shift;
    my $item = shift;
    my @tag = ();

    if(@_) {
	my $tag = shift;
	@tag = ( $tag->tag );
	$tag->forget($item);
    }
    else {
	my $tag;
	foreach $tag ($item->gettags) {
	    $tag->forget($item) if defined $tag;
	}
    }

    $cloth->SUPER::dtag($item->tag, @tag);
}

sub find {
    my $cloth = shift;
    my @tag =  $cloth->SUPER::find(map { ref($_) ? $_->tag : $_ } @_);
    @{$cloth->{'item_tags'}}{@tag};
}

sub itemfocus {
    my $cloth = shift;
    my @args = @_ ? ( shift->tag ) : ();
    $cloth->SUPER::focus(@args);
}

sub gettags {
    my $cloth = shift;
    my @tag =  $cloth->SUPER::gettags(shift->tag);
    @{$cloth->{'item_tags'}}{@tag};
}

sub icursor {
    my $cloth = shift;
    my $item =  shift;
    $cloth->SUPER::icursor($item->tag, @_);
}

sub index {
    my $cloth = shift;
    my $item =  shift;
    $cloth->SUPER::index($item->tag, @_);
}

sub insert {
    my $cloth = shift;
    my $item =  shift;
    $cloth->SUPER::insert($item->tag, @_);
}

sub itemcget {
    my $cloth = shift;
    my $item =  shift;
    $cloth->SUPER::itemcget($item->tag, @_);
}

sub itemconfigure {
    my $cloth = shift;
    my $item =  shift;
    $cloth->SUPER::itemconfigure($item->tag, @_);
}

sub itemlower {
    my $cloth = shift;
    $cloth->SUPER::lower( map { $_->tag } @_);
}

sub move {
    my $cloth = shift;
    my $item =  shift;
    $cloth->SUPER::move($item->tag, @_);
}

sub itemraise {
    my $cloth = shift;
    $cloth->SUPER::raise( map { $_->tag } @_);
}

sub select {
    my $cloth = shift;
    my $r = $cloth->SUPER::select(map { ref($_) ? $_->tag : $_ } @_);
    $r = $cloth->{'item_tags'}{$r}
	if(defined($r) && exists $cloth->{'item_tags'}{$r});
    $r;
}

sub scale {
    my $cloth = shift;
    my $item =  shift;
    $cloth->SUPER::scale($item->tag, @_);
}

sub type {
    my $cloth = shift;
    my $item =  shift;
    $cloth->SUPER::type($item->tag);
}

1;

__END__

=head1 NAME

Tk::Cloth - An OO Tk Canvas

=head1 SYNOPSIS

    use Tk::Cloth;
    
    $cloth = $parent->Cloth;
    $cloth->pack(-fill => 'both', -expand => 1);
    
    $rect = $cloth->Rectangle(
	-coords => [ 0,0,100,100],
	-fill => 'red'
    );
    
    $tag = $cloth->tag;
    $tag->Line(
	-coords => [10,10,100,100],
	-foreground => 'black'
    );
    $tag->Line(
	-coords => [50,50,100,100],
	-foreground => 'black'
    );
    $tag->move(30,30);
    
    $tag->bind("<1>", [ &button1 ]);

=head1 DESCRIPTION

B<Tk::Cloth> provides an object-orientated approach to a canvas and canvas
items.

=head1 SEE ALSO

L<Tk::Canvas|Tk::Canvas>

=head1 AUTHOR

Graham Barr E<lt>F<gbarr@pobox.com>E<gt>

Current maintainer is Slaven Rezic E<lt>F<slaven@rezic.de>E<gt>.

=head1 COPYRIGHT

Copyright (c) 1997-1998 Graham Barr. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
