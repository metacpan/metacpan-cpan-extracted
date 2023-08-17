# Time-Piece-Guess

Checks the passed string and compares it against a series of regexp to
find a matching format for it.

Below currently known formats, but Time::Piece as of currently does
not properly handle %Z, even though this lib does not recognize it.

```text
    %s
    %s\.\d*
    %Y%m%d %H%M
    %Y%m%d %H%M %Z
    %Y%m%d %H%M%S
    %Y%m%d %H%M%S %Z
    %Y%m%d %H%M%S%z
    %Y%m%d %H%M%SZ
    %Y%m%d %H%M%S\.\d*
    %Y%m%d %H%M%S\.\d* %Z
    %Y%m%d %H%M%S\.\d*%z
    %Y%m%d %H%M%S\.\d*Z
    %Y%m%d %H%M%z
    %Y%m%d %H%MZ
    %Y%m%d %H:%M
    %Y%m%d %H:%M %Z
    %Y%m%d %H:%M%z
    %Y%m%d %H:%M:%S
    %Y%m%d %H:%M:%S%z
    %Y%m%d %H:%M:%SZ
    %Y%m%d %H:%M:%S\.\d*
    %Y%m%d %H:%M:%S\.\d* %Z
    %Y%m%d %H:%M:%S\.\d*%z
    %Y%m%d %H:%M:%S\.\d*Z
    %Y%m%d %H:%MZ
    %Y%m%d/%H%M
    %Y%m%d/%H%M %Z
    %Y%m%d/%H%M%S
    %Y%m%d/%H%M%S %Z
    %Y%m%d/%H%M%S%z
    %Y%m%d/%H%M%SZ
    %Y%m%d/%H%M%S\.\d*
    %Y%m%d/%H%M%S\.\d* %Z
    %Y%m%d/%H%M%S\.\d*%z
    %Y%m%d/%H%M%S\.\d*Z
    %Y%m%d/%H%M%z
    %Y%m%d/%H%MZ
    %Y%m%d/%H:%M
    %Y%m%d/%H:%M %Z
    %Y%m%d/%H:%M%z
    %Y%m%d/%H:%M:%S
    %Y%m%d/%H:%M:%S %Z
    %Y%m%d/%H:%M:%S%z
    %Y%m%d/%H:%M:%SZ
    %Y%m%d/%H:%M:%S\.\d*
    %Y%m%d/%H:%M:%S\.\d* %Z
    %Y%m%d/%H:%M:%S\.\d*%z
    %Y%m%d/%H:%M:%S\.\d*Z
    %Y%m%d/%H:%MZ
    %Y%m%dT%H%M
    %Y%m%dT%H%M %Z
    %Y%m%dT%H%M%S
    %Y%m%dT%H%M%S %Z
    %Y%m%dT%H%M%S%z
    %Y%m%dT%H%M%SZ
    %Y%m%dT%H%M%S\.\d*
    %Y%m%dT%H%M%S\.\d* %Z
    %Y%m%dT%H%M%S\.\d*%z
    %Y%m%dT%H%M%S\.\d*Z
    %Y%m%dT%H%M%z
    %Y%m%dT%H%MZ
    %Y%m%dT%H:%M
    %Y%m%dT%H:%M %Z
    %Y%m%dT%H:%M%z
    %Y%m%dT%H:%M:%S
    %Y%m%dT%H:%M:%S %Z
    %Y%m%dT%H:%M:%S%z
    %Y%m%dT%H:%M:%SZ
    %Y%m%dT%H:%M:%S\.\d*
    %Y%m%dT%H:%M:%S\.\d* %Z
    %Y%m%dT%H:%M:%S\.\d*%z
    %Y%m%dT%H:%M:%S\.\d*Z
    %Y%m%dT%H:%MZ
    %Y-%m-%d %H%M
    %Y-%m-%d %H%M %Z
    %Y-%m-%d %H%M%S
    %Y-%m-%d %H%M%S %Z
    %Y-%m-%d %H%M%S%z
    %Y-%m-%d %H%M%SZ
    %Y-%m-%d %H%M%S\.\d*
    %Y-%m-%d %H%M%S\.\d* %Z
    %Y-%m-%d %H%M%S\.\d*%z
    %Y-%m-%d %H%M%S\.\d*Z
    %Y-%m-%d %H%M%z
    %Y-%m-%d %H%MZ
    %Y-%m-%d %H:%M
    %Y-%m-%d %H:%M %Z
    %Y-%m-%d %H:%M%z
    %Y-%m-%d %H:%M:%S
    %Y-%m-%d %H:%M:%S %Z
    %Y-%m-%d %H:%M:%S%z
    %Y-%m-%d %H:%M:%SZ
    %Y-%m-%d %H:%M:%S\.\d*
    %Y-%m-%d %H:%M:%S\.\d* %Z
    %Y-%m-%d %H:%M:%S\.\d*%z
    %Y-%m-%d %H:%M:%S\.\d*Z
    %Y-%m-%d %H:%MZ
    %Y-%m-%d/%H%M
    %Y-%m-%d/%H%M%S
    %Y-%m-%d/%H%M%S %Z
    %Y-%m-%d/%H%M%S%z
    %Y-%m-%d/%H%M%SZ
    %Y-%m-%d/%H%M%S\.\d*
    %Y-%m-%d/%H%M%S\.\d* %Z
    %Y-%m-%d/%H%M%S\.\d*%z
    %Y-%m-%d/%H%M%S\.\d*Z
    %Y-%m-%d/%H%M%Z
    %Y-%m-%d/%H%M%z
    %Y-%m-%d/%H%MZ
    %Y-%m-%d/%H:%M
    %Y-%m-%d/%H:%M %Z
    %Y-%m-%d/%H:%M%z
    %Y-%m-%d/%H:%M:%S
    %Y-%m-%d/%H:%M:%S %Z
    %Y-%m-%d/%H:%M:%S%z
    %Y-%m-%d/%H:%M:%SZ
    %Y-%m-%d/%H:%M:%S\.\d*
    %Y-%m-%d/%H:%M:%S\.\d* %Z
    %Y-%m-%d/%H:%M:%S\.\d*%z
    %Y-%m-%d/%H:%M:%S\.\d*Z
    %Y-%m-%d/%H:%MZ
    %Y-%m-%dT%H%M
    %Y-%m-%dT%H%M%S
    %Y-%m-%dT%H%M%S %Z
    %Y-%m-%dT%H%M%S%z
    %Y-%m-%dT%H%M%SZ
    %Y-%m-%dT%H%M%S\.\d*
    %Y-%m-%dT%H%M%S\.\d* %Z
    %Y-%m-%dT%H%M%S\.\d*%z
    %Y-%m-%dT%H%M%S\.\d*Z
    %Y-%m-%dT%H%MZ
    %Y-%m-%dT%H:%M
    %Y-%m-%dT%H:%M %Z
    %Y-%m-%dT%H:%M%z
    %Y-%m-%dT%H:%M:%S
    %Y-%m-%dT%H:%M:%S %Z
    %Y-%m-%dT%H:%M:%S%z
    %Y-%m-%dT%H:%M:%SZ
    %Y-%m-%dT%H:%M:%S\.\d*
    %Y-%m-%dT%H:%M:%S\.\d* %Z
    %Y-%m-%dT%H:%M:%S\.\d*%z
    %Y-%m-%dT%H:%M:%S\.\d*Z
    %Y-%m-%dT%H:%MZ
```

A small example showing first using it to get the format and create a
object using and then just passing it a string and getting a object back.

```perl
    use Time::Piece::Guess;
    use Time::Piece;

    my $string='2023-02-27T11:00:18.33';
    my ($format, $ms_clean_regex) = Time::Piece::Guess->guess('2023-02-27T11:00:18');
    # apply the regex if needed
    if (defined( $ms_clean_regex )){
        $string=~s/$ms_clean_regex//;
    }
    my $tp_object;
    if (!defined( $format )){
        print "No matching format found\n";
    }else{
        $tp_object = Time::Piece->strptime( '2023-02-27T11:00:18' , $format );
    }

    $tp_object = Time::Piece::Guess->guess_to_object('2023-02-27T11:00:18');
    if (!defined( $tp_object )){
        print "No matching format found\n";
    }
```

`Time::Piece::Guess->guess_to_object` also supports specials that will
do some automated stuff prior to returning the object.

```text
# current time -/+ the specified number of seconds, minutes, hours, days, or weeks
now[-+]\d+[mhdw]?

# applying zz to the end of the date stamp will automatically append
# the local tz offset. Similar is true for ZZ, but instead applies the
# local TZ short name.
2023-07-23T17:34:00zz
```
