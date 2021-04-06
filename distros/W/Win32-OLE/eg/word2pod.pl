use strict;
use Text::Wrap;
use Win32::OLE qw(in with);
use Win32::OLE::Const 'Microsoft Word';

die "Usage: perl word2pod.pl Documentation.doc" unless @ARGV == 1;
my $File = $ARGV[0];
$File = Win32::GetCwd() . "/$File" if $File !~ /^(\w:)?[\/\\]/;
die "File $ARGV[0] does not exist" unless -f $File;

my $Word = Win32::OLE->new('Word.Application', 'Quit')
  or die "Couldn't run Word";

my $Doc = $Word->Documents->Open($File);

# Cache the names of various styles
my %Style = (
   Heading1     => $Doc->Styles(wdStyleHeading1)->NameLocal,
   Heading2     => $Doc->Styles(wdStyleHeading2)->NameLocal,
   List         => $Doc->Styles(wdStyleList)->NameLocal,
   ListBullet   => $Doc->Styles(wdStyleListBullet)->NameLocal,
   ListContinue => $Doc->Styles(wdStyleListContinue)->NameLocal,
   ListNumber   => $Doc->Styles(wdStyleListNumber)->NameLocal,
   Normal       => $Doc->Styles(wdStyleNormal)->NameLocal,
   PlainText    => $Doc->Styles(wdStylePlainText)->NameLocal,
  );

# The following styles will not break list mode
my %ListStyle = map {$_ => 1} @Style{qw(List ListBullet ListContinue
					ListNumber PlainText)};

# We don't want to encode Bold/Italic/Code in headings or plaintext
foreach my $Style (wdStyleHeading1, wdStyleHeading2, wdStylePlainText) {
    with($Doc->Styles($Style)->Font,
	 Bold   => 0,
	 Italic => 0,
	 Name   => 'Times New Roman',
	);
}

# Translating the format on a char by char basis is just too slow through OLE.
# We use Words Search-and-Replace feature instead.
my $Search = $Doc->Content->Find;
my $Replace = $Search->Replacement;

$Search->Font->{Bold} = 1;
$Replace->{Text} = 'B<^&>';
$Search->Execute({Replace => wdReplaceAll});

$Search->Clearformatting;
$Search->Font->{Italic} = 1;
$Replace->{Text} = 'I<^&>';
$Search->Execute({Replace => wdReplaceAll});

$Search->Clearformatting;
$Replace->{Text} = 'C<^&>';
foreach my $FontName ('Courier', 'Courier New') {
    $Search->Font->{Name} = $FontName;
    $Search->Execute({Replace => wdReplaceAll});
}

my $EmptyLine = 1;
my $ListItem;

foreach my $Paragraph (in $Doc->Paragraphs) {
    my $Style = $Paragraph->Format->Style->NameLocal;
    # Remove trailing ^M (the paragraph marker) from Range
    my $Text = substr($Paragraph->Range->Text, 0, -1);

    if ($Style eq $Style{PlainText}) {
	$EmptyLine = scalar $Text =~ /^\s*$/;
	# Make sure plaintext starts with whitespace
	$Text = "\t$Text" unless $EmptyLine || $Text =~ /^\s/;
	print "$Text\n";
	next;
    }

    # Make sure previous plaintext block has a trailing empty line
    print "\n" unless $EmptyLine;
    $EmptyLine = 1;

    if (defined $ListItem && !$ListStyle{$Style}) {
	print "=back\n\n";
	undef $ListItem;
    }

    if ($Style eq $Style{Heading1}) {
	print "=head1 $Text\n\n";
    }
    elsif ($Style eq $Style{Heading2}) {
	print "=head2 $Text\n\n";
    }
    elsif ($ListStyle{$Style} && $Style ne $Style{ListContinue}) {
	unless (defined $ListItem) {
	    print "=over 4\n\n";
	    $ListItem = 0;
	}

	my $Bullet = '';
	$Bullet = '* ' if $Style eq $Style{ListBullet};
	$Bullet = sprintf "%d. ", ++$ListItem if $Style eq $Style{ListNumber};
	print "=item $Bullet$Text\n\n";
    }
    else {
	printf "%s\n\n", wrap('', '', $Text);
    }
}

$Doc->{Saved} = 1;
$Doc->Close;
