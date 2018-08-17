use warnings;
use strict;

package TextFileParser 0.204;

# ABSTRACT: an extensible Perl class to parse any text file by specifying grammar in derived classes.

use Exporter 'import';
our (@EXPORT_OK) = ();
our (@EXPORT)    = (@EXPORT_OK);


use Exception::Class (
    'TextFileParser::Exception',
    'TextFileParser::Exception::ParsingError' => {
        isa         => 'TextFileParser::Exception',
        description => 'For all parsing errors',
        alias       => 'throw_text_parsing_error'
    },
    'TextFileParser::Exception::FileNotFound' => {
        isa         => 'TextFileParser::Exception',
        description => 'File not found',
        alias       => 'throw_file_not_found'
    },
    'TextFileParser::Exception::FileCantOpen' => {
        isa         => 'TextFileParser::Exception',
        description => 'Error opening file',
        alias       => 'throw_cant_open'
    }
);

use Try::Tiny;


sub new {
    my $pkg = shift;
    bless {}, $pkg;
}


sub read {
    my ( $self, $fname ) = @_;
    return                    if not $self->__is_file_known_or_opened($fname);
    $self->filename($fname)   if not exists $self->{__filehandle};
    delete $self->{__records} if exists $self->{__records};
    $self->__read_file_handle;
    $self->__close_file;
}

sub __is_file_known_or_opened {
    my ( $self, $fname ) = @_;
    return 0 if not defined $fname and not exists $self->{__filehandle};
    return 0 if defined $fname and not $fname;
    return 1;
}


sub filename {
    my ( $self, $fname ) = @_;
    $self->__check_and_open_file($fname) if defined $fname;
    return ( exists $self->{__filename} and defined $self->{__filename} )
        ? $self->{__filename}
        : undef;
}

sub __check_and_open_file {
    my ( $self, $fname ) = @_;
    throw_file_not_found error =>
        "No such file $fname or it has no read permissions"
        if not -f $fname or not -r $fname;
    $self->__open_file($fname);
    $self->{__filename} = $fname;
}

sub __open_file {
    my ( $self, $fname ) = @_;
    $self->__close_file if exists $self->{__filehandle};
    open my $fh, "<$fname"
        or throw_cant_open error => "Error while opening file $fname";
    $self->{__filehandle} = $fh;
    $self->{__size}       = ( stat $fname )[7];
}

sub __read_file_handle {
    my $self = shift;
    my $fh   = $self->{__filehandle};
    $self->__init_read_fh;
    while (<$fh>) {
        $self->lines_parsed( $self->lines_parsed + 1 );
        $self->__try_to_parse($_);
    }
}

sub __init_read_fh {
    my $self = shift;
    $self->lines_parsed(0);
    $self->{__bytes_read} = 0;
}


sub lines_parsed {
    my $self = shift;
    return $self->{__current_line} = shift if @_;
    return ( exists $self->{__current_line} ) ? $self->{__current_line} : 0;
}

sub __try_to_parse {
    my ( $self, $line ) = @_;
    try { $self->save_record($line); }
    catch {
        $self->__close_file;
        $_->rethrow;
    };
}


sub save_record {
    my $self = shift;
    return if not @_;
    $self->{__records} = [] if not defined $self->{__records};
    push @{ $self->{__records} }, shift;
}

sub __close_file {
    my $self = shift;
    close $self->{__filehandle};
    delete $self->{__filehandle};
}


sub get_records {
    my $self = shift;
    return () if not exists $self->{__records};
    return @{ $self->{__records} };
}


