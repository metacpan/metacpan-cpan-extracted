package XML::XCES;

use XML::DT;

use warnings;
no warnings 'recursion';
use strict;

=head1 NAME

XML::XCES - Perl module to handle XCES xml files

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use XML::XCES;

    XML::XCES->align2pair("File.xml", "prefix");

=head1 FUNCTIONS

XML::XCES provides the following functions:

=head2 align2pair

This function receives an XCES xml filename with sentence alignment
content, and, optionally, a prefix for the output files.

Note that the aligned files paths should be absolute or relative to
the command issue directory.

=cut

sub align2pair {
  shift if ($_[0] eq "XML::XCES");
  my $xces = shift;
  my $prefix = shift || $xces;

  my $tuCount = 0;

  open S, ">$prefix-source.nat" or die;
  open T, ">$prefix-target.nat" or die;

  my %handler = (
		 -type => { linkGrp => 'SEQ' },

		 'link' => sub {
		   my ($s, $t) = split /\s*;\s*/, $v{xtargets};
		   my @s = grep { /./ } split /\s+/, $s;
		   my @t = grep { /./ } split /\s+/, $t;
		   return [[@s],[@t],$v{certainty}];
		 },

		 'linkGrp' => sub {
		   my ($source,$target) = ($v{fromDoc},$v{toDoc});
		   return unless -f $source and -f $target;

		   my $cont = $c;
		   printf STDERR "+ %s * %s ", _last26($source), _last26($target);

		   my (%s,%t);
		   my $ACTIVE;
		   my %h2 = (
			     -type => { linkGrp => 'SEQ' },

			     -outputenc => 'iso-8859-1',

			     -default => sub {
			       $c = _trim($c);
			       if ($v{id} && exists($ACTIVE->{$v{id}})) {
				 $ACTIVE->{$v{id}} = $c;
			       }
			       $c
			     });

		   my $tu = 0;
		   for my $link (@$cont) {
		     $tu++;
		     @s{@{$link->[0]}} = 1 x @{$link->[0]};
		     @t{@{$link->[1]}} = 1 x @{$link->[1]};
		   }
		   print STDERR "($tu TUs)\n";
		   $tuCount+=$tu;

		   $ACTIVE = \%s;
		   dt($source, %h2);

		   $ACTIVE = \%t;
		   dt($target, %h2);

		   for my $link (@$cont) {
		     print S (map { "$_\n" } (@s{@{$link->[0]}},'$'));
		     print T (map { "$_\n" } (@t{@{$link->[1]}},'$'));
		   }
		 },
		);

  dt($xces, %handler);

  return $tuCount;
}


sub _trim {
  my $x = shift;
  $x =~ s/\s+/ /g;
  $x =~ s/^\s+//;
  $x =~ s/\s+$//;
  return $x;
}

sub _last26 {
  my $x = shift;
  if (length($x)>26) {
    return "...".substr($x,-23,23);
  } else {
    return $x
  }
}



=head1 AUTHOR

Alberto Simoes, C<< <ambs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-xces@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2004-2005 Alberto Simoes, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of XML::XCES
