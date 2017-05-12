
require 5;
package Text::Shoebox::Entry;
use strict;
use vars qw(@ISA $Debug $VERSION);
use integer;
use Text::Shoebox 1.02 ();
use Carp ();

$Debug = 0 unless defined $Debug;
BEGIN {
  $VERSION = "1.02";
}
my $Array_Class;

unless($Text::Shoebox::Lexicon::VERSION) { require Text::Shoebox::Lexicon; }

###########################################################################

=head1 NAME

Text::Shoebox::Entry - class for Shoebox SF lexicon entries

=head1 SYNOPSIS

  use Text::Shoebox::Lexicon;
  my $lex = Text::Shoebox::Lexicon->read_file( "haida.sf" );

  foreach my $entry ($lex->entries) {
    #
    # Each $entry is a Text::Shoebox::Entry object
    #
    my %e = $entry->as_list;
    print "Looky, stuff! [", %e, "]!\n";
  }

=head1 DESCRIPTION

An object of this class represents an entry in an SF lexicon
(L<Text::Shoebox::Lexicon>).

An entry consists of a number of fields.  Each field has two scalars,
a key, and a value.  The first field in an entry is considered the
headword field, and its key must occur there and only there in that
entry.  There is no requirement on uniqueness of keys in the rest of
the entry.


=head1 METHODS


=over

=item $entry = Text::Shoebox::Entry->new();

=item $entry = Text::Shoebox::Entry->new( 'foo' => 'bar', 'baz' => 'quux' );

The C<new> method creates a new Text::Shoebox::Entry method.  If you
provide parameters, as in the second example, those are used as the
contents of the new object.

Normally you don't need to expressly create objects of this class,
as Text::Shoebox::Lexicon will create them as needed when you call
a Text::Shoebox::Lexicon C<read_file> or C<read_handle> method.

=item $entry2 = $entry->copy

This returns a copy of the object in $entry.

=cut

sub new {  # Text::Shoebox is free to not use this, for speed's sake
  my $class = shift;
  $class = ref($class) || $class; # be an object or a class method
  print "New object in class $class\n" if $Debug;
  if(@_ == 1 and ref($_[0]) eq 'ARRAY') {
    # listref form -- call as: Text::Shoebox::Entry->new([foo => 'bar']);
    return bless $_[0], $class;
  } else {
    # list form -- call as: Text::Shoebox::Entry->new(foo => 'bar');
    return bless [@_], $class;
  }
}

sub copy {
  my $original = $_[0];
  Carp::croak("Text::Shoebox::entry is strictly an object method.")
    unless ref $original;
  return bless( [@$original], ref($original) );
  # bless into the same class as the original
  # presumably a deep copy isn't necessary!
}

#--------------------------------------------------------------------------

=item @keys = $entry->keys;

This returns the names of all the keys (a/k/a fieldnames) in this entry.
For example, if $entry is
C<< ('hw' => 'foo', 'ex' => 'Things', 'ex' => "Stuff") >>,
then $entry->keys will return the list C<('hw', 'ex', 'ex')>.

=item @values = $entry->values;

This returns the values of all fields in this entry.
For example, if $entry is
C<< ('hw' => 'foo', 'ex' => 'Things', 'ex' => "Stuff") >>,
then $entry->values will return the list C<('foo', 'Things', 'Stuff')>.

=cut

sub keys {
  my @out;
  for(my $i = 0; $i < @{$_[0]}; $i += 2) { push @out, $_[0][$i] }
  return @out;
}

sub values {
  my @out;
  for(my $i = 1; $i < @{$_[0]}; $i += 2) { push @out, $_[0][$i] }
  return @out;
}

#--------------------------------------------------------------------------

=item $headword = $entry->headword;

This returns the headword value of this entry.  This is basically
a shortcut for C<< ($entry->values)[0] >>

=item $headword_field = $entry->headword_field;

This returns the fieldname of this entry's headword field.  This
is basically a shortcut for C<< ($entry->keys)[0] >>

=item $value = $entry->_(I<keyname>)

Yes, this method really is called _ !

This gets all the values of the pairs that have the key I<keyname>.  How
it returns those values (of which there may be none, one, or many) depends
on context:

In list context, this simply returns the list of found values.
E.g., if $entry is
C<< ('hw' => 'foo', 'ex' => 'Things', 'ex' => "Stuff") >>,
then C<< $entry->_('hw') >> returns the one-item list C<('foo')>,
then C<< $entry->_('zorp') >> returns the zero-item list C<()>,
and C<< $entry->_('ex') >> returns the two-item list C<('Things', 'Stuff')>.

In scalar context, this returns undef if no values were found.
Otherwise it returns a magical arrayref containing the list of
(one or more) found values.  What's special about these arrayrefs
is that if you treat one as a plain string, you get the useful value
C<join "; ", @$array_ref)>, instead of nonsense like
"ARRAY(0x1555294)".

(Internally, this is implemented just like L<Array::Autojoin>, which see.)

=cut


sub headword       { @{$_[0]} ? $_[0][1] : undef } # simply the first value
sub headword_field { @{$_[0]} ? $_[0][0] : undef } # simply the first key

sub Text::Shoebox::Entry::_ {
  my($self, $key) = @_;
  return unless defined $key;

  my @out;
  for(my $i = 0; $i < @$self; $i += 2) {
    push @out, $self->[$i+1] if $key eq $self->[$i];
  }
  if(wantarray) {
    return @out;
  } else {
    return unless @out;
    return bless \@out, $Array_Class;
  }
}



=item my $num_pairs = $entry->pair_count;

This returns an integer expressing the number of pairs in this entry.
It's basically the same as scalar($entry->keys).


=item ($key, $val) = $entry->pair($n)

This returns the key and value of pair number $n for this entry.
E.g., if $entry is
C<< ('hw' => 'foo', 'ex' => 'Things', 'ex' => "Stuff") >>,
then $entry->pair(1) is the list C<('ex', 'Things')>.


=item ($key, $val, $k2, $v2) = $entry->pairs($n, $m)

This returns the key and value of pair number $n 
and the key and value of pair number $m for this entry.
E.g., if $entry is
C<< ('hw' => 'foo', 'ex' => 'Things', 'ex' => "Stuff") >>,
then $entry->pair(0,2) is the list C<('hw' => 'foo', 'ex', "Stuff")>.

(Actually, C<< $entry->pair(...) >> is just an alias to
C<< $entry->pairs(...) >>.)


=cut

sub pair_count { return @{$_[0]} / 2; }

sub pair { (shift)->pairs(@_) } #alias

sub pairs { # also good for accessing one pair, or none!
  # get pair #3 (assuming counting from 0) :  ($k,$v) = $e->pairs(3);
  my $o = shift;
  map { @{$o}[$_ * 2, $_ * 2 + 1] } @_;
   # map to slices. Better be legal offsets!
   # e.g., 3 maps to @{$o}[6,7]
}

#--------------------------------------------------------------------------

=item $true_or_false = $entry->are_keys_unique;

This returns true iff every keyname in this entry appears only once.

=item $entry->assert_keys_unique;

This dies unless C<< $entry->are_keys_unique >> is true.

=cut

sub are_keys_unique {
  # returns true iff the keys are unique in this entry.
  # i.e., if no headword occurs twice (or more)
  return 1 if @{$_[0]} < 2; # can't have collisions with just one key!

  my %seen;
  for(my $i = 0; $i < @{$_[0]}; $i += 2) {
    return 0 if $seen{$_[0][$i]}++;
  }
  return 1;
}

sub assert_keys_unique {
  return $_[0] if $_[0]->are_keys_unique;
  my $e = shift;
  my @k = $e->keys;
  my %seen;
  for my $k (@k) { ++$seen{$k} }
  for my $k (@k) { $k = uc $k if $seen{$k} > 1 }
  Carp::croak "Entry $e \"$$e[1]\" has duplicate keys: [@k]\nAborting";
}


=item $true_or_false = $entry->is_null

This returns true iff this entry is empty.  This is basically the same
as C<< 0 == $entry->pair_count >>.

=item $true_or_false = $entry->is_sane

This returns true iff this entry is non-null, contains no
references, and if no keyname is undef or zero-length.

=item $entry->scrunch;

