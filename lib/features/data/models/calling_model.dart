class CallingModel {
  final String callID;
  final String callerID;
  final String callerName;
  final String callingID;
  final String callingName;
  final bool isActiveCall;
  final bool isAccepted;
  final bool isRinging;
  final DateTime startAt;
  final DateTime? endAt;
  final Duration callDuration;

  CallingModel({
    required this.callID,
    required this.callerID,
    required this.callerName,
    required this.callingID,
    required this.callingName,
    required this.isActiveCall,
    required this.isAccepted,
    required this.isRinging,
    required this.startAt,
    this.endAt,
    this.callDuration = Duration.zero,
  });

  Map<String, dynamic> toMap() {
    return {
      'callID': callID,
      'callerID': callerID,
      'callerName': callerName,
      'callingID': callingID,
      'callingName': callingName,
      'isActiveCall': isActiveCall,
      'isAccepted': isAccepted,
      'isRinging': isRinging,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
      'callDuration': callDuration.inSeconds,
    };
  }

  factory CallingModel.fromMap(Map<String, dynamic> map) {
    return CallingModel(
      callID: map['callID'],
      callerID: map['callerID'],
      callerName: map['callerName'],
      callingID: map['callingID'],
      callingName: map['callingName'],
      isActiveCall: map['isActiveCall'],
      isAccepted: map['isAccepted'],
      isRinging: map['isRinging'],
      startAt: DateTime.parse(map['startAt']),
      endAt: map['endAt'] != null ? DateTime.parse(map['endAt']) : null,
      callDuration: Duration(seconds: map['callDuration'] ?? 0),
    );
  }

  CallingModel copyWith({
    String? callID,
    String? callerID,
    String? callerName,
    String? callingID,
    String? callingName,
    bool? isActiveCall,
    bool? isAccepted,
    bool? isRinging,
    DateTime? startAt,
    DateTime? endAt,
    Duration? callDuration,
  }) {
    return CallingModel(
      callID: callID ?? this.callID,
      callerID: callerID ?? this.callerID,
      callerName: callerName ?? this.callerName,
      callingID: callingID ?? this.callingID,
      callingName: callingName ?? this.callingName,
      isActiveCall: isActiveCall ?? this.isActiveCall,
      isAccepted: isAccepted ?? this.isAccepted,
      isRinging: isRinging ?? this.isRinging,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      callDuration: callDuration ?? this.callDuration,
    );
  }
}
