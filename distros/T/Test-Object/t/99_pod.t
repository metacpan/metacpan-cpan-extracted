#!/use/bin/perl

use Test::More;

# Skip developer testing except for during automated testing
unless ( $ENV{AUTOMATED_TESTING} ) {
	plan skip_all => "Skipping module author tests";
	exit(0);
}

# Try to load Test::Pod
eval "use Test::Pod 1.00";
if ( $@ ) {
	plan skip_all => "Test::Pod 1.00 required for testing POD";
	exit(0);
}





#####################################################################
# WARNING: INSANE BLACK MAGIC
#####################################################################

# Hack Pod::Simple::BlackBox to ignore the Test::Inline "=begin has more than one word errors"
my $begin = \&Pod::Simple::BlackBox::_ponder_begin;
sub mybegin {
	my $para = $_[1];
	my $content = join ' ', splice @$para, 2;
	$content =~ s/^\s+//s;
	$content =~ s/\s+$//s;
	my @words = split /\s+/, $content;
	if ( $words[0] =~ /^test(?:ing)?\z/s ) {
		foreach ( 2 .. $#$para ) {
			$para->[$_] = '';
		}
		$para->[2] = $words[0];
	}

	# Continue as normal
	push @$para, @words;
	return &$begin(@_);
}

local $^W = 0;
*Pod::Simple::BlackBox::_ponder_begin = \&mybegin;

#####################################################################
# END BLACK MAGIC
#####################################################################

all_pod_files_ok();
