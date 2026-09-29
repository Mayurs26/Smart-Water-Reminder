class WaterIntake {
  final int? id;
  final int amount;
  final DateTime timestamp;
  final String date;

  WaterIntake({
    this.id,
    required this.amount,
    required this.timestamp,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'date': date,
    };
  }

  factory WaterIntake.fromMap(Map<String, dynamic> map) {
    return WaterIntake(
      id: map['id'] as int?,
      amount: map['amount'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      date: map['date'] as String,
    );
  }

  WaterIntake copyWith({
    int? id,
    int? amount,
    DateTime? timestamp,
    String? date,
  }) {
    return WaterIntake(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      date: date ?? this.date,
    );
  }

  @override
  String toString() {
    return 'WaterIntake(id: $id, amount: $amount, timestamp: $timestamp, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WaterIntake &&
        other.id == id &&
        other.amount == amount &&
        other.timestamp == timestamp &&
        other.date == date;
  }

  @override
  int get hashCode {
    return id.hashCode ^ amount.hashCode ^ timestamp.hashCode ^ date.hashCode;
  }
}