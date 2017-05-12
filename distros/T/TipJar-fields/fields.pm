package TipJar::fields;

use strict;
use warnings;
use vars qw/$VERSION/;
$VERSION = '0.01';
use Carp;
sub import{
	shift;
	my $CP = caller;
	my $number;
	my $code = join '',"package $CP;\n",
		map {
			my $N = $number++;
			<<EOF

sub $_(){$N;};
sub get$_ { \$_[0]->[$_]; };
sub set$_ { \$_[0]->[$_] = \$_[1]; };

EOF
		} @_;

	eval $code;

	$@ and croak "$@\n$code\nEND\n";
};

1;
__END__

=head1 NAME

TipJar::fields - generate constants and accessors for array-based objects

=head1 SYNOPSIS

  package foobarbazobj;
  use TipJar::fields qw/foo bar baz/;
  sub new{ shift; bless [@_];};
  sub foobaz {my $obj = shift; "$$obj[foo]$obj->[baz]"}; # like C ENUM
  package main;
  $fbb = new foobarbazobj qw/uno dos tres/;
  print $fbb->getfoo();		#prints 'uno'
  print $fbb->setfoo(700);	#prints '700'
  print $fbb->foobaz();		#prints '700tres'

=head1 DESCRIPTION

Sugar to create named fields for accessing arrays, just like
ENUM statements in the C programming language.  Also goes ahead
and creates get and set accessors.

=head2 EXPORT

exports zero through however many fields there are, as constant functions,
like C ENUM.  Also get* and set* accessors for each named field, assuming
a reference-to-array object structure.


=head1 HISTORY

=over 8

=item 0.01


=back


=head1 AUTHOR

David Nicol <davidnico@cpan.org>
released April 2003 GPL/AL.

=head1 SEE ALSO

L<fields>.

=cut
