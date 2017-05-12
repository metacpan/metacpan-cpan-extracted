#!/usr/local/bin/perl
# FILE %usr/unixonly/hp200lx/txt2ndb.pl
#
# convert text files into HP200LX NDB format
#
# The input files contain one or more records, each record
# separated by a blank line.  The first non-blank line of each
# record is the title
#
# written:       1998-07-22
# latest update: 1998-07-23 19:09:19
#

use HP200LX::DB ('openDB');

# configuration and setup
$template_ndb=   'leer.ndb';    # already existing note database
                                # use any, perferably empty, note database
$template_title= 'Titel';       # field names of a German language HP200LX
$template_note=  'Notiz';       # the note field
$template_kat=   'Kategorie';   # category is not really used here ...

$note= <<EO_NOTE;
Remember:
The viewpoint of the newly produced NDB files have not been updated.
You need to sort the notes after loading them to your HP 200 LX!
EO_NOTE

die "need an empty template notetaker database called $template_ndb"
  unless (-f $template_ndb);

$input= shift (@ARGV) || &usage;
$output= shift (@ARGV) || &usage;

&transfer_text_to_ndb ($input, $output);

print $note;
exit (0);

# ----------------------------------------------------------------------------
sub usage
{
  print <<EO_HELP;
usage: $0 text-file ndb-file

Transfer the contents of text file into a ndb file.  Records are
separated by blank lines, the first line is used as the title of
the record.  An empty template notebook named $template_ndb is
required.  The template as well as the output files are configured
for the german version of the note taker.  Edit this script if
necessary.

$note
EO_HELP
  exit (0);
}

# ----------------------------------------------------------------------------
# transfer the records of a text file into a note take database.
sub transfer_text_to_ndb
{
  my $fnm_txt=  shift;  # input text file
  my $fnm_db=   shift;  # output NDB file

  my @tmp= &read_text_database ($fnm_txt);

  # NOTE: after reading all the records, we could polish them
  # in some way...

  &write_ndb_database ($fnm_db, @tmp);
}

# ----------------------------------------------------------------------------
# read all note records from the text file
sub read_text_database
{
  my $fnm_txt=  shift;  # input text file

  my @tmp;              # temporary notes database
  my $sec= '';          # current section
  my $rec;              # ref. to current record

  open (FI, $fnm_txt) || die "can not read input text file $fnm_txt";
  while (<FI>)
  {
    chop;
    s/\015//g;
    if (/^$/)
    {
      $sec= '';
      next;
    }

    if ($sec)
    { # append 
      $rec->{Notiz} .= "$_\r\n";
    }
    else
    { # The first non-blank line indicates the start of a section.
      # This line is used as the title.
      $sec= $_;

      $rec=
      {
        $template_title => $sec,
        $template_note  => '',
      };
      push (@tmp, $rec);
    }
  }
  close (FI);

  @tmp;
}

# ----------------------------------------------------------------------------
# open the existing template database and overwrite
# any records therein with records from the text file
sub write_ndb_database
{
  my $fnm_db=   shift;  # output NDB file

  my ($ndb, @ndb);      # HP 200 LX Notes Database object and array tie

  my $ndb= openDB ($template_ndb);      # The input database must exist!!
  tie (@ndb, HP200LX::DB, $ndb);

  my $num= 0;
  foreach $rec (@_)
  {
    # NOTE: Perl can not push to tied arrays (yet).
    # We have to count the records.
    $ndb[$num++]= $rec;
  }

  # finally: save the database to the disc file
  $ndb->saveDB ($fnm_db);
}
