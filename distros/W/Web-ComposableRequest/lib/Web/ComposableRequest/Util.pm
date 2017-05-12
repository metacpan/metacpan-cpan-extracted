package Web::ComposableRequest::Util;

use strictures;
use parent 'Exporter::Tiny';

use Digest::MD5   qw( md5 md5_hex );
use Encode        qw( decode );
use English       qw( -no_match_vars );
use List::Util    qw( first );
use Scalar::Util  qw( blessed );
use Subclass::Of;
use Sys::Hostname qw( hostname );
use URI::Escape   qw( );
use URI::http;
use URI::https;
use Web::ComposableRequest::Constants qw( EXCEPTION_CLASS LANG );

our @EXPORT_OK  = qw( add_config_role base64_decode_ns base64_encode_ns bson64id
                      bson64id_time compose_class decode_array decode_hash
                      extract_lang first_char is_arrayref is_hashref is_member
                      list_config_roles merge_attributes new_uri trim thread_id
                      throw uri_escape );

my $bson_id_count  = 0;
my $bson_prev_time = 0;
my $class_stash    = {};
my @config_roles   = ();
my $host_id        = substr md5( hostname ), 0, 3;
my $reserved       = q(;/?:@&=+$,[]);
my $mark           = q(-_.!~*'());                                   #'; emacs
my $unreserved     = "A-Za-z0-9\Q${mark}\E%\#";
my $uric           = quotemeta( $reserved ) . '\p{isAlpha}' . $unreserved;

# Private functions
my $_base64_char_set = sub {
   return [ 0 .. 9, 'A' .. 'Z', '_', 'a' .. 'z', '~', '+' ];
};

my $_index64 = sub {
   return [ qw(XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX 64  XX XX XX XX
                0  1  2  3   4  5  6  7   8  9 XX XX  XX XX XX XX
               XX 10 11 12  13 14 15 16  17 18 19 20  21 22 23 24
               25 26 27 28  29 30 31 32  33 34 35 XX  XX XX XX 36
               XX 37 38 39  40 41 42 43  44 45 46 47  48 49 50 51
               52 53 54 55  56 57 58 59  60 61 62 XX  XX XX 63 XX

               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX) ];
};

my $_base64_decode_ns = sub {
   my $x = shift; defined $x or return; my @x = split q(), $x;

   my $index = $_index64->(); my $j = 0; my $k = 0;

   my $len = length $x; my $pad = 64; my @y = ();

 ROUND: {
    while ($j < $len) {
       my @c = (); my $i = 0;

       while ($i < 4) {
          my $uc = $index->[ ord $x[ $j++ ] ];

          $uc ne 'XX' and $c[ $i++ ] = 0 + $uc; $j == $len or next;

          if ($i < 4) {
             $i < 2 and last ROUND; $i == 2 and $c[ 2 ] = $pad; $c[ 3 ] = $pad;
          }

          last;
       }

      ($c[ 0 ]   == $pad || $c[ 1 ] == $pad) and last;
       $y[ $k++ ] = ( $c[ 0 ] << 2) | (($c[ 1 ] & 0x30) >> 4);
       $c[ 2 ]   == $pad and last;
       $y[ $k++ ] = (($c[ 1 ] & 0x0F) << 4) | (($c[ 2 ] & 0x3C) >> 2);
       $c[ 3 ]   == $pad and last;
       $y[ $k++ ] = (($c[ 2 ] & 0x03) << 6) | $c[ 3 ];
    }
 }

   return join q(), map { chr $_ } @y;
};

my $_base64_encode_ns = sub {
   my $x = shift; defined $x or return; my @x = split q(), $x;

   my $basis = $_base64_char_set->(); my $len = length $x; my @y = ();

   for (my $i = 0, my $j = 0; $len > 0; $len -= 3, $i += 3) {
      my $c1 = ord $x[ $i ]; my $c2 = $len > 1 ? ord $x[ $i + 1 ] : 0;

      $y[ $j++ ] = $basis->[ $c1 >> 2 ];
      $y[ $j++ ] = $basis->[ (($c1 & 0x3) << 4) | (($c2 & 0xF0) >> 4) ];

      if ($len > 2) {
         my $c3 = ord $x[ $i + 2 ];

         $y[ $j++ ] = $basis->[ (($c2 & 0xF) << 2) | (($c3 & 0xC0) >> 6) ];
         $y[ $j++ ] = $basis->[ $c3 & 0x3F ];
      }
      elsif ($len == 2) {
         $y[ $j++ ] = $basis->[ ($c2 & 0xF) << 2 ];
         $y[ $j++ ] = $basis->[ 64 ];
      }
      else { # len == 1
         $y[ $j++ ] = $basis->[ 64 ];
         $y[ $j++ ] = $basis->[ 64 ];
      }
   }

   return join q(), @y;
};

my $_bsonid_inc = sub {
   my $now = shift; $bson_id_count++;

   $now > $bson_prev_time and $bson_id_count = 0; $bson_prev_time = $now;

   return (pack 'n', thread_id() % 0xFFFF ).(pack 'n', $bson_id_count % 0xFFFF);
};

my $_bsonid_time = sub {
   my $now = shift;

   return (substr pack( 'N', $now >> 32 ), 2, 2).(pack 'N', $now % 0xFFFFFFFF);
};

my $_bson_id = sub {
   my $now = time; my $pid = pack 'n', $PID % 0xFFFF;

   return $_bsonid_time->( $now ).$host_id.$pid.$_bsonid_inc->( $now );
};

# Exported functions
sub add_config_role ($) {
   my $role = shift; return push @config_roles, $role;
}

sub base64_decode_ns ($) {
   return $_base64_decode_ns->( $_[ 0 ] );
}

sub base64_encode_ns (;$) {
   return $_base64_encode_ns->( $_[ 0 ] );
}

sub bson64id (;$) {
   return $_base64_encode_ns->( $_bson_id->() );
}

sub bson64id_time ($) {
   return unpack 'N', substr $_base64_decode_ns->( $_[ 0 ] ), 2, 4;
}

sub compose_class ($$;@) {
   my ($base, $params, %options) = @_;

   my @params = keys %{ $params // {} }; @params > 0 or return $base;

   my $class = "${base}::".(substr md5_hex( join q(), @params ), 0, 8);

   exists $class_stash->{ $class } and return $class_stash->{ $class };

   my $is = $options{is} // 'ro'; my @attrs;

   for my $name (@params) {
      my ($type, $default) = @{ $params->{ $name } };
      my $props            = [ is => $is, isa => $type ];

      defined $default and push @{ $props }, 'default', $default;
      push @attrs, $name, $props;
   }

   return $class_stash->{ $class } = subclass_of
      ( $base, -package => $class, -has => [ @attrs ] );
}

sub decode_array ($$) {
   my ($enc, $param) = @_;

   (not defined $param->[ 0 ] or blessed $param->[ 0 ]) and return;

   for (my $i = 0, my $len = @{ $param }; $i < $len; $i++) {
      $param->[ $i ] = decode( $enc, $param->[ $i ] );
   }

   return;
}

sub decode_hash ($$) {
   my ($enc, $param) = @_; my @keys = keys %{ $param };

   for my $k (@keys) {
      my $v = delete $param->{ $k };

      $param->{ decode( $enc, $k ) }
         = is_arrayref( $v ) ? [ map { decode( $enc, $_ ) } @{ $v } ]
                             :         decode( $enc, $v );
   }

   return;
}

sub extract_lang ($) {
   my $v = shift; return $v ? (split m{ _ }mx, $v)[ 0 ] : LANG;
}

sub first_char ($) {
   return substr $_[ 0 ], 0, 1;
}

sub is_arrayref (;$) {
   return $_[ 0 ] && ref $_[ 0 ] eq 'ARRAY' ? 1 : 0;
}

sub is_hashref (;$) {
   return $_[ 0 ] && ref $_[ 0 ] eq 'HASH' ? 1 : 0;
}

sub is_member (;@) {
   my ($candidate, @args) = @_; $candidate or return;

   is_arrayref $args[ 0 ] and @args = @{ $args[ 0 ] };

   return (first { $_ eq $candidate } @args) ? 1 : 0;
}

sub list_config_roles () {
   return @config_roles;
}

sub merge_attributes ($@) {
   my ($dest, @args) = @_;

   my $attr = is_arrayref( $args[ -1 ] ) ? pop @args : [];

   for my $k (grep { not exists $dest->{ $_ } or not defined $dest->{ $_ } }
                  @{ $attr }) {
      my $i = 0; my $v;

      while (not defined $v and defined( my $src = $args[ $i++ ] )) {
         my $class = blessed $src;

         $v = $class ? ($src->can( $k ) ? $src->$k() : undef) : $src->{ $k };
      }

      defined $v and $dest->{ $k } = $v;
   }

   return $dest;
}

sub new_uri ($$) {
   my $v = uri_escape( $_[ 1 ] ); return bless \$v, 'URI::'.$_[ 0 ];
}

sub thread_id () {
   return exists $INC{ 'threads.pm' } ? threads->tid() : 0;
}

sub throw (;@) {
   EXCEPTION_CLASS->throw( @_ );
}

sub trim (;$$) {
   my $chs = $_[ 1 ] // " \t"; (my $v = $_[ 0 ] // q()) =~ s{ \A [$chs]+ }{}mx;

   chomp $v; $v =~ s{ [$chs]+ \z }{}mx; return $v;
}

sub uri_escape ($;$) {
   my ($v, $pattern) = @_; $pattern //= $uric;

   $v =~ s{([^$pattern])}{ URI::Escape::uri_escape_utf8($1) }ego;
   utf8::downgrade( $v );
   return $v;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::ComposableRequest::Util - Functions used in this distribution

=head1 Synopsis

   use Web::ComposableRequest::Util qw( first_char );

=head1 Description

Functions used in this distribution

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

=head2 C<add_config_role>

   add_config_role $config_role_name;

The supplied configuration role name is pushed onto a class attribute list. See
L</list_config_roles>

=head2 C<base64_decode_ns>

   $decoded_value = base64_decode_ns $encoded_value;

Decode a scalar value encode using L</base64_encode_ns>

=head2 C<base64_encode_ns>

   $encoded_value = base64_encode_ns $encoded_value;

Base 64 encode a scalar value using an output character set that preserves
the input values sort order (natural sort)

=head2 C<bson64id>

   $base64_encoded_extended_bson64_id = bson64id;

Generate a new C<BSON> id. Returns a 20 character string that is reasonably
unique across hosts and are in ascending order. Use this to create unique ids
for data streams like message queues and file feeds

=head2 C<bson64id_time>

   $seconds_elapsed_since_the_epoch = bson64id_time $bson64_id;

Returns the time the L</bson64id> id was generated as Unix time

=head2 C<compose_class>

   $class_name = compose_class $base, $attributes, %options;

Compose a class from the base and attributes

=head2 C<decode_array>

   decode_array $encoding, $array_ref;

Applies L<Encode/decode> to each element in the supplied list

=head2 C<decode_hash>

   decode_hash $encoding, $hash_ref;

Applies L<Encode/decode> to both the keys and values of the supplied hash

=head2 C<extract_lang>

   $language_code = extract_lang $locale;

Returns the first part of the supplied locale which is the language code, e.g.
C<en_GB> returns C<en>

=head2 C<first_char>

   $single_char = first_char $some_string;

Returns the first character of C<$string>

=head2 C<is_arrayref>

   $bool = is_arrayref $scalar_variable

Tests to see if the scalar variable is an array ref

=head2 C<is_hashref>

   $bool = is_hashref $scalar_variable

Tests to see if the scalar variable is a hash ref

=head2 C<is_member>

   $bool = is_member 'test_value', qw( a_value test_value b_value );

Tests to see if the first parameter is present in the list of
remaining parameters

=head2 C<list_config_roles>

   @list_of_role_names = list_config_roles;

Returns the list of configuration role names stored in the class attribute.
See L</add_config_role>

=head2 merge_attributes

   $dest = merge_attributes $dest, $src, $defaults, $attr_list_ref;

Merges attribute hashes. The C<$dest> hash is updated and returned. The
C<$dest> hash values take precedence over the C<$src> hash values which
take precedence over the C<$defaults> hash values. The C<$src> hash
may be an object in which case its accessor methods are called

=head2 C<new_uri>

   $uri_object_ref = new_uri $scheme, $uri_path;

Return a new L</URI> object reference

=head2 C<thread_id>

   $tid = thread_id;

Returns the id of this thread. Returns zero if threads are not loaded

=head2 C<throw>

   throw error => 'error_key', args => [ 'error_arg' ];

Expose L<Web::ComposableRequest::Exception/throw>.
L<Web::ComposableRequest::Constants> has a class attribute
I<Exception_Class> which can be set change the class of the thrown exception

=head2 C<trim>

   $trimmed_string = trim $string_with_leading_and_trailing_whitespace;

Remove leading and trailing whitespace including trailing newlines. Takes
an additional string used as the character class to remove. Defaults to
space and tab

=head2 C<uri_escape>

   $value_ref = uri_escape $value, $pattern;

Uses L<URI::Escape/escape_char> to escape any characters in C<$value> that
match the optional pattern. Returns a reference to the escaped value

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Digest::MD5>

=item L<Encode>

=item L<URI::Escape>

=item L<URI::http>

=item L<URI::https>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-ComposableRequest.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