For all values in this entry, this compacts all whitespace, deletes
leading and trailing whitespace, and deletes any pairs where the
value is blank.  (Where "blank" means undef, zero-length, or
is all-whitespace.)

=item $entry->dump;

This prints (not returns!) a representation of this object's contents.

=cut


sub is_null { return( @{$_[0]} == 0 ) }

sub is_sane {
  my $e = $_[0];
  return 0 unless @$e; # empty entries are not sane
  for(my $i = 0; $i < @{$_[0]}; $i += 2) { # scan keys
    return 0 unless defined $e->[$i] and length $e->[$i];
     # all keys have to be defined and be non-null
    return 0 if ref $e->[$i] or ref $e->[$i+1];
     # no references anywhere!
  }
  return 1;
}

#--------------------------------------------------------------------------

sub scrunch {
  my $e = $_[0];
  for(my $i = 1; $i < @$e; $i += 2) { # scan keys
    unless( defined $e->[$i] and $e->[$i] =~ m/\S/ ) {
      splice @$e, $i-1, 2;  # nix K=>V where V is null or all-whitespace
      $i-=2;
    }
    $e->[$i] =~ s/^\s+//s;
    $e->[$i] =~ s/\s+$//s;
    $e->[$i] =~ s/[ \t]*[\n\r]+[ \t]*/ /g;
     # remove newlines and any whitespace around them
  }
  return $e;
}

#--------------------------------------------------------------------------

sub dump {
  my $e = $_[0];

  print "Entry $e contains:\n";

  my $safe;
  my $toggle = 0;
  foreach my $v (@$e) {
    ($safe = $v) =~ 
            s<([^\x20\x21\x23\x27-\x3F\x41-\x5B\x5D-\x7E\xA1-\xFE])>
             <$Text::Shoebox::p{$1}>eg;
    print(
      ($toggle ^= 1) ? qq{  $safe = } : qq{"$safe"\n} 
    );
  }
  print "\n";
  return $e;
}

#--------------------------------------------------------------------------

=item @it = $entry->as_list

This returns a list expressing the contents of $entry.
For example, if $entry is
C<< ('hw' => 'foo', 'ex' => 'Things', 'ex' => "Stuff") >>,
then this returns just that,
C<< ('hw' => 'foo', 'ex' => 'Things', 'ex' => "Stuff") >>.

=item $them = $entry->as_arrayref

This returns an arrayref (probably blessed) to the contents
of $entry.  For example, if $entry is
C<< ('hw' => 'foo', 'ex' => 'Things', 'ex' => "Stuff") >>,
then this will return an arrayred to just that list.

Note that this (and as_HoLS) is like the other C<as_I<thing>>
methods, in that this doesn't return any sort of copy; it returns
a reference to the entry's array itself -- if you do $them->[1] = 'x',
then $entry's contents change to
C<< ('hw' => 'x', 'ex' => 'Things', 'ex' => "Stuff") >>.)

(Internally, this method is implemented by simply returning
$entry itself, since I<in the current implementation>,
$entry I<is> just a blessed arrayref to the C<(k,v,k,v,...)>
list it contains.)

=item $h = $entry->as_hashref

This returns a hashref expressing the contents of $entry
as a C<< {key => value,...} >> hash, I<discarding duplicates.>
For example, if $entry is
C<< ('hw' => 'foo', 'ex' => 'Things', 'ex' => "Stuff") >>,
then this returns
C<< { 'hw' => 'foo', 'ex' => "Stuff" } >>.

=cut

sub as_list     { return  @{$_[0]}  }
sub as_arrayref { return    $_[0]   }
sub as_hashref  { return {@{$_[0]}} }




=item $hol = $entry->as_HoL

This returns a reference to a hash-of-lists expressing
the contents of this entry, i.e., a reference to a hash where
every value is an arrayref.  Note that this doesn't destroy
duplicates.

For example, if $entry is
C<< ('hw' => 'foo', 'ex' => 'Things', 'ex' => "Stuff") >>,
then this returns
C<< { 'hw' => ['foo'], 'ex' => ['Things', 'Stuff'] } >>.

