#
# Copyright (c) 2006-2011 TomTom International B.V.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the TomTom nor the names of its
#   contributors may be used to endorse or promote products derived from this
#   software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

package TomTom::WEBFLEET::Connect::Response;
use Text::ParseWords;
use Data::Dumper;
use Encode;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %params = @_;
  #my $response = shift; # a HTTP::Response
  my $duration = $params{duration}; #shift; # 

  my $self = {
    data => { raw => undef, array => undef },
    error => { code => 0, desc => undef },
    stats => { duration => undef}
  };

  bless($self, $class);

  if ($params{response}) {
    my $response = $params{response};
    # extract return data and error code from HTTP::Response
    if ($response->is_success) {
      if ($response->content =~ /^([\d\w_]+),(.*)$/) {
        $self->{error}{code} = $1;
        $self->{error}{desc} = $2;
      } else {
        $self->{data}{raw} = decode("utf8", $response->content);
      }
    } else {
      $response->status_line =~ /^(\d+)\s+(.*)$/;
        $self->{error}{code} = $1;
        $self->{error}{desc} = $2;
    }
  }
  elsif ($params{mockup}) {
    open(MOCKUP, "<$params{mockup}") or die $!;
    $self->{data}{raw} = join('',<MOCKUP>);
  }
  $self->{stats}{duration} = $duration;

  # parse return data into an array of hashes
  my @names;
  foreach $i (split /[\r\n]+/, $self->{data}{raw}) {
    my @j = parse_line(';', 0, $i);
    if (!@names) {
      @names = @j;
    } else {
      my %h;
      for $k (0 .. $#names) {
        $h{$names[$k]} = $j[$k];
      }
      push @{$self->{data}{array}}, \%h;
    }
  }

  return $self;
}

sub is_success {
  my $self = shift;
  return !$self->{error}{code};
}

sub code {
  my $self = shift;
  return $self->{error}{code};
}

sub message {
  my $self = shift;
  return $self->{error}{desc};
}

sub duration {
  my $self = shift;
  return $self->{stats}{duration};
}

sub content_raw {
  my $self = shift;
  return $self->{data}{raw};
}

sub content_arrayref {
  my $self = shift;
  if (is_success) {
    return \@{$self->{data}{array}};
  } else {
    return undef;
  }
}

1;
