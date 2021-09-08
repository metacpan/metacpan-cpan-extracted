package Text::VPrintf;

use v5.14;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT_OK = qw(&vprintf &vsprintf);

use Data::Dumper;
use Text::Conceal;

sub vprintf  { &printf (@_) }
sub vsprintf { &sprintf(@_) }

sub sprintf {
    my($format, @args) = @_;
    my $conceal = Text::Conceal->new(
	except => $format,
	test   => qr/[\e\b\P{ASCII}]/,
	length => \&vwidth,
	max    => int @args,
	);
    $conceal->encode(@args) if $conceal;
    my $s = CORE::sprintf $format, @args;
    $conceal->decode($s)    if $conceal;
    $s;
}

sub printf {
    my $fh = ref($_[0]) =~ /^(?:GLOB|IO::)/ ? shift : select;
    $fh->print(&sprintf(@_));
}

sub IsWideSpacing {
    return <<"END";
+utf8::East_Asian_Width=Wide
+utf8::East_Asian_Width=FullWidth
-utf8::Nonspacing_Mark
END
}

sub vwidth {
    local $_ = shift;
    my $w;
    while (m{\G  (?:
		 (?<zero> \p{Nonspacing_Mark} )
	     |   (?<two>  \p{IsWideSpacing} )
	     |   \X
	     )
	}xg) {
	$w += $+{zero} ? 0 : $+{two} ? 2 : 1;
    }
    $w;
}

1;

__END__
