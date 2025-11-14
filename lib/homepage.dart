import 'package:flutter/material.dart';

class BerthingDisplayScreen extends StatelessWidget {
  const BerthingDisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
    backgroundColor: Colors.lightBlue,
      body: SafeArea(
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg.gif'),
                fit: BoxFit.cover,
              ),
            ),
            width: w * 0.98, // Match tablet width
            height: h * 0.98,
            padding: const EdgeInsets.all(8),
         
            child: Column(
              children: [
                Container(
                  width: w * 0.9,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset('assets/logo.jpeg', height: h * 0.15),
                  ),
                ),
                SizedBox(height: h * 0.01),
                // TOP HEADER: Terminal Name + Logo
                SizedBox(
                  height: h * 0.2,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: const Text(
                            "Terminal Name",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.only(left: 12, right: 10),
                          child: dataBox(
                            width: w * 0.4,
                            title: "Angle",
                            value: "45°",
                            height: h * 0.2,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.only(left: 8, right: 10),
                          child: compassBox(height: h * 0.2),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: h * 0.04),

                // MAIN GRID
                Center(
                  child: SizedBox(
                    width: w * 0.95, // Controls total width of sensor section
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        sensorTile(
                          label: "Sensor",
                          number: "1",
                          height: h * 0.40,
                        ),
                        SizedBox(width: w * 0.03),
                        // LEFT COLUMN : SENSOR 1
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              dataBox(
                                width: w * 0.4,
                                title: "Speed (cm/s)",
                                value: "123",
                                height: h * 0.2,
                              ),
                              SizedBox(height: h * 0.02),
                              dataBox(
                                width: w * 0.4,
                                title: "Distance  (m)",
                                value: "24.5",
                                height: h * 0.2,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: w * 0.03),

                        // RIGHT COLUMN : SENSOR 2
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              dataBox(
                                width: w * 0.4,
                                title: "Speed (cm/s)",
                                value: "987",
                                height: h * 0.2,
                              ),
                              SizedBox(height: h * 0.02),
                              dataBox(
                                width: w * 0.4,
                                title: "Distance  (m)",
                                value: "54.2",
                                height: h * 0.2,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: w * 0.03),
                        sensorTile(
                          label: "Sensor",
                          number: "2",
                          height: h * 0.40,
                        ),
                      ],
                    ),
                  ),
                ),SizedBox(height: h * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "www.hitechelastomers.com",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),SizedBox(width: 20),
                    ElevatedButton(
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                      ),
                      onPressed: () {},
                      child: Text("Connect",style: TextStyle(color: Colors.black,fontSize: 25),),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------
  // WIDGETS
  // ------------------------------------------------------

  Widget sensorTile({
    required String label,
    required String number,
    required double height,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 3),
        color: Colors.grey.shade200,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          Text(
            number,
            style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget dataBox({
    required String title,
    required String value,
    required double height,
    required double width,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(
            width: 100,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),

            alignment: Alignment.center,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget compassBox({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),

        color: Colors.white,
      ),
      child: const Center(
        child: Text(
          "🧭\nCompass",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}
