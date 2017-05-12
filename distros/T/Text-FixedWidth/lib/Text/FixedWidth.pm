package Text::FixedWidth;

use warnings;
use strict;
use Carp;
use vars ('$AUTOLOAD');
use Storable ();

=head1 NAME

Text::FixedWidth - Easy OO manipulation of fixed width text files

=cut

our $VERSION = '0.13';

=head1 SYNOPSIS

   use Text::FixedWidth;

   my $fw = new Text::FixedWidth;
   $fw->set_attributes(qw(
      fname            undef  %10s
      lname            undef  %-10s
      points           0      %04d
   ));

   $fw->parse(string => '       JayHannah    0003');
   $fw->get_fname;               # Jay
   $fw->get_lname;               # Hannah
   $fw->get_points;              # 0003

   $fw->set_fname('Chuck');
   $fw->set_lname('Norris');
   $fw->set_points(17);
   $fw->string;                  # '     ChuckNorris    0017'

If you're familiar with printf formats, then this class should make processing
fixed width files trivial.
Just define your attributes and then you can get_* and set_* all day long. When
you're happy w/ your values envoke string() to spit out your object in your
defined fixed width format.

When reading a fixed width file, simply pass each line of the file into parse(), and
then you can use the get_ methods to retrieve the value of whatever attributes you
care about.

=head1 METHODS

=head2 new

Constructor. Does nothing fancy.

=cut

sub new {
   my ($caller,%args) = (@_);

   my $caller_is_obj = ref($caller);
   my $class = $caller_is_obj || $caller;
   my $self = bless {}, ref($class) || $class;
   return $self;
}


=head2 set_attributes

Pass in arguments in sets of 3 and we'll set up attributes for you.

