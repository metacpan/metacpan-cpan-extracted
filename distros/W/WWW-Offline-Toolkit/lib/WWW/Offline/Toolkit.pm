package WWW::Offline::Toolkit;

use 5.010000;
use strict;
use warnings;
use Data::Dumper;
use Parse::RecDescent;
use File::Find qw(finddepth);

our $VERSION = '0.01';

sub new
{
	my ($class, @args) = @_;
	my $self = bless {}, $class;
	return $self->init(@args);
}

sub init 
{
	my ($self, %options) = @_;

	$self->{'DataDirectory'}   = './data';
	$self->{'OnlineDirectory'} = './online';
	$self->{'IndexFile'}       = $self->{'OnlineDirectory'}.'/index.html';

	$self->{'PostsDirectory'}         = $self->{'OnlineDirectory'}.'/posts';
	$self->{'CategoriesDirectory'}    = $self->{'OnlineDirectory'}.'/categories';

	$self->{'MainCategoryId'}         = 'cat-Main';
	$self->{'CategoryPageTemplateId'} = 'tmpl-Main';
	$self->{'PostTeaserTemplateId'}   = 'tmpl-Teaser';
	$self->{'ImageTemplateId'}        = 'tmpl-Image';

	map { $self->{$_} = $options{$_} if exists $self->{$_} } 
	keys %options;

	$self->{'Objects'} = {};

	return $self;
}

