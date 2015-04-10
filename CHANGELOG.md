Master
------

#### enhancements

* Added generic form helper and config options
* Added locales to gem initalizer
* Added fallback for missing datetime localizations
* Setup dummy-app for testing and demonstration

#### bugfix

* Fixed wrong day labels in form input

#### deprecation

* Renamed column 'days' into 'days' in order to exactly match ice-cube's method names. Use a migration to update column name in db.
* Changed type for column 'until' into 'datetime'. Use a migration to update column type in db.