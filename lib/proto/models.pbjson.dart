// This is a generated file - do not edit.
//
// Generated from models.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use protoDailyRecurrenceDescriptor instead')
const ProtoDailyRecurrence$json = {
  '1': 'ProtoDailyRecurrence',
};

/// Descriptor for `ProtoDailyRecurrence`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoDailyRecurrenceDescriptor =
    $convert.base64Decode('ChRQcm90b0RhaWx5UmVjdXJyZW5jZQ==');

@$core.Deprecated('Use protoEveryNDaysRecurrenceDescriptor instead')
const ProtoEveryNDaysRecurrence$json = {
  '1': 'ProtoEveryNDaysRecurrence',
  '2': [
    {'1': 'interval', '3': 1, '4': 1, '5': 5, '10': 'interval'},
  ],
};

/// Descriptor for `ProtoEveryNDaysRecurrence`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoEveryNDaysRecurrenceDescriptor =
    $convert.base64Decode(
        'ChlQcm90b0V2ZXJ5TkRheXNSZWN1cnJlbmNlEhoKCGludGVydmFsGAEgASgFUghpbnRlcnZhbA'
        '==');

@$core.Deprecated('Use protoWeeklyRecurrenceDescriptor instead')
const ProtoWeeklyRecurrence$json = {
  '1': 'ProtoWeeklyRecurrence',
  '2': [
    {'1': 'weekdayBits', '3': 1, '4': 1, '5': 5, '10': 'weekdayBits'},
  ],
};

/// Descriptor for `ProtoWeeklyRecurrence`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoWeeklyRecurrenceDescriptor = $convert.base64Decode(
    'ChVQcm90b1dlZWtseVJlY3VycmVuY2USIAoLd2Vla2RheUJpdHMYASABKAVSC3dlZWtkYXlCaX'
    'Rz');

@$core.Deprecated('Use protoMonthlyRecurrenceDescriptor instead')
const ProtoMonthlyRecurrence$json = {
  '1': 'ProtoMonthlyRecurrence',
  '2': [
    {'1': 'day_of_month', '3': 1, '4': 1, '5': 5, '10': 'dayOfMonth'},
  ],
};

/// Descriptor for `ProtoMonthlyRecurrence`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoMonthlyRecurrenceDescriptor =
    $convert.base64Decode(
        'ChZQcm90b01vbnRobHlSZWN1cnJlbmNlEiAKDGRheV9vZl9tb250aBgBIAEoBVIKZGF5T2ZNb2'
        '50aA==');

@$core.Deprecated('Use protoYearlyRecurrenceDescriptor instead')
const ProtoYearlyRecurrence$json = {
  '1': 'ProtoYearlyRecurrence',
  '2': [
    {'1': 'month', '3': 1, '4': 1, '5': 5, '10': 'month'},
    {'1': 'day_of_month', '3': 2, '4': 1, '5': 5, '10': 'dayOfMonth'},
  ],
};

/// Descriptor for `ProtoYearlyRecurrence`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoYearlyRecurrenceDescriptor = $convert.base64Decode(
    'ChVQcm90b1llYXJseVJlY3VycmVuY2USFAoFbW9udGgYASABKAVSBW1vbnRoEiAKDGRheV9vZl'
    '9tb250aBgCIAEoBVIKZGF5T2ZNb250aA==');

@$core.Deprecated('Use protoRecurrenceRuleDescriptor instead')
const ProtoRecurrenceRule$json = {
  '1': 'ProtoRecurrenceRule',
  '2': [
    {
      '1': 'daily',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.todoonya.ProtoDailyRecurrence',
      '9': 0,
      '10': 'daily'
    },
    {
      '1': 'every_n_days',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.todoonya.ProtoEveryNDaysRecurrence',
      '9': 0,
      '10': 'everyNDays'
    },
    {
      '1': 'weekly',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.todoonya.ProtoWeeklyRecurrence',
      '9': 0,
      '10': 'weekly'
    },
    {
      '1': 'monthly',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.todoonya.ProtoMonthlyRecurrence',
      '9': 0,
      '10': 'monthly'
    },
    {
      '1': 'yearly',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.todoonya.ProtoYearlyRecurrence',
      '9': 0,
      '10': 'yearly'
    },
  ],
  '8': [
    {'1': 'rule'},
  ],
};

