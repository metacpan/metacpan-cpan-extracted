package WWW::Google::Docs::Upload;
use Moose;

use WWW::Mechanize;

our $VERSION = '0.02';

has email  => ( is => 'rw', required => 1 );
has passwd => ( is => 'rw', required => 1 );

has mech => (
    is  => 'rw',
    isa => 'WWW::Mechanize',
    default => sub {
        my $mech = WWW::Mechanize->new( stack_depth => 1 );
        $mech->env_proxy;
        $mech->agent_alias('Windows IE 6');
        $mech->timeout(10);
        $mech;
    },
);

sub upload {
    my ($self, $file, $option) = @_;

    confess q{required filename to upload} unless $file;
    confess qq{no such file "$file"} unless -e $file && -f _;

    my $mech = $self->mech;
    $mech->get('http://docs.google.com/DocAction?action=updoc&hl=en');

    if ($mech->res->base =~ /ServiceLogin/) {
        $mech->submit_form(
            fields => {
                Email  => $self->email,
                Passwd => $self->passwd,
            },
        );
        $mech->follow_link( tag => 'meta' );
        confess 'login failed' unless $mech->res->base->host eq 'docs.google.com';
    }

    $mech->submit_form(
        fields => {
            uploadedFile => $file,
            $option->{name} ? (DocName => $option->{name}) : (),
        },
    );

    $mech->res;
}

=head1 NAME

WWW::Google::Docs::Upload - Upload documents to Google Docs

=head1 SYNOPSIS

    use WWW::Google::Docs::Upload;
    
    my $docs = WWW::Google::Docs::Upload->new(
        email  => 'your email',
        passwd => 'your password'
    );
    $docs->upload('/path/to/yourfile.doc');

=head1 DESCRIPTION

This module helps you to upload your local document files to Google Docs.

=head1 METHODS

=head2 upload($filename, \%option)

Upload document file (named $filename) to Google Docs.

\%option is hashref and allowed key is:

=over 4

=item name

Filename what you want to call (if different than the filename)

=back

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
