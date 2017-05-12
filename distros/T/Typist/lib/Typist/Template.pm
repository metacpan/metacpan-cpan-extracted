package Typist::Template;
use strict;
use warnings;

use vars qw( $VERSION);
$VERSION = 0.04;

use base qw( Class::ErrorHandler );

use Typist::Builder;
use File::Spec;

sub new { bless {__text => $_[1]}, $_[0] }

sub load {
    my ($class, $file) = @_;
    my @paths =
      ($file, map File::Spec->catfile($_, $file), Typist->instance->tmpl_path);
    my $path;
    for my $p (@paths) {
        $path = $p, last if -e $p && -r _;
    }
    $path = $file unless defined $path;   # let missing file fall to open error.
    local *FH;
    open FH, $path
      or return $class->error(
        Typist->translate("Load of template '[_1]' failed: [_2]", $path, "$!"));
    local $/;
    my $text = <FH>;
    my $tmpl = $class->new($text);
    close FH;
    $tmpl;
}

sub build {
    my $tmpl = shift;
    my ($ctx, $cond) = @_;
    my $tokens = $tmpl->{__tokens};
    my $build  = Typist::Builder->new;
    unless ($tokens) {
        my $text = $tmpl->{__text};
        $tokens = $build->compile($ctx, $text)
          or return
          $tmpl->error(
                    Typist->translate(
                        "Parse error in template '[_1]': [_2]", $tmpl->filename,
                        $build->errstr
                    )
          );
        $tmpl->{__tokens} = $tokens;
    }
    defined(my $res = $build->build($ctx, $tokens, $cond))
      or return
      $tmpl->error(
                   Typist->translate(
                                     "Build error in template '[_1]': [_2]",
                                     $tmpl->filename,
                                     $build->errstr
                   )
      );
    $res;
}

1;

__END__

=head1 NAME

Typist::Template - A simple file-based template object

=head1 METHODS

=over

=item Typist::Template->new

Constructor called by load.

=item Typist::Template->load($filename)

Reads a $filename relative to the value return by the
C<tmpl_path> method for the current instance of Typist and
returns a object

=item $tmpl->build($ctx, \%cond)

Takes two required parameters, an initialized
L<Typist::Template::Context> object and a HASH reference of
conditional flags.

This method will take the template object, compile the
template and cache the tokens for later builds and then call
the C<build> method. Returns a string of the output of the
result.

=back

=end