#-------------------------------------------------------------------------------
sub process
{
	my ($self) = @_;
	
	#-------------------------------------------------------------------------------
	# find data files

	my @Files;
	finddepth(
		sub {
			push @Files, $File::Find::name
				if $File::Find::name =~ /\.txt$/;
		}, 
		$self->{'DataDirectory'});

	#-------------------------------------------------------------------------------
	# parse concatenated file contents

	my $Source = '';
	foreach my $file (@Files) {
		print "reading $file\n";
		$Source .= read_file($file);
	}

	$::RD_ERRORS = 1;
	#$::RD_WARN = 1;
	#$::RD_HINT = 1;		
	#$::RD_TRACE = 1;
	$::RD_AUTOSTUB = 1;		

	my $Grammar = q(

		<autoaction: { [@item] } >

		file: <skip: qr{[\s\t\r\n]*}x> object(s)
			{ [@{$item[2]}] }
		
		object: "(" type id hash ")"
			{ ['object', $item[2], $item[3], $item[4]] }
		
		hash: pair(s)
			{
				my %hash;
				foreach my $pair (@{$item[1]}) {
					my $value = $pair->[1];
					   $value = $value->[1] if $value->[0] eq 'value';
					$hash{$pair->[0]} = $value;
				}
				\%hash;
			}
		
			pair: key ":" value
				{ [$item[1], $item[3]] }
			
				value: object | ref | string | list
					{ $item[1] }
		
					ref: id

		id: "#" symbol
			{ $item[2] }
		
		type: symbol
			{ $item[1] }
		
		key: symbol
			{ $item[1] }
		
		symbol: /[A-Za-z0-9\_\-]+/
			{ $item[1] }
		
		string: "{" /[^\{\}]*/ "}"
			{ ['string', $item[2]] }
			
		list: "[" value(s) "]"
			{ [map { $_->[1] } @{$item[2]}] }

	);

	my $Parser = new Parse::RecDescent($Grammar);
	my $AST = $Parser->file($Source);

	#-------------------------------------------------------------------------------
	# create objects from AST

	foreach my $object (@{$AST}) {
		$self->create_object($object, $self->{'Objects'});
	}

	my $MainCategory         = $self->{'Objects'}->{$self->{'MainCategoryId'}};
	my $PostsDirectory       = $self->{'PostsDirectory'};
	my $CategoriesDirectory  = $self->{'CategoriesDirectory'};
	my $CategoryPageTemplate = $self->{'Objects'}->{$self->{'CategoryPageTemplateId'}};
	my $PostTeaserTemplate   = $self->{'Objects'}->{$self->{'PostTeaserTemplateId'}};
	my $ImageTemplate        = $self->{'Objects'}->{$self->{'ImageTemplateId'}};

	#-------------------------------------------------------------------------------
	# check object references

	while ($self->has_unresolved_references()) {
		foreach my $id (keys %{$self->{'Objects'}}) {
			$self->resolve_object_references($id);
		}
	}

	print "building website...\n";

	#-------------------------------------------------------------------------------
	# build index.html

	write_file($self->{'IndexFile'},
		'<html>'.
			'<head>'.
				'<meta http-equiv="refresh" content="0; URL=posts/'.
					to_filename($self->{'Objects'}->{'Home'}->{'title'}).'.html">'.
			'</head>'.
			'<body></body>'.
		'</html>');

	#-------------------------------------------------------------------------------
	# build post pages

	unless (-d $PostsDirectory) {
		mkdir($PostsDirectory) 
			or die "failed to create directory '$PostsDirectory': $!\n";
	}

	$self->map_objects_of_type(
		'post', sub {
			my ($post) = @_;
			
			# add navigation to post
			$post->{'nav'} = 
				$self->render_category_navigation(
					$MainCategory, $post->{'category'});
			$post->{'breadcrumb'} = $self->render_breadcrumb($MainCategory, $post->{'category'}, $post);
			
			$post->{'path'} = '../';
			
			my $outfile = $PostsDirectory.'/'.to_filename($post->{'title'}).'.html';
			print "writing $outfile\n";
			write_file($outfile, $self->fill_template($post->{'template'}, $post));
		});

	#-------------------------------------------------------------------------------
	# build category pages

	unless (-d $CategoriesDirectory) {
		mkdir($CategoriesDirectory) 
			or die "failed to create directory '$CategoriesDirectory': $!\n";
	}

	$self->map_objects_of_type(
		'category', sub {
			my ($cat) = @_;
			
			# find posts of that category
			my @posts;
			$self->map_objects_of_type(
				'post', sub {
					my ($post) = @_;
					push @posts, $post
						if $post->{'category'}->{'_id_'} eq $cat->{'_id_'} ||
						   $self->is_in_category($cat, $post->{'category'});
				}, 'date');
			
			my $albums = $self->render_albums_in_category($cat);
			
			$cat->{'nav'} = $self->render_category_navigation($MainCategory, $cat);
			$cat->{'breadcrumb'} = $self->render_breadcrumb($MainCategory, $cat);
			$cat->{'path'} = '../';
			$cat->{'content'} =
				'<h1 class="subcategories-title"><b>'.$cat->{'title'}.'</b></h1>'.
				# links to all posts in that category
				(scalar @posts ? 
					'<ol class="subcategories">'.
					join('', map { 
						$_->{'url'} = '../posts/'.to_filename($_->{'title'}).'.html';
						'<li>'.$self->fill_template($PostTeaserTemplate, $_).'</li>';
					} @posts).
					'</ol>' 
						: '<p><i>Nothing in this category, yet.</i>').
				# photo albums
				(length $albums ?
					'<h1>Photo albums</h1>'.
					$albums
						: '');
			
			my $outfile = $CategoriesDirectory.'/'.to_filename($cat->{'title'}).'.html';
			print "writing $outfile\n";
			write_file($outfile, $self->fill_template($CategoryPageTemplate, $cat));		
		});
		
	return 1;
}

#-------------------------------------------------------------------------------
sub has_unresolved_references
{
	my ($self) = @_;
	foreach my $id (keys %{$self->{'Objects'}}) {
		foreach my $key (keys %{$self->{'Objects'}->{$id}}) {
			my $value = $self->{'Objects'}->{$id}->{$key};
			return 1
				if ref $value eq 'HASH' && exists $value->{'_ref_'};
		}
	}
	return 0;
}

