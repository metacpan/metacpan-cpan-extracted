package WordList::EN::PersonName::PopularBabyName::US::SSA::2000::FemaleTop1000;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-22'; # DATE
our $DIST = 'WordLists-EN-PersonName-PopularBabyName-US-SSA'; # DIST
our $VERSION = '0.003'; # VERSION

use WordList;
our @ISA = qw(WordList);

our $SORT = 'rank';

our %STATS = ("longest_word_len",10,"num_words_contain_nonword_chars",0,"num_words",1000,"num_words_contain_whitespace",0,"num_words_contains_whitespace",0,"avg_word_len",6.05,"shortest_word_len",3,"num_words_contains_unicode",0,"num_words_contains_nonword_chars",0,"num_words_contain_unicode",0); # STATS

1;
# ABSTRACT: Top 1000 most popular names for female babies born in the USA in 2000 (from Social Security Administration)

=pod

=encoding UTF-8

=head1 NAME

WordList::EN::PersonName::PopularBabyName::US::SSA::2000::FemaleTop1000 - Top 1000 most popular names for female babies born in the USA in 2000 (from Social Security Administration)

=head1 VERSION

This document describes version 0.003 of WordList::EN::PersonName::PopularBabyName::US::SSA::2000::FemaleTop1000 (from Perl distribution WordLists-EN-PersonName-PopularBabyName-US-SSA), released on 2020-05-22.

=head1 SYNOPSIS

 use WordList::EN::PersonName::PopularBabyName::US::SSA::2000::FemaleTop1000;

 my $wl = WordList::EN::PersonName::PopularBabyName::US::SSA::2000::FemaleTop1000->new;

 # Pick a (or several) random word(s) from the list
 my $word = $wl->pick;
 my @words = $wl->pick(3);

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Iterate
 my $first_word = $wl->first_word;
 while (defined(my $word = $wl->next_word)) { ... }

 # Get all the words
 my @all_words = $wl->all_words;

=head1 DESCRIPTION

Taken from L<https://www.ssa.gov/oact/babynames/>

Sorted by rank (most popular first).

