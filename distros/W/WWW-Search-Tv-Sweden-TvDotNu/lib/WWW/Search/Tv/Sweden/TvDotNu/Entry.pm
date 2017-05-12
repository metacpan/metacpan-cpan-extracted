# $Id: Entry.pm,v 1.2 2004/03/31 20:28:29 claes Exp $

package WWW::Search::Tv::Sweden::TvDotNu::Entry;
use strict;

sub new {
  my ($class, %attr) = @_;
  $class = ref($class) || $class;
  bless {
	 description => "",
	 imdb => "",
	 channel => "",
	 showview => "",
	 
	 %attr,
	}, $class;
}

# Mutators
sub title {
  my $self = shift;
  $self->{title} = shift if @_;
  return $self->{title};
}
  
sub channel {
  my $self = shift;
  $self->{channel} = shift if @_;
  return $self->{channel};
}

sub url {
  my $self = shift;
  return $self->{url};
}

sub showview {
  my $self = shift;
  $self->{showview} = shift if @_;
  return $self->{showview};
}

sub description {
  my $self = shift;
  $self->{description} = shift if @_;
  return $self->{description};
}

sub imdb {
  my $self = shift;
  $self->{imdb} = shift if @_;
  return $self->{imdb};
}

# HTML::Parser callbacks
sub _entry_start_h {
  my ($self) = @_;
  
  return sub {
    my ($tagname, $attr) = @_;

    if($tagname eq 'a') {
      if(exists $attr->{href} && $attr->{href} =~ /imdb\.com/) {
	my $imdb = $attr->{href};
	$imdb =~ s/\n//g;
	$self->imdb($imdb);
      }
    }
  };
}

sub _entry_text_h {
  my ($self) = @_;
  
  return sub {
    my ($text) = @_;
    
    # Make text look nicer
    $text =~ s/^\s+//;
    $text =~ s/\n/ /g;
    $text =~ s/\s+$//;
    $text =~ s/\s+/ /;
    
    if($text =~ /ShowView\s*\|\s*(\d+)\s*\|/i) {  # Check for showview
      $self->showview($1);
    } elsif($text =~ /^.vrigt:\s*(.*)$/) {        # Check for description
      $self->description($1);
    }
  };
}

sub _entry_end_h {
  my ($self) = @_;
  
  return sub {};
}

# Checkers
sub in {
  my ($self, $start_hour, $start_min, $end_hour, $end_min) = @_;
  
  my $start_time = ($start_hour * 60) + $start_min;
  my $end_time = ($end_hour * 60) + $end_min;
  $end_time += 1440 if $end_time < $start_time;
  
  my $entry_start_time = ($self->{start_time}->[0] * 60) + $self->{start_time}->[1];
  return 1 if($entry_start_time > $start_time && $entry_start_time < $end_time);
    
  0;
}

# Formating
sub start_time {
    my ($self) = @_;
    return sprintf("%02d:%02d", $self->{start_time}->[0], $self->{start_time}->[1]);
}

sub end_time {
    my ($self) = @_;
    return sprintf("%02d:%02d", $self->{end_time}->[0], $self->{end_time}->[1]);
}

1;