The first argument is the attribute name. The second argument is the default
value we should use until told otherwise. The third is the printf format we should
use to read and write this attribute from/to a string.

  $fw->set_attributes(qw(
    fname            undef  %10s
    lname            undef  %-10s
    points           0      %04d
  );

=cut

sub set_attributes {
   my ($self, @att) = @_;

   unless (@att % 3 == 0) { die "set_attributes() requires sets of 3 parameters"; }
   while (@att) {
      my ($att, $value, $sprintf) = splice @att, 0, 3;
      if (exists $self->{_attributes}{$att}) {
         die "You already set attribute name '$att'! You can't set it again! All your attribute names must be unique";
      }
      if ($value && $value eq "undef") { $value = undef; }
      $self->{_attributes}{$att}{sprintf} = $sprintf;
      $self->{_attributes}{$att}{value}   = $value;
      my ($length) = ($sprintf =~ /(\d+)/g);
      $self->{_attributes}{$att}{length}  = $length;
      push @{$self->{_attribute_order}}, $att;
   }

   return 1;
}


=head2 set_attribute

Like set_attributes, but only sets one attribute at a time, via named parameters:

  $fw->set_attribute(
    name    => 'lname',
    default => undef,
    format  => '%10s',
  );

If an sprintf 'format' is insufficiently flexible, you can set 'reader' to a code reference 
and also define 'length'. For example, if you need a money format without a period: 

  $fw->set_attribute(
    name    => 'points2',
    reader  => sub { sprintf("%07.0f", $_[0]->get_points2 * 100) },
    length  => 7,
  );
  $fw->set_points2(13.2);
  $fw->get_points2;        # 13.2
  $fw->getf_points2;       # 0001320

Similarly, you can set 'writer' to a code reference for arbitrary manipulations when 
setting attributes:

  $fw->set_attribute(
    name    => 'points3',
    writer  => sub { $_[1] / 2 },
    format  => '%-6s',
  );
  $fw->set_points3(3);
  $fw->get_points3;        # 1.5
  $fw->getf_points3;       # '1.5   '

=cut

sub set_attribute {
   my ($self, %args) = @_;
   my $att =     $args{name};
   my $value =   $args{default};
   my $sprintf = $args{format};
   my $reader =  $args{reader};
   my $writer =  $args{writer};
   my $length =  $args{length};

   unless ($att)     { 
      die "set_attribute() requires a 'name' argument";
   }
   unless ($sprintf || $reader) { 
      die "set_attribute() requires a 'format' or a 'reader' argument"; 
   }
   if ($reader && not defined $length) { 
      die "set_attribute() requires a 'length' when a 'reader' argument is provided";
   }
   if (exists $self->{_attributes}{$att}) {
      die "You already set attribute name '$att'! You can't set it again! All your attribute names must be unique";
   }

   if ($value && $value eq "undef") { $value = undef; }
   $self->{_attributes}{$att}{value}   = $value;
   if ($sprintf) {
      $self->{_attributes}{$att}{sprintf} = $sprintf;
      ($length) = ($sprintf =~ /(\d+)/g);
   } else {
      $self->{_attributes}{$att}{reader} = $reader;
   }
   $self->{_attributes}{$att}{length} = $length;
   $self->{_attributes}{$att}{writer} = $writer;
   push @{$self->{_attribute_order}}, $att;

   return 1;
}


=head2 parse

Parses the string you hand in. Sets each attribute to the value it finds in the string.

  $fw->parse(string => '       JayHannah    0003');

=cut

sub parse {
   my ($self, %args) = @_;

   die ref($self).":Please provide a string argument" if (!$args{string});
   my $string = $args{string};

   $self = $self->clone if $args{clone};

   my $offset = 0;
   foreach (@{$self->{_attribute_order}}) {
      my $length = $self->{_attributes}{$_}{length};
      $self->{_attributes}{$_}{value}  = substr $string, $offset, $length;
      $offset += $length;
   }

   return $args{clone}? $self : 1;
}


=head2 string

Dump the object to a string. Walks each attribute in order and outputs each in the
format that was specified during set_attributes().

  print $fw->string;      #  '     ChuckNorris    0017'

=cut

sub string {
   my ($self) = @_;
   my $rval;
   foreach my $att (@{$self->{_attribute_order}}) {
      $rval .= $self->_getf($att);
   } 
   return $rval;
}


=head2 getf_*

For the 'foo' attribute, we provide the getter get_foo() per the SYNOPSIS above. 
But we also provide getf_foo(). get_* returns the current value in no particular format, 
while getf_* returns the fixed-width formatted value.

   $fw->get_fname;    # Jay          (no particular format)
   $fw->getf_fname;   # '       Jay' (the format you specified)

=cut

sub _getf {
   my ($self, $att) = @_;

   my $value   = $self->{_attributes}{$att}{value};
   my $length  = $self->{_attributes}{$att}{length};
   my $sprintf = $self->{_attributes}{$att}{sprintf};
   my $reader =  $self->{_attributes}{$att}{reader};
   if ($reader) {
      my $rval = $reader->($self);
      if (length($rval) != $length) {
         die "string() error: " . ref($self) . " is loaded with a 'reader' which returned a string of length " . length($rval) . ", but 'length' was set to $length. Please correct the class. The error occured on attribute '$att' converting value '$value' to '$rval'";
      }
      return $rval; 
   }

   if (defined ($value) and length($value) > $length) {
      warn "string() error! " . ref($self) . " length of attribute '$att' cannot exceed '$length', but it does. Please shorten the value '$value'";
      return 0;
   }
   if (not defined $value) {
      $value = '';
   }
   unless ($sprintf) {
      warn "string() error! " . ref($self) . " sprintf not set on attribute $att. Using '%s'";
      $sprintf = '%s';
   }

   my $rval;
   if (
      $sprintf =~ /\%\d*[duoxefgXEGbB]/ && (       # perldoc -f sprintf
         (not defined $value) ||
         $value eq "" ||
         $value !~ /^(\d+\.?\d*|\.\d+)$/        # match valid number
      )
   ) {
      $value = '' if (not defined $value);
      warn "string() warning: " . ref($self) . " attribute '$att' contains '$value' which is not numeric, yet the sprintf '$sprintf' appears to be numeric. Using 0";
      $value = 0;
   }
   $rval = sprintf($sprintf, (defined $value ? $value : ""));

   if (length($rval) != $length) {
      die "string() error: " . ref($self) . " is loaded with an sprintf format which returns a string that is NOT the correct length. Please correct the class. The error occured on attribute '$att' converting value '$value' via sprintf '$sprintf', which is '$rval', which is not '$length' characters long";
   }

   return $rval;
}


=head2 auto_truncate

Text::FixedWidth can automatically truncate long values for you. Use this method to tell your $fw
object which attributes should behave this way.

  $fw->auto_truncate("fname", "lname");

(The default behavior if you pass in a value that is too long is to carp out a warning,
ignore your set(), and return undef.)

=cut

sub auto_truncate {
   my ($self, @attrs) = @_;
   $self->{_auto_truncate} = {};
   foreach my $attr (@attrs) {
      unless ($self->{_attributes}{$attr}) {
         carp "Can't auto_truncate attribute '$attr' because that attribute does not exist";
         next;
      }
      $self->{_auto_truncate}->{$attr} = 1;
   }
   return 1;
}

=head2 clone

Provides a clone of a Text::FixedWidth object. If available it will attempt
to use L<Clone::Fast> or L<Clone::More> falling back on L<Storable/dclone>.

   my $fw_copy = $fw->clone;

This method is most useful when being called from with in the L</parse> method.

   while( my $row = $fw->parse( clone => 1, string => $str ) ) {
      print $row->foobar;
   }

See L</parse> for further information.

=cut

sub clone {
   my $self = shift;
   return Storable::dclone($self);
}




sub DESTROY { }

# Using Damian methodology so I don't need to require Moose.
#    Object Oriented Perl (1st edition)
#    Damian Conway
#    Release date  15 Aug 1999
#    Publisher   Manning Publications
sub AUTOLOAD {
  no strict "refs";
  if ($AUTOLOAD =~ /.*::get_(\w+)/) {
    my $att = $1;
    *{$AUTOLOAD} = sub {
      $_[0]->_get($att);
    };
    return &{$AUTOLOAD};
  }

  if ($AUTOLOAD =~ /.*::getf_(\w+)/) {
    my $att = $1;
    *{$AUTOLOAD} = sub {
      $_[0]->_getf($att);
    };
    return &{$AUTOLOAD};
  }

  if ($AUTOLOAD =~ /.*::set_(\w+)/) {
    my $att = $1;
    *{$AUTOLOAD} = sub {
      $_[0]->_set($att, $_[1]);
    };
    return &{$AUTOLOAD};
  }

  confess ref($_[0]).":No such method: $AUTOLOAD";
}


sub _get { 
  my ($self, $att) = @_;
  croak "Can't get_$att(). No such attribute: $att" unless (defined $self->{_attributes}{$att});
  my $ret = $self->{_attributes}{$att}{value};
  $ret =~ s/\s+$// if $ret;
  $ret =~ s/^\s+// if $ret;
  return $ret;
}


sub _set { 
  my ($self, $att, $val) = @_;

  my $length = $self->{_attributes}{$att}{length};
  my $writer = $self->{_attributes}{$att}{writer};

  croak "Can't set_$att(). No such attribute: $att" unless (defined $self->{_attributes}{$att});
  if (defined $self->{_attributes}{$att}) {
    if ($writer) {
      $val = $writer->($self, $val);
    } elsif (defined $val && length($val) > $length) {
      if ($self->{_auto_truncate}{$att}) {
        $val = substr($val, 0, $length);
        $self->{_attributes}{$att}{value} = $val;
      } else {
        carp "Can't set_$att('$val'). Value must be $length characters or shorter";
        return undef;
      }
    }
    $self->{_attributes}{$att}{value} = $val;
    return 1;
  } else {
    return 0;
  }
}


=head1 ALTERNATIVES

Other modules that may do similar things:
L<Parse::FixedLength>,
L<Text::FixedLength>,
L<Data::FixedFormat>,
L<AnyData::Format::Fixed>

=head1 AUTHOR

Jay Hannah, C<< <jay at jays.net> >>, http://jays.net

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-fixedwidth at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-FixedWidth>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::FixedWidth

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Text-FixedWidth>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-FixedWidth>

=item * Source code

L<http://github.com/jhannah/text-fixedwidth>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-FixedWidth>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2008-2013 Jay Hannah, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Text::FixedWidth
