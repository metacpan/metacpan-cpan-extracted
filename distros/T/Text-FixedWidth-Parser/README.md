# NAME

        Text::FixedWidth::Parser - Used to parse the fixed width text file 

# DESCRIPTION

        The Text::FixedWidth::Parser module allows you to read fixed width text file by specifying string mapper

# SYNOPSIS

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

# PARAMS 

- **StringMapper**

    \* StringMapper can be HASHRef or multiple StringMappers as ARRAY of HASHRefs

    \* If Multiple StringMappers exist, Based on Rule apropriate StringMapper will get selected

    \* In Multiple StringMappers, Its better to place Rule-less mapper after Rule based mappers

    \* Rule-less mapper will picked as soon as its get access in an array

    \* StringMapper fields should be defined as ARRAY, First element as StartingPoint of string and Second element as length of the string

    \* Rule, Expression are keywords, overriding or changing those will affect the functionality

- **TimestampToEpochFields**

    \* TimestampToEpochFields can have ARRAY of timestamp fields which need to be converted as epoch 

    \* TimestampToEpochFields can have Pattern of the timestamp in StringMapper as field name suffixed with Pattern keyword, Which will override ["DefaultDatePattern"](#defaultdatepattern) for that particular field

        Eg:- FieldName : DOB, DOBPattern => '%Y%m%d'

    \* see [STRPTIME PATTERN TOKENS](https://metacpan.org/pod/DateTime::Format::Strptime#STRPTIME-PATTERN-TOKENS) section in DateTime::Format::Strptime for more patterns

    \* TimestampToEpochFields can have timezone of the timestamp in StringMapper as field name suffixed with Timezone keyword, Which will override ["DefaultTimezone"](#defaulttimezone) for that particular field

        Eg:- FieldName : DOB, DOBTimezone=> 'GMT'

- **DefaultDatePattern**

    \* DefaultDatePattern can have DatePattern which will be used to convert date to epoch by default

- **DefaultTimezone** 

    \* DefaultTimezone can have timezone which will be used while converting date to epoch

- **ConcateString**

    \* StringMapper can be defined as {Address => \[24, 2, 26, 14\]} 

    \* This represents, Address field value will be concatenation of two strings, which are Startingpoint 24, Length 2 and Startingpoint 26, Length 14

    \* While concatenating strings, value of _ConcateString_ will be used 

        Eg: ConcateString = '-';  The Value of Address = 84-SOUTH STREET    

    \* Space(' ') is default ConcateString

- **EmptyAsUndef**

    \* If this flag is enabled, Empty values will be assigned as undef

        Eg: Name = '', it will be assigned as Name = undef

# METHODS

- **get\_string\_mapper**

    Desc   : This method will return the StringMapper

    Params : NONE

    Returns: HASHRef as Mentioned in the config

- **set\_string\_mapper**

    Desc   : This method is used set the StringMapper

    Params : StringMapper

    Returns: NONE

- **get\_concate\_string**

    Desc   : This method will return the ConcateString

    Params : NONE

    Returns: ConcateString

- **set\_concate\_string**

    Desc   : This method is used to set ConcateString

    Params : String

    Returns: NONE

- **is\_empty\_undef**

    Desc   : This method will indicate is empty flag enabled or disabled

    Params : NONE

    Returns: 1 on enabled, 0 on disabled

- **set\_empty\_undef**

    Desc   : This method is used to enable or disable EmptyAsUndef flag

    Params : 1 to enable, 0 to disable

    Returns: NONE

- **set\_timestamp\_to\_epoch\_fields**

    Desc   : This method is used to set fields that need to be converted to epoch

    Params : \[FieldName14,..\] 

    Returns: NONE

- **add\_timestamp\_to\_epoch\_fields**

    Desc   : This method is used to add fields with existing fields that need to be converted to epoch

    Params : \[FieldName14,..\] 

    Returns: NONE

- **get\_timestamp\_to\_epoch\_fields**

    Desc   : This method is used to get fields that will be converted to epoch

    Params : \[FieldName14,..\] 

    Returns: NONE

- **set\_default\_date\_pattern**

    Desc   : This method is used to set date format which will be used to convert the date to epoch. '%Y%m%d' is default DatePattern.

    Params : DatePattern eg:- '%Y%m%d'

    Returns: NONE

- **get\_default\_date\_pattern**

    Desc   : This method will return the date format which will be used to convert the date to epoch. 

    Params : NONE

    Returns: DatePattern eg:- '%Y%m%d' 

- **set\_default\_timezone**

    Desc   : This method is used to set timezone which will be used while converting date to epoch. GMT is a default timezone.

    Params : Timezone eg:- 'GMT'

    Returns: NONE

- **get\_default\_timezone**

    Desc   : This method will return timezone which will be used while converting timestamp to epoch

    Params : NONE

    Returns: Timezone eg:- 'GMT' 

- **read**

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

- **read\_all**

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

# LICENSE

This library is free software; you can redistribute and/or modify it under the same terms as Perl itself.

# AUTHORS

Venkatesan Narayanan, <venkatesanmusiri@gmail.com>
