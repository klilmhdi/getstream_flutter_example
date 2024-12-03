class MeetingModel {
  final String meetID;
  final String creatorID;
  final String creatorName;
  final String receiverID;
  final String receiverName;
  final bool isActiveMeet;

  MeetingModel({
    required this.meetID,
    required this.creatorID,
    required this.creatorName,
    required this.receiverID,
    required this.receiverName,
    required this.isActiveMeet,
  });

  MeetingModel copyWith({
    String? meetID,
    String? creatorID,
    String? creatorName,
    String? receiverID,
    String? receiverName,
    bool? isActiveMeet,
  }) => MeetingModel(
      meetID: meetID ?? this.meetID,
      creatorID: creatorID ?? this.creatorID,
      creatorName: creatorName ?? this.creatorName,
      receiverID: receiverID ?? this.receiverID,
      receiverName: receiverName ?? this.receiverName,
      isActiveMeet: isActiveMeet ?? this.isActiveMeet,
    );


  // Convert a MeetingModel object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'meetID': meetID,
      'creatorID': creatorID,
      'creatorName': creatorName,
      'receiverID': receiverID,
      'receiverName': receiverName,
      'isActiveMeet': isActiveMeet,
    };
  }

  // Create a MeetingModel object from Firestore data
  factory MeetingModel.fromMap(Map<String, dynamic> map) {
    return MeetingModel(
      meetID: map['meetID'],
      creatorID: map['creatorID'],
      creatorName: map['creatorName'],
      receiverID: map['receiverID'],
      receiverName: map['receiverName'],
      isActiveMeet: map['isActiveMeet'],
    );
  }
}
