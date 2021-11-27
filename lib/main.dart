import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'dart:io'; //CUSTOM CHANGE

void main() {
  runApp(Home());
}

//Taken from https://github.com/tekartik/sqflite/blob/master/sqflite/doc/opening_asset_db.md
class DatabaseHelper {
  late Database db;
  var initialized = false;

  Future<Database> setupDatabase() async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, "yugiohPauper2.db");

    var exists = await databaseExists(path);
    print(exists);

    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load(join("assets", "yugiohPauper2.db"));
      List<int> bytes =
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await File(path).writeAsBytes(bytes, flush: true);
    } else {}

    var db = await openDatabase(path, readOnly: true);
    return db;
  }

  Future<void> _initialize() async {
    if(!initialized){
      db = await setupDatabase();
      initialized = true;
    }
  }

  Future<List<Map>> performSearch(String name, String description, String minAttack, String maxAttack,
      String minDefense, String maxDefense, String minLevel, String maxLevel, String minLinkRating,
      String maxLinkRating, String minPendulumScale, String maxPendulumScale, String attribute,
      String cardType, String race) async {
    List<Map> result = await db.rawQuery("SELECT * FROM cards WHERE "
        "name=?"
        "AND desc=?"
        "AND attribute=?"
        "AND race=?"
        "AND type=?"
        "AND atk >=?"
        "AND atk <=?"
        "AND def >=?"
        "AND def <=?"
        "AND level >=?"
        "AND level <=?"
        "AND linkRating >=?"
        "AND linkRating <=?"
        "AND pendulumScale >=?"
        "AND pendulumScale <=?",
        [name, description, attribute, race, cardType, minAttack, maxAttack, minDefense, maxDefense, minLevel, maxLevel,
        minLinkRating, maxLinkRating, minPendulumScale, maxPendulumScale]);
    return result;
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pauper Yugioh Home',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      home: SearchInput(),
    );
  }
}

class SearchResults extends StatelessWidget {
  const SearchResults({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pauper Yugioh Search Results',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      home: Results(),
    );
  }
}

class SearchInput extends StatefulWidget {
  const SearchInput({Key? key}) : super(key: key);

