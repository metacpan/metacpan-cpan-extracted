# ========================================================================== #
# Text/FixedWidth/Parser.pm  - This module used to read the FixedWidth files
# ========================================================================== #

package Text::FixedWidth::Parser;

use Moose;
use Math::Expression;
use DateTime::Format::Strptime;

our $VERSION = '0.3';

# ========================================================================== #

=pod

=encoding UTF-8

=head1 NAME

	Text::FixedWidth::Parser - Used to parse the fixed width text file 

=head1 DESCRIPTION

	The Text::FixedWidth::Parser module allows you to read fixed width text file by specifying string mapper


=head1 SYNOPSIS

  use Text::FixedWidth::Parser;

  FileData
  ~~~~~~~~
  ADDRESS001XXXXX YYYYYYY84 SOUTH STREET USA
  MARK0018286989020140101         
  ADDRESS002YYYYYYY      69 BELL STREET  UK 
  MARK0028869893920140101         

  my $string_mapper = [
        {
            Rule => {
                LinePrefix => [1, 7],
                Expression => "LinePrefix eq 'ADDRESS'"
            },
            Id   => [8,  3],
            Name => [11, 13],
            Address => {DoorNo => [24, 2], Street => [26, 14]},
            Country => [40, 3]
        },
        {
            Rule => {
                LinePrefix => [1, 4],
                Expression => "LinePrefix eq 'MARK'"
            },
            Id                 => [5,  3],
            Mark1              => [8,  2],
            Mark2              => [10, 2],
            Mark3              => [12, 2],
            Mark4              => [14, 3],
            ResultDate         => [15, 8],
            ResultDatePattern  => '%Y%m%d',
            ResultDateTimezone => 'America/Chicago'
        }
  ];
 

  # StringMapper should be passed while creating object
  my $obj = Text::FixedWidth::Parser->new( 
                { 
                   #Required Params
                   StringMapper  => $string_mapper,
                   #optional Params
                   TimestampToEpochFields => ['ResultDate'],
                   DefaultDatePattern     => '%Y%m%d',
                   DefaultTimezone        => 'GMT',
                   ConcateString          => '', 
                   EmptyAsUndef           => 1
                }
            );

  open my $fh, '<', 'filename';

  $data = $obj->read($fh);

=head1 PARAMS 

=over 4


=item B<StringMapper>

* StringMapper can be HASHRef or multiple StringMappers as ARRAY of HASHRefs

* If Multiple StringMappers exist, Based on Rule apropriate StringMapper will get selected

* In Multiple StringMappers, Its better to place Rule-less mapper after Rule based mappers

* Rule-less mapper will picked as soon as its get access in an array

* StringMapper fields should be defined as ARRAY, First element as StartingPoint of string and Second element as length of the string

* Rule, Expression are keywords, overriding or changing those will affect the functionality

=item B<TimestampToEpochFields>

* TimestampToEpochFields can have ARRAY of timestamp fields which need to be converted as epoch 

* TimestampToEpochFields can have Pattern of the timestamp in StringMapper as field name suffixed with Pattern keyword, Which will override L</"DefaultDatePattern"> for that particular field

  Eg:- FieldName : DOB, DOBPattern => '%Y%m%d'

* see L<STRPTIME PATTERN TOKENS|DateTime::Format::Strptime/"STRPTIME PATTERN TOKENS"> section in DateTime::Format::Strptime for more patterns

* TimestampToEpochFields can have timezone of the timestamp in StringMapper as field name suffixed with Timezone keyword, Which will override L</"DefaultTimezone"> for that particular field

  Eg:- FieldName : DOB, DOBTimezone=> 'GMT'

=item B<DefaultDatePattern>

* DefaultDatePattern can have DatePattern which will be used to convert date to epoch by default

=item B<DefaultTimezone> 

* DefaultTimezone can have timezone which will be used while converting date to epoch


=item B<ConcateString>

