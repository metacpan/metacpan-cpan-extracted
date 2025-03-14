package WordList::PersonName::PopularBabyNames::US::SSA::1980::MaleTop1000;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-01'; # DATE
our $DIST = 'WordLists-PersonName-PopularBabyNames-US-SSA'; # DIST
our $VERSION = '0.001'; # VERSION

use WordList;
our @ISA = qw(WordList);

our $SORT = 'rank';

our %STATS = ("longest_word_len",11,"num_words_contain_nonword_chars",0,"num_words_contains_unicode",0,"num_words_contain_whitespace",0,"num_words",1000,"shortest_word_len",2,"num_words_contain_unicode",0,"num_words_contains_nonword_chars",0,"num_words_contains_whitespace",0,"avg_word_len",5.781); # STATS

1;
# ABSTRACT: Top 1000 most popular names for male babies born in the USA in 1980 (from Social Security Administration)

=pod

=encoding UTF-8

=head1 NAME

WordList::PersonName::PopularBabyNames::US::SSA::1980::MaleTop1000 - Top 1000 most popular names for male babies born in the USA in 1980 (from Social Security Administration)

=head1 VERSION

This document describes version 0.001 of WordList::PersonName::PopularBabyNames::US::SSA::1980::MaleTop1000 (from Perl distribution WordLists-PersonName-PopularBabyNames-US-SSA), released on 2020-05-01.

=head1 SYNOPSIS

 use WordList::PersonName::PopularBabyNames::US::SSA::1980::MaleTop1000;

 my $wl = WordList::PersonName::PopularBabyNames::US::SSA::1980::MaleTop1000->new;

 # Pick a (or several) random word(s) from the list
 my $word = $wl->pick;
 my @words = $wl->pick(3);

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Get all the words
 my @all_words = $wl->all_words;

=head1 DESCRIPTION

Taken from L<https://www.ssa.gov/oact/babynames/>

Sorted by rank (most popular first).

=head1 STATISTICS

 +----------------------------------+-------+
 | key                              | value |
 +----------------------------------+-------+
 | avg_word_len                     | 5.781 |
 | longest_word_len                 | 11    |
 | num_words                        | 1000  |
 | num_words_contain_nonword_chars  | 0     |
 | num_words_contain_unicode        | 0     |
 | num_words_contain_whitespace     | 0     |
 | num_words_contains_nonword_chars | 0     |
 | num_words_contains_unicode       | 0     |
 | num_words_contains_whitespace    | 0     |
 | shortest_word_len                | 2     |
 +----------------------------------+-------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordLists-PersonName-PopularBabyNames-US-SSA>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordLists-PersonName-PopularBabyNames-US-SSA>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordLists-PersonName-PopularBabyNames-US-SSA>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
