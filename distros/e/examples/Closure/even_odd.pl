sub even_odd_print_gen {
    # $last is shared between the two procedures
    my ($rs1, $rs2);
    my ($last) = shift;  # Shared by the two closures below
    $rs1 = sub { # Even number printer
        if ($last % 2) {$last ++;}
        else { $last += 2};
        print "$last \n";
    };
    $rs2 = sub { # Even number printer
        if ($last % 2) {$last += 2 }
        else { $last++};
        print "$last \n";
    };
    return ($rs1, $rs2);   # Returning two anon sub references
}
($even_iter,$odd_iter) = even_odd_print_gen(10);
&$even_iter ();  # prints 12
&$odd_iter  ();  # prints 13
&$odd_iter  ();  # prints 13
&$even_iter ();  # prints 14
&$odd_iter  ();  # prints 15