  @override
  _SearchInputState createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {

  DatabaseHelper dbHelper = DatabaseHelper();
  List<Map> results = [];

  List<String> attributes = [
    "Default",
    "Fire",
    "Water",
    "Earth",
    "Wind",
    "Light",
    "Dark",
    "Divine"
  ];
  List<String> races = [
    "Default",
    "Aqua",
    "Beast",
    "Beast-Warrior",
    "Cyberse",
    "Dinosaur",
    "Divine-Beast",
    "Dragon",
    "Fairy",
    "Fiend",
    "Fish",
    "Insect",
    "Machine",
    "Plant",
    "Psychic",
    "Pyro",
    "Reptile",
    "Rock",
    "Sea Serpent",
    "Spellcaster",
    "Thunder",
    "Warrior",
    "Winged Beast",
    "Wyrm",
    "Zombie",
    "Continuous",
    "Equip",
    "Field",
    "Normal",
    "Quick-Play",
    "Ritual",
    "Counter"
  ];
  List<String> cardTypes = [
    "Default",
    "Normal Monster",
    "Effect Monster",
    "XYZ Monster",
    "Flip Effect Monster",
    "Fusion Monster",
    "Gemini Monster",
    "Link Monster",
    "Normal Tuner",
    "Pendulum Effect Monster",
    "Pendulum Normal Monster",
    "Pendulum Tuner Effect Monster",
    "Ritual Effect Monster",
    "Ritual Monster",
    "Spell Card",
    "Synchro Monster",
    "Synchro Tuner Monster",
    "Spirit Monster",
    "Trap Card",
    "Tuner Monster",
    "Union Effect Monster"
  ];

  String attribute = "Default";
  String race = "Default";
  String cardType = "Default";
  String name = "Default";
  String description = "Default";
  String minAttack = "Default";
  String maxAttack = "Default";
  String minDefense = "Default";
  String maxDefense = "Default";
  String minLevel = "Default";
  String maxLevel = "Default";
  String minLinkRating = "Default";
  String maxLinkRating = "Default";
  String minPendulumScale = "Default";
  String maxPendulumScale = "Default";

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final minAttackController = TextEditingController();
  final maxAttackController = TextEditingController();
  final minDefenseController = TextEditingController();
  final maxDefenseController = TextEditingController();
  final minLevelController = TextEditingController();
  final maxLevelController = TextEditingController();
  final minLinkRatingController = TextEditingController();
  final maxLinkRatingController = TextEditingController();
  final minPendulumScaleController = TextEditingController();
  final maxPendulumScaleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pauper Yu-Gi-Oh Search"),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(child: _searchInterface())),
    );
  }

  Widget _searchInterface() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _dropdownButtons(_changeAttribute, attribute, attributes),
          _dropdownButtons(_changeRace, race, races),
          _dropdownButtons(_changeCardType, cardType, cardTypes),
          Row(
            children: [const Text("Name"), _tinyTextField(nameController)],
          ),
          Row(
            children: [
              const Text("Description"),
              _tinyTextField(descriptionController)
            ],
          ),
          Row(
            children: [
              _tinyTextField(minAttackController),
              const Text("≤ Attack ≤"),
              _tinyTextField(maxAttackController)
            ],
          ),
          Row(
            children: [
              _tinyTextField(minDefenseController),
              const Text("≤ Defense ≤"),
              _tinyTextField(maxDefenseController)
            ],
          ),
          Row(
            children: [
              _tinyTextField(minLevelController),
              const Text("≤ Level/Rank ≤"),
              _tinyTextField(maxLevelController)
            ],
          ),
          Row(
            children: [
              _tinyTextField(minLinkRatingController),
              const Text("≤ Link Rating ≤"),
              _tinyTextField(maxLinkRatingController)
            ],
          ),
          Row(
            children: [
              _tinyTextField(minPendulumScaleController),
              const Text("≤ Pendulum Scale ≤"),
              _tinyTextField(maxPendulumScaleController)
            ],
          ),
          ElevatedButton(
            child: const Text('Search'),
            onPressed: () async {
              dbHelper._initialize();
              getVariables();
              dbHelper.performSearch(name, description, minAttack, maxAttack, minDefense, maxDefense, minLevel, maxLevel,
              minLinkRating, maxLinkRating, minPendulumScale, maxPendulumScale, attribute, cardType, race);
              Navigator.push(
                  this.context,
                  MaterialPageRoute(builder: (context) => const SearchResults())
              );
            }
          ),
        ]);
  }

  //Generates a dropdown button with the default value of currentValue and a list of values from allValues
  Widget _dropdownButtons(Function valueChanger, String updatedValue, List<String> allValues) {
    return DropdownButton<String>(
      value: updatedValue,
      items: allValues.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          valueChanger(newValue);
        });
      },
    );
  }

  void _changeAttribute(String newValue){
    attribute = newValue;
  }

  void _changeCardType(String newValue){
    cardType = newValue;
  }

  void _changeRace(String newValue){
    race = newValue;
  }

  Widget _tinyTextField(TextEditingController textController) {
    return SizedBox(
        width: 100,
        child: TextField(
            focusNode: FocusNode(canRequestFocus: false),
            controller: textController,
            decoration: InputDecoration(border: OutlineInputBorder())));
  }

  void getVariables(){
    name = nameController.text;
    description = descriptionController.text;
    minAttack = minAttackController.text;
    maxAttack = maxAttackController.text;
    minDefense = minDefenseController.text;
    maxDefense = maxDefenseController.text;
    minLevel = minLevelController.text;
    maxLevel = maxLevelController.text;
    minLinkRating = minLinkRatingController.text;
    maxLinkRating = maxLinkRatingController.text;
    minPendulumScale = minPendulumScaleController.text;
    maxPendulumScale = maxPendulumScaleController.text;
  }
}

class Results extends StatefulWidget {
  const Results({Key? key}) : super(key: key);

  @override
  _ResultsState createState() => _ResultsState();
}

class _ResultsState extends State<Results> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pauper Yu-Gi-Oh Results"),
      ),
      body: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemBuilder: (BuildContext context, int index) {
            return Container(
              child: _individualResult()
            );
          }
      )
    );
  }

  Widget _individualResult(){
    return(
      Column(
        children: <Widget>[
          Text("Name"),
          Text("Description"),
          Text("Attribute"),
          Text("Level or Rank"),
          Text("Type"),
          Text("Card Type"),
          Text("Attack"),
          Text("Defense"),
          Text("Link Rating"),
          Text("Pendulum Scales")
        ],
      )
    );
  }
}



