#
# ROADS Thesaurus Object
#
# Author: jon@net.lut.ac.uk
#
# $Id: ISO.pm,v 1.4 1998/10/21 13:31:40 jon Exp jon $
#

package Text::Thesaurus::ISO;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter AutoLoader);
$VERSION = "1.0";

my($debug) = 0; # turn debugging off normally

# Constructor method
sub new {
   my $this = shift;
   my $isofile = @_;
   my $class = ref($this) || $this;
   my $self = {};
   bless $self, $class;

   if(defined($isofile)) {
     $self->open($isofile);
   }
   return $self;
}

# method to open a theasaurus
sub open {
  my($self) = shift;
  my($isofile) = @_;

  if(!dbmopen(%{$$self{"termdbm"}} ,"$isofile.term",undef)) {
    $self->reopen($isofile);
  } else {
    CORE::open(THESFILE,$isofile) || return(undef);
    dbmopen(%{$$self{"broaddbm"}} ,"$isofile.broad",0666);
  }
}

# method to reopen a theasaurus, rebuilding the database structures.
sub reopen {
  my($self) = shift;
  my($isofile) = @_;
  my($first,$line,$term,@terms,$position,@broadterms,$mainterm);

  CORE::open(THESFILE,$isofile) || return(undef);
  dbmopen(%{$$self{"termdbm"}} ,"$isofile.term",0666);
  dbmopen(%{$$self{"broaddbm"}} ,"$isofile.broad",0666);
  warn "About to undef DBM files\n" if($debug);
  undef(%{$$self{"termdbm"}});
  undef(%{$$self{"broaddbm"}});
  warn "Done undef DBM files\n" if($debug);
  $first = 0;
  while($line = <THESFILE>) {
    $line =~ s/[\n\r]//g;
    if($line eq "\$\$") {
      if($first) {
        foreach $term (@terms) {
          $term=~s/^\s+//;
          $term=~s/\s+$//;
          warn "Adding $term to termdbm\n" if($debug);
          $$self{"termdbm"}->{"$term"} = $position;
        }
        foreach $term (@broadterms) {
          $term=~s/^\s+//;
          $term=~s/\s+$//;
          warn "Adding $term to broaddbm\n" if($debug);
          if(!defined($$self{"broaddbm"}->{"$term"})){
            $$self{"broaddbm"}->{"$term"} = $mainterm;
          } else {
            $$self{"broaddbm"}->{"$term"} = 
              $$self{"broaddbm"}->{"$term"}.",$mainterm";
          }
        }
      }
      $first = 1;
      $position = tell THESFILE;
      warn "Position is now $position\n" if($debug);
      $mainterm = "";
      @terms = ();
      @broadterms = ();
    } elsif ($line =~ /TERM\s+(.*)/) {
      push(@terms,$1);
      $mainterm = $1;
    } elsif ($line =~ /ALT\s+(.*)/) {
      my($alt) = $1;
      $alt =~ s/^\s*ALTERNATE:\s*//;
      push(@terms,$alt);
    } elsif ($line =~ /UKALT\s+(.*)/) {
      my($alt) = $1;
      $alt =~ s/^\s*UK ALTERNATE:\s*//g;
      push(@terms,$alt);
    } elsif ($line =~ /UK\s+(.*)/) {
      my($alt) = $1;
      $alt =~ s/^\s*UK:\s*//g;
      push(@terms,$alt);
    } elsif ($line =~ /UF\s+(.*)/) {
      push(@terms,$1);
    } elsif ($line =~ /BT\s+(.*)/) {
      push(@broadterms,$1);
    }
  }
}

# method to get details of an input term
sub terminfo {
  my($self) = shift;
  my($inputterm) = @_;
  my($position,$line);
  my(%thesaurusrecord);

  $position = $$self{"termdbm"}->{"$inputterm"};
  warn "Position for term $inputterm is $position\n" if($debug);
  seek(THESFILE,$position,0);
  while($line = <THESFILE>) {
    $line =~ s/[\r\n]+$//;
    if($line =~ /^\$\$/) {
      last;
    } 
    if ($line =~ /([a-zA-Z0-9]+)\s+(.*)/) {
      my($attrib) = $1;
      my($value) = $2;

      $value =~ s/^ALTERNATE:\s*// if($attrib eq "ALT");
      $value =~ s/^SCOPE NOTE:\s*// if($attrib eq "SN");
      $value =~ s/^UK ALTERNATE:\s*// if($attrib eq "UKALT");
      if(!defined($thesaurusrecord{"$attrib"})) { 
        $thesaurusrecord{"$attrib"} = $value;
      } else {
        my($old) =  $thesaurusrecord{"$attrib"};
        $thesaurusrecord{"$attrib"} = "$old\n$value";
      }
    }
  }

  return(%thesaurusrecord);

}

# method to get a list of broader terms from an input term
sub broader {
  my($self) = shift;
  my($inputterm) = @_;
  my(%fullrecord);

  %fullrecord = $self->terminfo($inputterm);
  return(split("\n",$fullrecord{"BT"}));
}

# method to get a list of narrower terms from an input term
sub narrower {
  my($self) = shift;
  my($inputterm) = @_;

  return(split(",",$$self{"broaddbm"}->{"$inputterm"}));
}

# method to return the date that the record was entered
sub dateentered {
  my($self) = shift;
  my($inputterm) = @_;
  my(%record);

  %record = $self->terminfo($inputterm);
  if(defined($record{"DATENT"})) {
    return($record{"DATENT"});
  } else {
    return(undef);
  }
}

