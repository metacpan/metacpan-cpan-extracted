#!/usr/bin/perl -Ilib -w

#
# Copyright (c) 2006-2011, TomTom International B.V.
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

=head1 NAME

show_objects - Using C<TomTom::WEBFLEET::Connect> to display a list of objects

=head1 SYNOPSIS

 showObjects.pl [options]

   Options:
     --accout     Account name (required)
     --username   User name (required)
     --password   Password (required)
     --trace      Enable trace output (URL, response)
     --xml        Output data as XML
     --help|?     Show help
     --man        Show manual

=head1 DESCRIPTION

B<showObjects> will query TomTom WEBFLEET.connect for a list of objects and write everything to standard output, either as a Perl expression or as XML.

=head1 SEE ALSO

L<TomTom::WEBFLEET::Connect>

=head1 COPYRIGHT

Copyright 2006-2011 TomTom International B.V.

All rights reserved.

=cut

use strict;
use TomTom::WEBFLEET::Connect;
use Getopt::Long;
use Pod::Usage;

my %opt = ();
GetOptions(\%opt, 'account=s', 'username=s', 'password=s', 'trace!', 'xml', 'man');
pod2usage(-exitstatus => 0, -verbose => 2) if $opt{man};
pod2usage(2) if (!defined($opt{account}) or !defined($opt{username}) or !defined($opt{password}));

my $connect = new TomTom::WEBFLEET::Connect((%opt, useISO8601=>'true'));
my @objects;
my $r = $connect->showObjectReport();
if ($r->is_success) {
  foreach my $i (@{$r->content_arrayref}) {
    push @objects, $i;
  }
} else {
  print $r->code, " - ", $r->message, "\n";
}

if ($opt{xml}) {
  use XML::Simple;
  print '<?xml version="1.0" encoding="utf-8"?>', "\n";
  print '<objects>', "\n";
  foreach my $i (@objects) {
    print XMLout($i, NoAttr=>1,RootName=>'object');
  }
  print '</objects>', "\n";
} else {
  use Data::Dumper;
  print Dumper(\@objects);
}

__END__
