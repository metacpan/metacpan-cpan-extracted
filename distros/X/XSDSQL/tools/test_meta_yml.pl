#!/usr/bin/env perl

#
# test META.yml file 
# META.yml is generated from Makefile.PM with name MYMETA.yml
#


use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 13
use Test::More tests => 2;
use Test::CPAN::Meta::YAML;

my $file=defined $ARGV[0] ? $ARGV[0] : '../META.yml';

unless (-r $file) {
	print STDERR "file $file is not readable\n";
	exit 1;
}

#meta_spec_ok('META.yml','1.3',$msg);
#meta_spec_ok(undef,'1.3',$msg);

meta_spec_ok($file,undef);
exit 0;
__END__

=head1 NAME test_meta_yml.pl

=cut


=head1 VERSION

0.10.0

=cut



=head1 BUGS

Please report any bugs or feature requests to https://rt.cpan.org/Public/Bug/Report.html?Queue=XSDSQL

=cut



=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>


=cut


=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
