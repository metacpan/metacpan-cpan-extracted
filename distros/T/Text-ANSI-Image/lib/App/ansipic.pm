package App::ansipic;

our $VERSION = "0.02";

use v5.16;
use warnings;
use open IO => 'utf8', ':std';
use Pod::Usage;
use Getopt::EX::Long qw(:DEFAULT Configure ExConfigure);
use Getopt::EX::RPN qw(rpn_calc);
use Text::ANSI::Image;

use Exporter 'import';
our @EXPORT_OK = qw(ansipic);

# The command as a function: it takes the arguments, and returns the
# status, 0, 1 when a file is not shown, or 2 for an error.  It does
# not exit, so that Command::Run can call it without a fork.
sub ansipic {
    # in a variable, the object is gone when it returns: Getopt::EX::Hashed
    # dies for a new object while another is there
    my $app = __PACKAGE__->new;
    $app->perform(@_);
}

use Getopt::EX::Hashed 'has'; {
    Getopt::EX::Hashed->configure(DEFAULT => [ is => 'rw' ]);
    has method  => ' m =s ' , default => 'auto';
    has width   => ' w =s ' ;
    has height  => ' H =s ' ;
    has types   => ' t =s ' ;
    has term    => '   =s ' ;
    has tty     => '   =s ' ;
    has help    => ' h    ' ;
    has version => ' v    ' ;
} no Getopt::EX::Hashed;

sub perform {
    my $app = shift;
    local @ARGV = @_;
    ExConfigure BASECLASS => [ __PACKAGE__, 'Getopt::EX' ];
    Configure qw(bundling no_ignore_case);
    $app->getopt or return usage();
    # --help and --version do not exit, as a function must not
    if ($app->help) {
	# the manual is in the script; called as a function, $0 may not be
	# a file, and the module has a manual too
	pod2usage(-exitval => 'NOEXIT', -verbose => 99, -sections => [ qw(SYNOPSIS VERSION) ],
		  -input => -f $0 ? $0 : $INC{'App/ansipic.pm'});
	return 0;
    }
    if ($app->version) {
	say "ansipic $VERSION";
	return 0;
    }
    @ARGV or return usage();
    my $img = eval { $app->image } // do {
	warn "ansipic: ", $@ =~ s/ at .* line \d+.*//sr =~ s/\n*\z/\n/r;
	return 2;
    };
    my $status = 0;
    for my $file (@ARGV) {
	my @rows = $img->rows($file);
	unless (@rows) {
	    warn "ansipic: $file: " . (-e $file ? 'not shown' : 'not found') . "\n";
	    $status = 1;
	    next;
	}
	# the image goes to the terminal before the cells which show it
	$img->flush;
	print "$_\n" for @rows;
    }
    $status;
}

sub usage {
    warn "Usage: ansipic [options] file ...\n";
    2;
}

# The object of Text::ANSI::Image for the options.  It dies for an
# error.
sub image {
    my $app = shift;
    # --width and --height: a number, or an RPN expression which starts
    # with the width or the height of the terminal, as 2/ for the half
    my($tcols, $trows) = Text::ANSI::Image->terminal($app->term);
    for ([ width => $tcols ], [ height => $trows ]) {
	my($name, $init) = @$_;
	my $val = $app->$name // next;
	$val =~ s/^=//;		# -w=2/, as ansifold takes it
	if ($val !~ /\D/) { $app->$name = $val; next }
	defined $init or die "--$name $val: the size of the terminal is not known\n";
	my $n = rpn_calc($init, $val) // die "--$name $val: invalid expression\n";
	$app->$name = int $n;
    }
    my @types;
    if (defined $app->types) {
	@types = split /,/, $app->types;
	for my $t (@types) {
	    grep { $_ eq $t } @Text::ANSI::Image::TYPES
		or die "unknown type: $t (@{[ join ', ', @Text::ANSI::Image::TYPES ]})\n";
	}
    }
    Text::ANSI::Image->new(
	method => $app->method,
	@types ? (types => \@types) : (),
	defined $app->height ? (rows => $app->height) : (),
	map { defined $app->$_ ? ($_ => $app->$_) : () } qw(width term tty),
    ) // die "no method for this terminal: give one with --method\n";
}

1;

__END__

=encoding utf-8

=head1 NAME

App::ansipic - show images in the terminal as lines of text

=head1 SYNOPSIS

    use App::ansipic qw(ansipic);
    my $status = ansipic('-w', '2/', 'logo.png');

    use Command::Run;
    my $out = Command::Run->new(
        command => [ \&App::ansipic::ansipic, 'logo.png' ],
        nofork  => 1,
    )->run->{data};

=head1 DESCRIPTION

The command L<ansipic> as a function.  B<ansipic> takes the arguments
of the command, prints the rows of the images to the standard output,
and returns the status: 0, 1 when a file is not shown, and 2 for an
error.  It does not exit, even for B<--help> and B<--version>.
L<Command::Run> does not take the value: the status of a function it
runs is 0, unless the function dies.

=head1 SEE ALSO

L<ansipic>, L<Text::ANSI::Image>, L<Command::Run>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