* StringMapper can be defined as {Address => [24, 2, 26, 14]} 

* This represents, Address field value will be concatenation of two strings, which are Startingpoint 24, Length 2 and Startingpoint 26, Length 14

* While concatenating strings, value of I<ConcateString> will be used 

  Eg: ConcateString = '-';  The Value of Address = 84-SOUTH STREET    

* Space(' ') is default ConcateString

=item B<EmptyAsUndef>
    
* If this flag is enabled, Empty values will be assigned as undef

   Eg: Name = '', it will be assigned as Name = undef
=cut

=back

=head1 METHODS

=over 4

=cut

# ========================================================================== #
has me_obj => (
    is      => 'ro',
    isa     => 'Math::Expression',
    default => sub { Math::Expression->new }
);

# ========================================================================== #

=item B<get_string_mapper>

Desc   : This method will return the StringMapper

Params : NONE

Returns: HASHRef as Mentioned in the config

=cut 

=item B<set_string_mapper>

Desc   : This method is used set the StringMapper

Params : StringMapper

Returns: NONE

=cut

has 'StringMapper' => (
    is            => 'rw',
    required      => 1,
    reader        => 'get_string_mapper',
    writer        => 'set_string_mapper',
    documentation => 'This attribute is used to read the file values'
);

# ========================================================================== #

=item B<get_concate_string>

Desc   : This method will return the ConcateString

Params : NONE

Returns: ConcateString

=cut

=item B<set_concate_string>

Desc   : This method is used to set ConcateString

Params : String

Returns: NONE

=cut

has 'ConcateString' => (
    is            => 'rw',
    isa           => 'Str',
    default       => ' ',
    reader        => 'get_concate_string',
    writer        => 'set_concate_string',
    documentation => 'This attribute is used to concatenate string with given string. Default value is space'
);

# ========================================================================== #

=item B<is_empty_undef>

Desc   : This method will indicate is empty flag enabled or disabled

Params : NONE

Returns: 1 on enabled, 0 on disabled

=cut

=item B<set_empty_undef>

Desc   : This method is used to enable or disable EmptyAsUndef flag

Params : 1 to enable, 0 to disable

Returns: NONE

=cut

has 'EmptyAsUndef' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    reader        => 'is_empty_undef',
    writer        => 'set_empty_undef',
    documentation => 'This attribute is used to say set undef where the value is undef'
);

# ========================================================================== #

=item B<set_timestamp_to_epoch_fields>

Desc   : This method is used to set fields that need to be converted to epoch

Params : [FieldName14,..] 

Returns: NONE

=cut

has 'TimestampToEpochFields' => (
    is      => 'rw',
    default => 0,
    writer  => 'set_timestamp_to_epoch_fields',
    trigger => sub {
        my ($self, $new_val, $old_val) = @_;
        print("Invalid TimestampToEpochFields value, Value should be ARRAYREF\n") and return undef
          if (ref($new_val) ne 'ARRAY');
        my $val;
        $val->{$_} = 1 for (@$new_val);
        $self->{time_to_epoch_fields} = $val;
    },
    documentation => 'This attribute is used to configure fileds that need to be convert as epoch'
);

# ========================================================================== #

=item B<add_timestamp_to_epoch_fields>

Desc   : This method is used to add fields with existing fields that need to be converted to epoch

Params : [FieldName14,..] 

Returns: NONE

=cut

sub add_timestamp_to_epoch_fields
{
    my ($self, $value) = @_;

    print("Invalid TimestampToEpochFields value, Value should be ARRAYREF\n") and return undef
      if (ref($value) ne 'ARRAY');

    $self->{time_to_epoch_fields}{$_} = 1 for (@$value);
    push(@{$self->{TimestampToEpochFields}}, @$value);
}

# ========================================================================== #

=item B<get_timestamp_to_epoch_fields>

Desc   : This method is used to get fields that will be converted to epoch

