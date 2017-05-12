%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
%#
%#		$m->comp('/dir.mc',
%#			include => '^\d\d\d\d$',
%#			columns => ['icon', 'description'],
%#			title => undef,
%#			nobackurl => 1,
%#
%#			description => sub {
%#				my $file = shift;
%#				$file =~ s|^.*/([^/]+)$|$1|;
%#				return "Folder description for $file";
%#			},
%#
%#		);
%#
%# include, exclude: array ref to regex
%#
%# columns => ['icon', 'name', 'size', 'modified', 'description'],
%#
%# title: Title for the directory. Defaults to dir name
%#
%# nobackurl => 1 Do not show link to parent directory
%#
%# description: ref to hash or sub (hash with absolute filenames, fullname pass to
%# sub as first argument
%#
%# sortcode => sub { $a <=> $b } - sorting method
%#
%#----------------------------------------------------------------------------
<%perl>
	my %files;
	my $counter;

	my $phys_path = $r->filename;
  if ( -f $phys_path ) {
    $phys_path =~ s|^(.*)/[^/]*|$1|;    # remove filename part
  }

	my $uri_path = $r->uri;
	$uri_path =~ s|^(.*)/[^/]*|$1|;		# remove filename part

	# Add system names to exclude list
	push @exclude, qw/\.mc$ \.htaccess \.htfolder/;

	if (!opendir(DIR, $phys_path)) {
		</%perl>
		<h2><% pick_lang(
					rus => "Не могу прочитать каталог: ",
          eng => "Cannot read directory: " )
					%><% $uri_path %></h2>
		<%perl>
		return;
	}

	FILE: while(my $file = readdir DIR) {           # @METAGS readdir_DIR
		next if $file =~ /^\./;

		if ((! -d "$phys_path/$file") and scalar @include) {

			my $included = 0;
			foreach my $pat (@include) {
				if ($file =~ /$pat/i) {
					$included = 1;
					last;
				}
			}
			next FILE unless $included;
		}
		if (scalar @exclude) {
			my $excluded = 0;
			foreach my $pat (@exclude) {
				if ($file =~ /$pat/i) {
					$excluded = 1;
					last;
				}
			}
			next FILE if $excluded;
		}

		my $icon = 'generic.gif';
		$icon = "dir.gif" if -d "$phys_path/$file";
		if ($file =~ /\.doc$/oi) {
			$icon = "word.gif";
		} elsif ($file =~ /\.xl?$/oi) {
			$icon = "excel.gif";
		}

		my ($size, $modified) = (stat("$phys_path/$file"))[7,9];
		my @ltime = CORE::localtime($modified);
		$files{$file} = {
      name => cstocs($ePortal->disk_charset, 'WIN', $file),
			size => $size,
			modified => sprintf("%02d.%02d.%04d %02d:%02d:%02d",
				$ltime[3], $ltime[4]+1, $ltime[5]+1900, (@ltime)[2,1,0] ),

      url =>  (join '/', (map {escape_uri($_)} split '/',("$uri_path/$file"))) .
							(-d "$phys_path/$file"? "/" : undef),

			icon => $icon,

			description =>
				(ref($description) eq 'HASH' ?
          $description->{cstocs($ePortal->disk_charset, 'WIN', $file)} :
					(ref($description) eq 'CODE' ?
						&$description("$phys_path/$file", $file) :
						'')),
		};
	}
	closedir DIR;

	my $back_url = $uri_path;
	$back_url =~ s|/([^/]+)$||;
  $back_url = join('/', (map {escape_uri($_)} split '/',($back_url))) . "/";
	$files{".."} = {
		name => pick_lang(rus => '[Шаг назад]', eng => '[Back]'),
		size => 0,
		modified => '',
		url => $back_url,
		icon => 'back.gif',
		description => pick_lang(rus => 'Вернуться к пред.каталогу', eng => 'Go to parent directory'),
		};

	# @METAGS Columns
	my %column_name = (
		icon => '&nbsp;',
		name => pick_lang(rus => 'Имя', eng => 'Name'),
		size => pick_lang(rus => 'Размер', eng => 'Size'),
		modified => pick_lang(rus => 'Изменен', eng => 'Changed'),
		description => pick_lang(rus => 'Описание', eng => 'Description') );

	if ($title eq 'default') {
    $title = pick_lang(rus => "Каталог: ", eng => "Directory: ") .
      cstocs($ePortal->disk_charset,'WIN', $uri_path);
	}
</%perl>

%	if ($title) {
	<h2><% $title %></h2>
% }

	<table border=0 width="100%" cellspacing=0 cellpadding=0 class="<% $class %>">
		<tr bgcolor="#cdcdcd">
%			foreach (@columns) {
				<td><b><% $column_name{$_} %></b></td>
%			}
		</tr>


%		foreach my $file ('..', $sortcode ? sort $sortcode keys %files : sort keys %files) {
%			next if ($nobackurl and $file eq '..');
%			$nobackurl = 1 if ($file eq '..');

			<tr bgcolor="<% $counter++ % 2 == 0? '#FFFFFF' : '#eeeeee' %>">
%				foreach (@columns) {
          <td valign="top"<% /size/ ? ' align="right"' : undef %>>
%					if (/icon/o) {
						<a href="<% $files{$file}{url} %>"><% img( src => "/images/icons/" . $files{$file}{icon} ) %></a>
%					} elsif (/name/o) {
						<a href="<% $files{$file}{url} %>"><% $files{$file}{name} %></a>
%					} elsif (/size/o) {
						<a href="<% $files{$file}{url} %>"><% $files{$file}{size} %></a>
%					} elsif (/modified/o) {
						<a href="<% $files{$file}{url} %>"><% $files{$file}{modified} %></a>
%					} elsif (/description/o) {
						<a href="<% $files{$file}{url} %>"><% $files{$file}{description} %></a>
%					}
					</td>
%				}
			</tr>
% 	}

		<tr bgcolor="#cdcdcd">
%				foreach (@columns) {
					<td>&nbsp;</td>
%				}
		</tr>
	</table>
	<p>

<!-- r->filename <% $r->filename %> -->
<!-- phys_path: <% $phys_path %> -->
<!-- dhandler_arg: <% $m->dhandler_arg %> -->
%return;






%#============================================================================
<%args>
@include => ()		# regex to include names
@exclude => ()		# regex to exclude names
@columns => qw/icon name size modified description/
$description => undef		# hash or sub
$title => 'default'	# Directory title
$sortcode => undef		# Sorting method
$nobackurl => undef		# Do not show back url
$class => undef
</%args>
