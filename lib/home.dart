import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:page_animation_transition/animations/right_to_left_transition.dart';
import 'package:page_animation_transition/page_animation_transition.dart';
import 'package:timetabel/landing.dart';
import 'package:timetabel/takedata.dart';

class HomeApp extends StatefulWidget {
  const HomeApp({Key? key}) : super(key: key);

  @override
  State<HomeApp> createState() => _HomeAppState();
}

class _HomeAppState extends State<HomeApp> {
  String day = 'Monday';
  late Stream<QuerySnapshot> ttstream;
  final Map<String, String> _dayAbbreviationMap = {
    'Mon': 'Monday',
    'Tue': 'Tuesday',
    'Wed': 'Wednesday',
    'Thu': 'Thursday',
    'Fri': 'Friday',
    'Sat': 'Saturday',
  };
  String? userId;
  final Set<String> _expandedTiles = {};

  @override
  void initState() {
    super.initState();
    _initDataAndStream();
  }

  void _initDataAndStream() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // This should be handled by the LandingPage, but as a safeguard:
      return;
    }
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (mounted) {
      if (userDoc.exists) {
        setState(() {
          userId = userDoc['id'];
          _updateStream();
        });
      } else {
        // This indicates a data inconsistency. A logged-in user should have a user document.
        // Signing out to force a clean login/registration flow.
        print('Error: User document does not exist for UID: ${user.uid}');
        await FirebaseAuth.instance.signOut();
        Fluttertoast.showToast(msg: 'User data not found. Please log in again.');
      }
    }
  }

  void _updateStream() {
    if (userId != null) {
      ttstream = FirebaseFirestore.instance
          .collection('timetable')
          .doc(userId)
          .collection(day)
          .orderBy('startTime')
          .snapshots();
    }
  }

  String _getCurrentDayOfWeek() {
    // DateTime.now().weekday returns 1 for Monday and 7 for Sunday.
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[DateTime.now().weekday - 1];
  }

  Future<bool> _isFriendInClass(String friendId) async {
    try {
      final now = DateTime.now();
      final dayOfWeek = _getCurrentDayOfWeek();
      final currentTimeInMinutes = now.hour * 60 + now.minute;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('timetable')
          .doc(friendId)
          .collection(dayOfWeek)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false; // No classes today for this friend.
      }

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final startTimeString = data['startTime'] as String?;
        final endTimeString = data['endTime'] as String?;

        if (startTimeString == null || endTimeString == null) continue;

        final startTimeParts = startTimeString.split(':');
        final endTimeParts = endTimeString.split(':');

        if (startTimeParts.length != 2 || endTimeParts.length != 2) continue;

        final startHour = int.tryParse(startTimeParts[0]);
        final startMinute = int.tryParse(startTimeParts[1]);
        final endHour = int.tryParse(endTimeParts[0]);
        final endMinute = int.tryParse(endTimeParts[1]);

        if (startHour == null || startMinute == null || endHour == null || endMinute == null) continue;

        final classStartInMinutes = startHour * 60 + startMinute;
        final classEndInMinutes = endHour * 60 + endMinute;

        if (currentTimeInMinutes >= classStartInMinutes && currentTimeInMinutes < classEndInMinutes) {
          return true; // Friend is in a class.
        }
      }
    } catch (e) {
      print('Error checking friend status for $friendId: $e');
      return false; // Assume not in class on error
    }
    return false; // Friend is not in any class right now.
  }

  String _formatTimeForDisplay(String? timeString, BuildContext context) {
    if (timeString == null) return 'N/A';
    try {
      final parts = timeString.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute).format(context);
    } catch (e) {
      // If parsing fails (e.g., for old data), return the original string.
      return timeString;
    }
  }

  Future<void> _deleteClass(String documentId) async {
    if (userId == null) {
      Fluttertoast.showToast(msg: 'Error: User not identified.');
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('timetable')
          .doc(userId)
          .collection(day)
          .doc(documentId)
          .delete();

      Fluttertoast.showToast(
        msg: "Class deleted successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error deleting class: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.white70),
            softWrap: true,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFFF5ECED),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFFF5ECED),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onDoubleTap: () async {
                            await FirebaseAuth.instance.signOut();
                            Fluttertoast.showToast(msg: 'Done');
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>LandingPage()));

                          },
                          child: Text(
                            'Timetable',
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(PageAnimationTransition(
                                page: AddTimetablePage(),
                                pageAnimationType: RightToLeftTransition()));
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: Icon(Icons.add),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _dayAbbreviationMap.keys.map((abbr) => daybox(abbr)).toList(),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: userId == null
                    ? Container(
                        color: Color(0xFFF5ECED),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: ttstream,
                        builder: (BuildContext context,
                            AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.hasError) {
                            return Container(
                                color: Color(0xFFF5ECED),
                                child: Center(child: Text('Something went wrong')));
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                                color: Color(0xFFF5ECED),
                                child: Center(child: CircularProgressIndicator()));
                          }
                          if (snapshot.data!.docs.isEmpty) {
                            return Container(
                                color: Color(0xFFF5ECED),
                                child: Center(child: Text('No schedule for $day.')));
                          }
                          return Container(
                            color: Color(0xFFF5ECED),
                            child: ListView(
                              padding: EdgeInsets.all(8.0),
                              children: snapshot.data!.docs
                                  .map((DocumentSnapshot document) {
                                Map<String, dynamic> data =
                                    document.data() as Map<String, dynamic>;
                                final documentId = document.id;
                                final isExpanded = _expandedTiles.contains(documentId);
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(begin: Alignment.topLeft,end: Alignment.bottomRight,colors: [Color(0xFF141E30),Color(0xFF243B55)]),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  margin: EdgeInsets.symmetric(vertical: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: ExpansionTile(
                                      key: PageStorageKey(documentId),
                                      title: Text(
                                        data['className'] ?? 'No Subject',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        'Time: ${_formatTimeForDisplay(data['startTime'], context)} - ${_formatTimeForDisplay(data['endTime'], context)}',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      onExpansionChanged: (bool expanded) {
                                        setState(() {
                                          if (expanded) {
                                            _expandedTiles.add(documentId);
                                          } else {
                                            _expandedTiles.remove(documentId);
                                          }
                                        });
                                      },
                                      initiallyExpanded: isExpanded,
                                      collapsedIconColor: Colors.white,
                                      iconColor: Colors.white,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Divider(color: Colors.white30),
                                              SizedBox(height: 8),
                                              _buildDetailRow('Room:', data['roomNumber'] ?? 'N/A'),
                                              SizedBox(height: 4),
                                              _buildDetailRow('Teacher:', data['teacherName']?.isNotEmpty == true ? data['teacherName'] : 'N/A'),
                                              SizedBox(height: 4),
                                              _buildDetailRow('Type:', data['classType'] ?? 'N/A'),
                                              SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  TextButton.icon(
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (BuildContext ctx) => AlertDialog(
                                                          backgroundColor: Color(0xFF243B55),
                                                          title: Text('Confirm Delete', style: TextStyle(color: Colors.white)),
                                                          content: Text('Are you sure you want to delete this class?', style: TextStyle(color: Colors.white70)),
                                                          actions: <Widget>[
                                                            TextButton(
                                                              child: Text('Cancel', style: TextStyle(color: Colors.white)),
                                                              onPressed: () => Navigator.of(ctx).pop(),
                                                            ),
                                                            TextButton(
                                                              child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                                              onPressed: () {
                                                                Navigator.of(ctx).pop();
                                                                _deleteClass(document.id);
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                    icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                                                    label: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
              ),
              Expanded(
                flex:2,
                child: Container(
                  padding: EdgeInsets.all(15),
                  margin:EdgeInsets.all(5) ,
                  width: double.infinity,
                  decoration: BoxDecoration(
          
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(begin: Alignment.topLeft,end: Alignment.bottomRight,colors: [Color(0xFF141E30),Color(0xFF243B55)],)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Friends',style: TextStyle(color: Colors.white,fontSize: 30,fontWeight: FontWeight.bold,),),
                          
                          GestureDetector(
                            onTap: () {
                              _showTextInputDialog(context);
                            },
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                shape: BoxShape.circle
                              ),
                              child: Icon(Icons.add,color: Colors.white,)
                              ),
                          )
                        ],
                      ),
                      
                      Container(
                        width: double.infinity,
                        height: 2,
                        color: Colors.grey,
                      ),
                        SizedBox(height: 10),

                        StreamBuilder(
                        stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .collection('friends')
                          .snapshots(),
                        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                          return Center(child: Text('Error loading friends'));
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('No friends added yet.', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
                          );
                          }
                          return Expanded(
                          child: ListView(
                            children: snapshot.data!.docs.map((doc) {
                            final friendId = (doc.data() as Map<String, dynamic>)['fid'] as String?;
                            final data = doc.data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                              padding: EdgeInsets.all(3),
                              height: 30,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${doc['Name'].toString().toUpperCase()}',style: TextStyle(color: Colors.white),),
                                  FutureBuilder<bool>(
                                    future: friendId != null ? _isFriendInClass(friendId) : Future.value(false),
                                    builder: (context, statusSnapshot) {
                                      Color statusColor = Colors.grey; // Default/loading color
                                      if (statusSnapshot.connectionState == ConnectionState.done) {
                                        // Check if the future completed successfully and returned true
                                        if (statusSnapshot.hasData && statusSnapshot.data == true) {
                                          statusColor = Colors.red; // In class
                                        } else {
                                          statusColor = Colors.green; // Not in class (or an error occurred)
                                        }
                                      }
                                      return Container(
                                        width: 15,
                                        height: 15,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    },
                                  )
                                ],
                              ),
                              ),
                            );
                            }).toList(),
                          ),
                          );
                        },
                        )

          
          
          
          
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showTextInputDialog(BuildContext context) {
    TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF141E30), Color(0xFF243B55)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Friend',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: textController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Student ID (Should be capital)',
                    hintStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    SizedBox(width: 10),
                    TextButton(
                      child: const Text('OK', style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        String enteredText = textController.text;
                        String friendName = '';
                        try {
                          QuerySnapshot<Map<String, dynamic>> querySnapshot =
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .where('id', isEqualTo: enteredText)
                                  .get();
                          if (querySnapshot.docs.isNotEmpty) {
                            friendName = querySnapshot.docs.first.data()['name'] ?? '';
                          }
                        } catch (e) {
                          friendName = '';
                        }
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .collection('friends')
                            .add({
                              'fid': enteredText,
                              'Name': friendName,
                            });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget daybox(String s) {
    bool isSelected = day == _dayAbbreviationMap[s];

    return GestureDetector(
      onTap: () {
        setState(() {
          day = _dayAbbreviationMap[s]!;
          _updateStream();
        });
      },
      child: Container(
        padding: EdgeInsets.all(8),
        margin: EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_month_outlined, size: 30),
            Text(
              s,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}