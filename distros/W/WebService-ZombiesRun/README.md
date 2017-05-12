[![Support via Gittip](https://rawgithub.com/twolfson/gittip-badge/0.1.0/dist/gittip.png)](https://www.gittip.com/pjf/)

# SUMMARY

This module provides a basic interface for fetching data from the
popular "[Zombies, Run!](https://www.zombiesrungame.com/)" game.

# INSTALLATION

If installing from the CPAN (users):

    $ cpanm WebService::ZombiesRun

If installing from a cloned git repository (developers):

    $ dzil authordeps | cpanm
    $ dzil listdeps   | cpanm
    $ dzil install

# EXTRAS

The packaged `zombiesrun` cmdline tool will take a player name and
return basic information about that user. It's very basic, and
mostly provided as a proof-of-concept.