#-------------------------------------------------------------------------------
sub resolve_object_references
{
	my ($self, $id) = @_;
	#dmp($id);
	foreach my $key (keys %{$self->{'Objects'}->{$id}}) {
		#dmp(' - '.$key);
		my $value = $self->{'Objects'}->{$id}->{$key};
		if (ref $value eq 'ARRAY') {
			# list of objects
			foreach my $num (0..scalar(@{$value})-1) {
				if (ref $value->[$num] eq 'HASH' && exists $value->[$num]->{'_ref_'}) {
					#dmp(' --- '.$num);
					#print "$id / $key / $num\n";
					$self->_resolve_object_reference($id, $key, $num);
				}
			}
		}
		elsif (ref $value eq 'HASH' && exists $value->{'_ref_'}) {
			#print "$id / $key\n";
			# reference to object
			$self->_resolve_object_reference($id, $key);
		}		
	}
	
	sub _resolve_object_reference
	{
		my ($self, $id, $key, $num) = @_;
		my $value = (defined $num ? $self->{'Objects'}->{$id}->{$key}->[$num] : $self->{'Objects'}->{$id}->{$key});
		#dmp($value);
		if (defined $num) {
			die "could not find referenced object with id '".$value->{'_ref_'}."'.\n"
				unless exists $self->{'Objects'}->{$value->{'_ref_'}};
			$self->{'Objects'}->{$id}->{$key}->[$num] = $self->{'Objects'}->{$value->{'_ref_'}};
		} else {
			die "could not find referenced object with id '".$value->{'_ref_'}."'.\n"
				unless exists $self->{'Objects'}->{$value->{'_ref_'}};
			$self->{'Objects'}->{$id}->{$key} = $self->{'Objects'}->{$value->{'_ref_'}};
		}
	}
}

#-------------------------------------------------------------------------------
sub render_albums_in_category
{
	my ($self, $cat) = @_;
	my $s = '';
	$self->map_objects_of_type(
		'album', sub {
			my ($album) = @_;
			if ($album->{'category'}->{'_id_'} eq $cat->{'_id_'} ||
				$self->is_in_category($cat, $album->{'category'})) {
				
				$s .= '<li>'.$self->render_album($album).'</li>';
			}
		}, 'date');
	return (length $s ? '<ol>'.$s.'</ol>' : '');
}

#-------------------------------------------------------------------------------
sub render_album
{
	my ($self, $album) = @_;
	my $s = '';
	# find images in album
	my $first = 1;
	$album->{'firstimage'} = '';
	$album->{'restimages'} = '';
	foreach my $img (@{$album->{'images'}}) {
		$img->{'path'} = '../';
		$img->{'albumname'} = '['.$album->{'title'}.']';
		if ($first) {
			$album->{'thumbnail'}->{'path'} = '../';
			my $first = {
				'path' => $img->{'path'},
				'file' => $img->{'file'},
				'albumname' => '['.$album->{'title'}.']',
				'title' => $self->fill_template($self->{'Objects'}->{'tmpl-Image'}, $album->{'thumbnail'}),
				'description' => $album->{'description'},
				'date' => $album->{'date'},
			};
			$album->{'firstimage'} = $self->fill_template($self->{'Objects'}->{'tmpl-AlbumImage'}, $first);
		} else {
			$album->{'restimages'} .= $self->fill_template($self->{'Objects'}->{'tmpl-AlbumImageNoName'}, $img);					
		}
		$first = 0;
	}			
	$s .= $self->fill_template($self->{'Objects'}->{'tmpl-Album'}, $album);
	return $s;
}

#-------------------------------------------------------------------------------
sub map_objects_of_type
{
	my ($self, $type, $function, $order_by) = @_;
	foreach my $id 
		(reverse
		 map { $_->{'_id_'} } 
		 sort { (defined $order_by && defined $a->{$order_by} && defined $b->{$order_by} ? 
					($a->{$order_by} cmp $b->{$order_by}) : 0) } 
		 values %{$self->{'Objects'}}) {
		 
		my $object = $self->{'Objects'}->{$id};
		if ($object->{'_type_'} eq $type) {
			$function->($object);
		}
	}
}

