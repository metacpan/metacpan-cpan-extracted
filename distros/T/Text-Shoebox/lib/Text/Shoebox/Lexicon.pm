
package Text::Shoebox::Lexicon;
require 5;
use strict;
use vars qw(@ISA $Debug $VERSION $ENTRY_CLASS);
use Carp ();

$Debug = 0 unless defined $Debug;
BEGIN { 
  $VERSION = "1.02";
}
$ENTRY_CLASS ||= 'Text::Shoebox::Entry';
use Text::Shoebox 1.02 ();

unless($Text::Shoebox::Entry::VERSION) { require Text::Shoebox::Entry; }

###########################################################################

=head1 NAME

Text::Shoebox::Lexicon - an object-oriented interface to Shoebox lexicons

=head1 SYNOPSIS

  use Text::Shoebox::Lexicon;
  my $lex = Text::Shoebox::Lexicon->read_file( "haida.sf" );
  my @entries = $lex->entries;
  print "See, it has ", scalar( @entries ), " entries!\n";
  $lex->dump;

=head1 DESCRIPTION

On object of class Text::Shoebox::Lexicon represents a SF-format lexicon.
This mostly just means it's a container for a list of
Text::Shoebox::Entry objects, which represent the entries in this lexicon.

This class (plus Text::Shoebox::Entry) exists basically to provide an OO
interface around L<Text::Shoebox> -- but you're free to directly
use Text::Shoebox instead if you prefer a functional interface.

=head1 METHODS

=over

=item $lex = Text::Shoebox::Lexicon->new;

This method returns a new Text::Shoebox Lexicon object, containing
an empty list of entries.

=cut

###########################################################################

sub new {
  my $new = bless {},  ref($_[0]) || $_[0];;
  $new->init;
  return $new;
}

sub init {
  my $self = shift;
  $self->{'e'} = [];
}

#--------------------------------------------------------------------------

=item $lex->read_file( $filespec );

This reads entries from $filespec (e.g., "./whatever.sf") into $lex.
If $filespec doesn't exist or isn't readable, then this dies.

=item $lex = Text::Shoebox::Lexicon->read_file( $filespec );

This constructs a new lexicon object and reads entries from $filespec into
it.  I.e., it's basically a shortcut for:

               $lex = Text::Shoebox::Lexicon->new;
               $lex->read_file($filespec);

=item $lex->read_handle( $filehandle );

=item $lex = Text::Shoebox::Lexicon->read_handle( $filehandle );

These work just like read_file except that the argument should be a
filehandle instead of a filespec string.

=item $lex->write_file( $filespec );

This writes the entries from $lex to the given filespec.  If they can't
be written, this dies.

=item $lex->write_handle( $filehandle );

These work just like write_file except that the argument should be a
filehandle instead of a filespec string.

=cut

sub read_file {
  my($self, $in) = @_;
  $self = $self->new unless ref $self;  # tolerate being a class method
  Text::Shoebox::read_sf( 'from_file' => $in, 'into' => $self->{'e'},
    $self->{'rs'} ? ('rs' => $self->{'rs'}) : ()
  );
  $self->tidy_up;
  return $self;
}

sub read_handle {
  my($self, $in) = @_;
  $self = $self->new unless ref $self;  # tolerate being a class method
  Text::Shoebox::read_sf( 'from_handle' => $in, 'into' => $self->{'e'},
    $self->{'rs'} ? ('rs' => $self->{'rs'}) : ()
  );
  $self->tidy_up;
  return $self;
}

sub write_file {
  my($self, $out) = @_;
  Carp::confess "write_file is an object method, not a class method"
   unless ref $self;
  Text::Shoebox::write_sf( 'to_file' => $out, 'from' => $self->{'e'},
    $self->{'rs'} ? ('rs' => $self->{'rs'}) : ()
  ) || Carp::confess "Couldn't write_file to $out: $!";
  return $self;
}

