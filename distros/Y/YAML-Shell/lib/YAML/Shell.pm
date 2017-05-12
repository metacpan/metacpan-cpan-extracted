use strict; use warnings;
package YAML::Shell;
our $VERSION = '0.71';

use Term::ReadLine;
sub Term::ReadLine::Perl::Tie::FIRSTKEY {undef}
use Data::Dumper;
use Config;
$Data::Dumper::Indent = 1;
our $prompt = 'ysh > ';
my $round_trip = 0;
my $force = 0;
my $log = 0;
my $yaml_module = 'YAML::Any';
my $yaml_version;
$| = 1;
my $sh;

sub run {
    my $class = shift;
    set_version($yaml_module);
    my @env_args = split /\s+/, ($ENV{YSH_OPT} || '');
    my @args = (@env_args, @_);
    my $stream = -t STDIN ? '' : join('', <STDIN>);
    while (my $arg = shift @args) {
        set_version($1), next if $arg =~ /^-M(.*)/;

        handle_help(), exit if $arg eq '-h';
        handle_version(), exit if $arg eq '-v';
        handle_Version(), exit if $arg eq '-V';

        $YAML::Indent = $1, next if $arg =~ /^-i(\d+)$/;
        $YAML::UseFold = 1, next if $arg eq '-uf';
        $YAML::UseBlock = 1, next if $arg eq '-ub';
        $YAML::UseCode = 1, next if $arg eq '-uc';
        $YAML::UseHeader = 0, next if $arg eq '-nh';
        $YAML::UseVersion = 0, next if $arg eq '-nv';
        $round_trip = 1, next if $arg eq '-r';
        $round_trip = 2, next if $arg eq '-R';
        $log = 1, next if $arg eq '-l';
        $log = 2, next if $arg eq '-L';
        $force = 1, next if $arg eq '-F';
        warn(<<END), exit 1;
Unknown YAML Shell argument: '$arg'.
For help, try: perldoc ysh
END
    }

    set_version($yaml_module);

    check_install() unless $force;

    if ($log) {
        if ($log == 2) {
            open LOGFILE, "> ./ysh.log" or die $!;
        }
        else {
            open LOGFILE, ">> ./ysh.log" or die $!;
        }
        no strict 'refs';
        my $version = ${"${yaml_module}::VERSION"};
        print LOGFILE "\n$yaml_module Version $version\n";
        print LOGFILE "Begin logging at ", scalar localtime, "\n\n";
    }

    if (not length($stream)) {
        Print(<<END);
Welcome to the YAML Test Shell (@{[ $class->implementation ]})

Type ':help' for more information.

END
    }

    {
        {
            local @ENV{qw(HOME EDITOR)};
            local $^W;
            $sh = Term::ReadLine::->new('The YAML Shell');
        }

        sub my_readline {
            print LOGFILE $prompt if $log;
            my $input = $sh->readline($prompt);
            if (not defined $input) {
                $input = ':exit';
                Print("\n");
            }
            $input .= "\n";
        }
    }

    if (length($stream)) {
        my @objects;
        no strict 'refs';
        eval { @objects = &{"${yaml_module}::Load"}($stream) };
        if ($@) {
            print STDERR $@;
            exit 1;
        }
        else {
            print STDOUT Data::Dumper::Dumper(@objects);
            exit 0;
        }
    }

    while ($_ = my_readline()) {
        print LOGFILE $_ if $log;
        next if /^\s*$/;
        exec('ysh', @ARGV) if /^\/$/;
        handle_command($_),next if /^:/;
        handle_file($1),next if /^<\s*(\S+)\s*$/;
        handle_yaml($_),next if /^--\S/;
        handle_yaml(''),next if /^===$/;
        handle_perl($_,1),next if /^;/;
        handle_perl($_,0),next;
        Print("Unknown command. Type ':help' for instructions.\n");
    }
}

sub set_version {
    my $module = shift;
    eval "require $module";
    die $@ if $@;
    $yaml_module = $module;
    no strict 'refs';
    $yaml_version = ${"${yaml_module}::VERSION"};
}

sub Print {
    print @_;
    print LOGFILE @_ if $log;
}
local $SIG{__WARN__} = sub { Print @_ };

sub handle_file {
    my ($file) = @_;
    my @objects;
    eval {
        no strict 'refs';
        @objects = &{"${yaml_module}::LoadFile"}($file)
    };
    if ($@) {
        Print $@;
    }
    else {
        Print Data::Dumper::Dumper(@objects);
    }
}