Params : [FieldName14,..] 

Returns: NONE

=cut

sub get_timestamp_to_epoch_fields
{
    my $self = shift;

    my @fields;

    if (defined $self->{time_to_epoch_fields}) {
        @fields = keys @{$self->{time_to_epoch_fields}};
    }

    return \@fields;
}

# ========================================================================== #

=item B<set_default_date_pattern>

Desc   : This method is used to set date format which will be used to convert the date to epoch. '%Y%m%d' is default DatePattern.

Params : DatePattern eg:- '%Y%m%d'

Returns: NONE

=cut

=item B<get_default_date_pattern>

Desc   : This method will return the date format which will be used to convert the date to epoch. 

Params : NONE

Returns: DatePattern eg:- '%Y%m%d' 

=cut

has 'DefaultDatePattern' => (
    is      => 'rw',
    isa     => 'Str',
    writer  => 'set_default_date_pattern',
    reader  => 'get_default_date_pattern',
    default => '%Y%m%d',
    lazy    => 1,
    documentation =>
      'This attribute is used to configure the default date format which will be used to convert date to epoch'
);

# ========================================================================== #

=item B<set_default_timezone>

Desc   : This method is used to set timezone which will be used while converting date to epoch. GMT is a default timezone.

Params : Timezone eg:- 'GMT'

Returns: NONE

=cut

=item B<get_default_timezone>

Desc   : This method will return timezone which will be used while converting timestamp to epoch

Params : NONE

Returns: Timezone eg:- 'GMT' 

=cut

has 'DefaultTimezone' => (
    is            => 'rw',
    isa           => 'Str',
    writer        => 'set_default_timezone',
    reader        => 'get_default_timezone',
    default       => 'GMT',
    documentation => 'This attribute is used to configure the default timezone'
);

# ========================================================================== #

=item B<read>

Desc   : This method is used to read the line by line values

Params : FileHandle

Returns: HASHRef as Mentioned in the StringMapper

         Eg : {
                  'Address' => {
                    'DoorNo' => '84',
                    'Street' => 'SOUTH STREET'
                  },
                  'Country' => 'USA',
                  'Id' => '001',
                  'Name' => 'XXXXX YYYYYYY'
               }
=cut

sub read
{
    my ($self, $fh) = @_;

    return undef if eof $fh;

    my $data = {};

    my $line = <$fh>;

    $data = $self->_read_data($line, $self->_get_config($line)) if ($line !~ /^\s+$/);

    return $data;
}

# This is private method used to read the file and Construct data structure as per StringMapper
sub _read_data
{

    my ($self, $line, $string_mapper) = @_;

    return undef if ((not defined $line) or (not defined $string_mapper));

    my $concate_string = $self->get_concate_string;

    #Match empty value with or without space
    my $is_empty = qr/^\s*$/;

    my $data;

    foreach my $field (keys %{$string_mapper}) {

        my $field_map = $string_mapper->{$field};

        if (ref($field_map) eq 'HASH' && $field ne 'Rule') {
            $data->{$field} = $self->_read_data($line, $field_map);
            next;
        }

        next if (ref($field_map) ne 'ARRAY');

        my $map_count = @{$field_map} / 2;
        my $column_val;

        foreach my $count (1 .. $map_count) {

            #start_index decremented by one to match substr postion
            #substr() start_index always one char before the string
            my $start_index = $field_map->[$count - 1] - 1;
            my $length      = $field_map->[$count];

            my $extracted_value = substr($line, $start_index, $length);

            # To Remove the space before and after string
            $extracted_value =~ s/^\s+|\s+$//g;

            if ($self->{time_to_epoch_fields} && $self->{time_to_epoch_fields}{$field}) {

                my $format =
                  (defined $string_mapper->{"${field}Pattern"})
                  ? $string_mapper->{"${field}Pattern"}
                  : $self->get_default_date_format;
                my $tz = $string_mapper->{"${field}Timezone"};
                $extracted_value = $self->_get_time_stamp_to_epoch($extracted_value, $format, $tz);
            }

            # Adding ConcateString between the strings while concatenate
            defined $column_val ? $column_val .= "$concate_string$extracted_value" : $column_val = $extracted_value;
        }

        $column_val = undef if (((not defined $column_val) || $column_val =~ $is_empty) && $self->is_empty_undef);

        $data->{$field} = $column_val;
    }

    return $data;
}

