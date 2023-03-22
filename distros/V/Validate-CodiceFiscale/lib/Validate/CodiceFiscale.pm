package Validate::CodiceFiscale;
use v5.24;
use Carp;
use experimental qw< signatures >;
{ our $VERSION = '0.001' }

use List::Util 'sum';
use Time::Local 'timegm';
use Exporter 'import';

our @EXPORT_OK = qw< assert_valid_cf is_valid_cf validate_cf r >;

# PUBLIC interface

sub assert_valid_cf ($cf, %options) {
   my $errors = validate_cf($cf, all_errors => 0, %options) or return;

   defined(my $ecb = $options{on_error})
     or croak join ', ', $errors->@*;

   my $exception = $ecb->($errors->@*);
   die $exception;    # just as a fallback, $ecb might throw by itself

} ## end sub assert_valid_cf

sub is_valid_cf ($cf, %options) {
   my $error = 0;
   _validate_cf($cf, $options{data}, sub { $error = 1; return 0 });
   return !$error;
}

sub validate_cf ($cf, %options) {
   my $data = $options{data} // undef;

   my $collect_all_errors = $options{all_errors} // 1;
   my @errors;
   my $callback = sub ($msg) {
      push @errors, $msg;
      return $collect_all_errors;
   };

   _validate_cf($cf, $data, $callback);

   return scalar(@errors) ? \@errors : undef;
} ## end sub validate_cf

# The following is useful for one-lines:
#
#     $ perl -MValidate::CodiceFiscale=r -er bcadfe88a48h501p
#
sub r (@args) {
   @args = @ARGV unless @args;
   my $i = 0;
   my $n = 0;
   for my $cf (@ARGV) {
      if (my $errors = validate_cf($cf)) {
         say "$i not ok - " . join(', ', $errors->@*);
         ++$n;
      }
      else {
         say "$i ok - $cf";
      }
      ++$i;
   } ## end for my $cf (@ARGV)
   return $n ? 1 : 0;
} ## end sub r

exit r(@ARGV) unless caller();    # modulino

# PRIVATE interface

sub _validate_cf ($cf, $data, $cb) {
   state $consonant = qr{(?imxs:[BCDFGHJKLMNPQRSTVWXYZ])};
   state $vowel     = qr{(?imxs:[AEIOU])};
   state $namish    = qr{(?imxs:
         $consonant  $consonant  $consonant  # includes CCX, CXX, XXX
      |  $consonant  $consonant  $vowel
      |  $consonant  $vowel      $vowel
      |  $consonant  $vowel      X
      |  $vowel      $vowel      $vowel
      |  $vowel      $vowel      X
      |  $vowel      X           X
   )};
   state $digitish = qr{(?imxs:[0-9LMNPQRSTUV])};

   return $cb->('invalid length') if length($cf) != 16;

   $cf = uc($cf);

   return
     if substr($cf, 0, 3) !~ m{\A$namish\z}mxs
     && !$cb->('invalid surname');

   return
     if substr($cf, 3, 3) !~ m{\A$namish\z}mxs
     && !$cb->('invalid name');

   return
     if !_is_valid_cf_date(substr($cf, 6, 5))
     && !$cb->('invalid birth date');

   return
     if substr($cf, 11, 4) !~ m{\A [A-Z] $digitish{3} \z}mxs
     && !$cb->('invalid birth place');

   my $checksum = _cf_checksum($cf);
   return
     if $checksum ne substr($cf, -1, 1)
     && !$cb->("invalid checksum (should be: $checksum)");

   return unless $data;

   if (defined(my $surname = $data->{surname})) {
      return
        if substr($cf, 0, 3) ne _compact_surname($surname)
        && !$cb->('surname mismatch');
   }
   if (defined(my $name = $data->{name})) {
      return
        if substr($cf, 3, 3) ne _compact_name($name)
        && !$cb->('name mismatch');
   }
   if (defined(my $birthdate = $data->{birthdate})) {
      my ($male, $female) = _compact_birthdates($birthdate);
      my $got = _normalized_birthdate(substr($cf, 6, 5));
      return
           if ($got ne $male)
        && ($got ne $female)
        && !$cb->('birth date mismatch');
   } ## end if (defined(my $birthdate...))
   if (defined(my $sex = $data->{sex})) {
      my $got = _normalized_birthdate(substr($cf, 6, 5));
      my $day = substr($got, -2, 2) + 0;
      return
        if ((lc($sex) eq 'm' && $day > 31)
         || (lc($sex) eq 'f' && $day < 41))
        && !$cb->('sex mismatch');
   } ## end if (defined(my $sex = ...))
   if (defined(my $place = $data->{birthplace})) {
      my $got = _normalized_birthplace(substr($cf, 11, 4));
      $place = _normalized_birthplace($place);
      return
        if fc($got) ne fc($place)
        && !$cb->('birth place mismatch');
   } ## end if (defined(my $place ...))

   return;
} ## end sub _validate_cf

