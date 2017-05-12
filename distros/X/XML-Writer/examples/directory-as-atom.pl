#!/usr/bin/perl -w

# A full example that presents a directory as an Atom feed
# It demonstrates namespace and formatting control.
# Intended to productise the /junk convention.

# Usage: directory-as-atom.pl <local directory> <public URL> [feed title] [feed subtitle]

# e.g., directory-as-atom.pl /home/user/public_html/junk http://www.example.com/~user/junk/ >index.atom

use strict;

use DirHandle;
use URI::URL;
use DateTime;

use XML::Writer;

my ($dir, $base, $title, $subtitle) = @ARGV;

defined($base) or die "Usage: directory-as-atom.pl <local directory> <public URL> [feed title] [feed subtitle]";

$dir ||= '.';

$title ||= '/junk/';
$subtitle ||= 'ls -ltr $dir | head -10';


my $uid = (stat($dir))[4];

my $dh = DirHandle->new($dir) || die "Unable to opendir $dir: $!";

my @de;

while(my $e = $dh->read()) {
	# Skip dotfiles
	next if ($e =~ /^\./);

	my $n = "$dir/$e";

	next unless (-f $n);

	my ($mtime, $bytes) = (stat($n))[9,7];

	my $desc; # undef, for now

	if (defined($mtime)) {push(@de, [$e, $mtime, $desc, $bytes])};
}

undef($dh);

# Sort into reverse date order...
@de = sort {
	$b->[1] <=> $a->[1];
} @de;

# ...take the most recent ten
if (@de > 10) {
	@de = @de[0..9];
}

# Constants for the namespace URIs
my $ATOM = 'http://www.w3.org/2005/Atom';
my $HTML = 'http://www.w3.org/1999/xhtml';
my $XML = 'http://www.w3.org/XML/1998/namespace';

sub toIsoDate($)
{
	my $t = shift;

	my $d = DateTime->from_epoch(epoch => $t);
	$d->set_time_zone('UTC');

	return $d->iso8601 . "Z";
}

my $w = XML::Writer->new(
	# Use namespaces
	NAMESPACES => 1,
	
	# Write in data mode, with indentation
	DATA_MODE => 1, DATA_INDENT => 1,

	# Use specific namespace prefixes
	PREFIX_MAP => {$ATOM => '', $HTML => 'html'},

	# Force an xmlns:html declaration on the root element
	FORCED_NS_DECLS => [$HTML],

	# Encode text as UTF-8
	ENCODING => 'utf-8'
);

$base = URI::URL->new($base)->abs;

my $feedUrl = URI::URL->new('index.atom', $base);

$w->xmlDecl();

# Start the root element with an xml:base declaration
$w->startTag([$ATOM, 'feed'], [$XML, 'base'] => $base);

$w->dataElement([$ATOM, 'id'], $feedUrl->abs);

# Mandatory Atom feed elements
$w->dataElement([$ATOM, 'title'], $title);
$w->dataElement([$ATOM, 'subtitle'], $subtitle);
$w->dataElement('generator', 'Old-skool directory-based CMS');
$w->emptyTag('link', 'rel' => 'self', 'href' => $feedUrl) if $feedUrl;
$w->dataElement([$ATOM, 'updated'] => toIsoDate(time));

# Find out the directory owner's name
if (my ($name) = (getpwuid($uid))[0]) {
	$w->startTag([$ATOM, 'author']);
	$w->dataElement([$ATOM, 'name'], $name);
	$w->endTag([$ATOM, 'author']);
}

# Write an entry for each file
foreach (@de) {
	my ($n, $mtime, $desc, $bytes) = @{$_};

	my $url = url($n, $base)->abs->as_string;

	$w->startTag([$ATOM, 'entry']);

	$w->dataElement([$ATOM, 'title'], $n);
	$w->dataElement([$ATOM, 'id'], $url);
	$w->emptyTag([$ATOM, 'link'], 'href' => $n);
	$w->dataElement([$ATOM, 'updated'], toIsoDate($mtime));

	# Write atom:content as XHTML; turn off data mode
	#  to control whitespace inside the html:div element
	$w->startTag([$ATOM, 'content'], 'type' => 'xhtml');
	$w->startTag([$HTML, 'div']);
	$w->setDataMode(0);
	$w->dataElement([$HTML, 'code'], $n);
	$w->characters(" - ${bytes} bytes");
	$w->characters(" - ${desc}") if $desc;
	$w->setDataMode(1);
	$w->endTag([$HTML, 'div']);
	$w->endTag([$ATOM, 'content']);

	$w->endTag([$ATOM, 'entry']);
}

$w->endTag([$ATOM, 'feed']);
$w->end();
