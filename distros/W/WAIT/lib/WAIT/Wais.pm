#                              -*- Mode: Perl -*- 
# $Basename: Wais.pm $
# $Revision: 1.5 $
# Author          : Ulrich Pfeifer
# Created On      : Mon Sep 16 11:08:04 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sat Apr 15 15:51:49 2000
# Language        : CPerl
# 
# (C) Copyright 1997-2000, Ulrich Pfeifer
# 

package WAIT::Wais;

require WAIT::Query::Wais;
require WAIT::Database;
use Fcntl;
use strict;
use vars qw(%DB %TB);

my %FORMATTER;

BEGIN { # check for available formatters
  %FORMATTER = qw(text WAIT::Format::Base);
  for my $inc (@INC) {
    if (-d "$inc/WAIT/Format") {
      for my $format ( <$inc/WAIT/Format/*.pm>) {
        my ($name) = ($format =~ /(\w+)\.pm$/);
        my $module = "WAIT::Format::$name";
        $name = lc $name;
        $FORMATTER{$name} = $module;
      }
    }
  }
}


sub _database {
  my $path = shift;
  my ($dir, $dn, $tn) = ($path =~ m:(.*)/([^/]+)/([^/]+)$:);

  return $DB{"$dir/$dn"} if exists $DB{"$dir/$dn"};
  $DB{"$dir/$dn"} = WAIT::Database->open(name => $dn, directory => $dir,
                                         mode => O_RDONLY);
  return $DB{"$dir/$dn"};
}

sub _table {
  my $path = shift;

  return $TB{$path} if exists $TB{$path};
  my $db = _database($path);
  my ($dir, $dn, $tn) = ($path =~ m:(.*)/([^/]+)/([^/]+)$:);
  $TB{$path} = $db->table(name => $tn);
  $TB{$path};
}

sub Search {
  my (@requests) = @_;
  my $request;
  my $result    = new WAIT::Wais::Result;
  for $request (@requests) {
    my $query     = $request->{'query'};
    my $database  = $request->{'database'};
    my $tag       = $request->{'tag'}  || $request->{'database'};
    my ($dir, $dn, $tn) = ($database =~ m:(.*)/([^/]+)/([^/]+)$:);
    my $tb        = _table($database);
    unless (defined $tb) {
      $result->add(Tag => $tag, Error => 'Could not open database');
      return $result;
    }
    my $wquery;
    eval {$wquery = WAIT::Query::Wais::query($tb, $query)};
    if ($@ ne '') {
      $result->add(Tag => $tag, Error => $@);
      return $result;
    }
    my %po        = $wquery->execute();
    $result->add(Tag => $tag,  Database => $database,
                 Table => $tb, Postings => \%po)
  }
  $result;
}

sub Retrieve {
  my %parm = @_;
  my $result = new WAIT::Wais::Result;
  my $tb = _table($parm{database});

  unless (defined $tb) {
    $result->add(Tag => 'document', Error => 'Could not open database');
    return $result;
  }

  my $did   = ref($parm{docid})?$parm{docid}->did:$parm{docid};

  my %rec   = $tb->fetch($did);

  # another CPAN hack
  if ($rec{docid} =~ m(^data/)) {
    $rec{docid} = $tb->dir . '/' . $rec{docid};
  }

  my $text = $tb->fetch_extern($rec{docid});

  my @txt;
  $tb->open;
  if ($parm{query}) {
    @txt = WAIT::Query::Wais::query($tb,$parm{query})->hilight($text);
  } else {
    @txt = $tb->layout->tag($text);
  }

  if ($parm{lines}) {
    @txt = filter($parm{lines}, @txt);
  }

  my $type = lc $parm{type};

  my $module = (exists $FORMATTER{$type})?$FORMATTER{$type}:$FORMATTER{text};
  my $path   = $module;
  $path =~ s(::)(/)g;

  require "$path.pm";
  my $format = new $module;
  $text = $format->as_string(\@txt, sub {$tb->fetch($did)});
  $result->add(Tag => 'document', Text => $text);
}

sub filter {
  my $filter = shift;
  my @result;
  my @context;
  my $lines   = 0;
  my $clines  = 0;
  my $elipsis = 0;

  while (@_) {
    my %tag = %{shift @_};
    my $txt =  shift @_;

    for (split /(\n)/, $txt) {
      if ($_ eq "\n") {
        if (exists $tag{_qt}) {
          #die "Weird!";
          push @result, {_i=>1}, "[WEIRD]";
        } elsif ($lines) {
          push @result, {}, $_;
          $lines--;
        } else {
          push @context, {}, $_;
          $clines++;
        }
      } else {
        if (exists $tag{_qt}) {
          push @result, {_i=>1}, "\n[ $elipsis lines ]\n" if $elipsis;
          push @result, @context, {%tag}, $_;
          delete $tag{_qt};
          @context = (); $clines = 0; $elipsis=0;
          $lines = $filter+1;
        } elsif ($lines) {
          push @result, \%tag, $_;
        } else {
          push @context, \%tag, $_;
        }
      }
      if ($clines>$filter) {
        my (%tag, $txt);
        while ($clines>$filter) {
          %tag = %{shift @context};
          $txt =  shift @context;
          if ($txt =~ /\n/) {
            $clines--;
            $elipsis++;
          }
        }
      }
    }
  }
  @result;
}

package WAIT::Wais::Result;

sub new {
  my $type = shift;
  my %par  = @_;
  my $self = {'header' => [], 'diagnostics' => [], 'text' => ''};

  bless $self, $type;
}

sub _header {
  my ($database, $did, $score) = @_;
  my $types;
  my $tb = WAIT::Wais::_table($database);
  my %rec = $tb->fetch($did);
  my $lines    = $rec{'lines'} || 0;
  my $length   = $rec{'size'} || 0;
  unless ($length) {
    ($length) = ($rec{docid} =~ /(\d+)$/)
  }
  unless ($rec{docid} =~ m(^/)) {
    $rec{docid} = $tb->dir . '/' . $rec{docid};
  }
  my $headline = $rec{headline} || '';
  if (exists $rec{types}) {
    $types = [split ',', $rec{types}]
  } else {
    $types = [keys %FORMATTER];
  }

  [$score, $lines, $length, $headline, $types,
   WAIT::Wais::Docid->new('wait',$database, $did)];
}

sub add {
  my $self = shift;
  my %parm = @_;
  my $tag  = $parm{Tag};
  my $docid;

  if ($parm{Postings}) {
    my @result;
    my @left  = @{$self->{'header'}};
    my @right;
    for (keys %{$parm{Postings}}) {
      push @right, _header($parm{Database}, $_, $parm{Postings}->{$_})
    }
    while (($#left >= $[) or ($#right >= $[)) {
      if ($#left < $[) {
        for (@right) {
          push @result, [$tag, @{$_}];
        }
        last;
      }
      if ($#right < $[) {
        push @result, @left;
        last;
      }
      if ($left[0]->[1] > $right[0]->[0]) {
        push @result, shift @left;
      } else {
        push @result, [$tag, @{shift @right}];
      }
    }
    $self->{'header'} = \@result;
  }
  if ($parm{Errors}) {
    my %diag = %{$parm{Errors}};
    for (keys %diag) {
      push(@{$self->{'diagnostics'}}, [$tag, $_, $diag{$_}]);
    }
  }
  if ($parm{Text}) {
    $self->{'text'} .= $parm{Text};
  }

  $self;
}


sub diagnostics {
  my $self = shift;

  @{$self->{'diagnostics'}};
}

sub header {
  my $self = shift;

  @{$self->{'header'}};
}

sub text {
  my $self = shift;

  $self->{'text'};
}

package WAIT::Wais::Docid;

sub new {
  my $type = shift;
  my ($server, $database, $dodid) = @_;
  my $self = join ';', $server, $database, $dodid;
  bless \$self, $type;
}

sub did {
  ($_[0]->split)[2];
}

sub split {
  my $self = shift;

  split /;/, $$self;
}

1;
