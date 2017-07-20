## Glossary

```
SN         = Eksisozluk (Social Network)
Module     = WWW::Eksi (SN parser)
Entry      = A single post in SN, with at least one timestamp
CreateTime = Timestamp which shows create time of an entry
UpdateTime = Optional timestamp which shows update time of an entry

DST        = Daylight Saving Time
TZ         = Timezone
EET        = Eastern European Time
EEST       = Eastern European Summer Time
DZ         = Danger Zone
```

## Summary

 - SN probably did not store TZ information in DB
 - DST changes were out of sync with the actual rules (until 2007)
 - There is no way to decide on TZ in entry's `update time`
Whenever you get a parsed time through WWW::Eksi, it will not contain time-zone (TZ) information from v0.20 on.

## Background

Turkey had Daylight Saving Time (DST) since 1940:

```
    WINTER: Eastern European Time        (EET)   UTC+2  October to March
    SUMMER: Eastern Europen SUMMER Time  (EEST)  UTC+3  March to October
```

Spring forward day (March) is a 23 hour day, with no 01:30 happening. If we can find an entry with `create time` 01:30 (we can), we know there's a problem. Hence, I would like to call this interval that never existed *DANGER ZONE* (DZ).

Fall back day is 25 hours, hence two 01:30s. Even if you assume everything on Eksisozluk is correct (it's not), we need to find a way to distinguish first 01:30 (+3) from the second (+2).

As an example, assume we are parsing a post with timestamp "27 October 2013 01:30". Just by looking at this data, we cannot tell if this date-time is EET or EEST. I would like to call this ambiguous interval *DANGER ZONE* as well.

## Spring Forward: Try-Catch

### If correct DST rules were applied

With one hour jump, and no ambiguous intervals, DateTime actually find correct timezones pretty fast.

### Reality

Eksisozluk had a different set of DST rules: For 2001 through 2006, Turkey had observed DST at 01:00, whereas Eksisozluk had it at 02:00. Here's a hypothetical example:

| ID   | SN Time       | Turkey Time   | Comment     |
| ---- | ------------- | ------------- | ----------- |
| 201  | 00:59:59 (+2) | 00:59:59 (+2) |             |
| 202  | 01:00:01 (+2) | 02:00:01 (+3) | DANGER ZONE |
| ...  | ............  | ............  | DANGER ZONE |
| 222  | 01:59:59 (+2) | 02:59:59 (+3) | DANGER ZONE |
| 223  | 03:00:01 (+3) | 03:00:01 (+3) |             |
| ...  | ............  | ............  |             |
| 298  | 03:59:59 (+3) | 03:59:59 (+3) |             |
| 299  | 04:00:01 (+3) | 03:59:59 (+3) |             |

If you try to create a `DateTime` object with Europe/Istanbul local, it will give you an error:
`Invalid local time for date in time zone: Europe/Istanbul`. We can, however, catch that error, manually increment 'hour' by one, and then re-create DateTime object. This will result in us having correct TZ data, even though it's not what is displayed on SN. Note that this solution works both for create time and update time, and it requires no additional information.

## Fall back: Looking at IDs

### If correct DST rules were applied

We can use additional data to understand the timezone. An intuitive idea is to utilize entry ids. We can locate posts at borders of DZ, hardcode their ids into module, and that would solve all our problems, right? (nope.) Let's look at this hypothetical list of entries.

| ID   | Time          | Comment     |
| ---- | ------------- | ----------- |
| 501  | 01:59:59 (+3) |             |
| 502  | 02:00:01 (+3) | DANGER ZONE |
| ...  | ............. | DANGER ZONE |
| 554  | 02:59:59 (+3) | DANGER ZONE |
| 555  | 02:00:01 (+2) | DANGER ZONE |
| ...  | ............. | DANGER ZONE |
| 598  | 02:59:59 (+2) | DANGER ZONE |
| 599  | 03:00:01 (+2) |             |

Now, observe that entry #502 and #555 have exactly the same time, but different timezones. If we just use parsed HTML, `DateTime` will always assume latest possible timezone, which is +2. Hence, entries with id greater than 502 will parse to +2, but we know that 502-554 are in +3, and we can use it to set correct timezone. All we have to do is to find border entries for all years that have fall back (2001 through 2015), implement a method which will decide on TZ. Note that this doesn't provide a solution for update times.

### Reality

Just look at this table.

| ID   | SN Time       | Turkey Time   | Comment     |
| ---- | ------------- | ------------- | ----------- |
| 709  | 00:59:59 (+3) | 00:59:59 (+3) |             |
| 710  | 01:00:01 (+3) | 01:00:01 (+3) | DANGER ZONE |
| ...  | ............  | ............  | DANGER ZONE |
| 719  | 01:59:59 (+3) | 01:59:59 (+3) | DANGER ZONE |
| 720  | 02:00:01 (+3) | 01:00:01 (+2) | DANGER ZONE |
| ...  | ............  | ............  | DANGER ZONE |
| 729  | 02:59:59 (+3) | 01:59:59 (+2) | DANGER ZONE |
| 730  | 02:00:01 (+2) | 02:00:01 (+2) | DANGER ZONE |
| ...  | ............  | ............  | DANGER ZONE |
| 739  | 02:59:59 (+2) | 02:59:59 (+2) | DANGER ZONE |
| 740  | 03:00:01 (+2) | 03:59:59 (+2) |             |

I have a huge DZ here, and the reason is we have two 02:00s according to SN, and two 01:00 according to rules that were actually applied. Our simple "try catch" won't work here, because it won't error. Instead, we need a clear mapping.

 - If we see 01:30 on SN, we know it's 01:30 (+3) for sure. That's because SN didn't do fall-back yet. However, when we give this to `DateTime`, it will assume (+2), because correct rules have two possibility for 01:30. This can be avoided by subtracting one hour: DateTime will apply it to TZ. No ID needed so far.
 - If we see 02:30 on SN, that's SN's danger zone: there are two possibilities. `DateTime` will think it's +2 (as there's only one 02:30 with correct rules). If entry is written after DST change (look: ID between 730-739), then this is actually correct. If it was written before (720-729), then we need to subtract another hour. We *do* need to know ID numbers to make the decision though.