# ========================================================================== #

=item B<read_all>

Desc   : This method is used to read complete file

Params : FileHandle

Returns: HASHRef as Mentioned in the StringMapper

         Eg : [
                 {
                   'Address' => {
                     'DoorNo' => '84',
                     'Street' => 'SOUTH STREET'
                   },
                   'Country' => 'USA',
                   'Id' => '001',
                   'Name' => 'XXXXX YYYYYYY'
                 },
                 {
                   'Id' => '001',
                   'Mark1' => '82',
                   'Mark2' => '86',
                   'Mark3' => '98',
                   'Mark4' => '90'
                 },
                 {
                   'Address' => {
                     'DoorNo' => '69',
                     'Street' => 'BELL STREET'
                   },
                   'Country' => 'UK',
                   'Id' => '002',
                   'Name' => 'YYYYYYY'
                 },
                 {
                   'Id' => '002',
                   'Mark1' => '88',
                   'Mark2' => '69',
                   'Mark3' => '89',
                   'Mark4' => '39'
                 }
               ]


=cut

sub read_all
{

    my ($self, $fh) = @_;

    my $data;

    while (my $line = <$fh>) {
        next if ($line =~ /^\s+$/);

        my $extracted_value = $self->_read_data($line, $self->_get_config($line));

        push(@$data, $extracted_value) if ($extracted_value);
    }

    return $data;
}

# ========================================================================== #

# This method will return the config based on rule. If rule does not exist, it will return the base config.

sub _get_config
{
    my ($self, $line) = @_;

    my $config_set = $self->get_string_mapper;

    $config_set = [$config_set] if (ref($config_set) ne 'ARRAY');

    my $me_obj = $self->{me_obj};

    foreach my $config (@{$config_set}) {

        my $rule = $config->{Rule};

        if ($rule) {

            foreach my $rule_key (keys %{$rule}) {

                next if (ref($rule->{$rule_key}) ne 'ARRAY');

                my $start_index = $rule->{$rule_key}[0] - 1;
                my $length      = $rule->{$rule_key}[1];

                my $extracted_value = substr($line, $start_index, $length);

                $extracted_value =~ s/^\s+|\s+$//g;

                $me_obj->VarSetScalar($rule_key, $extracted_value);
            }

            my $expression = $rule->{Expression};

            return $config if ($me_obj->ParseToScalar($expression));

        }
        else {
            return $config;
        }
    }

    return undef;
}

# ========================================================================== #

# This method is used to convert the date to epoch using date format

sub _get_time_stamp_to_epoch
{
    my ($self, $date, $format, $tz) = @_;

    my $time_zone = $tz || $self->get_default_timezone;
    my $pattern = $format;

    my $strp = DateTime::Format::Strptime->new(
        pattern   => $pattern,
        time_zone => $time_zone
    );

    my $dt = $strp->parse_datetime($date);

    my $epoch;

    if (defined $dt) {

        $epoch = $dt->epoch;

        if ($epoch !~ /^\d{1,10}$/o) {
            return undef;
        }
    }
    return $epoch;
}

1;

__END__

=back
   
=head1 LICENSE

This library is free software; you can redistribute and/or modify it under the same terms as Perl itself.

=head1 AUTHORS

Venkatesan Narayanan, <venkatesanmusiri@gmail.com>

=cut

# vim: ts=4
# vim600: fdm=marker fdl=0 fdc=3