# method to return the date that the record was last changed
sub datechanged {
  my($self) = shift;
  my($inputterm) = @_;
  my(%record);

  %record = $self->terminfo($inputterm);
  if(defined($record{"DATCHG"})) {
    return($record{"DATCHG"});
  } else {
    return(undef);
  }
}

# method to get a list of alternatives terms from an input term
sub alternatives {
  my($self) = shift;
  my($inputterm) = @_;
  my(%record);
  my(@alternatives);

  %record = $self->terminfo($inputterm);
  @alternatives = split("\n",$record{"TERM"});
  push(@alternatives, split("\n",$record{"ALT"}));
  push(@alternatives, split("\n",$record{"UK"}));
  push(@alternatives, split("\n",$record{"UF"}));
  return(@alternatives);
}

# method to return a list of source information statements
sub sources {
  my($self) = shift;
  my($inputterm) = @_;
  my(%record);
  my(@sources);

  %record = $self->terminfo($inputterm);
  @sources = split("\n",$record{"SOURCE"});
  return(@sources);
}

# method to return a list of links to other terms
sub links {
  my($self) = shift;
  my($inputterm) = @_;
  my(%record);
  my(@links);

  %record = $self->terminfo($inputterm);
  @links = split("\n",$record{"LINK"});
  return(@links);
}

# method to return the scope note, which usually describes the term in
# natural language.
sub scopenote {
  my($self) = shift;
  my($inputterm) = @_;
  my(%record);
  my(@sn);

  %record = $self->terminfo($inputterm);
  @sn = split("\n",$record{"SN"});
  return(@sn);
}

# method to return the history behind a term's entry in the thesaurus
sub history {
  my($self) = shift;
  my($inputterm) = @_;
  my(%record);
  my(@sn);

  %record = $self->terminfo($inputterm);
  @sn = split("\n",$record{"HN"});
  return(@sn);
}

1;
__END__

=head1 NAME

Text::Thesaurus::ISO - A class to handle ISO thesaurii

=head1 SYNOPSIS

  use Text::Thesaurus::ISO;

  $thes = new Text::Thesaurus::ISO;
  $thes->open("myisothesfile");
  $thes->reopen("myisothesfile");
  %entry = $thes->terminfo("dumpy");
  @broaderterms = $thes->broader("dumpy");
  @narrowerterms = $thes->narrower("dumpy");
  $dateentered = $thes->dateentered("dumpy");
  $datechanged = $thes->datechanged("dumpy");
  @alternatives = $thes->alternatives("dumpy");
  @sources = $thes->sources("dumpy");
  @links = $thes->links("dumpy");
  @scopenotes = $thes->scopenote("dumpy");
  @historynotes = $thes->history("dumpy");

=head1 DESCRIPTION

This module defines an abstract ROADS Thesaurus object and a number of methods
that operate on these objects.  These methods allow new Thesaurus objects to
be created, specify what Thesaurus file to use, retrieve all the information
from the thesaurus concerning a given term, find broader terms for a given
term and find narrower terms for a given term.

=head1 METHODS

=head2 new

This creates a new (empty) thesaurus object.

=head2 open

Opens an ISO thesaurus file specified by its single parameter.  It also
checks if the backend database exists for this file and if not, creates
it.

=head2 reopen

Opens an ISO thesaurus file specified by its single parameter.  This
method always reindexes the ISO thesaurus file, and so should be called
if the ISO thesaurus file has been changed since the last time the 
index was generated.  Note that this call can be quite time consuming,
especially on a large thesaurus file, so its probably best avoided in
interactive systems (have a batch script that periodically updates the 
thesaurus indexes behind the scenes instead).

=head2 terminfo

Takes a term (a word or phrase) and returns all the information for
that term from its thesaurus record.  The information is returned in a
hash array keyed on the attribute name in the ISO thesaurus record (ie
BT, TERM, UF, etc).

=head2 broader

Takes a term and returns a list of all the broader terms for it.

=head2 narrower

Takes a term and returns a list of all the narrower terms for it.

=head2 dateentered

Takes a thesaurus term as a parameter and returns the date that the 
term's record was entered into the thesaurus file.  Returns an
undef value if the term does not exist in the thesaurus file or if
there is no entry date recorded.

=head2 datechanged

Takes a thesaurus term as a parameter and returns the date that the 
term's record was last changed in the thesaurus file.  Returns an
undef value if the term does not exist in the thesaurus file or if
there is no changed date recorded.

=head2 alternatives

Takes a thesaurus term as a parameter and returns an array of alternative
terms based on that.

=head2 sources

Takes a thesaurus term as a parameter and returns an array of source
statements that detail where the term was extracted from.

=head2 links

Takes a thesaurus term as a parameter and returns an array of links
to other terms in the thesaurus.

=head2 scopenote

Takes a thesaurus term as a parameter and returns an array of scope
notes applying to that term.  The scope notes often provide human
readable descriptions of the term and the its limits.

=head2 history

Takes a thesaurus term as a parameter and returns an array of historical
notes.  These are usually human readable comments made when major changes
have been made to the thesaurus that effect the specified term's entry.

=head1 BUGS

None known of as yet.  It is intended that more methods will be added
in the future to specifically retreive various parts of the thesaurus
record which will hopefully make the terminfo method obsolete.  Also
note that this version has only been tested against a single ISO
thesaurus file (a demonstration version of the Art and Architecture
Thesaurus) - feedback of bugs with other thesaurii are most welcome.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

It was developed by the Department of Computer Studies at Loughborough
University of Technology, as part of the ROADS project.  ROADS is funded
under the UK Electronic Libraries Programme (eLib), and the European
Commission Telematics for Research Programme.

=head1 AUTHOR

Jon Knight <j.p.knight@lut.ac.uk>
Martin Hamilton <m.t.hamilton@lut.ac.uk>







