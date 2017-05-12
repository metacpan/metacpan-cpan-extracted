package TipJar::MTA::queue;

use 5.006;
use strict;
use warnings;
use Carp;

use vars qw/$VERSION $basedir $tally/;

$VERSION = '0.02';
$tally = 'a';

# use TipJar::fields qw/RA targetlist body/;
sub RA(){0};
sub targetlist(){1};
sub body(){2};
# humbug
# use Fcntl ':flock';
sub FLOCK_EX(){2};
sub FLOCK_UN(){8};

sub new{
	bless [undef,[],''];
};

sub import{
	shift;
	$basedir = shift;
	-d $basedir or croak "[$basedir] is no directory";
	-w $basedir or croak "[$basedir] is not writable";
};

sub return_address{
	# set the RA field
	$_[0][RA] = $_[1];
	1;
};

sub recipient{
	# add to the targetlist array
	my $obj=shift;
	push @{$obj->[targetlist]},@_;
	1;
};

sub data{
	my $obj = shift;
	$obj->[body] = join '',$obj->[body],@_;
	1;
};


sub printlist($);
sub printlist($){
	# print STDERR "Debug: printlist called with $_[0]\n";
	my $x = shift;
	if (ref($x)){
		my $y;
		for $y (@{$x}){
			printlist $y;
		};
	}else{
		print MESSAGE "$x\n";
	};
};

sub enqueue{
	my $obj = shift;
	my $name = join '.',time,$$,$tally++,rand(36294626999);
	open MESSAGE, ">$basedir/$name"
	   or croak "could not open [$basedir/$name]: $!";
	flock MESSAGE, FLOCK_EX;
	print MESSAGE $obj->[RA],"\n";
	printlist $obj->[targetlist];
	print MESSAGE "\n",$obj->[body],"\n";
	flock MESSAGE, FLOCK_UN;
	close MESSAGE;
	@{$obj} = (undef,[],'');
	1;
};
	

1;
__END__

=head1 NAME

TipJar::MTA::queue - send e-mail via TipJar::MTA

=head1 SYNOPSIS

  use TipJar::MTA::queue '/var/MTAspool'; # sets $TipJar::MTA::queue::basedir 
  my $m = new TipJar::MTA::queue;
  $m->return_address('me@mydomain.tld');
  $m->recipient('you@yourdomain.tld'); # must pass sanity check
  $m->data(<<EOF);	# include all headers
From: my name <iamthesender\@mydomain.tld>
To: your name <you@yourdomain.tld>
Subject: this is a test from me to you

This was sent out via the TipJar::MTA outbound SMTP system!
EOF
  $m->enqueue();	# a TipJar::MTA daemon on /var/MTAspool
                        # will attempt delivery presently. $m
                        # is cleared for reuse.
  $m->return_address('list-bounces@mydomain.tld');
  $m->recipient(@list_members); # will expand array refs
  ...

=head1 DESCRIPTION

TipJar::MTA::queue creates messages in the outgoing queue of
a TipJar::MTA daemon. It is provided for use within other software
that composes the mails.  It does not provide any header lines or
MIME formatting etc. -- you have to get that elsewhere and use
the provided interface to add the data to the object.

=head1 GLOBALS

=over 4

=item $TipJar::MTA::queue::basedir

this package variable holds the base directory of
the L<TipJar::MTA> queue; (see)

=back

=head1 METHODS

=over 4

=item new

returns a blessed object reference.  Many of these can coexist
without interfering with each other.

=item return_address

takes a scalar which must pass a sanity
test which is probably not loose enough, will croak
when the return_address is not sane

=item recipient

takes one or more addresses or array references.  Trusts
that the addresses it is given are valid.  Invalid addresses
will stop processing and get included as weird header lines.  Array
references are not expanded until C<enqueue()> time.

=item data

Appends its argument(s) to the message data block.

=item enqueue

Constructs a new message file according to the TipJar::MTA new message format,
and clears the object for reuse.

=back

=head2 EXPORT

None.

=head1 to-not-do list

=over 8

=item header generation and checking; other bells and whistles

it would be nice to insert more headers into the message. L<mail::Sendmail>
looks like the place to from which to lift features. OTOH, the clarity
of only allowing return address, recipient list, and data is good; perhaps
using another module to compose header lines and building the data block
before passing it to C<< $m->data() >> is the way to go.  So I might
create and publish a L<TipJar::MTA::compose module|TipJar::MTA::compose>
which will rely on the TipJar::MTA::queue interface to post its composed
messages.

=back

=head1 INTERNALS

The object is at this time an array-based object
originally facilitated using TipJar::fields,
but now it just has the
field names written into it as constant functions.

=head1 CAVEATS

This module (and the TipJar::MTA daemon) rely on L<flock locking|flock>
for data corruption control, so it is not reccommended for use on a
shared volume (such as NFS) unless your locking daemons are cooperative
and robust.

=head1 HISTORY

=over 8

=item 0.01

Original version, April 2003

=item 0.02

test script now sends the author two e-mails, in concert with
the test script of the TipJar::MTA module.  See the test script
for example of a date header generator.

=back


=head1 AUTHOR

david nicol E<lt>davidnico@cpan.orgE<gt>

=head1 LICENSE

GPL/AL, enjoy.

=head1 SEE ALSO

L<CPAN|CPAN> has myriad modules to help with
composing and sending e-mail.

None of them have the same interface. 

=cut
