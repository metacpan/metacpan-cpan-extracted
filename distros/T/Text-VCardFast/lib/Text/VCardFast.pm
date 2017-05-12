package Text::VCardFast;

use strict;
use warnings;

use Encode qw(decode_utf8 encode_utf8);
use MIME::Base64 qw(decode_base64 encode_base64);

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::VCardFast ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	vcard2hash
	hash2vcard
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	vcard2hash
	hash2vcard
);

our $VERSION = '0.11';

require XSLoader;
XSLoader::load('Text::VCardFast', $VERSION);

# public API

sub vcard2hash { &vcard2hash_c }
sub hash2vcard { &hash2vcard_pp }

# Implementation

sub vcard2hash_c {
    my $vcard = shift;
    my %params = @_;
    if (utf8::is_utf8($vcard)) {
        utf8::encode($vcard);
        $params{is_utf8} = 1;
    }
    unless ($vcard =~ m/\n\S/) {
        # cruddy card with \r as line separator?
        $vcard =~ tr/\r/\n/;
    }
    my $hash = Text::VCardFast::_vcard2hash($vcard, \%params);
    return $hash;
}

# pureperl version

# VCard parsing and formatting {{{

my %RFC6868Map = ("n" => "\n", "^" => "^", "'" => "\"");
my %RFC6868RevMap = reverse %RFC6868Map;
my %UnescapeMap = ("n" => "\n", "N" => "\n");

my $Pos = 1;
my @PropOutputOrder = qw(version fn n nickname lang gender org title role bday anniversary email tel adr url impp);
my %PropOutputOrder = map { $_ => $Pos++ } @PropOutputOrder;
my @ParamOutputOrder = qw(type pref);
my %ParamOutputOrder = map { $_ => $Pos++ } @ParamOutputOrder;

sub vcard2hash_pp {
  my $vcard = shift;
  unless ($vcard =~ m/\n\S/) {
    # cruddy card with \r as line separator?
    $vcard =~ tr/\r/\n/;
  }
  my %params = @_;
  return vcardlines2hash_pp(\%params, (split /\r?\n/, $vcard));
}

sub vcardlines2hash_pp {
  my $args = shift;
  local $_;

  my %MultiFieldMap;
  my %MultiParamMap;
  if ($args->{multival}) {
    %MultiFieldMap = map { $_ => 1 } @{$args->{multival}};
  }
  if ($args->{multiparam}) {
    %MultiParamMap = map { $_ => 1 } @{$args->{multiparam}};
  }

  # rfc2425, rfc2426, rfc6350, rfc6868

  my @Path;
  my $Current;
  while ($_ = shift @_) {
    # Strip EOL
    s/\r?\n$//;

    # 5.8.1 - Unfold lines if next line starts with space or tab
    if (@_ && $_[0] =~ s/^[ \t]//) {
      $_ .= shift @_;
      redo;
    }

    # Ignore empty lines
    next if /^\s*$/;

    if (/^BEGIN:(.*)/i) {
      push @Path, $Current;
      $Current = { type => lc $1 };
      push @{ $Path[-1]{objects} }, $Current;
      next;
    }
    if (/^END:(.*)/i) {
      die "END $1 in $Current->{type}"
        unless $Current->{type} eq lc $1;
      $Current = pop @Path;
      return $Current if ($args->{only_one} and not @Path);
      next;
    }

    # 5.8.2 - Parse '[group "."] name *(";" param) ":" value'
    #  In v2.1, params may not have "=value" part
    #  In v4, "," is allowed in non-quoted param value
    my ($Name) = /^([^;:]*)/gc;
    my @Params = /\G;(?:([\w\-]+)=)?("[^"]*"|[^";:=]*)/gc;
    my ($Value) = /\G:(.*)$/g;

    # 5.8.2 - Type names and parameter names are case insensitive
    my $LName = lc $Name;

    my %Props;

    # Remove group from each property name and add as attribute
    #  (in v4, group names are case insensitive as well)
    if ($LName =~ s/^(.+)\.(.*?)$/$2/) {
      $Props{group} = $1;
    }

    $Props{name} = $LName;

    # Parse out parameters
    my %Params;
    while (@Params) {
      # Parsed into param => param-value pairs
      my ($PName, $PValue) = splice @Params, 0, 2;
      if (not defined $PName) {
        if ($args->{barekeys}) {
          $PName = $PValue;
          $PValue = undef;
        }
        else {
          $PName = 'type';
        }
      }

      # 5.8.2 - parameter names are case insensitive
      my $LPName = lc $PName;

      my @PValue = (undef);
      if (defined $PValue) {
        $PValue =~ s/^"(.*)"$/$1/;
        # \n needed for label, but assume any \; is meant to be ; as well
        $PValue =~ s#\\(.)#$UnescapeMap{$1} // $1#ge;
        # And RFC6868 recoding
        $PValue =~ s/\^([n^'])/$RFC6868Map{$1}/g;
        if ($MultiParamMap{$LPName}) {
          @PValue = split /,/, $PValue;
        }
        else {
          @PValue = ($PValue);
        }
      }

      if (exists $Params{$LPName}) {
        push @{$Params{$LPName}}, @PValue;
      } else {
        $Params{$LPName} = \@PValue;
      }
    }
    $Props{params} = \%Params if keys %Params;

    my $Encoding = $Params{encoding};

    if ($MultiFieldMap{$LName}) {
      # use negative 'limit' to force trailing fields
      $Value = [ split /(?<!\\);/, $Value, -1 ];
      s#\\(.)#$UnescapeMap{$1} // $1#ge for @$Value;
      $Props{values} = $Value;
    } elsif ($Encoding && lc $Encoding eq 'b') {
      # Don't bother unescaping base64 value

      $Props{value} = $Value;
    } else {
      $Value =~ s#\\(.)#$UnescapeMap{$1} // $1#ge;
      $Props{value} = $Value;
    }

    push @{$Current->{properties}->{$LName}}, \%Props;
  }

  # something did a BEGIN but no END - TODO, unwind this nicely as
  # it may be more than one level
  die "BEGIN $Current->{type} without matching END"
    if @Path;

  return $Current;
}

