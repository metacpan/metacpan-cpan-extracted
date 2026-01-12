package Wordsmith::Claude::Blog::Builder;

use 5.020;
use strict;
use warnings;

use Claude::Agent qw(session);
use Claude::Agent::Options;
use Wordsmith::Claude::Options;
use Wordsmith::Claude::Blog;
use Wordsmith::Claude::Blog::Result;
use Future::AsyncAwait;
use IO::Async::Loop;
use Scalar::Util qw(blessed);
use Unicode::Normalize;

use Types::Standard qw(Str CodeRef);

use Marlin
    'topic!'      => Str,
    'style?'      => sub { 'technical' },
    'tone?'       => sub { 'professional' },
    'size?'       => sub { 'medium' },
    'options?'    => sub { Wordsmith::Claude::Options->new() },
    'loop?'       => sub { IO::Async::Loop->new },
    # Callbacks for each step
    'on_research?'    => CodeRef,   # Called with research results
    'on_outline?'     => CodeRef,   # Called with outline options
    'on_title?'       => CodeRef,   # Called with title options
    'on_section?'     => CodeRef,   # Called for each section draft
    'on_complete?'    => CodeRef,
    # Internal session client
    '_client==.';   # Called when done

=head1 NAME

Wordsmith::Claude::Blog::Builder - Interactive step-by-step blog builder

=head1 SYNOPSIS

    use Wordsmith::Claude::Blog::Builder;
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new;

    my $builder = Wordsmith::Claude::Blog::Builder->new(
        topic => 'Claude Code and the Perl SDK',
        style => 'technical',
        tone  => 'enthusiastic',
        loop  => $loop,

        # Research step - see what info was gathered
        on_research => sub {
            my ($research) = @_;
            print "Research:\n$research\n\n";
            print "Continue? [Y/n] ";
            my $answer = <STDIN>;
            return $answer !~ /^n/i;  # Return false to abort
        },

        # Outline step - choose from options
        on_outline => sub {
            my ($outlines) = @_;  # ArrayRef of outline options
            print "Choose an outline:\n";
            for my $i (0 .. $#$outlines) {
                print "\n[$i] ", $outlines->[$i], "\n";
            }
            print "\nChoice (or 'custom'): ";
            my $choice = <STDIN>;
            chomp $choice;
            if ($choice eq 'custom') {
                return undef;
            } elsif ($choice =~ /^\d+$/ && $choice < @$outlines) {
                return $outlines->[$choice];
            } else {
                return $outlines->[0];
            }
        },

        # Title step - choose from options
        on_title => sub {
            my ($titles) = @_;  # ArrayRef of title options
            print "Choose a title:\n";
            for my $i (0 .. $#$titles) {
                print "  [$i] $titles->[$i]\n";
            }
            print "Choice (or type custom): ";
            my $choice = <STDIN>;
            chomp $choice;
            return ($choice =~ /^\d+$/ && $choice < @$titles) ? $titles->[$choice] : ($choice || $titles->[0]);
        },

        # Section step - approve, regenerate, revise, or edit each section
        on_section => sub {
            my ($section_name, $draft) = @_;
            print "\n=== $section_name ===\n$draft\n";
            print "\n[a]pprove, [r]egenerate, re[v]ise, [e]dit? ";
            my $choice = <STDIN>;
            chomp $choice;
            if ($choice eq 'r') {
                return { action => 'regenerate' };
            } elsif ($choice eq 'v') {
                print "Enter revision instructions: ";
                my $instructions = <STDIN>;
                chomp $instructions;
                return { action => 'revise', instructions => $instructions };
            } elsif ($choice eq 'e') {
                print "Enter your edited version (end with '---END---' on its own line):\n";
                my @lines;
                while (my $line = <STDIN>) {
                    last if $line =~ /^---END---$/;
                    push @lines, $line;
                }
                return { action => 'replace', content => join('', @lines) };
            }
            return { action => 'approve' };
        },
    );

    my $result = $builder->build->get;
    print $result->as_markdown;

=head1 DESCRIPTION

Interactive blog builder that walks through the content creation process
step by step, giving you control at each stage:

1. Research - Gather information about the topic
2. Outline - Generate multiple outline options to choose from
3. Title - Generate multiple title options to choose from
4. Sections - Draft each section with approve/regenerate/edit options

=head1 METHODS

=head2 build

    my $result = $builder->build->get;