#-------------------------------------------------------------------------------
sub render_breadcrumb
{
	my ($self, $top_category, $current_category, $post) = @_;
	
	my ($crumbs, $last_link) = $self->_render_breadcrumb($top_category, $current_category);
	my $home_link = '../posts/'.to_filename($self->{'Objects'}->{'Home'}->{'title'}).'.html';
	my $post_link = (defined $post ? '../posts/'.to_filename($post->{'title'}).'.html' : '');
	my $s = 
		'<ul>'.
			'<li class="text">You are here:</li>'.
			($home_link ne $last_link ?
				'<li><a href="../posts/'.to_filename($self->{'Objects'}->{'Home'}->{'title'}).'.html">'.
					$self->{'Objects'}->{'Home'}->{'title'}.
				'</a></li>' : '').
			$crumbs.
			(defined $post && $post_link ne $last_link ?
				'<li><a href="'.$post_link.'">'.
					$post->{'title'}.
				'</a></li>' : '').
		'</ul>';
	
	sub _render_breadcrumb
	{
		my ($self, $top_category, $current_category) = @_;
		
		my $s = '';
		my $last_link = '';
		if (exists $top_category->{'subcategories'}) {
			my @subs = @{$top_category->{'subcategories'}};
			foreach my $item (@subs) {
				if ($self->is_in_category($item, $current_category) ||
					$item->{'_id_'} eq $current_category->{'_id_'}) {
					
					$last_link = 
						(exists $item->{'targetpost'} ? 
							'../posts/'.to_filename($item->{'targetpost'}->{'title'}): 
							'../categories/'.to_filename($item->{'title'})).'.html';
					$s .=
						'<li>'.
							'<a href="'.$last_link.'">'.
								$item->{'title'}.
							'</a> '.
						'</li>';
				}
			}
		}
		return ($s, $last_link);
	}
}

#-------------------------------------------------------------------------------
sub render_category_navigation
{
	my ($self, $top_category, $current_category) = @_;
	#dmp($top_category);
	my $s = '';
	if (exists $top_category->{'subcategories'}) {
		my @subs = @{$top_category->{'subcategories'}};
		$s = (scalar @subs ? '<ul>' : '');
		foreach my $item (@subs) {
			#dmp($item);
			my $current = 
				$self->is_in_category($item, $current_category) ||
				$item->{'_id_'} eq $current_category->{'_id_'};
			#print $item->{'_id_'}." ($current)\n";
			$s .=
				'<li '.($current ? 'class="current"' : '').'>'.
					'<a href="'.
						(exists $item->{'targetpost'} ? 
							'../posts/'.to_filename($item->{'targetpost'}->{'title'}): 
							'../categories/'.to_filename($item->{'title'})).
						'.html">'.
						$item->{'title'}.
					'</a> '.
					$self->render_category_navigation($self->{'Objects'}->{$item->{'_id_'}}, $current_category).
				'</li>';				
		}
		$s .= (scalar @subs ? '</ul>' : '');
	}
	#dmp($s);
	return $s;
}

#-------------------------------------------------------------------------------
sub is_in_category
{
	my ($self, $cat, $current_cat) = @_;
	if (exists $cat->{'subcategories'}) {
		# check subcats
		return scalar(grep { $self->is_in_category($_, $current_cat) } @{$cat->{'subcategories'}});
	}
	else {
		if ($cat->{'_id_'} eq $current_cat->{'_id_'}) {
			return 1;
		} else {
			return 0;
		}
	}
}

#-------------------------------------------------------------------------------
sub to_filename
{
	my ($s) = @_;
	$s =~ s/[\n\r]/ /g;
	$s =~ s/[\s\t]+/ /g;
	$s =~ s/\s/-/g;
	$s =~ s/[^a-zA-Z0-9\-\.\_]//g;
	return $s;
}

#-------------------------------------------------------------------------------
sub dmp
{
	print Dumper(@_);
}

sub render_sound
{
	my ($self, $sound) = @_;
	return
		'<div class="sound">'.
		'<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" '.
			'codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0" '.
			'width="165" height="38" id="niftyPlayer1" align="">'.
			'<param name=movie value="../niftyplayer.swf?file=../'.$sound->{'file'}.'&as=1">'.
			'<param name=quality value=high>'.
			'<param name=bgcolor value=#FFFFFF>'.
			'<embed src="../niftyplayer.swf?file=../'.$sound->{'file'}.'&as=0" '.
				'quality=high bgcolor=#FFFFFF width="165" height="38" '.
				'name="niftyPlayer1" align="" type="application/x-shockwave-flash" '.
				'pluginspage="http://www.macromedia.com/go/getflashplayer">'.
			'</embed>'.
		'</object>'.
			'<p><emph>'.$sound->{'title'}.'</emph> by '.
				(length $sound->{'artist'} ? '<b>'.$sound->{'artist'}.'</b>' : 'unknown').'</p>'.
		'</div>';
}