Michael
Christopher
Jason
David
James
Matthew
Joshua
John
Robert
Joseph
Daniel
Brian
Justin
William
Ryan
Eric
Nicholas
Jeremy
Andrew
Timothy
Jonathan
Adam
Kevin
Anthony
Thomas
Richard
Jeffrey
Steven
Charles
Brandon
Mark
Benjamin
Scott
Aaron
Paul
Nathan
Travis
Patrick
Chad
Stephen
Kenneth
Gregory
Jacob
Dustin
Jesse
Jose
Shawn
Sean
Bryan
Derek
Bradley
Edward
Donald
Samuel
Peter
Keith
Kyle
Ronald
Juan
George
Jared
Douglas
Gary
Erik
Phillip
Raymond
Joel
Corey
Shane
Larry
Marcus
Zachary
Craig
Derrick
Todd
Jeremiah
Antonio
Carlos
Shaun
Dennis
Frank
Philip
Cory
Brent
Gabriel
Nathaniel
Randy
Luis
Curtis
Jeffery
Alexander
Russell
Casey
Jerry
Wesley
Brett
Luke
Lucas
Seth
Billy
Terry
Carl
Mario
Ian
Jamie
Troy
Victor
Tony
Bobby
Vincent
Jesus
Alan
Johnny
Tyler
Adrian
Brad
Ricardo
Christian
Marc
Danny
Rodney
Ricky
Martin
Allen
Lee
Jimmy
Jon
Miguel
Lawrence
Willie
Clinton
Micheal
Andre
Roger
Henry
Randall
Walter
Kristopher
Jorge
Joe
Jay
Albert
Cody
Manuel
Roberto
Wayne
Arthur
Gerald
Jermaine
Isaac
Louis
Lance
Roy
Francisco
Trevor
Alex
Bruce
Jack
Evan
Jordan
Frederick
Maurice
Darren
Mitchell
Ruben
Reginald
Jaime
Darrell
Hector
Omar
Jonathon
Angel
Ronnie
Johnathan
Barry
Oscar
Eddie
Jerome
Terrance
Ernest
Neil
Damien
Mathew
Shannon
Calvin
Javier
Alejandro
Edwin
Garrett
Eugene
Raul
Kurt
Leonard
Clayton
Clint
Fernando
Tommy
Dale
Geoffrey
Marvin
Steve
Clifford
Beau
Colin
Theodore
Tyrone
Harold
Rafael
Kelly
Terrence
Austin
Joey
Jarrod
Cameron
Glenn
Ramon
Grant
Melvin
Brendan
Jessie
Stanley
Pedro
Armando
Dwayne
Karl
Levi
Eduardo
Micah
Ross
Ralph
Byron
Dominic
Marco
Chris
Caleb
Devin
Blake
Andy
Sergio
Noah
Erick
Howard
Francis
Tyson
Ivan
Cedric
Heath
Leon
Alberto
Earl
Damon
Edgar
Franklin
Alvin
Alfred
Clarence
Courtney
Harry
Darryl
Nicolas
Ray
Gilbert
Marshall
Cesar
Dylan
Alfredo
Dean
Warren
Clifton
Enrique
Julio
Kirk
Abraham
Bernard
Arturo
Preston
Daryl
Roderick
Elijah
Julian
Antoine
Ashley
Orlando
Andres
Wade
Norman
Drew
Spencer
Duane
Morgan
Vernon
Ethan
Leroy
Lonnie
Demetrius
Brock
Nelson
Nickolas
Dallas
Rene
Israel
Bryce
Salvador
Toby
Ernesto
Lewis
Gerardo
Bradford
Marcos
Fredrick
Taylor
Bryant
Kelvin
Lamar
Jayson
Jody
Terrell
Angelo
Don
Glen
Rocky
Charlie
Neal
Damian
Fred
Lorenzo
Jamal
Trent
Rickey
Kenny
Herbert
Jake
Rodolfo
Stuart
Lloyd
Greg
Donnie
Derick
Jeff
Brady
Allan
Felix
Marlon
Eli
Gordon
Quincy
Desmond
Logan
Ben
Dwight
Darnell
Julius
Dana
Leslie
Rusty
Kent
Darius
Rudy
Dusty
Pablo
Freddie
Jimmie
Lamont
Max
Roland
Abel
Leo
Kendrick
Quentin
Lester
Josh
Kareem
Rolando
Simon
Tracy
Jamar
Noel
Jackie
Darin
Gene
Alfonso
Graham
Jamaal
Floyd
Johnnie
Perry
Scotty
Robin
Rick
Carlton
Dewayne
Cornelius
Devon
Kerry
Chadwick
Guy
Gilberto
Bret
Emmanuel
Felipe
Cecil
Mike
Zachariah
Antwan
Rogelio
Milton
Branden
Frankie
Terence
Guillermo
Jarrett
Jonah
Oliver
Ty
Loren
Kurtis
Gustavo
Waylon
Clyde
Dante
Ismael
Elias
Johnathon
Landon
Jarod
Kendall
Salvatore
Herman
Sam
Ted
Alonzo
Saul
Collin
Fabian
Jerrod
Tomas
Trenton
Rory
Isaiah
Owen
Sidney
Alexis
Gavin
Moses
Chester
Clay
Nathanael
Leonardo
Donovan
Robbie
Sammy
Emanuel
Gerard
Esteban
Jonas
Bryon
Hugo
Jarvis
Mason
Everett
Dan
Elliott
Forrest
Nolan
Xavier
Josue
Dane
Dominick
Sheldon
Jarred
Kory
Nick
Rashad
Wendell
Ramiro
Marquis
Myron
Tanner
Garry
Randolph
Guadalupe
Marty
Sherman
Jim
Lionel
Stephan
Gregg
Rex
Reynaldo
Miles
Benny
Jerod
Otis
Ron
Reuben
Jess
Brooks
Noe
Anton
Moises
Harvey
Jackson
Wilson
Darrin
Efrain
Ira
Harley
Pierre
Deon
Arnold
Jamel
Aron
Cole
Elliot
Dion
Humberto
Donnell
Erich
Will
Edmund
Joaquin
Claude
Deandre
Blaine
Donte
Lyle
Quinton
Thaddeus
Erin
Dexter
Amos
Clark
Colby
Malcolm
Roman
Donny
Josiah
Bill
Alton
Earnest
Santiago
Teddy
Ali
Damion
Joesph
Stewart
Tobias
Hunter
Reggie
Sterling
Wallace
Kasey
Robby
Ariel
Blair
Jeromy
Tom
Adan
Vicente
Ahmad
Ignacio
Matt
Stefan
Timmy
Randal
Stacy
Bo
Wyatt
Jeramy
Avery
Elvis
Scottie
Hugh
Willis
Curt
Demarcus
Santos
Sonny
Pete
Kristofer
Zachery
Jovan
Quinn
Jed
Korey
Rico
Freddy
Rodrick
Bradly
Jean
Kris
Marques
Mickey
Solomon
Reid
Bart
Conrad
Hans
Jennifer
Rigoberto
Leland
Tristan
Bennie
Brendon
Chance
Issac
Roosevelt
Jedediah
Luther
Wilfredo
Giovanni
Jeremie
Darrel
Emilio
Marion
Sylvester
Virgil
Weston
Darrick
Conor
Reed
Cedrick
Jeffry
Morris
Rudolph
Cary
Tommie
Brice
Diego
Jerald
Zane
Jerad
Nathanial
Brenton
Maxwell
Barrett
Heriberto
Derik
Jedidiah
Jamey
Arron
Daren
Jamison
Alvaro
Jeramie
Keenan
Wilbert
Benito
Rodrigo
Archie
Brain
Jeremey
Royce
Winston
Aubrey
Chase
Marcel
Jefferson
Ervin
Brant
Ellis
Lynn
Carlo
Leif
Malik
Carey
Demond
Mauricio
Dillon
Ezra
Vaughn
Adolfo
Aric
Sebastian
Tim
Dorian
Nigel
Riley
Willard
Jasper
Elmer
Tyree
Cyrus
Dave
Demario
Laurence
Chauncey
Deshawn
Jasen
Edmond
Jamil
Raphael
Tory
Galen
Stacey
Agustin
Carson
Raheem
Leonel
Monte
Nicholaus
Dereck
Hubert
Jered
Van
Rhett
Shayne
Vance
Abram
Josef
Rocco
Antwon
Rufus
Dirk
Kristian
Mack
Antione
Ari
Braden
Brannon
Domingo
Lane
Louie
Lukas
Seneca
Andrea
Gino
Jacques
Bernardo
Cliff
Cortney
Garret
Rickie
Aldo
Grady
Brennan
Ken
Kristoffer
Octavio
Whitney
Cornell
Davin
Buddy
Cleveland
Davis
Denny
Melissa
Scot
Chaz
Delbert
Markus
Bryson
Gregorio
Harrison
Trey
Asa
Dewey
Judson
Shelby
Parker
Tavares
Zackary
Elton
Deangelo
Federico
Jamin
Prince
Rodger
Amir
Dario
Hassan
Stevie
Daron
Francesco
Alec
Jereme
Tyrell
Nikolas
Osvaldo
Yoel
Jessica
Mikel
Edwardo
Raymundo
Tyron
Dominique
Ernie
Percy
Denis
Gonzalo
Broderick
Deric
Horace
Juston
Titus
Johnpaul
Kenton
Shelton
Ulysses
Bennett
Dedrick
Junior
Russel
Billie
Kaleb
Marlin
Alphonso
Bert
Darwin
Ezekiel
Kip
Shad
Theron
Jaron
Monty
Quintin
Antony
Silas
Delvin
Jerimiah
Randell
Errol
Jan
Jermey
Liam
Shea
Torrey
Efren
Elvin
Judd
Elisha
Kim
Myles
Vito
Erwin
Jade
Jameel
Kelley
Lavar
Mohammad
Coy
Davon
Dejuan
Fidel
Keegan
Sedrick
Al
Cortez
Paris
Ramsey
August
Cristian
Garth
Lowell
Chadrick
Chet
Emmett
German
Adrain
Ahmed
Augustine
Bob
Franco
Homer
Irvin
Nestor
Abdul
Anson
Danial
Kirby
Tremaine
Tremayne
Garrick
Kenyatta
Keon
Moshe
Ronny
Tucker
Amit
Andrae
Brenden
Denver
Donta
Eddy
Forest
Garland
Justen
Andreas
Javon
Mitchel
Eliseo
Jeramiah
Laron
Cale
Carmen
Jarret
Lazaro
Michelle
Tad
Zackery
Ezequiel
Lars
Simeon
Boyd
Burton
Cullen
Duncan
Jayme
Norberto
Gerry
Kenyon
Arnulfo
Genaro
Levar
Michel
Valentin
Wilbur
Buck
Hank
Kelsey
Lenny
Lincoln
Uriah
Woodrow
Germaine
Jude
Barton
Carter
Chadd
Dameon
Giuseppe
Isidro
Leopoldo
Rashawn
Trever
Zebulon
Brook
Darian
Edgardo
Irving
Jabari
Jace
Omari
Renaldo
Sammie
Cruz
Demarco
Eloy
Garett
Jarad
Jermain
Jessy
Nicky
Bobbie
Emil
Kody
Kraig
Rasheed
Bjorn
Brandan
Brody
Greggory
Lindsey
Samson
Shay
Vince
Amanda
Britton
Cristopher
Elbert
Nicole
Bronson
Coby
Deshaun
Doyle
Harlan
Keven
Marcelino
Rustin
Samir
Torrance
Estevan
Hiram
Lashawn
Sarah
Trinity
Westley
Antwain
Claudio
Dustan
Gideon
Jerrell
Kai
Kimberly
Muhammad
Cordell
Cristobal
Darron
Isaias
Mohammed