=head1 STATISTICS

 +----------------------------------+-------+
 | key                              | value |
 +----------------------------------+-------+
 | avg_word_len                     | 6.05  |
 | longest_word_len                 | 10    |
 | num_words                        | 1000  |
 | num_words_contain_nonword_chars  | 0     |
 | num_words_contain_unicode        | 0     |
 | num_words_contain_whitespace     | 0     |
 | num_words_contains_nonword_chars | 0     |
 | num_words_contains_unicode       | 0     |
 | num_words_contains_whitespace    | 0     |
 | shortest_word_len                | 3     |
 +----------------------------------+-------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordLists-EN-PersonName-PopularBabyName-US-SSA>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordLists-EN-PersonName-PopularBabyName-US-SSA>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordLists-EN-PersonName-PopularBabyName-US-SSA>

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
Emily
Hannah
Madison
Ashley
Sarah
Alexis
Samantha
Jessica
Elizabeth
Taylor
Lauren
Alyssa
Kayla
Abigail
Brianna
Olivia
Emma
Megan
Grace
Victoria
Rachel
Anna
Sydney
Destiny
Morgan
Jennifer
Jasmine
Haley
Julia
Kaitlyn
Nicole
Amanda
Katherine
Natalie
Hailey
Alexandra
Savannah
Chloe
Rebecca
Stephanie
Maria
Sophia
Mackenzie
Allison
Isabella
Mary
Amber
Danielle
Gabrielle
Jordan
Brooke
Michelle
Sierra
Katelyn
Andrea
Madeline
Sara
Kimberly
Courtney
Erin
Brittany
Vanessa
Jenna
Jacqueline
Caroline
Faith
Makayla
Bailey
Paige
Shelby
Melissa
Kaylee
Christina
Trinity
Mariah
Caitlin
Autumn
Marissa
Angela
Breanna
Catherine
Zoe
Briana
Jada
Laura
Claire
Alexa
Kelsey
Kathryn
Leslie
Alexandria
Sabrina
Mia
Isabel
Molly
Katie
Leah
Gabriella
Cheyenne
Cassandra
Tiffany
Erica
Lindsey
Kylie
Amy
Diana
Cassidy
Mikayla
Ariana
Margaret
Kelly
Miranda
Maya
Melanie
Audrey
Jade
Gabriela
Caitlyn
Angel
Jillian
Alicia
Jocelyn
Erika
Lily
Heather
Madelyn
Adriana
Arianna
Lillian
Kiara
Riley
Crystal
Mckenzie
Meghan
Skylar
Ana
Britney
Angelica
Kennedy
Chelsea
Daisy
Kristen
Veronica
Isabelle
Summer
Hope
Brittney
Lydia
Hayley
Evelyn
Bethany
Shannon
Karen
Michaela
Jamie
Daniela
Angelina
Kaitlin
Karina
Sophie
Sofia
Diamond
Payton
Cynthia
Alexia
Valerie
Monica
Peyton
Carly
Bianca
Hanna
Brenda
Rebekah
Alejandra
Mya
Avery
Brooklyn
Ashlyn
Lindsay
Ava
Desiree
Alondra
Camryn
Ariel
Naomi
Jordyn
Kendra
Mckenna
Holly
Julie
Kendall
Kara
Jasmin
Selena
Esmeralda
Amaya
Kylee
Maggie
Makenzie
Claudia
Kyra
Cameron
Karla
Kathleen
Abby
Delaney
Amelia
Casey
Serena
Savanna
Aaliyah
Giselle
Mallory
April
Adrianna
Raven
Christine
Kristina
Nina
Asia
Natalia
Valeria
Aubrey
Lauryn
Kate
Patricia
Jazmin
Rachael
Katelynn
Cierra
Alison
Nancy
Macy
Elena
Kyla
Katrina
Jazmine
Joanna
Tara
Gianna
Juliana
Fatima
Sadie
Allyson
Gracie
Guadalupe
Genesis
Yesenia
Julianna
Skyler
Tatiana
Alexus
Alana
Elise
Kirsten
Nadia
Sandra
Ruby
Dominique
Haylee
Jayla
Tori
Cindy
Ella
Sidney
Tessa
Carolina
Jaqueline
Camille
Carmen
Whitney
Vivian
Priscilla
Bridget
Celeste
Kiana
Makenna
Alissa
Madeleine
Miriam
Natasha
Ciara
Cecilia
Kassandra
Mercedes
Reagan
Aliyah
Josephine
Charlotte
Rylee
Shania
Kira
Meredith
Eva
Lisa
Dakota
Hallie
Anne
Rose
Liliana
Kristin
Deanna
Imani
Marisa
Kailey
Annie
Nia
Carolyn
Anastasia
Brenna
Dana
Shayla
Ashlee
Kassidy
Alaina
Wendy
Rosa
Logan
Tabitha
Paola
Callie
Addison
Lucy
Gillian
Clarissa
Esther
Destinee
Josie
Denise
Katlyn
Mariana
Bryanna
Emilee
Georgia
Kamryn
Deja
Ashleigh
Cristina
Ruth
Baylee
Heaven
Raquel
Monique
Teresa
Helen
Krystal
Tiana
Cassie
Kayleigh
Marina
Ivy
Heidi
Clara
Ashton
Meagan
Gina
Linda
Gloria
Jacquelyn
Ellie
Jenny
Renee
Daniella
Lizbeth
Anahi
Virginia
Gisselle
Kaitlynn
Julissa
Cheyanne
Lacey
Haleigh
Marie
Martha
Eleanor
Kierra
Tiara
Talia
Eliza
Kaylie
Mikaela
Harley
Jaden
Hailee
Madalyn
Kasey
Ashlynn
Brandi
Lesly
Elisabeth
Allie
Viviana
Cara
Marisol
India
Litzy
Tatyana
Melody
Jessie
Brandy
Alisha
Hunter
Noelle
Carla
Francesca
Tia
Layla
Krista
Zoey
Carley
Janet
Carissa
Iris
Susan
Kaleigh
Tyler
Tamara
Theresa
Yasmine
Tatum
Sharon
Alice
Yasmin
Tamia
Abbey
Alayna
Kali
Lilly
Bailee
Lesley
Mckayla
Ayanna
Serenity
Karissa
Precious
Jane
Maddison
Jayda
Lexi
Kelsie
Phoebe
Halle
Kiersten
Kiera
Tyra
Annika
Felicity
Taryn
Kaylin
Ellen
Kiley
Jaclyn
Rhiannon
Madisyn
Colleen
Joy
Charity
Pamela
Tania
Fiona
Kaila
Irene
Alyson
Annabelle
Emely
Angelique
Alina
Johanna
Regan
Janelle
Janae
Madyson
Paris
Justine
Chelsey
Sasha
Paulina
Mayra
Zaria
Skye
Cora
Brisa
Emilie
Felicia
Tianna
Larissa
Macie
Aurora
Sage
Lucia
Alma
Chasity
Ann
Deborah
Nichole
Jayden
Alanna
Malia
Carlie
Angie
Nora
Sylvia
Carrie
Kailee
Elaina
Sonia
Barbara
Kenya
Genevieve
Piper
Marilyn
Amari
Macey
Marlene
Julianne
Tayler
Brooklynn
Lorena
Perla
Elisa
Eden
Kaley
Leilani
Miracle
Devin
Aileen
Chyna
Esperanza
Athena
Regina
Adrienne
Shyanne
Luz
Tierra
Clare
Cristal
Eliana
Kelli
Eve
Sydnee
Madelynn
Breana
Melina
Arielle
Justice
Toni
Corinne
Abbigail
Maia
Tess
Ciera
Ebony
Lena
Maritza
Lexie
Isis
Aimee
Leticia
Sydni
Sarai
Halie
Alivia
Destiney
Laurel
Edith
Fernanda
Carina
Amya
Destini
Aspen
Nathalie
Paula
Tanya
Tina
Frances
Christian
Elaine
Shayna
Aniya
Mollie
Ryan
Essence
Simone
Kyleigh
Nikki
Anya
Reyna
Savanah
Kaylyn
Nicolette
Abbie
Montana
Kailyn
Itzel
Leila
Cayla
Stacy
Robin
Araceli
Candace
Dulce
Noemi
Aleah
Jewel
Ally
Mara
Nayeli
Karlee
Keely
Micaela
Alisa
Desirae
Leanna
Antonia
Judith
Brynn
Jaelyn
Raegan
Katelin
Sienna
Celia
Yvette
Juliet
Anika
Emilia
Calista
Carlee
Eileen
Kianna
Thalia
Rylie
Rosemary
Daphne
Kacie
Karli
Micah
Ericka
Jadyn
Lyndsey
Hana
Haylie
Madilyn
Blanca
Laila
Kayley
Katarina
Kellie
Maribel
Sandy
Joselyn
Kaelyn
Kathy
Madisen
Carson
Margarita
Stella
Juliette
Devon
Bria
Camila
Donna
Helena
Lea
Jazlyn
Jazmyn
Skyla
Christy
Joyce
Katharine
Karlie
Lexus
Alessandra
Salma
Delilah
Moriah
Beatriz
Celine
Lizeth
Brianne
Kourtney
Sydnie
Mariam
Stacey
Robyn
Hayden
Janessa
Kenzie
Jalyn
Sheila
Meaghan
Aisha
Shawna
Jaida
Estrella
Marley
Melinda
Ayana
Karly
Devyn
Nataly
Loren
Rosalinda
Brielle
Laney
Sally
Lizette
Tracy
Lilian
Rebeca
Chandler
Jenifer
Diane
Valentina
America
Candice
Abigayle
Susana
Aliya
Casandra
Harmony
Jacey
Alena
Aylin
Carol
Shea
Stephany
Aniyah
Zoie
Jackeline
Alia
Gwendolyn
Savana
Damaris
Violet
Marian
Anita
Jaime
Alexandrea
Dorothy
Jaiden
Kristine
Carli
Gretchen
Janice
Annette
Mariela
Amani
Maura
Bella
Kaylynn
Lila
Armani
Anissa
Aubree
Kelsi
Greta
Kaya
Kayli
Lillie
Willow
Ansley
Catalina
Lia
Maci
Mattie
Celina
Shyann
Alysa
Jaquelin
Quinn
Cecelia
Kallie
Kasandra
Chaya
Hailie
Haven
Maegan
Maeve
Rocio
Yolanda
Christa
Gabriel
Kari
Noelia
Jeanette
Kaylah
Marianna
Nya
Kennedi
Presley
Yadira
Elissa
Nyah
Shaina
Reilly
Alize
Amara
Arlene
Izabella
Lyric
Aiyana
Allyssa
Drew
Rachelle
Adeline
Jacklyn
Jesse
Citlalli
Giovanna
Liana
Brook
Graciela
Princess
Selina
Chanel
Elyse
Cali
Berenice
Iliana
Jolie
Annalise
Caitlynn
Christiana
Sarina
Cortney
Darlene
Dasia
London
Yvonne
Karley
Shaylee
Kristy
Myah
Ryleigh
Amira
Juanita
Dariana
Teagan
Kiarra
Ryann
Yamilet
Sheridan
Alexys
Baby
Kacey
Shakira
Dianna
Lara
Isabela
Reina
Shirley
Jaycee
Silvia
Tatianna
Eryn
Ingrid
Keara
Randi
Reanna
Kalyn
Lisette
Monserrat
Abril
Ivana
Lori
Darby
Kaela
Maranda
Parker
Darian
Jasmyn
Jaylin
Katia
Ayla
Bridgette
Elyssa
Hillary
Kinsey
Yazmin
Caleigh
Rita
Asha
Dayana
Nikita
Chantel
Reese
Stefanie
Nadine
Samara
Unique
Michele
Sonya
Hazel
Patience
Cielo
Mireya
Paloma
Aryanna
Magdalena
Anaya
Dallas
Joelle
Norma
Arely
Kaia
Misty
Taya
Deasia
Trisha
Elsa
Joana
Alysha
Aracely
Bryana
Dawn
Alex
Brionna
Katerina
Ali
Bonnie
Hadley
Martina
Maryam
Jazmyne
Shaniya
Alycia
Dejah
Emmalee
Estefania
Jakayla
Lilliana
Nyasia
Anjali
Daisha
Myra
Amiya
Belen
Jana
Aja
Saige
Annabel
Scarlett
Destany
Joanne
Aliza
Ashly
Cydney
Fabiola
Gia
Keira
Roxanne
Kaci
Abigale
Abagail
Janiya
Odalys
Aria
Daija
Delia
Kameron
Raina
Ashtyn
Dayna
Katy
Lourdes
Emerald
Kirstin
Marlee
Neha
Beatrice
Blair
Kori
Luisa
Yasmeen
Annamarie
Breonna
Jena
Leann
Rhianna
Yessenia
Breanne
Katlynn
Laisha
Mandy
Amina
Jailyn
Jayde
Jill
Kaylan
Kenna
Antoinette
Rayna
Sky
Iyana
Keeley
Kenia
Maiya
Melisa
Adrian
Marlen
