#!/usr/bin/perl
use strict;
use warnings;

use File::Slurp;
use Getopt::Long;
use IO::Handle;
use File::Basename;
use Term::Prompt;
use File::ShareDir qw(dist_dir);
use File::Path qw(make_path);
use Pod::Usage;
use Cwd 'abs_path';
STDERR->autoflush(1);
STDOUT->autoflush(1);

=head1 NAME

shopify-themer.pl - Supports the pushing and pulling of themes from a shopify store.

=head1 SYNOPSIS

shopify-themer.pl action [options]

	action		Action can be one of several things.
		
			info
			Spits out a bunch of theme information in JSON form.
			Mainly used for debugging, and gedit integration.

			pullAll
			Pulls all themes from the shop

			pushAll
			Pushes all assets from all themes.

			push <ID/Name>
			Pushes all assets from the specified theme.

			pull <ID/Name>
			Pulls all assets form the specified theme.
			
			activate <ID/Name>
			Sets the specified theme as the main theme.
			
			watch <ID/Name>
			Watches the specified folder for changes,
			and then pushes those changes when necessary.
			If an ID or name is specified, it only
			watches that folder.

			installGedit
			Checks for gedit on the system and then
			installs the appropriate plugin into
			the gedit configuration folder.
			
			interactive
			Causes the script to be interactive; useful if
			you want to do something non-transactional,
			like continuous interaction with gedit. Will
			drop to a command line, and await the above
			actions. To exit, type exit.
	
	--help		Displays this messaqge.
	--fullhelp	Displays the full pod doc.

	--wd		Sets the working directory to be something other
			than .
	--interval	Sets the interval of time that the 'watch' command
			checks files at. Default is 1 second.

	This following three parameters only need to be speciefied once
	per working directory, as it will be saved in a hidden file in
	that directory.

	--url		Sets the shop url.
	--api_key	Sets the api key of your private application.
	--email		Sets the email you want to log in with.
	--password	Either your private application's password when
			used with api_key, or your account's password
			when used with email.

=cut

=head1 DESCRIPTION

Shopify themer is a simple script which uses L<WWW::Shopify::Private> and
L<WWW::Shopify> to fetch themes and assets from a Shopify store. It is
meant to be used as either a standalone application, or integrated with
Gedit as a plugin. It also has the ability to fetch/push pages from the
Shopify store.

The gedit plugin is written in python, but ultimately is simply a wrapper
around this script. Currently, support is limited to those OSs which can
make symlinks and can install gedit. This means that it should also work
(experimentally) on Windows and Mac. The system is mainly tested on Linux,
so support for Linux is definitely higher priority than for other systmes.

Normally, you only have to specify the shop url, api key/email and password
once per working directory/site. Don't try and create multiple site themes
in the same directory as this is a _BAD_ _IDEA_. 

The Shopify shop is the ultimate arbitrator of what is the 'final' version
of a file; this makes good sense when multiple people are working on a shop,
but may be somewhat annoying. What this means, is that:

For pushing:
Files that are locally changed, and remotely not, will be pushed.
Files that are locally changed, and remotely changed, will not be pushed.
Files that are locally unchanged will only be pushed if the file is missing on the server.

For pulling:
Files that are locally and remotely changed will be overwritten locally, so keep an eye out for this.
Files that are locally not, and remotely chagned will be overritten locally.
Files that are not present locally and remotely present will be pulled.

=cut

use WWW::Shopify::Tools::Themer;

use JSON qw(encode_json decode_json);

my @ARGS = ();

my $settings = {directory => '.'};
my $interval = 1;
GetOptions(
	"url=s" => \$settings->{url},
	"api_key=s" => \$settings->{apikey},
	"password=s" => \$settings->{password},
	"email=s" => \$settings->{email},
	"wd=s" => \$settings->{directory},
	"help" => \my $help,
	"fullhelp" => \my $fullhelp,
	"interval" => \$interval,
	'<>' => sub { push(@ARGS, $_[0]); }
);

my $action = $ARGS[0];

pod2usage(-verbose => 2) if ($fullhelp);
pod2usage() if ($help || !defined $action);

