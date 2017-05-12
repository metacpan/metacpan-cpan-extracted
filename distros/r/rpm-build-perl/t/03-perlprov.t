use Test::More qw(no_plan);
use strict;

use Config qw(%Config);
use Fcntl qw(F_SETFD);

sub spawn ($) {
	my $file = shift;
	open my $pipe, "-|", $^X, qw(-Mblib perl.prov) => $file
		or return (undef, undef);
	my $output = join '' => <$pipe>;
	return (close($pipe), $output);
}

sub grok ($) {
	my $file = shift;
	fcntl(STDERR, F_SETFD, 1);
	my ($ok, $output) = spawn($file);
	if (not $ok) {
		fcntl(STDERR, F_SETFD, 0);
		spawn($file);
	}
	chomp $output;
	$output =~ s/\s+/ /g;
	return $output;
}

sub Provides ($$) {
	my ($f, $expected) = @_;
	require $f;
	my $got = grok $INC{$f};
	like $got, qr/^\Q$expected\E(\d|$)/, "$f dependencies";
	ok $? == 0, "$f zero exit status";
}

my ($lib, $arch) = @Config{qw{installprivlib installarchlib}};

# Valid for perl-5.8.0 - perl-5.16.1.
Provides "attributes.pm"	=> "perl(attributes.pm) = 0.";
Provides "AutoLoader.pm"	=> "perl(AutoLoader.pm) = 5.";
Provides "base.pm"		=> "perl(base.pm) = ";
Provides "constant.pm"		=> "perl(constant.pm) = 1.";
Provides "Exporter.pm"		=> "perl(Exporter.pm) = 5.";
Provides "fields.pm"		=> "perl(fields.pm) = ";
Provides "File/Basename.pm" 	=> "perl(File/Basename.pm) = 2.";
Provides "Getopt/Long.pm"	=> "perl(Getopt/Long.pm) = 2.";
Provides "dumpvar.pl"		=> "perl(dumpvar.pl)";
Provides "Cwd.pm"		=> "perl(Cwd.pm) = ";
Provides "Data/Dumper.pm"	=> "perl(Data/Dumper.pm) = 2.";
Provides "IO/File.pm"		=> "perl(IO/File.pm) = 1.";
Provides "File/Glob.pm"		=> "perl(File/Glob.pm) = ";
Provides "Socket.pm"		=> "perl(Socket.pm) = ";
Provides "POSIX.pm"		=> "perl(POSIX.pm) = 1.";

