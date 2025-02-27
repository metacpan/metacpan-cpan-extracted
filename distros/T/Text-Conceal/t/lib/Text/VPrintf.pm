package Text::VPrintf;

use v5.14;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT_OK = qw(&vprintf &vsprintf);

use Data::Dumper;
use Text::Conceal;
use Text::VisualWidth::PP qw(vwidth);

sub vprintf  { &printf (@_) }
sub vsprintf { &sprintf(@_) }

my %default = (
    test      => qr/[\e\b\P{ASCII}]/,
    length    => \&vwidth,
    ordered   => 0,
    duplicate => 1,
);

sub configure {
    %default = (%default, @_);
}

sub sprintf {
    my($format, @args) = @_;
    my $conceal = Text::Conceal->new(
	%default,
	except    => $format,
	max       => int @args,
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

1;

__END__
