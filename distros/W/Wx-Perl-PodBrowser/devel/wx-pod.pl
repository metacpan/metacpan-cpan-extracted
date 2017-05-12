#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2016 Kevin Ryde

# This file is part of Wx-Perl-PodBrowser.
#
# Wx-Perl-PodBrowser is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Wx-Perl-PodBrowser is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Wx-Perl-PodBrowser.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use Wx;
use Wx::RichText;

# uncomment this to run the ### lines
# use Smart::Comments;

my $str;

# {
#   my $app = Wx::SimpleApp->new;
#   my $frame = Wx::Frame->new(undef, Wx::wxID_ANY(), 'Pod');
#
#   require Wx::Perl::PodRichText;
#   my $textctrl = Wx::Perl::PodRichText->new ($frame);
#   # $textctrl->goto_pod (string => $str);
#   # $textctrl->goto_pod (module => 'FindBin');
#   $textctrl->goto_pod (module => 'perlfunc');
#   #  $textctrl->goto_module (module => 'Math::PlanePath::SquareSpiral');
#
#   $frame->SetSize (800, 800);
#
#   $frame->Show;
#   $app->MainLoop;
#   exit 0;
# }

$str = <<'HERE';
=head1 NAME

Foo - bar

Foo2 - bar2

=head1 DESCRIPTION

This is a paragraph.
Over two lines.
Blah.
Blah.  Blah

X<Idx B<entry>>L<libE<sol>Foo.pm> ...
L<Tk::HistEntry/BUGS/TODO> ...
L<Tk::HistEntry/BUGSE<sol>TODO> ...
L<Devel::REPL::Plugin::Nopaste/#nopaste> ...
L<Getopt::Long::Descriptive/%arg>

X<Breakability>Breakable words and then S<block of non breaking spaces extending to HERE>
blah blah.

=head4 Foo & Bar && Quux

=over

=item Item One

=cut

=pod

=item Item Two

=item Item Three

Paragraph.

=back

X<Index entry>  blah
Verbatim fjsdk fksdj fjks fjksd fjksd.  Fjs dfjks djfk sdjkf sdkf sdf

    +----------------------------------------+
    |                                        |
    +----------------------------------------+

    and more
    verb

    atim
    atim2

C<code+-------+> C<bold> plain I<italic> I<I<italicitalic>> plain F<file> plain.

link L<Math::Symbolic/SEE ALSO> F<filename>

link L<perlfunc/bind>

mucho duplicate heads: L<Padre::Current/NAME>,
L<Set::IntSpan/Examples>,
L<XML::RSS::Timing/AUTHOR>

plain L<http://localhost/index.html>
disp L<display part|http://localhost/index.html>

C<code> B<bold> I<italic> E<65> E<48> E<gt> E<fdjk> B<I<bold+italic>>

I<B<italic+bold> italicagain>

C<I<code+italic> codeagain>

C<code I<+italic B<+bold> italicagain> codeagain>

C<B<code+bold> codeagain>

B<C<bold+code> boldagain>

I<italic I<italic+italic> italicagain>.

link L</mysection>
link L<Math::Symbolic>
link L<Math::NumSeq>

=over

=item 1

item heading of first

more text of first E<16384>, with char 16384

=item 2

item heading of second

more text of second

=item 456789

item heading of blah

more text of blah

=item 3

item heading of third

more text of third

=item 5

heading

=item 5

heading

=item 5

heading

=item 5

heading

=item 5

heading

=item 5

heading

=item 5

heading

=item 5

heading

=item 5

heading

=item 5

heading

=item 5

heading

=item 5

heading

=item 5

heading

=item 5

heading

=item 5

heading

=back

=begin comment

begin comment

=end comment

=begin something

begin block

=end something

=begin text

begin text

more of begin text

=end text

=head2 mysection

=over 4

Indent level one

=over 4

Indent level two

=over 4

Indent level three

=back

=back

=back




Plain para.


Plain para.

=over

=item first item

text of first

=item second C<foo-E<gt>bar> item

text of second

=back

Plain para.

=over

=item *

text of b1

plain b1

=item *

text of b2

plain b2

=back

=for nothing

=over 4

Indent

=over 4

=item *

bullet

Indent more

=back

=back

X<Unindented>Unindented

=head1 & YY jkl jfkls jfkls jfk lsjfkls jfk sdjfkl sdjflksd jflks djfkl sdjflk

Foo.

=head1 E<32>ZZ

=head2 mysection

X<duplicate>duplicate mysection

=cut
HERE

{
  my $app = Wx::SimpleApp->new;
  require Wx::Perl::PodBrowser;
  my $browser = Wx::Perl::PodBrowser->new ();
  $browser->SetTitle ('hello');
  $browser->Show;
  if (@ARGV) {
    $browser->goto_pod (guess => $ARGV[0]);
  } else {
    #$browser->goto_pod (string => "=encoding utf-8\n\nSome text.\n");
     $browser->goto_pod (string => $str);
    # $browser->goto_pod (string => "=pod\n\nabc");
    # $browser->goto_pod (string => $str);
    # $browser->goto_pod (module => 'Math::NumSeq::HafermanZ');
    # $browser->goto_pod (module => 'Math::Symbolic::AuxFunctions');
    # $browser->goto_pod (module => 'Math::PlanePath::PeanoCurve',
    #                     section => 'SEE ALSO');
    # $browser->goto_pod (module => 'FindBin');
    # $browser->goto_pod (module  => 'perlfunc',
    #                     section => 'abs');
    # $browser->goto_pod (module => 'perlop');
    # $browser->goto_pod (module => 'perlop');
    # $browser->goto_pod (string  => "=head1 NAME\n\nplain\n");
    # $browser->goto_pod (string  => "=head1 NAME\n\nplain\n");

    # $browser->pod_print();
  }
  $app->MainLoop;
  exit 0;
}