And there's a useful bit of magic added -- the arrayrefs aren't just
plain arrayrefs, they're special arrayrefs (implemented
just like L<Array::Autojoin>) such that if you treat one
as a plain string, you get the useful value
C<join "; ", @$array_ref)>, instead of nonsense like
"ARRAY(0x1555294)".

=cut


sub as_HoL {
  my $e = $_[0];
  my %h;
  for(my $i = 0; $i < @$e; $i += 2) {
    push @{ $h{ $e->[$i] } ||= []}, $e->[$i+1];
  }
  foreach my $v (CORE::values %h) { bless $v, $Array_Class }
  \%h;
}


=item $hol = $entry->as_HoLS

This returns a hashref where every value is a reference to an array
of scalar-refs to the value-slots in $entry.  This is so you can
alter $entry.  (This and $entry->as_arrayref are really the only ways
to alter an entry objects's content.)

This sounds (and is) very circuitous, but it's like this:
If $entry is
C<< ('hw' => 'foo', 'ex' => 'Things', 'ex' => "Stuff") >>,
then this returns
C<< { 'hw' => [$fooslot], 'ex' => [$thingsslot, $stuffslot] } >>,
where if you do C<$$thingslot = 'gack'>, then $entry then becomes
C<< ('hw' => 'foo', 'ex' => B<'gack'>, 'ex' => "Stuff") >>.

=cut

sub as_HoLS { # ref to a hash of list of refs to each of the value slots
  my $e = $_[0];
  my %h;
  for(my $i = 0; $i < @$e; $i += 2) {
    push @{
           $h{ $e->[$i] } ||= []
          },  \$e->[$i + 1];
  }
  \%h;
}



=item $hol = $entry->as_doublets

This returns this entry as a list of "doublets" -- i.e., 
as a list of two-item arrayrefs.

For example, if $entry is
C<< ('hw' => 'foo', 'ex' => 'Things', 'ex' => "Stuff") >>,
then this returns the list
C<< (['hw','foo'], ['ex','Things'], ['ex','Stuff']) >>.

=cut

sub as_doublets {
  # returns this entry...
  #     (hw => 'shash', english => 'bear')
  # as this...
  #     ([hw => 'shash'], [english => 'bear'])
  my @out;
  for(my $i = 0; $i < @{$_[0]}; $i += 2) {
    push @out, [ @{ $_[0] }[$i, $i+1] ];
  }
  return @out;
}



=item $xml_source = $entry->as_xml()

=item $xml_source = $entry->as_xml( I<TagNameHash> )

This returns an XML representation of this entry's contents.  In short,
For example, if $entry is
C<< ('hw' => 'foo', 'ex' => 'Things', 'ex' => "Stuff") >>,
then this returns this string:

    <hw>foo</hw>
    <ex>Things</ex>
    <ex>Stuff</ex>

The only details arise from the problem of how to turn $entry's keynames
into XML tag names.  For each key, if it's present in the optional TagNameHash
hashref parameter, then that value (C<< $tagnamehash->{$keyname} >>) is used;
otherwise, $keyname itself is used, stripped of characters other than
C<a-zA-Z0-9>, colon, underscore, period, and dash.



=item $xml_source = $entry->as_xml_pairs()

=item $xml_source = $entry->as_xml_pairs( I<PairTagName, KeyAttrName, ValAttrName>)

This returns an XML representation of this entry's contents.  In short,
For example, if $entry is
C<< ('hw' => 'foo', 'ex' => 'Things', 'ex' => "Stuff") >>,
then this returns this string:

    <pair key="hw" value="foo" />
    <pair key="ex" value="Things" />
    <pair key="ex" value="Stuff" />

This avoids the problem of how to turn keynames into XML tagnames.
If you don't like the choice of the pair tagname (by default, "pair")
or the key attribute name (by default, "key"),
or the value attribute name (by default, "value"), then you can
specify new values as the parameters.  So if you call
C<<
$entry->as_xml_pairs( 'fee' , 'fie', 'Foe:Fum')
>>, the return value is:

    <fee fie="hw" Foe:Fum="foo" />
    <fee fie="ex" Foe:Fum="Things" />
    <fee fie="ex" Foe:Fum="Stuff" />

=cut

sub as_xml {
  # Yes, VERY simpleminded.  And note that the result is NOT wrapped
  #  in an <entry>...</entry> or anything.

  # returns this entry...
  #     (hw => 'shash', english => 'bear')
  # as this...
  #     " <hw>shash</hw>\n<english>bear</english>\n"

  # Consider this entry more as a suggestion, and as a debugging tool, than
  #  anything else.

  # Optional first parameter: a reference to a hash mapping key names
  #  to tags.  E.g., $e->as_xml({hw => 'headword', english => 'gloss'})
  # will give you this:
  #     " <headword>shash</headword>\n<gloss>bear</gloss>\n"

  my $map = ref($_[1]) ? $_[1] : {};

  my(@out, $k, $v);
  for(my $i = 0; $i < @{$_[0]}; $i += 2) {
    ($k,$v) = @{$_[0]}[$i, 1 + $i];

    if(exists $map->{$k}){
      $k = $map->{$k};
    } else {
      # spiff up the key name so it's an okay GI (tag name)
      $k =~ tr<-._:a-zA-Z0-9><_>cd; # Yes, this is conservative
      if(length $k) {
        $k = '_' . $k unless $k =~ m<^[_:a-zA-Z]>s;
        # prefix unsafe things.
      } else { # to avoid a null GI
        $k = 'NULL';
      }
    }

    $v =~ s/&/&amp;/g;
    $v =~ s/</&lt;/g ;
    $v =~ s/>/&gt;/g ;
    push @out, " <$k>$v</$k>\n";
  }
  return join '', @out;
}

sub as_xml_pairs {
  # A bit less pointless.  And note that the result is still not wrapped
  #  in an <entry>...</entry> or anything.

  # Returns this entry...
  #     (hw => 'shash', english => 'bear')
  # as this...
  #     " <pair key="hw" value="shash" /><pair key="english" value="bear"/>\n"

  # Consider this entry more as a suggestion, and as a debugging tool, than
  #  anything else.

  # Calling format: $e->as_xml_pairs(TAGNAME, KEYNAME, VALUENAME)
  #  TAGNAME defaults to 'pair'.
  #  KEYNAME defaults to 'key'.
  #  VALUENAME defaults to 'value'.

  my($o, $gi, $key_name, $value_name) = @_;
  $gi         ||= 'pair'  ;
  $key_name   ||= 'key'   ;
  $value_name ||= 'value' ;

  my(@out, $k, $v);
  for(my $i = 0; $i < @$o; $i += 2) {
    ($k,$v) = @{$o}[$i, 1 + $i];
    foreach my $x ($k, $v) {
      # NB: Doesn't entitify apostrophes.  No point, really.
      $x =~ s/&/&amp;/g;
      $x =~ s/"/&quot;/g;
      $x =~ s/</&lt;/g;
      $x =~ s/>/&gt;/g;
      $x =~ s<([\n\t\cm\cj])>
             <'&#'.(ord($1)).';'>seg;
       # turn newlines into character references
    }
    push @out, " <$gi $key_name=\"$k\" $value_name=\"$v\" />\n"
  }

  return join '', @out;
}

###########################################################################
{
  # Basically just the guts of Array::Autojoin:

  package Text::Shoebox::Entry::_Autojoin;
  $Array_Class = __PACKAGE__;

  use overload(

    '""' => sub {    join '; ', @{$_[0]}},

    '0+' => sub {0 + ( $_[0][0] || 0  ) },
     # stringifies and then just numerifies, but feh.

    'fallback' => 1,  # turn on cleverness

    'bool', => sub {  # true iff there's any true items in it
      for (@{$_[0]}) { return 1 if $_ };
      return '';
    },

    '.=' => sub {  # sure, why not.
      if(@{$_[0]}) { $_[0][-1] .= $_[1] } else { push @{$_[0]}, $_[1] }
      $_[0];
    },  # but can't overload ||= or the like

  );
}
###########################################################################
1;

__END__


=back



=head1 COPYRIGHT

Copyright 2004, Sean M. Burke C<sburke@cpan.org>, all rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Sean M. Burke, C<sburke@cpan.org>

I hasten to point out, incidentally, that I am not in any way
affiliated with the Summer Institute of Linguistics.

=cut

