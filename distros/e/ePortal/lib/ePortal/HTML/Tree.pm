#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------

package ePortal::HTML::Tree;
    our $VERSION = '4.5';

	use ePortal::Global;
    use ePortal::Utils;     # import logline, pick_lang, CGI
	use Carp;

=head1 NAME

ePortal::HTML::Tree - Draws a tree.

THIS MODULE IS UNDER CONSTRUCTION !!!

=head1 SYNOPSIS

This module is used to draw a tree of objects.

=head1 METHODS

=cut

############################################################################
sub new	{	#09/07/01 2:04
############################################################################
	my ($proto, %p) = @_;

	my $class = ref($proto) || $proto;
	my $self = {};
	bless $self, $class;

	# Set some defaults. This is @metags Tree_attributes
	$self->{obj_by_id} 	= {};	# Hash of objects. Each object is a hash
								# id =>
								# parent =>
								# text => complete text
								# title => need processing by myself
								# expanded => 1|0
								# children => [] my children
                                #
	$self->{id} = 1;			# Internal ID generator
    $self->{root} = [];         # Array of root branches ID.
	$self->{depth} = 1;			# The depth of the tree
	$self->{button_edit} = undef;
	$self->{button_access} = undef;
	$self->{button_delete} = undef;
	$self->{class} = [];		# array of attributes. [0] is default for all tree
	$self->{style} = [];		# [1] for 1st depth
	$self->{url} = [];			# #id# expanded to current ID
	$self->{sorted} = undef;	# Sort by title while drawing

	$self->initialize(%p);
	return $self;
}##new



############################################################################
sub initialize	{	#09/07/01 2:07
############################################################################
    my ($self, %p) = (@_);

	# overwrite known initialization parameters
	foreach my $key (keys %$self) {
		$self->{$key} = $p{$key} if exists $p{$key};
		die "Unknown key [$key] for Tree.pm" if not exists $self->{$key};
	}

	$self;
}##initialize


=head2 self_url(cal_param, value)

Constructs self referencing URL removing all myself specific parameters.
New parameters should be passed to this function to make them added to URL.

Returns URL with parameters.

=cut

############################################################################
sub self_url	{	#02/14/02 4:52
############################################################################
    my ($self, %opt_args) = (@_);

    my %args = $ePortal->m->request_args;
	delete $args{$_} foreach (qw/t_c t_e/);

	return href($ePortal->r->uri, %args, %opt_args);
}##self_url


############################################################################
sub new_id	{	#03/15/02 2:25
############################################################################
    my ($self) = (@_);

	while(exists $self->{obj_by_id}{$self->{id}}) {
		$self->{id} ++;
	}
	return $self->{id};
}##new_id


############################################################################
# Function: handle_request
# Description: handle apache request.
# Parameters:
# Returns:
# 	new location to redirect
############################################################################
sub handle_request	{	#09/07/01 2:08
############################################################################
    my ($self, %p) = (@_);
	$self->initialize(%p);

    my %args = $ePortal->m->request_args;           # this is %ARGS
	my %state = $self->list_state(1);		# these keys we use
	my $location;							# will return this

	# restore OLD state. Form name used as a key
    my $old_state = {};

	# somebody pressed a button in the list form
	if ($args{list_submit}) {

		# get list of selected items
		my @id = ref($args{list_chbox}) eq 'ARRAY' ? @{$args{list_chbox}} : ($args{list_chbox});
		$self->{list_items} = [@id];

		if ($args{list_btcreate}) {	# "Create" pressed
			$location = href($self->{button_create}{url}, objid => 0);

		} elsif ($args{list_btdelete}) {	# "Delete selected" pressed

			# do redirect if needed
			if ($self->{button_delete}{url}) {
				$location = href($self->{button_delete}{url}, objid => $self->{list_items});
			} else {
				$location = href("/delete.htm", objid => $self->{list_items},
						objtype => ref($self->{obj}),
						done => href($ENV{SCRIPT_NAME}, $self->list_state));
            }
        }
	}	# if list_submit

    # Calculate LIMITs
	$self->{limit_rows} = $self->{rows_per_page} + 1; # One more to know is any data more?
	if ($self->{page} > 1) {
			# limit_offset counts from 0
		$self->{limit_offset} = ($self->{page}-1) * $self->{rows_per_page};
	}


	if ($location) {
		$ePortal->m->comp("/redirect.mc", location => $location);
	}

	return $location;
}##handle_request