Runs the full interactive build workflow. Returns a Future that resolves
to a Wordsmith::Claude::Blog::Result.

=cut

async sub build {
    my ($self) = @_;

    my $topic = $self->topic;
    my $loop = $self->loop;

    # Step 1: Research
    my $research = await $self->_do_research($topic);
    if ($self->has_on_research) {
        my $continue = $self->on_research->($research);
        # Explicitly check for defined false to distinguish from undef
        if (defined $continue && !$continue) {
            $self->_cleanup_session();
            return Wordsmith::Claude::Blog::Result->new(
                topic => $topic,
                title => "Blog: $topic",
                text  => '',
                error => 'Aborted at research step',
            );
        }
    }

    # Step 2: Generate outline options
    my $outlines = await $self->_generate_outlines($topic, $research);
    my $chosen_outline;
    if ($self->has_on_outline) {
        $chosen_outline = $self->on_outline->($outlines);
        # If they returned undef, let them provide custom outline
        unless ($chosen_outline) {
            $chosen_outline = $outlines->[0];  # Default to first
        }
    } else {
        $chosen_outline = $outlines->[0];
    }

    # Step 3: Generate title options (in parallel with outline parsing)
    # Parse outline is sync, title generation is async - run together
    my $titles_future = $self->_generate_titles($topic, $chosen_outline);
    my @sections = $self->_parse_outline($chosen_outline);
    my $titles = await $titles_future;

    my $chosen_title;
    if ($self->has_on_title) {
        $chosen_title = $self->on_title->($titles);
        $chosen_title //= $titles->[0];
    } else {
        $chosen_title = $titles->[0];
    }

    # Step 4: Draft each section
    my @final_sections;
    for my $section (@sections) {
        my $draft = await $self->_draft_section($topic, $section, $research, \@final_sections);

        if ($self->has_on_section) {
            my $section_added = 0;
            my $total_iterations = 0;
            my $max_total_iterations = 10;  # Safety limit for all iterations (regenerate/revise combined)

            while ($total_iterations < $max_total_iterations) {
                $total_iterations++;
                my $response = $self->on_section->($section, $draft);

                # Validate callback response
                if (!$response || ref($response) ne 'HASH' || !$response->{action}) {
                    $response = { action => 'approve' };
                } elsif ($response->{action} !~ /^(approve|replace|regenerate|revise)$/) {
                    warn "Unknown action '$response->{action}', defaulting to approve";
                    $response = { action => 'approve' };
                }

                if ($response->{action} eq 'approve') {
                    push @final_sections, { heading => $section, content => $draft };
                    $section_added = 1;
                    last;
                }
                elsif ($response->{action} eq 'replace') {
                    # Sanitize user-provided replacement content
                    my $safe_content = NFC($response->{content} // '');
                    $safe_content =~ s/\"\"\"/''''/g;
                    $safe_content =~ s/\b(ignore|disregard|forget|skip|omit|override|bypass)[^a-z]*(all|any|the|your|previous|above|prior|earlier|system|instructions?)\b/[filtered]/gi;
                    $safe_content =~ s/\b(new|different|actual)[^a-z]*instructions?\b/[filtered]/gi;
                    push @final_sections, { heading => $section, content => $safe_content };
                    $section_added = 1;
                    last;
                }
                elsif ($response->{action} eq 'regenerate') {
                    $draft = await $self->_draft_section($topic, $section, $research, \@final_sections, $draft);
                }
                elsif ($response->{action} eq 'revise') {
                    $draft = await $self->_revise_section($draft, $response->{instructions});
                }
                else {
                    push @final_sections, { heading => $section, content => $draft };
                    $section_added = 1;
                    last;
                }
            }
            # Fallback: add last draft if not added (max iterations exceeded)
            unless ($section_added) {
                push @final_sections, { heading => $section, content => $draft };
            }
        } else {
            push @final_sections, { heading => $section, content => $draft };
        }
    }

    # Assemble final blog post
    my $final_text = $self->_assemble_blog($chosen_title, \@final_sections);

    # Cleanup session
    $self->_cleanup_session();

    # Notify completion
    if ($self->has_on_complete) {
        $self->on_complete->($final_text);
    }

    return Wordsmith::Claude::Blog::Result->new(
        topic    => $topic,
        title    => $chosen_title,
        text     => $final_text,
        style    => $self->style,
        tone     => $self->tone,
        size     => $self->size,
        sections => \@final_sections,
        metadata => {
            # Use consistent word counting - consider extracting to shared utility
            word_count   => scalar(split /\s+/, $final_text),
            reading_time => int((scalar(split /\s+/, $final_text) + 199) / 200),
        },
    );
}

async sub _do_research {
    my ($self, $topic) = @_;

    # Apply Unicode normalization to mitigate homoglyph bypass attempts
    my $safe_topic = NFC($topic);
    $safe_topic =~ s/\"\"\"/''''/g;
    $safe_topic =~ s/\b(ignore|disregard|forget|skip|omit|override|bypass)[^a-z]*(all|any|the|your|previous|above|prior|earlier|system|instructions?)\b/[filtered]/gi;
    $safe_topic =~ s/\b(new|different|actual)[^a-z]*instructions?\b/[filtered]/gi;
    my $prompt = <<"END";
Research the following topic for a blog post: """$safe_topic"""

Gather key information including:
- Main concepts and definitions
- Key features or benefits
- Common use cases
- Technical details if relevant
- Any notable examples or comparisons

Provide a concise research summary (3-5 paragraphs) that will inform the blog post.
Do not write the blog post yet - just gather the information.
END

    # First query in session
    return await $self->_query($prompt, 1);
}

async sub _generate_outlines {
    my ($self, $topic, $research) = @_;

    my $style_desc = Wordsmith::Claude::Blog->style_description($self->style);
    my $length_desc = Wordsmith::Claude::Blog->length_description($self->size);

    # Session already has research context, no need to repeat it
    my $prompt = <<"END";
Based on the research you just provided, generate 3 different outline options for a $style_desc blog post ($length_desc).

Format each outline as:
OUTLINE 1:
- Section name
- Section name
...

OUTLINE 2:
...

OUTLINE 3:
...

Make each outline distinct - vary the structure, angle, or focus.
END

    my $result = await $self->_query($prompt);

    # Parse outlines from result
    my @outlines;
    while ($result =~ /OUTLINE \d+:(.*?)(?=OUTLINE \d+:|$)/gs) {
        my $outline = $1;
        $outline =~ s/^\s+|\s+$//g;
        push @outlines, $outline if $outline;
    }

    # Fallback if parsing failed - try alternative parsing for bullet/numbered lists
    if (@outlines < 2) {
        # Check if result contains structured content (bullet points or numbered lists)
        if ($result =~ /^[-*]\s+/m || $result =~ /^\d+[\.\)]\s+/m) {
            # Extract just the list portion, filtering out preamble text
            my @lines = split /\n/, $result;
            my @list_lines = grep { /^[-*\d]/ } @lines;
            if (@list_lines >= 2) {
                @outlines = (join("\n", @list_lines));
            } else {
                @outlines = ($result);
            }
        } else {
            @outlines = ($result);
        }
    }

    return \@outlines;
}

