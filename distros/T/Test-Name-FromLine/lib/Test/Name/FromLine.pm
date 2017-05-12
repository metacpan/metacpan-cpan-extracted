package Test::Name::FromLine;

use strict;
use warnings;

our $VERSION = '0.13';

use Test::Builder;
use File::Slurp;
use File::Spec;
use Cwd qw(getcwd);

our $BASE_DIR = getcwd();
our %filecache;

no warnings 'redefine';
my $ORIGINAL_ok = \&Test::Builder::ok;
*Test::Builder::ok = sub {
	@_ = @_; # for pass and fail
	$_[2] = do {
		my ($package, $filename, $line) = caller($Test::Builder::Level);
		undef $filename if $filename && $filename eq '-e';
		if ($filename) {
			$filename = File::Spec->rel2abs($filename, $BASE_DIR);
			my $file = $filecache{$filename} ||= [ read_file($filename) ];
			my $lnum = $line;
			$line = $file->[$lnum-1];
			$line =~ s{^\s+|\s+$}{}g;
			if ($_[2]) {
				"L$lnum: $_[2]";
			} else {
				"L$lnum: $line";
			}
		} else {
			""; # invalid $Test::Builder::Level
		}
	};
	goto &$ORIGINAL_ok;
};


1;
__END__

=encoding utf8

=head1 NAME

Test::Name::FromLine - Auto fill test names from caller line

=head1 SYNOPSIS

  use Test::Name::FromLine; # just use this
  use Test::More;

  is 1, 1; #=> ok 1 - L3: is 1, 1;

  done_testing;


=head1 DESCRIPTION

Test::Name::FromLine is test utility that fills test names from its file.
Just use this module in test and this module fill test names to all test except named one.

=head1 AUTHOR

cho45 E<lt>cho45@lowreal.netE<gt>

=head1 SEE ALSO

This is inspired from L<http://subtech.g.hatena.ne.jp/motemen/20101214/1292316676>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
