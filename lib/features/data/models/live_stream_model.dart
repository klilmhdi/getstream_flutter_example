class LiveStreamModel {
  final String id;
  final String title;
  final String creatorId;
  final String creatorName;
  final bool isLive;
  final Duration duration;
  final DateTime startTime;
  final DateTime? endTime;
  final List<String> subscriptionsId;
  final List<String> subscriptionsName;

  LiveStreamModel({
    required this.id,
    required this.title,
    required this.creatorId,
    required this.creatorName,
    required this.startTime,
    this.endTime,
    this.isLive = true,
    this.duration = Duration.zero,
    this.subscriptionsId = const [],
    this.subscriptionsName = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'isLive': isLive,
      'duration': duration.inSeconds,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'subscriptionsId': subscriptionsId,
      'subscriptionsName': subscriptionsName,
    };
  }

  factory LiveStreamModel.fromMap(Map<String, dynamic> map) {
    return LiveStreamModel(
      id: map['id'],
      title: map['title'],
      creatorId: map['creatorId'],
      creatorName: map['creatorName'],
      isLive: map['isLive'],
      duration: Duration(seconds: map['duration'] ?? 0),
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      subscriptionsId: List<String>.from(map['subscriptionsId'] ?? []),
      subscriptionsName: List<String>.from(map['subscriptionsName'] ?? []),
    );
  }

  LiveStreamModel copyWith({
    String? id,
    String? title,
    String? creatorId,
    String? creatorName,
    bool? isLive,
    Duration? duration,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? subscriptionsId,
    List<String>? subscriptionsName,
  }) {
    return LiveStreamModel(
      id: id ?? this.id,
      title: title ?? this.title,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      isLive: isLive ?? this.isLive,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subscriptionsId: subscriptionsId ?? this.subscriptionsId,
      subscriptionsName: subscriptionsName ?? this.subscriptionsName,
    );
  }
}