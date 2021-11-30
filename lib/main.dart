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
    if (!initialized) {
      db = await setupDatabase();
      initialized = true;
    }
  }

  Future<List<Map>> performSearch(
      String name,
      String description,
      String minAttack,
      String maxAttack,
      String minDefense,
      String maxDefense,
      String minLevel,
      String maxLevel,
      String minLinkRating,
      String maxLinkRating,
      String minPendulumScale,
      String maxPendulumScale,
      String attribute,
      String cardType,
      String race) async {
    List<Map> result;

    String queryString =
        "SELECT * FROM cards WHERE name LIKE ? AND desc LIKE ? AND race LIKE ? AND type LIKE ?";

    if (attribute == "%") {
      queryString = "$queryString AND (attribute LIKE ? or attribute is NULL)";
    } else {
      queryString = "$queryString AND attribute LIKE ?";
    }
    if (minAttack == "-1" && maxAttack == "100000") {
      queryString =
          "$queryString AND (atk >=? or atk is NULL) AND (atk <=? or atk is NULL)";
    } else {
      queryString = "$queryString AND atk >=? AND atk <=?";
    }
    if (minDefense == "-1" && maxDefense == "100000") {
      queryString =
          "$queryString AND (def >=? or def is NULL) AND (def <=? or def is NULL)";
    } else {
      queryString = "$queryString AND def >=? AND def <=?";
    }
    if (minLevel == "-1" && maxLevel == "100000") {
      queryString =
          "$queryString AND (level >=? or level is NULL) AND (level <=? or level is NULL)";
    } else {
      queryString = "$queryString AND level >=? AND level <=?";
    }
    if (minLinkRating == "-1" || maxLinkRating == "100000") {
      queryString =
          "$queryString AND (linkRating >=? or linkRating is NULL) AND (linkRating <=? or linkRating is NULL)";
    } else {
      queryString = "$queryString AND linkRating >=? AND linkRating <=?";
    }
    if (minPendulumScale == "-1" || maxPendulumScale == "100000") {
      queryString =
          "$queryString AND (pendulumScale >=? or pendulumScale is NULL) AND (pendulumScale <=? or pendulumScale is NULL)";
    } else {
      queryString = "$queryString AND pendulumScale >=? AND pendulumScale <=?";
    }
/* search anything
    List<Map> result = await db.rawQuery("SELECT * FROM cards WHERE "
        "name LIKE ?"
        "AND desc LIKE ?"
        "AND attribute LIKE ?"
        "AND race LIKE ?"
        "AND type LIKE ?"
        "AND (atk >=? or atk is NULL)"
        "AND (atk <=?  or atk is NULL)"
        "AND (def >=? or def is NULL)"
        "AND (def <=? or def is NULL)"
        "AND (level >=? or level is NULL)"
        "AND (level <=? or level is NULL)"
        "AND (linkRating >=? or linkRating is NULL)"
        "AND (linkRating <=? or linkRating is NULL)"
        "AND (pendulumScale >=? or pendulumScale is NULL)"
        "AND (pendulumScale <=? or pendulumScale is NULL)",
        ['%$name%', '%$description', attribute, race, cardType, minAttack, maxAttack, minDefense, maxDefense, minLevel, maxLevel,
        minLinkRating, maxLinkRating, minPendulumScale, maxPendulumScale]);
*/
    //List<Map> result = await db.rawQuery("SELECT * FROM cards WHERE name=?", ["Forest"]);
    //String testQuerry = "SELECT * FROM cards WHERE name LIKE ?";
    result = await db.rawQuery(queryString, [
      '%$name%',
      '%$description%',
      race,
      cardType,
      attribute,
      minAttack,
      maxAttack,
      minDefense,
      maxDefense,
      minLevel,
      maxLevel,
      minLinkRating,
      maxLinkRating,
      minPendulumScale,
      maxPendulumScale
    ]);
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
    List<Map> resultsList =
        ModalRoute.of(context)!.settings.arguments as List<Map>;
    return MaterialApp(
      title: 'Pauper Yugioh Search Results',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      home: Results(resultsList: resultsList),
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
  String attributeValue = "";
  String race = "Default";
  String raceValue = "";
  String cardType = "Default";
  String cardTypeValue = "";
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
            children: [const Text("Name: "), _tinyTextField(nameController)],
          ),
          Row(
            children: [
              const Text("Description: "),
              _tinyTextField(descriptionController)
            ],
          ),
          Row(
            children: [
              _tinyTextField(minAttackController),
              const Text(" ≤ Attack ≤ "),
              _tinyTextField(maxAttackController)
            ],
          ),
          Row(
            children: [
              _tinyTextField(minDefenseController),
              const Text(" ≤ Defense ≤ "),
              _tinyTextField(maxDefenseController)
            ],
          ),
          Row(
            children: [
              _tinyTextField(minLevelController),
              const Text(" ≤ Level/Rank ≤ "),
              _tinyTextField(maxLevelController)
            ],
          ),
          Row(
            children: [
              _tinyTextField(minLinkRatingController),
              const Text(" ≤ Link Rating ≤ "),
              _tinyTextField(maxLinkRatingController)
            ],
          ),
          Row(
            children: [
              _tinyTextField(minPendulumScaleController),
              const Text(" ≤ Pendulum Scale ≤ "),
              _tinyTextField(maxPendulumScaleController)
            ],
          ),
          ElevatedButton(
              child: const Text('Search'),
              onPressed: () async {
                await dbHelper._initialize();
                getVariables();
                List<Map> results = await dbHelper.performSearch(
                    name,
                    description,
                    minAttack,
                    maxAttack,
                    minDefense,
                    maxDefense,
                    minLevel,
                    maxLevel,
                    minLinkRating,
                    maxLinkRating,
                    minPendulumScale,
                    maxPendulumScale,
                    attributeValue,
                    cardTypeValue,
                    raceValue);
                Navigator.push(
                    this.context,
                    MaterialPageRoute(
                        builder: (context) => const SearchResults(),
                        settings: RouteSettings(arguments: results)));
              }),
        ]);
  }

  //Generates a dropdown button with the default value of currentValue and a list of values from allValues
  Widget _dropdownButtons(
      Function valueChanger, String updatedValue, List<String> allValues) {
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

  void _changeAttribute(String newValue) {
    attribute = newValue;
  }

  void _changeCardType(String newValue) {
    cardType = newValue;
  }

  void _changeRace(String newValue) {
    race = newValue;
  }

  Widget _tinyTextField(TextEditingController textController) {
    return SizedBox(
        width: 90,
        child: TextField(
            focusNode: FocusNode(canRequestFocus: false),
            controller: textController,
            decoration: InputDecoration(border: OutlineInputBorder())));
  }

  void getVariables() {
    if (nameController.text != "") {
      name = nameController.text;
    } else {
      name = "%";
    }
    if (descriptionController.text != "") {
      description = descriptionController.text;
    } else {
      description = "%";
    }
    if (minAttackController.text != "") {
      minAttack = minAttackController.text;
    } else {
      minAttack = "-1";
    }
    if (maxAttackController.text != "") {
      maxAttack = maxAttackController.text;
    } else {
      maxAttack = "100000";
    }
    if (minDefenseController.text != "") {
      minDefense = minDefenseController.text;
    } else {
      minDefense = "-1";
    }
    if (maxDefenseController.text != "") {
      maxDefense = maxDefenseController.text;
    } else {
      maxDefense = "100000";
    }
    if (minLevelController.text != "") {
      minLevel = minLevelController.text;
    } else {
      minLevel = "-1";
    }
    if (maxLevelController.text != "") {
      maxLevel = maxLevelController.text;
    } else {
      maxLevel = "100000";
    }
    if (minLinkRatingController.text != "") {
      minLinkRating = minLinkRatingController.text;
    } else {
      minLinkRating = "-1";
    }
    if (maxLinkRatingController.text != "") {
      maxLinkRating = maxLinkRatingController.text;
    } else {
      maxLinkRating = "100000";
    }
    if (minPendulumScaleController.text != "") {
      minPendulumScale = minPendulumScaleController.text;
    } else {
      minPendulumScale = "-1";
    }
    if (maxPendulumScaleController.text != "") {
      maxPendulumScale = maxPendulumScaleController.text;
    } else {
      maxPendulumScale = "100000";
    }
    if (attribute == "Default") {
      attributeValue = "%";
    } else {
      attributeValue = attribute;
    }
    if (race == "Default") {
      raceValue = "%";
    } else {
      raceValue = race;
    }
    if (cardType == "Default") {
      cardTypeValue = "%";
    } else {
      cardTypeValue = cardType;
    }
  }
}

