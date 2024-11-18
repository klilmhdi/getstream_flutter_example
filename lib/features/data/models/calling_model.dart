class CallingModel {
  final String callID;
  final String callerID;
  final String callerName;
  final String callingID;
  final String callingName;
  final bool isActiveCall;
  final bool isAccepted;
  final bool isRinging;
  dynamic callDuration;

  CallingModel({
    required this.callID,
    required this.callerID,
    required this.callerName,
    required this.callingID,
    required this.callingName,
    required this.isActiveCall,
    required this.isAccepted,
    required this.isRinging,
    this.callDuration,
  });

  // Convert a CallingModel object to a map for Firestore
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
      'callDuration': callDuration,
    };
  }

  // Create a CallingModel object from Firestore data
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
      callDuration: map['callDuration'],
    );
  }
}