sub hash2vcard_pp {
  return join "", map { $_ . ($_[1] // "\n") } hash2vcardlines_pp($_[0]);
}

sub hash2vcardlines_pp {
  my $Objects = shift->{objects} // [];

  my @Lines;
  for my $Card (@$Objects) {
    # We group properties in the same group together, track if we've
    #  already output a property
    my %DoneProps;

    my $Props = $Card->{properties};

    # Order the properties
    my @PropKeys = sort {
      ($PropOutputOrder{$a} // 1000) <=> ($PropOutputOrder{$b} // 1000)
        || $a cmp $b
    } keys %$Props;

    # Make sure items in the same group are output together
    my $Groups = $Card->{groups} || do {
      my %Groups;
      for (map { @$_ } values %$Props) {
	push @{$Groups{$_->{group}}}, $_ if $_->{group};
      }
      \%Groups;
    };

    # Generate output list
    my @OutputProps;
    for my $PropKey (@PropKeys) {
      my @PropVals = @{$Props->{$PropKey}};
      for my $PropVal (@PropVals) {
        next if $DoneProps{"$PropVal"}++;

        push @OutputProps, $PropVal;

        # If it has a group, output all values in that group together
        if (my $Group = $PropVal->{group}) {
          push @OutputProps, grep { !$DoneProps{"$_"}++ } @{$Groups->{$Group}};
        }
      }
    }

    my $Type = uc $Card->{type};
    push @Lines, ("BEGIN:" . $Type);

    for (@OutputProps) {
      # Skip deleted or synthetic properties
      next if $_->{deleted} || $_->{name} eq 'online';

      my $Binary = $_->{binary};
      if ($Binary) {
        my $Encoding = ($_->{params}->{encoding} //= []);
        push @$Encoding, "b" if !@$Encoding;
      }

      my $LName = $_->{name};
      my $Group = $_->{group};

      # rfc6350 3.3 - it is RECOMMENDED that property and parameter names be upper-case on output.
      my $Line = ($Group ? (uc $Group . ".") : "") . uc $LName;

      while (my ($Param, $ParamVals) = each %{$_->{params} // {}}) {
        if (!defined $ParamVals) {
          $Line .= ";" . uc($Param);
        }
        for (ref($ParamVals) ? @$ParamVals : $ParamVals) {
          my $PV = $_ // next; # Modify copy
          $PV =~ s/\n/\\N/g if $Param eq 'label';
          $PV =~ s/([\n^"])/'^' . $RFC6868RevMap{$1}/ge;
          $PV = '"' . $PV . '"' if $PV =~ /\W/;
          $Line .= ";" . uc($Param) . "=" . $PV;
        }
      }
      $Line .= ":";

      my $Value = $_->{values} || $_->{value};

      if ($_->{binary}) {
        $Value = encode_base64($Value, '');

      } else {
        my @Values = map {
          my $V = ref($_) ? $$_ : $_; # Modify copy
          $V //= '';
          # rfc6350 3.4 (v4, assume clarifies many v3 semantics)
          # - a SEMICOLON in a field of such a "compound" property MUST be
          #   escaped with a BACKSLASH character
          # - a COMMA character in one of a field's values MUST be escaped
          #   with a BACKSLASH character
          # - BACKSLASH characters in values MUST be escaped with a BACKSLASH
          #   character.
          $V =~ s/([\,\;\\])/\\$1/g;
          # - NEWLINE (U+000A) characters in values MUST be encoded
          #   by two characters: a BACKSLASH followed by either an 'n' (U+006E)
          #   or an 'N' (U+004E).
          $V =~ s/\n/\\n/g;
          $V;
        } ref $Value ? @$Value : $Value;

        $Value = join ";", @Values;

        # Stripped v4 proto prefix, add it back
        if (my $ProtoStrip = $_->{proto_strip}) {
          $Value = $ProtoStrip . $Value;
        }

        # If it's a perl unicode string, make it utf-8 bytes
        #if (utf8::is_utf8($Value)) {
          #$Value = encode_utf8($Value);
        #}
      }

      $Line .= $Value;

      push @Lines, foldline($Line);
    }

    push @Lines, hash2vcardlines_pp($Card);

    push @Lines, "END:" . $Type;
  }

  return @Lines;
}

sub foldline {
  local $_ = shift;

  # Fold at every \n, regardless of position
  # Try folding on at whitespace boundaries after 60 chars first
  # Otherwise fold to 75 chars, but don't split utf-8 unicode char or end with a \
  my @Out;
  while (/\G(.{0,75}?\\n)/gc || /\G(.{60,75})(?<=[^\n\t ])(?=[\n\t ])/gc || /\G(.{0,74}[^\\])(?![\x80-\xbf])/gc) {
    push @Out, (@Out ? " " . $1 : $1);
  }
  push @Out, " " . substr($_, pos($_)) if pos $_ != length $_;

  return @Out;
}

# }}}

1;

1;
__END__
=head1 NAME

Text::VCardFast - Perl extension for very fast parsing of VCards

=head1 SYNOPSIS

  use Text::VCardFast;

  my $hash = Text::VCard::vcard2hash($card, multival => ['adr', 'org', 'n']);
  my $card = Text::VCard::hash2vcard($hash, "\r\n");

=head1 DESCRIPTION

Text::VCardFast is designed to parse VCards very quickly compared to
pure-perl solutions.  It has a perl and an XS version of the same API,
accessible as vcard2hash_pp and vcard2hash_c, with the XS version being
preferred.

Why would you care?  We were writing the calendaring code for fastmail.fm,
and it was taking over 6 seconds to draw respond to a request for calendar
data, and the bulk was going to the perl middleware layer - and THAT
profiled down to the vcard parser.

Two of us independently wrote better pure perl implementations, leading to
about a 5 times speedup in each case.  I figured it was worth checking if
XS would be much better.  Here's the benchmark on the v4 example from
Wikipedia:

    Benchmark: timing 10000 iterations of fastxs, pureperl, vcardasdata...
        fastxs:  0 wallclock secs ( 0.16 usr +  0.01 sys =  0.17 CPU) @ 58823.53/s (n=10000)
                (warning: too few iterations for a reliable count)
      pureperl:  1 wallclock secs ( 1.04 usr +  0.00 sys =  1.04 CPU) @ 9615.38/s (n=10000)
    vcardasdata:  8 wallclock secs ( 7.35 usr +  0.00 sys =  7.35 CPU) @ 1360.54/s (n=10000)

(see bench.pl in the source tarball for the code)

=head2 EXPORT

  vcard2hash
  hash2vcard

=head2 API

=over

=item Text::VCard::vcard2hash($card, %options);

  Options:

  * only_one - A flag which, if true, means parsing will stop after
    extracting a single VCard from the buffer.  This is very useful
    in cases where, for example, a disclaimer has been added after
    a calendar event in an email.

  * multival - A list of entry names which will be considered to have
    multiple values.  Instead of having a 'value' field in the hash,
    entries with this key will have a 'values' field containing an
    arrayref of values - even if there is only one value.
    The value is split on semicolon, with escaped semicolons decoded
    correctly within each item.

    Default is the empty list.

  * multiparam - As with values - multiparam is a list of entry names
    which can have multiple values.  To see the difference here you
    must consider something like this:

    EMAIL;TYPE="INTERNET,HOME";TYPE=PREF:example@example.com

    If 'multiparam' includes 'TYPE' then the result will be:
    ['INTERNET', 'HOME', 'PREF'], otherwise it will be:
    ['INTERNET,HOME', 'PREF'].

    Default is the empty list.

  * barekeys - if set, then a bare parameter will be considered to be
    a parameter name with an undefined value, rather than a being a
    value for the parameter type.

    Consider:

    EMAIL;INTERNET;HOME:example@example.com

    barekeys off:

    {
      name => 'email',
      params => { type => ['INTERNET', 'HOME'] },
      value => 'example@example.com',
    }

    barekeys on:

    {
      name => 'email',
      params => { internet => [undef], home => [undef] },
      value => 'example@example.com',
    }

    default is barekeys off.

  The input is a scalar containing VFILE text, as per RFC 6350 or the various
  earlier RFCs it replaces.  If the perl unicode flag is set on the scalar,
  then it will be propagated to the output values.

  The output is a hash reference containing a single key 'objects', which is
  an array of all the cards within the source text.

  Each object can have the following keys:
  * type - the text after BEGIN: and END: of the card (lower cased)
  * properties - a hash from name to array of instances within the card.
  * objects - an array of sub cards within the card.

  Properties are a hash with the following keys:
  * group - optional - if the propery name as 'foo.bar', this will be foo.
  * name - a copy of the hash key that pointed to this property, so that
    this hash can be used without keeping the key around too
  * params - a hash of the parameters on the entry.  This is everything from
    the ; to the :
  * value - either a scalar (if not a multival field) or an array of values.
    This is everything after the :

  Decoding is done where possible, including RFC 6868 handling of ^.

  All names, both entry names and parameter names, are lowercased where the
  RFC says they are not case significant.  This means that all hash keys are
  lowercase within this API, as are card types.

  Values, on the other hand, are left in their original case even where the
  RFC says they are case insignificant - due to the increased complexity of
  tracking which version what parameters are in effect.

=item Text::VCard::hash2vcard($hash, $eol)

  The inverse operation (as much as possible!)

  Given a hash with an 'objects' key in it, output a scalar string containing
  the VCARD representation.  Lines are separated with the $eol string given,
  or the default "\n".  Use "\r\n" for files going to caldav/carddav servers.

  In the inverse of the above case, where names are case insignificant, they
  are generated in UPPERCASE in the card, for maximum compatibility with
  other implementations.

=back

=head1 EXAMPLES

  For more examples see the t/cases directory in the tarball, which contains
  some sample VCARDs and JSON dumps of the hash representation.

  BEGIN:VCARD
  KEY;PKEY=PVALUE:VALUE
  KEY2:VALUE2
  END:VCARD

  {
  'objects' => [
    {
      'type' => 'vcard',
      'properties' => {
        'key2' => [
          {
            'value' => 'VALUE2',
            'name' => 'key2'
          }
        ],
        'key' => [
          {
            'params' => {
              'pkey' => [
                'PVALUE'
              ]
            },
            'value' => 'VALUE',
            'name' => 'key'
          }
        ]
      }
    }
  ]
  }

  BEGIN:VCARD
  BEGIN:SUBCARD
  KEY:VALUE
  END:SUBCARD
  END:VCARD

  {
  'objects' => [
    {
      'objects' => [
        {
          'type' => 'subcard',
          'properties' => {
            'key' => [
              {
                'value' => 'VALUE',
                'name' => 'key'
              }
            ]
          }
        }
      ],
      'type' => 'vcard',
      'properties' => {}
    }
  ]
  }

  BEGIN:VCARD
  GROUP1.KEY:VALUE
  GROUP1.KEY2:VALUE2
  GROUP2.KEY:VALUE
  END:VCARD

  {
  'objects' => [
    {
      'type' => 'vcard',
      'properties' => {
        'key2' => [
          {
            'group' => 'group1',
            'value' => 'VALUE2',
            'name' => 'key2'
          }
        ],
        'key' => [
          {
            'group' => 'group1',
            'value' => 'VALUE',
            'name' => 'key'
          },
          {
            'group' => 'group2',
            'value' => 'VALUE',
            'name' => 'key'
          }
        ]
      }
    }
  ]
  }


=head1 SEE ALSO

There is a similar module Text::VFile::asData on CPAN, but it is much
slower and doesn't do as much decoding.

Code is stored on github at

https://github.com/brong/Text-VCardFast/

=head1 AUTHOR

Bron Gondwana, E<lt>brong@fastmail.fm<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Bron Gondwana

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
