#!perl -w
use strict;
use Test;
BEGIN {
    plan(tests => 7);
    #chdir 't'; # cd's to the test directory
}
END {
    #chdir '..'; # cd's back to distribution dir
}

# load the modules
eval { require Text::Annotated::Reader };
ok(length $@ == 0) or warn $@; # 1
eval { require Text::Annotated::Writer };
ok(length $@ == 0) or warn $@; # 2

# annotate a sample file
my $annotator;
eval { 
    $annotator = Text::Annotated::Reader->reader(
        input          => 't/annotate.in',
        #input_postread => 'chomp', 
          # by omitting this, we test for the final line without newline
    ) 
};
ok(length $@ == 0) or warn $@; # 3
my $ra_lines = $annotator->{annotated_lines};

# write a copy of the sample file
{
    my $copier; # in local scope so the output file will be flushed
    eval { 
	$copier = Text::Annotated::Writer->writer(
            input           => [ @$ra_lines ], 
               # makes a copy, because this array will be emptied
	    output          => 't/annotate.copy',
            no_annotation   => 1, 
            #output_prewrite => 'newline',
        )
    };
    ok(length $@ == 0) or warn $@; # 4
}

# compare the copy with the original file
ok((0xffff & system('diff t/annotate.copy t/annotate.in')) == 0);
END { 
    unlink 't/annotate.copy';
}

# write annotated output of the read file
{
    my $printer;
    eval { 
	$printer = Text::Annotated::Writer->writer(
            input           => [ @$ra_lines ],
	    output          => 't/annotate.x',
            output_prewrite => 'newline',
        )
    };
    ok(length $@ == 0) or warn $@; # 6
}

# compare the annotated output with the expected output
ok((0xffff & system('diff t/annotate.x t/annotate.an')) == 0); # 7
END {
    unlink 't/annotate.x';
}

