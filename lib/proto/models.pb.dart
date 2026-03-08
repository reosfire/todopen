// This is a generated file - do not edit.
//
// Generated from models.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ProtoDailyRecurrence extends $pb.GeneratedMessage {
  factory ProtoDailyRecurrence() => create();

  ProtoDailyRecurrence._();

  factory ProtoDailyRecurrence.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoDailyRecurrence.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoDailyRecurrence',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoDailyRecurrence clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoDailyRecurrence copyWith(void Function(ProtoDailyRecurrence) updates) =>
      super.copyWith((message) => updates(message as ProtoDailyRecurrence))
          as ProtoDailyRecurrence;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoDailyRecurrence create() => ProtoDailyRecurrence._();
  @$core.override
  ProtoDailyRecurrence createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoDailyRecurrence getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoDailyRecurrence>(create);
  static ProtoDailyRecurrence? _defaultInstance;
}

class ProtoEveryNDaysRecurrence extends $pb.GeneratedMessage {
  factory ProtoEveryNDaysRecurrence({
    $core.int? interval,
  }) {
    final result = create();
    if (interval != null) result.interval = interval;
    return result;
  }

  ProtoEveryNDaysRecurrence._();

  factory ProtoEveryNDaysRecurrence.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoEveryNDaysRecurrence.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoEveryNDaysRecurrence',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'interval')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoEveryNDaysRecurrence clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoEveryNDaysRecurrence copyWith(
          void Function(ProtoEveryNDaysRecurrence) updates) =>
      super.copyWith((message) => updates(message as ProtoEveryNDaysRecurrence))
          as ProtoEveryNDaysRecurrence;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoEveryNDaysRecurrence create() => ProtoEveryNDaysRecurrence._();
  @$core.override
  ProtoEveryNDaysRecurrence createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoEveryNDaysRecurrence getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoEveryNDaysRecurrence>(create);
  static ProtoEveryNDaysRecurrence? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get interval => $_getIZ(0);
  @$pb.TagNumber(1)
  set interval($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInterval() => $_has(0);
  @$pb.TagNumber(1)
  void clearInterval() => $_clearField(1);
}

class ProtoWeeklyRecurrence extends $pb.GeneratedMessage {
  factory ProtoWeeklyRecurrence({
    $core.int? weekdayBits,
  }) {
    final result = create();
    if (weekdayBits != null) result.weekdayBits = weekdayBits;
    return result;
  }

  ProtoWeeklyRecurrence._();

  factory ProtoWeeklyRecurrence.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoWeeklyRecurrence.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoWeeklyRecurrence',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'weekdayBits', protoName: 'weekdayBits')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoWeeklyRecurrence clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoWeeklyRecurrence copyWith(
          void Function(ProtoWeeklyRecurrence) updates) =>
      super.copyWith((message) => updates(message as ProtoWeeklyRecurrence))
          as ProtoWeeklyRecurrence;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoWeeklyRecurrence create() => ProtoWeeklyRecurrence._();
  @$core.override
  ProtoWeeklyRecurrence createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoWeeklyRecurrence getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoWeeklyRecurrence>(create);
  static ProtoWeeklyRecurrence? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get weekdayBits => $_getIZ(0);
  @$pb.TagNumber(1)
  set weekdayBits($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWeekdayBits() => $_has(0);
  @$pb.TagNumber(1)
  void clearWeekdayBits() => $_clearField(1);
}

class ProtoMonthlyRecurrence extends $pb.GeneratedMessage {
  factory ProtoMonthlyRecurrence({
    $core.int? dayOfMonth,
  }) {
    final result = create();
    if (dayOfMonth != null) result.dayOfMonth = dayOfMonth;
    return result;
  }

  ProtoMonthlyRecurrence._();

  factory ProtoMonthlyRecurrence.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoMonthlyRecurrence.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoMonthlyRecurrence',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'dayOfMonth')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoMonthlyRecurrence clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoMonthlyRecurrence copyWith(
          void Function(ProtoMonthlyRecurrence) updates) =>
      super.copyWith((message) => updates(message as ProtoMonthlyRecurrence))
          as ProtoMonthlyRecurrence;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoMonthlyRecurrence create() => ProtoMonthlyRecurrence._();
  @$core.override
  ProtoMonthlyRecurrence createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoMonthlyRecurrence getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoMonthlyRecurrence>(create);
  static ProtoMonthlyRecurrence? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get dayOfMonth => $_getIZ(0);
  @$pb.TagNumber(1)
  set dayOfMonth($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDayOfMonth() => $_has(0);
  @$pb.TagNumber(1)
  void clearDayOfMonth() => $_clearField(1);
}

class ProtoYearlyRecurrence extends $pb.GeneratedMessage {
  factory ProtoYearlyRecurrence({
    $core.int? month,
    $core.int? dayOfMonth,
  }) {
    final result = create();
    if (month != null) result.month = month;
    if (dayOfMonth != null) result.dayOfMonth = dayOfMonth;
    return result;
  }

