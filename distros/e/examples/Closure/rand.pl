sub my_srand {
    my ($seed) = @_; 
    # Returns a random number generator function
    # Being predictive, the algorithm requires you to supply a 
    # random initial value.
    my $rand = $seed; 
    return sub  {
             # Compute a new pseudo-random number based on its old value
             # This number is constrained between 0 and 1000.
             $rand = ($rand*21+1)%1000; 
    };
}
$random_iter1 = my_srand  (100);  
$random_iter2 = my_srand (1099);
for ($i = 0; $i < 100; $i++) {
    print &$random_iter1(), " ", &$random_iter2(), "\n";
}