class Results extends StatefulWidget {
  final List<Map> resultsList;
  const Results({Key? key, required this.resultsList}) : super(key: key);

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
            itemCount: widget.resultsList.length,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                  child: _individualResult(widget.resultsList[index]));
            }));
  }

  Widget _individualResult(Map result) {
    return (Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: [
            Text("Name: "),
            Text(cleanText(result["name"])),
          ],
        ),
        Text("Description: "),
        Text(cleanText(result["desc"])),
        Row(
          children: [
            Text("Attribute: "),
            Text(cleanText(result["attribute"])),
          ],
        ),
        Row(
          children: [
            Text("Level or Rank: "),
            Text(cleanInt(result["level"])),
          ],
        ),
        Row(
          children: [
            Text("Type: "),
            Text(cleanText(result["race"])),
          ],
        ),
        Row(
          children: [
            Text("Card Type: "),
            Text(cleanText(result["type"])),
          ],
        ),
        Row(
          children: [
            Text("Attack: "),
            Text(cleanInt(result["atk"])),
          ],
        ),
        Row(
          children: [
            Text("Defense: "),
            Text(cleanInt(result["def"])),
          ],
        ),
        Row(
          children: [
            Text("Link Rating: "),
            Text(cleanInt(result["linkRating"])),
          ],
        ),
        Row(
          children: [
            Text("Pendulum Scales: "),
            Text(cleanInt(result["pendulumScale"])),
          ],
        ),
        Divider()
      ],
    ));
  }

  String cleanText(dynamic text) {
    text ??= "";
    return text;
  }

  String cleanInt(dynamic text) {
    if (text == null) {
      return "N/A";
    } else {
      return text.toString();
    }
  }
}
