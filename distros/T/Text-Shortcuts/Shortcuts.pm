
# Made by Steven Rubin steven@ssrubin.com (April 2002)

package Text::Shortcuts;
$VERSION = 0.02;
use strict;
use Text::xSV;
sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = { SF => shift, OF => shift };

	bless($self, $class);
	unless (-s $self->{SF}) {
                my $file = $self->{SF};
		open(SF, ">>$file");
		print SF "shortcut,output\n";
		close(SF);
	}
	return $self;
}
sub set_shortcut {
	my $self = shift;

	my $is_taken=0;
	my $char = shift;
	my $text = shift;
	my $csv = new Text::xSV;
	$csv->open_file($self->{SF});
	$csv->bind_header();
	while ($csv->get_row()) {
		my ($shortcut) = $csv->extract(qw(shortcut));
		if ($char eq $shortcut) {
			warn "Shortcut character already used!";
			$is_taken=1;
			last;
		}
	}
	unless ($is_taken) {
                my $file = $self->{SF};
		open(SF, ">>$file");
		print SF "$char,$text\n";
		close(SF);
	}
}
sub get_shortcuts {
	my $self = shift;

	my $csv = new Text::xSV;
	$csv->open_file($self->{SF});
	$csv->bind_header();
	while ($csv->get_row()) {
		my ($shortcut, $output) = $csv->extract(qw(shortcut output));
	  	print "\[$shortcut\] produces $output\n";
	}
}
sub new_doc {
	my $self = shift;

        my $file = $self->{OF};
	open(OF, ">>$file");
	while (my $line = <STDIN>) {
		last if $line =~ /^(end)$/;
		my %shortcuts;
		my $csv = new Text::xSV;
		$csv->open_file($self->{SF});
		$csv->bind_header();
		while ($csv->get_row()) {
			my ($shortcut, $output) = $csv->extract(qw(shortcut output));
			$shortcuts{$shortcut} = $output;
		}
		$line =~ s/\[(\w)\]+/$shortcuts{$1}/g;
		print OF $line;
	}
	close(OF);
}
sub get_doc {
	my $self = shift;

        my $file = $self->{OF};
	open(OF, "<$file");
	while (<OF>) {
		print;
	}
	close(OF);
}
1;

__END__

=head1 NAME

Text::Shortcuts - A shortcut creation & usage engine

=head1 SYNOPSIS

    use Text::Shortcuts;
    my $sc = Text::Shortcuts->new($shortcut_file, $output_file);

    while(1) {
    	print "Choose option:\n
    		\t1. Set Shortcut\n
    		\t2. Get Shortcuts\n
    		\t3. Start Note\n
    		\t4. Read Note\n";
    	print "Choice: ";
    	chomp(my $choice = <STDIN>);

    	unless ($choice == 1
    		|| $choice == 2
    		|| $choice == 3 ||                 #--Quick Gettaway
    		$choice == 4) {
    		print "Invalid Choice: $choice";
    		redo;
    	}

    	if ($choice == 1) {
    		print "What letter do you want to make this shortcut? ";
    		chomp (my $letter = <STDIN>);
    		print "What do you want \[$letter\] to produce?\n";
    		chomp (my $produce = <STDIN>);
    		$sc->set_shortcut($letter, $produce);
    	} elsif ($choice == 2) {
    		$sc->get_shortcuts;
    	} elsif ($choice == 3) {
    		print "type 'end' to end\n";
    		$sc->new_doc;
    	} elsif ($choice == 4) {
    		$sc->get_doc;
    	}
}

=head1 DESCRIPTION

This module is for use in creating a shortcuts engine. Shortcuts engine?
you ask. Text::Shortcuts lets you define shortcuts (such as [j] or [R])
and then lets you write documents using your shortcuts to stand for
longer pieces of text.

For example, you might set [y] to equal Yoonsdock, Mars. When you create
a new document using C<new_doc>, it will change all occurences of
[y] in that document to Yoonsdock, Mars.

This modules allows for creating and viewing of shortcuts, and creating and
viewing of documents. When a document is typed using C<$sc->new_doc>, the
module sends the I<real> text to the output file, not the shortcut.

=head1 USAGE

=over 4

=item C<new($shortcut_file, $output_file)>

This is the constructor method. It must have the args for the file that
contains the shortcut definitions, and the file that the output will go to.

=item C<set_shortcut($shortcut_letter, $shortcut_expanded)>

This method sets shortcuts, so [$shortcut_letter] will acess $shortcut_expanded.

=item C<get_shortcuts>

This method print out a list of every shortcut, and what it produces.

=item C<new_doc>

This method allows you to type to your output file using shortcuts
you've defined earlier.

=item C<get_doc>

A method for people who are too lazy to C<open> their output file. It
simply opens the output file and prints what's in it.

=back

=head1 BUGS

None known yet. Email me at steven@ssrubin.com if any are found.

=head1 AUTHOR

Steven S. Rubin (steven@ssrubin.com)

=head1 COPYRIGHT

Copyright 2002.  This may be modified and distributed on the same
terms as Perl.



