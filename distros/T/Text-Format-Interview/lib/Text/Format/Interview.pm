package Text::Format::Interview;
use Moose;

=head1 NAME

Text::Format::Interview - Take a text interview transcript and format to html.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

 use Text::Format::Interview;

 my $txt = Text::Format::Interview->new();
 my $html = $txt->process($string);


Converts text of the form:

  # Interview between Fred Flintstone and Barney Rubble, 3rd April, 2000 BC

  Fred: [00:00:00]
  So, Barney, when did you decide to become a Flintstone?

  Barney: [00:00:10]
  Well Fred, I'm not actually a Flintstone, my surname is Rubble and I live in Bedrock.

Into HTML, something like:

  # Interview between Fred Flintstone and Barney Rubble, 3rd April, 2000 BC

  <h2>Fred: [00:00:00]</h2>
  <p>So, Barney, when did you decide to become a Flintstone?</p>

This is intended as a pre-processor, so the header is using markdown here, but could equally be html.

Alternatively if you specify a comma separated list of "interviewers" and
"interviewees" at the top of the file to be processed, you'll get some css
classes as well:

  # Interview between Fred Flintstone and Barney Rubble, 3rd April, 2000 BC
  interviewer: fred,wilma
  interviewee: barney,betty

  Fred: [00:00:00]
  So what's it like to be a flintstone?

  Barney: [00:00:05]
  I'm not a Flintstone, I'm a Rubble.  What do you think Betty?

  Betty:  [00:00:10]
  Yes Fred, you're confused.

  Wilma:  [00:00:15]
  I'm so terribly embarrassed by my husband.

Which ought to render to:

  # Interview between Fred Flintstone and Barney Rubble, 3rd April, 2000 BC

  <p>interviewer: fred, wilma <br>
  interviewee: barney, betty <br></p>

  <h2 class="interviewer">Fred: [00:00:00]</h2>
  <p>So what's it like to be a flintstone?</p>

  <h2 class="interviewee">Barney: [00:00:05]</p>
  <p>I'm not a Flintstone, I'm a Rubble.  What do you think Betty?</p>

This gives us the ability to put pretty colours in the interview transcript
with CSS, something like this:

  h2.interviewer > p { color: red }

(or something far more tortorous if you need to Internet Explorer 6 support ...)

=head1 FUNCTIONS

=head2 process

Takes the text, and spits out the html.

=cut

sub process {
    my ($self, $content) = @_;
    my $rendered = '';
    # first let's make sure our newlines are consistent for the current platform.
    # regex ripped out of the cpan module File::LocalizeNewlines
    $content =~ s/(?:\015{1,2}\012|\015|\012)/\n/sg;
    my @content = split /\n\n/, $content;
    shift @content if $content[0] =~ /^$/;
    my ($interviewer) = $content[0] =~ /interviewer:\s?(.*)$/mi;
    $interviewer ||='';
    my (@interviewers, @interviewees);
    eval {
        @interviewers = split /,\s?/,$interviewer;
    };
    warn "No interviewers specified" if @_;
    my ($interviewee) = $content[0] =~ /interviewee:\s?(.*)$/mi;
    $interviewee ||= '';
    eval {
        @interviewees = split /,\s?/,$interviewee;
    };
    warn "No interviewees specified" if @_;
    my %speaker;
    $speaker{lc($_)} = 'class = "interviewee"' for @interviewees;
    $speaker{lc($_)} = 'class = "interviewer"' for @interviewers;
    
    my @first_para = split /\n/, $content[0];
    $rendered .= $first_para[0] . "\n\n"; # interview title 

    #remainder is metadata/ text description
    $rendered .= "<p>";
    $rendered .=  $_ . "<br>\n" for @first_para[1 .. $#first_para];
    $rendered .= "</p>\n\n";

    foreach my $c (@content[1 .. $#content]) {
        my ($who,$time,$txt) = $c =~ /^(.*?:)\s+?(\[.*?\])\s?(.*)/ms;
        my ($name) = $who =~ /(\w+):/;
        $speaker{lc($name)} = '' unless exists $speaker{lc($name)};
        $rendered .=  "<h2 " .$speaker{lc($name)} . ">$who</h2>\n\n<p><span class='timestamp'>$time</span>$txt</p>\n\n";
    }
    return $rendered;
}

=head1 AUTHOR

Kieren Diment, C<< <zarquon at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-format-interview at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Format-Interview>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Format::Interview


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Format-Interview>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Format-Interview>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Format-Interview>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Format-Interview/>

=item * Version Control Repository (Github)

L<http://github.com/singingfish/Test-Format-Interview/tree/master>

=back

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Kieren Diment, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Text::Format::Interview