if ($action eq 'installGedit') {
	die "You system doesn't support symlinks. Which is crazy. Still on XP, eh? (probably) Not supported, aborting install.\n" unless eval { symlink("", ""); 1; };

	sub prompt_directory {
		my ($directory) = @_;
		if (!-d $directory) {
			# We shoudln't need to create any folders in Windows; they should all be there.
			die "Can't find $directory, aborting install.\n" if ($^O =~ m/MSWin/i);
			print "No.\n";
			my $result = &prompt("y", "Would you like to create it?", undef, "y");
			if (!$result) {
				print "Aborting install.\n";
				exit(0);
			}
			make_path($directory);
		}
		else {
			print "Yes.\n";
		}
	}

	my $dist_directory = dist_dir('WWW-Shopify-Tools-Themer');
	my ($plugin_directory, $target_directory, $language_directory, $icon_directory);
	if ($^O !~ m/MSWin/i) {
		# *NIX Derivatives install, probably.
		die "Must have HOME environment variable defined; Sorry, automatic gedit installation isn't supported without this.\n" unless $ENV{'HOME'};
		print "Checking to see if gedit exists... ";
		`gedit --version`;
		die "Can't detect gedit.\n" unless $? == 0;
		print "Yes.\n";
		print "Checking to see if python exists... ";
		`python --version`;
		die "Can't detect python.\n" unless $? == 0;
		my $share_directory = $ENV{'HOME'} . "/.local/share";
		$plugin_directory = "$share_directory/gedit/plugins";
		$target_directory = "$plugin_directory/shopifyeditor";
		$language_directory = "$share_directory/gtksourceview-3.0";
		$icon_directory = "$share_directory/icons/hicolor/scalable/apps";
	}
	else {
		die "Can't find program files environment variable." unless $ENV{'PROGRAMFILES'};
		my $share_directory = $ENV{'PROGRAMFILES'} . "/gedit";
		if (!(-d $share_directory) && $ENV{'PROGRAMFILES(X86)'}) {
			$share_directory = $ENV{'PROGRAMFILES(X86)'} . "/gedit";
		}
		if (!-d $share_directory) {
			print "Can't find gedit directory in Program Files; enter it here: " unless -d $share_directory;
			$share_directory = <STDIN>;
		}
		die "Directory doesn't exist." unless -d $share_directory;
		$share_directory = "$share_directory/share";
		$plugin_directory = "$share_directory/plugins";
		$target_directory = "$plugin_directory/shopifyeditor";
		$language_directory = "$share_directory/gtksourceview-2.0";
		$icon_directory = "$share_directory/icons/hicolor/scalable/apps";
	}
	if (!-e $target_directory) {
		print "Checking for presence of gedit settings directory in $plugin_directory... ";
		prompt_directory($plugin_directory);
		print "Symlinking sharedir to directory... ";
		die "Can't symlink, for some reason.\n" if symlink($dist_directory, $target_directory) != 1;
		print "OK.\n";
	}
	if (!-e "$language_directory/language-specs") {
		print "Checking for presence of source view languages in $language_directory... ";
		prompt_directory($language_directory);
		print "Symlinking language dir to directory... ";
		die "Can't symlink for some reason.\n" if symlink("$dist_directory/languages", "$language_directory/language-specs") != 1;
		print "OK.\n";
	}
	if (!-e "$icon_directory") {
		print "Checking for presence of icon directory in $icon_directory... ";
		prompt_directory($icon_directory);
	}
	if (!-l "$icon_directory/shopify-icon.png") {
		print "Symlinking icon to directory... ";
		die "Can't symlink, for some reason.\n" if symlink("$dist_directory/shopify-icon.png", "$icon_directory/shopify-icon.png") != 1;
		print "OK.\n";
	}
	print "Done.\n";
	exit(0);
}

my ($settingFile, $manifestFile) = ($settings->{directory} . "/.shopsettings", $settings->{directory} . "/.shopmanifest");
my $filesettings = decode_json(read_file($settingFile)) if (-e $settingFile);
for (keys(%$filesettings)) { $settings->{$_} = $filesettings->{$_} unless defined $settings->{$_}; }
die "Please specify a --url, --apikey xor --email and --password when using for the first time.\n" unless defined $settings->{url} && defined $settings->{password} && (defined $settings->{apikey} xor defined $settings->{email});
my %saveSettings = map {  $_ => $settings->{$_} } grep { $_ ne "directory" } keys(%$settings);
write_file($settingFile, encode_json(\%saveSettings));

my $STC = new WWW::Shopify::Tools::Themer($settings);

use List::Util qw(first);
my $interactive = $action eq "interactive";