sub handle_perl {
    my ($perl, $multi) = @_;
    my (@objects, $yaml, $yaml2);
    local $prompt = 'perl> ';
    my $line = '';
    if ($multi) {
        while ($line !~ /^;$/) {
            $line = my_readline();
            print LOGFILE $line if $log;
            $perl .= $line;
        }
    }
    @objects = eval "no strict;$perl";
    Print("Bad Perl expression:\n$@"), return if $@;
    {
        no strict 'refs';
        eval { $yaml = &{"${yaml_module}::Dump"}(@objects) };
    }
    $@ =~ s/^ at.*\Z//sm if $@;
    Print("Dump failed:\n$@"), return if $@;
    Print $yaml;
    if ($round_trip) {
        {
            local $SIG{__WARN__} = sub {};
            no strict 'refs';
            eval { $yaml2 = &{"${yaml_module}::Dump"}(&{"${yaml_module}::Load"}($yaml)) };
        }
        $@ =~ s/^ at.*\Z//sm if $@;
        Print("Load failed:\n$@"), return if $@;
        if ($yaml eq $yaml2) {
            if ($round_trip > 1) {
                Print "\nData roundtripped OK!!!\n";
            }
        }
        else {
            Print "================\n";
            Print "after roundtrip:\n";
            Print "================\n";
            # $yaml2 =~ s/ /_/g;  #
            # $yaml2 =~ s/\n/+/g; #
            # Print $yaml2, "\n"; #
            Print $yaml2;
            Print "=========================\n";
            Print "Data did NOT roundtrip...\n";
        }
    }
}

sub handle_yaml {
    my $yaml = shift;
    my $line = $yaml;
    my (@objects);
    local $prompt = 'yaml> ';
    $line = my_readline();
    print LOGFILE $line if $log;
    $line = '' unless defined $line;
    while ($line !~ /^\.{3}$/) {
        $yaml .= $line;
        $line = my_readline();
        print LOGFILE $line if $log;
        last unless defined $line;
    }
    $yaml =~ s/\^{2,8}/\t/g;
    no strict 'refs';
    eval { @objects = &{"${yaml_module}::Load"}($yaml) };
    $@ =~ s/^ at.*\Z//sm if $@;
    $@ =~ s/^/  /gm if $@;
    Print("YAML Load Failed:\n$@"), return if $@;
    Print Data::Dumper::Dumper(@objects);
}

sub handle_command {
    my $line = shift;
    chomp $line;
    my ($cmd, $args);
    if ($line =~ /^:(\w+)\s*(.*)$/) {
        $cmd = $1;
        $args = $2;
        exit if $cmd =~ /^(exit|q(uit)?)$/;
        handle_help(),return if $cmd eq 'help';
        print `clear`,return if $cmd =~ /^c(lear)?$/;
    }
    Print "Invalid command\n";
}

sub handle_help {
    Print <<END;

       Welcome to the YAML Test Shell (@{[ __PACKAGE__->implementation ]})

   When you to type in Perl, you get back YAML. And vice versa.

   By default, every line you type is a one line Perl program, the return value
   of which will be displayed as YAML.

   To enter multi-line Perl code start the first line with ';' and use as many
   lines as needed. Terminate with a line containing just ';'.

   To enter YAML text, start with a valid YAML separator/header line which is
   typically '---'. Use '===' to indicate that there is no YAML header. Enter
   as many lines as needed. Terminate with a line containing just '...'.

   Shell Commands:             (Begin with ':')
      :exit or :q(uit) - leave the shell
      :help - get this help screen

END
}

sub implementation {
    my $module = $yaml_module;
    if ($yaml_module eq 'YAML::Any') {
        $module .= " -> " . YAML::Any->implementation;
    }
    return $module;
}

sub check_install {
    if (-f "./YAML.pm" && -f "./pm_to_blib" &&
        -M "./YAML.pm" <  -M "./pm_to_blib"
       ) {
        die "You need to 'make install'!\n";
    }
}

sub handle_version {
    print STDERR <<END;

ysh: '$VERSION'
${yaml_module}: '$yaml_version'

END
}

sub handle_Version {
    my $TRP = get_version('Term::ReadLine::Perl');
    my $TRG = get_version('Term::ReadLine::Gnu');
    my $POE = get_version('POE');
    my $TO = get_version('Time::Object');

    print STDERR <<END;

ysh: '$VERSION'
${yaml_module}: '$yaml_version'
perl: '$Config::Config{version}'
Data::Dumper: '$Data::Dumper::VERSION'
Term::ReadLine::Perl: '$TRP'
Term::ReadLine::Gnu: '$TRG'
POE: '$POE'
Time::Object: '$TO'

END
}

sub get_version {
    my ($module) = @_;
    my $version;
    eval "no strict; use $module; \$version = \$${module}::VERSION";
    #$version = "$@" if $@;
    $version = "not installed" if $@;
    return $version;
}

1;
