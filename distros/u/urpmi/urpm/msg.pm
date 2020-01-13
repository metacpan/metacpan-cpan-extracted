package urpm::msg;


use strict;
no warnings;
use Exporter;
use URPM;
use urpm::util 'append_to_file';

my $encoding;
BEGIN {
    eval { require encoding; $encoding = encoding::_get_locale_encoding() };
    eval "use open ':locale'" if $encoding && $encoding ne 'ANSI_X3.4-1968';
}

our @ISA = 'Exporter';
our @EXPORT = qw(N N_ P translate bug_log message_input toMb formatXiB sys_log);

#- I18N.
use Locale::gettext;
use POSIX ();
POSIX::setlocale(POSIX::LC_ALL(), "");
my @textdomains = qw(urpmi rpm-summary-main rpm-summary-contrib rpm-summary-devel);
foreach my $domain (@textdomains) {
	Locale::gettext::bind_textdomain_codeset($domain, 'UTF-8');
}
URPM::bind_rpm_textdomain_codeset();

our $no_translation;

sub from_locale_encoding {
    my ($s) = @_;
    $encoding && eval {
	require Encode;
	Encode::decode($encoding, $s);
    } || do { 
	require utf8;
	utf8::decode($s);
	$s;
    } || $s;
}

sub translate {
    my ($s, $o_plural, $o_nb) = @_;
    my $res;
    if ($no_translation) {
	$s;
    } elsif ($o_nb) {
        foreach my $domain (@textdomains) {
            eval { $res = Locale::gettext::dngettext($domain, $s || '', $o_plural, $o_nb) || $s };
            return $res if $s ne $res;
        }
        return $s;
    } else {
        foreach my $domain (@textdomains) {
            eval { $res = Locale::gettext::dgettext($domain, $s || '') || $s };
            return $res if $s ne $res;
        }
        return $s;
    }
}

sub P {
    my ($s_singular, $s_plural, $nb, @para) = @_; 
    sprintf(translate($s_singular, $s_plural, $nb), @para);
}

sub N {
    my ($format, @params) = @_;
    sprintf(translate($format), @params);
}
sub N_ { $_[0] }

my $noexpr = N("Nn");
my $yesexpr = N("Yy");

eval {
    require Sys::Syslog;
    Sys::Syslog->import;
    (my $tool = $0) =~ s!.*/!!;

    #- what we really want is "unix" (?)
    #- we really don't want "console" which forks/exit and thus
    #  run callbacks registered through atexit() : x11, gtk+, rpm, ...
    Sys::Syslog::setlogsock([ 'tcp', 'unix', 'stream' ]);

    openlog($tool, '', 'user');
    END { defined &closelog and closelog() }
};

sub sys_log { defined &syslog and eval { syslog("info", @_) } }

#- writes only to logfile, not to screen
sub bug_log {
    append_to_file($::logfile, @_) if $::logfile;
}

sub ask_yes_or_no {
    my ($msg) = @_;
    message_input($msg . N(" (y/N) "), boolean => 1) =~ /[$yesexpr]/;
}

sub message_input {
    my ($msg, %o_opts) = @_;
    _message_input($msg, undef, %o_opts);
}
sub _message_input {
    my ($msg, $o_default_input, %o_opts) = @_;
    my $input;
    while (1) {
	print $msg;
	if ($o_default_input) {
	    #- deprecated argument. don't you want to use $o_opts{default} instead?
	    $urpm::args::options{bug} and bug_log($o_default_input);
	    return $o_default_input;
	}
	$input = <STDIN>;
	defined $input or return undef;
	chomp $input;
	$urpm::args::options{bug} and bug_log($input);
	if ($o_opts{boolean}) {
	    $input =~ /^[$noexpr$yesexpr]?$/ and last;
	} elsif ($o_opts{range}) {
	    $input eq "" and $input = $o_opts{default} || 1; #- defaults to first choice
	    (defined $o_opts{range_min} ? $o_opts{range_min} : 1) <= $input && $input <= $o_opts{range} and last;
	} else {
	    last;
	}
	print N("Sorry, bad choice, try again\n");
    }
    return $input;
}

sub toMb {
    my $nb = $_[0] / 1024 / 1024;
    int $nb + 0.5;
}

my @format_line_field_sizes = (30, 12, 13, 7, 0);
my $format_line_format = '  ' . join(' ', map { '%-' . $_ . 's' } @format_line_field_sizes);

sub format_line_selected_packages {
    my ($urpm, $state, $pkgs) = @_;

    my (@pkgs, @lines, $prev_medium);
    my $flush = sub {
	push @lines, _format_line_selected_packages($state, $prev_medium, \@pkgs);
	@pkgs = ();
    };
    foreach my $pkg (@$pkgs) {
	my $medium = URPM::pkg2media($urpm->{media}, $pkg);
	if ($prev_medium && $prev_medium ne $medium) {
	    $flush->();
	}
	push @pkgs, $pkg;
	$prev_medium = $medium;
    }
    $flush->();

    (sprintf($format_line_format, N("Package"), N("Version"), N("Release"), N("Arch")),
     @lines);
}
sub _format_line_selected_packages {
    my ($state, $medium, $pkgs) = @_;

    my @l = map {
	my @name_and_evr = $_->fullname;
	if ($state->{selected}{$_->id}{recommended}) {
	    push @name_and_evr, N("(recommended)");
	}
	\@name_and_evr;
    } sort { $a->name cmp $b->name } @$pkgs;

    my $i;
    foreach my $max (@format_line_field_sizes) { 
	foreach (@l) {
	    if ($max && length($_->[$i]) > $max) {
		$_->[$i] = substr($_->[$i], 0, $max-1) . '>';
	    }
	}
	$i++;
    }

    ('(' . ($medium ? N("medium \"%s\"", $medium->{name}) : N("command line")) . ')',
     map { sprintf($format_line_format, @$_) } @l);
}

# duplicated from svn+ssh://svn.mandriva.com/svn/soft/drakx/trunk/perl-install/common.pm
sub formatXiB {
    my ($newnb, $o_newbase) = @_;
    my $newbase = $o_newbase || 1;
    my ($nb, $base);
    my $decr = sub { 
	($nb, $base) = ($newnb, $newbase);
	$base >= 1024 ? ($newbase = $base / 1024) : ($newnb = $nb / 1024);
    };
    my $suffix;
    foreach (N("B"), N("KB"), N("MB"), N("GB"), N("TB")) {
	$decr->(); 
	if ($newnb < 1 && $newnb * $newbase < 1) {
	    $suffix = $_;
	    last;
	}
    }
    my $v = $nb * $base;
    my $s = $v < 10 && int(10 * $v - 10 * int($v));
    int($v) . ($s ? ".$s" : '') . ($suffix || N("TB"));
}

sub localtime2changelog { scalar(localtime($_[0])) =~ /(.*) \S+ (\d{4})$/ && "$1 $2" }

1;


=head1 NAME

urpm::msg - routines to prompt messages from the urpm* tools

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT

Copyright (C) 2000, 2001, 2002, 2003, 2004, 2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2020 Mageia

=cut
