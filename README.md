# SA-MP CW/TG GameMode
The Clan War & Training gamemode emerged in 2008/2009 by Czechoslovak developers exclusively to make Clan Wars between clans.
## New features
This version I provide brings new things added that were not included in the original codes.
- [Ranked sytem](#ranked-system)
- [Clan system](#clan-system)
- [Anti-fake system](#antifake-system)
- [Admin system](#admin-system)
## Includes
Are required to compile:
- [sscanf](https://github.com/maddinat0r/sscanf)
- [geolocation](https://github.com/Whitetigerswt/SAMP-geoip)
- zcmd (by [ZeeX](https://:github.com/Zeex))
## Plugins
To test the server:
- [crashdetect](https://github.com/Zeex/samp-plugin-crashdetect)
## Bugs
Nothing.
## Add
It is written in Spanish, when the gamemode is completely finished, the English translations will come out.

# Ranked system
The server saves all the data of the registered players through SQL queries, in which it will have the ranked score that is divided into 7 ranges
- Bronze
- Silver
- Gold
- Platinum
- Diamond
- Master
- Grand Master

The ranked score is only achieved by playing 1 vs 1..

# Clan system
The system is not finished, you have the basics like creating, removing and inviting people.

# Antifake system
If this system is activated, it does not allow players to enter with secondary accounts, only with the main account.

# Admin system
This system allows a player to have 3 type of levels administration, which are:
- (1) Game manager
- (2) General administrator
- (3) Player administrator

In addition, each range contains different administrator commands depending on its level.
