
use strict;
use warnings;
use Test::More;
use Test::Tk;
$mwclass = 'Tk::AppWindow';
my @iconpath = ('t/Themes');
require Tk::NoteBook;
require Tk::LabFrame;
use Module::Load::Conditional('check_install', 'can_load');

use Config;
my $osname = $Config{'osname'};

BEGIN { use_ok('Tk::AppWindow::Ext::Art') };

createapp(
	-extensions => ['Art'],
	-iconpath => \@iconpath,
	-icontheme =>  'png_1',
);

my $art;
my $notebook;
my %pages = ();
my %testicons = (
	png_1 => [ 'accessories-text-editor', 'document-new', 'document-save', 'edit-cut', 'edit-find',
			'help-browser', 'multimedia-volume-control', 'system-file-manager'],
	png_2 => ['arrow-down', 'arrow-left', 'arrow-left-double', 'arrow-up-double',
			'call-start', 'checkbox', 'gwenview', 'inkscape'],
	svg_1 => ['adjustrgb', 'align-horizontal-left-out', 'align-horizontal-left',
			'kate', 'utilities-terminal', 'vlc'],
);

if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$art = $app->extGet('Art');
	$notebook = $app->NoteBook->pack(-fill => 'both');
	$pages{22} = $notebook->add(22, -label => 22);
	$pages{32} = $notebook->add(32, -label => 32);
}

push @tests, [sub { return $art->Name }, 'Art', 'extension Art loaded'];

push @tests, [sub {
	my @t = $art->AvailableThemes;
	return \@t
}, [ 'png_1', 'png_2', 'svg_1' ], 'Available themes'];

push @tests, [sub {
	my @i = $art->AvailableIcons('png_1');
	return \@i
}, [ 'accessories-text-editor', 'document-new', 'document-save', 'edit-cut', 'edit-find',
			'help-browser', 'multimedia-volume-control', 'system-file-manager' ], 'All available icons'];

push @tests, [sub {
	my @i = $art->AvailableIcons('png_1', 32);
	return \@i
}, [ 'accessories-text-editor', 'edit-cut', 'edit-find', 'help-browser' ], 'All available icons in size'];

push @tests, [sub {
	my @i = $art->AvailableIcons('png_1', 45);
	return \@i
}, [ ], 'No available icons in size'];

push @tests, [sub {
	my @i = $art->AvailableIcons('png_1', 32, 'Actions');
	return \@i
}, [ 'edit-cut', 'edit-find' ], 'All available icons in size and context'];

push @tests, [sub {
	my @i = $art->AvailableIcons('png_1', 45, 'Actions');
	return \@i
}, [  ], 'No available icons in size and context 1'];

push @tests, [sub {
	my @i = $art->AvailableIcons('png_1', 32, 'Blobber');
	return \@i
}, [  ], 'No available icons in size and context 2'];

push @tests, [sub {
	my @i = $art->AvailableIcons('png_1', undef, 'Actions');
	return \@i
}, [ 'document-new', 'document-save', 'edit-cut', 'edit-find' ], 'All available icons in context'];

push @tests, [sub {
	my @i = $art->AvailableIcons('png_1', undef, 'Blobber');
	return \@i
}, [  ], 'No available icons in context'];

push @tests, [sub {
	my @s = $art->AvailableSizes('png_1',);
	return \@s
}, [ 22, 32 ], 'Available sizes'];

push @tests, [sub {
	my @s = $art->AvailableSizes('png_1','edit-cut');
	return \@s
}, [ 32 ], 'Available sizes in name'];

push @tests, [sub {
	my @s = $art->AvailableSizes('png_1','does-not-exist');
	return \@s
}, [ ], 'No available sizes in name'];

push @tests, [sub {
	my @s = $art->AvailableSizes('png_1','edit-cut', 'Actions');
	return \@s
}, [ 32 ], 'Available sizes in name and context'];

push @tests, [sub {
	my @s = $art->AvailableSizes('png_1','does-not-exist', 'Actions');
	return \@s
}, [ ], 'No available sizes in name and context 1'];

push @tests, [sub {
	my @s = $art->AvailableSizes('png_1','edit-cut', 'Blobber');
	return \@s
}, [ ], 'No available sizes in name and context 2'];

push @tests, [sub {
	my @s = $art->AvailableSizes('png_1', undef, 'Actions');
	return \@s
}, [ 22, 32 ], 'Available sizes in context'];

push @tests, [sub {
	my @s = $art->AvailableSizes('png_1', undef, 'Blobber');
	return \@s
}, [ ], 'No available sizes in context'];

for (sort keys %pages) {
	my $size = $_;
	for ('png_1', 'png_2') {
		&CreateImgTests($_, $size);
	}
	my $modname = 'Image::LibRSVG';
	my $inst = check_install(module => $modname);
	if (defined $inst) {
		if (can_load(modules => {$modname => $inst->{'version'}})){
			&CreateImgTests('svg_1', $size);
		}
	}
}

starttesting;
my $num_of_tests = @tests + 3;
done_testing( $num_of_tests );

sub CreateImgTests {
	my ($theme, $size) = @_;
	my $f;
	push @tests, [sub {
		my $page = $pages{$size};
		$art->configPut(-icontheme => $theme);
		$f = $page->LabFrame(
			-label => $theme,
			-labelside => 'acrosstop',
		)->pack(-fill => 'both', -padx => 2, -pady => 2);
		return 1
	}, 1, "Setting theme $theme for size $size"];
	my $icons = $testicons{$theme};
	for (@$icons) {
		my $icon = $_;
		push @tests, [sub {
# 			print "Icon $icon in theme $theme\n";
			my $img = $art->getIcon($icon, $size);
			if (defined $img) {
				$f->Label(
					-image => $img,
				)->pack(-side => 'left', -padx => 2, -pady => 2);
				return 1
			}
			return 0
		}, 1, "Theme $theme, size $size, icon $icon"];
	}
}


