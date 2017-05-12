package ENH::Messages;


my %Catalog =  (
	amh => {
		_name		=>  "emarNa",
		advertisements	=>  "mastaweqiyawoc",
		headlines	=>  "yezEna erstoc",
		magazines	=>  "meSHEtoc",
		calendars	=>  "yeityoPya qen meqWuTeriyawoc",
		ourchurches	=>  "bEtekrstiyanocacn",
		archives	=>  "senedoc mawCa",
		specialfeatures	=>  "lyu `Itm",
		africannews	=>  "yeefrika zEna",
		worldnews	=>  "yeelem zEna",
		athiopianparliament => "yeityoPya parlama",
		number		=> "qWu",
		java		=> "yejava",
		web		=> "yewEb",
		africa		=> "efrika",
		# newspaperlibrary	=> "yegazETa mawCa",
		# library"	=> `abeyt yeityoPya zEnawoc mawCa",
		# monthlibrary	=> "yeweru mawCa",
	},
	gez => {
		_name		=>  "g`Iz",
		advertisements	=>  "mastaweqiyatat",
		headlines	=>  "erIsete zEna",
		magazines	=>  "meSHEtat",
		calendars	=>  "Hesabe - me`alt zeityoPya",
		ourchurches	=>  "bEte - krstiyanat",
		archives	=>  "mewS'E mezgeb",
		specialfeatures	=>  "fluy Htmet",
		africannews	=>  "zEna efriqa",
		worldnews	=>  "zEna `alem",
		athiopianparliament => "parlama zeityoPya",
		number		=> "qWu",
		java		=> "zejava",
		web		=> "zewEb",
		africa		=> "efriqa",
	},
	tir => {
		_name		=>  "tgrNa",
		advertisements	=>  "mastaweqiyatat",
		headlines	=>  "nay zEna ArIstat",
		magazines	=>  "meSHEtat",
		ourchurches	=>  "bEte - Krstiyanatna",
		calendars	=>  "nay ityoPya me`alti meqWSeri",
		archives	=>  "senedat mewS'i",
		specialfeatures	=>  "fluy Htam",
		africannews	=>  "nay Afrika zEna",
		worldnews	=>  "nay `alem zEna",
		athiopianparliament => "nay ityoPya parlama",
		number		=> "qWu",
		java		=> "nay java",
		web		=> "nay wEb",
		africa		=> "afrika",
	},

);


sub mapTerms
{
my $file = shift;

	open (FILE, "$file");
	my $data = join ( "", <FILE> );
	close (FILE);

	foreach ( keys %Catalog ) {
		my $lang = $_;
		my $ldata = $data;
		my $lfile = $file;
		$lfile =~ s/\./.$lang./;

		foreach ( keys %{$Catalog{$lang}} ) {
			$ldata =~ s/%%$_%%/$Catalog{$lang}{$_}/g;
		}

		open (LFILE, ">$lfile");
		print LFILE $ldata;
		close (LFILE);
	}

}


sub MakeHTML
{
print<<TOP;
<html>
<head>
  <title>ENH Message Catalog</title>
</head>
<body bgcolor="#fffffh">
<h1 align="center">ENH Message Catalog</h1>
<div align="center">
<table border>
  <tr bgcolor="#bfbfbf">
TOP
	foreach ( sort keys %Catalog ) {
		print "    <th><sera>$Catalog{$_}{_name}</sera></th>\n";
	}
	print "  </tr>\n";

	foreach ( sort keys %{$Catalog{amh}} ) {
		next if /_name/;
		my $key = $_;
		print "  <tr>\n";
		foreach ( sort keys %Catalog ) {
			print "    <td><sera>$Catalog{$_}{$key}</sera></td>\n";
		}
		print "  </tr>\n";
	}


print<<BOTTOM;
</table>
</div>
</body>
</html>
BOTTOM
}


1;

__END__
