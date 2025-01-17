import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handle background notification tap
  print('Notification tapped in background: ${notificationResponse.payload}');
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
const InitializationSettings initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/launcher_icon'),
    linux: initializationSettingsLinux);

const LinuxInitializationSettings initializationSettingsLinux =
    LinuxInitializationSettings(defaultActionName: 'Open notification');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) async {},
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
  runApp(Phoenix(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'How much did you drink today?',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'How much did you drink today?'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

int extra = 0;
int watergoal = 2000;
int glass = 500;
int get buttonsNumber {
  return ((watergoal / glass) + extra).round();
}

int drankToday = 0;
String defaultImage = 'assets/fullg.png';
String emptyImage = "assets/emptyg.png";

class _MyHomePageState extends State<MyHomePage> {
  late List<String> buttonStates; // List to track the image of each button
  final myController = TextEditingController(); //needed for input widgets
  @override
  void initState() {
    _isAndroidPermissionGranted();
    _requestPermissions();
    super.initState();
    buttonStates =
        List<String>.filled(buttonsNumber, defaultImage, growable: true);
    readList(buttonStates); // re-assigns buttonsStates if possible
    readDT();
    readHistroy();
    getPrefs(); //changes watergoal and glass to saved user settings
    setState(() {
      timeChecker(drankToday, extra); //checks date
    });
  }

  bool _notificationsEnabled = false;

  Future<void> _isAndroidPermissionGranted() async {
    final bool granted = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled() ??
        false;

    setState(() {
      _notificationsEnabled = granted;
    });
  }

  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final bool? grantedNotificationPermission =
        await androidImplementation?.requestNotificationsPermission();
    setState(() {
      _notificationsEnabled = grantedNotificationPermission ?? false;
    });
  }

  void _waterCounter() {
    setState(() {
      drankToday = drankToday + glass;
    });
  }

  List<String> makeButtons() {
    setState(() {
      extra += 1;
      buttonStates.add(defaultImage);
    });
    return buttonStates;
  }

  void _toggleButtonState(int index) {
    setState(() {
      for (int i = 0; i < buttonStates.length; i++) {
        if (i == index) {
          buttonStates[i] = emptyImage;
        }
      }
    });
  }

  Future<void> getPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    watergoal = prefs.getInt("watergoal") ?? 2000;
    glass = prefs.getInt("glass") ?? 500;
    emptyImage = prefs.getString("emptyI") ?? emptyImage;
    defaultImage = prefs.getString("fullI") ?? defaultImage;
  }

  Future<void> writePrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt("watergoal", watergoal);
    await prefs.setInt("glass", glass);
    await prefs.setString("emptyI", emptyImage);
    await prefs.setString("fullI", defaultImage);
  }

  Future<void> writeList(List<String> buttonStates) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("buttonStates", buttonStates);
  }

  Future<List<String>> readList(List<String> buttonsStates) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      buttonStates = prefs.getStringList("buttonStates") ?? buttonStates;
    });
    return buttonStates;
  }

  Future<void> writeDT(drankToday) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt("drankToday", drankToday);
    DateTime dateTimeN = DateTime.now();
    await prefs.setString(
        "date", "${dateTimeN.year}-${dateTimeN.month}-${dateTimeN.day}");
  }

  Future<int> readDT() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      drankToday = prefs.getInt("drankToday") ?? 0;
    });
    return drankToday;
  }

  Future<String> readLastLoggedDate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String lastLoggedDate = "future";
    setState(() {
      lastLoggedDate = prefs.getString("date") ?? "error";
    });
    return lastLoggedDate;
  }

  Future<void> writeDay(lastLoggedDay) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt("lastLoggedDay", lastLoggedDay);
  }

  Future<int> readDay() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int lastLoggedDay = prefs.getInt("lastLoggedDay") ?? 0;
    //if no current day is stored it gives back 0
    return lastLoggedDay;
  }

  void resetOnNewDay(int lastLoggedDay, newDay) {
    writeHistory(drankToday);
    drankToday = 0;
    extra = 0;
    writeDT(drankToday);
    buttonStates =
        List<String>.filled(buttonsNumber, defaultImage, growable: true);
    writeList(buttonStates);
    Phoenix.rebirth(context);
  }

  Future<void> timeChecker(int drankToday, int extra) async {
    int lastLoggedDay = await readDay();
    writeDay(lastLoggedDay);
    DateTime newDate = DateTime.now();
    int newDay = newDate.day;
    if (newDay == lastLoggedDay) {
      return;
    } else {
      resetOnNewDay(lastLoggedDay, newDay);
      lastLoggedDay = newDay;
      writeDay(lastLoggedDay);
    }
  }

  void onClicked(String value) {
    switch (value) {
      case 'change goal':
        inpuDialogGoal();
        break;
      case 'change glass size':
        inpuDialogGlass();
        break;
      case 'change icon theme':
        inpuDialogTheme();
        break;
      case 'Show History':
        showHistory(context);
        break;
    }
  }

  void inpuDialogGoal() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: SizedBox(
              height: 200,
              width: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text("How much do you want to drink a day?"),
                  TextField(
                    controller: myController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter your daily goal (ml)',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (!(myController.text == "")) {
                          watergoal = int.parse(myController.text);
                          writePrefs();
                          setState(() {
                            buttonStates = List<String>.filled(
                                buttonsNumber, defaultImage,
                                growable: true);
                            for (int i = 0; i < drankToday / glass; i++) {
                              //if (i == index) {
                              buttonStates[i] = emptyImage;
                            }
                          });
                          writeList(buttonStates);
                        }
                      },
                      child: const Text("Apply"))
                ],
              ),
            ),
          );
        });
  }

  void inpuDialogGlass() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: SizedBox(
              height: 200,
              width: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text("How big is one glass ?"),
                  TextField(
                    controller: myController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter your glass size (ml)',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (!(myController.text == "")) {
                          glass = int.parse(myController.text);
                          writePrefs();
                          setState(() {
                            buttonStates = List<String>.filled(
                                buttonsNumber, defaultImage,
                                growable: true);
                            for (int i = 0; i < drankToday / glass; i++) {
                              //if (i == index) {
                              buttonStates[i] = emptyImage;
                            }
                          });
                          writeList(buttonStates);
                        }
                      },
                      child: const Text("Apply"))
                ],
              ),
            ),
          );
        });
  }

  Future writeHistory(drankToday) async {
    List<String> userHistory = await readHistroy();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String dateToday = await readLastLoggedDate();
    if (drankToday != 0) {
      userHistory.insert(0,
          "$dateToday : $drankToday"); //values from yesterday, written before daily reset
      await prefs.setStringList("History", userHistory);
    }
  }

  Future<List<String>> readHistroy() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> userHistory = prefs.getStringList("History") ?? [];
    return userHistory;
  }

  void showHistory(BuildContext context) async {
    final localContext =
        context; //stores context locally so no issues occur bc of awaiting
    List userHistory = await readHistroy();
    if (localContext.mounted) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              child: SizedBox(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                    ),
                    const Text("This is your history:"),
                    Expanded(
                      child: ListView.builder(
                          itemCount: userHistory.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(userHistory[index]),
                            );
                          }),
                    ),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("Close"))
                  ],
                ),
              ),
            );
          });
    }
  }

  void inpuDialogTheme() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: SizedBox(
              height: 300,
              width: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text("Choose your icon theme:"),
                  TextButton(
                      onPressed: () {
                        defaultImage = "assets/fullg.png";
                        emptyImage = "assets/emptyg.png";
                      },
                      child: const Text("Default theme (water)")),
                  TextButton(
                      onPressed: () {
                        defaultImage = "assets/fullbubbletea.png";
                        emptyImage = "assets/emptybubbletea.png";
                      },
                      child: const Text("Bubbletea ")),
                  TextButton(
                      onPressed: () {
                        defaultImage = "assets/fulltea.png";
                        emptyImage = "assets/emptytea.png";
                      },
                      child: const Text("Teacup")),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        writePrefs();
                        setState(() {
                          buttonStates = List<String>.filled(
                              buttonsNumber, defaultImage,
                              growable: true);
                          for (int i = 0; i < drankToday / glass; i++) {
                            //if (i == index) {
                            buttonStates[i] = emptyImage;
                          }
                        });
                        writeList(buttonStates);
                      },
                      child: const Text("Apply"))
                ],
              ),
            ),
          );
        });
  }

  @override //
  void dispose() {
    // Clean up the controller (for input) when the widget is removed from the widget tree
    myController.dispose();
    super.dispose();
  }

