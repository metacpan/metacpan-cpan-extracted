package XML::ASX::Event;

use strict;
use vars qw($VERSION $AUTOLOAD @ISA);

@ISA = qw(XML::ASX);

use XML::ASX::Entry;

use overload '""' => \&xml;

$VERSION = '0.01';

my %RW_SLOTS = (
				name => '',
				whendone => '',
			   );

sub AUTOLOAD {
	my $self = shift;
	my $param = $AUTOLOAD;
	$param =~ s/.*:://;
	die(__PACKAGE__." doesn't implement $param") unless defined($RW_SLOTS{$param});
	$self->{$param} = shift if @_;
	return $self->{$param};
}

sub new {
	my $class = shift;
	my %param = @_;
	my $self = bless {}, $class;

	$self->$_($RW_SLOTS{$_}) foreach keys %RW_SLOTS;
	$self->$_($param{$_}) foreach keys %param;

	return $self;
}

sub add_entry {
	my $self = shift;
	my $entry = XML::ASX::Entry->new;
	push @{$self->{queue}}, $entry;

	return $self->{queue}->[scalar @{$self->{queue}} - 1];
}

sub xml {
	my $self = shift;

	die __PACKAGE__.': name() required' unless $self->name;
	die __PACKAGE__.': whendone() required.  Valid values are "RESUME","NEXT","BREAK"' unless $self->whendone eq 'RESUME' or $self->whendone eq 'NEXT' or $self->whendone eq 'BREAK';

	my $content = join '', ($self->each_in_queue);

	return $self->entag('Event',$content,{NAME=>$self->name,WHENDONE=>$self->whendone});
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

XML::ASX::Event - Manipulate playback of a block of XML::ASX::Entry

=head1 SYNOPSIS

  use XML::ASX::Event;
  my $event = XML::ASX::Event->new;
  $event->name('The Big Bang');
  $event->whendone('NEXT');
  $ent1 = $event->add_entry;
  $ent->url('http://www.com/1.asf');
  $ent1 = $event->add_entry;
  $ent->url('http://www.com/2.asf');
  print $event;

=head1 DESCRIPTION

The code snippet from the synopsis will produce this:

  <Event NAME="The Big Bang" WHENDONE="NEXT">
    <Entry><Ref href="http://www.com/1.asf"></Entry>
    <Entry><Ref href="http://www.com/2.asf"></Entry>
  </Event>

Read more about events at MSDN.

=head1 AUTHOR

Allen Day, <allenday@ucla.edu>

=head1 SEE ALSO

Video::Info

=cut
