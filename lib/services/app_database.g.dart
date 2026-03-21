// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TaskEntriesTable extends TaskEntries
    with TableInfo<$TaskEntriesTable, TaskEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>(
        'scheduled_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousTaskIdMeta = const VerificationMeta(
    'previousTaskId',
  );
  @override
  late final GeneratedColumn<String> previousTaskId = GeneratedColumn<String>(
    'previous_task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextTaskIdMeta = const VerificationMeta(
    'nextTaskId',
  );
  @override
  late final GeneratedColumn<String> nextTaskId = GeneratedColumn<String>(
    'next_task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceTypeMeta = const VerificationMeta(
    'recurrenceType',
  );
  @override
  late final GeneratedColumn<String> recurrenceType = GeneratedColumn<String>(
    'recurrence_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceParam1Meta = const VerificationMeta(
    'recurrenceParam1',
  );
  @override
  late final GeneratedColumn<int> recurrenceParam1 = GeneratedColumn<int>(
    'recurrence_param1',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceParam2Meta = const VerificationMeta(
    'recurrenceParam2',
  );
  @override
  late final GeneratedColumn<int> recurrenceParam2 = GeneratedColumn<int>(
    'recurrence_param2',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    notes,
    isCompleted,
    createdAt,
    scheduledDate,
    listId,
    previousTaskId,
    nextTaskId,
    recurrenceType,
    recurrenceParam1,
    recurrenceParam2,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('previous_task_id')) {
      context.handle(
        _previousTaskIdMeta,
        previousTaskId.isAcceptableOrUnknown(
          data['previous_task_id']!,
          _previousTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('next_task_id')) {
      context.handle(
        _nextTaskIdMeta,
        nextTaskId.isAcceptableOrUnknown(
          data['next_task_id']!,
          _nextTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_type')) {
      context.handle(
        _recurrenceTypeMeta,
        recurrenceType.isAcceptableOrUnknown(
          data['recurrence_type']!,
          _recurrenceTypeMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_param1')) {
      context.handle(
        _recurrenceParam1Meta,
        recurrenceParam1.isAcceptableOrUnknown(
          data['recurrence_param1']!,
          _recurrenceParam1Meta,
        ),
      );
    }
    if (data.containsKey('recurrence_param2')) {
      context.handle(
        _recurrenceParam2Meta,
        recurrenceParam2.isAcceptableOrUnknown(
          data['recurrence_param2']!,
          _recurrenceParam2Meta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date'],
      ),
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      )!,
      previousTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_task_id'],
      ),
      nextTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_task_id'],
      ),
      recurrenceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_type'],
      ),
      recurrenceParam1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence_param1'],
      ),
      recurrenceParam2: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence_param2'],
      ),
    );
  }

  @override
  $TaskEntriesTable createAlias(String alias) {
    return $TaskEntriesTable(attachedDatabase, alias);
  }
}

class TaskEntry extends DataClass implements Insertable<TaskEntry> {
  final String id;
  final String title;
  final String notes;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final String listId;
  final String? previousTaskId;
  final String? nextTaskId;
  final String? recurrenceType;
  final int? recurrenceParam1;
  final int? recurrenceParam2;
  const TaskEntry({
    required this.id,
    required this.title,
    required this.notes,
    required this.isCompleted,
    required this.createdAt,
    this.scheduledDate,
    required this.listId,
    this.previousTaskId,
    this.nextTaskId,
    this.recurrenceType,
    this.recurrenceParam1,
    this.recurrenceParam2,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['notes'] = Variable<String>(notes);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || scheduledDate != null) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    }
    map['list_id'] = Variable<String>(listId);
    if (!nullToAbsent || previousTaskId != null) {
      map['previous_task_id'] = Variable<String>(previousTaskId);
    }
    if (!nullToAbsent || nextTaskId != null) {
      map['next_task_id'] = Variable<String>(nextTaskId);
    }
    if (!nullToAbsent || recurrenceType != null) {
      map['recurrence_type'] = Variable<String>(recurrenceType);
    }
    if (!nullToAbsent || recurrenceParam1 != null) {
      map['recurrence_param1'] = Variable<int>(recurrenceParam1);
    }
    if (!nullToAbsent || recurrenceParam2 != null) {
      map['recurrence_param2'] = Variable<int>(recurrenceParam2);
    }
    return map;
  }

  TaskEntriesCompanion toCompanion(bool nullToAbsent) {
    return TaskEntriesCompanion(
      id: Value(id),
      title: Value(title),
      notes: Value(notes),
      isCompleted: Value(isCompleted),
      createdAt: Value(createdAt),
      scheduledDate: scheduledDate == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDate),
      listId: Value(listId),
      previousTaskId: previousTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(previousTaskId),
      nextTaskId: nextTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(nextTaskId),
      recurrenceType: recurrenceType == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceType),
      recurrenceParam1: recurrenceParam1 == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceParam1),
      recurrenceParam2: recurrenceParam2 == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceParam2),
    );
  }

  factory TaskEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskEntry(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String>(json['notes']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      scheduledDate: serializer.fromJson<DateTime?>(json['scheduledDate']),
      listId: serializer.fromJson<String>(json['listId']),
      previousTaskId: serializer.fromJson<String?>(json['previousTaskId']),
      nextTaskId: serializer.fromJson<String?>(json['nextTaskId']),
      recurrenceType: serializer.fromJson<String?>(json['recurrenceType']),
      recurrenceParam1: serializer.fromJson<int?>(json['recurrenceParam1']),
      recurrenceParam2: serializer.fromJson<int?>(json['recurrenceParam2']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String>(notes),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'scheduledDate': serializer.toJson<DateTime?>(scheduledDate),
      'listId': serializer.toJson<String>(listId),
      'previousTaskId': serializer.toJson<String?>(previousTaskId),
      'nextTaskId': serializer.toJson<String?>(nextTaskId),
      'recurrenceType': serializer.toJson<String?>(recurrenceType),
      'recurrenceParam1': serializer.toJson<int?>(recurrenceParam1),
      'recurrenceParam2': serializer.toJson<int?>(recurrenceParam2),
    };
  }

  TaskEntry copyWith({
    String? id,
    String? title,
    String? notes,
    bool? isCompleted,
    DateTime? createdAt,
    Value<DateTime?> scheduledDate = const Value.absent(),
    String? listId,
    Value<String?> previousTaskId = const Value.absent(),
    Value<String?> nextTaskId = const Value.absent(),
    Value<String?> recurrenceType = const Value.absent(),
    Value<int?> recurrenceParam1 = const Value.absent(),
    Value<int?> recurrenceParam2 = const Value.absent(),
  }) => TaskEntry(
    id: id ?? this.id,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt ?? this.createdAt,
    scheduledDate: scheduledDate.present
        ? scheduledDate.value
        : this.scheduledDate,
    listId: listId ?? this.listId,
    previousTaskId: previousTaskId.present
        ? previousTaskId.value
        : this.previousTaskId,
    nextTaskId: nextTaskId.present ? nextTaskId.value : this.nextTaskId,
    recurrenceType: recurrenceType.present
        ? recurrenceType.value
        : this.recurrenceType,
    recurrenceParam1: recurrenceParam1.present
        ? recurrenceParam1.value
        : this.recurrenceParam1,
    recurrenceParam2: recurrenceParam2.present
        ? recurrenceParam2.value
        : this.recurrenceParam2,
  );
  TaskEntry copyWithCompanion(TaskEntriesCompanion data) {
    return TaskEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      listId: data.listId.present ? data.listId.value : this.listId,
      previousTaskId: data.previousTaskId.present
          ? data.previousTaskId.value
          : this.previousTaskId,
      nextTaskId: data.nextTaskId.present
          ? data.nextTaskId.value
          : this.nextTaskId,
      recurrenceType: data.recurrenceType.present
          ? data.recurrenceType.value
          : this.recurrenceType,
      recurrenceParam1: data.recurrenceParam1.present
          ? data.recurrenceParam1.value
          : this.recurrenceParam1,
      recurrenceParam2: data.recurrenceParam2.present
          ? data.recurrenceParam2.value
          : this.recurrenceParam2,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('listId: $listId, ')
          ..write('previousTaskId: $previousTaskId, ')
          ..write('nextTaskId: $nextTaskId, ')
          ..write('recurrenceType: $recurrenceType, ')
          ..write('recurrenceParam1: $recurrenceParam1, ')
          ..write('recurrenceParam2: $recurrenceParam2')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    notes,
    isCompleted,
    createdAt,
    scheduledDate,
    listId,
    previousTaskId,
    nextTaskId,
    recurrenceType,
    recurrenceParam1,
    recurrenceParam2,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.isCompleted == this.isCompleted &&
          other.createdAt == this.createdAt &&
          other.scheduledDate == this.scheduledDate &&
          other.listId == this.listId &&
          other.previousTaskId == this.previousTaskId &&
          other.nextTaskId == this.nextTaskId &&
          other.recurrenceType == this.recurrenceType &&
          other.recurrenceParam1 == this.recurrenceParam1 &&
          other.recurrenceParam2 == this.recurrenceParam2);
}