=head2 draw()

Main entrance

=cut

############################################################################
sub draw	{	#12/17/01 3:15
############################################################################
    my ($self, @p) = (@_);
	my @out;

	$self->initialize(@p);

	my @prepared_items;
    {
		use locale;
        @prepared_items = $self->{sorted}
			? sort { uc($self->{obj_by_id}{$a}{title}) cmp uc($self->{obj_by_id}{$b}{title})} @{$self->{root}}
			: @{$self->{root}};
	}

	foreach my $root ( @prepared_items ) {
		push @out, $self->_draw_item($root);
    }

	# Return resulting HTML or output it directly to client
	defined wantarray ? join("\n", @out) : $ePortal->m->out( join("\n", @out) );
}##draw_list


=head2 _draw_item

ID of image TR%_###i

ID of hideable span TR%_###s

% is current level of tree starting with 1.

### - the ID of the item

=cut

############################################################################
sub _draw_item	{	#03/15/02 3:24
############################################################################
	my ($self, $item_id) = @_;
	my $item = $self->{obj_by_id}{$item_id};
	my @out;

	my $image_id = $item->{name} . 'i';
	my $span_id =  $item->{name} . 's';


	push @out, CGI::a({-name => $item->{id}});

	# empty cells for indentation
	for (1 .. $item->{depth}-1) {
		push @out, img( src => "/images/ePortal/none.gif" );
	}

	# item image
	if (! @{$item->{children}}) {
		push @out, img( src => "/images/ePortal/item.gif" );
	} else {
		push @out, img( src => "/images/ePortal/minus.gif", id => $image_id,
			 		href => "javascript:expand_tree('$item->{name}');");
	}

	# prepare class & style for title
	my %cgi = ();
	foreach (qw/class style/) {
		my $attr = $item->{$_} || $self->{$_}[$item->{depth}] || $self->{$_}[0];
		$cgi{"-$_"} = $attr if $attr;
	}

	# prepare url for title
	my $url = $item->{url} || $self->{url}[$item->{depth}] || $self->{url}[0];
	$url =~ s/#id#/$item->{id}/;

	# Javascript URL to expand child items
	if (!$url and @{$item->{children}}) {
		$url = "javascript:expand_tree('$item->{name}');";
    }

	# Item itself
	push @out, $url
		? CGI::a({-href => $url, %cgi}, $item->{title})
		: CGI::span(\%cgi, $item->{title});

	# optional column
	push @out, $item->{html};
	push @out, "<br>\n";

	# If children present draw them
	if (@{$item->{children}}) {
		push @out, CGI::start_span({ -id => $span_id, -style => $item->{expanded} ? "display:inline;" : "display:none;"});
		my @prepared_items;
        {
			use locale;
            @prepared_items = $self->{sorted}
				? sort { uc($self->{obj_by_id}{$a}{title}) cmp uc($self->{obj_by_id}{$b}{title})} @{$item->{children}}
				: @{$item->{children}};
		}

		foreach my $child_id ( @{$item->{children}} ) {
			push @out, $self->_draw_item($child_id);
        }
		push @out, '</span>';
		my $expanded = $item->{expanded} * 1;
		push @out, CGI::script({-language => 'JavaScript'}, "expand_tree('$item->{name}', $expanded);");
	}

	if (defined wantarray) {
		return join "\n", @out;
	} else {
		 $ePortal->m->out(join "\n", @out);
		 $ePortal->m->flush_buffer;
	}
}##_draw_item






=head2 add_item($id,$title,$parent,%parameters)

$parent is undef for root items.

Parameters are:

html - custom HTML code for the item

class, style

Returns $id or new generated id.

=cut

