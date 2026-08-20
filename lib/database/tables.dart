import 'package:drift/drift.dart';

@DataClassName('User')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get publicKey => text()();
  TextColumn get avatarPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Buddy')
class Buddies extends Table {
  TextColumn get id => text()();
  TextColumn get nickname => text().nullable()();
  TextColumn get publicKey => text()();
  
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LastLocation')
class LastLocations extends Table {
  TextColumn get buddyId => text().references(Buddies, #id)();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracy => real()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get speed => real().nullable()();
  RealColumn get heading => real().nullable()();
  TextColumn get transport => text()(); // 'internet' | 'sms' | 'cache'

  @override
  Set<Column> get primaryKey => {buddyId};
}

@DataClassName('TrackingSession')
class TrackingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get buddyId => text().references(Buddies, #id)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get mode => text()(); // e.g. 'active', 'passive'

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PendingRequest')
class PendingRequests extends Table {
  TextColumn get id => text()();
  TextColumn get fromBuddyId => text()();
  TextColumn get payload => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, accepted, rejected

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Setting')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
