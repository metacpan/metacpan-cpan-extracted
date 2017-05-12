package Text::Label::Prepender;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::Label::Prepender ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '1.0';


# Preloaded methods go here.

#
# the object constructor (simplistic version)
#

my $LABEL        = 0;
my $SEP          = 1;
my $LABEL_CHAR   = 2;
my $LABEL_RE     = 3;

sub new {

    my $pkg = shift;
    my %args = @_;
    my $self  = [];
    my $default = { initial_label => '', separator => '', label_char => ':' };

    $self->[$LABEL]      = $args{initial_label};
    $self->[$SEP]        = $args{separator};
    $self->[$LABEL_CHAR] = $args{label_char};

    my $tmp = $self->[$LABEL_CHAR];
    
    $self->[$LABEL_RE] = qr/(.*)$tmp\s*$/;

    warn $self->[$LABEL_RE];

    bless($self);           # but see below (says perldoc perltoot)
    return $self;
}

sub process {

    my ($self,$line) = @_;

    if ($line =~ /$self->[$LABEL_RE]/) {

	$self->[$LABEL] = $1;

	return undef;

    } else {

	my @O = 
	
	return join $self->[$SEP], ($self->[$LABEL], $line);

    }	
}


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Text::Label::Prepender - dynamically prepend label to input strings

=head1 SYNOPSIS

  use Text::Label::Prepender;

  my $prepender = Text::Label::Prepender->new ( 
    initial_label => '.', # initial label
    separator     => '/',   # output between label and data line
    label_char    => ':',  # the character signifying a line is a label
   ) ;
      

my @input = qw(aaa bbb ccc one one/hump: ddd eee fff two/hump: ggg hhh iii);

for (@input) {
    
    if (my $processed = $prepender->process($_)) {
       print $processed, "\n";
    }

}

 OUTPUT:

 ./aaa
 ./bbb 
 ./ccc 
  one/hump/ddd 
  one/hump/eee 
  one/hump/fff 
  two/hump/ggg 
  two/hump/hhh
  two/hump/iii
 

=head1 DESCRIPTION

This object-oriented package processes input lines, taking a _label_ like:

   food/bar:

and prepends the contents of the label line (sans delimiter) to all
successive lines, until the next label line comes along. This is the sort
of listing that ls -lR would produce.

=head2 EXPORT

None by default.


=head1 AUTHOR

T. M. Brannon, <tbone@cpan.org>

This program is nothing but an OOP-ization of p.224 of "Programming Perl", 
the edition for Perl 4, which I guess means that Randal Schwartz originally
wrote this program.

I thought it would be a nice tool for someone someday and it has been awhile
since I wrote anything object-oriented, so what the hay?!

=head1 SEE ALSO

L<perl>.

=cut
