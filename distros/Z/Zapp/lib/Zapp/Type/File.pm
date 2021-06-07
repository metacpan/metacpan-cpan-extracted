package Zapp::Type::File;
use Digest;
use Mojo::Base 'Zapp::Type', -signatures;
use Mojo::File;
use Mojo::Asset::File;

has path => sub( $self ) { $self->app->home->child( 'public' ) };
has url => sub( $self ) { '/' };

# "die" for validation errors

sub _digest_dir( $self, $asset ) {
    my $sha = Digest->new( 'SHA-1' );
    if ( $asset->is_file ) {
        ; say "File path: " . $asset->path;
        $sha->addfile( $asset->path );
    }
    else {
        $sha->add( $asset->slurp );
    }
    my $digest = $sha->b64digest =~ tr{+/}{-_}r;
    my @parts = split /(.{2})/, $digest, 3;
    my $dir = $self->path->child( @parts );
    $dir->make_path;
    return $dir;
}

sub _save_upload( $self, $c, $upload ) {
    return undef if !defined $upload->filename || $upload->filename eq '';
    my $dir = $self->_digest_dir( $upload->asset );
    my $file = $dir->child( $upload->filename );
    #; $c->log->debug( "Saving file: $file" );
    $upload->move_to( $file );
    return $file->to_rel( $self->path );
}

# No default allowed for these values (for now)
sub process_config( $self, $c, $form_value ) {
    return {};
}

# Form value -> Type value
sub process_input( $self, $c, $config_value, $form_value ) {
    return $self->_save_upload( $c, $form_value );
}

# Type value -> Task value
sub task_input( $self, $config_value, $input_value ) {
    ; say "Task input (file): $input_value";
    return $self->path->child( $input_value )->to_abs;
}

# Task value -> Type value
sub task_output( $self, $config_value, $task_value ) {
    ; say "Task output (file): $task_value";
    # Task gave us a path. Save the path and return the saved path.
    my $path = Mojo::File->new( $task_value );
    my $output_file = Mojo::Asset::File->new( path => "$path" );
    my $dir = $self->_digest_dir( $output_file );
    my $task_file = $dir->child( $path->basename );
    $output_file->move_to( $task_file );
    return $task_file->to_rel( $self->path );
}

1;

=pod

=head1 NAME

Zapp::Type::File

=head1 VERSION

version 0.004

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
@@ input.html.ep
%= file_field 'value', value => $value, class => 'form-control'

@@ output.html.ep
%# Show a link to download the file
%= link_to $value => $self->url . $value

