package Wordsmith::Claude::Blog::Interactive;

use 5.020;
use strict;
use warnings;
use utf8;

use Claude::Agent::CLI qw(
    start_spinner stop_spinner
    header divider status
    prompt ask_yn menu select_option choose_from
);
use Wordsmith::Claude::Blog::Builder;
use Wordsmith::Claude::Options;
use Future::AsyncAwait;
use IO::Async::Loop;
use Types::Standard qw(Str CodeRef);

use Marlin
    'topic!'      => Str,
    'style?'      => sub { 'technical' },
    'tone?'       => sub { 'professional' },
    'size?'       => sub { 'medium' },
    'options?'    => sub { Wordsmith::Claude::Options->new() },
    'loop?'       => sub { IO::Async::Loop->new },
    '_spinner==.';

=head1 NAME

Wordsmith::Claude::Blog::Interactive - Interactive blog builder with terminal UI

=head1 SYNOPSIS

    use Wordsmith::Claude::Blog::Interactive;
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new;

    my $interactive = Wordsmith::Claude::Blog::Interactive->new(
        topic => 'Building AI Tools with Perl',
        style => 'technical',
        tone  => 'enthusiastic',
        loop  => $loop,
    );

    my $result = $interactive->run->get;

    if ($result->is_success) {
        print $result->as_markdown;
    }

=head1 DESCRIPTION

Wraps Wordsmith::Claude::Blog::Builder with a colorful terminal UI featuring:

=over 4

=item * Spinners during AI processing

=item * Colored headers and status messages

=item * Interactive menus for outline/title selection

=item * Section-by-section approval workflow

=back

=cut

async sub run {
    my ($self) = @_;

    header("Interactive Blog Builder");
    status('info', "Topic: " . $self->topic);
    print "\n";

    my $builder = Wordsmith::Claude::Blog::Builder->new(
        topic   => $self->topic,
        style   => $self->style,
        tone    => $self->tone,
        size    => $self->size,
        options => $self->options,
        loop    => $self->loop,

        on_research => sub { $self->_handle_research(@_) },
        on_outline  => sub { $self->_handle_outline(@_) },
        on_title    => sub { $self->_handle_title(@_) },
        on_section  => sub { $self->_handle_section(@_) },
        on_complete => sub { $self->_handle_complete(@_) },
    );

    # Start spinner for research phase (pass loop for async animation)
    $self->_spinner(start_spinner("Researching topic...", $self->loop));

    return await $builder->build;
}

sub _handle_research {
    my ($self, $research) = @_;

    # Stop research spinner
    stop_spinner($self->_spinner, "Research complete");
    $self->_spinner(undef);

    header("STEP 1: Research");
    print $research, "\n\n";
    divider();

    my $continue = ask_yn("Continue with this research?", 'y');

    if ($continue) {
        # Start spinner for outline generation
        $self->_spinner(start_spinner("Generating outline options...", $self->loop));
    }

    return $continue;
}

sub _handle_outline {
    my ($self, $outlines) = @_;

    # Stop outline spinner
    stop_spinner($self->_spinner, "Outlines ready");
    $self->_spinner(undef);

    header("STEP 2: Choose an Outline");

    my $chosen;

    # Use Term::Choose for keyboard navigation if multiple outlines
    if (@$outlines > 1) {
        my @display_options;
        for my $i (0 .. $#$outlines) {
            my $preview = $outlines->[$i];
            $preview =~ s/\n/  /g;  # Flatten for display
            $preview = substr($preview, 0, 80) . '...' if length($preview) > 80;
            push @display_options, "Option " . ($i + 1) . ": $preview";
        }
        push @display_options, "[Enter custom outline]";

        my $choice = choose_from(\@display_options,
            inline_prompt => 'Use arrow keys to select, Enter to confirm:',
            layout        => 2,  # Single column
            return_index  => 1,
        );

        if (!defined $choice) {
            $chosen = undef;  # Cancelled
        } elsif ($choice == $#display_options) {
            $chosen = undef;  # Custom selected
        } else {
            $chosen = $outlines->[$choice];
        }
    } else {
        # Single outline - just show and confirm
        print $outlines->[0], "\n\n";
        divider();

        if (ask_yn("Use this outline?", 'y')) {
            $chosen = $outlines->[0];
        } else {
            # User wants custom
            print "Enter your custom outline (end with blank line):\n";
            my @lines;
            while (my $line = <STDIN>) {
                chomp $line;
                last if $line eq '';
                push @lines, $line;
            }
            $chosen = join("\n", @lines) || $outlines->[0];
        }
    }

    # Start spinner for title generation
    $self->_spinner(start_spinner("Generating title options...", $self->loop));

    return $chosen;
}

