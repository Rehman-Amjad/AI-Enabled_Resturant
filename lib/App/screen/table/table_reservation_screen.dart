import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TableReservationScreen extends StatefulWidget {
  @override
  _TableReservationScreenState createState() => _TableReservationScreenState();
}

class _TableReservationScreenState extends State<TableReservationScreen> {
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  int tableNumber = 1; // Default table number
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now().add(Duration(days: 1)); // Default to tomorrow
    selectedTime = TimeOfDay.now();
  }

  void _refreshTableAndTime() {
    setState(() {
      selectedDate = DateTime.now().add(Duration(days: 1));
      selectedTime = TimeOfDay.now();
      tableNumber = (tableNumber % 10) + 1; // Assuming 10 tables
    });
  }

  Future<bool> _isTableAlreadyBooked() async {
    DateTime reservationDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    QuerySnapshot query = await _firestore
        .collection('reservations')
        .where('tableNumber', isEqualTo: tableNumber)
        .where('reservationDate',
            isEqualTo: Timestamp.fromDate(reservationDateTime))
        .get();

    return query.docs.isNotEmpty;
  }

  Future<void> _bookTable() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    if (await _isTableAlreadyBooked()) {
      // If table is already booked, show a dialog or toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This table is already booked at the selected time.'),
        ),
      );
      return;
    }

    await _firestore.collection('reservations').add({
      'userId': user.uid,
      'tableNumber': tableNumber,
      'reservationDate': DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      ),
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Table booked successfully!'),
      ),
    );
  }

  Future<void> _cancelReservation(String reservationId) async {
    await _firestore.collection('reservations').doc(reservationId).delete();
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Table Reservation'),
        backgroundColor: Color(0xff6149cd),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text('Date'),
              subtitle: Text('${selectedDate.toLocal()}'.split(' ')[0]),
              trailing: Icon(Icons.calendar_today),
            ),
            ListTile(
              title: Text('Time'),
              subtitle: Text('${selectedTime.format(context)}'),
              trailing: Icon(Icons.access_time),
            ),
            ListTile(
              title: Text('Table Number'),
              subtitle: Text('$tableNumber'),
              trailing: Icon(Icons.table_bar),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Color(0xff6149cd)),
                  ),
                  onPressed: _refreshTableAndTime,
                  child: Text('Refresh'),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Color(0xff6149cd)),
                  ),
                  onPressed: _bookTable,
                  child: Text('Book'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Your Future Reservations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('reservations')
                    .where('userId', isEqualTo: user?.uid)
                    .where('reservationDate',
                        isGreaterThanOrEqualTo: Timestamp.now())
                    .orderBy('reservationDate')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  var reservations = snapshot.data!.docs;
                  if (reservations.isEmpty) {
                    return Center(child: Text('No future reservations'));
                  }
                  return ListView.builder(
                    itemCount: reservations.length,
                    itemBuilder: (context, index) {
                      var reservation = reservations[index];
                      var reservationDate =
                          reservation['reservationDate'].toDate();
                      return ListTile(
                        title: Text('Table ${reservation['tableNumber']}'),
                        subtitle: Text(
                            '${reservationDate.toLocal()} - ${TimeOfDay.fromDateTime(reservationDate).format(context)}'),
                        trailing: IconButton(
                          icon: Icon(Icons.cancel),
                          onPressed: () => _cancelReservation(reservation.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