async sub _generate_titles {
    my ($self, $topic, $outline) = @_;

    my $tone_desc = Wordsmith::Claude::Blog->tone_description($self->tone);

    # Session already has topic and outline context
    my $prompt = <<"END";
Based on the outline we chose, generate 4 compelling title options for this blog post.

The tone should be: $tone_desc

Provide exactly 4 title options. Output ONLY the titles, one per line.
No explanations, no introductions, no numbering - just the titles themselves.
Make them varied - some clever, some direct, some question-based.
END

    my $result = await $self->_query($prompt);

    # Parse titles (one per line)
    my @titles = grep { /\S/ && length($_) > 10 } split /\n/, $result;
    @titles = map {
        my $t = $_;
        $t =~ s/^[\d\.\-\*]+\s*//;      # Remove numbering
        $t =~ s/^\*\*|\*\*$//g;          # Remove bold markers
        $t =~ s/^\*|\*$//g;              # Remove italic markers
        $t =~ s/^["']|["']$//g;          # Remove quotes
        $t =~ s/^\s+|\s+$//g;            # Trim whitespace
        $t;
    } @titles;

    # Filter out explanatory lines (not actual titles)
    @titles = grep {
        !/^(Based on|Here are|I've|Let me|These|The following|Below)/i &&
        !/^(Title|Option)\s*\d/i &&
        length($_) < 120  # Titles shouldn't be too long
    } @titles;

    # Fallback
    if (@titles < 2) {
        @titles = ("Blog: $topic");
    }

    return \@titles;
}

async sub _draft_section {
    my ($self, $topic, $section_name, $research, $previous_sections, $previous_draft) = @_;

    my $style_inst = Wordsmith::Claude::Blog->get_style($self->style);
    my $tone_inst = Wordsmith::Claude::Blog->get_tone($self->tone);

    # Apply Unicode normalization to section name only (topic/research in session context)
    my $safe_section = NFC($section_name);
    $safe_section =~ s/\"\"\"/''''/g;
    $safe_section =~ s/\b(ignore|disregard|forget|skip|omit|override|bypass)[^a-z]*(all|any|the|your|previous|above|prior|earlier|system|instructions?)\b/[filtered]/gi;
    $safe_section =~ s/\b(new|different|actual)[^a-z]*instructions?\b/[filtered]/gi;

    my $regen_note = "";
    if ($previous_draft) {
        my $safe_prev_draft = $previous_draft;
        $safe_prev_draft =~ s/\"\"\"/''''/g;
        $regen_note = "\nThe previous draft wasn't satisfactory. Please regenerate with a different approach.\n";
    }

    # Session has full context (research, outline, title, previous sections)
    my $prompt = <<"END";
Write the "$safe_section" section for the blog post.
$regen_note
Style: $style_inst
Tone: $tone_inst

Write ONLY the content for the "$safe_section" section.
Do not include the section heading - just the content.
Use markdown formatting where appropriate (code blocks, bold, lists).
END

    return await $self->_query($prompt);
}

async sub _revise_section {
    my ($self, $draft, $instructions) = @_;

    # Apply Unicode normalization to mitigate homoglyph bypass attempts
    my $safe_inst = NFC($instructions);
    $safe_inst =~ s/\"\"\"/''''/g;
    $safe_inst =~ s/\b(ignore|disregard|forget|skip|omit|override|bypass)[^a-z]*(all|any|the|your|previous|above|prior|earlier|system|instructions?)\b/[filtered]/gi;
    $safe_inst =~ s/\b(new|different|actual)[^a-z]*instructions?\b/[filtered]/gi;

    # Session has the draft context from the previous message
    my $prompt = <<"END";
Revise the section you just wrote according to these instructions: $safe_inst

IMPORTANT: You must actually apply the changes requested. Do NOT return the original text unchanged.
For example:
- If asked to "replace we with I", change every "we" to "I", "our" to "my", "us" to "me"
- If asked to "make it shorter", significantly reduce the word count
- If asked to "add more examples", include additional concrete examples

Output ONLY the revised text with the changes applied. No explanations or commentary.
END

    return await $self->_query($prompt);
}

sub _parse_outline {
    my ($self, $outline) = @_;

    my @sections;
    for my $line (split /\n/, $outline) {
        if ($line =~ /^[\-\*\d\.]+\s*(.+)/) {
            my $section = $1;
            $section =~ s/^\s+|\s+$//g;
            push @sections, $section if $section;
        }
    }

    # Fallback to basic structure
    if (@sections < 2) {
        @sections = ('Introduction', 'Main Content', 'Conclusion');
    }

    return @sections;
}

sub _assemble_blog {
    my ($self, $title, $sections) = @_;

    my $blog = "# $title\n\n";

    for my $section (@$sections) {
        $blog .= "## $section->{heading}\n\n";
        $blog .= "$section->{content}\n\n";
    }

    return $blog;
}

sub _init_session {
    my ($self) = @_;

    return if $self->_client;

    my $claude_opts = Claude::Agent::Options->new(
        permission_mode => $self->options->permission_mode // 'bypassPermissions',
        $self->options->has_model ? (model => $self->options->model) : (),
    );

    $self->_client(session(
        options => $claude_opts,
        loop    => $self->loop,
    ));
}

sub _cleanup_session {
    my ($self) = @_;
    if ($self->_client) {
        $self->_client->disconnect;
        $self->_client(undef);
    }
}

async sub _query {
    my ($self, $prompt, $is_first) = @_;

    $self->_init_session();

    my $client = $self->_client;

    # First query uses connect, subsequent use send
    if ($is_first || !$client->is_connected) {
        $client->connect($prompt);
    } else {
        $client->send($prompt);
    }

    my $result_text;
    while (my $msg = await $client->receive_async) {
        if (blessed($msg) && $msg->isa('Claude::Agent::Message::Result')) {
            $result_text = $msg->result;
            last;
        }
    }

    return $result_text // '';
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