sub _handle_title {
    my ($self, $titles) = @_;

    # Stop title spinner
    stop_spinner($self->_spinner, "Titles ready");
    $self->_spinner(undef);

    header("STEP 3: Choose a Title");

    # Use Term::Choose for keyboard navigation
    my @options = @$titles;
    push @options, "[Enter custom title]";

    my $choice = choose_from(\@options,
        inline_prompt => 'Select a title:',
        layout        => 2,
        return_index  => 1,
    );

    my $chosen;
    if (!defined $choice) {
        $chosen = $titles->[0];  # Default on cancel
    } elsif ($choice == $#options) {
        # Custom title
        $chosen = prompt("Enter your title:", $titles->[0]);
    } else {
        $chosen = $titles->[$choice];
    }

    # Start spinner for first section
    $self->_spinner(start_spinner("Writing first section...", $self->loop));

    return $chosen;
}

sub _handle_section {
    my ($self, $section_name, $draft) = @_;

    # Stop section spinner
    stop_spinner($self->_spinner, "Section draft ready");
    $self->_spinner(undef);

    header("STEP 4: Section - $section_name");
    print $draft, "\n\n";
    divider();

    my $choice = menu("Action", [
        { key => 'a', label => 'Approve this section' },
        { key => 'r', label => 'Regenerate (different approach)' },
        { key => 'v', label => 'Revise with instructions' },
        { key => 'e', label => 'Edit manually' },
    ]);

    my $result;
    if ($choice eq 'r') {
        $self->_spinner(start_spinner("Regenerating section...", $self->loop));
        $result = { action => 'regenerate' };
    }
    elsif ($choice eq 'v') {
        my $instructions = prompt("Enter revision instructions:");
        $self->_spinner(start_spinner("Revising section...", $self->loop));
        $result = { action => 'revise', instructions => $instructions };
    }
    elsif ($choice eq 'e') {
        $result = $self->_manual_edit($draft);
        # Start spinner for next section after manual edit
        $self->_spinner(start_spinner("Writing next section...", $self->loop));
    }
    else {
        status('success', "Section approved");
        # Start spinner for next section
        $self->_spinner(start_spinner("Writing next section...", $self->loop));
        $result = { action => 'approve' };
    }

    return $result;
}

sub _manual_edit {
    my ($self, $draft) = @_;

    # Try to use external editor
    my $editor = $ENV{EDITOR} || $ENV{VISUAL} || 'vim';
    my $tmpfile = "/tmp/blog-section-$$.txt";

    # Write current draft to temp file
    if (open my $tmp, '>:encoding(UTF-8)', $tmpfile) {
        print $tmp $draft;
        close $tmp;

        # Open editor
        system($editor, $tmpfile);

        # Read back edited content
        if (-f $tmpfile && open my $in, '<:encoding(UTF-8)', $tmpfile) {
            my $edited = do { local $/; <$in> };
            close $in;
            $edited =~ s/^\s+|\s+$//g;
            unlink $tmpfile;

            if ($edited ne $draft) {
                status('success', "Section edited");
                return { action => 'replace', content => $edited };
            }
        }
        unlink $tmpfile if -f $tmpfile;
    }

    status('warning', "Edit cancelled or failed, approving original");
    return { action => 'approve' };
}

sub _handle_complete {
    my ($self, $final_text) = @_;

    # Stop any remaining spinner
    if ($self->_spinner) {
        stop_spinner($self->_spinner);
        $self->_spinner(undef);
    }

    print "\n";
    header("Blog Complete!");
    status('success', "Your blog post is ready");
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
