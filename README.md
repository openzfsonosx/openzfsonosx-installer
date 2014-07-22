openzfsonosx-installer
======================

### How to run it:
`./make-installers.sh`

### Requirements:
- OS X 10.8 Mountain Lion or OS X 10.9 Mavericks
- http://s.sudre.free.fr/Software/files/Packages.dmg
- ~/Library/Keychains/openzfs-login.keychain added to Keychain Access.app
- Autotools, compiler, etc.

Caveat: If you do not have access to openzfs-login.keychain, at the moment you  
need to comment out all of the Mavericks and code signing sections.  

### Configuration options:

make-installers.sh
- `make_only`

scripts/make-pkg.sh
- `version`
- `should_unlock`
- `should_sign_installer`
- `dev_id_application`
- `dev_id_installer`
