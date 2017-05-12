package Web::AssetLib::MinifierEngine;

use Moose;

with 'Web::AssetLib::Role::Logger';

no Moose;
1;

=pod
 
=encoding UTF-8
 
=head1 NAME

Web::AssetLib::MinifierEngine - a base class for writing your own Minifier Engine

=head1 SYNOPSIS

    package My::Library::MinifierEngine;

    use Method::Signatures;
    use Moose;

    extends 'Web::AssetLib::MinifierEngine';

    method minify( :$contents!, :$type ) {
		# do minification
		return $minified;
    }

=head1 USAGE

If you have a need for a special file minification scenario, you 
can simply extend this class, and it will plug in to the rest of 
the Web::AssetLib pipeline.

The only requirement is that your Output Engine implements the 
L<< minify(...)|/"minify( :$contents!, :$type )" >>
method, which returns the minfied string.

=head1 IMPLEMENTATION

=head2 minify( :$contents!, :$type )

C<< $contents >> and C<< $type >> are both strings.  Minify the content, and
return it as a string.

=head1 SEE ALSO

L<Web::AssetLib::MinifierEngine::Standard>

=head1 AUTHOR
 
Ryan Lang <rlang@cpan.org>

=cut