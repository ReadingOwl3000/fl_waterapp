import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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

//might need replacing if the variables should be changed inside the app
int extra = 0;
int watergoal = 2000;
int glass = 500;
int get buttonsNumber {
  return ((watergoal / glass) + extra).round();
}

int drankToday = 0;
String defaultImage = 'assets/fullg.png';

class _MyHomePageState extends State<MyHomePage> {
  late List<String> buttonStates; // List to track the image of each button
  @override
  void initState() {
    super.initState();
    buttonStates =
        List<String>.filled(buttonsNumber, defaultImage, growable: true);
    readList(buttonStates); // re-assigns buttonsStates if possible
    readDT();
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
          buttonStates[i] = "assets/emptyg.png";
        }
      }
    });
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
  }

  Future<int> readDT() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      drankToday = prefs.getInt("drankToday") ?? 0;
    });
    return drankToday;
  }

  Future<void> writeDay(currentDay) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt("currentDay", currentDay);
  }

  Future<int> readDay(
    currentDay,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentDay = prefs.getInt("currentDay") ??
          0; //if no current day is stored it gives back 0
    });
    return currentDay;
  }

  void resetOnNewDay(int currentDay, newDay) {
    drankToday = 0;
    extra = 0;
    writeDT(drankToday);
    writeList(buttonStates);
    buttonStates =
        List<String>.filled(buttonsNumber, defaultImage, growable: true);
    writeList(buttonStates);
    Phoenix.rebirth(context);
  }

  Future<void> timeChecker(int drankToday, int extra) async {
    int currentDay = 0;
    readDay(currentDay);
    currentDay = await readDay(currentDay);
    writeDay(currentDay);
    DateTime newDate = DateTime.now();
    int newDay = newDate.day;
    if (newDay == currentDay) {
      return;
    } else {
      resetOnNewDay(currentDay, newDay);
      currentDay = newDay;
      writeDay(currentDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
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
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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