/// Descriptor for `ProtoRecurrenceRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoRecurrenceRuleDescriptor = $convert.base64Decode(
    'ChNQcm90b1JlY3VycmVuY2VSdWxlEjYKBWRhaWx5GAEgASgLMh4udG9kb29ueWEuUHJvdG9EYW'
    'lseVJlY3VycmVuY2VIAFIFZGFpbHkSRwoMZXZlcnlfbl9kYXlzGAIgASgLMiMudG9kb29ueWEu'
    'UHJvdG9FdmVyeU5EYXlzUmVjdXJyZW5jZUgAUgpldmVyeU5EYXlzEjkKBndlZWtseRgDIAEoCz'
    'IfLnRvZG9vbnlhLlByb3RvV2Vla2x5UmVjdXJyZW5jZUgAUgZ3ZWVrbHkSPAoHbW9udGhseRgE'
    'IAEoCzIgLnRvZG9vbnlhLlByb3RvTW9udGhseVJlY3VycmVuY2VIAFIHbW9udGhseRI5CgZ5ZW'
    'FybHkYBSABKAsyHy50b2Rvb255YS5Qcm90b1llYXJseVJlY3VycmVuY2VIAFIGeWVhcmx5QgYK'
    'BHJ1bGU=');

@$core.Deprecated('Use protoTaskDescriptor instead')
const ProtoTask$json = {
  '1': 'ProtoTask',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 12, '10': 'id'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'notes', '3': 3, '4': 1, '5': 9, '10': 'notes'},
    {'1': 'is_completed', '3': 4, '4': 1, '5': 8, '10': 'isCompleted'},
    {'1': 'created_at_ms', '3': 5, '4': 1, '5': 3, '10': 'createdAtMs'},
    {'1': 'scheduled_date_ms', '3': 6, '4': 1, '5': 3, '10': 'scheduledDateMs'},
    {
      '1': 'recurrence',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.todoonya.ProtoRecurrenceRule',
      '10': 'recurrence'
    },
    {'1': 'tag_ids', '3': 8, '4': 3, '5': 12, '10': 'tagIds'},
    {'1': 'list_id', '3': 9, '4': 1, '5': 12, '10': 'listId'},
    {'1': 'previous_task_id', '3': 10, '4': 1, '5': 12, '10': 'previousTaskId'},
    {'1': 'next_task_id', '3': 11, '4': 1, '5': 12, '10': 'nextTaskId'},
    {
      '1': 'completed_dates_ms',
      '3': 12,
      '4': 3,
      '5': 3,
      '10': 'completedDatesMs'
    },
  ],
};

/// Descriptor for `ProtoTask`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoTaskDescriptor = $convert.base64Decode(
    'CglQcm90b1Rhc2sSDgoCaWQYASABKAxSAmlkEhQKBXRpdGxlGAIgASgJUgV0aXRsZRIUCgVub3'
    'RlcxgDIAEoCVIFbm90ZXMSIQoMaXNfY29tcGxldGVkGAQgASgIUgtpc0NvbXBsZXRlZBIiCg1j'
    'cmVhdGVkX2F0X21zGAUgASgDUgtjcmVhdGVkQXRNcxIqChFzY2hlZHVsZWRfZGF0ZV9tcxgGIA'
    'EoA1IPc2NoZWR1bGVkRGF0ZU1zEj0KCnJlY3VycmVuY2UYByABKAsyHS50b2Rvb255YS5Qcm90'
    'b1JlY3VycmVuY2VSdWxlUgpyZWN1cnJlbmNlEhcKB3RhZ19pZHMYCCADKAxSBnRhZ0lkcxIXCg'
    'dsaXN0X2lkGAkgASgMUgZsaXN0SWQSKAoQcHJldmlvdXNfdGFza19pZBgKIAEoDFIOcHJldmlv'
    'dXNUYXNrSWQSIAoMbmV4dF90YXNrX2lkGAsgASgMUgpuZXh0VGFza0lkEiwKEmNvbXBsZXRlZF'
    '9kYXRlc19tcxgMIAMoA1IQY29tcGxldGVkRGF0ZXNNcw==');

