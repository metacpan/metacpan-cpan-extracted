package TiddlyWeb::EditPage;
use warnings;
use strict;
use Carp qw/croak/;
use File::Temp;
use JSON::XS;
use Encode;

=head1 NAME

TiddlyWeb::EditPage - Edit a wiki page using your favourite EDITOR.

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

Fetch a page, edit it, and then post it.

    use TiddlyWeb::EditPage;

    # The rester is set with the server and workspace
    my $rester = TiddlyWeb::Resting->new(%opts);

    my $s = TiddlyWeb::EditPage->new(rester => $rester);
    $s->edit_page('Snakes on a Plane');

=head1 FUNCTIONS

=head2 new( %opts )

Arguments:

=over 4

=item rester

Users must provide a TiddlyWeb::Resting object setup to use the desired 
workspace and server.

=item pull_includes

If true, C<include> wafls will be inlined into the page as extraclude
blocks.

=back

=cut

sub new {
    my ($class, %opts) = @_;
    my $self = { %opts };
    bless $self, $class;
    return $self;
}

=head2 C<edit_page( %opts )>

This method will fetch the page content, and then run $EDITOR on the file.
After the file has been edited, it will be put back on the wiki server.

Arguments:

=over 4

=item page

The name of the page you wish to edit.

=item callback

If supplied, callback will be called after the page has been edited.  This
function will be passed the edited content, and should return the content to
be put onto the server.

=item summary_callback

If supplied, callback will be called after the page has been edit.  This 
function should return the edit summary text for this edit, if desired.

=item tags 

If supplied, these tags will be applied to the page after it is updated.

=item output

If supplied, the page will be saved to the given file instead of edited. 
The page will not be uploaded to the server.

=item template

If specified, this page will be used as the template for a new page.

=item line

If specified, the editor will be sent to this line to begin editing.

=back

=cut

sub edit_page {
    my $self = shift;
    my %args = @_;
    my $page = $self->{page} = delete $args{page};
    croak "page is mandatory" unless $page;

    my $rester = $self->{rester};
    my $content = $self->_get_page($page);

    my $orig_content = $content->{text};
    my $orig_tags = $content->{tags};
    my $bag = $content->{bag};
    my $orig_fields = $content->{fields};
    while (1) {
        my $new_content = $orig_content;
        $new_content = $self->_edit_content($new_content);

        if ($orig_content eq $new_content) {
            print "$page did not change.\n";
            return;
        }

        $new_content = $args{callback}->($new_content) if $args{callback};

        eval { 
            $rester->put_page($page, {
                    text => $new_content,
                    tags => $orig_tags,
                    fields => $orig_fields,
                    bag => $bag,
                }
            );
        };
        last unless $@;
        if ($@ =~ /412/) { # collision detected!
            print "$@\nA collision was detected.  I will merge the changes and "
                  . "re-open your editor.\nHit enter.\n";
            sleep 2;
            print "Merging...\n";
            $orig_content = $self->_get_page($page);
            my $updated_file = _write_file(undef, $orig_content);
            my $orig_file = _write_file(undef, $content);
            my $our_file  = _write_file(undef, $new_content);

            # merge the content and re-edit
            # XXX: STDERR is not redirected.  Should use IPC::Run.  However,
            # it's nice to be able to create pages w/ quotes and other shell
            # characters in their name.
            system(qw(merge -L yours -L original -L), "new edit", $our_file,
                   $orig_file, $updated_file);

            $content = _read_file($our_file);
        }
        else {
            $self->_handle_error($@, $page, $new_content);
        }
    }

    print "Updated page $page\n";
}

=head2 C<edit_last_page( %opts )>

This method will retrieve a last of all pages tagged with the supplied
tag, and then open the latest one for edit.

Arguments are passed through to edit_page(), accept for:

=over 4

=item tag

The name of the tag you wish to edit.

=back

=cut

sub edit_last_page {
    my $self = shift;
    my %opts = @_;

    my $tag = delete $opts{tag} || croak "tag is mandatory";
    my $rester = $self->{rester};
    $rester->accept('application/json');
    my $pages = decode_json($rester->get_taggedpages($tag));
    unless (@$pages) {
        die "No pages found tagged '$tag'\n";
    }
    my @pages = sort { $b->{modified_time} <=> $a->{modified_time} }
                @$pages;
    my $newest_page = shift @pages;
    print "Editing '$newest_page->{name}'\n";
    $self->edit_page(page => $newest_page->{page_id}, %opts);
}

sub _get_page {
    my $self = shift;
    my $page_name = shift;
    my $rester = $self->{rester};
    $rester->accept('perl_hash');

    my $page = $rester->get_page($page_name);

    return $page;
}

sub _edit_content {
    my $self = shift;
    my $content = shift;

    my $workspace = $self->{rester}->workspace || '';
    (my $page = $self->{page}) =~ s#/#_#g;
    my $filename = File::Temp->new( 
        TEMPLATE => "$workspace.$page.XXXX", 
        SUFFIX => '.wiki' 
    );
    _write_file($filename, $content);
    my $editor   = $ENV{EDITOR} || '/usr/bin/vim';

    if (defined $self->{command} and $editor =~ /vi/) {
        my $c = $self->{command};
        if ($c eq 'o') {
            system $editor, "+normal gg$self->{line}Go", "+startinsert", $filename;
        }
        elsif ($c eq 'i') {
            system $editor, "+normal gg$self->{line}G$self->{col}|", "+startinsert", $filename;
        }
        elsif ($c eq 'a') {
            system $editor, "+normal gg$self->{line}G$self->{col}|l", "+startinsert", $filename;
        }
        elsif ($c eq 'A') {
            system $editor, "+normal gg$self->{line}G", "+startinsert!", $filename;
        }
        else {
            system( $editor, $filename );
        }
    } else {
        system( $editor, $filename );
    }

    return _read_file($filename);
}

sub _handle_error {
    my ($self, $err, $page, $content) = @_;
    my $file = $page . ".sav";
    my $i = 0;
    while (-f $file) {
        $i++;
        $file =~ s/\.sav(?:\.\d+)?$/\.sav\.$i/;
    }
    warn "Failed to write '$page', saving to $file\n";
    _write_file($file, $content);
    die "wrote backup to: $file\n$err\n";
}

sub _write_file {
    my ($filename, $content) = @_;
    $filename ||= File::Temp->new( SUFFIX => '.wiki' );
    open(my $fh, ">$filename") or die "Can't open $filename: $!";
    print $fh $content || '';
    close $fh or die "Can't write $filename: $!";
    return $filename;
}

sub _read_file {
    my $filename = shift;
    open(my $fh, $filename) or die "unable to open $filename $!\n";
    my $new_content;
    {
        local $/;
        $new_content = <$fh>;
    }
    close $fh;
    $new_content = decode("UTF-8", $new_content);
    return $new_content;
}

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-socialtext-editpage at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TiddlyWeb-Resting-Utils>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TiddlyWeb::EditPage

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TiddlyWeb-Resting-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TiddlyWeb-Resting-Utils>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TiddlyWeb-Resting-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/TiddlyWeb-Resting-Utils>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
