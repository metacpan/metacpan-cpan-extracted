package Valiant::Validator::Format;

use Moo;
use Valiant::I18N;

with 'Valiant::Validator::Each';     


has match => (is=>'ro', predicate=>'has_match');
has without => (is=>'ro', predicate=>'has_without');

has invalid_format_match => (is=>'ro', required=>1, default=>sub {_t 'invalid_format_match'});
has invalid_format_without => (is=>'ro', required=>1, default=>sub {_t 'invalid_format_without'});

has exclusion => (is=>'ro', required=>1, default=>sub {_t 'exclusion'});

sub BUILD {
  my ($self, $args) = @_;
  $self->_requires_one_of($args, 'match', 'without');
}

# Stolen from Email::Valid
our $RFC822PAT = <<'EOF';
[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\
xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xf
f\n\015()]*)*\)[\040\t]*)*(?:(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\x
ff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|"[^\\\x80-\xff\n\015
"]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015"]*)*")[\040\t]*(?:\([^\\\x80-\
xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80
-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*
)*(?:\.[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\
\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\
x80-\xff\n\015()]*)*\)[\040\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x8
0-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|"[^\\\x80-\xff\n
\015"]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015"]*)*")[\040\t]*(?:\([^\\\x
80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^
\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040
\t]*)*)*@[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([
^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\
\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\
x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-
\xff\n\015\[\]]|\\[^\x80-\xff])*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()
]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\
x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:\.[\04
0\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\
n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\
015()]*)*\)[\040\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?!
[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\
]]|\\[^\x80-\xff])*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\
x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\01
5()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*)*|(?:[^(\040)<>@,;:".
\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]
)|"[^\\\x80-\xff\n\015"]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015"]*)*")[^
()<>@,;:".\\\[\]\x80-\xff\000-\010\012-\037]*(?:(?:\([^\\\x80-\xff\n\0
15()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][
^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)|"[^\\\x80-\xff\
n\015"]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015"]*)*")[^()<>@,;:".\\\[\]\
x80-\xff\000-\010\012-\037]*)*<[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?
:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-
\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:@[\040\t]*
(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015
()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()
]*)*\)[\040\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\0
40)<>@,;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\
[^\x80-\xff])*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\
xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*
)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:\.[\040\t]*(?:\([^\\\x80
-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x
80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t
]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\
\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff])
*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x
80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80
-\xff\n\015()]*)*\)[\040\t]*)*)*(?:,[\040\t]*(?:\([^\\\x80-\xff\n\015(
)]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\
\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*@[\040\t
]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\0
15()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015
()]*)*\)[\040\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(
\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|
\\[^\x80-\xff])*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80
-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()
]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:\.[\040\t]*(?:\([^\\\x
80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^
\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040
\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".
\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff
])*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\
\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x
80-\xff\n\015()]*)*\)[\040\t]*)*)*)*:[\040\t]*(?:\([^\\\x80-\xff\n\015
()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\
\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*)?(?:[^
(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-
\037\x80-\xff])|"[^\\\x80-\xff\n\015"]*(?:\\[^\x80-\xff][^\\\x80-\xff\
n\015"]*)*")[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|
\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))
[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:\.[\040\t]*(?:\([^\\\x80-\xff
\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\x
ff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(
?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\
000-\037\x80-\xff])|"[^\\\x80-\xff\n\015"]*(?:\\[^\x80-\xff][^\\\x80-\
xff\n\015"]*)*")[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\x
ff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)
*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*)*@[\040\t]*(?:\([^\\\x80-\x
ff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-
\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)
*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\
]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff])*\]
)[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-
\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\x
ff\n\015()]*)*\)[\040\t]*)*(?:\.[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(
?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80
-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:[^(\040)<
>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x8
0-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff])*\])[\040\t]*(?:
\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]
*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)
*\)[\040\t]*)*)*>)
EOF

$RFC822PAT =~ s/\n//g;

#  credit_card
#  domain_FQDN
#  IsISO8601
#  uppercase
#  lowercase
#  is_url
#  IP address
#  us zip6 / us zip10
#  us social security
#

our %prebuilt_formats = (
  alpha           => [ qr/^[a-z]+$/i,                 _t('not_alpha') ],
  words           => [ qr/^[a-z ]+$/i,                 _t('not_words') ], # letters and spaces only
  alpha_numeric   => [ qr/^\w+$/,                     _t('not_alpha_numeric') ],
  alphanumeric    => [ qr/^\w+$/,                     _t('not_alpha_numeric') ], # likely common error
  email           => [ qr/^$RFC822PAT$/o,             _t('not_email') ],
  zip             => [ qr/^\d{5}(?:[- ]\d{4})?$/,     _t('not_zip') ],
  zip5            => [ qr/^\d\d\d\d\d$/,              _t('not_zip5') ],
  zip9            => [ qr/^\d\d\d\d\d[- ]\d\d\d\d$/,  _t('not_zip9') ],
  ascii           => [qr/^\p{IsASCII}*\z/,            _t('not_ascii') ],
  word            => [qr/^\w*\z/,                     _t('not_word') ],
);

