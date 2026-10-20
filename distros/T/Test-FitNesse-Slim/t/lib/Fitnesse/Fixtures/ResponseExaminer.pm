package Fitnesse::Fixtures::ResponseExaminer;

use strict;
use warnings;

use Encode qw(decode FB_DEFAULT);
use HTML::Entities qw(decode_entities encode_entities);
use Fitnesse::Fixtures::ResponseContext;

sub new {
  my($class) = @_;
  bless {
    type => undef,
    pattern => undef,
    line => undef,
    value => undef,
    number => 0,
    group => 0,
    matcher => undef,
    current_line => 0,
    current_position => 0,
  } => $class;
}

sub contents {
  my($self) = @_;
  decode_entities($self->_response_content);
}

sub html {
  my($self) = @_;
  $self->_response_content;
}

sub full_contents {
  my($self) = @_;
  encode_entities($self->_response_content, '<>&"');
}

sub status {
  my($self) = @_;
  my $response = $self->_response;
  defined($response->{status}) ? "$response->{status}" : undef;
}

sub in_order {
  my($self) = @_;
  return 'false' unless defined $self->{line};
  my @lines = split /\n/, $self->_response_content;
  my $needle = $self->{line};
  $needle =~ s/^\s+|\s+$//g;
  for (my $i = $self->{current_line}; $i < @lines; $i++) {
    my $line = $lines[$i];
    $line =~ s/^\s+|\s+$//g;
    if (index($line, $needle) >= 0) {
      $self->{current_line} = $i;
      return 'true';
    }
  }
  return 'false';
}

sub occurs_after {
  my($self) = @_;
  return 'false' unless defined $self->{line};
  my $position = index($self->_response_content, $self->{line}, $self->{current_position});
  return 'false' if $position < 0;
  $self->{current_position} = $position;
  return 'true';
}

sub match_count {
  my($self) = @_;
  my $regex = $self->_pattern;
  my $value = $self->extract_value_from_response;
  my $count = 0;
  $count++ while $value =~ /$regex/g;
  pos($value) = 0;
  $count;
}

sub extract_value_from_response {
  my($self) = @_;
  my $type = $self->{type};
  my $response = $self->_response;
  my $value;
  if (defined($type) && $type eq 'contents') {
    $value = decode_entities($self->_response_content);
  }
  elsif (defined($type) && $type eq 'fullContents') {
    $value = $self->full_contents;
  }
  elsif (defined($type) && $type eq 'rawContents') {
    $value = $self->_response_content;
  }
  elsif (defined($type) && $type eq 'stringContents') {
    $value = $self->_response_content;
  }
  elsif (defined($type) && $type eq 'pageContents') {
    $value = $response->{page_content} // $self->_response_content;
  }
  elsif (defined($type) && $type eq 'pageHtml') {
    $value = $response->{page_html} // $self->_response_content;
  }
  elsif (defined($type) && $type eq 'matchers') {
    $value = $self->{matcher} ? $self->{matcher}->[$self->{group}] : undef;
  }
  elsif (defined($type) && $type eq 'status') {
    $value = defined($response->{status}) ? "$response->{status}" : undef;
  }
  elsif (defined($type) && $type eq 'headers') {
    my $headers = $response->{headers} || {};
    $value = join "\r\n", map { "$_: $headers->{$_}" } sort keys %$headers;
  }
  else {
    die "Bad type in ResponseExaminer";
  }
  $self->{value} = $value;
  return $value;
}

sub matches {
  my($self) = @_;
  $self->match_count > 0 ? 'true' : 'false';
}

sub string {
  my($self) = @_;
  if (defined($self->{type}) && $self->{type} eq 'contents') {
    return $self->_response->{page_html} // $self->_response_content;
  }
  if (defined($self->{type}) && $self->{type} eq 'line') {
    return $self->get_line($self->{number});
  }
  die "Bad type in ResponseExaminer";
}

sub get_line {
  my($self,$number) = @_;
  my $page_html = $self->_response->{page_html} // $self->_response_content;
  $page_html =~ s{<br/>}{\n}g;
  my @lines = grep { length } split /\n/, $page_html;
  return undef if $number < 1 || $number > @lines;
  my $line = $lines[$number - 1];
  $line =~ s/^\s+|\s+$//g;
  return $line;
}

sub found {
  my($self,$group) = @_;
  $group = $self->{group} unless defined $group;
  my $regex = $self->_pattern;
  my $value = $self->extract_value_from_response;
  if ($value =~ /$regex/) {
    my @groups = ($value =~ /$regex/);
    $self->{matcher} = [ $&, @groups ];
    return $self->{matcher}->[$group];
  }
  $self->{matcher} = undef;
  return undef;
}

sub extract_match {
  my($self,$pattern,$type,$group) = @_;
  $self->{pattern} = $pattern if defined $pattern;
  $self->{type} = $type if defined $type;
  $self->{group} = $group if defined $group;
  $self->found;
}

sub source {
  my($self) = @_;
  $self->{value};
}

sub wrapped_html {
  my($self) = @_;
  my $text = $self->_response_content;
  $text =~ s{(<br */?>)}{$1\n}g;
  '<pre>' . encode_entities($text, '<>&"') . '</pre>';
}

sub set_type { $_[0]->{type} = $_[1]; return; }
sub set_pattern { $_[0]->{pattern} = $_[1]; return; }
sub set_value { $_[0]->{value} = $_[1]; return; }
sub set_number { $_[0]->{number} = $_[1]; return; }
sub set_group { $_[0]->{group} = $_[1]; return; }
sub set_line { $_[0]->{line} = $_[1]; return; }
sub get_value { $_[0]->{value}; }

sub _pattern {
  my($self) = @_;
  die "response pattern is not set" unless defined $self->{pattern};
  my $regex = eval { qr/$self->{pattern}/ms };
  die "invalid response pattern: $@" if $@;
  return $regex;
}

sub _response {
  my($self) = @_;
  my $response = Fitnesse::Fixtures::ResponseContext->current;
  die "no FitNesse response is available" unless $response;
  return $response;
}

sub _response_content {
  my($self) = @_;
  my $content = $self->_response->{content} // '';
  return $content if utf8::is_utf8($content);
  return decode('UTF-8', $content, FB_DEFAULT);
}

1;
