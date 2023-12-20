import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ESenseLineChart extends StatelessWidget {
  final List<FlSpot> data;

  const ESenseLineChart(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ESenseLineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          minX: 0,
          maxX: data.length.toDouble() - 1,
          minY: -5000,
          maxY: 5000,
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              color: Colors.blue,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ) as List<FlSpot>,
      ),
    );
  }
}