class TaskEntriesCompanion extends UpdateCompanion<TaskEntry> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> notes;
  final Value<bool> isCompleted;
  final Value<DateTime> createdAt;
  final Value<DateTime?> scheduledDate;
  final Value<String> listId;
  final Value<String?> previousTaskId;
  final Value<String?> nextTaskId;
  final Value<String?> recurrenceType;
  final Value<int?> recurrenceParam1;
  final Value<int?> recurrenceParam2;
  final Value<int> rowid;
  const TaskEntriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.listId = const Value.absent(),
    this.previousTaskId = const Value.absent(),
    this.nextTaskId = const Value.absent(),
    this.recurrenceType = const Value.absent(),
    this.recurrenceParam1 = const Value.absent(),
    this.recurrenceParam2 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskEntriesCompanion.insert({
    required String id,
    required String title,
    this.notes = const Value.absent(),
    this.isCompleted = const Value.absent(),
    required DateTime createdAt,
    this.scheduledDate = const Value.absent(),
    required String listId,
    this.previousTaskId = const Value.absent(),
    this.nextTaskId = const Value.absent(),
    this.recurrenceType = const Value.absent(),
    this.recurrenceParam1 = const Value.absent(),
    this.recurrenceParam2 = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       listId = Value(listId);
  static Insertable<TaskEntry> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<bool>? isCompleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? scheduledDate,
    Expression<String>? listId,
    Expression<String>? previousTaskId,
    Expression<String>? nextTaskId,
    Expression<String>? recurrenceType,
    Expression<int>? recurrenceParam1,
    Expression<int>? recurrenceParam2,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (listId != null) 'list_id': listId,
      if (previousTaskId != null) 'previous_task_id': previousTaskId,
      if (nextTaskId != null) 'next_task_id': nextTaskId,
      if (recurrenceType != null) 'recurrence_type': recurrenceType,
      if (recurrenceParam1 != null) 'recurrence_param1': recurrenceParam1,
      if (recurrenceParam2 != null) 'recurrence_param2': recurrenceParam2,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? notes,
    Value<bool>? isCompleted,
    Value<DateTime>? createdAt,
    Value<DateTime?>? scheduledDate,
    Value<String>? listId,
    Value<String?>? previousTaskId,
    Value<String?>? nextTaskId,
    Value<String?>? recurrenceType,
    Value<int?>? recurrenceParam1,
    Value<int?>? recurrenceParam2,
    Value<int>? rowid,
  }) {
    return TaskEntriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      listId: listId ?? this.listId,
      previousTaskId: previousTaskId ?? this.previousTaskId,
      nextTaskId: nextTaskId ?? this.nextTaskId,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceParam1: recurrenceParam1 ?? this.recurrenceParam1,
      recurrenceParam2: recurrenceParam2 ?? this.recurrenceParam2,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (previousTaskId.present) {
      map['previous_task_id'] = Variable<String>(previousTaskId.value);
    }
    if (nextTaskId.present) {
      map['next_task_id'] = Variable<String>(nextTaskId.value);
    }
    if (recurrenceType.present) {
      map['recurrence_type'] = Variable<String>(recurrenceType.value);
    }
    if (recurrenceParam1.present) {
      map['recurrence_param1'] = Variable<int>(recurrenceParam1.value);
    }
    if (recurrenceParam2.present) {
      map['recurrence_param2'] = Variable<int>(recurrenceParam2.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskEntriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('listId: $listId, ')
          ..write('previousTaskId: $previousTaskId, ')
          ..write('nextTaskId: $nextTaskId, ')
          ..write('recurrenceType: $recurrenceType, ')
          ..write('recurrenceParam1: $recurrenceParam1, ')
          ..write('recurrenceParam2: $recurrenceParam2, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskTagEntriesTable extends TaskTagEntries
    with TableInfo<$TaskTagEntriesTable, TaskTagEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskTagEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [taskId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskTagEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId, tagId};
  @override
  TaskTagEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTagEntry(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $TaskTagEntriesTable createAlias(String alias) {
    return $TaskTagEntriesTable(attachedDatabase, alias);
  }
}

class TaskTagEntry extends DataClass implements Insertable<TaskTagEntry> {
  final String taskId;
  final String tagId;
  const TaskTagEntry({required this.taskId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  TaskTagEntriesCompanion toCompanion(bool nullToAbsent) {
    return TaskTagEntriesCompanion(taskId: Value(taskId), tagId: Value(tagId));
  }

  factory TaskTagEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTagEntry(
      taskId: serializer.fromJson<String>(json['taskId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  TaskTagEntry copyWith({String? taskId, String? tagId}) =>
      TaskTagEntry(taskId: taskId ?? this.taskId, tagId: tagId ?? this.tagId);
  TaskTagEntry copyWithCompanion(TaskTagEntriesCompanion data) {
    return TaskTagEntry(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskTagEntry(')
          ..write('taskId: $taskId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(taskId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskTagEntry &&
          other.taskId == this.taskId &&
          other.tagId == this.tagId);
}

class TaskTagEntriesCompanion extends UpdateCompanion<TaskTagEntry> {
  final Value<String> taskId;
  final Value<String> tagId;
  final Value<int> rowid;
  const TaskTagEntriesCompanion({
    this.taskId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskTagEntriesCompanion.insert({
    required String taskId,
    required String tagId,
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       tagId = Value(tagId);
  static Insertable<TaskTagEntry> custom({
    Expression<String>? taskId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskTagEntriesCompanion copyWith({
    Value<String>? taskId,
    Value<String>? tagId,
    Value<int>? rowid,
  }) {
    return TaskTagEntriesCompanion(
      taskId: taskId ?? this.taskId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskTagEntriesCompanion(')
          ..write('taskId: $taskId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskCompletedDateEntriesTable extends TaskCompletedDateEntries
    with TableInfo<$TaskCompletedDateEntriesTable, TaskCompletedDateEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskCompletedDateEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [taskId, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_completed_dates';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskCompletedDateEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId, date};
  @override
  TaskCompletedDateEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskCompletedDateEntry(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $TaskCompletedDateEntriesTable createAlias(String alias) {
    return $TaskCompletedDateEntriesTable(attachedDatabase, alias);
  }
}

class TaskCompletedDateEntry extends DataClass
    implements Insertable<TaskCompletedDateEntry> {
  final String taskId;
  final DateTime date;
  const TaskCompletedDateEntry({required this.taskId, required this.date});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['date'] = Variable<DateTime>(date);
    return map;
  }

  TaskCompletedDateEntriesCompanion toCompanion(bool nullToAbsent) {
    return TaskCompletedDateEntriesCompanion(
      taskId: Value(taskId),
      date: Value(date),
    );
  }

  factory TaskCompletedDateEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskCompletedDateEntry(
      taskId: serializer.fromJson<String>(json['taskId']),
      date: serializer.fromJson<DateTime>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'date': serializer.toJson<DateTime>(date),
    };
  }

  TaskCompletedDateEntry copyWith({String? taskId, DateTime? date}) =>
      TaskCompletedDateEntry(
        taskId: taskId ?? this.taskId,
        date: date ?? this.date,
      );
  TaskCompletedDateEntry copyWithCompanion(
    TaskCompletedDateEntriesCompanion data,
  ) {
    return TaskCompletedDateEntry(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskCompletedDateEntry(')
          ..write('taskId: $taskId, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(taskId, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskCompletedDateEntry &&
          other.taskId == this.taskId &&
          other.date == this.date);
}

class TaskCompletedDateEntriesCompanion
    extends UpdateCompanion<TaskCompletedDateEntry> {
  final Value<String> taskId;
  final Value<DateTime> date;
  final Value<int> rowid;
  const TaskCompletedDateEntriesCompanion({
    this.taskId = const Value.absent(),
    this.date = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskCompletedDateEntriesCompanion.insert({
    required String taskId,
    required DateTime date,
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       date = Value(date);
  static Insertable<TaskCompletedDateEntry> custom({
    Expression<String>? taskId,
    Expression<DateTime>? date,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (date != null) 'date': date,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskCompletedDateEntriesCompanion copyWith({
    Value<String>? taskId,
    Value<DateTime>? date,
    Value<int>? rowid,
  }) {
    return TaskCompletedDateEntriesCompanion(
      taskId: taskId ?? this.taskId,
      date: date ?? this.date,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskCompletedDateEntriesCompanion(')
          ..write('taskId: $taskId, ')
          ..write('date: $date, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListEntriesTable extends ListEntries
    with TableInfo<$ListEntriesTable, ListEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    colorValue,
    folderId,
    orderIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      ),
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
    );
  }

  @override
  $ListEntriesTable createAlias(String alias) {
    return $ListEntriesTable(attachedDatabase, alias);
  }
}

class ListEntry extends DataClass implements Insertable<ListEntry> {
  final String id;
  final String name;
  final int? colorValue;
  final String? folderId;
  final int orderIndex;
  const ListEntry({
    required this.id,
    required this.name,
    this.colorValue,
    this.folderId,
    required this.orderIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || colorValue != null) {
      map['color_value'] = Variable<int>(colorValue);
    }
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  ListEntriesCompanion toCompanion(bool nullToAbsent) {
    return ListEntriesCompanion(
      id: Value(id),
      name: Value(name),
      colorValue: colorValue == null && nullToAbsent
          ? const Value.absent()
          : Value(colorValue),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      orderIndex: Value(orderIndex),
    );
  }

  factory ListEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorValue: serializer.fromJson<int?>(json['colorValue']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'colorValue': serializer.toJson<int?>(colorValue),
      'folderId': serializer.toJson<String?>(folderId),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  ListEntry copyWith({
    String? id,
    String? name,
    Value<int?> colorValue = const Value.absent(),
    Value<String?> folderId = const Value.absent(),
    int? orderIndex,
  }) => ListEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    colorValue: colorValue.present ? colorValue.value : this.colorValue,
    folderId: folderId.present ? folderId.value : this.folderId,
    orderIndex: orderIndex ?? this.orderIndex,
  );
  ListEntry copyWithCompanion(ListEntriesCompanion data) {
    return ListEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue, ')
          ..write('folderId: $folderId, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorValue, folderId, orderIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorValue == this.colorValue &&
          other.folderId == this.folderId &&
          other.orderIndex == this.orderIndex);
}

class ListEntriesCompanion extends UpdateCompanion<ListEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<int?> colorValue;
  final Value<String?> folderId;
  final Value<int> orderIndex;
  final Value<int> rowid;
  const ListEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.folderId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListEntriesCompanion.insert({
    required String id,
    required String name,
    this.colorValue = const Value.absent(),
    this.folderId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<ListEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? colorValue,
    Expression<String>? folderId,
    Expression<int>? orderIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorValue != null) 'color_value': colorValue,
      if (folderId != null) 'folder_id': folderId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int?>? colorValue,
    Value<String?>? folderId,
    Value<int>? orderIndex,
    Value<int>? rowid,
  }) {
    return ListEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      folderId: folderId ?? this.folderId,
      orderIndex: orderIndex ?? this.orderIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue, ')
          ..write('folderId: $folderId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FolderEntriesTable extends FolderEntries
    with TableInfo<$FolderEntriesTable, FolderEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FolderEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, orderIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<FolderEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FolderEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FolderEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
    );
  }

  @override
  $FolderEntriesTable createAlias(String alias) {
    return $FolderEntriesTable(attachedDatabase, alias);
  }
}

class FolderEntry extends DataClass implements Insertable<FolderEntry> {
  final String id;
  final String name;
  final int orderIndex;
  const FolderEntry({
    required this.id,
    required this.name,
    required this.orderIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  FolderEntriesCompanion toCompanion(bool nullToAbsent) {
    return FolderEntriesCompanion(
      id: Value(id),
      name: Value(name),
      orderIndex: Value(orderIndex),
    );
  }

  factory FolderEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FolderEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  FolderEntry copyWith({String? id, String? name, int? orderIndex}) =>
      FolderEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        orderIndex: orderIndex ?? this.orderIndex,
      );
  FolderEntry copyWithCompanion(FolderEntriesCompanion data) {
    return FolderEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FolderEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, orderIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FolderEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.orderIndex == this.orderIndex);
}

class FolderEntriesCompanion extends UpdateCompanion<FolderEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> orderIndex;
  final Value<int> rowid;
  const FolderEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FolderEntriesCompanion.insert({
    required String id,
    required String name,
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<FolderEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? orderIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (orderIndex != null) 'order_index': orderIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FolderEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? orderIndex,
    Value<int>? rowid,
  }) {
    return FolderEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FolderEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagEntriesTable extends TagEntries
    with TableInfo<$TagEntriesTable, TagEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, colorValue];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
    );
  }

  @override
  $TagEntriesTable createAlias(String alias) {
    return $TagEntriesTable(attachedDatabase, alias);
  }
}

class TagEntry extends DataClass implements Insertable<TagEntry> {
  final String id;
  final String name;
  final int colorValue;
  const TagEntry({
    required this.id,
    required this.name,
    required this.colorValue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color_value'] = Variable<int>(colorValue);
    return map;
  }

  TagEntriesCompanion toCompanion(bool nullToAbsent) {
    return TagEntriesCompanion(
      id: Value(id),
      name: Value(name),
      colorValue: Value(colorValue),
    );
  }

  factory TagEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'colorValue': serializer.toJson<int>(colorValue),
    };
  }

  TagEntry copyWith({String? id, String? name, int? colorValue}) => TagEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
  );
  TagEntry copyWithCompanion(TagEntriesCompanion data) {
    return TagEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorValue == this.colorValue);
}

class TagEntriesCompanion extends UpdateCompanion<TagEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> colorValue;
  final Value<int> rowid;
  const TagEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagEntriesCompanion.insert({
    required String id,
    required String name,
    required int colorValue,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       colorValue = Value(colorValue);
  static Insertable<TagEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? colorValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorValue != null) 'color_value': colorValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? colorValue,
    Value<int>? rowid,
  }) {
    return TagEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SmartListEntriesTable extends SmartListEntries
    with TableInfo<$SmartListEntriesTable, SmartListEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmartListEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconCodePointMeta = const VerificationMeta(
    'iconCodePoint',
  );
  @override
  late final GeneratedColumn<int> iconCodePoint = GeneratedColumn<int>(
    'icon_code_point',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filterTypeMeta = const VerificationMeta(
    'filterType',
  );
  @override
  late final GeneratedColumn<String> filterType = GeneratedColumn<String>(
    'filter_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filterDateFromMeta = const VerificationMeta(
    'filterDateFrom',
  );
  @override
  late final GeneratedColumn<DateTime> filterDateFrom =
      GeneratedColumn<DateTime>(
        'filter_date_from',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _filterDateToMeta = const VerificationMeta(
    'filterDateTo',
  );
  @override
  late final GeneratedColumn<DateTime> filterDateTo = GeneratedColumn<DateTime>(
    'filter_date_to',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    iconCodePoint,
    colorValue,
    filterType,
    filterDateFrom,
    filterDateTo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'smart_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmartListEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_code_point')) {
      context.handle(
        _iconCodePointMeta,
        iconCodePoint.isAcceptableOrUnknown(
          data['icon_code_point']!,
          _iconCodePointMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_iconCodePointMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('filter_type')) {
      context.handle(
        _filterTypeMeta,
        filterType.isAcceptableOrUnknown(data['filter_type']!, _filterTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_filterTypeMeta);
    }
    if (data.containsKey('filter_date_from')) {
      context.handle(
        _filterDateFromMeta,
        filterDateFrom.isAcceptableOrUnknown(
          data['filter_date_from']!,
          _filterDateFromMeta,
        ),
      );
    }
    if (data.containsKey('filter_date_to')) {
      context.handle(
        _filterDateToMeta,
        filterDateTo.isAcceptableOrUnknown(
          data['filter_date_to']!,
          _filterDateToMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SmartListEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmartListEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconCodePoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_code_point'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      filterType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_type'],
      )!,
      filterDateFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}filter_date_from'],
      ),
      filterDateTo: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}filter_date_to'],
      ),
    );
  }

  @override
  $SmartListEntriesTable createAlias(String alias) {
    return $SmartListEntriesTable(attachedDatabase, alias);
  }
}

class SmartListEntry extends DataClass implements Insertable<SmartListEntry> {
  final String id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final String filterType;
  final DateTime? filterDateFrom;
  final DateTime? filterDateTo;
  const SmartListEntry({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.filterType,
    this.filterDateFrom,
    this.filterDateTo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon_code_point'] = Variable<int>(iconCodePoint);
    map['color_value'] = Variable<int>(colorValue);
    map['filter_type'] = Variable<String>(filterType);
    if (!nullToAbsent || filterDateFrom != null) {
      map['filter_date_from'] = Variable<DateTime>(filterDateFrom);
    }
    if (!nullToAbsent || filterDateTo != null) {
      map['filter_date_to'] = Variable<DateTime>(filterDateTo);
    }
    return map;
  }

  SmartListEntriesCompanion toCompanion(bool nullToAbsent) {
    return SmartListEntriesCompanion(
      id: Value(id),
      name: Value(name),
      iconCodePoint: Value(iconCodePoint),
      colorValue: Value(colorValue),
      filterType: Value(filterType),
      filterDateFrom: filterDateFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(filterDateFrom),
      filterDateTo: filterDateTo == null && nullToAbsent
          ? const Value.absent()
          : Value(filterDateTo),
    );
  }

  factory SmartListEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmartListEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      iconCodePoint: serializer.fromJson<int>(json['iconCodePoint']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      filterType: serializer.fromJson<String>(json['filterType']),
      filterDateFrom: serializer.fromJson<DateTime?>(json['filterDateFrom']),
      filterDateTo: serializer.fromJson<DateTime?>(json['filterDateTo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'iconCodePoint': serializer.toJson<int>(iconCodePoint),
      'colorValue': serializer.toJson<int>(colorValue),
      'filterType': serializer.toJson<String>(filterType),
      'filterDateFrom': serializer.toJson<DateTime?>(filterDateFrom),
      'filterDateTo': serializer.toJson<DateTime?>(filterDateTo),
    };
  }

  SmartListEntry copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    String? filterType,
    Value<DateTime?> filterDateFrom = const Value.absent(),
    Value<DateTime?> filterDateTo = const Value.absent(),
  }) => SmartListEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    colorValue: colorValue ?? this.colorValue,
    filterType: filterType ?? this.filterType,
    filterDateFrom: filterDateFrom.present
        ? filterDateFrom.value
        : this.filterDateFrom,
    filterDateTo: filterDateTo.present ? filterDateTo.value : this.filterDateTo,
  );
  SmartListEntry copyWithCompanion(SmartListEntriesCompanion data) {
    return SmartListEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconCodePoint: data.iconCodePoint.present
          ? data.iconCodePoint.value
          : this.iconCodePoint,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      filterType: data.filterType.present
          ? data.filterType.value
          : this.filterType,
      filterDateFrom: data.filterDateFrom.present
          ? data.filterDateFrom.value
          : this.filterDateFrom,
      filterDateTo: data.filterDateTo.present
          ? data.filterDateTo.value
          : this.filterDateTo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmartListEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('colorValue: $colorValue, ')
          ..write('filterType: $filterType, ')
          ..write('filterDateFrom: $filterDateFrom, ')
          ..write('filterDateTo: $filterDateTo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    iconCodePoint,
    colorValue,
    filterType,
    filterDateFrom,
    filterDateTo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmartListEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconCodePoint == this.iconCodePoint &&
          other.colorValue == this.colorValue &&
          other.filterType == this.filterType &&
          other.filterDateFrom == this.filterDateFrom &&
          other.filterDateTo == this.filterDateTo);
}

class SmartListEntriesCompanion extends UpdateCompanion<SmartListEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> iconCodePoint;
  final Value<int> colorValue;
  final Value<String> filterType;
  final Value<DateTime?> filterDateFrom;
  final Value<DateTime?> filterDateTo;
  final Value<int> rowid;
  const SmartListEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconCodePoint = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.filterType = const Value.absent(),
    this.filterDateFrom = const Value.absent(),
    this.filterDateTo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SmartListEntriesCompanion.insert({
    required String id,
    required String name,
    required int iconCodePoint,
    required int colorValue,
    required String filterType,
    this.filterDateFrom = const Value.absent(),
    this.filterDateTo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       iconCodePoint = Value(iconCodePoint),
       colorValue = Value(colorValue),
       filterType = Value(filterType);
  static Insertable<SmartListEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? iconCodePoint,
    Expression<int>? colorValue,
    Expression<String>? filterType,
    Expression<DateTime>? filterDateFrom,
    Expression<DateTime>? filterDateTo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconCodePoint != null) 'icon_code_point': iconCodePoint,
      if (colorValue != null) 'color_value': colorValue,
      if (filterType != null) 'filter_type': filterType,
      if (filterDateFrom != null) 'filter_date_from': filterDateFrom,
      if (filterDateTo != null) 'filter_date_to': filterDateTo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SmartListEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? iconCodePoint,
    Value<int>? colorValue,
    Value<String>? filterType,
    Value<DateTime?>? filterDateFrom,
    Value<DateTime?>? filterDateTo,
    Value<int>? rowid,
  }) {
    return SmartListEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      filterType: filterType ?? this.filterType,
      filterDateFrom: filterDateFrom ?? this.filterDateFrom,
      filterDateTo: filterDateTo ?? this.filterDateTo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconCodePoint.present) {
      map['icon_code_point'] = Variable<int>(iconCodePoint.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (filterType.present) {
      map['filter_type'] = Variable<String>(filterType.value);
    }
    if (filterDateFrom.present) {
      map['filter_date_from'] = Variable<DateTime>(filterDateFrom.value);
    }
    if (filterDateTo.present) {
      map['filter_date_to'] = Variable<DateTime>(filterDateTo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmartListEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('colorValue: $colorValue, ')
          ..write('filterType: $filterType, ')
          ..write('filterDateFrom: $filterDateFrom, ')
          ..write('filterDateTo: $filterDateTo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SmartListTagFilterEntriesTable extends SmartListTagFilterEntries
    with TableInfo<$SmartListTagFilterEntriesTable, SmartListTagFilterEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmartListTagFilterEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _smartListIdMeta = const VerificationMeta(
    'smartListId',
  );
  @override
  late final GeneratedColumn<String> smartListId = GeneratedColumn<String>(
    'smart_list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [smartListId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'smart_list_tag_filters';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmartListTagFilterEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('smart_list_id')) {
      context.handle(
        _smartListIdMeta,
        smartListId.isAcceptableOrUnknown(
          data['smart_list_id']!,
          _smartListIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_smartListIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {smartListId, tagId};
  @override
  SmartListTagFilterEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmartListTagFilterEntry(
      smartListId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}smart_list_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $SmartListTagFilterEntriesTable createAlias(String alias) {
    return $SmartListTagFilterEntriesTable(attachedDatabase, alias);
  }
}

class SmartListTagFilterEntry extends DataClass
    implements Insertable<SmartListTagFilterEntry> {
  final String smartListId;
  final String tagId;
  const SmartListTagFilterEntry({
    required this.smartListId,
    required this.tagId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['smart_list_id'] = Variable<String>(smartListId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  SmartListTagFilterEntriesCompanion toCompanion(bool nullToAbsent) {
    return SmartListTagFilterEntriesCompanion(
      smartListId: Value(smartListId),
      tagId: Value(tagId),
    );
  }

  factory SmartListTagFilterEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmartListTagFilterEntry(
      smartListId: serializer.fromJson<String>(json['smartListId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'smartListId': serializer.toJson<String>(smartListId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  SmartListTagFilterEntry copyWith({String? smartListId, String? tagId}) =>
      SmartListTagFilterEntry(
        smartListId: smartListId ?? this.smartListId,
        tagId: tagId ?? this.tagId,
      );
  SmartListTagFilterEntry copyWithCompanion(
    SmartListTagFilterEntriesCompanion data,
  ) {
    return SmartListTagFilterEntry(
      smartListId: data.smartListId.present
          ? data.smartListId.value
          : this.smartListId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmartListTagFilterEntry(')
          ..write('smartListId: $smartListId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(smartListId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmartListTagFilterEntry &&
          other.smartListId == this.smartListId &&
          other.tagId == this.tagId);
}

class SmartListTagFilterEntriesCompanion
    extends UpdateCompanion<SmartListTagFilterEntry> {
  final Value<String> smartListId;
  final Value<String> tagId;
  final Value<int> rowid;
  const SmartListTagFilterEntriesCompanion({
    this.smartListId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SmartListTagFilterEntriesCompanion.insert({
    required String smartListId,
    required String tagId,
    this.rowid = const Value.absent(),
  }) : smartListId = Value(smartListId),
       tagId = Value(tagId);
  static Insertable<SmartListTagFilterEntry> custom({
    Expression<String>? smartListId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (smartListId != null) 'smart_list_id': smartListId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SmartListTagFilterEntriesCompanion copyWith({
    Value<String>? smartListId,
    Value<String>? tagId,
    Value<int>? rowid,
  }) {
    return SmartListTagFilterEntriesCompanion(
      smartListId: smartListId ?? this.smartListId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (smartListId.present) {
      map['smart_list_id'] = Variable<String>(smartListId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmartListTagFilterEntriesCompanion(')
          ..write('smartListId: $smartListId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetadataEntriesTable extends MetadataEntries
    with TableInfo<$MetadataEntriesTable, MetadataEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetadataEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetadataEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetadataEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetadataEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $MetadataEntriesTable createAlias(String alias) {
    return $MetadataEntriesTable(attachedDatabase, alias);
  }
}

class MetadataEntry extends DataClass implements Insertable<MetadataEntry> {
  final String key;
  final String value;
  const MetadataEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetadataEntriesCompanion toCompanion(bool nullToAbsent) {
    return MetadataEntriesCompanion(key: Value(key), value: Value(value));
  }

  factory MetadataEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetadataEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MetadataEntry copyWith({String? key, String? value}) =>
      MetadataEntry(key: key ?? this.key, value: value ?? this.value);
  MetadataEntry copyWithCompanion(MetadataEntriesCompanion data) {
    return MetadataEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetadataEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetadataEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class MetadataEntriesCompanion extends UpdateCompanion<MetadataEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MetadataEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetadataEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetadataEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetadataEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MetadataEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetadataEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncEntityEntriesTable extends SyncEntityEntries
    with TableInfo<$SyncEntityEntriesTable, SyncEntityEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncEntityEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<String> ts = GeneratedColumn<String>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, ts];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_entities';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncEntityEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncEntityEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncEntityEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ts'],
      )!,
    );
  }

  @override
  $SyncEntityEntriesTable createAlias(String alias) {
    return $SyncEntityEntriesTable(attachedDatabase, alias);
  }
}

class SyncEntityEntry extends DataClass implements Insertable<SyncEntityEntry> {
  final String key;
  final String ts;
  const SyncEntityEntry({required this.key, required this.ts});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['ts'] = Variable<String>(ts);
    return map;
  }

  SyncEntityEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncEntityEntriesCompanion(key: Value(key), ts: Value(ts));
  }

  factory SyncEntityEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncEntityEntry(
      key: serializer.fromJson<String>(json['key']),
      ts: serializer.fromJson<String>(json['ts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'ts': serializer.toJson<String>(ts),
    };
  }

  SyncEntityEntry copyWith({String? key, String? ts}) =>
      SyncEntityEntry(key: key ?? this.key, ts: ts ?? this.ts);
  SyncEntityEntry copyWithCompanion(SyncEntityEntriesCompanion data) {
    return SyncEntityEntry(
      key: data.key.present ? data.key.value : this.key,
      ts: data.ts.present ? data.ts.value : this.ts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncEntityEntry(')
          ..write('key: $key, ')
          ..write('ts: $ts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, ts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncEntityEntry &&
          other.key == this.key &&
          other.ts == this.ts);
}

class SyncEntityEntriesCompanion extends UpdateCompanion<SyncEntityEntry> {
  final Value<String> key;
  final Value<String> ts;
  final Value<int> rowid;
  const SyncEntityEntriesCompanion({
    this.key = const Value.absent(),
    this.ts = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncEntityEntriesCompanion.insert({
    required String key,
    required String ts,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       ts = Value(ts);
  static Insertable<SyncEntityEntry> custom({
    Expression<String>? key,
    Expression<String>? ts,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (ts != null) 'ts': ts,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncEntityEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? ts,
    Value<int>? rowid,
  }) {
    return SyncEntityEntriesCompanion(
      key: key ?? this.key,
      ts: ts ?? this.ts,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (ts.present) {
      map['ts'] = Variable<String>(ts.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncEntityEntriesCompanion(')
          ..write('key: $key, ')
          ..write('ts: $ts, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncDeletionEntriesTable extends SyncDeletionEntries
    with TableInfo<$SyncDeletionEntriesTable, SyncDeletionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncDeletionEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<String> ts = GeneratedColumn<String>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, ts];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_deletions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncDeletionEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncDeletionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncDeletionEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ts'],
      )!,
    );
  }

  @override
  $SyncDeletionEntriesTable createAlias(String alias) {
    return $SyncDeletionEntriesTable(attachedDatabase, alias);
  }
}

class SyncDeletionEntry extends DataClass
    implements Insertable<SyncDeletionEntry> {
  final String key;
  final String ts;
  const SyncDeletionEntry({required this.key, required this.ts});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['ts'] = Variable<String>(ts);
    return map;
  }

  SyncDeletionEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncDeletionEntriesCompanion(key: Value(key), ts: Value(ts));
  }

  factory SyncDeletionEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncDeletionEntry(
      key: serializer.fromJson<String>(json['key']),
      ts: serializer.fromJson<String>(json['ts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'ts': serializer.toJson<String>(ts),
    };
  }

  SyncDeletionEntry copyWith({String? key, String? ts}) =>
      SyncDeletionEntry(key: key ?? this.key, ts: ts ?? this.ts);
  SyncDeletionEntry copyWithCompanion(SyncDeletionEntriesCompanion data) {
    return SyncDeletionEntry(
      key: data.key.present ? data.key.value : this.key,
      ts: data.ts.present ? data.ts.value : this.ts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncDeletionEntry(')
          ..write('key: $key, ')
          ..write('ts: $ts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, ts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncDeletionEntry &&
          other.key == this.key &&
          other.ts == this.ts);
}

class SyncDeletionEntriesCompanion extends UpdateCompanion<SyncDeletionEntry> {
  final Value<String> key;
  final Value<String> ts;
  final Value<int> rowid;
  const SyncDeletionEntriesCompanion({
    this.key = const Value.absent(),
    this.ts = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncDeletionEntriesCompanion.insert({
    required String key,
    required String ts,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       ts = Value(ts);
  static Insertable<SyncDeletionEntry> custom({
    Expression<String>? key,
    Expression<String>? ts,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (ts != null) 'ts': ts,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncDeletionEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? ts,
    Value<int>? rowid,
  }) {
    return SyncDeletionEntriesCompanion(
      key: key ?? this.key,
      ts: ts ?? this.ts,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (ts.present) {
      map['ts'] = Variable<String>(ts.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncDeletionEntriesCompanion(')
          ..write('key: $key, ')
          ..write('ts: $ts, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UiStateEntriesTable extends UiStateEntries
    with TableInfo<$UiStateEntriesTable, UiStateEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UiStateEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ui_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<UiStateEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  UiStateEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UiStateEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $UiStateEntriesTable createAlias(String alias) {
    return $UiStateEntriesTable(attachedDatabase, alias);
  }
}

class UiStateEntry extends DataClass implements Insertable<UiStateEntry> {
  final String key;
  final String value;
  const UiStateEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  UiStateEntriesCompanion toCompanion(bool nullToAbsent) {
    return UiStateEntriesCompanion(key: Value(key), value: Value(value));
  }

  factory UiStateEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UiStateEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  UiStateEntry copyWith({String? key, String? value}) =>
      UiStateEntry(key: key ?? this.key, value: value ?? this.value);
  UiStateEntry copyWithCompanion(UiStateEntriesCompanion data) {
    return UiStateEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UiStateEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UiStateEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class UiStateEntriesCompanion extends UpdateCompanion<UiStateEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const UiStateEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UiStateEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<UiStateEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UiStateEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return UiStateEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UiStateEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TaskEntriesTable taskEntries = $TaskEntriesTable(this);
  late final $TaskTagEntriesTable taskTagEntries = $TaskTagEntriesTable(this);
  late final $TaskCompletedDateEntriesTable taskCompletedDateEntries =
      $TaskCompletedDateEntriesTable(this);
  late final $ListEntriesTable listEntries = $ListEntriesTable(this);
  late final $FolderEntriesTable folderEntries = $FolderEntriesTable(this);
  late final $TagEntriesTable tagEntries = $TagEntriesTable(this);
  late final $SmartListEntriesTable smartListEntries = $SmartListEntriesTable(
    this,
  );
  late final $SmartListTagFilterEntriesTable smartListTagFilterEntries =
      $SmartListTagFilterEntriesTable(this);
  late final $MetadataEntriesTable metadataEntries = $MetadataEntriesTable(
    this,
  );
  late final $SyncEntityEntriesTable syncEntityEntries =
      $SyncEntityEntriesTable(this);
  late final $SyncDeletionEntriesTable syncDeletionEntries =
      $SyncDeletionEntriesTable(this);
  late final $UiStateEntriesTable uiStateEntries = $UiStateEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    taskEntries,
    taskTagEntries,
    taskCompletedDateEntries,
    listEntries,
    folderEntries,
    tagEntries,
    smartListEntries,
    smartListTagFilterEntries,
    metadataEntries,
    syncEntityEntries,
    syncDeletionEntries,
    uiStateEntries,
  ];
}

typedef $$TaskEntriesTableCreateCompanionBuilder =
    TaskEntriesCompanion Function({
      required String id,
      required String title,
      Value<String> notes,
      Value<bool> isCompleted,
      required DateTime createdAt,
      Value<DateTime?> scheduledDate,
      required String listId,
      Value<String?> previousTaskId,
      Value<String?> nextTaskId,
      Value<String?> recurrenceType,
      Value<int?> recurrenceParam1,
      Value<int?> recurrenceParam2,
      Value<int> rowid,
    });
typedef $$TaskEntriesTableUpdateCompanionBuilder =
    TaskEntriesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> notes,
      Value<bool> isCompleted,
      Value<DateTime> createdAt,
      Value<DateTime?> scheduledDate,
      Value<String> listId,
      Value<String?> previousTaskId,
      Value<String?> nextTaskId,
      Value<String?> recurrenceType,
      Value<int?> recurrenceParam1,
      Value<int?> recurrenceParam2,
      Value<int> rowid,
    });

class $$TaskEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TaskEntriesTable> {
  $$TaskEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousTaskId => $composableBuilder(
    column: $table.previousTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextTaskId => $composableBuilder(
    column: $table.nextTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceType => $composableBuilder(
    column: $table.recurrenceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recurrenceParam1 => $composableBuilder(
    column: $table.recurrenceParam1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recurrenceParam2 => $composableBuilder(
    column: $table.recurrenceParam2,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskEntriesTable> {
  $$TaskEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousTaskId => $composableBuilder(
    column: $table.previousTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextTaskId => $composableBuilder(
    column: $table.nextTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceType => $composableBuilder(
    column: $table.recurrenceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrenceParam1 => $composableBuilder(
    column: $table.recurrenceParam1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrenceParam2 => $composableBuilder(
    column: $table.recurrenceParam2,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskEntriesTable> {
  $$TaskEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumn<String> get previousTaskId => $composableBuilder(
    column: $table.previousTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextTaskId => $composableBuilder(
    column: $table.nextTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceType => $composableBuilder(
    column: $table.recurrenceType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recurrenceParam1 => $composableBuilder(
    column: $table.recurrenceParam1,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recurrenceParam2 => $composableBuilder(
    column: $table.recurrenceParam2,
    builder: (column) => column,
  );
}

class $$TaskEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskEntriesTable,
          TaskEntry,
          $$TaskEntriesTableFilterComposer,
          $$TaskEntriesTableOrderingComposer,
          $$TaskEntriesTableAnnotationComposer,
          $$TaskEntriesTableCreateCompanionBuilder,
          $$TaskEntriesTableUpdateCompanionBuilder,
          (
            TaskEntry,
            BaseReferences<_$AppDatabase, $TaskEntriesTable, TaskEntry>,
          ),
          TaskEntry,
          PrefetchHooks Function()
        > {
  $$TaskEntriesTableTableManager(_$AppDatabase db, $TaskEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> scheduledDate = const Value.absent(),
                Value<String> listId = const Value.absent(),
                Value<String?> previousTaskId = const Value.absent(),
                Value<String?> nextTaskId = const Value.absent(),
                Value<String?> recurrenceType = const Value.absent(),
                Value<int?> recurrenceParam1 = const Value.absent(),
                Value<int?> recurrenceParam2 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskEntriesCompanion(
                id: id,
                title: title,
                notes: notes,
                isCompleted: isCompleted,
                createdAt: createdAt,
                scheduledDate: scheduledDate,
                listId: listId,
                previousTaskId: previousTaskId,
                nextTaskId: nextTaskId,
                recurrenceType: recurrenceType,
                recurrenceParam1: recurrenceParam1,
                recurrenceParam2: recurrenceParam2,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String> notes = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> scheduledDate = const Value.absent(),
                required String listId,
                Value<String?> previousTaskId = const Value.absent(),
                Value<String?> nextTaskId = const Value.absent(),
                Value<String?> recurrenceType = const Value.absent(),
                Value<int?> recurrenceParam1 = const Value.absent(),
                Value<int?> recurrenceParam2 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskEntriesCompanion.insert(
                id: id,
                title: title,
                notes: notes,
                isCompleted: isCompleted,
                createdAt: createdAt,
                scheduledDate: scheduledDate,
                listId: listId,
                previousTaskId: previousTaskId,
                nextTaskId: nextTaskId,
                recurrenceType: recurrenceType,
                recurrenceParam1: recurrenceParam1,
                recurrenceParam2: recurrenceParam2,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskEntriesTable,
      TaskEntry,
      $$TaskEntriesTableFilterComposer,
      $$TaskEntriesTableOrderingComposer,
      $$TaskEntriesTableAnnotationComposer,
      $$TaskEntriesTableCreateCompanionBuilder,
      $$TaskEntriesTableUpdateCompanionBuilder,
      (TaskEntry, BaseReferences<_$AppDatabase, $TaskEntriesTable, TaskEntry>),
      TaskEntry,
      PrefetchHooks Function()
    >;
typedef $$TaskTagEntriesTableCreateCompanionBuilder =
    TaskTagEntriesCompanion Function({
      required String taskId,
      required String tagId,
      Value<int> rowid,
    });
typedef $$TaskTagEntriesTableUpdateCompanionBuilder =
    TaskTagEntriesCompanion Function({
      Value<String> taskId,
      Value<String> tagId,
      Value<int> rowid,
    });

class $$TaskTagEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TaskTagEntriesTable> {
  $$TaskTagEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskTagEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskTagEntriesTable> {
  $$TaskTagEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskTagEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskTagEntriesTable> {
  $$TaskTagEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);
}

class $$TaskTagEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskTagEntriesTable,
          TaskTagEntry,
          $$TaskTagEntriesTableFilterComposer,
          $$TaskTagEntriesTableOrderingComposer,
          $$TaskTagEntriesTableAnnotationComposer,
          $$TaskTagEntriesTableCreateCompanionBuilder,
          $$TaskTagEntriesTableUpdateCompanionBuilder,
          (
            TaskTagEntry,
            BaseReferences<_$AppDatabase, $TaskTagEntriesTable, TaskTagEntry>,
          ),
          TaskTagEntry,
          PrefetchHooks Function()
        > {
  $$TaskTagEntriesTableTableManager(
    _$AppDatabase db,
    $TaskTagEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskTagEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskTagEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskTagEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskTagEntriesCompanion(
                taskId: taskId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                required String tagId,
                Value<int> rowid = const Value.absent(),
              }) => TaskTagEntriesCompanion.insert(
                taskId: taskId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskTagEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskTagEntriesTable,
      TaskTagEntry,
      $$TaskTagEntriesTableFilterComposer,
      $$TaskTagEntriesTableOrderingComposer,
      $$TaskTagEntriesTableAnnotationComposer,
      $$TaskTagEntriesTableCreateCompanionBuilder,
      $$TaskTagEntriesTableUpdateCompanionBuilder,
      (
        TaskTagEntry,
        BaseReferences<_$AppDatabase, $TaskTagEntriesTable, TaskTagEntry>,
      ),
      TaskTagEntry,
      PrefetchHooks Function()
    >;
typedef $$TaskCompletedDateEntriesTableCreateCompanionBuilder =
    TaskCompletedDateEntriesCompanion Function({
      required String taskId,
      required DateTime date,
      Value<int> rowid,
    });
typedef $$TaskCompletedDateEntriesTableUpdateCompanionBuilder =
    TaskCompletedDateEntriesCompanion Function({
      Value<String> taskId,
      Value<DateTime> date,
      Value<int> rowid,
    });

class $$TaskCompletedDateEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TaskCompletedDateEntriesTable> {
  $$TaskCompletedDateEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskCompletedDateEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskCompletedDateEntriesTable> {
  $$TaskCompletedDateEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskCompletedDateEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskCompletedDateEntriesTable> {
  $$TaskCompletedDateEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);
}

class $$TaskCompletedDateEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskCompletedDateEntriesTable,
          TaskCompletedDateEntry,
          $$TaskCompletedDateEntriesTableFilterComposer,
          $$TaskCompletedDateEntriesTableOrderingComposer,
          $$TaskCompletedDateEntriesTableAnnotationComposer,
          $$TaskCompletedDateEntriesTableCreateCompanionBuilder,
          $$TaskCompletedDateEntriesTableUpdateCompanionBuilder,
          (
            TaskCompletedDateEntry,
            BaseReferences<
              _$AppDatabase,
              $TaskCompletedDateEntriesTable,
              TaskCompletedDateEntry
            >,
          ),
          TaskCompletedDateEntry,
          PrefetchHooks Function()
        > {
  $$TaskCompletedDateEntriesTableTableManager(
    _$AppDatabase db,
    $TaskCompletedDateEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskCompletedDateEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TaskCompletedDateEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TaskCompletedDateEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskCompletedDateEntriesCompanion(
                taskId: taskId,
                date: date,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                required DateTime date,
                Value<int> rowid = const Value.absent(),
              }) => TaskCompletedDateEntriesCompanion.insert(
                taskId: taskId,
                date: date,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskCompletedDateEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskCompletedDateEntriesTable,
      TaskCompletedDateEntry,
      $$TaskCompletedDateEntriesTableFilterComposer,
      $$TaskCompletedDateEntriesTableOrderingComposer,
      $$TaskCompletedDateEntriesTableAnnotationComposer,
      $$TaskCompletedDateEntriesTableCreateCompanionBuilder,
      $$TaskCompletedDateEntriesTableUpdateCompanionBuilder,
      (
        TaskCompletedDateEntry,
        BaseReferences<
          _$AppDatabase,
          $TaskCompletedDateEntriesTable,
          TaskCompletedDateEntry
        >,
      ),
      TaskCompletedDateEntry,
      PrefetchHooks Function()
    >;
typedef $$ListEntriesTableCreateCompanionBuilder =
    ListEntriesCompanion Function({
      required String id,
      required String name,
      Value<int?> colorValue,
      Value<String?> folderId,
      Value<int> orderIndex,
      Value<int> rowid,
    });
typedef $$ListEntriesTableUpdateCompanionBuilder =
    ListEntriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int?> colorValue,
      Value<String?> folderId,
      Value<int> orderIndex,
      Value<int> rowid,
    });

class $$ListEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ListEntriesTable> {
  $$ListEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ListEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ListEntriesTable> {
  $$ListEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ListEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListEntriesTable> {
  $$ListEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );
}

class $$ListEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ListEntriesTable,
          ListEntry,
          $$ListEntriesTableFilterComposer,
          $$ListEntriesTableOrderingComposer,
          $$ListEntriesTableAnnotationComposer,
          $$ListEntriesTableCreateCompanionBuilder,
          $$ListEntriesTableUpdateCompanionBuilder,
          (
            ListEntry,
            BaseReferences<_$AppDatabase, $ListEntriesTable, ListEntry>,
          ),
          ListEntry,
          PrefetchHooks Function()
        > {
  $$ListEntriesTableTableManager(_$AppDatabase db, $ListEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> colorValue = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListEntriesCompanion(
                id: id,
                name: name,
                colorValue: colorValue,
                folderId: folderId,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int?> colorValue = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListEntriesCompanion.insert(
                id: id,
                name: name,
                colorValue: colorValue,
                folderId: folderId,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ListEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ListEntriesTable,
      ListEntry,
      $$ListEntriesTableFilterComposer,
      $$ListEntriesTableOrderingComposer,
      $$ListEntriesTableAnnotationComposer,
      $$ListEntriesTableCreateCompanionBuilder,
      $$ListEntriesTableUpdateCompanionBuilder,
      (ListEntry, BaseReferences<_$AppDatabase, $ListEntriesTable, ListEntry>),
      ListEntry,
      PrefetchHooks Function()
    >;
typedef $$FolderEntriesTableCreateCompanionBuilder =
    FolderEntriesCompanion Function({
      required String id,
      required String name,
      Value<int> orderIndex,
      Value<int> rowid,
    });
typedef $$FolderEntriesTableUpdateCompanionBuilder =
    FolderEntriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> orderIndex,
      Value<int> rowid,
    });

class $$FolderEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FolderEntriesTable> {
  $$FolderEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FolderEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FolderEntriesTable> {
  $$FolderEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FolderEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FolderEntriesTable> {
  $$FolderEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );
}

class $$FolderEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FolderEntriesTable,
          FolderEntry,
          $$FolderEntriesTableFilterComposer,
          $$FolderEntriesTableOrderingComposer,
          $$FolderEntriesTableAnnotationComposer,
          $$FolderEntriesTableCreateCompanionBuilder,
          $$FolderEntriesTableUpdateCompanionBuilder,
          (
            FolderEntry,
            BaseReferences<_$AppDatabase, $FolderEntriesTable, FolderEntry>,
          ),
          FolderEntry,
          PrefetchHooks Function()
        > {
  $$FolderEntriesTableTableManager(_$AppDatabase db, $FolderEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FolderEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FolderEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FolderEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FolderEntriesCompanion(
                id: id,
                name: name,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FolderEntriesCompanion.insert(
                id: id,
                name: name,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FolderEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FolderEntriesTable,
      FolderEntry,
      $$FolderEntriesTableFilterComposer,
      $$FolderEntriesTableOrderingComposer,
      $$FolderEntriesTableAnnotationComposer,
      $$FolderEntriesTableCreateCompanionBuilder,
      $$FolderEntriesTableUpdateCompanionBuilder,
      (
        FolderEntry,
        BaseReferences<_$AppDatabase, $FolderEntriesTable, FolderEntry>,
      ),
      FolderEntry,
      PrefetchHooks Function()
    >;
typedef $$TagEntriesTableCreateCompanionBuilder =
    TagEntriesCompanion Function({
      required String id,
      required String name,
      required int colorValue,
      Value<int> rowid,
    });
typedef $$TagEntriesTableUpdateCompanionBuilder =
    TagEntriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> colorValue,
      Value<int> rowid,
    });

class $$TagEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TagEntriesTable> {
  $$TagEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TagEntriesTable> {
  $$TagEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagEntriesTable> {
  $$TagEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );
}

class $$TagEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagEntriesTable,
          TagEntry,
          $$TagEntriesTableFilterComposer,
          $$TagEntriesTableOrderingComposer,
          $$TagEntriesTableAnnotationComposer,
          $$TagEntriesTableCreateCompanionBuilder,
          $$TagEntriesTableUpdateCompanionBuilder,
          (TagEntry, BaseReferences<_$AppDatabase, $TagEntriesTable, TagEntry>),
          TagEntry,
          PrefetchHooks Function()
        > {
  $$TagEntriesTableTableManager(_$AppDatabase db, $TagEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagEntriesCompanion(
                id: id,
                name: name,
                colorValue: colorValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int colorValue,
                Value<int> rowid = const Value.absent(),
              }) => TagEntriesCompanion.insert(
                id: id,
                name: name,
                colorValue: colorValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagEntriesTable,
      TagEntry,
      $$TagEntriesTableFilterComposer,
      $$TagEntriesTableOrderingComposer,
      $$TagEntriesTableAnnotationComposer,
      $$TagEntriesTableCreateCompanionBuilder,
      $$TagEntriesTableUpdateCompanionBuilder,
      (TagEntry, BaseReferences<_$AppDatabase, $TagEntriesTable, TagEntry>),
      TagEntry,
      PrefetchHooks Function()
    >;
typedef $$SmartListEntriesTableCreateCompanionBuilder =
    SmartListEntriesCompanion Function({
      required String id,
      required String name,
      required int iconCodePoint,
      required int colorValue,
      required String filterType,
      Value<DateTime?> filterDateFrom,
      Value<DateTime?> filterDateTo,
      Value<int> rowid,
    });
typedef $$SmartListEntriesTableUpdateCompanionBuilder =
    SmartListEntriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> iconCodePoint,
      Value<int> colorValue,
      Value<String> filterType,
      Value<DateTime?> filterDateFrom,
      Value<DateTime?> filterDateTo,
      Value<int> rowid,
    });

class $$SmartListEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SmartListEntriesTable> {
  $$SmartListEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filterType => $composableBuilder(
    column: $table.filterType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get filterDateFrom => $composableBuilder(
    column: $table.filterDateFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get filterDateTo => $composableBuilder(
    column: $table.filterDateTo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SmartListEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SmartListEntriesTable> {
  $$SmartListEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterType => $composableBuilder(
    column: $table.filterType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get filterDateFrom => $composableBuilder(
    column: $table.filterDateFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get filterDateTo => $composableBuilder(
    column: $table.filterDateTo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SmartListEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmartListEntriesTable> {
  $$SmartListEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filterType => $composableBuilder(
    column: $table.filterType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get filterDateFrom => $composableBuilder(
    column: $table.filterDateFrom,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get filterDateTo => $composableBuilder(
    column: $table.filterDateTo,
    builder: (column) => column,
  );
}

class $$SmartListEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmartListEntriesTable,
          SmartListEntry,
          $$SmartListEntriesTableFilterComposer,
          $$SmartListEntriesTableOrderingComposer,
          $$SmartListEntriesTableAnnotationComposer,
          $$SmartListEntriesTableCreateCompanionBuilder,
          $$SmartListEntriesTableUpdateCompanionBuilder,
          (
            SmartListEntry,
            BaseReferences<
              _$AppDatabase,
              $SmartListEntriesTable,
              SmartListEntry
            >,
          ),
          SmartListEntry,
          PrefetchHooks Function()
        > {
  $$SmartListEntriesTableTableManager(
    _$AppDatabase db,
    $SmartListEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmartListEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmartListEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmartListEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> iconCodePoint = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<String> filterType = const Value.absent(),
                Value<DateTime?> filterDateFrom = const Value.absent(),
                Value<DateTime?> filterDateTo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmartListEntriesCompanion(
                id: id,
                name: name,
                iconCodePoint: iconCodePoint,
                colorValue: colorValue,
                filterType: filterType,
                filterDateFrom: filterDateFrom,
                filterDateTo: filterDateTo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int iconCodePoint,
                required int colorValue,
                required String filterType,
                Value<DateTime?> filterDateFrom = const Value.absent(),
                Value<DateTime?> filterDateTo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmartListEntriesCompanion.insert(
                id: id,
                name: name,
                iconCodePoint: iconCodePoint,
                colorValue: colorValue,
                filterType: filterType,
                filterDateFrom: filterDateFrom,
                filterDateTo: filterDateTo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SmartListEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmartListEntriesTable,
      SmartListEntry,
      $$SmartListEntriesTableFilterComposer,
      $$SmartListEntriesTableOrderingComposer,
      $$SmartListEntriesTableAnnotationComposer,
      $$SmartListEntriesTableCreateCompanionBuilder,
      $$SmartListEntriesTableUpdateCompanionBuilder,
      (
        SmartListEntry,
        BaseReferences<_$AppDatabase, $SmartListEntriesTable, SmartListEntry>,
      ),
      SmartListEntry,
      PrefetchHooks Function()
    >;
typedef $$SmartListTagFilterEntriesTableCreateCompanionBuilder =
    SmartListTagFilterEntriesCompanion Function({
      required String smartListId,
      required String tagId,
      Value<int> rowid,
    });
typedef $$SmartListTagFilterEntriesTableUpdateCompanionBuilder =
    SmartListTagFilterEntriesCompanion Function({
      Value<String> smartListId,
      Value<String> tagId,
      Value<int> rowid,
    });

class $$SmartListTagFilterEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SmartListTagFilterEntriesTable> {
  $$SmartListTagFilterEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get smartListId => $composableBuilder(
    column: $table.smartListId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SmartListTagFilterEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SmartListTagFilterEntriesTable> {
  $$SmartListTagFilterEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get smartListId => $composableBuilder(
    column: $table.smartListId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SmartListTagFilterEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmartListTagFilterEntriesTable> {
  $$SmartListTagFilterEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get smartListId => $composableBuilder(
    column: $table.smartListId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);
}

class $$SmartListTagFilterEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmartListTagFilterEntriesTable,
          SmartListTagFilterEntry,
          $$SmartListTagFilterEntriesTableFilterComposer,
          $$SmartListTagFilterEntriesTableOrderingComposer,
          $$SmartListTagFilterEntriesTableAnnotationComposer,
          $$SmartListTagFilterEntriesTableCreateCompanionBuilder,
          $$SmartListTagFilterEntriesTableUpdateCompanionBuilder,
          (
            SmartListTagFilterEntry,
            BaseReferences<
              _$AppDatabase,
              $SmartListTagFilterEntriesTable,
              SmartListTagFilterEntry
            >,
          ),
          SmartListTagFilterEntry,
          PrefetchHooks Function()
        > {
  $$SmartListTagFilterEntriesTableTableManager(
    _$AppDatabase db,
    $SmartListTagFilterEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmartListTagFilterEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SmartListTagFilterEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SmartListTagFilterEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> smartListId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmartListTagFilterEntriesCompanion(
                smartListId: smartListId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String smartListId,
                required String tagId,
                Value<int> rowid = const Value.absent(),
              }) => SmartListTagFilterEntriesCompanion.insert(
                smartListId: smartListId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SmartListTagFilterEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmartListTagFilterEntriesTable,
      SmartListTagFilterEntry,
      $$SmartListTagFilterEntriesTableFilterComposer,
      $$SmartListTagFilterEntriesTableOrderingComposer,
      $$SmartListTagFilterEntriesTableAnnotationComposer,
      $$SmartListTagFilterEntriesTableCreateCompanionBuilder,
      $$SmartListTagFilterEntriesTableUpdateCompanionBuilder,
      (
        SmartListTagFilterEntry,
        BaseReferences<
          _$AppDatabase,
          $SmartListTagFilterEntriesTable,
          SmartListTagFilterEntry
        >,
      ),
      SmartListTagFilterEntry,
      PrefetchHooks Function()
    >;
typedef $$MetadataEntriesTableCreateCompanionBuilder =
    MetadataEntriesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$MetadataEntriesTableUpdateCompanionBuilder =
    MetadataEntriesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$MetadataEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MetadataEntriesTable> {
  $$MetadataEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetadataEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MetadataEntriesTable> {
  $$MetadataEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetadataEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetadataEntriesTable> {
  $$MetadataEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$MetadataEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetadataEntriesTable,
          MetadataEntry,
          $$MetadataEntriesTableFilterComposer,
          $$MetadataEntriesTableOrderingComposer,
          $$MetadataEntriesTableAnnotationComposer,
          $$MetadataEntriesTableCreateCompanionBuilder,
          $$MetadataEntriesTableUpdateCompanionBuilder,
          (
            MetadataEntry,
            BaseReferences<_$AppDatabase, $MetadataEntriesTable, MetadataEntry>,
          ),
          MetadataEntry,
          PrefetchHooks Function()
        > {
  $$MetadataEntriesTableTableManager(
    _$AppDatabase db,
    $MetadataEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetadataEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetadataEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetadataEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetadataEntriesCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => MetadataEntriesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetadataEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetadataEntriesTable,
      MetadataEntry,
      $$MetadataEntriesTableFilterComposer,
      $$MetadataEntriesTableOrderingComposer,
      $$MetadataEntriesTableAnnotationComposer,
      $$MetadataEntriesTableCreateCompanionBuilder,
      $$MetadataEntriesTableUpdateCompanionBuilder,
      (
        MetadataEntry,
        BaseReferences<_$AppDatabase, $MetadataEntriesTable, MetadataEntry>,
      ),
      MetadataEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncEntityEntriesTableCreateCompanionBuilder =
    SyncEntityEntriesCompanion Function({
      required String key,
      required String ts,
      Value<int> rowid,
    });
typedef $$SyncEntityEntriesTableUpdateCompanionBuilder =
    SyncEntityEntriesCompanion Function({
      Value<String> key,
      Value<String> ts,
      Value<int> rowid,
    });

class $$SyncEntityEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncEntityEntriesTable> {
  $$SyncEntityEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncEntityEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncEntityEntriesTable> {
  $$SyncEntityEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncEntityEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncEntityEntriesTable> {
  $$SyncEntityEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);
}

class $$SyncEntityEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncEntityEntriesTable,
          SyncEntityEntry,
          $$SyncEntityEntriesTableFilterComposer,
          $$SyncEntityEntriesTableOrderingComposer,
          $$SyncEntityEntriesTableAnnotationComposer,
          $$SyncEntityEntriesTableCreateCompanionBuilder,
          $$SyncEntityEntriesTableUpdateCompanionBuilder,
          (
            SyncEntityEntry,
            BaseReferences<
              _$AppDatabase,
              $SyncEntityEntriesTable,
              SyncEntityEntry
            >,
          ),
          SyncEntityEntry,
          PrefetchHooks Function()
        > {
  $$SyncEntityEntriesTableTableManager(
    _$AppDatabase db,
    $SyncEntityEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncEntityEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncEntityEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncEntityEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> ts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncEntityEntriesCompanion(key: key, ts: ts, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String ts,
                Value<int> rowid = const Value.absent(),
              }) => SyncEntityEntriesCompanion.insert(
                key: key,
                ts: ts,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncEntityEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncEntityEntriesTable,
      SyncEntityEntry,
      $$SyncEntityEntriesTableFilterComposer,
      $$SyncEntityEntriesTableOrderingComposer,
      $$SyncEntityEntriesTableAnnotationComposer,
      $$SyncEntityEntriesTableCreateCompanionBuilder,
      $$SyncEntityEntriesTableUpdateCompanionBuilder,
      (
        SyncEntityEntry,
        BaseReferences<_$AppDatabase, $SyncEntityEntriesTable, SyncEntityEntry>,
      ),
      SyncEntityEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncDeletionEntriesTableCreateCompanionBuilder =
    SyncDeletionEntriesCompanion Function({
      required String key,
      required String ts,
      Value<int> rowid,
    });
typedef $$SyncDeletionEntriesTableUpdateCompanionBuilder =
    SyncDeletionEntriesCompanion Function({
      Value<String> key,
      Value<String> ts,
      Value<int> rowid,
    });

class $$SyncDeletionEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncDeletionEntriesTable> {
  $$SyncDeletionEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncDeletionEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncDeletionEntriesTable> {
  $$SyncDeletionEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncDeletionEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncDeletionEntriesTable> {
  $$SyncDeletionEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);
}

class $$SyncDeletionEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncDeletionEntriesTable,
          SyncDeletionEntry,
          $$SyncDeletionEntriesTableFilterComposer,
          $$SyncDeletionEntriesTableOrderingComposer,
          $$SyncDeletionEntriesTableAnnotationComposer,
          $$SyncDeletionEntriesTableCreateCompanionBuilder,
          $$SyncDeletionEntriesTableUpdateCompanionBuilder,
          (
            SyncDeletionEntry,
            BaseReferences<
              _$AppDatabase,
              $SyncDeletionEntriesTable,
              SyncDeletionEntry
            >,
          ),
          SyncDeletionEntry,
          PrefetchHooks Function()
        > {
  $$SyncDeletionEntriesTableTableManager(
    _$AppDatabase db,
    $SyncDeletionEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncDeletionEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncDeletionEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SyncDeletionEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> ts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  SyncDeletionEntriesCompanion(key: key, ts: ts, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String ts,
                Value<int> rowid = const Value.absent(),
              }) => SyncDeletionEntriesCompanion.insert(
                key: key,
                ts: ts,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncDeletionEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncDeletionEntriesTable,
      SyncDeletionEntry,
      $$SyncDeletionEntriesTableFilterComposer,
      $$SyncDeletionEntriesTableOrderingComposer,
      $$SyncDeletionEntriesTableAnnotationComposer,
      $$SyncDeletionEntriesTableCreateCompanionBuilder,
      $$SyncDeletionEntriesTableUpdateCompanionBuilder,
      (
        SyncDeletionEntry,
        BaseReferences<
          _$AppDatabase,
          $SyncDeletionEntriesTable,
          SyncDeletionEntry
        >,
      ),
      SyncDeletionEntry,
      PrefetchHooks Function()
    >;
typedef $$UiStateEntriesTableCreateCompanionBuilder =
    UiStateEntriesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$UiStateEntriesTableUpdateCompanionBuilder =
    UiStateEntriesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$UiStateEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $UiStateEntriesTable> {
  $$UiStateEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UiStateEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $UiStateEntriesTable> {
  $$UiStateEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UiStateEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UiStateEntriesTable> {
  $$UiStateEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$UiStateEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UiStateEntriesTable,
          UiStateEntry,
          $$UiStateEntriesTableFilterComposer,
          $$UiStateEntriesTableOrderingComposer,
          $$UiStateEntriesTableAnnotationComposer,
          $$UiStateEntriesTableCreateCompanionBuilder,
          $$UiStateEntriesTableUpdateCompanionBuilder,
          (
            UiStateEntry,
            BaseReferences<_$AppDatabase, $UiStateEntriesTable, UiStateEntry>,
          ),
          UiStateEntry,
          PrefetchHooks Function()
        > {
  $$UiStateEntriesTableTableManager(
    _$AppDatabase db,
    $UiStateEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UiStateEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UiStateEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UiStateEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  UiStateEntriesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => UiStateEntriesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UiStateEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UiStateEntriesTable,
      UiStateEntry,
      $$UiStateEntriesTableFilterComposer,
      $$UiStateEntriesTableOrderingComposer,
      $$UiStateEntriesTableAnnotationComposer,
      $$UiStateEntriesTableCreateCompanionBuilder,
      $$UiStateEntriesTableUpdateCompanionBuilder,
      (
        UiStateEntry,
        BaseReferences<_$AppDatabase, $UiStateEntriesTable, UiStateEntry>,
      ),
      UiStateEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TaskEntriesTableTableManager get taskEntries =>
      $$TaskEntriesTableTableManager(_db, _db.taskEntries);
  $$TaskTagEntriesTableTableManager get taskTagEntries =>
      $$TaskTagEntriesTableTableManager(_db, _db.taskTagEntries);
  $$TaskCompletedDateEntriesTableTableManager get taskCompletedDateEntries =>
      $$TaskCompletedDateEntriesTableTableManager(
        _db,
        _db.taskCompletedDateEntries,
      );
  $$ListEntriesTableTableManager get listEntries =>
      $$ListEntriesTableTableManager(_db, _db.listEntries);
  $$FolderEntriesTableTableManager get folderEntries =>
      $$FolderEntriesTableTableManager(_db, _db.folderEntries);
  $$TagEntriesTableTableManager get tagEntries =>
      $$TagEntriesTableTableManager(_db, _db.tagEntries);
  $$SmartListEntriesTableTableManager get smartListEntries =>
      $$SmartListEntriesTableTableManager(_db, _db.smartListEntries);
  $$SmartListTagFilterEntriesTableTableManager get smartListTagFilterEntries =>
      $$SmartListTagFilterEntriesTableTableManager(
        _db,
        _db.smartListTagFilterEntries,
      );
  $$MetadataEntriesTableTableManager get metadataEntries =>
      $$MetadataEntriesTableTableManager(_db, _db.metadataEntries);
  $$SyncEntityEntriesTableTableManager get syncEntityEntries =>
      $$SyncEntityEntriesTableTableManager(_db, _db.syncEntityEntries);
  $$SyncDeletionEntriesTableTableManager get syncDeletionEntries =>
      $$SyncDeletionEntriesTableTableManager(_db, _db.syncDeletionEntries);
  $$UiStateEntriesTableTableManager get uiStateEntries =>
      $$UiStateEntriesTableTableManager(_db, _db.uiStateEntries);
}