// Test notification scheduling function
  Future<void> scheduleTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'reminder_channel_id', // Unique ID for the channel
      'Reminder Channel', // Channel name
      channelDescription: 'Channel for reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Remember to drink enough water!', // Title
      'You have reached ${drankToday / watergoal * 100}% of your daily goal', // Body
      notificationDetails,
      payload: 'reminder', // Data associated with the notification
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: <Widget>[
          PopupMenuButton<String>(
              onSelected: onClicked,
              itemBuilder: (BuildContext context) {
                return {
                  'change goal',
                  'change glass size',
                  'change icon theme',
                  '',
                  'Show History',
                }.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              }),
        ],
      ),
      body: Column(
        children: [
          const Text(
            'You drank this much today:)',
          ),
          Text(
            '$drankToday ',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          TextButton(
              onPressed: () async {
                // Schedule a notification
                await scheduleTestNotification();
              },
              child: const Text("test message")),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Number of columns in the grid
                mainAxisSpacing: 5.0,
                crossAxisSpacing: 5.0,
                childAspectRatio: 1.1,
              ),
              // Adjust the aspect ratio to make buttons look good,
              itemCount: buttonStates.length,
              itemBuilder: (context, index) {
                return TextButton(
                  onPressed: () {
                    if (buttonStates[index] == defaultImage) {
                      //print("pressed");
                      _waterCounter();
                      _toggleButtonState(index);
                      writeList(buttonStates);
                      writeDT(drankToday);
                    }
                  },
                  child: Image.asset(buttonStates[index]),
                );
              },
            ),
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: makeButtons,
        tooltip: 'add glass',
        child: const Icon(Icons.add),
      ), //];
    );
  }
}
