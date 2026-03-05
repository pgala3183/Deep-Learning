import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const WaterTrackerApp());
}

class WaterTrackerApp extends StatelessWidget {
  const WaterTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const WaterHomeScreen(),
    );
  }
}

class WaterHomeScreen extends StatefulWidget {
  const WaterHomeScreen({super.key});

  @override
  State<WaterHomeScreen> createState() => _WaterHomeScreenState();
}

class _WaterHomeScreenState extends State<WaterHomeScreen> {
  static const int _defaultDailyGoalMl = 2000;
  static const String _prefsKeyIntake = 'intake_ml';
  static const String _prefsKeyHistory = 'history_entries';
  static const String _prefsKeyLastDate = 'last_date';

  bool _isLoading = true;
  int _intakeMl = 0;
  final int _dailyGoalMl = _defaultDailyGoalMl;
  List<_HistoryEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();

    final today = DateTime.now();
    final savedDateString = prefs.getString(_prefsKeyLastDate);
    DateTime? savedDate;
    if (savedDateString != null) {
      savedDate = DateTime.tryParse(savedDateString);
    }

    if (savedDate != null &&
        savedDate.year == today.year &&
        savedDate.month == today.month &&
        savedDate.day == today.day) {
      _intakeMl = prefs.getInt(_prefsKeyIntake) ?? 0;
      final historyStrings = prefs.getStringList(_prefsKeyHistory) ?? [];
      _history = historyStrings
          .map(_HistoryEntry.fromPersistedString)
          .whereType<_HistoryEntry>()
          .toList();
    } else {
      await prefs.remove(_prefsKeyIntake);
      await prefs.remove(_prefsKeyHistory);
      await prefs.setString(
        _prefsKeyLastDate,
        DateTime(today.year, today.month, today.day).toIso8601String(),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    await prefs.setInt(_prefsKeyIntake, _intakeMl);
    await prefs.setString(
      _prefsKeyLastDate,
      DateTime(today.year, today.month, today.day).toIso8601String(),
    );
    await prefs.setStringList(
      _prefsKeyHistory,
      _history.map((e) => e.toPersistedString()).toList(),
    );
  }

  double get _progress {
    if (_dailyGoalMl <= 0) return 0;
    final value = _intakeMl / _dailyGoalMl;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  Future<void> _addWater(int ml) async {
    setState(() {
      _intakeMl += ml;
      _history.insert(
        0,
        _HistoryEntry(
          amountMl: ml,
          time: TimeOfDay.now(),
        ),
      );
    });
    await _saveState();
  }

  Future<void> _showAddWaterDialog() async {
    const options = [150, 200, 250, 300, 350, 500];

    await showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Add water'),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Choose how much water you just drank:'),
            ),
            const SizedBox(height: 8),
            ...options.map(
              (ml) => SimpleDialogOption(
                onPressed: () {
                  Navigator.of(context).pop();
                  _addWater(ml);
                },
                child: Text('$ml ml'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_progress * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Tracker'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: _progress,
                                  strokeWidth: 8,
                                ),
                                Center(
                                  child: Text(
                                    '$percentage%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$_intakeMl ml of $_dailyGoalMl ml',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Today\'s entries',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _history.isEmpty
                        ? const Center(
                            child: Text(
                              'No water logged yet.\nTap the + button to add your first glass.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            itemCount: _history.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final entry = _history[index];
                              final timeLabel = entry.time.format(context);
                              return ListTile(
                                leading: const Icon(Icons.local_drink),
                                title: Text('+${entry.amountMl} ml'),
                                subtitle: Text(timeLabel),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWaterDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add water'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _HistoryEntry {
  final int amountMl;
  final TimeOfDay time;

  _HistoryEntry({
    required this.amountMl,
    required this.time,
  });

  String toPersistedString() {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$amountMl|$hour|$minute';
  }

  static _HistoryEntry? fromPersistedString(String value) {
    final parts = value.split('|');
    if (parts.length != 3) return null;
    final amount = int.tryParse(parts[0]);
    final hour = int.tryParse(parts[1]);
    final minute = int.tryParse(parts[2]);
    if (amount == null || hour == null || minute == null) return null;
    return _HistoryEntry(
      amountMl: amount,
      time: TimeOfDay(hour: hour, minute: minute),
    );
  }
}