sub prebuilt_formats { return \%prebuilt_formats }

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);

  foreach my $key (qw/match without/) {
    next unless exists $args->{$key};
    next if (ref($args->{$key})||'') eq 'Regexp';
    next unless $class->prebuilt_formats->{$args->{$key}};
    my $prebuilt = $args->{$key};
    $args->{$key}     = $class->prebuilt_formats->{$prebuilt}->[0];
    $args->{message}  = $class->prebuilt_formats->{$prebuilt}->[1] unless exists $args->{message};  
    return $args;
  }

  return $args;
};

sub normalize_shortcut {
  my ($class, $arg) = @_;
  return +{ match => $arg };
}

sub validate_each {
  my ($self, $record, $attribute, $value, $opts) = @_;

  if($self->has_match) {
    my $with = $self->_cb_value($record, $self->match);
    $record->errors->add($attribute, $self->invalid_format_match, $opts)
      unless defined($value) && $value =~m/$with/;
  }
  if($self->has_without) {
    my $with = $self->_cb_value($record, $self->without);
    if($value =~m/$with/) {
      $record->errors->add($attribute, $self->invalid_format_without, $opts);
    }
  }
}

1;

=head1 NAME

Valiant::Validator::Format - Validate a value based on a regular expression

=head1 SYNOPSIS

    package Local::Test::Format;

    use Moo;
    use Valiant::Validations;

    has phone => (is=>'ro');
    has name => (is=>'ro');
    has email => (is=>'ro');

    validates phone => (
      format => +{
        match => qr/\d\d\d-\d\d\d-\d\d\d\d/,
      },
    );

    validates name => (
      format => +{
        without => qr/\d+/,
      },
    );

    validates email =>
      format => 'email';

    my $object = Local::Test::Format->new(
      phone => '387-1212',
      name => 'jjn1056',
    );

    $object->validate;

    warn $object->errors->_dump;

    $VAR1 = {
      'phone' => [
                 'Phone does not match the required pattern'
               ],
      'name' => [
                'Name contains invalid characters'
              ],
      'email' => [
                'Email is not an email address'
              ],

    };

=head1 DESCRIPTION

Validates that the attribute value either matches a given regular expression (C<match)
or that it fails to match an exclusion expression (C<without>).

Values that fail the C<match> condition (which can be a regular expression or a
reference to a method that provides one) will add an error matching the tag 
C<invalid_format_match>, which can be overridden as with other tags.

Values that match the C<without> conditions (also either a regular expression or
a coderef that provides one) with all an error matching the tag C<invalid_format_without>
which can also be overridden via a passed parameter.

A number of format shortcuts are built in to help you bootstrap faster.  Use the text
string in place of the regexp (for example:)

    validates email => (
      format => +{ 
        match => 'email',
      }
    );

You can add to the prebuilts by adding keys to the global C<%prebuilt_formats>
hash.  See code for more.

=over 4

=item email

Uses a regexp to validate that a string looks like an email.  This is naive but
probably acceptable for most uses.  For real detailed eail checking you'll need
to build something on L<Email::Valid>.  Uses translation tag C<not_email>.

=item alpha

Text can only be upper or lowercase letter.  Uses translation tag C<not_alpha>.

=item alpha_numeric

Text can only be upper or lowercase letters, numbers or '_'.  Uses translation
tag C<not_alpha_numeric>.

=item words

Only letters and spaces.  Error message default is translation tag C<not_words>.

=item word

Must contain only a single word.  Adds error C<not_word> if fails.

=item zip

=item zip5

=item zip9

Match US zipcodes.  This is a pattern match only, we don't actually check if the zip
is a true valid zipcode, just that it looks like one.  C<zip5> matches a common 5
digit zipcode and return C<not_zip5> translation tag if not.  C<zip9> looks for the
'Zip +4' extended zipcode, such as 11111-2222 (the separator can be either '-' or a
space).  Adds errors C<not_zip9> if not.  Finally C<zip> will match either zip or zip +4
and add error C<not_zip> on failure to match.

=item ascii

Must contain only ASCII characters.  Adds error C<not_ascii> if fails.

=cut

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( format => qr/\d\d\d/, ... );

Which is the same as:

    validates attribute => (
      format => +{
        match => qr/\d\d\d/,
      },
    );

We choose to shortcut the 'match' pattern based on experiene that suggested
it is more common to required a specific pattern than to have an exclusion
pattern.  

This also works for the coderef form.

    validates attribute => ( format => \&pattern, ... );

Which is the same as:

    validates attribute => (
      format => +{
        match => \&pattern,
      },
    );

And of course its very handy for using one of the built in pattern tags:

    validates email => (format => 'email');

Which is the same as:

    validates email => (
      format => +{ 
        match => 'email',
      }
    );

=head1 GLOBAL PARAMETERS

This validator supports all the standard shared parameters: C<if>, C<unless>,
C<message>, C<strict>, C<allow_undef>, C<allow_blank>.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Validator>, L<Valiant::Validator::Each>.

=head1 AUTHOR
 
See L<Valiant>  
    
=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
