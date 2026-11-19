######################################################################
# 9032-meta_prereqs.t  Prerequisites declared in META.yml / META.json
#
# mb-0.67 as first built declared "v5.44", "feature" and "experimental"
# as test prerequisites.  They came from example source kept in
# here-documents of t/5010_perl544.t ("use v5.44;" and
# "use feature 'enhanced_xx';" at column zero), which the prerequisite
# scanner of pmake.bat 0.52 took for real "use" statements.  "v5.44" is
# no module at all, "experimental" needs perl 5.010, and "feature" is
# not on CPAN, so no CPAN client could have satisfied them on the perls
# this distribution supports.
#
# pmake.bat dist writes META before it runs this suite, so this test
# aborts a dist that would declare such a prerequisite again.
#
#   M1-M2   META.yml / META.json are readable
#   M3-M4   every prerequisite name is a package name (not a version)
#   M5-M6   every required (not recommended) module is core in 5.005_03
#   M7      "feature", "experimental" and "vN..." are never declared
#   M8      META.yml and META.json declare the same modules
#   M9      every required module loads on this perl
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin;
use vars qw($VERSION @test); $VERSION = $VERSION;

my $root = "$FindBin::Bin/..";

# modules shipped with perl 5.005_03 that a distribution of ina@CPAN may
# require; a module outside of this list cannot be required, because
# META says "perl 5.00503" and a CPAN client must then be able to
# install it there
my %core_5005 = map { $_ => 1 } qw(
    AutoLoader Benchmark Carp Config Cwd Data::Dumper DirHandle Exporter
    ExtUtils::MakeMaker Fcntl File::Basename File::Compare File::Copy
    File::Find File::Path File::Spec FileHandle FindBin Getopt::Long
    Getopt::Std IO IO::File IO::Handle IPC::Open2 IPC::Open3 POSIX
    SelectSaver Symbol Sys::Hostname Test Test::Harness Text::ParseWords
    Text::Wrap Time::Local constant integer lib overload strict vars
);

sub slurp {
    my($file) = @_;
    local $/ = undef;
    local *FH;
    open(FH, $file) or return undef;
    my $text = <FH>;
    close(FH);
    return $text;
}

# ($required, $recommended) of META.yml: hash refs of name => version
sub yml_prereqs {
    my($yml) = @_;
    my %required    = ();
    my %recommended = ();
    my $phase = '';
    for my $line (split /\r?\n/, $yml) {
        if ($line =~ /\A([A-Za-z_]+):/) {
            $phase = $1;
        }
        elsif ($line =~ /\A\s+(\S+)\s*:\s*(\S+)\s*\z/) {
            my($name, $version) = ($1, $2);
            if ($phase =~ /\A(?:requires|build_requires|configure_requires|test_requires)\z/) {
                $required{$name} = $version;
            }
            elsif ($phase eq 'recommends') {
                $recommended{$name} = $version;
            }
        }
    }
    return ({ %required }, { %recommended });
}

# ($required, $recommended) of META.json: hash refs of name => version
sub json_prereqs {
    my($json) = @_;
    my %required    = ();
    my %recommended = ();
    if ($json =~ /"prereqs"\s*:\s*\{(.*?)\n    \}/s) {
        my $prereqs = $1;
        while ($prereqs =~ /"(requires|recommends|suggests)"\s*:\s*\{([^{}]*)\}/g) {
            my $relation = $1;
            my $list     = $2;
            while ($list =~ /"([^"]+)"\s*:\s*"([^"]*)"/g) {
                if ($relation eq 'requires') {
                    $required{$1} = $2;
                }
                else {
                    $recommended{$1} = $2;
                }
            }
        }
    }
    return ({ %required }, { %recommended });
}

sub bad_names {
    my(@name) = @_;
    return grep { ($_ ne 'perl') and not /\A[A-Za-z_][A-Za-z_0-9]*(?:::[A-Za-z_0-9]+)*\z/ } @name;
}

sub not_core {
    my(@name) = @_;
    return grep { ($_ ne 'perl') and not $core_5005{$_} } @name;
}

sub report {
    my(@name) = @_;
    print "# unexpected: @name\n" if @name;
    return @name ? 0 : 1;
}

my $yml  = slurp("$root/META.yml");
my $json = slurp("$root/META.json");
my($yml_req,  $yml_rec)  = yml_prereqs(defined($yml)  ? $yml  : '');
my($json_req, $json_rec) = json_prereqs(defined($json) ? $json : '');

@test = (
    # M1-M2
    sub { defined($yml)  and (scalar(keys %{$yml_req})  > 0) },
    sub { defined($json) and (scalar(keys %{$json_req}) > 0) },

    # M3-M4
    sub { report(bad_names(sort(keys(%{$yml_req}),  keys(%{$yml_rec})))) },
    sub { report(bad_names(sort(keys(%{$json_req}), keys(%{$json_rec})))) },

    # M5-M6
    sub { report(not_core(sort keys %{$yml_req})) },
    sub { report(not_core(sort keys %{$json_req})) },

    # M7
    sub {
        report(sort grep { /\A(?:feature|experimental|v[0-9].*|[0-9].*)\z/ }
            keys(%{$yml_req}), keys(%{$yml_rec}), keys(%{$json_req}), keys(%{$json_rec}));
    },

    # M8
    sub {
        my $y = join ' ', sort(keys(%{$yml_req}),  keys(%{$yml_rec}));
        my $j = join ' ', sort(keys(%{$json_req}), keys(%{$json_rec}));
        print "# META.yml : $y\n# META.json: $j\n" if $y ne $j;
        ($y eq $j) ? 1 : 0;
    },

    # M9
    sub {
        my @fail = ();
        for my $module (sort keys %{$json_req}) {
            next if $module eq 'perl';
            next if bad_names($module);
            push @fail, $module unless eval "require $module; 1";
        }
        report(@fail);
    },
);

print "1..", scalar(@test), "\n";
my $testno = 1;
for my $test (@test) {
    print $test->() ? "ok $testno\n" : "not ok $testno\n";
    $testno++;
}

__END__
