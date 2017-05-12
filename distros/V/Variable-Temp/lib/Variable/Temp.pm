package Variable::Temp;

use 5.006;

use strict;
use warnings;

=head1 NAME

Variable::Temp - Temporarily change the value of a variable.

=head1 VERSION

Version 0.03

=cut

our $VERSION;
BEGIN {
 $VERSION = '0.03';
}

=head1 SYNOPSIS

    use Variable::Temp 'temp';

    my $x = 1;
    say $x; # 1
    {
     temp $x = 2;
     say $x; # 2
    }
    say $x; # 1

=head1 DESCRIPTION

This module provides an utility routine that can be used to temporarily change the value of a scalar, array or hash variable, until the end of the current scope is reached where the original value of the variable is restored.
It is similar to C<local>, except that it can be applied onto lexicals as well as globals, and that it replaces values by copying the new value into the container variable instead of by aliasing.

=cut

use Variable::Magic 0.51;

use Scope::Upper;

=head1 FUNCTIONS

=head2 C<temp>

    temp $var;
    temp $var = $value;

    temp @var;
    temp @var = \@value;

    temp %var;
    temp %var = \%value;

Temporarily replaces the value of the lexical or global variable C<$var> by C<$value> (respectively C<@var> by C<@value>, C<%var> by C<%value>), or by C<undef> if C<$value> is omitted (respectively empties C<@var> and C<%var> if the second argument is omitted), until the end of the current scope.
Any subsequent assignments to this variable in the current (or any inferior) scope will not affect the original value which will be restored into the variable at scope end.
Several C<temp> calls can be made onto the same variable, and the restore are processed in reverse order.

Note that destructors associated with the variable will B<not> be called when C<temp> sets the temporary value, but only at the natural end of life of the variable.
They will trigger after any destructor associated with the replacement value.

Due to a shortcoming in the handling of the C<\$> prototype, which was addressed in C<perl> 5.14, the pseudo-statement C<temp $var = $value> will cause compilation errors on C<perl> 5.12.x and below.
If you want your code to run on these versions of C<perl>, you are encouraged to use L</set_temp> instead.

=cut

my $wiz;
$wiz = Variable::Magic::wizard(
 data => sub { $_[1] },
 set  => sub {
  my ($token, $var) = @_;
  &Variable::Magic::dispell($token, $wiz);
  if (ref $var eq 'ARRAY') {
   @$var = @$$token;
  } else {
   %$var = %$$token;
  }
  return;
 },
 free => sub {
  my ($token, $var) = @_;
  # We need Variable::Magic 0.51 so that dispell in free does not crash.
  &Variable::Magic::dispell($token, $wiz);
  if (ref $var eq 'ARRAY') {
   @$var = ();
  } else {
   %$var = ();
  }
 },
);

sub temp (\[$@%]) :lvalue {
 my $var    = $_[0];
 my $target = Scope::Upper::UP;
 my $ret;
 my $type   = ref $var;
 if ($type eq 'ARRAY') {
  my @save = @$var;
  &Scope::Upper::reap(sub { @$var = @save } => $target);
  my $token;
  Variable::Magic::cast($token, $wiz, $var);
  $ret = \$token;
 } elsif ($type eq 'HASH') {
  my %save = %$var;
  &Scope::Upper::reap(sub { %$var = %save } => $target);
  my $token;
  Variable::Magic::cast($token, $wiz, $var);
  $ret = \$token;
 } else { # $type eq 'SCALAR' || $type eq 'REF'
  my $save = $$var;
  &Scope::Upper::reap(sub { $$var = $save } => $target);
  $$var = undef;
  $ret  = $var;
 }
 $$ret;
}

=head2 C<set_temp>

    set_temp $var;
    set_temp $var => $value;

    set_temp @var;
    set_temp @var => \@value;

    set_temp %var;
    set_temp %var => \%value;

A non-lvalue variant of L</temp> that can be used with any version of C<perl>.

=cut

sub set_temp (\[$@%];$) {
 my $var    = $_[0];
 my $target = Scope::Upper::UP;
 my $type   = ref $var;
 if ($type eq 'ARRAY') {
  my @save = @$var;
  &Scope::Upper::reap(sub { @$var = @save } => $target);
  @$var = @_ >= 2 ? @{$_[1]} : ();
 } elsif ($type eq 'HASH') {
  my %save = %$var;
  &Scope::Upper::reap(sub { %$var = %save } => $target);
  %$var = @_ >= 2 ? %{$_[1]} : ();
 } else { # $type eq 'SCALAR' || $type eq 'REF'
  my $save = $$var;
  &Scope::Upper::reap(sub { $$var = $save } => $target);
  $$var = $_[1];
 }
 return;
}

=head1 EXPORT

The functions L</temp> and L</set_temp> are only exported on request by specifying their names in the module import list.

=cut

use base 'Exporter';

our @EXPORT      = ();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw<temp set_temp>;

=head1 DEPENDENCIES

L<perl> 5.6.

L<Exporter> (core since perl 5).

L<Scope::Upper>.

L<Variable::Magic> 0.51.

=head1 SEE ALSO

L<Scope::Upper>.

L<perlfunc/local>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-variable-temp at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Variable-Temp>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Variable::Temp

=head1 COPYRIGHT & LICENSE

Copyright 2015 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Variable::Temp
