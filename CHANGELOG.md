schedulable
===========

> Changelog

master
------

#### Enhancements
* Added option `input_types` for integrating custom form controls

#### Bugfix

# Fix max_build_count-option should be ignored when set to zero
* Fix config-generator template breaks with removed options
* Merge #17: Fixes the timezone issue #16, with event occurrences of recurring events
* Fix #14: Incorrect number of event occurrences
* Fix #11: Different name other than schedule
* Merge #15: Fix postgres error in build_occurrences rake task / Fix default_scope without block is removed

v0.0.10
-------

#### Bugfix

* Fixed occurrences association order

v0.0.9
------

#### Bugfix

* Fix singular occurrences not been updated in some cases
* Fix timezone offset with singular rule
* Fix missing remaining occurrences due to wrong ice_cube initialization date
* Fix undefined argument in init schedule
* Fix simple-form wrapper labels messing up monthly layout

v0.0.8
------

#### Enhancements

* Added generic form helper and config options
* Added locales to gem initalizer
* Added fallback for missing datetime localizations
* Setup dummy-app for testing and demonstration

#### Bugfix

* Fix wrong day labels in form input #5
* Fix deprecated group-syntax in rake task #6

#### Deprecation

* Renamed column 'days' into 'day' in order to exactly match ice-cube's method names. Use a migration to update column name in db.
* Changed type for column 'until' into 'datetime'. Use a migration to update column type in db.
* Schedule-Support-Model is now extended instead of included.