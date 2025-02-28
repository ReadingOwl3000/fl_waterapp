import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:fl_waterapp/utilities/notifications.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode:
          false // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
      );
//TODO: re-register reminder task here based on previous user input
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
  final myController =
      TextEditingController(); //needed for input widgets TODO move to dialog utils
  @override
  void initState() {
    permissions.isAndroidPermissionGranted();
    permissions.requestPermissions();
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
      case 'notification settings':
        dialogNotifications();
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

  void dialogNotifications() async {
    String gettingNotifs = await getNotifSettings();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            child: SizedBox(
                height: 500,
                width: 300,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text(
                          "Notification Settings",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Padding(padding: EdgeInsets.all(8)),
                        const Text(
                            "You can disable/enable notifications in your system settings"),
                        Text(gettingNotifs),
                        const Padding(padding: EdgeInsets.all(8)),

                        const Text("How often would you like to be reminded?"),
                        TextField(
                          controller: myController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'mintes between reminders (≥ 15)',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                        const Text(
                          "note: due to system limitations, this function has a minimum of 15min and might not be 100% accurate",
                          //: TextStyle(fontStyle: FontStyle.italic),
                          style: TextStyle(
                              fontSize: 10, fontStyle: FontStyle.italic),
                        ),
                        const Padding(padding: EdgeInsets.all(8)),
                        // const Text(
                        //     "Between which times would you like to get notifications?"),
                        //  const Padding(padding: EdgeInsets.all(8)),
                        TextButton(
                            onPressed: () {
                              int sleepBetweenNotifs =
                                  int.parse(myController.text);
                              if (sleepBetweenNotifs >= 15) {
                                saveNotificationSettings(sleepBetweenNotifs);

                                Navigator.pop(context);
                              } else {
                                showErrorDialog();
                              }
                            },
                            child: const Text("Save changes"))
                      ]),
                )));
      },
    );
  }

  void saveNotificationSettings(int sleepBetweenNotifs) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt("sleepBetweenNotifs", sleepBetweenNotifs);

    Workmanager().registerPeriodicTask(
      "reminder_",
      "reminder-task_",
      // When no frequency is provided the default 15 minutes is set.
      // Minimum frequency is 15 min. Android will automatically change your frequency to 15 min if you have configured a lower frequency.
      frequency: Duration(minutes: sleepBetweenNotifs),
    );
    //Workmanager().registerOneOffTask("1", "simpleTask", tag: "tag");
    print("task registerd");
  }

  Future<String> getNotifSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int? alreadySet = prefs.getInt("sleepBetweenNotifs");
    if (notificationsEnabled && alreadySet != null) {
      return "You are currently receiving notifications every ${prefs.getInt("sleepBetweenNotifs")} minutes";
    } else {
      return "You are not receiving notifications. Please input your preferred time and check your system settings";
    }
  }

  void showErrorDialog() {
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
                  const Text("This is an invalid input"),
                  TextButton(
                      onPressed: Navigator.of(context).pop,
                      child: const Text("Close")),
                ]),
          ));
        });
  }

  @override //
  void dispose() {
    // Clean up the controller (for input) when the widget is removed from the widget tree
    myController.dispose();
    super.dispose();
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
                  'notification settings',
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
