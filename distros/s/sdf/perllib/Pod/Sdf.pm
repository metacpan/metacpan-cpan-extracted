package Pod::Sdf;
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(sdf_escape pod2sdf);
use strict;

sub sdf_escape {
    my($line) = @_;

    # Escape special leading characters/patterns
    $line = "\\$line" if $line =~ /^\s*([-&[:>#!=*^+.\\]|[A-Z_0-9]\w*[:[])/;

    # Escape phrase patterns
    if ($line =~ s/\[\[/E<2[>/g) {
        $line =~ s/\]\]/E<2]>/g;
    }
    if ($line =~ s/\{\{/E<2{>/g) {
        $line =~ s/\}\}/E<2}>/g;
    }
    return $line;
}

sub pod2sdf {
    my($pod, $param) = @_;
    my(@sdf) = ();

    # Get the conversion parameters
    my $main = $param->{'main'};

    # If the first line isn't a pod command, we need to start cutting
    # until we find one
    my $i;
    my $line;
    if (substr($$pod[0], 0, 1) ne '=') {
        @sdf = ('=cut', '');
        for ($i = 0; $i < scalar(@$pod); $i++) {
            $line = $$pod[$i];
            if ($line =~ /^\=/) {
                push(@sdf, '=begin sdf', '');
                last;
            }
            else {
                push(@sdf, $line);
            }
        }
    }

    # Convert the rest
    my $new_para = 1;
    my $sdf_mode = 0;
    my $this_type = '';
    my $last_type = '';
    my $in_title = '';
    my $tab_size = 8;
    for (; $i < scalar(@$pod); $i++) {
        $line = $$pod[$i];

        # Convert tabs to spaces
        1 while $line =~ s/\t+/' ' x (length($&) * $tab_size - length($`) % $tab_size)/e;

        # If we're in sdf mode, just pass lines through into the output
        if ($sdf_mode) {
            if ($line =~ /^=end\s+sdf/) {
                $sdf_mode = 0;
                $line =~ s/^/#/;
            }
            push(@sdf, $line);
            next;
        }

        # Blank lines terminate paragraphs
        if ($line =~ /^\s*$/) {
            $new_para = 1;
            $last_type = $this_type;
            next if $in_title;
        }

        # To convert from POD paragraphs to SDF, the rules are:
        # * tag indented lines as V (verbatim) paragraphs
        # * tag normal paragraphs (with N:), if necessary
        # * assume the first normal paragraph after =head NAME
        #   is the document name, if this is a main document
        elsif ($new_para) {
            if ($line =~ /^\s+/) {
                $this_type = 'V';
                $line = ">$line";
                $sdf[$#sdf] = ">" if $last_type eq 'V';
            }
            elsif (substr($line, 0, 1) eq '=') {
                $this_type = '=';
                $in_title = $main && ($line =~ /^=head1\s+NAME\b/);
                if ($in_title) {
                    next;
                }
                elsif ($line =~ /^=for\s+sdf\s*/) {
                    $line = $';
                }
                elsif ($line =~ /^=begin\s+sdf/) {
                    $line =~ s/^/#/;
                    $sdf_mode = 1;
                }
                else {
                    $line = "=" . sdf_escape(substr($line, 1));
                }
            }
            else {
                $this_type = 'N';
                if ($in_title) {
                    $line =~ s/(['\\])/\\$1/g;
                    push(@sdf,
                        "# Build the title",
                        "!define DOC_NAME '$line'",
                        "!build_title",
                        '');
                    next;
                }
                else {
                    $line = sdf_escape($line);
                }
            }
            $new_para = 0;
        }

        # For lines within a normal paragraph, we need to escape
        # anything with special meaning in SDF
        elsif ($this_type eq 'N') {
            $line = sdf_escape($line);
        }

        # For lines within a verbatim paragraph, make them a
        # new verbatim paragraph.
        elsif ($this_type eq 'V') {
            $line = ">$line";
        }

        # Update the output
        push(@sdf, $line);
    }

    # If the last line is a command, we need to explicitly
    # terminate it so that lines immediately following don't
    # get accidently eaten by the = parsing
    if ($sdf[$#sdf] =~ /^\=/) {
        push(@sdf, '');
    }

    # Return result
    return @sdf;
}

# package return value
1;
