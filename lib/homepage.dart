import 'package:flutter/material.dart';

class BerthingDisplayScreen extends StatelessWidget {
  const BerthingDisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: Colors.blue.shade700,
      body: SafeArea(
        child: Center(
          child: Container(
            width: w * 0.95,          // Match tablet width
            height: h * 0.95,
            padding: const EdgeInsets.all(8),
            color: Colors.blue.shade300,
            child: Column(
              children: [
                // TOP HEADER: Terminal Name + Logo
                SizedBox(
                  height: h * 0.10,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          color: Colors.white,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 12),
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
                          color: Colors.white,
                          child: const Center(
                            child: Text(
                              "LOGO",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                SizedBox(height: h * 0.01),

                // MAIN GRID
                Expanded(
                  child: Row(
                    children: [
                      // LEFT COLUMN : SENSOR 1
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            sensorTile(
                              label: "Sensor",
                              number: "1",
                              height: h * 0.20,
                            ),
                            SizedBox(height: h * 0.02),
                            dataBox(
                              title: "Speed (cm/s)",
                              value: "123",
                              height: h * 0.15,
                            ),
                            SizedBox(height: h * 0.02),
                            dataBox(
                              title: "Distance (m)",
                              value: "24.5",
                              height: h * 0.15,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: w * 0.02),

                      // CENTER SECTION : ANGLE + SPACING
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            dataBox(
                              title: "Angle",
                              value: "45°",
                              height: h * 0.20,
                            ),
                            SizedBox(height: h * 0.02),
                            compassBox(height: h * 0.25),
                          ],
                        ),
                      ),

                      SizedBox(width: w * 0.02),

                      // RIGHT COLUMN : SENSOR 2
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            sensorTile(
                              label: "Sensor",
                              number: "2",
                              height: h * 0.20,
                            ),
                            SizedBox(height: h * 0.02),
                            dataBox(
                              title: "Speed (cm/s)",
                              value: "987",
                              height: h * 0.15,
                            ),
                            SizedBox(height: h * 0.02),
                            dataBox(
                              title: "Distance (m)",
                              value: "54.2",
                              height: h * 0.15,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // FOOTER
                SizedBox(height: h * 0.01),
                Container(
                  height: h * 0.07,
                  width: double.infinity,
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: const Text(
                    "HI-TECH BERTH APPROACH SYSTEM",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: h * 0.005),
                Container(
                  height: h * 0.06,
                  width: double.infinity,
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: const Text(
                    "Client Logo",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
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
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 3),
        color: Colors.grey.shade200,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          Text(
            number,
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget dataBox({
    required String title,
    required String value,
    required double height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 3),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Container(
            width: 100,
            color: Colors.black,
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
        ],
      ),
    );
  }

  Widget compassBox({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 3),
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
