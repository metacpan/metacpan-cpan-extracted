package MP3::Tag;

################
#
# provides a general interface for different modules, which can read tags
#
# at the moment MP3::Tag works with MP3::TAG::ID3v1 and MP3::TAG::ID3v2

use strict;
use MP3::TAG::ID3v1;
use MP3::TAG::ID3v2;
use vars qw/$VERSION/;

$VERSION="0.1";

=pod

=head1 NAME

Tag - Perl extension reading tags of mp3 files

=head1 SYNOPSIS

  use Tag;
  $mp3 = MP3::Tag->new($filename);
  $mp3->getTags;

  if (exists $mp3->{ID3v1}) {
    $id3v1 = $mp3->{ID3v1};
    print $id3v1->song;
    ...
  }

  if (exists $mp3->{ID3v2}) {
    ($name, $info) = $mp3->{ID3v2}->getFrame("TIT2");
    ...
  }

=head1 AUTHOR

Thomas Geffert, thg@users.sourceforge.net

=head1 DESCRIPTION

Tag is a wrapper module to read different tags of mp3 files. 
It provides an easy way to access the functions of seperate moduls
which do the handling of reading/writing the tags itself.

At the moment MP3::TAG::ID3v1 and MP3::TAG::ID3v2 are supported.

!! As this is only a beta version, it is very likely that the design 
!! of this wrapper module will change soon !!

=over 4

=item new

 $mp3 = MP3::TAG->new($filename);

Creates a mp3-object, which can be used to retrieve/set
different tags.

=cut

sub new {
  my $class = shift;
  my $self={filename=>shift};
  return undef unless -f $self->{filename};
  bless $self, $class;
  return $self;
}

=pod

=item getTags

  @tags = $mp3->getTags;

Checks which tags can be found in the mp3-object. It returns
a list @tags which contains strings identifying the found tags.

Each found tag can be accessed then with $mp3->{tagname} .

Use the information found in MP3::TAG::ID3v1 and MP3::TAG::ID3v2
to see what you can do with the tags.

=cut 

################ tag subs

sub getTags {
  my $self = shift;
  my (@IDs, $ref);
  if ($self->open()) {
    if (defined ($ref = MP3::TAG::ID3v2->new($self))) {
      $self->{ID3v2} = $ref;
      push @IDs, "ID3v2";
    }
    if(defined ($ref = MP3::TAG::ID3v1->new($self))) {
      $self->{ID3v1} = $ref;
      push @IDs, "ID3v1";
    }
    return @IDs;
  }
  return undef;
}

=pod

=item newTag

  $mp3->newTag($tagname);

Creates a new tag of the given type $tagname. You
can access it then with $mp3->{$tagname}

=cut

sub newTag {
  my $self = shift;
  my $whichTag = shift;
  if ($whichTag eq "ID3v1") {
    $self->{ID3v1}= MP3::TAG::ID3v1->new($self,1);
  } elsif ($whichTag eq "ID3v2") {
    $self->{ID3v2}= MP3::TAG::ID3v2->new($self,1);
  }
}

=pod

=item genres

  @allgenres = $mp3->genres;
  $genreName = $mp3->genres($genreID);
  $genreID   = $mp3->genres($genreName);  

Returns a list of all genres, or the according name or id to
a given id or name.

This function is only a shortcut to MP3::TAG::ID3v1->genres.

=cut

sub genres {
  # returns all genres, or if a parameter is given, the according genre
  return MP3::ID3v1::genres(shift);
}

################ file subs
sub open {
  my $self=shift;
  my $mode= shift || "<";
  unless (exists $self->{FH}) {
    if (open (FH, $mode . $self->{filename})) {
      $self->{FH} = *FH;
    } else {
      warn "Open $self->{filename} failed: $!\n";
    }
  }
  return exists $self->{FH};
}

sub close {
  my $self=shift;
  if (exists $self->{FH}) {
    close $self->{FH};
    delete $self->{FH};
  }
}

sub write {
  my ($self, $data) = @_;
  if (exists $self->{FH}) {
    print {$self->{FH}} $data;
  }
}

sub truncate {
  my ($self, $length) = @_;
  if ($length<0) {
    my @stat = stat $self->{FH};
    $length = $stat[7] + $length;
  }
  if (exists $self->{FH}) {
    truncate $self->{FH}, $length;
  }
}

sub seek {
  my ($self, $pos, $whence)=@_;
  $self->open unless exists $self->{FH};
  seek $self->{FH}, $pos, $whence;
}

sub tell {
  my ($self, $pos, $whence)=@_;
  return undef unless exists $self->{FH};
  return tell $self->{FH};
}

sub read {
  my ($self, $buf_, $length) = @_;
  $self->open unless exists $self->{FH};
  return read $self->{FH}, $$buf_, $length;
}

sub isOpen {
  return exists shift->{FH};
}


sub DESTROY {
  my $self=shift;
  if (exists $self->{FH}) {
    $self->close;
  }
}


1;

=pod

=head1 SEE ALSO

MP3::TAG::ID3v1, MP3::TAG::ID3v2

=cut