#-------------------------------------------------------------------------------
sub fill_template
{
	my ($self, $tmpl_object, $data_object) = @_;
	my $s = $tmpl_object->{'content'};
	
	foreach my $key (keys %{$data_object}) {
		my $value = $data_object->{$key};
		if (!ref $value) {
			my $k = quotemeta $key;
			$s =~ s/\[$k\]/$value/g;
		}
	}
	
	# replace embedded objects
	while ($s =~ /\[\#([a-zA-Z0-9\.\-\_]+)\]/) {
		my $id = $1;
		if (exists $self->{'Objects'}->{$id}) {
			my $object = $self->{'Objects'}->{$id};
			my $value = '';
			if ($object->{'_type_'} eq 'album') {
				$value = $self->render_album($object);
			}
			elsif ($object->{'_type_'} eq 'category') {
				$value = '<a href="../categories/'.to_filename($object->{'title'}).'.html">'.$object->{'title'}.'</a>';
			}
			elsif ($object->{'_type_'} eq 'post') {
				$value = '<a href="../posts/'.to_filename($object->{'title'}).'.html">'.$object->{'title'}.'</a>';
			}
			elsif ($object->{'_type_'} eq 'image') {
				$value = $self->fill_template($self->{'Objects'}->{'tmpl-Image'}, $object);
			}
			elsif ($object->{'_type_'} eq 'sound') {
				$value = $self->render_sound($object);
			}
			$s =~ s/\[\#$id\]/$value/g;
		}
	}
	
	# replace empty undefined placeholders with empty string
	$s =~ s/\[\#?[a-zA-Z0-9\.\-\_]+\]//g;
	return $s;
}

#-------------------------------------------------------------------------------
sub create_object
{
	my ($self, $astobj, $objects) = @_;
	if (ref $astobj->[0] eq 'ARRAY') {
		# list of objects
		return [ map { $self->create_object($_, $objects) } @{$astobj} ];
	}
	else {
		# single object
		my ($asttype, @parts) = @{$astobj};
		
		if ($asttype eq 'object') {
			my ($objtype, $id, $hash) = @parts;	
			foreach my $key (keys %{$hash}) {
				$hash->{$key} = $self->create_object($hash->{$key}, $objects);
			}
			die "cannot redefine object with id '$id'.\n"
				if exists $objects->{$id};
			$hash->{'_type_'} = $objtype;
			$hash->{'_id_'} = $id;
			$objects->{$id} = $hash;
			return $objects->{$id};
		}
		elsif ($asttype eq 'string') {
			return $astobj->[1];
		}
		elsif ($asttype eq 'ref') {
			return {'_ref_' => $astobj->[1]};
		}
	}
}

#-------------------------------------------------------------------------------
sub read_file
{
	my ($filename) = @_;
	open(FILE, "<$filename") || die "failed to read file '$filename': $!\n";
	my $content = join '', <FILE>;
	close FILE;
	return $content;
}

#-------------------------------------------------------------------------------
sub write_file
{
	my ($filename, $string) = @_;
	open(FILE, ">$filename") || die "failed to write to file '$filename': $!\n";
	print FILE $string;
	close FILE;
}

1;
__END__
=head1 NAME

WWW::Offline::Toolkit - Perl module for offline website creation.

=head1 SYNOPSIS

	my $kit = 
		WWW::Offline::Toolkit->new(
			'DataDirectory'   => './data',
			'OnlineDirectory' => './online',
			'IndexFile'       => './online/index.html',

			'MainCategoryId'         => 'cat-Main',
			'PostsDirectory'         => './online/posts',
			'CategoriesDirectory'    => './online/categories',
			'CategoryPageTemplateId' => 'tmpl-Main',
			'PostTeaserTemplateId'   => 'tmpl-Teaser',
			'ImageTemplateId'        => 'tmpl-Image',
		);

	$kit->process;

=head1 DESCRIPTION

WWW::Offline::Toolkit provides a way of creating a website
offline (aka bunch of XHTML files) based on a set of assets
that are defined using a custom lisp-like text format.

Assets like pages, posts, categories, images, albums and
sounds are supported.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Nothing to mention here, yet.

=head1 AUTHOR

Tom Kirchner, E<lt>tom@tomkirchner.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Tom Kirchner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
