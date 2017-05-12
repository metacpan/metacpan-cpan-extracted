package Bundle::ToolSet;
use ToolSet 0.99;
use base 'ToolSet';
our $VERSION = 0.1;

BEGIN{
  #Extra-funky user customization here
}

#NO USER SERVICABLE PARTS BELOW, edit POD =head1 CONTENTS
my $parser = Bundle::ToolSet_Pod->new();

#Permit fat commas, otherwise: parse_file( *Bundle::ToolSet_Pod::DATA );
my @LINES;
while(<Bundle::ToolSet_Pod::DATA>){
  s/\s*=>\s*/ /g;
  push @LINES, $_;
}
$parser->parse_lines(@LINES, undef);

ToolSet->export(@{$_}) for @{$parser->{module}};

foreach( @{$parser->{pragma}} ){
  my $toggle = pop @${_};

  if( $toggle eq '-' ){
    ToolSet->use_pragma($_->[0], split/\s+/, $_->[1]); }
  elsif( $toggle eq '+' ){
    ToolSet->no_pragma ($_->[0], split/\s+/, $_->[1]); }
  else{
    warn "Something's rotten in Denmark.";  }
}

1;

package Bundle::ToolSet_Pod;
our $VERSION = 0.01;
use base qw(Pod::Simple);

#<grumble>Parser makes you do some of the heavy lifting</grumble>
our $MODE;

sub _handle_element_start {
  my($undef, $elem) = @_;
  $MODE = 1 if $elem =~ /head1/i;
  $MODE = 0 unless $elem =~ /head1|Para/;
}

sub _handle_text{
  my($self, $text) = @_;

  if( $MODE && $text =~ /^CONTENTS/i ){
    $MODE = 2;
    $self->{module} = [];
    $self->{pragma} = [];
    return;
  }
  return unless $MODE == 2;

  if( $text =~
	/\s*             #padding
	([\w:']+)        #package

	 \s*             #padding
	(\d*(?:\.\d+)*)? #optional version

	(?:              #optional comment

        (?:              #"Comment"
	    \s*          #padding
          -\s+           #delimiter

          (?:            #optional extensions
	    \s*          #padding
	    (.*)         #import
            ([+-])       #no?
	    \s*          #padding
          )?

          (.+)?          #actual comment 
        )?
      )?
      /x ){
#    print "#$text \nP<$1> V<$2> I<$3> N<$4> C<$5>\n";

    #XXX ToolSet doesn't support version specifications...
    if( $1 eq lc($1) ){ #ISA pragma
      push @{$self->{pragma}}, [$1, $3, $4];
    }
    else{
      push @{$self->{module}}, [$1, $3];
    }
  }
}

1;

__DATA__

=pod

=head1 NAME

Bundle::ToolSet - write-once ToolSet+Bundle hybrid

=head1 SYNOPSIS

This module is a template to allow you to use a Bundle, which facilitates
installation of a collection of modules, as a ToolSet... without maintaining
two lists that may fall out of sync. As a side-effect the Bundle necessarily
constitutes minimal documentation, though you're welcome to supply additional
details such as tips & tricks or justification for the imposition of a pragma.

=head1 CONTENTS

warnings - FATAL => all - sadistic coding practice

strict - subs vars - I want symbolic vars damnit!

diagnostics - + ick

Carp 1.02

=head1 DESCRIPTION

To create your own ToolSet+Bundle, simply edit this POD and save the file under
a different name. Specifically, to change what is installed/loaded, edit the
L</CONTENTS> section. You can then copy the Bundle to an arbitrary machine
and use CPAN or CPANPLUS to "install" it i.e; fetch the modules specified.

=head1 OPTIONS

In order to support the additional features of ToolSet, this module
extends the usual syntax of L</CONTENTS> which is usually:

E<nbsp>E<nbsp>I<package><1> I<version>?<2> (- comment)?<3>

It does so by prepending a phrase to the third field, or comment section of
an entry to permit the specification of import options and a togglable
delimiter which indicates the state of pragmas. The resulting entry structure
is:

E<nbsp>E<nbsp>I<package><1> I<version>?<2> (-(I<import> [B<+->])?<4> comment)?<3>

In addition, a restriction is imposed that no POD formatting codes be used in
this section.

I<import>, the 4th field, may currently be blank (\s*) or a list of items
to import. Imagine this list is wrapped in a C<qw()> that sees fat commas
C<=E<gt>> as whitespace.

=over

The delimiter between the import options and comment toogles whether a
pragma is on or off; B<+> is equivalent to C<no> and B<-> to C<use>.
This is of course only meaningful for pragmas i.e; a purely lowercase package.

=head1 SEE ALSO

L<ToolSet>, L<CPAN/Bundles>, L<CPANPLUS>

=head1 AUTHOR

Jerrad Pierce <jpierce@cpan.org>

=head1 LICENSE

=over

=item * Thou shalt not claim ownership of unmodified materials.

=item * Thou shalt not claim whole ownership of modified materials.

=item * Thou shalt grant the indemnity of the provider of materials.

=item * Thou shalt use and dispense freely without other restrictions.

=back

=cut

=head1 HISTORY

The idea was inspired by http://perladvent.org/2008/10/

=cut
