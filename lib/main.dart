import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_tts/flutter_tts.dart';
void main() {
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
//// LOGIN PAGE
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  void login() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Stack(
        children: [

          // 🌄 BACKGROUND IMAGE
          
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/farm.jpg"), // 👈 add image
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🌫️ DARK OVERLAY

          Container(
            color: Colors.black.withOpacity(0.3),
          ),

          // 🌟 LOGIN CARD

          Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 25),
              padding: EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // LOGO
                  
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.agriculture,
                        size: 40, color: Colors.green),
                  ),

                  SizedBox(height: 10),

                  Text("OSS",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),

                  SizedBox(height: 5),

                  Text("Onion Storage System ",
                      style: TextStyle(color: Colors.grey)),

                  SizedBox(height: 20),

                  // EMAIL FIELD

                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      hintText: "Email",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  SizedBox(height: 15),

                  // PASSWORD FIELD
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      hintText: "Password",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  SizedBox(height: 10),
                  // OPTIONS ROW
                 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Row(
                        children: [
                          Checkbox(value: true, onChanged: (v) {}),
                          Text("Show"),
                        ],
                      ),

                      Text("Forgot Password?",
                          style: TextStyle(color: Colors.green)),
                    ],
                  ),

                  SizedBox(height: 10),

                  // LOGIN BUTTON
                  
                  GestureDetector(
                    onTap: login,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.lightGreen],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text("LOGIN",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// DASHBOARD

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  bool alertShown = false;
  String systemStatus = "--";

  late IOWebSocketChannel channel;
final FlutterTts tts = FlutterTts();

void speakAlert(String rack) async {
  await tts.setLanguage("en-IN");
  await tts.setPitch(1.0);
  await tts.speak("Warning. Spoilage detected in $rack");
}
  String temperature = "--";
  String humidity = "--";
  String gas = "--";
  String spoilage = "--";

  String t1="--", t2="--", t3="--";
  String h1="--", h2="--", h3="--";
  String g1="--", g2="--", g3="--";

  @override
  void initState() {
    super.initState();
    connectSocket();
  }

  //////////////////////////////////////////////////////
  // WEBSOCKET
  //////////////////////////////////////////////////////
  void connectSocket() {
    channel = IOWebSocketChannel.connect(
      Uri.parse('ws://10.240.162.129:81'),
    );

    channel.stream.listen((message) {
      print("📥 DATA: $message");

      var data = jsonDecode(message);

      setState(() {

        systemStatus = data["status"];

        t1 = data["temp1"].toString();
        t2 = data["temp2"].toString();
        t3 = data["temp3"].toString();

        h1 = data["hum1"].toString();
        h2 = data["hum2"].toString();
        h3 = data["hum3"].toString();

        g1 = data["gas1"].toString();
        g2 = data["gas2"].toString();
        g3 = data["gas3"].toString();

        temperature = (
          (double.parse(t1) + double.parse(t2) + double.parse(t3)) / 3
        ).toStringAsFixed(1);

        humidity = (
          (double.parse(h1) + double.parse(h2) + double.parse(h3)) / 3
        ).toStringAsFixed(1);

        gas = (
          (int.parse(g1) + int.parse(g2) + int.parse(g3)) ~/ 3
        ).toString();

        spoilage = data["spoilage"].toString();
      });

      //////////////////////////////////////////////////////
      // 🚨 ALERT
      //////////////////////////////////////////////////////
      bool alert = data["alert"] == true;

String rackAlert = "";

if (int.parse(data["gas1"].toString()) > 1400) {
  rackAlert += "Rack 1 ";
}
if (int.parse(data["gas2"].toString()) > 1400) {
  rackAlert += "Rack 2 ";
}
if (int.parse(data["gas3"].toString()) > 1400) {
  rackAlert += "Rack 3 ";
}

if (alert && !alertShown) {
  alertShown = true;

  ////////////////////////////////////////////
  // 🔔 POPUP
  ////////////////////////////////////////////
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("🚨 Spoilage Alert"),
      content: Text("Problem detected in: $rackAlert"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            alertShown = false;
          },
          child: Text("OK"),
        )
      ],
    ),
  );

  ////////////////////////////////////////////
  // 🔊 VOICE ALERT
  ////////////////////////////////////////////
  speakAlert(rackAlert);
}

    }); // ✅ IMPORTANT (closing listen)
  }

  //////////////////////////////////////////////////////
  // UI HELPERS
  //////////////////////////////////////////////////////
  IconData getWeatherIcon() {
    if (spoilage == "HIGH") return Icons.thunderstorm;
    if (spoilage == "MEDIUM") return Icons.cloud;
    return Icons.wb_sunny;
  }

  List<Color> getGradient() {
    if (spoilage == "HIGH") return [Colors.red, Colors.orange];
    if (spoilage == "MEDIUM") return [Colors.orange, Colors.amber];
    return [Color(0xFF6DD5FA), Color(0xFF2980B9)];
  }

  Widget bigCard() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: getGradient()),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Storage Status", style: TextStyle(color: Colors.white)),
              Icon(getWeatherIcon(), color: Colors.white),
            ],
          ),
          SizedBox(height: 10),
          Text("$temperature°C",
              style: TextStyle(color: Colors.white, fontSize: 40)),
          Text("Humidity: $humidity%", style: TextStyle(color: Colors.white)),
          Text("Gas: $gas", style: TextStyle(color: Colors.white)),
          Text("Spoilage: $spoilage", style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  void openDetails(String title) {
    List<Map<String, String>> data = [];

    if (title == "Temperature") {
      data = [
        {"name": "Sensor 1", "value": "$t1°C"},
        {"name": "Sensor 2", "value": "$t2°C"},
        {"name": "Sensor 3", "value": "$t3°C"},
      ];
    } else if (title == "Humidity") {
      data = [
        {"name": "Sensor 1", "value": "$h1%"},
        {"name": "Sensor 2", "value": "$h2%"},
        {"name": "Sensor 3", "value": "$h3%"},
      ];
    } else {
      data = [
        {"name": "Sensor 1", "value": g1},
        {"name": "Sensor 2", "value": g2},
        {"name": "Sensor 3", "value": g3},
      ];
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SensorDetailPage(title: title, data: data),
      ),
    );
  }

  Widget smallCard(String title, String value, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => openDetails(title),
      child: Container(
        width: 150,
        height: 120,
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            Text(title),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////
  // UI
  //////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEAF6FF),

      appBar: AppBar(
        title: Text("Smart Storage"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            bigCard(),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                smallCard("Temperature", "$temperature°C", Icons.thermostat, Colors.orange),
                smallCard("Humidity", "$humidity%", Icons.water_drop, Colors.blue),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                smallCard("Gas", gas, Icons.science, Colors.purple),
                smallCard("Spoilage", spoilage, Icons.warning, Colors.red),
              ],
            ),

            SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FanDetailPage(status: systemStatus),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.air, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      systemStatus,
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// DETAIL PAGE


class SensorDetailPage extends StatelessWidget {

  final String title;
  final List<Map<String, String>> data;

  const SensorDetailPage({super.key, required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),

      body: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {

          return ListTile(
            title: Text(data[index]["name"]!),
            trailing: Text(data[index]["value"]!),
          );
        },
      ),
    );
  }
}