@$core.Deprecated('Use protoTaskListDescriptor instead')
const ProtoTaskList$json = {
  '1': 'ProtoTaskList',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 12, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'has_color', '3': 3, '4': 1, '5': 8, '10': 'hasColor'},
    {'1': 'color_value', '3': 4, '4': 1, '5': 5, '10': 'colorValue'},
    {'1': 'folder_id', '3': 5, '4': 1, '5': 12, '10': 'folderId'},
    {'1': 'order', '3': 6, '4': 1, '5': 5, '10': 'order'},
  ],
};

/// Descriptor for `ProtoTaskList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoTaskListDescriptor = $convert.base64Decode(
    'Cg1Qcm90b1Rhc2tMaXN0Eg4KAmlkGAEgASgMUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEhsKCW'
    'hhc19jb2xvchgDIAEoCFIIaGFzQ29sb3ISHwoLY29sb3JfdmFsdWUYBCABKAVSCmNvbG9yVmFs'
    'dWUSGwoJZm9sZGVyX2lkGAUgASgMUghmb2xkZXJJZBIUCgVvcmRlchgGIAEoBVIFb3JkZXI=');

@$core.Deprecated('Use protoFolderDescriptor instead')
const ProtoFolder$json = {
  '1': 'ProtoFolder',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 12, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'order', '3': 3, '4': 1, '5': 5, '10': 'order'},
  ],
};

/// Descriptor for `ProtoFolder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoFolderDescriptor = $convert.base64Decode(
    'CgtQcm90b0ZvbGRlchIOCgJpZBgBIAEoDFICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIUCgVvcm'
    'RlchgDIAEoBVIFb3JkZXI=');

@$core.Deprecated('Use protoTagDescriptor instead')
const ProtoTag$json = {
  '1': 'ProtoTag',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 12, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'color_value', '3': 3, '4': 1, '5': 5, '10': 'colorValue'},
  ],
};

/// Descriptor for `ProtoTag`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoTagDescriptor = $convert.base64Decode(
    'CghQcm90b1RhZxIOCgJpZBgBIAEoDFICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIfCgtjb2xvcl'
    '92YWx1ZRgDIAEoBVIKY29sb3JWYWx1ZQ==');

@$core.Deprecated('Use protoTodayFilterDescriptor instead')
const ProtoTodayFilter$json = {
  '1': 'ProtoTodayFilter',
};

/// Descriptor for `ProtoTodayFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoTodayFilterDescriptor =
    $convert.base64Decode('ChBQcm90b1RvZGF5RmlsdGVy');

@$core.Deprecated('Use protoTomorrowFilterDescriptor instead')
const ProtoTomorrowFilter$json = {
  '1': 'ProtoTomorrowFilter',
};

/// Descriptor for `ProtoTomorrowFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoTomorrowFilterDescriptor =
    $convert.base64Decode('ChNQcm90b1RvbW9ycm93RmlsdGVy');

@$core.Deprecated('Use protoUpcomingFilterDescriptor instead')
const ProtoUpcomingFilter$json = {
  '1': 'ProtoUpcomingFilter',
};

/// Descriptor for `ProtoUpcomingFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoUpcomingFilterDescriptor =
    $convert.base64Decode('ChNQcm90b1VwY29taW5nRmlsdGVy');

@$core.Deprecated('Use protoOverdueFilterDescriptor instead')
const ProtoOverdueFilter$json = {
  '1': 'ProtoOverdueFilter',
};

/// Descriptor for `ProtoOverdueFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoOverdueFilterDescriptor =
    $convert.base64Decode('ChJQcm90b092ZXJkdWVGaWx0ZXI=');

@$core.Deprecated('Use protoCompletedFilterDescriptor instead')
const ProtoCompletedFilter$json = {
  '1': 'ProtoCompletedFilter',
};

/// Descriptor for `ProtoCompletedFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoCompletedFilterDescriptor =
    $convert.base64Decode('ChRQcm90b0NvbXBsZXRlZEZpbHRlcg==');

