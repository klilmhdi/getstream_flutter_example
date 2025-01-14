class MeetingModel {
  final String meetID;
  final String creatorID;
  final String creatorName;
  final String receiverID;
  final String receiverName;
  final bool isActiveMeet;
  final DateTime startMeetAt;
  final DateTime? endMeetAt;
  final Duration meetDuration;

  MeetingModel({
    required this.meetID,
    required this.creatorID,
    required this.creatorName,
    required this.receiverID,
    required this.receiverName,
    required this.isActiveMeet,
    required this.startMeetAt,
    this.endMeetAt,
    this.meetDuration = Duration.zero,
  });

  Map<String, dynamic> toMap() {
    return {
      'meetID': meetID,
      'creatorID': creatorID,
      'creatorName': creatorName,
      'receiverID': receiverID,
      'receiverName': receiverName,
      'isActiveMeet': isActiveMeet,
      'startMeetAt': startMeetAt.toIso8601String(),
      'endMeetAt': endMeetAt?.toIso8601String(),
      'meetDuration': meetDuration.inSeconds,
    };
  }

  factory MeetingModel.fromMap(Map<String, dynamic> map) {
    return MeetingModel(
      meetID: map['meetID'],
      creatorID: map['creatorID'],
      creatorName: map['creatorName'],
      receiverID: map['receiverID'],
      receiverName: map['receiverName'],
      isActiveMeet: map['isActiveMeet'],
      startMeetAt: DateTime.parse(map['startMeetAt']),
      endMeetAt: map['endMeetAt'] != null ? DateTime.parse(map['endMeetAt']) : null,
      meetDuration: Duration(seconds: map['meetDuration'] ?? 0),
    );
  }

  MeetingModel copyWith({
    String? meetID,
    String? creatorID,
    String? creatorName,
    String? receiverID,
    String? receiverName,
    bool? isActiveMeet,
    DateTime? startMeetAt,
    DateTime? endMeetAt,
    Duration? meetDuration,
  }) =>
      MeetingModel(
        meetID: meetID ?? this.meetID,
        creatorID: creatorID ?? this.creatorID,
        creatorName: creatorName ?? this.creatorName,
        receiverID: receiverID ?? this.receiverID,
        receiverName: receiverName ?? this.receiverName,
        isActiveMeet: isActiveMeet ?? this.isActiveMeet,
        meetDuration: meetDuration ?? this.meetDuration,
        startMeetAt: startMeetAt ?? this.startMeetAt,
        endMeetAt: endMeetAt ?? this.endMeetAt,
      );
}
