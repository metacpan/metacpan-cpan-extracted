# Blosxom Plugin: tiki
# Author(s): Rael Dornfest <rael@oreilly.com> 
# Version: 2.0b2
# Documentation: See the bottom of this file or type: perldoc tiki

package tiki;

# --- Configurable variables -----

# What flag in your weblog entries lets me know to turn on tiki translation?
my $tiki_on_flag = "<!-- tiki on -->";

# --------------------------------

use lib qq{$blosxom::plugin_dir/lib};

sub start {
  eval "require Text::Tiki";
  return $@ ? 0 : 1;
}

sub story {
  my($pkg, $path, $filename, $story_ref, $title_ref, $body_ref) = @_;

  $$body_ref =~ s/$tiki_on_flag//mi or return 0;

  my $processor=new Text::Tiki;
  $$body_ref = $processor->format($$body_ref);
  
  return 1;
}

1;

__END__

=head1 NAME

Blosxom Plug-in: tiki

=head1 SYNOPSIS

Purpose: Provides Tiki [http://www.mplode.com/tima/archives/000215.html] 
formatting for Weblog entries.

Assumes $plugin_dir/lib/Text/Tiki.pm

=head1 VERSION

2.0b2

Version number coincides with the version of Blosxom with which the 
current version was first bundled.

=head1 AUTHOR

Rael Dornfest  <rael@oreilly.com>, http://www.raelity.org/

=head1 SEE ALSO

Blosxom Home/Docs/Licensing: http://www.raelity.org/apps/blosxom/

Blosxom Plugin Docs: http://www.raelity.org/apps/blosxom/plugin.shtml

=head1 BUGS

Address bug reports and comments to the Blosxom mailing list 
[http://www.yahoogroups.com/group/blosxom].

=head1 LICENSE

Blosxom and this Blosxom Plug-in
Copyright 2003, Rael Dornfest 

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