// PROFILE


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  String name = "";
  String phone = "";

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  void loadProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      name = prefs.getString("name") ?? "User";
      phone = prefs.getString("phone") ?? "Not Available";
    });
  }

  Widget infoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEAF6FF),

      body: Column(
        children: [

          /// 🔵 TOP PROFILE CARD (MODERN)
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: 60, bottom: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF43CEA2), // green
                  Color(0xFF185A9D), // blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),

            child: Column(
              children: [

                /// PROFILE ICON
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: Colors.green),
                ),

                SizedBox(height: 10),

                /// NAME
                Text(
                  name,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 5),

                /// PHONE
                Text(
                  phone,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          /// 🔹 DETAILS SECTION
          Expanded(
            child: Container(
              padding: EdgeInsets.all(15),
              child: Column(
                children: [

                  infoTile(Icons.email, "Customer Care Email",
                      "support@smartstorage.com"),

                  infoTile(Icons.phone, "Customer Care Number",
                      "+91 9876543210"),

                  infoTile(Icons.info, "App Version",
                      "1.0.0"),

                  infoTile(Icons.settings, "System",
                      "Smart Onion Storage"),

                  SizedBox(height: 20),

                  /// LOGOUT BUTTON
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(
                          horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: Icon(Icons.logout),
                    label: Text("Logout"),
                    onPressed: () async {

                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.clear();

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LoginPage()),
                            (route) => false,
                      );
                    },
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
// FAN DETAIL PAGE


class FanDetailPage extends StatelessWidget {

  final String status;

  FanDetailPage({required this.status});

  bool isCooling() => status == "COOLING";
  bool isHeating() => status == "HEATING";
  bool isNormal()  => status == "NORMAL";

  Widget fanCard(String title, bool isOn, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOn ? color : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Row(
            children: [
              Icon(icon, color: Colors.white),
              SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18)),
            ],
          ),

          Text(
            isOn ? "ON" : "OFF",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: Text("Fan Details")),

      body: Column(
        children: [

          SizedBox(height: 20),

          fanCard("Cooling Fan ❄", isCooling(),
              Icons.ac_unit, Colors.blue),

          fanCard("Heating Fan 🔥", isHeating(),
              Icons.local_fire_department, Colors.red),

          fanCard("Normal Fan 🌬", isNormal(),
              Icons.air, Colors.green),

        ],
      ),
    );
  }
}

