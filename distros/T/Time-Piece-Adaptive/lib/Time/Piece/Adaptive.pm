package Time::Piece::Adaptive;

use warnings;
use strict;

no warnings 'redefine';

=head1 VERSION

Version 0.03

=cut

our $VERSION = 0.03;

=head1 NAME

Time::Piece::Adaptive - subclass of Time::Piece which allows the default
stringification function to be set.

=head1 REQUIRES

Subclasses Time::Piece.

=head1 SYNOPSIS

See Time::Piece

I actually think this subclass encapsulates the behavior I would expect from
Time::Piece, but I haven't been able to elicit a response from the authors of
Time::Piece.

=head1 EXPORT

=over 4

=item * gmtime

=item * localtime

=item * :override:

=back

See Time::Piece for more.

=cut

use vars qw(@ISA @EXPORT %EXPORT_TAGS);

require Exporter;
require DynaLoader;
use Time::Piece;

@ISA = qw(Time::Piece);

@EXPORT = qw(
    localtime
    gmtime
);

%EXPORT_TAGS = (
    ':override' => 'internal',
    );

my %_special_exports = (
  localtime => sub { my $c = $_[0]; sub { $c->localtime(@_) } },
  gmtime    => sub { my $c = $_[0]; sub { $c->gmtime(@_)    } },
); 

sub _export
{ 
    my ($class, $to, @methods) = @_;
    for my $method (@methods)
    {
	if (exists $_special_exports{$method})
	{
	    no strict 'refs';
	    no warnings 'redefine';
	    *{$to . "::$method"} = $_special_exports{$method}->($class);
	} else { 
	    $class->SUPER::export ($to, $method);
	}
    } 
}

sub import
{
    # replace CORE::GLOBAL localtime and gmtime if required
    my $class = shift;
    my %params;
    map $params{$_}++, @_, @EXPORT;
    if (delete $params{':override'})
    {
	$class->_export ('CORE::GLOBAL', keys %params);
    }
    else
    {
	$class->_export((caller)[0], keys %params);
    }
}



=head1 METHODS

=head2 new

  my $t1 = new Time::Piece::Adaptive (time, stringify => "%Y%m%d%H%M%S");
  print "The MySql timestamp was $t1.";

  my $t2 = new Time::Piece::Adaptive (time,
                                      stringify => \&my_func,
                                      stringify_args => $my_data);

Like the constructor for Time::Piece, except it may set the default
stringify function.

The above examples are semanticly equivalent to:

  my $t1 = new Time::Piece::Adaptive (time);
  $t1->set_stringify ("%Y%m%d%H%M%S");
  print "The MySql timestamp was $t1.";

  my $t2 = new Time::Piece::Adaptive (time);
  $t2->set_stringify (\&my_func, $my_data);

=cut

sub new
{
    my $class = shift;
    my $time = shift
	unless $_[0] && ($_[0] eq "stringify" || $_[0] eq "stringify_arg");
    my %args = @_;

    my $self = $class->SUPER::new ($time);
    my $stringify = $args{stringify} if exists $args{stringify};
    my $stringify_args = $args{stringify_args} if exists $args{stringify_args};
    $self->set_stringify ($stringify, $stringify_args);
    return $self;
}



=head2 localtime

=head2 gmtime

C<localtime> and C<gmtime> work like Time::Piece's versions, except they accept
stringify arguments, as C<new>.

=cut

sub localtime {
    unshift @_, __PACKAGE__ unless eval {$_[0]->isa ('Time::Piece')};
    my $class = shift;
    my $time  = shift
	unless $_[0] && ($_[0] eq "stringify" || $_[0] eq "stringify_arg");
    $time = time unless defined $time;
    return $class->_mktime ($time, 1, @_);
}

sub gmtime {
    unshift @_, __PACKAGE__ unless eval {$_[0]->isa ('Time::Piece')};
    my $class = shift;
    my $time  = shift
	unless $_[0] && ($_[0] eq "stringify" || $_[0] eq "stringify_arg");
    $time = time unless defined $time;
    return $class->_mktime ($time, 0, @_);
}

