=head1 TIECLASS
Name:	POP::Lazy_object
Desc:	Implements a tied scalar which holds a persistent object, lazily.
	When tie() is called, it gets a reference to the syntactical scalar
	(the one which is being tied into this class), the persistent class
	name of the object we wish to store, and the pid of that object.
	The first time the scalar is accessed, we restore the object and then
	perform some heavy wizardry, untieing the syntactical scalar and
	setting it to the object we just restored. Ta-da! Now you see it, now
	you don't...
=cut
package POP::Lazy_object;

$VERSION = do{my(@r)=q$Revision: 1.2 $=~/d+/g;sprintf '%d.'.'%02d'x$#r,@r};

use strict;
use vars qw/$VERSION/;
use Carp;

=head2 METHOD
Name:	POP::Lazy_object::TIESCALAR
Desc:	The tied scalar constructor; takes a reference to the syntactical
	scalar (the one which is being tied into this class), the persistent
	class name of the object we wish to store, and the pid of that object.
=cut
sub TIESCALAR {
  my($type, $tier, $class, $val) = @_;
  my $pm = $class;
  $pm =~ s,::,/,g;
  $pm .= '.pm';
  return bless {'tier' => $tier,
                'pm' => $pm,
                'class' => $class,
                'pid' => $val}, $type;
}

=head2 METHOD
Name:	POP::Lazy_object::FETCH
Desc:	Called when the scalar is accessed the first time.  Restores the
	object and then commits harakiri.
=cut
sub FETCH {
  my $this = shift;
  # restore the object
  require $this->{'pm'};
  my $obj;
  eval {
    $obj = $this->{'class'}->new($this->{'pid'});
  };
  if ($@ || !$obj) {
    croak "Unable to restore object [$this->{'pid'}] in class [".
	"$this->{'class'}]: $@";
  }
  # replace the thing which is tied to us with the object
  untie ${$this->{'tier'}};
  ${$this->{'tier'}} = $obj;
}

=head2 METHOD
Name:	POP::Lazy_object::pid
Desc:	Used to get at the pid without having to restore the object. Must be
	called as (tied $foo)->pid;
=cut
sub pid {
  $_[0]{'pid'};
}

=head2 METHOD
Name:	POP::Lazy_object::STORE
Desc:	Just need this for completeness; it'll never get called
=cut
sub STORE { }

$VERSION = $VERSION;
