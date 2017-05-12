#===============================================================================
#
#  DESCRIPTION:  Test get bookinfo blocks
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================

package main;
use strict;
use warnings;
use v5.10;
use Test::More tests => 13;    # last test to print
use Perl6::Pod::Utl;
use Data::Dumper;
use WriteAt;
use utf8;
use_ok('WriteAt');

my $t = <<T;
=begin pod
=ЗАГОЛОВОК asdasd
=SUBTITLE asdasd
=for DESCRIPTION :tag<tag pod6 test>
asd asd 
=begin CHANGES
Sep 19th 2011(v0.7)[zag]   Классы и объекты

May 13th 2011(v0.6)[zag]   Формат Pod

Jan 08th 2011(v0.5)[zag]   Подпрограммы и сигнатуры

=end CHANGES
=AUTHOR Александр Загацкий

=for CHAPTER :published<'2012-11-27T09:39:19Z'> :tag<intro>
Test chapter

Ok 
=head1 Test name
=head2 test

yes

=head1 Test 1

ok

=CHAPTER Test chapter2

Ok 
=head1 Teste

=end pod
T

#utf8::decode($t) unless utf8::is_utf8($t);

my $tree = Perl6::Pod::Utl::parse_pod( $t, default_pod => 1 )
  || die "Can't parse ";
my %res = ();
$tree = &WriteAt::get_book_info_blocks( $tree, \%res );
my ($DESCR) = @{ $res{DESCRIPTION} };
is_deeply $DESCR->get_attr(), {
          'tag' => [
                   'tag',
                   'pod6',
                   'test'
                 ]
        }, 'check tag attr';

my $res = &WriteAt::make_levels( "CHAPTER", 0, $tree );

is scalar(@$res), 2, 'Get semantic nodes';
is &WriteAt::get_text( $res->[0]->{node} ), 'Test chapter',
  'get text content of node';

my %res2 = ();
my $tree2 = Perl6::Pod::Utl::parse_pod( $t, default_pod => 1 )
  || die "Can't parse ";
$tree2 = &WriteAt::get_book_info_blocks( $tree2, \%res2 );
use_ok "WriteAt::To::Atom";

my $out = '';
open( my $fd, ">", \$out );

my $atom = new WriteAt::To::Atom::
  lang              => 'en',
  default_published => 0,
  set_date          => '2012-12-15T13:00:00Z',
  writer            => new Perl6::Pod::Writer( out => $fd, escape => 'xml' );

is my $utc = $atom->get_time_stamp_from_string('2003-02-15T13:00:00Z'),
  $atom->get_time_stamp_from_string('2003-02-15T12:00:00-01:00'),
  "Get timestams";
is $utc, $atom->get_time_stamp_from_string('2003-02-15 13:00'),
  "2003-02-15 13:00";
is $utc, $atom->get_time_stamp_from_string('2003-02-15 13'), "2003-02-15 13";
is $atom->get_time_stamp_from_string('2003-02-15T00:00:00Z'),
  $atom->get_time_stamp_from_string('2003-02-15'),
  "2003-02-15";

is $atom->unixtime_to_string(
    $atom->get_time_stamp_from_string('2003-01-15T06:00:00-02:00') ),
  '2003-01-15T08:00:00Z', 'unixtime_to_string';

$atom->start_write(%res2);
$atom->write($tree2);
$atom->end_write();
close $fd;
is scalar( @{ [ $out =~ /(<\/entry>)/gs ] } ), 2, 'default_published';
#test DESCRIPTION :tag
ok $out =~ m%<category>pod6</category>%, '=for DESCRITION :tag<pod6>';
ok $out =~ m%<category>intro</category>%, '=for CHAPTER :tag<intro>';