## Conclusion

- Spring Forward out-of-sync problem can be solved without additional data. It can be solved both for create time and update time.
- Fall back problem *needs* entry ids to be hardcoded in module. Even then, it doesn't fix the problem for update time.
- This problem only applies to a very tiny subset of entries you can reach with WWW::Eksi. This can be read in two ways:
  - If it only applies to small number of entries, then just drop the TZ for those
  - If it only applies to small number of entries, don't spend time looking for ids & implementing weird control subroutines. (Write a blog instead.)

## Appendix: DST observance for Turkey between 1999-2016

Spring Forward   |  Fall Back       | Comment                     |
---------------- | ---------------- | ----------------------------|
03/28/1999 01:00 | 10/31/1999 02:00 | SN has no time (only date)  |
03/26/2000 01:00 | 10/29/2000 02:00 | out of sync from here on    |
03/25/2001 01:00 | 10/28/2001 02:00 |                             |
03/31/2002 01:00 | 10/27/2002 02:00 |                             |
03/30/2003 01:00 | 10/26/2003 02:00 |                             |
03/28/2004 01:00 | 10/31/2004 02:00 |                             |
03/27/2005 01:00 | 10/30/2005 02:00 |                             |
03/26/2006 01:00 | 10/29/2006 02:00 |                             |
03/25/2007 01:00 | 10/28/2007 02:00 |                             |
03/30/2008 03:00 | 10/26/2008 04:00 | in sync from this year on   |
03/29/2009 03:00 | 10/25/2009 04:00 |                             |
03/28/2010 03:00 | 10/31/2010 04:00 |                             |
03/28/2011 03:00 | 10/30/2011 04:00 |                             |
03/25/2012 03:00 | 10/28/2012 04:00 |                             |
03/31/2013 03:00 | 10/27/2013 04:00 |                             |
03/31/2014 03:00 | 10/26/2014 04:00 |                             |
03/29/2015 03:00 | 11/08/2015 04:00 |                             |
03/27/2016 03:00 | ---------------  | Turkey ends DST observance  |
