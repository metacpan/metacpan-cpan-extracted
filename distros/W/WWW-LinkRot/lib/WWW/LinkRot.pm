package WWW::LinkRot;
use warnings;
use strict;
use Carp;
use utf8;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/
    check_links
    get_links
    html_report
    replace
/;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use LWP::UserAgent;
use HTML::Make;
use HTML::Make::Page 'make_page';
use File::Slurper qw!read_text write_text!;
use JSON::Create 'write_json';
use JSON::Parse 'read_json';
use Convert::Moji 'make_regex';

our $VERSION = '0.01';

sub get_links
{
    my ($files) = @_;
    my %links;
    for my $file (@$files) {
	if (! -f $file) {
	    carp "Can't find file '$file'";
	    next;
	}
	my $text = read_text ($file);
	# Remove comments so that commented-out links don't appear in
	# the results.
	$text =~ s/<!--.*?-->//gsm;
	while ($text =~ /href=["'](.*?)["']/g) {
	    my $link = $1;
	    push @{$links{$link}}, $file; 
	}
    }
    return \%links;
}

sub check_links
{
    my ($links, %options) = @_;
    my $out = $options{out};
    my $verbose = $options{verbose};
    my $nook = $options{nook};
    my $tempfile = "$out-temp.json";
    my %skip;
    my $ua = LWP::UserAgent->new (
	agent => __PACKAGE__,
    );
    $ua->max_redirect (0);
    # Time out after five seconds (dead sites etc.)
    $ua->timeout (5);

    if (-f $out) {
	my $old = read_json ($out);
	for my $link (@$old) {
	    if ($link->{status} =~ /200/) {
		$skip{$link->{link}} = $link;
	    }
	}
    }
    my $count = 0;
    my @checks;
    for my $link (sort keys %$links) {
    if ($nook) {
	if ($skip{$link}) {
	    if ($verbose) {
		print "$link was OK last time, skipping\n";
	    }
	    # Keep a copy of this link in the output.
	    push @checks, $skip{$link};
	    next;
	}
    }
	my %r = (
	    link => $link,
	    files => $links->{$link},
	);
	if ($verbose) {
	    print "Getting $link...\n";
	}
	my $res = $ua->get ($link);
	$r{status} = $res->status_line ();
	if ($r{status} =~ m!^30[12]!) {
	    $r{location} = $res->header ('location');
	}
	push @checks, \%r;
	$count++;
	if ($count % 5 == 0) {
	    write_json ($tempfile, \@checks, indent => 1, sort => 1);
	}
    }
    unlink ($tempfile) or carp "Error unlinking $tempfile: $!";
    write_json ($out, \@checks, indent => 1, sort => 1);
}

sub html_report
{
    my (%options) = @_;
    my $links = read_json ($options{in});
    my $title = $options{title};
    if (! $title) {
	$title = 'WWW::LinkRot link report';
    }
    my $style = <<EOF;
.error {
    background: gold;
}

.moved {
    background: pink;
}
EOF
    my ($html, $body) = make_page (
	title => $title,
	style => $style,
    );
    $body->push ('h1', text => $title);
    my $table = $body->push ('table');
    for my $xlink (@$links) {
	my $status = $xlink->{status};
	my $class = 'OK';
	if ($status =~ /30.*/) {
	    $class = 'moved';
	}
	elsif ($status =~ /^[45].*/) {
	    $class = 'error';
	}
	my $row = $table->push ('tr', class => $class,);
	my $link = $row->push ('td');
	my $text = $xlink->{link};
	if (length ($text) > 100) {
	    $text = substr ($text, 0, 100);
	}
	my $h = $xlink->{link};
	$link->push (
	    'a',
	    attr => {
		target => '_blank',
		href => $h,
	    },
	    text => $text,
	);
	my $archive = "https://web.archive.org/web/*/$h";
	$link->push (
	    'a',
	    attr => {
		href => $archive,
		target => '_blank',
	    },
	    text => '[archive]',
	);
	my $statcell = $row->push ('td', text => $xlink->{status});
	if ($class eq 'moved') {
	    my $loc = $xlink->{location};
	    if ($loc) {
		my $hs = $h;
		$hs =~ s!http!https!;
		if ($hs eq $loc) {
		    $statcell->add_text (' (HTTPS)');
		}
		else {
		    $statcell->push ('a', href => $loc, text => $loc);
		}
	    }
	}
	my $files = $row->push ('td');
	my $filelist = $xlink->{files};
	if ($filelist) {
	    my $nfiles = scalar (@$filelist);
	    my $maxfiles = $nfiles;
	    if ($nfiles > 5) {
		$maxfiles = 5;
	    }
	    my $filen = 0;
	    for my $file (@$filelist) {
		$filen++;
		if ($filen > $maxfiles) {
		    last;
		}
		if ($options{strip}) {
		    $file =~ s!$options{strip}!!;
		}
		my $href = "$options{url}/$file";
		$files->push (
		    'a',
		    attr => {target => '_blank', href => $href},
		    text => $file
		);
	    }
	}
    }
    write_text ($options{out}, $html->text ());
}

sub replace
{
    my ($links, $files) = @_;
    my @moved;
    for my $l (keys %$links) {
#	print "$l\n";
	my $link = $links->{$l};
	if ($link->{status} =~ m!^30! && $link->{location}) {
	    push @moved, $l;
#	    print "$l\n";
	}
    }
#    print "@moved\n";
    my $re = make_regex (@moved);
#    print "$re\n";
    for my $file (@$files) {
	my $text = read_text ($file);
	if ($text =~ s!($re)!$links->{$1}{location}!g) {
	    print "$file changed $1 $links->{$1}{location}\n";
	    write_text ($file, $text);
	}
	else {
#	    print "$file unchanged\n";
	}
    }
}

1;