sub _cf_checksum ($cf) {
   state $odd_checksums = {
      0 => 1,
      1 => 0,
      2 => 5,
      3 => 7,
      4 => 9,
      5 => 13,
      6 => 15,
      7 => 17,
      8 => 19,
      9 => 21,
      A => 1,
      B => 0,
      C => 5,
      D => 7,
      E => 9,
      F => 13,
      G => 15,
      H => 17,
      I => 19,
      J => 21,
      K => 2,
      L => 4,
      M => 18,
      N => 20,
      O => 11,
      P => 3,
      Q => 6,
      R => 8,
      S => 12,
      T => 14,
      U => 16,
      V => 10,
      W => 22,
      X => 25,
      Y => 24,
      Z => 23,
     },
     my $even_checksums = {
      0 => 0,
      1 => 1,
      2 => 2,
      3 => 3,
      4 => 4,
      5 => 5,
      6 => 6,
      7 => 7,
      8 => 8,
      9 => 9,
      A => 0,
      B => 1,
      C => 2,
      D => 3,
      E => 4,
      F => 5,
      G => 6,
      H => 7,
      I => 8,
      J => 9,
      K => 10,
      L => 11,
      M => 12,
      N => 13,
      O => 14,
      P => 15,
      Q => 16,
      R => 17,
      S => 18,
      T => 19,
      U => 20,
      V => 21,
      W => 22,
      X => 23,
      Y => 24,
      Z => 25,
     };
   state $checksums_for = [$odd_checksums, $even_checksums];
   my @chars = split m{}mxs, substr($cf, 0, 15);    # no checksum
   my $sum = sum map { $checksums_for->[$_ % 2]{$chars[$_]} } 0 .. $#chars;
   chr(ord('A') + ($sum % 26));
} ## end sub _cf_checksum

sub _normalized_string ($string, @positions) {
   state $letters   = [qw< L M N P Q R S T U V >];
   state $digit_for = {map { $letters->[$_] => $_ } 0 .. $letters->$#*};
   for my $i (@positions) {
      my $current = substr($string, $i, 1);
      substr($string, $i, 1, $digit_for->{$current})
        if exists $digit_for->{$current};
   }
   return $string;
} ## end sub _normalized_string

sub _normalized_birthplace ($place) { _normalized_string($place, 1 .. 3) }
sub _normalized_birthdate ($date) { _normalized_string($date, 0, 1, 3, 4) }

sub _is_valid_cf_date ($date) {
   state $mlf       = [split m{}mxs, 'ABCDEHLMPRST'];
   state $month_for = {map { $mlf->[$_] => $_ } 0 .. $mlf->$#*};

   $date = _normalized_birthdate($date);
   my ($y, $mc, $d) = $date =~ m{\A(\d\d)([ABCDEHLMPRST])(\d\d)\z}mxs;
   my $m = $month_for->{$mc};
   $_ += 0 for ($d, $y);
   $d -= 40 if $d > 40;

   return !0
     if (($m != 1) || ($y % 100) || ($d < 29))
     && eval { timegm(30, 30, 12, $d, $m, $y + 1900); 1 };

   # We have $y = 0 but we might have uncertainty as to which exact century
   # we have to consider, and they have different opinions about being leap
   # or not.

   return !1 if $d != 29;    # this check is trivial

   # try out "meaningful" centuries. CF was introduced in 19xx so it makes
   # sense to check from 19 up to the current one. We mean "century" as
   # "whatever year without the last two digits", so 20th century is 19
   my $current_century = 19 + int((gmtime)[5] / 100);
   for my $century (reverse(19 .. $current_century)) {
      return !0 if eval { timegm(30, 30, 12, $d, $m, $century * 100); 1 };
   }

   return !1;
} ## end sub _is_valid_cf_date

sub _compact_birthdates ($birthdate) {
   state $month_letter_for = ['', split m{}mxs, 'ABCDEHLMPRST'];
   my ($y, $m, $d) = split m{\D}mxs, $birthdate;
   ($y, $d) = ($d, $y) if $d > 31;
   $y %= 100;
   $m = $month_letter_for->[$m + 0];
   map { sprintf '%02d%s%02d', $y, $m, $_ } ($d, $d + 40);
} ## end sub _compact_birthdates

sub _compact_surname ($surname) {
   my ($cs, $vs) = _consonants_and_vowels($surname);
   my @retval = ($cs->@*, $vs->@*, ('X') x 3);
   return join '', @retval[0 .. 2];
}

sub _compact_name ($name) {
   my ($cs, $vs) = _consonants_and_vowels($name);
   splice $cs->@*, 1, 1 if $cs->@* > 3;
   my @retval = ($cs->@*, $vs->@*, ('X') x 3);
   return join '', @retval[0 .. 2];
} ## end sub _compact_name

sub _consonants_and_vowels ($string) {
   my (@consonants, @vowels);
   for my $char (grep { m{[A-Z]}mxs } split m{}mxs, uc($string)) {
      if   ($char =~ m{[AEIOU]}mxs) { push @vowels,     $char }
      else                          { push @consonants, $char }
   }
   return (\@consonants, \@vowels);
} ## end sub _consonants_and_vowels

1;

__END__