sub last_record {
    my $self = shift;
    return undef if not exists $self->{__records};
    my (@record) = @{ $self->{__records} };
    return $record[$#record];
}


sub pop_record {
    my $self = shift;
    return undef if not exists $self->{__records};
    pop @{ $self->{__records} };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TextFileParser - an extensible Perl class to parse any text file by specifying grammar in derived classes.

=head1 VERSION

version 0.204

=head1 SYNOPSIS

    use TextFileParser;

    my $parser = TextFileParser->new();
    $parser->read(shift @ARGV);
    print $parser->get_records, "\n";

The above code reads a text file and prints the content to C<STDOUT>.

=head1 DESCRIPTION

This class can be used to parse any arbitrary text file format.

C<TextFileParser> does all operations like C<open> file, C<close> file, line-count, and storage/deletion/retrieval of records. Future versions are expected to include progress-bar support. All these software features are file-format independent and can be re-used in parsing any text file format. Thus derived classes of C<TextFileParser> will be able to take advantage of these features without having to re-write the code again.

The L<Examples|/"EXAMPLES"> section describes how one could use inheritance to build a parser.

=head1 EXAMPLES

The following examples should illustrate the use of inheritance to parse various types of text file formats.

=head2 Basic principle

Derived classes simply need to override one method : C<save_record>. With the help of that any arbitrary file format can be read. C<save_record> should interpret the format of the text and store it in some form by calling C<SUPER::save_record>. The C<main::> program will then use the records and create an appropriate data structure with it.

=head2 Example 1 : A simple CSV Parser

We will write a parser for a simple CSV file that reads each line and stores the records as array references.

    package CSVParser;
    use parent 'TextFileParser';

    sub save_record {
        my ($self, $line) = @_;
        chomp $line;
        my (@fields) = split /,/, $line;
        $self->SUPER::save_record(\@fields);
    }

That's it! Now in C<main::> you can write the following.

    use CSVParser;
    
    my $csvp = CSVParser->new();
    $csvp->read(shift @ARGV);

=head3 Error checking

It is easy to add any error checks using exceptions. One of the easiest ways to do this is to C<use L<Exception::Class>>.

    package CSVParser;
    use Exception::Class (
        'CSVParser::Error', 
        'CSVParser::TooManyFields' => {
            isa => 'CSVParser::Error',
        },
    );
    
    use parent 'TextFileParser';

    sub save_record {
        my ($self, $line) = @_;
        chomp $line;
        my (@fields) = split /,/, $line;
        my $self->{__csv_header} = \@fields if not scalar($self->get_records);
        CSVParser::TooManyFields->throw(error => "Too many fields on " . $self->lines_parsed)
            if scalar(@fields) > scalar(@{$self->{__csv_header}});
        $self->SUPER::save_record(\@fields);
    }

The C<TextFileParser> class will close all filehandles automatically as soon as an exception is thrown from C<save_record>. You can then catch the exception in C<main::> by C<use>ing C<L<Try::Tiny>>.

=head2 Example 2 : Multi-line records

Many text file formats have some way to indicate line-continuation. In BASH and many other interpreted shell languages, a line continuation is indicated with a trailing back-slash (\). In SPICE syntax if a line starts with a C<'+'> character then it is to be treated as a continuation of the previous line.

To illustrate multi-line records we will write a derived class that simply joins the lines in a SPICE file and stores them as records.

    package SPICELineJoiner;
    use parent 'TextFileParser'l

    sub save_record {
        my ($self, $line) = @_;
        $line = ($line =~ /^[+]\s*/) ? $self->__combine_with_last_record($line) : $line;
        $self->SUPER::save_record( $line );
    }

    sub __combine_with_last_record {
        my ($self, $line) = @_;
        $line =~ s/^[+]\s*//;
        my $last_rec = $self->pop_record;
        chomp $last_rec;
        return $last_rec . ' ' . $line;
    }

=head3 Making roles instead

Line-continuation is a classic feature which is common to many different formats. If each syntax grammar generates a new class, one could potentially have to re-write code for line-continuation for each syntax or grammar. Instead it would be good to somehow re-use only the ability to join continued lines, but leave the actual syntax recognition to actual class that understands the syntax.

But if we separate this functionality into a class of its own line we did above with C<SPICELineJoiner>, then it gives an impression that we can now create an object of C<SPICELineJoiner>. But in reality an object of this class would have not have much functionality and is therefore limited.

This is where L<roles|Role::Tiny> are very useful.

=head1 METHODS

=head2 new

Takes no arguments. Returns a blessed reference of the object.

    my $pars = TextFileParser->new();

This C<$pars> variable will be used in examples below.

=head2 read

Takes zero or one string argument containing the name of the file. Throws an exception if filename provided is either non-existent or cannot be read for any reason.

    $pars->read($filename);

    # The above is equivalent to the following
    $pars->filename($anotherfile);
    $pars->read();

Returns once all records have been read or if an exception is thrown for any parsing errors. This function will handle all C<open> and C<close> operations on all files even if any exception is thrown.

B<Recommendation:> Don't override this subroutine. Override C<save_record> instead.

=head2 filename

Takes zero or one string argument containing the name of a file. Returns the name of the file that was last opened if any. Returns undef if no file has been opened.

    print "Last read ", $pars->filename, "\n";

=head2 lines_parsed

Takes no arguments. Returns the number of lines last parsed.

    print $pars->lines_parsed, " lines were parsed\n";

This is also very useful for error message generation.

=head2 save_record

Takes exactly one argument which can be anything: C<SCALAR>, or C<ARRAYREF>, or C<HASHREF> or anything else meaningful. The important thing to remember is that exactly one record is saved per call. So if more than one argument are passed, everything after the first argument is ignored. And if no arguments are passed, then C<undef> is stored as a record.

In an application that uses a text parser, you will most-likely never call this method directly. It is automatically called within C<read> for each line. In this base class C<TextFileParser>, C<save_record> is simply called with a string containing the line text. Derived classes can decide to store records in a different form. See L<Inheritance examples|/"EXAMPLES"> for examples on how C<save_record> could be overridden for other text file formats.

=head2 get_records

Takes no arguments. Returns an array containing all the records that were read by the parser.

    foreach my $record ( $pars->get_records ) {
        $i++;
        print "Record: $i: ", $record, "\n";
    }

=head2 last_record

Takes no arguments and returns the last saved record. Leaves the saved records untouched.

    my $last_rec = $pars->last_record;

=head2 pop_record

Takes no arguments and pops the last saved record.

    my $last_rec = $pars->pop_record;
    $uc_last = uc $last_rec;
    $pars->save_record($uc_last);

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://rt.cpan.org/Public/Dist/Display.html?Name=TextFileParser> or by
email to L<bug-textfileparser at rt.cpan.org|mailto:bug-textfileparser at
rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Balaji Ramasubramanian <balajiram@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Balaji Ramasubramanian.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
