#!/usr/bin/perl
# Embedded images (the "image" subcommand), compared with Tk::Text, and
# inside blocks.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 28;
$mw->geometry('+10+10');

my @bgerrors;
{
  no warnings 'redefine';
  *Tk::Error = sub { my ($w, $err, @loc) = @_; push @bgerrors, $err };
}

my $photo = $mw->Photo(-width => 12, -height => 8);
my $photo2 = $mw->Photo(-width => 20, -height => 30);

sub make {
  my ($class) = @_;
  my $w = $mw->$class(-width => 30, -height => 8, -wrap => 'none')->pack;
  $w->insert('end', "abc def\nline two\nthird\n");
  my @names;
  push @names, $w->imageCreate('1.3', -image => $photo, -align => 'top', -padx => 2, -pady => 1);
  push @names, $w->imageCreate('2.2', -image => $photo2, -name => 'pic');
  push @names, $w->imageCreate('2.5', -image => $photo, -align => 'baseline');
  push @names, $w->imageCreate('3.0', -name => 'empty');
  $mw->update;
  return ($w, @names);
}
my ($ref, @rnames) = make('Text');
my ($w, @enames) = make('eText');
is("@enames", "@rnames", "image create returns the same names as Tk::Text (@enames)");

my (%bad, $queries);
sub cmp_both {
  my ($what, $method, @args) = @_;
  my @r = eval { $ref->$method(@args) }; my $rerr = $@;
  my @e = eval { $w->$method(@args) }; my $eerr = $@;
  $queries++;
  no warnings 'uninitialized';
  if ("@r" ne "@e" || !!$rerr != !!$eerr) {
    $bad{$what}++;
    diag("$what: $method(@args): Text says [@r] ($rerr), eText says [@e] ($eerr)")
      if $bad{$what} <= 3;
  }
}
cmp_both('names', 'imageNames');
cmp_both('names', 'index', $_) for @enames;
is($bad{names} || 0, 0, 'image names and their positions like Tk::Text');
for my $n (@enames) {
  cmp_both('cget', 'imageCget', $n, $_) for qw(-align -padx -pady -image -name);
  cmp_both('cget', 'imageConfigure', $n, '-align');
  my @c = $w->imageConfigure($n);
  is(scalar(@c), 5, "image configure of $n lists 5 options");
}
is($bad{cget} || 0, 0, 'image cget like Tk::Text');
for my $l (1 .. 3) {
  cmp_both('geometry', 'dlineinfo', "$l.0");
  (my $n = $ref->index("$l.0 lineend")) =~ s/.*\.//;
  for my $c (0 .. $n) {
    cmp_both('geometry', 'bbox', "$l.$c");
    cmp_both('text', 'get', "$l.$c");
    cmp_both('text', 'index', "$l.$c +1c");
    cmp_both('text', 'index', "$l.$c -1c");
  }
}
is($bad{geometry} || 0, 0, 'bbox and dlineinfo with images like Tk::Text');
is($bad{text} || 0, 0, 'get and index arithmetic around images like Tk::Text');
# (Tk::Text's dump reports the -image object or nothing as the value of
# an image; the documented value, and ours, is the image's name in the
# widget.  Compare everything else.)
{
  my @r = $ref->dump('-all', '1.0', 'end');
  my @e = $w->dump('-all', '1.0', 'end');
  for my $d (\@r, \@e) {
    for (my $i = 0; $i < @$d; $i += 3) { $d->[$i + 1] = 'IMG' if $d->[$i] eq 'image' }
  }
  is_deeply(\@e, \@r, 'dump with images like Tk::Text');
  my @names = $w->dump('-image', '1.0', 'end');
  is(join(' ', @names[map { 3 * $_ + 1 } 0 .. 3]), "@enames", 'dump -image reports the image names');
}
cmp_both('dump', 'get', '1.0', 'end');
is($bad{dump} || 0, 0, 'get with images like Tk::Text');
cmp_both('errors', 'imageCreate', '1.0');
cmp_both('errors', 'imageCget', '1.0', '-align');
cmp_both('errors', 'imageConfigure', '1.0');
cmp_both('errors', 'index', 'nosuchimage');
cmp_both('errors', 'imageCreate', '1.0', -image => 'nosuchimage');
is($bad{errors} || 0, 0, 'error cases like Tk::Text');

# Reconfiguring, changing the image, deleting.
$_->imageConfigure('pic', -align => 'bottom', -padx => 3) for $ref, $w;
$_->imageConfigure($enames[0], -image => $photo2) for $ref, $w;
$mw->update;
%bad = ();
cmp_both('reconf', 'imageCget', 'pic', '-align');
cmp_both('reconf', 'bbox', 'pic');
cmp_both('reconf', 'bbox', $enames[0]);
cmp_both('reconf', 'dlineinfo', '1.0');
is($bad{reconf} || 0, 0, 'image configure like Tk::Text');
$photo->configure(-width => 40, -height => 5);
$mw->update;
cmp_both('change', 'bbox', $enames[2]);
cmp_both('change', 'dlineinfo', '2.0');
is($bad{change} || 0, 0, 'a changed image is laid out again like Tk::Text');
$_->delete('2.0', '2.end') for $ref, $w;
$mw->update;
cmp_both('delete', 'imageNames');
is($bad{delete} || 0, 0, 'deleting text removes its images like Tk::Text');
cmp_ok($queries, '>', 100, "that was $queries comparisons");
$ref->destroy;
$w->destroy;

# Images and blocks.
$w = $mw->eText(-width => 30, -height => 8)->pack;
$w->blockConfigure('Std');
$w->insert('end', "ab cdef gh\n");
my $name = $w->imageCreate('1.5', -image => $photo2);
$w->blockInsert('Std', '1.3', '1.8');
$mw->update;
is($w->get('1.0', 'end'), "ab {cdef} gh\n\n", 'image inside a block is invisible to get');
is($w->index($name), '1.6', 'index by image name is the position inside the block');
like($w->imageCget('1.6', '-image'), qr/^image\d+$/, 'image cget inside the block');
my @b = $w->bbox('1.6');
is("$b[2] $b[3]", '20 30', 'bbox of the image inside the block is the image size');
my @list = $w->blockList('1.0', 'end');
my ($block) = grep { ref $_ eq 'Tk::Text::Block' } @list;
my ($img) = grep { ref $_ eq 'Tk::Text::EmbImage' } @$block;
ok($img, 'block list reports the image inside the block');
is($img->[0], $name, 'with its name');
is_deeply([@$img[1 .. $#$img]], ['-image', $w->imageCget($name, '-image'), '-align', 'center', '-padx', 0, '-pady', 0],
	  'and its options as option/value pairs (undo re-creates it from them)');
my @dump = $w->dump('-image', '1.0', 'end');
is("@dump", "image $name 1.6", 'dump -image finds the image inside the block');
$w->imageConfigure($name, -align => 'top', -pady => 4);
$mw->update;
is($w->imageCget($name, '-pady'), 4, 'image configure inside the block');
$w->delete('1.0', 'end');
$mw->update;
is_deeply([$w->imageNames], [], 'deleting the block deletes its image');
is_deeply(\@bgerrors, [], 'no background errors') or diag(@bgerrors);
$w->destroy;
$mw->destroy;
