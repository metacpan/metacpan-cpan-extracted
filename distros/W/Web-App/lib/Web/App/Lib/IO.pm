package Web::App::Lib::IO;
# $Id: IO.pm,v 1.1 2009/03/29 10:12:26 apla Exp $

use strict;

use Imager;
use Image::Thumbnail;

use IO::Easy;
use IO::Easy::Dir;
use IO::Easy::File;

sub nodes {
	my $class  = shift;
	my $app    = shift;
	my $params = shift;
	
	my $place  = $params->{place} || 'htdocs';
	
	my $node = $app->request->params->param ('node') || '';
	
	return # bwahaha
		if $node =~ /\.\./;
	
	my $images_root = $app->root->append ($place, $node)->as_dir;
	
	my $list = [];
	
	foreach my $dir_item ($images_root->items) {
		my $name = $dir_item->name;
		my $type = $dir_item->type;
		$type = 'folder' if $type eq 'dir';
		
		next
			if $params->{'no-files'} and $type eq 'file';
		
		push @$list, {
			text => $name,
			id   => ($node eq '' ? '' : $node . '/') . $name,
			cls  => $type,
		};
		
		if ($type eq 'file') {
			$list->[-1]->{leaf} = 1;
			$list->[-1]->{extension} = $dir_item->extension;
		}
	}
	
	return $list;
}

sub file_contents {
	my $class  = shift;
	my $app    = shift;
	my $params = shift;
	
	my $place = $params->{place} || 'htdocs';
	
	my $node = $app->request->path_info;
	
	return # bwahaha
		if $node =~ /\.\./;
	
	my $contents = $app->root->append ($place, $node)->as_file->contents;
	
	return {
		contents => $contents,
		path => $node
	};
}

sub store_file {
	my $class  = shift;
	my $app    = shift;
	my $params = shift;
	
	my $place = $params->{place} || 'htdocs';
	my $entity = $params->{entity} || 'contents';
	my $type = $params->{type} || 'xml';
	
	my $node = $app->request->path_info;
	
	my $cgi = $app->request->params;
	my $path = $cgi->param ('doc-path');
	my $name = $cgi->param ('doc-name');
	my $cont = $cgi->param ('doc-contents');

	return # bwahaha
		if $node =~ /\.\./;
	
	my $file;
	if ($name ne '') {
		$file = $app->root->append ($place, $path, "$name.$type")->as_file;
	} else {
		$file = $app->root->append ($place, $path)->as_file;
	}
	
	$file->store ($cont);
	
	$app->var->{result} = 'ok';
	
	return;
}


sub document_files {
	my $class  = shift;
	my $app    = shift;
	my $params = shift;
	
	my $place = $params->{place} || 'htdocs';
	
	my $node = $app->request->params->param ('node') || '';
	
	return # bwahaha
		if $node =~ /\.\./;
	
	my $node_path = $app->root->append ($place, $node)->as_dir;
	
	my $list = [];
	
	foreach my $dir_item ($node_path->items ($params->{filter})) {
		my $name = $dir_item->name;
		my $type = $dir_item->type;
		
		next
			if $type eq 'dir';
		
		push @$list, {
			name   => $name,
			size   => $dir_item->size,
			mtime  => $dir_item->mtime,
			url  => '/' . ($node eq '' ? '' : $node . '/') . $name,
		};
		
	}
	
	return $list;
}

sub image_files {
	my $class  = shift;
	my $app    = shift;
	my $params = shift;
	
	my $place = $params->{place} || 'htdocs';
	
	my $node = $app->request->params->param ('node') || '';
	
	return # bwahaha
		if $node =~ /\.\./;
	
	my $images_root = $app->root->append ($place, $node)->as_dir;
	
	my $list = [];
	
	foreach my $dir_item ($images_root->items ($params->{filter})) {
		my $name = $dir_item->name;
		my $type = $dir_item->type;
		
		next
			if $type eq 'dir';
		
		next
			if $name =~ /^--/;
		
		my $thumb_file = $images_root->append ('--'.$name)->as_file;
		
		my $im = Imager->new;
		if (!$im->read (file => $dir_item->path)) {
			warn $im->errstr;
			next;
		}
		
		my ($w, $h) = ($im->getwidth, $im->getheight);
		
		my $small_dims = 0;
		$small_dims = 1
			if $w < 351 and $h < 351;
		
		if (! -f $thumb_file and ! $small_dims) {
			
			my $t = Image::Thumbnail->new (
				size       => 300,
				create     => 1,
				module     => 'Imager',
				quality    => '90',
				input      => $dir_item->path,
				outputpath => $thumb_file->path,
			);
		}
		
		my $uri_dir = '/' . ($node eq '' ? '' : $node . '/');
		
		push @$list, {
			name   => $name,
			size   => $dir_item->size,
			mtime  => $dir_item->mtime,
			width  => $w,
			height => $h,
			thumb_url => $uri_dir . ($small_dims ? '' : '--') . $name,
			image_url => $uri_dir . $name
		};
		
	}
	
	return $list;
	
}

sub make_dir {
	my $class  = shift;
	my $app    = shift;
	my $params = shift;
	
	my $place = $params->{place} || 'htdocs';
	my $entity = $params->{entity} || 'makeDir';
	
	my $cgi = $app->request->params;
	my $path = $cgi->param ('dir-path');
	my $name = $cgi->param ('dir-name');
	
	my $dir = $app->root->append ($place, $path, $name)->as_dir;
	
	if (-e $dir) {
		if (-d $dir) {
			$app->var->{$entity} = {result => 'ok', reason => 'already-exists'};
		} else {
			$app->var->{$entity} = {result => 'error', reason => 'not-a-dir'};
		}
	} else {
		$dir->create;
		$app->var->{$entity} = {result => 'ok'};
	}
	
	return;
	
}


sub upload {
	my $class  = shift;
	my $app    = shift;
	my $params = shift;
	
	my $dir = $params->{dir} || 'htdocs';
	
	my $req = $app->request;

	my $location = $req->param ('location');
	
	return # bwahaha
		if $location =~ /\.\./;
	
	my $file_contents = $req->param ('file');
	my $file_name = $req->params->param_filename ('file');

	my $file = $app->root->append ($dir, $location, $file_name)->as_file;

	$file->store ($file_contents);

	$app->var->{success} = 'true';

	return;
	
}


1;