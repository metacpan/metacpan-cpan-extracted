package WebService::DetectLanguage::Result;
$WebService::DetectLanguage::Result::VERSION = '0.02';
use 5.006;
use Moo;

has language    => ( is => 'ro' );
has is_reliable => ( is => 'ro' );
has confidence  => ( is => 'ro' );

1;

=head1 NAME

WebService::DetectLanguage::Result - a language detection result from detectlanguage.com

=head1 SYNOPSIS

 my ($result) = $api->detect($text);
 printf "language   = %s (%s)\n", $result->language->name, $result->language->code;
 printf "reliable   = %s\n",      $result->is_reliable ? 'Yes' : 'No';
 printf "confidence = %f\n",      $result->confidence;

=head1 DESCRIPTION

This module is a class for data objects returned
by the C<detect()> or C<multi_detect()> methods
of L<WebService::DetectLanguage>.

See the documentation of that module for more details.

=head1 ATTRIBUTES

=head2 language

An instance of L<WebService::DetectLanguage::Language>,
which provides the C<name> and C<code> for the identified language.

=head2 confidence

A confidence level for the result,
which is a bit like a percentage,
but can be higher than 100.

=head2 is_reliable

A boolean, which says whether this is a good guess.

=head1 SEE ALSO

L<WebService::DetectLanguage> the main module for talking
to the language detection API at detectlanguage.com.

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2019 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

