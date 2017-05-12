package XML::ASX::Repeat;

use strict;
use vars qw($VERSION $AUTOLOAD @ISA);

@ISA = qw(XML::ASX);

use XML::ASX::Entry;

use overload '""' => \&xml;

$VERSION = '0.01';

my %RW_SLOTS = (
			   count => '1',
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
	my $entry = shift || XML::ASX::Entry->new;
	push @{$self->{entries}}, $entry;

	return $self->{entries}->[scalar @{$self->{entries}} - 1];
}

sub each_entry {
	my $self = shift;
	return $self->{entries} ? @{$self->{entries}} : ();
}

sub xml {
	my $self = shift;

	my $content = join '', ($self->each_entry);

	return $self->entag('Repeat',$content,{COUNT=>$self->count});
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

XML::ASX::Repeat - Repeat a block of XML::ASX::Entry

=head1 SYNOPSIS

  use XML::ASX::Repeat;
  my $repeat = XML::ASX::Repeat->new;
  $repeat->count(3);
  $ent1 = $repeat->add_entry;
  $ent->url('http://www.com/1.asf');
  $ent1 = $repeat->add_entry;
  $ent->url('http://www.com/2.asf');
  print $repeat;

=head1 DESCRIPTION

The Repeat tag is parented by the ASX tag and can contain ENTRY tags.
The effect is to cause the contained ENTRYs to be repeated (collated)
the number of times specified by the COUNT attribute of the Repeat tag.

The code snippet from the synopsis will produce this:

  <Repeat COUNT="3">
    <Entry><Ref href="http://www.com/1.asf"></Entry>
    <Entry><Ref href="http://www.com/2.asf"></Entry>
  </Repeat>

=head1 METHODS

=head2 ACCESSORS

count() - how many times should the block be repeated?

=head1 AUTHOR

Allen Day, <allenday@ucla.edu>

=head1 SEE ALSO

Video::Info

=cut