@$core.Deprecated('Use protoAllTasksFilterDescriptor instead')
const ProtoAllTasksFilter$json = {
  '1': 'ProtoAllTasksFilter',
};

/// Descriptor for `ProtoAllTasksFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoAllTasksFilterDescriptor =
    $convert.base64Decode('ChNQcm90b0FsbFRhc2tzRmlsdGVy');

@$core.Deprecated('Use protoDateRangeFilterDescriptor instead')
const ProtoDateRangeFilter$json = {
  '1': 'ProtoDateRangeFilter',
  '2': [
    {'1': 'has_date_from', '3': 1, '4': 1, '5': 8, '10': 'hasDateFrom'},
    {'1': 'date_from_ms', '3': 2, '4': 1, '5': 3, '10': 'dateFromMs'},
    {'1': 'has_date_to', '3': 3, '4': 1, '5': 8, '10': 'hasDateTo'},
    {'1': 'date_to_ms', '3': 4, '4': 1, '5': 3, '10': 'dateToMs'},
  ],
};

/// Descriptor for `ProtoDateRangeFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoDateRangeFilterDescriptor = $convert.base64Decode(
    'ChRQcm90b0RhdGVSYW5nZUZpbHRlchIiCg1oYXNfZGF0ZV9mcm9tGAEgASgIUgtoYXNEYXRlRn'
    'JvbRIgCgxkYXRlX2Zyb21fbXMYAiABKANSCmRhdGVGcm9tTXMSHgoLaGFzX2RhdGVfdG8YAyAB'
    'KAhSCWhhc0RhdGVUbxIcCgpkYXRlX3RvX21zGAQgASgDUghkYXRlVG9Ncw==');

@$core.Deprecated('Use protoTagsFilterDescriptor instead')
const ProtoTagsFilter$json = {
  '1': 'ProtoTagsFilter',
  '2': [
    {'1': 'tag_ids', '3': 1, '4': 3, '5': 12, '10': 'tagIds'},
  ],
};

/// Descriptor for `ProtoTagsFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoTagsFilterDescriptor = $convert
    .base64Decode('Cg9Qcm90b1RhZ3NGaWx0ZXISFwoHdGFnX2lkcxgBIAMoDFIGdGFnSWRz');

@$core.Deprecated('Use protoSmartListFilterDescriptor instead')
const ProtoSmartListFilter$json = {
  '1': 'ProtoSmartListFilter',
  '2': [
    {
      '1': 'today',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.todoonya.ProtoTodayFilter',
      '9': 0,
      '10': 'today'
    },
    {
      '1': 'tomorrow',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.todoonya.ProtoTomorrowFilter',
      '9': 0,
      '10': 'tomorrow'
    },
    {
      '1': 'upcoming',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.todoonya.ProtoUpcomingFilter',
      '9': 0,
      '10': 'upcoming'
    },
    {
      '1': 'overdue',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.todoonya.ProtoOverdueFilter',
      '9': 0,
      '10': 'overdue'
    },
    {
      '1': 'date_range',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.todoonya.ProtoDateRangeFilter',
      '9': 0,
      '10': 'dateRange'
    },
    {
      '1': 'tags',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.todoonya.ProtoTagsFilter',
      '9': 0,
      '10': 'tags'
    },
    {
      '1': 'completed',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.todoonya.ProtoCompletedFilter',
      '9': 0,
      '10': 'completed'
    },
    {
      '1': 'all',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.todoonya.ProtoAllTasksFilter',
      '9': 0,
      '10': 'all'
    },
  ],
  '8': [
    {'1': 'filter'},
  ],
};

