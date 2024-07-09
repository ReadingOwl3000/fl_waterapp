import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'dart:async';

void main() {
  runApp( 
    Phoenix(child: 
      const MyApp())
  
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
  // This widget is the home page of your application. 
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
  
//might need replacing if the variables should be changed inside the app
  int extra = 0;
  int watergoal = 2000;
  int glass = 500;
  int get buttonsNumber { return ((watergoal / glass)+ extra ).round(); }
  int drankToday = 0;
  String defaultImage = 'assets/fullg.png';


class _MyHomePageState extends State<MyHomePage> {
  //
  //
  late List<String> buttonStates; // List to track the image of each button

  @override
  void initState() {
    super.initState();
    buttonStates = List<String>.filled(buttonsNumber, defaultImage, growable: true);
  }

  

  void _waterCounter() {
    setState(() {
      
        drankToday= drankToday + glass;

    });
  }

  void makeButtons() {
    setState(() {
      extra += 1;
     // drankToday += glass;
      buttonStates.add(defaultImage);
    });
  }
  
   void _toggleButtonState(int index) {
    setState(() {
      //buttonStates[index] = "assets/emptyg.png";
      setState((){
      for (int i = 0; i < buttonsNumber; i++) {
                        if (i == index) {
                          buttonStates[i] = "assets/emptyg.png"; // Change pressed image path here
                        } 
                        } 
    });

      }
    );
   }
  

  void timeChecker() {
    DateTime nowDate =DateTime.now();
    
    int currentDay = nowDate.day;
    //if current day changes rebuild the thing 
    Timer.periodic(const Duration(minutes: 5), (timer) {
      //print(currentDay,);
      DateTime newDate = DateTime.now();
      int newDay = newDate.day;
      if (newDay == currentDay){}
      else {Phoenix.rebirth(context);}



    }
    );


  }


  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
              const Text(
                'You drank this much today:)' ,
              ),
              Text(
                '$drankToday',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Number of columns in the grid
                mainAxisSpacing: 5.0,
                crossAxisSpacing: 5.0,
                childAspectRatio: 1.1,),
                 // Adjust the aspect ratio to make buttons look good, 
              itemCount: buttonsNumber,
              itemBuilder: (context, index) {
                return TextButton(
                  onPressed: () {
                    if (buttonStates[index] == defaultImage){
                      _waterCounter();}
                    _toggleButtonState(index);
                    //timeChecker();
                   
                 },
                    child:
                        Image.asset(buttonStates[index]),
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
      ), // This trailing comma makes auto-formatting nicer for build methods.
    //];
    );
  }
}

//problem scheint zu sein dass bei add glass die liste nicht länger wird, dh liste muss auf jeden fall neu 
//aufgerfuen/gesettet werden (setstate?) ggf auch variablen aber an sich sollten die fine sein