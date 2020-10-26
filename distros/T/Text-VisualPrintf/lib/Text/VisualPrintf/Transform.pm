package Text::VisualPrintf::Transform;

use v5.14;
use warnings;
use utf8;
use Carp;
use Data::Dumper;
{
    no warnings 'redefine';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
    $Data::Dumper::Sortkey = 1;
}

my %default = (
    test   => undef,
    length => sub { length $_[0] },
    match  => qr/.+/s,
    except => '',
);

sub new {
    my $class = shift;
    my $obj = bless { %default }, $class;
    $obj->configure(@_) if @_;
    $obj;
}

sub configure {
    my $obj = shift;
    while (my($key, $value) = splice @_, 0, 2) {
	if (not exists $default{$key}) {
	    croak "$key: invalid parameter";
	}
	$obj->{$key} = $value;
    }
    $obj;
}

sub encode {
    my $obj = shift;
    $obj->{replace} = [];
    my $guard = $obj->guard_maker(0+@_, $obj->{except} // '', @_)
	or return @_;
    for my $arg (grep { defined } @_) {
	if (my $test = $obj->{test}) {
	    next unless ( ( ref $test eq 'Regexp' and $arg =~ $test ) or
			  ( ref $test eq 'CODE'   and $test->($arg) ) );
	}
	my $match = $obj->{match} or die;
	$arg =~ s{$obj->{match}}{
	    if (my($replace, $regex, $len) = $guard->(${^MATCH})) {
		push @{$obj->{replace}}, [ $regex, ${^MATCH}, $len ];
		$replace;
	    } else {
		${^MATCH};
	    }
	}pge;
    }
    @_;
}

sub decode {
    my $obj = shift;
    my @replace = @{$obj->{replace}};
  ARGS:
    for (@_) {
	for my $i (0 .. $#replace) {
	    my $ent = $replace[$i];
	    my($regex, $orig, $len) = @$ent;
	    # capture group is defined in $regex
	    if (s/$regex/_replace($1, $orig, $len)/e) {
		splice @replace, 0, $i + 1;
		redo ARGS;
	    }
	}
    }
    @_;
}

sub _replace {
    my($matched, $orig, $len) = @_;
    my $width = length $matched;
    if ($width == $len) {
	$orig;
    } else {
	_trim($orig, $width);
    }
}

sub _trim {
    my($str, $width) = @_;
    use Text::ANSI::Fold;
    state $f = Text::ANSI::Fold->new(padding => 1);
    my($folded, $rest, $w) = $f->fold($str, width => $width);
    if ($w <= $width) {
	$folded;
    } elsif ($width == 1) {
	' '; # wide char not fit to single column
    } else {
	die "Panic"; # should never reach here...
    }
}

sub guard_maker {
    my $obj = shift;
    my $max = shift;
    local $_ = join '', @_;
    my @a;
    for my $i (1 .. 255) {
	my $c = pack "C", $i;
	next if $c =~ /\s/ || /\Q$c/;
	push @a, $c;
	last if @a > $max;
    }
    return if @a < 2;
    my $lead = do { local $" = ''; qr/[^\Q@a\E]*+/ };
    my $b = pop @a;
    return sub {
	my $len = $obj->{length}->(+shift);
	return if $len < 1;
	my $a = $a[ (state $n)++ % @a ];
	( $a . ($b x ($len - 1)), qr/\G${lead}\K(\Q${a}${b}\E*)/, $len );
    };
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::VisualPrintf::Transform - transform and recover interface for text processing

=head1 SYNOPSIS

    use Text::VisualPrintf::Transform;
    my $xform = Text::VisualPrintf::Transform->new();
    $xform->encode(@args);
    $_ = foo(@args);
    $xform->decode($_);

=head1 DESCRIPTION

This is a general interface to transform text data into desirable
form, and recover the result after the process.

For example, L<Text::Tabs> does not take care of Asian wide characters
to calculate string width.  So next program does not work as we wish.

    use Text::Tabs;
    print expand <>;

In this case, make transform object with B<length> function which
understand wide character width, and the pattern of string to be
replaced.

    use Text::VisualPrintf::Transform;
    use Text::VisualWidth::PP;
    my $xform = Text::VisualPrintf::Transform
        ->new(length => \&Text::VisualWidth::PP::width,
              match  => qr/\P{ASCII}+/);

Then next program encode data, call B<expand>() function, and recover
the result into original text.

    my @lines = <>;
    $xform->encode(@lines);
    my @expanded = expand @lines;
    $xform->decode(@expanded);
    print @expanded;

Be aware that B<encode> and B<decode> method alter the values of given
arguments.  Because they return results as a list too, this can be
done more simply.

    print $xform->decode(expand($xform->encode(<>)));

Next program implements ANSI terminal sequence aware expand command.

    use Text::ANSI::Fold::Util qw(ansi_width);

    my $xform = Text::VisualPrintf::Transform
        ->new(length => \&ansi_width,
              match  => qr/[^\t\n]+/);
    while (<>) {
        print $xform->decode(expand($xform->encode($_)));
    }

Giving many arguments to B<decode> is not a good idea, because
replacement cycle is performed against all items.  So mix up the
result into single string if possible.

    print $xform->decode(join '', @expanded);

=head1 METHODS

=over 7

=item B<new>

Create transform object.  Takes following parameters.

=over 4

=item B<length> => I<function>

Function to calculate text width.  Default is C<length>.

=item B<match> => I<regex>

Specify text area to be replaced.  Default is C<qr/.+/s>.

=item B<test> => I<regex> or I<sub>

Specify regex or subroutine to test if the argument is to be processed
or not.  Default is B<undef>, so all arguments will be subject to
replace.

=item B<except> => I<string>

Transformation is done by replacing text with different string which
can not be found in all arguments.  This parameter gives additional
string which also to be taken care of.

=back

=item B<encode>

=item B<decode>

Encode/Decode arguments and return them.  Given arguments will be
altered.

=back

=head1 LIMITATION

All arguments given to B<encode> method have to appear in the same
order in to-be-decoded string.  Each argument can be shorter than
the original, or it can even disappear.

If an argument is trimmed down into single byte in a result, and it
have to be recovered to wide character, it is replaced by single
space.

Replacement string is made of characters those can not be found in all
arguments.  So if they contains all characters from C<"\001"> to
C<"\377">, B<encode> method does nothing.  It requires at least two.

Minimum two characters is good enough to produce correct result if all
arguments will appear in the same order.  However, if even single
argument is missing, it wor'n work correctly.  Less characters, more
confusion.

=head1 SEE ALSO

=over 4

=item L<Text::VisualPrintf>, L<https://github.com/kaz-utashiro/Text-VisualPrintf>

This module is originally implemented as a part of
L<Text::VisualPrintf> module.

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#  LocalWords:  ansi xform regex undef