############################################################################
sub add_item	{	#03/15/02 2:42
############################################################################
    my ($self, $id, $title, $parent_id, %p) = (@_);

	$id = $self->new_id if (exists $self->{obj_by_id}{$id});

	my $item = {
		id => $id,
		parent => $parent_id,
		title => $title,
		children => [],
		depth => 1,
#		class => undef,
#		style => undef,
#		url => undef,
		expanded => 0,
		%p
	};


	if (exists $self->{obj_by_id}{$parent_id}) {
		my $parent = $self->{obj_by_id}{$parent_id};
		$item->{depth} = $parent->{depth} + 1;
		$self->{depth} = $item->{depth} > $self->{depth}? $item->{depth} : $self->{depth};
		push @{$parent->{children}}, $id;

    } elsif ($parent_id==0) {  # drop items without existing parent
		$item->{parent} = undef;
		push @{$self->{root}}, $id;
	}

	$self->{obj_by_id}{$id} = $item;
	$item->{name} = 'TR' . $item->{depth} . '_' . $item->{id};

	return $item;
}##add_item



############################################################################
sub load_item	{	#03/18/02 11:05
############################################################################
    my ($self, $obj, %p) = (@_);

	$p{field_id} = 'id' unless $p{field_id};
	$p{field_title} = 'title' unless $p{field_title};
	$p{field_parent} = 'parent' if ! $p{field_parent} and $obj->attribute('parent');

	my %pass_params;
	$pass_params{$_} = $p{$_} foreach (qw/class style url expanded/);

	my $parent = $p{parent};
	$parent = $obj->value($p{field_parent}) if $p{field_parent};

	my $icon_edit_html = icon_edit($obj)     if $p{button_edit}   || $self->{button_edit};
	my $icon_delete_html = icon_delete($obj) if $p{button_delete} || $self->{button_delete};

    $self->add_item( $obj->value($p{field_id}),$obj->value($p{field_title}),
		$parent, %pass_params,
        html => $p{html} . $icon_edit_html . $icon_delete_html );

}##load_item

############################################################################
sub load_items	{	#03/18/02 11:05
############################################################################
    my ($self, $obj, %p) = (@_);

	while($obj->restore_next) {
		$self->load_item($obj, %p);
    }

}##load_items





=head2 class('class_name',$depth)

Set default class name for items at depth $depth. Use individual properties
in C<add_item()> to override this defaults.

=cut

############################################################################
sub class	{	#03/19/02 10:22
############################################################################
    my ($self, $class, $depth) = (@_);
	$depth *=1;
	$self->{class}[$depth] = $class;
}##class




=head2 style('style_name',$depth)

Set default style name for items at depth $depth. Use individual properties
in C<add_item()> to override this defaults.

=cut


############################################################################
sub style	{	#03/19/02 10:22
############################################################################
    my ($self, $style, $depth) = (@_);
	$depth *=1;
	$self->{style}[$depth] = $style;
}##style



=head2 url('url',$depth)

Set default url for items at depth $depth. Use individual properties
in C<add_item()> to override this defaults.

=cut


############################################################################
sub url	{	#03/19/02 10:22
############################################################################
    my ($self, $url, $depth) = (@_);
	$depth *=1;
	$self->{url}[$depth] = $url;
}##url



=head2 expand_level($level)

Expand first $level levels. Collapse others.

=cut

 ############################################################################
 sub expand_level	{	#04/01/02 1:37
 ############################################################################
    my ($self, $depth) = (@_);

 	foreach my $id (keys %{$self->{obj_by_id}}) {
		my $item = $self->{obj_by_id}{$id};
		$item->{expanded} = $item->{depth} < $depth ? 1 : 0;
	}
 }##expand_level



=head2 expand_item($id,expand_children)

Expand tree to make the item visible. Collapse all others.

=cut

############################################################################
sub expand_item	{	#04/01/02 1:40
############################################################################
    my ($self, $item, $expand_children) = (@_);

	my $the_item = $self->{obj_by_id}{$item};

	if ($expand_children != -2) {
		# collapse all items
 		foreach my $id (keys %{$self->{obj_by_id}}) {
			$self->{obj_by_id}{$id}{expanded} = 0;
		}

		# expand the item and its parents
		while( $self->{obj_by_id}{$item}{parent} ) {
			$self->{obj_by_id}{$item}{expanded} = 1;
			$item = $self->{obj_by_id}{$item}{parent};
		}
	}
	$self->{obj_by_id}{$item}{expanded} = 1;

	if ($expand_children) {
		foreach (@{$the_item->{children}}) {
			$self->expand_item($_, -2);
        }
    }
}##expand_item

1;


__END__

=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