sub _mktime
{
    my ($class, $time, $islocal, %args) = @_;
    return $class->SUPER::_mktime ($time) if wantarray;

    my $self = $class->SUPER::_mktime ($time);
    my $stringify = $args{stringify} if exists $args{stringify};
    my $stringify_args = $args{stringify_args} if exists $args{stringify_args};
    $self->set_stringify ($stringify, $stringify_args);
    return $self;
}

=head2 set_stringify

  $t->set_stringify ($format, $arg);
  print "The date is $t.";

If C<$format> is a reference to a function, set the stringify function to
C<$format>, which should return a string when passed a reference to an
instantiated Time::Piece and C<$arg>.

If C<$format> is a string, use it to format an output string using
C<strftime> (any C<$arg> is ignored).

When called without specifying C<$format>, restore the default stringifier
(C<&Time::Piece::cdate>).

=cut

use overload '""' => \&_stringify;

use constant 'c_stringify_func' => 11;
use constant 'c_stringify_arg' => 12;

sub _stringify
{
    my ($self) = @_;
    my $func = $self->[c_stringify_func];
    my $arg = $self->[c_stringify_arg];
    my $string = &{$func}($self, $arg);
    return $string;
}



sub set_stringify
{
    my ($self, $format, $arg) = @_;
    if (ref $format) {
	$self->[c_stringify_func] = $format;
	if (defined $arg) {
	    $self->[c_stringify_arg] = $arg if defined $arg;
	} else {
	    delete $self->[c_stringify_arg];
	}
    } elsif (defined $format) {
	$self->[c_stringify_func] = \&Time::Piece::strftime;
	$self->[c_stringify_arg] = $format;
    } else {
	$self->[c_stringify_func] = \&Time::Piece::cdate;
	delete $self->[c_stringify_arg];
    }
}



=head2 add

=head2 subtract

Like the Time::Piece functions of the same name, except C<stringify> and
C<stringify_arg> arguments are accepted.

Also, when a Time::Piece::Adaptive object is subtracted from an arbitrary
object, it is converted to a string according to its stringify function and
passed to perl for handling.

=cut

use overload
        '-' => \&subtract,
        '+' => \&add;

sub subtract
{
    my $time = shift;

    if ($_[1])
    {
	# SWAPED is set and our parent doesn't know how to handle
	# NOTDATE - DATE.  For backwards compatibility reasons, return
	# the result as if the string $time resolves to was subtracted
	# from NOTDATE.
	return $_[0] - "$time";
    }

    my $new = $time->SUPER::subtract (@_);
    $new->set_stringify ($time->[c_stringify_func],
			 $time->[c_stringify_arg])
	if $new->isa ('Time::Piece');
    return $new;
}

sub add
{
    my ($time) = shift;
    my $new = $time->SUPER::add (@_);
    $new->set_stringify ($time->[c_stringify_func],
			 $time->[c_stringify_arg]);
    return $new;
}



=head2 strptime

  my $t = Time::Piece::Adaptive::strptime ($mysqltime, "%Y%m%d%H%M%S");
  print "The MySql timestamp was $t.";

  my $t = Time::Piece::Adaptive::strptime ($mysqltime, "%Y%m%d%H%M%S",
                                           stringify =>
                                           \&Time::Piece::Adaptive::cdate);
  print "The MySql timestamp was $t.";


Like the C<Time::Piece::strptime>, except a stringify function may be set as
per C<Time::Piece::Adaptive::new> and, if the stringify function is not
explicitly specified, then it is set by calling C<set_stringify ($format)> on
the new object with the same C<$format> string passed to C<strptime>.

=cut

sub strptime
{
    my ($time, $string, $format, %args) = @_;
    my $self = $time->SUPER::strptime ($string, $format);
    my $stringify = exists $args{stringify} ? $args{stringify} : $format;
    my $stringify_args = $args{stringify_args} if exists $args{stringify_args};
    $self->set_stringify ($stringify, $stringify_args);
    return $self;
}

=head1 SEE ALSO

=over 4

=item L<Time::Piece>

=back

=head1 AUTHOR

Derek Price, C<< <derek at ximbiot.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<time-piece-adaptive at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Time-Piece-Adaptive>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Time::Piece::Adaptive

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Time-Piece-Adaptive>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Time-Piece-Adaptive>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Time-Piece-Adaptive>

=item * Search CPAN

L<http://search.cpan.org/dist/Time-Piece-Adaptive>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Derek Price, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