sub write_handle {
  my($self, $out) = @_;
  Carp::confess "write_handle is an object method, not a class method"
   unless ref $self;
  Text::Shoebox::write_sf( 'to_handle' => $out, 'from' => $self->{'e'},
    $self->{'rs'} ? ('rs' => $self->{'rs'}) : ()
  ) || Carp::confess "Couldn't write_handle to $out: $!";
  return $self;
}

#--------------------------------------------------------------------------

=item $lex->dump;

This prints (not returns!) a dump of the contents of $lex.

=cut

sub dump {
  my($self, $out) = @_;
  Carp::confess "dump is an object method, not a class method"
   unless ref $self;
  print "Lexicon $self contains ", scalar @{ $self->{'e'} }, " entries:\n\n";
  foreach my $e ( @{ $self->{'e'} } ) {
    $e->dump;
  }
  return $self;
}

#--------------------------------------------------------------------------

=item @them = $lex->entries;

This returns a list of the entry objects in $lex.


=item $them = $lex->entries_as_lol;

This returns a reference to the array of entry objects in $lex.

This can be useful for doing things like C<push @$them, $newentry;>.

This is your only way of altering the entry-list in $lex, other
than read_file and read_handle!

=cut


sub entries {
  my $self = shift;
  return @{ $self->{'e'} } unless @_;
  @{ $self->{'e'} } = @_ ;  # otherwise, be a set method
  return $self;
}

sub tidy_up {
  my $self = $_[0];
  my $entry_class = $self->{'entry_class'} || $ENTRY_CLASS;
  foreach my $e (@{ $self->{'e'} }) {
    if( ref($e) eq 'ARRAY' ) {
      bless $e, $entry_class;
      $e->scrunch unless $self->{'no_scrunch'};
    }
  }
  return $self;
}

sub entries_as_lol { return $_[0]{'e'} }

#--------------------------------------------------------------------------
# Dumb boilerplate accessors:

=back

=head2 Other Attributes

A lexicon object is mainly for just holding a list of entries.  But besides
that list, it also contains these attributes, which you usually don't have
to know about:

=over

=item The "no_scrunch" attribute

Right after read_file (or read_handle) has finished reading entries, it
goes over all of them and calls C<< $e->scrunch >> on each.  (See
L<Text::Shoebox::Entry> for an explanation of the scrunch method.)  But
you can override this by calling $lex->no_scrunch(1) to set the "no_scrunch"
method to a true value.

(You can also explicitly turn this off with $lex->no_scrunch(0), or check
it with $lex->no_scrunch().)


=item The "rs" attribute

When Text::Shoebox::Lexicon reads or writes a lexicon, it normally
lets L<Text::Shoebox> determine the right value for the newline string
(also known as the "RS", even tho for SF format it's not a record
separator at all), and that's usually the right thing.

But if that's not working right and you need to override that newline-guessing
(notably, this might be necessary with
read_handle, which isn't as good as guessing as read_file is), then you
can set the lexicon's C<rs> attribute directly, with C<<
$lex->rs("\cm\cj") >>.  Or you can even force it to the system-default
value with just C<< $lex->rs($/) >>.  Or you can just check the
value of the C<rs> attribute with just C<< $lex->rs() >>.

=back

=cut

sub no_scrunch {
  return $_[0]{'no_scrunch'} if @_ == 1; # get
         $_[0]{'no_scrunch'} = $_[1];    # set...
  return $_[0];
}
sub rs {
  return $_[0]{'rs'} if @_ == 1; # get
         $_[0]{'rs'} = $_[1];    # set...
  return $_[0];
}
#--------------------------------------------------------------------------

1;
__END__

=head1 COPYRIGHT

Copyright 2004, Sean M. Burke C<sburke@cpan.org>, all rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Sean M. Burke, C<sburke@cpan.org>

I hasten to point out, incidentally, that I am not in any way
affiliated with the Summer Institute of Linguistics.

=cut