/// Descriptor for `ProtoSmartListFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoSmartListFilterDescriptor = $convert.base64Decode(
    'ChRQcm90b1NtYXJ0TGlzdEZpbHRlchIyCgV0b2RheRgBIAEoCzIaLnRvZG9vbnlhLlByb3RvVG'
    '9kYXlGaWx0ZXJIAFIFdG9kYXkSOwoIdG9tb3Jyb3cYAiABKAsyHS50b2Rvb255YS5Qcm90b1Rv'
    'bW9ycm93RmlsdGVySABSCHRvbW9ycm93EjsKCHVwY29taW5nGAMgASgLMh0udG9kb29ueWEuUH'
    'JvdG9VcGNvbWluZ0ZpbHRlckgAUgh1cGNvbWluZxI4CgdvdmVyZHVlGAQgASgLMhwudG9kb29u'
    'eWEuUHJvdG9PdmVyZHVlRmlsdGVySABSB292ZXJkdWUSPwoKZGF0ZV9yYW5nZRgFIAEoCzIeLn'
    'RvZG9vbnlhLlByb3RvRGF0ZVJhbmdlRmlsdGVySABSCWRhdGVSYW5nZRIvCgR0YWdzGAYgASgL'
    'MhkudG9kb29ueWEuUHJvdG9UYWdzRmlsdGVySABSBHRhZ3MSPgoJY29tcGxldGVkGAcgASgLMh'
    '4udG9kb29ueWEuUHJvdG9Db21wbGV0ZWRGaWx0ZXJIAFIJY29tcGxldGVkEjEKA2FsbBgIIAEo'
    'CzIdLnRvZG9vbnlhLlByb3RvQWxsVGFza3NGaWx0ZXJIAFIDYWxsQggKBmZpbHRlcg==');

@$core.Deprecated('Use protoSmartListDescriptor instead')
const ProtoSmartList$json = {
  '1': 'ProtoSmartList',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 12, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'icon_code_point', '3': 3, '4': 1, '5': 5, '10': 'iconCodePoint'},
    {'1': 'color_value', '3': 4, '4': 1, '5': 5, '10': 'colorValue'},
    {
      '1': 'filter',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.todoonya.ProtoSmartListFilter',
      '10': 'filter'
    },
  ],
};

/// Descriptor for `ProtoSmartList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoSmartListDescriptor = $convert.base64Decode(
    'Cg5Qcm90b1NtYXJ0TGlzdBIOCgJpZBgBIAEoDFICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRImCg'
    '9pY29uX2NvZGVfcG9pbnQYAyABKAVSDWljb25Db2RlUG9pbnQSHwoLY29sb3JfdmFsdWUYBCAB'
    'KAVSCmNvbG9yVmFsdWUSNgoGZmlsdGVyGAUgASgLMh4udG9kb29ueWEuUHJvdG9TbWFydExpc3'
    'RGaWx0ZXJSBmZpbHRlcg==');

@$core.Deprecated('Use protoSyncIndexDescriptor instead')
const ProtoSyncIndex$json = {
  '1': 'ProtoSyncIndex',
  '2': [
    {
      '1': 'entities',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.todoonya.ProtoSyncIndex.EntitiesEntry',
      '10': 'entities'
    },
    {
      '1': 'deletions',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.todoonya.ProtoSyncIndex.DeletionsEntry',
      '10': 'deletions'
    },
  ],
  '3': [ProtoSyncIndex_EntitiesEntry$json, ProtoSyncIndex_DeletionsEntry$json],
};

@$core.Deprecated('Use protoSyncIndexDescriptor instead')
const ProtoSyncIndex_EntitiesEntry$json = {
  '1': 'EntitiesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 3, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use protoSyncIndexDescriptor instead')
const ProtoSyncIndex_DeletionsEntry$json = {
  '1': 'DeletionsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 3, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `ProtoSyncIndex`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protoSyncIndexDescriptor = $convert.base64Decode(
    'Cg5Qcm90b1N5bmNJbmRleBJCCghlbnRpdGllcxgBIAMoCzImLnRvZG9vbnlhLlByb3RvU3luY0'
    'luZGV4LkVudGl0aWVzRW50cnlSCGVudGl0aWVzEkUKCWRlbGV0aW9ucxgCIAMoCzInLnRvZG9v'
    'bnlhLlByb3RvU3luY0luZGV4LkRlbGV0aW9uc0VudHJ5UglkZWxldGlvbnMaOwoNRW50aXRpZX'
    'NFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoA1IFdmFsdWU6AjgBGjwKDkRl'
    'bGV0aW9uc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgDUgV2YWx1ZToCOA'
    'E=');