my %actions = (
	'info' => sub {
		my @themes = $STC->get_themes;
		print encode_json(int(@themes) > 0 ? \@themes : []) . "\n";
	},
	'pullAll' => sub {
		$STC->pull_all;
	},
	'pushAll' => sub {
		$STC->push_all;
	},
	'push_pages' => sub {
		$STC->push_pages;
	},
	'pull_pages' => sub {
		$STC->pull_pages;
	},
	'watch' => sub {
		use File::Find;
		my $theme = undef;
		if ($ARGS[1]) {
			if ($ARGS[1] =~ m/^\d+$/) {
				$theme = first { $_->{id} eq $ARGS[1] } @{$STC->manifest->{themes}};
			}
			else {
				$theme = first { $_->{name} eq $ARGS[1] } @{$STC->manifest->{themes}}
			}
		}
		die "Unable to find theme " . $ARGS[1] . "\n" unless $theme;
		print "Entering Check Loop for " . ($theme ? "theme " . $theme->{name} . " (" . $theme->{id} . ") " : "all themes ") . "...\n";
		my $directory = $theme ? $STC->directory . "/" . $STC->shop_url_truncated . "-" . $theme->{id} : $STC->directory;
		while (1) {
			my $should_push = 0;
			find({ wanted => sub {
				my ($file) = $_;
				$should_push = 1 if !$should_push && !-d $file && $file !~ m/\/\.[^\/]+$/ && $STC->manifest->has_local_changes($file);
			}, no_chdir => 1 }, $directory);
			if ($should_push) {
				print "Change detected. Pushing ...\n";
				if ($theme) {
					$STC->push(new WWW::Shopify::Model::Theme($theme));
				}
				else {
					$STC->push_all;
				}
				print "Done.\n";
			}
			sleep($interval);
		}
	},
	'push' => sub {
		die "Please specify a specific theme to push.\n" unless int(@ARGS) >= 2;
		my $theme = undef;
		if ($ARGS[1] =~ m/^\d+$/) {
			$theme = first { $_->{id} eq $ARGS[1] } @{$STC->manifest->{themes}};
		}
		else {
			$theme = first { $_->{name} eq $ARGS[1] } @{$STC->manifest->{themes}}
		}
		die "Unable to find theme " . $ARGS[1] . "\n" unless $theme;
		$STC->push(new WWW::Shopify::Model::Theme($theme));
	},
	'pull' => sub {
		die "Please specify a specific theme to pull.\n" unless int(@ARGS) >= 2;
		my $theme = undef;
		if ($ARGS[1] =~ m/^\d+$/) {
			$theme = first { $_->{id} eq $ARGS[1] } @{$STC->manifest->{themes}};
		}
		else {
			$theme = first { $_->{name} eq $ARGS[1] } @{$STC->manifest->{themes}}
		}
		die "Unable to find theme " . $ARGS[1] . "\n" unless $theme;
		$STC->pull(new WWW::Shopify::Model::Theme($theme));
	},
	'activate' => sub {
		die "Please specify a specific theme to pull.\n" unless int(@ARGS) >= 2;
		my $theme = undef;
		if ($ARGS[1] =~ m/^\d+$/) {
			$theme = first { $_->{id} eq $ARGS[1] } @{$STC->manifest->{themes}};
		}
		else {
			$theme = first { $_->{name} eq $ARGS[1] } @{$STC->manifest->{themes}}
		}
		die "Unable to find theme " . $ARGS[1] . "\n" unless $theme;
		$STC->activate(new WWW::Shopify::Model::Theme($theme));
	},
	'exit' => sub { $interactive = undef; }
);


do {
	if ($interactive) {
		$action = <STDIN>;
		chomp $action;
	}
	if (exists ($actions{$action})) {
		eval {
			$actions{$action}();
			print "Done.\n";
			$STC->manifest->save($manifestFile);
		};
		if (my $exception = $@) {
			print STDERR "Error: " . $STC->read_exception($exception) . "\n";
		}
	}
	else {
		print STDERR "Unknown action: $action.\n";
	}
} while ($interactive);

exit 0;


=head1 SEE ALSO

L<WWW::Shopify>, L<WWW::Shopify::Private>

=head1 AUTHOR

Adam Harrison (adamdharrison@gmail.com)

=head1 LICENSE

Copyright (C) 2013 Adam Harrison

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

