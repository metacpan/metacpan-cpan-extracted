# This is an inlined version of the private Phase N module File::DirUtils,
# approved for use only in its inline state as Test::Inline::Util.
# It will be released to CPAN at some later time, once complete.
# We ask that until that time you respect our development process and
# do not use this code.
package Test::Inline::Util;
use strict;
use File::Spec::Functions ':ALL';
use vars qw{$VERSION};
BEGIN {
$VERSION = '2.213';
}
sub shorten {
my $class = ref $_[0] ? ref shift : shift;
my $path = (defined $_[0] and length $_[0])
? canonpath( shift )
: return shift;
my @parts = splitdir( $path );
my $i = 0;
while ( defined $parts[++$i] ) {
next unless $i;
next unless $parts[$i] eq updir();
next if $parts[$i - 1] eq updir();
splice @parts, $i - 1, 2;
$i -= 2;
}
catdir( @parts );
}
sub parts {
my $class = ref $_[0] ? ref shift : shift;
my $path = $class->shorten(shift);
$path = '' if $path eq curdir();
scalar splitdir($path);
}
sub inverse {
my $class = ref $_[0] ? ref shift : shift;
my $path = $class->shorten( shift );
if ( ! defined $path or $path eq '' or $path eq curdir() ) {
return $path;
}
return undef if file_name_is_absolute( $path );
my @parts = splitdir( $path );
return undef if $parts[0] eq updir();
catdir( (updir()) x scalar @parts );
}
sub commonise {
my $class = ref $_[0] ? ref shift : shift;
my $first = $class->shorten( shift );
my $second = $class->shorten( shift );
return undef unless defined $first;
return undef unless defined $second;
my @first = splitdir( $first );
my @second = splitdir( $second );
my @base = ();
while ( defined $first[0] and defined $second[0] and $first[0] eq $second[0] ) {
push @base, $first[0];
shift @first;
shift @second;
}
[ catdir(@base), catdir(@first), catdir(@second) ];
}
sub relative {
my $class = ref $_[0] ? ref shift : shift;
my $commonised = $class->commonise( @_ ) or return undef;
my $from = $class->inverse( $commonised->[1] );
return undef unless defined $from;
my $to = $commonised->[2];
if ( $from eq '' and $to eq '' ) {
return '';
}
catdir( grep { length $_ } ($from, $to) );
}
1;
