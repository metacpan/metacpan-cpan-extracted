use strict;
use warnings;
use Text::Bayon;
use Test::More tests => 3;

{
    my $bayon = Text::Bayon->new;
	my $input;
    my $args_outfiles;
    eval { $bayon->_io_file_names($input,$args_outfiles); };
    like( $@, qr/^wrong input/ );
}

{
    my $bayon = Text::Bayon->new;
	my $input = 'hoge';
    my $args_outfiles;
    eval { $bayon->_io_file_names($input,$args_outfiles); };
    like( $@, qr/^can't find input file hoge/ );
}

{
    my $bayon = Text::Bayon->new;
	my $input = ['aaa', 'bbb'];
    my $args_outfiles;
    eval { $bayon->_io_file_names($input,$args_outfiles); };
    like( $@, qr/^wrong input/ );
}
