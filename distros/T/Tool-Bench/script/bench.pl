#!/usr/bin/perl 
use strict;
use warnings;
use Getopt::Long;
use Tool::Bench;

=head1 EXAMPLE

  perl -Ilib script/bench.pl --interp 'perl -Ilib' --file 't/01-works.t' --count 3 --format JSON

=head1 TODO

needs docs

=cut

die qx{perldoc $0} unless @ARGV;

my ($count,$format,$interp,$file) = (1,'JSON'); #supply defaults;
my $opt = GetOptions ("interp=s" => \$interp,
                      "file=s"   => \$file,
                      "format=s" => \$format,
                      "count=i"  => \$count,
                     );

my $bench = Tool::Bench->new;
my $cmd = join ' ', $interp, $file;
$bench->add_items($file => sub{qx{$cmd}});
$bench->run($count);
print $bench->report(format => $format, interp => $interp);