  ProtoYearlyRecurrence._();

  factory ProtoYearlyRecurrence.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoYearlyRecurrence.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoYearlyRecurrence',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'month')
    ..aI(2, _omitFieldNames ? '' : 'dayOfMonth')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoYearlyRecurrence clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoYearlyRecurrence copyWith(
          void Function(ProtoYearlyRecurrence) updates) =>
      super.copyWith((message) => updates(message as ProtoYearlyRecurrence))
          as ProtoYearlyRecurrence;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoYearlyRecurrence create() => ProtoYearlyRecurrence._();
  @$core.override
  ProtoYearlyRecurrence createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoYearlyRecurrence getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoYearlyRecurrence>(create);
  static ProtoYearlyRecurrence? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get month => $_getIZ(0);
  @$pb.TagNumber(1)
  set month($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMonth() => $_has(0);
  @$pb.TagNumber(1)
  void clearMonth() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get dayOfMonth => $_getIZ(1);
  @$pb.TagNumber(2)
  set dayOfMonth($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDayOfMonth() => $_has(1);
  @$pb.TagNumber(2)
  void clearDayOfMonth() => $_clearField(2);
}

enum ProtoRecurrenceRule_Rule {
  daily,
  everyNDays,
  weekly,
  monthly,
  yearly,
  notSet
}

class ProtoRecurrenceRule extends $pb.GeneratedMessage {
  factory ProtoRecurrenceRule({
    ProtoDailyRecurrence? daily,
    ProtoEveryNDaysRecurrence? everyNDays,
    ProtoWeeklyRecurrence? weekly,
    ProtoMonthlyRecurrence? monthly,
    ProtoYearlyRecurrence? yearly,
  }) {
    final result = create();
    if (daily != null) result.daily = daily;
    if (everyNDays != null) result.everyNDays = everyNDays;
    if (weekly != null) result.weekly = weekly;
    if (monthly != null) result.monthly = monthly;
    if (yearly != null) result.yearly = yearly;
    return result;
  }

  ProtoRecurrenceRule._();

  factory ProtoRecurrenceRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoRecurrenceRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ProtoRecurrenceRule_Rule>
      _ProtoRecurrenceRule_RuleByTag = {
    1: ProtoRecurrenceRule_Rule.daily,
    2: ProtoRecurrenceRule_Rule.everyNDays,
    3: ProtoRecurrenceRule_Rule.weekly,
    4: ProtoRecurrenceRule_Rule.monthly,
    5: ProtoRecurrenceRule_Rule.yearly,
    0: ProtoRecurrenceRule_Rule.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoRecurrenceRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5])
    ..aOM<ProtoDailyRecurrence>(1, _omitFieldNames ? '' : 'daily',
        subBuilder: ProtoDailyRecurrence.create)
    ..aOM<ProtoEveryNDaysRecurrence>(2, _omitFieldNames ? '' : 'everyNDays',
        subBuilder: ProtoEveryNDaysRecurrence.create)
    ..aOM<ProtoWeeklyRecurrence>(3, _omitFieldNames ? '' : 'weekly',
        subBuilder: ProtoWeeklyRecurrence.create)
    ..aOM<ProtoMonthlyRecurrence>(4, _omitFieldNames ? '' : 'monthly',
        subBuilder: ProtoMonthlyRecurrence.create)
    ..aOM<ProtoYearlyRecurrence>(5, _omitFieldNames ? '' : 'yearly',
        subBuilder: ProtoYearlyRecurrence.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoRecurrenceRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoRecurrenceRule copyWith(void Function(ProtoRecurrenceRule) updates) =>
      super.copyWith((message) => updates(message as ProtoRecurrenceRule))
          as ProtoRecurrenceRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoRecurrenceRule create() => ProtoRecurrenceRule._();
  @$core.override
  ProtoRecurrenceRule createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoRecurrenceRule getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoRecurrenceRule>(create);
  static ProtoRecurrenceRule? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  ProtoRecurrenceRule_Rule whichRule() =>
      _ProtoRecurrenceRule_RuleByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  void clearRule() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ProtoDailyRecurrence get daily => $_getN(0);
  @$pb.TagNumber(1)
  set daily(ProtoDailyRecurrence value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDaily() => $_has(0);
  @$pb.TagNumber(1)
  void clearDaily() => $_clearField(1);
  @$pb.TagNumber(1)
  ProtoDailyRecurrence ensureDaily() => $_ensure(0);

  @$pb.TagNumber(2)
  ProtoEveryNDaysRecurrence get everyNDays => $_getN(1);
  @$pb.TagNumber(2)
  set everyNDays(ProtoEveryNDaysRecurrence value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasEveryNDays() => $_has(1);
  @$pb.TagNumber(2)
  void clearEveryNDays() => $_clearField(2);
  @$pb.TagNumber(2)
  ProtoEveryNDaysRecurrence ensureEveryNDays() => $_ensure(1);

  @$pb.TagNumber(3)
  ProtoWeeklyRecurrence get weekly => $_getN(2);
  @$pb.TagNumber(3)
  set weekly(ProtoWeeklyRecurrence value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasWeekly() => $_has(2);
  @$pb.TagNumber(3)
  void clearWeekly() => $_clearField(3);
  @$pb.TagNumber(3)
  ProtoWeeklyRecurrence ensureWeekly() => $_ensure(2);

  @$pb.TagNumber(4)
  ProtoMonthlyRecurrence get monthly => $_getN(3);
  @$pb.TagNumber(4)
  set monthly(ProtoMonthlyRecurrence value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMonthly() => $_has(3);
  @$pb.TagNumber(4)
  void clearMonthly() => $_clearField(4);
  @$pb.TagNumber(4)
  ProtoMonthlyRecurrence ensureMonthly() => $_ensure(3);

  @$pb.TagNumber(5)
  ProtoYearlyRecurrence get yearly => $_getN(4);
  @$pb.TagNumber(5)
  set yearly(ProtoYearlyRecurrence value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasYearly() => $_has(4);
  @$pb.TagNumber(5)
  void clearYearly() => $_clearField(5);
  @$pb.TagNumber(5)
  ProtoYearlyRecurrence ensureYearly() => $_ensure(4);
}

class ProtoTask extends $pb.GeneratedMessage {
  factory ProtoTask({
    $core.List<$core.int>? id,
    $core.String? title,
    $core.String? notes,
    $core.bool? isCompleted,
    $fixnum.Int64? createdAtMs,
    $fixnum.Int64? scheduledDateMs,
    ProtoRecurrenceRule? recurrence,
    $core.Iterable<$core.List<$core.int>>? tagIds,
    $core.List<$core.int>? listId,
    $core.List<$core.int>? previousTaskId,
    $core.List<$core.int>? nextTaskId,
    $core.Iterable<$fixnum.Int64>? completedDatesMs,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (title != null) result.title = title;
    if (notes != null) result.notes = notes;
    if (isCompleted != null) result.isCompleted = isCompleted;
    if (createdAtMs != null) result.createdAtMs = createdAtMs;
    if (scheduledDateMs != null) result.scheduledDateMs = scheduledDateMs;
    if (recurrence != null) result.recurrence = recurrence;
    if (tagIds != null) result.tagIds.addAll(tagIds);
    if (listId != null) result.listId = listId;
    if (previousTaskId != null) result.previousTaskId = previousTaskId;
    if (nextTaskId != null) result.nextTaskId = nextTaskId;
    if (completedDatesMs != null)
      result.completedDatesMs.addAll(completedDatesMs);
    return result;
  }

  ProtoTask._();

  factory ProtoTask.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoTask.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoTask',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'id', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'notes')
    ..aOB(4, _omitFieldNames ? '' : 'isCompleted')
    ..aInt64(5, _omitFieldNames ? '' : 'createdAtMs')
    ..aInt64(6, _omitFieldNames ? '' : 'scheduledDateMs')
    ..aOM<ProtoRecurrenceRule>(7, _omitFieldNames ? '' : 'recurrence',
        subBuilder: ProtoRecurrenceRule.create)
    ..p<$core.List<$core.int>>(
        8, _omitFieldNames ? '' : 'tagIds', $pb.PbFieldType.PY)
    ..a<$core.List<$core.int>>(
        9, _omitFieldNames ? '' : 'listId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        10, _omitFieldNames ? '' : 'previousTaskId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        11, _omitFieldNames ? '' : 'nextTaskId', $pb.PbFieldType.OY)
    ..p<$fixnum.Int64>(
        12, _omitFieldNames ? '' : 'completedDatesMs', $pb.PbFieldType.K6)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoTask clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoTask copyWith(void Function(ProtoTask) updates) =>
      super.copyWith((message) => updates(message as ProtoTask)) as ProtoTask;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoTask create() => ProtoTask._();
  @$core.override
  ProtoTask createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoTask getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ProtoTask>(create);
  static ProtoTask? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get id => $_getN(0);
  @$pb.TagNumber(1)
  set id($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get notes => $_getSZ(2);
  @$pb.TagNumber(3)
  set notes($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNotes() => $_has(2);
  @$pb.TagNumber(3)
  void clearNotes() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isCompleted => $_getBF(3);
  @$pb.TagNumber(4)
  set isCompleted($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsCompleted() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsCompleted() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get createdAtMs => $_getI64(4);
  @$pb.TagNumber(5)
  set createdAtMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCreatedAtMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedAtMs() => $_clearField(5);

  /// 0 means "not set" for optional timestamps
  @$pb.TagNumber(6)
  $fixnum.Int64 get scheduledDateMs => $_getI64(5);
  @$pb.TagNumber(6)
  set scheduledDateMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasScheduledDateMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearScheduledDateMs() => $_clearField(6);

  @$pb.TagNumber(7)
  ProtoRecurrenceRule get recurrence => $_getN(6);
  @$pb.TagNumber(7)
  set recurrence(ProtoRecurrenceRule value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasRecurrence() => $_has(6);
  @$pb.TagNumber(7)
  void clearRecurrence() => $_clearField(7);
  @$pb.TagNumber(7)
  ProtoRecurrenceRule ensureRecurrence() => $_ensure(6);

  @$pb.TagNumber(8)
  $pb.PbList<$core.List<$core.int>> get tagIds => $_getList(7);

  @$pb.TagNumber(9)
  $core.List<$core.int> get listId => $_getN(8);
  @$pb.TagNumber(9)
  set listId($core.List<$core.int> value) => $_setBytes(8, value);
  @$pb.TagNumber(9)
  $core.bool hasListId() => $_has(8);
  @$pb.TagNumber(9)
  void clearListId() => $_clearField(9);

  /// empty bytes means "not set"
  @$pb.TagNumber(10)
  $core.List<$core.int> get previousTaskId => $_getN(9);
  @$pb.TagNumber(10)
  set previousTaskId($core.List<$core.int> value) => $_setBytes(9, value);
  @$pb.TagNumber(10)
  $core.bool hasPreviousTaskId() => $_has(9);
  @$pb.TagNumber(10)
  void clearPreviousTaskId() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.List<$core.int> get nextTaskId => $_getN(10);
  @$pb.TagNumber(11)
  set nextTaskId($core.List<$core.int> value) => $_setBytes(10, value);
  @$pb.TagNumber(11)
  $core.bool hasNextTaskId() => $_has(10);
  @$pb.TagNumber(11)
  void clearNextTaskId() => $_clearField(11);

  @$pb.TagNumber(12)
  $pb.PbList<$fixnum.Int64> get completedDatesMs => $_getList(11);
}

class ProtoTaskList extends $pb.GeneratedMessage {
  factory ProtoTaskList({
    $core.List<$core.int>? id,
    $core.String? name,
    $core.bool? hasColor,
    $core.int? colorValue,
    $core.List<$core.int>? folderId,
    $core.int? order,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (hasColor != null) result.hasColor = hasColor;
    if (colorValue != null) result.colorValue = colorValue;
    if (folderId != null) result.folderId = folderId;
    if (order != null) result.order = order;
    return result;
  }

  ProtoTaskList._();

  factory ProtoTaskList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoTaskList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoTaskList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'id', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOB(3, _omitFieldNames ? '' : 'hasColor')
    ..aI(4, _omitFieldNames ? '' : 'colorValue')
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'folderId', $pb.PbFieldType.OY)
    ..aI(6, _omitFieldNames ? '' : 'order')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoTaskList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoTaskList copyWith(void Function(ProtoTaskList) updates) =>
      super.copyWith((message) => updates(message as ProtoTaskList))
          as ProtoTaskList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoTaskList create() => ProtoTaskList._();
  @$core.override
  ProtoTaskList createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoTaskList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoTaskList>(create);
  static ProtoTaskList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get id => $_getN(0);
  @$pb.TagNumber(1)
  set id($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  /// color_value = 0 and has_color = false means no color
  @$pb.TagNumber(3)
  $core.bool get hasColor => $_getBF(2);
  @$pb.TagNumber(3)
  set hasColor($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHasColor() => $_has(2);
  @$pb.TagNumber(3)
  void clearHasColor() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get colorValue => $_getIZ(3);
  @$pb.TagNumber(4)
  set colorValue($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasColorValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearColorValue() => $_clearField(4);

  /// empty bytes means "not set"
  @$pb.TagNumber(5)
  $core.List<$core.int> get folderId => $_getN(4);
  @$pb.TagNumber(5)
  set folderId($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFolderId() => $_has(4);
  @$pb.TagNumber(5)
  void clearFolderId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get order => $_getIZ(5);
  @$pb.TagNumber(6)
  set order($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOrder() => $_has(5);
  @$pb.TagNumber(6)
  void clearOrder() => $_clearField(6);
}

class ProtoFolder extends $pb.GeneratedMessage {
  factory ProtoFolder({
    $core.List<$core.int>? id,
    $core.String? name,
    $core.int? order,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (order != null) result.order = order;
    return result;
  }

  ProtoFolder._();

  factory ProtoFolder.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoFolder.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoFolder',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'id', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aI(3, _omitFieldNames ? '' : 'order')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoFolder clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoFolder copyWith(void Function(ProtoFolder) updates) =>
      super.copyWith((message) => updates(message as ProtoFolder))
          as ProtoFolder;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoFolder create() => ProtoFolder._();
  @$core.override
  ProtoFolder createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoFolder getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoFolder>(create);
  static ProtoFolder? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get id => $_getN(0);
  @$pb.TagNumber(1)
  set id($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get order => $_getIZ(2);
  @$pb.TagNumber(3)
  set order($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOrder() => $_has(2);
  @$pb.TagNumber(3)
  void clearOrder() => $_clearField(3);
}

class ProtoTag extends $pb.GeneratedMessage {
  factory ProtoTag({
    $core.List<$core.int>? id,
    $core.String? name,
    $core.int? colorValue,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (colorValue != null) result.colorValue = colorValue;
    return result;
  }

  ProtoTag._();

  factory ProtoTag.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoTag.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoTag',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'id', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aI(3, _omitFieldNames ? '' : 'colorValue')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoTag clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoTag copyWith(void Function(ProtoTag) updates) =>
      super.copyWith((message) => updates(message as ProtoTag)) as ProtoTag;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoTag create() => ProtoTag._();
  @$core.override
  ProtoTag createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoTag getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ProtoTag>(create);
  static ProtoTag? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get id => $_getN(0);
  @$pb.TagNumber(1)
  set id($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get colorValue => $_getIZ(2);
  @$pb.TagNumber(3)
  set colorValue($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasColorValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearColorValue() => $_clearField(3);
}

class ProtoTodayFilter extends $pb.GeneratedMessage {
  factory ProtoTodayFilter() => create();

  ProtoTodayFilter._();

  factory ProtoTodayFilter.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoTodayFilter.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoTodayFilter',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoTodayFilter clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoTodayFilter copyWith(void Function(ProtoTodayFilter) updates) =>
      super.copyWith((message) => updates(message as ProtoTodayFilter))
          as ProtoTodayFilter;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoTodayFilter create() => ProtoTodayFilter._();
  @$core.override
  ProtoTodayFilter createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoTodayFilter getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoTodayFilter>(create);
  static ProtoTodayFilter? _defaultInstance;
}

class ProtoTomorrowFilter extends $pb.GeneratedMessage {
  factory ProtoTomorrowFilter() => create();

  ProtoTomorrowFilter._();

  factory ProtoTomorrowFilter.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoTomorrowFilter.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoTomorrowFilter',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoTomorrowFilter clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoTomorrowFilter copyWith(void Function(ProtoTomorrowFilter) updates) =>
      super.copyWith((message) => updates(message as ProtoTomorrowFilter))
          as ProtoTomorrowFilter;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoTomorrowFilter create() => ProtoTomorrowFilter._();
  @$core.override
  ProtoTomorrowFilter createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoTomorrowFilter getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoTomorrowFilter>(create);
  static ProtoTomorrowFilter? _defaultInstance;
}

class ProtoUpcomingFilter extends $pb.GeneratedMessage {
  factory ProtoUpcomingFilter() => create();

  ProtoUpcomingFilter._();

  factory ProtoUpcomingFilter.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoUpcomingFilter.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoUpcomingFilter',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoUpcomingFilter clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoUpcomingFilter copyWith(void Function(ProtoUpcomingFilter) updates) =>
      super.copyWith((message) => updates(message as ProtoUpcomingFilter))
          as ProtoUpcomingFilter;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoUpcomingFilter create() => ProtoUpcomingFilter._();
  @$core.override
  ProtoUpcomingFilter createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoUpcomingFilter getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoUpcomingFilter>(create);
  static ProtoUpcomingFilter? _defaultInstance;
}

class ProtoOverdueFilter extends $pb.GeneratedMessage {
  factory ProtoOverdueFilter() => create();

  ProtoOverdueFilter._();

  factory ProtoOverdueFilter.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoOverdueFilter.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoOverdueFilter',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoOverdueFilter clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoOverdueFilter copyWith(void Function(ProtoOverdueFilter) updates) =>
      super.copyWith((message) => updates(message as ProtoOverdueFilter))
          as ProtoOverdueFilter;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoOverdueFilter create() => ProtoOverdueFilter._();
  @$core.override
  ProtoOverdueFilter createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoOverdueFilter getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoOverdueFilter>(create);
  static ProtoOverdueFilter? _defaultInstance;
}

class ProtoCompletedFilter extends $pb.GeneratedMessage {
  factory ProtoCompletedFilter() => create();

  ProtoCompletedFilter._();

  factory ProtoCompletedFilter.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoCompletedFilter.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoCompletedFilter',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoCompletedFilter clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoCompletedFilter copyWith(void Function(ProtoCompletedFilter) updates) =>
      super.copyWith((message) => updates(message as ProtoCompletedFilter))
          as ProtoCompletedFilter;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoCompletedFilter create() => ProtoCompletedFilter._();
  @$core.override
  ProtoCompletedFilter createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoCompletedFilter getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoCompletedFilter>(create);
  static ProtoCompletedFilter? _defaultInstance;
}

class ProtoAllTasksFilter extends $pb.GeneratedMessage {
  factory ProtoAllTasksFilter() => create();

  ProtoAllTasksFilter._();

  factory ProtoAllTasksFilter.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoAllTasksFilter.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoAllTasksFilter',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoAllTasksFilter clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoAllTasksFilter copyWith(void Function(ProtoAllTasksFilter) updates) =>
      super.copyWith((message) => updates(message as ProtoAllTasksFilter))
          as ProtoAllTasksFilter;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoAllTasksFilter create() => ProtoAllTasksFilter._();
  @$core.override
  ProtoAllTasksFilter createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoAllTasksFilter getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoAllTasksFilter>(create);
  static ProtoAllTasksFilter? _defaultInstance;
}

class ProtoDateRangeFilter extends $pb.GeneratedMessage {
  factory ProtoDateRangeFilter({
    $core.bool? hasDateFrom,
    $fixnum.Int64? dateFromMs,
    $core.bool? hasDateTo,
    $fixnum.Int64? dateToMs,
  }) {
    final result = create();
    if (hasDateFrom != null) result.hasDateFrom = hasDateFrom;
    if (dateFromMs != null) result.dateFromMs = dateFromMs;
    if (hasDateTo != null) result.hasDateTo = hasDateTo;
    if (dateToMs != null) result.dateToMs = dateToMs;
    return result;
  }

  ProtoDateRangeFilter._();

  factory ProtoDateRangeFilter.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoDateRangeFilter.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoDateRangeFilter',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'hasDateFrom')
    ..aInt64(2, _omitFieldNames ? '' : 'dateFromMs')
    ..aOB(3, _omitFieldNames ? '' : 'hasDateTo')
    ..aInt64(4, _omitFieldNames ? '' : 'dateToMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoDateRangeFilter clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoDateRangeFilter copyWith(void Function(ProtoDateRangeFilter) updates) =>
      super.copyWith((message) => updates(message as ProtoDateRangeFilter))
          as ProtoDateRangeFilter;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoDateRangeFilter create() => ProtoDateRangeFilter._();
  @$core.override
  ProtoDateRangeFilter createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoDateRangeFilter getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoDateRangeFilter>(create);
  static ProtoDateRangeFilter? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get hasDateFrom => $_getBF(0);
  @$pb.TagNumber(1)
  set hasDateFrom($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHasDateFrom() => $_has(0);
  @$pb.TagNumber(1)
  void clearHasDateFrom() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get dateFromMs => $_getI64(1);
  @$pb.TagNumber(2)
  set dateFromMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDateFromMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearDateFromMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get hasDateTo => $_getBF(2);
  @$pb.TagNumber(3)
  set hasDateTo($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHasDateTo() => $_has(2);
  @$pb.TagNumber(3)
  void clearHasDateTo() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get dateToMs => $_getI64(3);
  @$pb.TagNumber(4)
  set dateToMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDateToMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearDateToMs() => $_clearField(4);
}

class ProtoTagsFilter extends $pb.GeneratedMessage {
  factory ProtoTagsFilter({
    $core.Iterable<$core.List<$core.int>>? tagIds,
  }) {
    final result = create();
    if (tagIds != null) result.tagIds.addAll(tagIds);
    return result;
  }

  ProtoTagsFilter._();

  factory ProtoTagsFilter.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoTagsFilter.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoTagsFilter',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..p<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'tagIds', $pb.PbFieldType.PY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoTagsFilter clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoTagsFilter copyWith(void Function(ProtoTagsFilter) updates) =>
      super.copyWith((message) => updates(message as ProtoTagsFilter))
          as ProtoTagsFilter;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoTagsFilter create() => ProtoTagsFilter._();
  @$core.override
  ProtoTagsFilter createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoTagsFilter getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoTagsFilter>(create);
  static ProtoTagsFilter? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.List<$core.int>> get tagIds => $_getList(0);
}

enum ProtoSmartListFilter_Filter {
  today,
  tomorrow,
  upcoming,
  overdue,
  dateRange,
  tags,
  completed,
  all,
  notSet
}

class ProtoSmartListFilter extends $pb.GeneratedMessage {
  factory ProtoSmartListFilter({
    ProtoTodayFilter? today,
    ProtoTomorrowFilter? tomorrow,
    ProtoUpcomingFilter? upcoming,
    ProtoOverdueFilter? overdue,
    ProtoDateRangeFilter? dateRange,
    ProtoTagsFilter? tags,
    ProtoCompletedFilter? completed,
    ProtoAllTasksFilter? all,
  }) {
    final result = create();
    if (today != null) result.today = today;
    if (tomorrow != null) result.tomorrow = tomorrow;
    if (upcoming != null) result.upcoming = upcoming;
    if (overdue != null) result.overdue = overdue;
    if (dateRange != null) result.dateRange = dateRange;
    if (tags != null) result.tags = tags;
    if (completed != null) result.completed = completed;
    if (all != null) result.all = all;
    return result;
  }

  ProtoSmartListFilter._();

  factory ProtoSmartListFilter.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoSmartListFilter.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ProtoSmartListFilter_Filter>
      _ProtoSmartListFilter_FilterByTag = {
    1: ProtoSmartListFilter_Filter.today,
    2: ProtoSmartListFilter_Filter.tomorrow,
    3: ProtoSmartListFilter_Filter.upcoming,
    4: ProtoSmartListFilter_Filter.overdue,
    5: ProtoSmartListFilter_Filter.dateRange,
    6: ProtoSmartListFilter_Filter.tags,
    7: ProtoSmartListFilter_Filter.completed,
    8: ProtoSmartListFilter_Filter.all,
    0: ProtoSmartListFilter_Filter.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoSmartListFilter',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8])
    ..aOM<ProtoTodayFilter>(1, _omitFieldNames ? '' : 'today',
        subBuilder: ProtoTodayFilter.create)
    ..aOM<ProtoTomorrowFilter>(2, _omitFieldNames ? '' : 'tomorrow',
        subBuilder: ProtoTomorrowFilter.create)
    ..aOM<ProtoUpcomingFilter>(3, _omitFieldNames ? '' : 'upcoming',
        subBuilder: ProtoUpcomingFilter.create)
    ..aOM<ProtoOverdueFilter>(4, _omitFieldNames ? '' : 'overdue',
        subBuilder: ProtoOverdueFilter.create)
    ..aOM<ProtoDateRangeFilter>(5, _omitFieldNames ? '' : 'dateRange',
        subBuilder: ProtoDateRangeFilter.create)
    ..aOM<ProtoTagsFilter>(6, _omitFieldNames ? '' : 'tags',
        subBuilder: ProtoTagsFilter.create)
    ..aOM<ProtoCompletedFilter>(7, _omitFieldNames ? '' : 'completed',
        subBuilder: ProtoCompletedFilter.create)
    ..aOM<ProtoAllTasksFilter>(8, _omitFieldNames ? '' : 'all',
        subBuilder: ProtoAllTasksFilter.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoSmartListFilter clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoSmartListFilter copyWith(void Function(ProtoSmartListFilter) updates) =>
      super.copyWith((message) => updates(message as ProtoSmartListFilter))
          as ProtoSmartListFilter;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoSmartListFilter create() => ProtoSmartListFilter._();
  @$core.override
  ProtoSmartListFilter createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoSmartListFilter getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoSmartListFilter>(create);
  static ProtoSmartListFilter? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  ProtoSmartListFilter_Filter whichFilter() =>
      _ProtoSmartListFilter_FilterByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  void clearFilter() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ProtoTodayFilter get today => $_getN(0);
  @$pb.TagNumber(1)
  set today(ProtoTodayFilter value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasToday() => $_has(0);
  @$pb.TagNumber(1)
  void clearToday() => $_clearField(1);
  @$pb.TagNumber(1)
  ProtoTodayFilter ensureToday() => $_ensure(0);

  @$pb.TagNumber(2)
  ProtoTomorrowFilter get tomorrow => $_getN(1);
  @$pb.TagNumber(2)
  set tomorrow(ProtoTomorrowFilter value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTomorrow() => $_has(1);
  @$pb.TagNumber(2)
  void clearTomorrow() => $_clearField(2);
  @$pb.TagNumber(2)
  ProtoTomorrowFilter ensureTomorrow() => $_ensure(1);

  @$pb.TagNumber(3)
  ProtoUpcomingFilter get upcoming => $_getN(2);
  @$pb.TagNumber(3)
  set upcoming(ProtoUpcomingFilter value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasUpcoming() => $_has(2);
  @$pb.TagNumber(3)
  void clearUpcoming() => $_clearField(3);
  @$pb.TagNumber(3)
  ProtoUpcomingFilter ensureUpcoming() => $_ensure(2);

  @$pb.TagNumber(4)
  ProtoOverdueFilter get overdue => $_getN(3);
  @$pb.TagNumber(4)
  set overdue(ProtoOverdueFilter value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasOverdue() => $_has(3);
  @$pb.TagNumber(4)
  void clearOverdue() => $_clearField(4);
  @$pb.TagNumber(4)
  ProtoOverdueFilter ensureOverdue() => $_ensure(3);

  @$pb.TagNumber(5)
  ProtoDateRangeFilter get dateRange => $_getN(4);
  @$pb.TagNumber(5)
  set dateRange(ProtoDateRangeFilter value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasDateRange() => $_has(4);
  @$pb.TagNumber(5)
  void clearDateRange() => $_clearField(5);
  @$pb.TagNumber(5)
  ProtoDateRangeFilter ensureDateRange() => $_ensure(4);

  @$pb.TagNumber(6)
  ProtoTagsFilter get tags => $_getN(5);
  @$pb.TagNumber(6)
  set tags(ProtoTagsFilter value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasTags() => $_has(5);
  @$pb.TagNumber(6)
  void clearTags() => $_clearField(6);
  @$pb.TagNumber(6)
  ProtoTagsFilter ensureTags() => $_ensure(5);

  @$pb.TagNumber(7)
  ProtoCompletedFilter get completed => $_getN(6);
  @$pb.TagNumber(7)
  set completed(ProtoCompletedFilter value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasCompleted() => $_has(6);
  @$pb.TagNumber(7)
  void clearCompleted() => $_clearField(7);
  @$pb.TagNumber(7)
  ProtoCompletedFilter ensureCompleted() => $_ensure(6);

  @$pb.TagNumber(8)
  ProtoAllTasksFilter get all => $_getN(7);
  @$pb.TagNumber(8)
  set all(ProtoAllTasksFilter value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasAll() => $_has(7);
  @$pb.TagNumber(8)
  void clearAll() => $_clearField(8);
  @$pb.TagNumber(8)
  ProtoAllTasksFilter ensureAll() => $_ensure(7);
}

class ProtoSmartList extends $pb.GeneratedMessage {
  factory ProtoSmartList({
    $core.List<$core.int>? id,
    $core.String? name,
    $core.int? iconCodePoint,
    $core.int? colorValue,
    ProtoSmartListFilter? filter,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (iconCodePoint != null) result.iconCodePoint = iconCodePoint;
    if (colorValue != null) result.colorValue = colorValue;
    if (filter != null) result.filter = filter;
    return result;
  }

  ProtoSmartList._();

  factory ProtoSmartList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoSmartList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoSmartList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'id', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aI(3, _omitFieldNames ? '' : 'iconCodePoint')
    ..aI(4, _omitFieldNames ? '' : 'colorValue')
    ..aOM<ProtoSmartListFilter>(5, _omitFieldNames ? '' : 'filter',
        subBuilder: ProtoSmartListFilter.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoSmartList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoSmartList copyWith(void Function(ProtoSmartList) updates) =>
      super.copyWith((message) => updates(message as ProtoSmartList))
          as ProtoSmartList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoSmartList create() => ProtoSmartList._();
  @$core.override
  ProtoSmartList createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoSmartList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoSmartList>(create);
  static ProtoSmartList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get id => $_getN(0);
  @$pb.TagNumber(1)
  set id($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get iconCodePoint => $_getIZ(2);
  @$pb.TagNumber(3)
  set iconCodePoint($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIconCodePoint() => $_has(2);
  @$pb.TagNumber(3)
  void clearIconCodePoint() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get colorValue => $_getIZ(3);
  @$pb.TagNumber(4)
  set colorValue($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasColorValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearColorValue() => $_clearField(4);

  @$pb.TagNumber(5)
  ProtoSmartListFilter get filter => $_getN(4);
  @$pb.TagNumber(5)
  set filter(ProtoSmartListFilter value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasFilter() => $_has(4);
  @$pb.TagNumber(5)
  void clearFilter() => $_clearField(5);
  @$pb.TagNumber(5)
  ProtoSmartListFilter ensureFilter() => $_ensure(4);
}

class ProtoSyncIndex extends $pb.GeneratedMessage {
  factory ProtoSyncIndex({
    $core.Iterable<$core.MapEntry<$core.String, $fixnum.Int64>>? entities,
    $core.Iterable<$core.MapEntry<$core.String, $fixnum.Int64>>? deletions,
  }) {
    final result = create();
    if (entities != null) result.entities.addEntries(entities);
    if (deletions != null) result.deletions.addEntries(deletions);
    return result;
  }

  ProtoSyncIndex._();

  factory ProtoSyncIndex.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtoSyncIndex.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtoSyncIndex',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'todoonya'),
      createEmptyInstance: create)
    ..m<$core.String, $fixnum.Int64>(1, _omitFieldNames ? '' : 'entities',
        entryClassName: 'ProtoSyncIndex.EntitiesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.O6,
        packageName: const $pb.PackageName('todoonya'))
    ..m<$core.String, $fixnum.Int64>(2, _omitFieldNames ? '' : 'deletions',
        entryClassName: 'ProtoSyncIndex.DeletionsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.O6,
        packageName: const $pb.PackageName('todoonya'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoSyncIndex clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtoSyncIndex copyWith(void Function(ProtoSyncIndex) updates) =>
      super.copyWith((message) => updates(message as ProtoSyncIndex))
          as ProtoSyncIndex;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtoSyncIndex create() => ProtoSyncIndex._();
  @$core.override
  ProtoSyncIndex createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtoSyncIndex getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtoSyncIndex>(create);
  static ProtoSyncIndex? _defaultInstance;

  /// key (e.g. "tasks/abc-123") → last-modified timestamp in ms since epoch
  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, $fixnum.Int64> get entities => $_getMap(0);

  /// key → deletion timestamp in ms since epoch
  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $fixnum.Int64> get deletions => $_getMap(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
