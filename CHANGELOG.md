Master
------

#### Bugfix
* Fixed occurrences not been updated due to picking datetime to identify existing items
* Fixed timezone offset with singular rule
* Fixed missing remaining occurrences due to wrong ice_cube initialization date
* Fixed undefined argument in init schedule
* Fixed simple-form wrapper labels messing up monthly layout

v0.0.8
------

#### Enhancements

* Added generic form helper and config options
* Added locales to gem initalizer
* Added fallback for missing datetime localizations
* Setup dummy-app for testing and demonstration

#### Bugfix

* Fixed wrong day labels in form input #5
* Fixed deprecated group-syntax in rake task #6

#### Deprecation

* Renamed column 'days' into 'day' in order to exactly match ice-cube's method names. Use a migration to update column name in db.
* Changed type for column 'until' into 'datetime'. Use a migration to update column type in db.
* Schedule-Support-Model is now extended instead of included.